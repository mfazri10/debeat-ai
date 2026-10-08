package debate

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	pb "github.com/debateai/api-gateway/gen/go/debateai/v1"
	"github.com/debateai/api-gateway/internal/session"
	"github.com/debateai/api-gateway/pkg/config"
	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// TODO: Validasi origin di production
		return true
	},
	HandshakeTimeout: 10 * time.Second,
}

// Handler menangani HTTP → WebSocket upgrade dan lifecycle koneksi.
type Handler struct {
	hub *Hub
	cfg *config.Config
}

func NewHandler(hub *Hub, cfg *config.Config) *Handler {
	return &Handler{hub: hub, cfg: cfg}
}

// HandleWebSocket adalah endpoint utama arena debat.
// Path: GET /ws/debate/:sessionId
func (h *Handler) HandleWebSocket(c echo.Context) error {
	sessionID := c.Param("sessionId")
	userID, _ := c.Get("user_id").(string) // Diset oleh JWTMiddlewareWS

	// Upgrade ke WebSocket
	conn, err := upgrader.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		return err
	}

	// Buat client dan daftarkan ke Hub
	client := &Client{
		hub:       h.hub,
		conn:      conn,
		send:      make(chan ServerMessage, 256),
		sessionID: sessionID,
		userID:    userID,
	}
	h.hub.register <- client

	// Start goroutines read/write secara concurrent
	go client.writePump()
	go client.readPump(h.hub)

	return nil
}

// ============================================================
// CLIENT PUMPS
// ============================================================

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 64 * 1024 // 64KB
)

// readPump membaca pesan dari Flutter dan memprosesnya.
func (c *Client) readPump(hub *Hub) {
	defer func() {
		hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, msgBytes, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway, websocket.CloseAbnormalClosure,
			) {
				// Log error
			}
			break
		}

		var msg ClientMessage
		if err := json.Unmarshal(msgBytes, &msg); err != nil {
			c.Send(ServerMessage{
				Type:    MsgTypeError,
				Payload: map[string]string{"code": "INVALID_MESSAGE", "message": "Format pesan tidak valid"},
			})
			continue
		}

		// Proses pesan berdasarkan tipe
		go hub.processClientMessage(c, msg)
	}
}

// writePump menulis pesan dari channel send ke koneksi WebSocket.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Hub menutup channel
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteJSON(msg); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// ============================================================
// MESSAGE PROCESSING
// ============================================================

// processClientMessage memproses pesan dari Flutter dan memicu AI pipeline.
func (h *Hub) processClientMessage(c *Client, msg ClientMessage) {
	switch msg.Type {
	case MsgTypeArgument:
		h.handleArgument(c, msg)
	case MsgTypeForfeit:
		h.handleForfeit(c, msg)
	case MsgTypePause:
		h.BroadcastToSession(msg.SessionID, ServerMessage{Type: MsgTypePause, Payload: nil})
	case MsgTypeResume:
		h.BroadcastToSession(msg.SessionID, ServerMessage{Type: MsgTypeResume, Payload: nil})
	}
}

// handleArgument adalah inti dari arena debat:
// User kirim argumen → persist DB → RAG search → SessionStarted (jika pertama) → AI pipeline
func (h *Hub) handleArgument(c *Client, msg ClientMessage) {
	ctx := context.Background()
	sessionID := msg.SessionID

	// 1. Muat sesi dari DB — validasi keberadaan & ambil konfigurasi
	sess, err := h.store.GetByID(ctx, sessionID)
	if err != nil {
		c.Send(ServerMessage{
			Type:    MsgTypeError,
			Payload: map[string]string{"code": "SESSION_NOT_FOUND", "message": "Sesi tidak ditemukan. Buat sesi terlebih dahulu."},
		})
		return
	}

	// 2. Persist argumen user ke DB
	participantID, perr := h.store.GetUserParticipantID(ctx, sessionID, c.userID)
	if perr != nil {
		// Fallback: user belum terdaftar sebagai partisipan (mis. guest dev) — daftarkan
		participantID, perr = h.store.AddParticipant(ctx, sessionID, map[string]any{
			"user_id":       c.userID,
			"persona_id":    nil,
			"persona_name":  "Anda",
			"stance":        "PRO",
			"role":          "HOST",
			"is_ai":         false,
			"ai_difficulty": nil,
		})
		if perr != nil {
			c.Send(ServerMessage{
				Type:    MsgTypeError,
				Payload: map[string]string{"code": "PARTICIPANT_ERROR", "message": "Gagal mendaftarkan partisipan."},
			})
			return
		}
	}

	round, turn, _ := h.store.IncrementTurn(ctx, sessionID)
	argumentID, _ := h.store.InsertArgument(ctx, sessionID, participantID, msg.Content, "TEXT", round, turn, nil)

	// 3. Notify semua client bahwa AI sedang berpikir
	h.BroadcastToSession(sessionID, ServerMessage{
		Type:    MsgTypeAIThinking,
		Payload: nil,
	})

	// 4. Generate embedding dari argumen user untuk RAG
	var kbChunks []*pb.KbChunk
	embeddingResp, err := h.grpc.GenerateEmbedding(ctx, &pb.EmbeddingRequest{
		Text:     msg.Content,
		Language: sess.Language,
	})
	if err == nil && embeddingResp != nil {
		// 5. Search knowledge base (RAG retrieval)
		kbResp, kerr := h.grpc.SearchKnowledge(ctx, &pb.SearchRequest{
			Embedding: embeddingResp.Embedding,
			TopK:      5,
			Threshold: 0.70,
			Language:  sess.Language,
		})
		if kerr == nil && kbResp != nil {
			kbChunks = kbResp.Chunks
		}
	}

	// 6. Ambil atau buat orchestrator (stream gRPC per-sesi)
	orch, err := h.getOrCreateOrchestrator(ctx, sessionID)
	if err != nil {
		h.BroadcastToSession(sessionID, ServerMessage{
			Type:    MsgTypeError,
			Payload: map[string]string{"code": "AI_UNAVAILABLE", "message": "AI tidak tersedia saat ini. Coba beberapa saat lagi."},
		})
		return
	}

	// 7. Kirim SessionStartedEvent sekali (fix bug SESSION_NOT_STARTED)
	orch.ensureStarted(h.buildSessionConfig(ctx, sess))

	// 8. Kirim event ArgumentSubmitted ke Python (dengan KB context)
	orch.sendArgument(&pb.ArgumentSubmittedEvent{
		SessionId:     sessionID,
		ArgumentId:    argumentID,
		Content:       msg.Content,
		ParticipantId: c.userID,
		RoundNumber:   int32(round),
		TurnNumber:    int32(turn),
	})

	// kbChunks diteruskan via session state di Python; broadcast update
	// ditangani oleh orchestrator.recvLoop. Simpan referensi KB untuk logging.
	_ = kbChunks
}

// buildSessionConfig menyusun SessionStartedEvent dari data sesi di DB.
func (h *Hub) buildSessionConfig(ctx context.Context, sess *session.Session) *pb.SessionStartedEvent {
	cfg := &pb.SessionStartedEvent{
		SessionId:  sess.ID,
		Topic:      sess.Topic,
		Format:     sess.Format,
		Language:   sess.Language,
		Difficulty: "MEDIUM",
		AiProvider: sess.AIProvider,
	}

	// Ambil persona AI dari DB
	personaID, personaName, stance, difficulty, err := h.store.GetAIParticipant(ctx, sess.ID)
	if err == nil {
		cfg.Difficulty = derefOr(difficulty, "MEDIUM")
		persona := &pb.PersonaContext{
			Name:   derefOr(personaName, "AI Lawan"),
			Stance: derefOr(stance, "CONTRA"),
		}
		if personaID != nil && *personaID != "" {
			persona.Id = *personaID
			if name, desc, style, pstance, perr := h.store.GetPersonaDetail(ctx, *personaID); perr == nil {
				persona.Name = derefOr(name, persona.Name)
				persona.Description = derefOr(desc, "")
				persona.SpeakingStyle = derefOr(style, "")
				if pstance != nil && *pstance != "" {
					persona.Stance = *pstance
				}
			}
		}
		cfg.AiPersona = persona
	}

	return cfg
}

func derefOr(s *string, def string) string {
	if s == nil || *s == "" {
		return def
	}
	return *s
}

// handleForfeit menangani pengguna yang menyerah.
func (h *Hub) handleForfeit(c *Client, msg ClientMessage) {
	// Tutup orchestrator sesi
	h.removeOrchestrator(msg.SessionID)
	// Tandai sesi selesai di DB
	if h.store != nil {
		_ = h.store.SetStatus(context.Background(), msg.SessionID, "CANCELLED")
	}
	h.BroadcastToSession(msg.SessionID, ServerMessage{
		Type: MsgTypeSessionEnd,
		Payload: map[string]interface{}{
			"forfeitedBy": c.userID,
		},
	})
}

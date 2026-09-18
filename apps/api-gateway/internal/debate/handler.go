package debate

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	pb "github.com/debateai/api-gateway/gen/go/debateai/v1"
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
	userID := c.Get("userID").(string) // Diset oleh JWTMiddlewareWS

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
// User kirim argumen → RAG search → AI Lawan stream → 3 Juri score → Audience react
func (h *Hub) handleArgument(c *Client, msg ClientMessage) {
	ctx := context.Background()
	sessionID := msg.SessionID

	// 1. Notify semua client bahwa AI sedang berpikir
	h.BroadcastToSession(sessionID, ServerMessage{
		Type:    MsgTypeAIThinking,
		Payload: nil,
	})

	// 2. Generate embedding dari argumen user untuk RAG
	embeddingResp, err := h.grpc.GenerateEmbedding(ctx, &pb.EmbeddingRequest{
		Text:     msg.Content,
		Language: "ID", // TODO: ambil dari session config
	})
	if err != nil {
		// Lanjut tanpa RAG (graceful degradation)
		embeddingResp = nil
	}

	// 3. Search knowledge base (RAG retrieval)
	var kbChunks []*pb.KbChunk
	if embeddingResp != nil {
		kbResp, err := h.grpc.SearchKnowledge(ctx, &pb.SearchRequest{
			Embedding: embeddingResp.Embedding,
			TopK:      5,
			Threshold: 0.75,
			Language:  "ID",
		})
		if err == nil && kbResp != nil {
			kbChunks = kbResp.Chunks
		}
	}

	// 4. Buka bidirectional gRPC stream ke Python untuk full orchestration
	stream, err := h.grpc.OrchestrateDebate(ctx)
	if err != nil {
		h.BroadcastToSession(sessionID, ServerMessage{
			Type:    MsgTypeError,
			Payload: map[string]string{"code": "AI_UNAVAILABLE", "message": "AI tidak tersedia saat ini. Coba beberapa saat lagi."},
		})
		return
	}

	// 5. Kirim event ArgumentSubmitted ke Python
	_ = stream.Send(&pb.DebateEvent{
		Event: &pb.DebateEvent_ArgumentSubmitted{
			ArgumentSubmitted: &pb.ArgumentSubmittedEvent{
				SessionId:   sessionID,
				Content:     msg.Content,
				ParticipantId: c.userID,
				// TODO: isi round_number dan turn_number dari state Redis
			},
		},
	})

	// 6. Terima stream updates dari Python dan broadcast ke Flutter
	go func() {
		_ = kbChunks // digunakan sebagai context (sudah di-inject di Python via session state)
		for {
			update, err := stream.Recv()
			if err != nil {
				break
			}

			switch u := update.Update.(type) {
			case *pb.DebateUpdate_OpponentChunk:
				// Streaming teks AI Lawan — karakter per karakter ke Flutter
				h.BroadcastAIChunk(sessionID, u.OpponentChunk.Content, u.OpponentChunk.IsDone)

			case *pb.DebateUpdate_JudgeResult:
				// Skor dari salah satu juri (Logika / Retorika / Dampak)
				h.BroadcastJudgeScore(sessionID, u.JudgeResult)

			case *pb.DebateUpdate_AudienceReact:
				// Reaksi penonton (emoji + komentar)
				h.BroadcastAudienceReaction(sessionID, u.AudienceReact)

			case *pb.DebateUpdate_Error:
				h.BroadcastToSession(sessionID, ServerMessage{
					Type: MsgTypeError,
					Payload: map[string]string{
						"code":    u.Error.Code,
						"message": u.Error.Message,
					},
				})
			}
		}
	}()
}

// handleForfeit menangani pengguna yang menyerah.
func (h *Hub) handleForfeit(c *Client, msg ClientMessage) {
	h.BroadcastToSession(msg.SessionID, ServerMessage{
		Type: MsgTypeSessionEnd,
		Payload: map[string]interface{}{
			"forfeitedBy": c.userID,
		},
	})
}

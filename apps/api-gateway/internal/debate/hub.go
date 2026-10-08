package debate

import (
	"context"
	"sync"

	pb "github.com/debateai/api-gateway/gen/go/debateai/v1"
	"github.com/debateai/api-gateway/internal/session"
	"github.com/debateai/api-gateway/pkg/grpcclient"
	"github.com/gorilla/websocket"
)

// MessageType mendefinisikan tipe pesan WebSocket antara server dan Flutter client.
type MessageType string

const (
	// Client → Server
	MsgTypeArgument MessageType = "debate:argument"
	MsgTypeForfeit  MessageType = "debate:forfeit"
	MsgTypePause    MessageType = "debate:pause"
	MsgTypeResume   MessageType = "debate:resume"

	// Server → Client
	MsgTypeAIThinking       MessageType = "debate:ai_thinking"
	MsgTypeAIChunk          MessageType = "debate:ai_chunk"          // Streaming teks AI
	MsgTypeAIResponse       MessageType = "debate:ai_response"       // Respons AI selesai
	MsgTypeJudgeScore       MessageType = "debate:judge_score"       // Skor salah satu juri
	MsgTypeAudienceReaction MessageType = "debate:audience"          // Reaksi penonton
	MsgTypeTurnChange       MessageType = "debate:turn_change"       // Pergantian giliran
	MsgTypeRoundEnd         MessageType = "debate:round_end"         // Akhir ronde
	MsgTypeSessionEnd       MessageType = "debate:session_end"       // Akhir debat
	MsgTypeError            MessageType = "debate:error"
)

// ClientMessage adalah pesan dari Flutter ke Go WebSocket server.
type ClientMessage struct {
	Type      MessageType `json:"type"`
	SessionID string      `json:"sessionId"`
	Content   string      `json:"content,omitempty"`
}

// ServerMessage adalah pesan dari Go ke Flutter.
type ServerMessage struct {
	Type    MessageType `json:"type"`
	Payload interface{} `json:"payload"`
}

// Client merepresentasikan satu koneksi WebSocket dari Flutter.
type Client struct {
	hub       *Hub
	conn      *websocket.Conn
	send      chan ServerMessage
	sessionID string
	userID    string
	mu        sync.Mutex
}

// Send mengirim pesan ke client secara thread-safe.
func (c *Client) Send(msg ServerMessage) {
	select {
	case c.send <- msg:
	default:
		// Buffer penuh — client kemungkinan lambat atau disconnect
	}
}

// Hub mengelola semua koneksi WebSocket dan mendistribusikan pesan ke client yang tepat.
type Hub struct {
	// sessionID → map of clients (untuk satu sesi bisa ada beberapa observer)
	sessions map[string]map[*Client]bool
	mu       sync.RWMutex

	register   chan *Client
	unregister chan *Client
	broadcast  chan sessionBroadcast

	grpc  *grpcclient.Clients
	store *session.Store

	// orchestrators menyimpan stream gRPC aktif per sessionID
	orchMu     sync.Mutex
	orchestrators map[string]*SessionOrchestrator
}

type sessionBroadcast struct {
	sessionID string
	message   ServerMessage
}

// NewHub membuat Hub baru.
func NewHub(grpc *grpcclient.Clients, store *session.Store) *Hub {
	return &Hub{
		sessions:      make(map[string]map[*Client]bool),
		register:      make(chan *Client, 100),
		unregister:    make(chan *Client, 100),
		broadcast:     make(chan sessionBroadcast, 500),
		grpc:          grpc,
		store:         store,
		orchestrators: make(map[string]*SessionOrchestrator),
	}
}

// Run adalah goroutine utama Hub — harus dipanggil sekali dengan `go hub.Run()`.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if h.sessions[client.sessionID] == nil {
				h.sessions[client.sessionID] = make(map[*Client]bool)
			}
			h.sessions[client.sessionID][client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if clients, ok := h.sessions[client.sessionID]; ok {
				delete(clients, client)
				if len(clients) == 0 {
					delete(h.sessions, client.sessionID)
				}
			}
			h.mu.Unlock()
			close(client.send)

		case sb := <-h.broadcast:
			h.mu.RLock()
			clients := h.sessions[sb.sessionID]
			h.mu.RUnlock()

			for client := range clients {
				client.Send(sb.message)
			}
		}
	}
}

// BroadcastToSession mengirim pesan ke semua client dalam satu sesi.
func (h *Hub) BroadcastToSession(sessionID string, msg ServerMessage) {
	h.broadcast <- sessionBroadcast{sessionID: sessionID, message: msg}
}

// BroadcastJudgeScore mengirim skor juri ke semua client dalam sesi.
func (h *Hub) BroadcastJudgeScore(sessionID string, result *pb.JudgeResult) {
	h.BroadcastToSession(sessionID, ServerMessage{
		Type:    MsgTypeJudgeScore,
		Payload: result,
	})
}

// BroadcastAudienceReaction mengirim reaksi penonton ke semua client.
func (h *Hub) BroadcastAudienceReaction(sessionID string, reaction *pb.AudienceResponse) {
	h.BroadcastToSession(sessionID, ServerMessage{
		Type:    MsgTypeAudienceReaction,
		Payload: reaction,
	})
}

// BroadcastAIChunk mengirim satu chunk teks AI Lawan (streaming).
func (h *Hub) BroadcastAIChunk(sessionID string, chunk string, isDone bool) {
	h.BroadcastToSession(sessionID, ServerMessage{
		Type: MsgTypeAIChunk,
		Payload: map[string]interface{}{
			"content": chunk,
			"isDone":  isDone,
		},
	})
}

// SessionOrchestrator mengelola satu stream gRPC bidirectional OrchestrateDebate
// untuk satu sesi debat. Memastikan SessionStartedEvent dikirim sekali sebelum argumen.
type SessionOrchestrator struct {
	hub       *Hub
	sessionID string
	stream    pb.DebateEngine_OrchestrateDebateClient
	sendCh    chan *pb.DebateEvent
	cancel    context.CancelFunc
	started   bool
	mu        sync.Mutex
}

// getOrCreateOrchestrator mengambil atau membuat orchestrator untuk sesi.
func (h *Hub) getOrCreateOrchestrator(ctx context.Context, sessionID string) (*SessionOrchestrator, error) {
	h.orchMu.Lock()
	defer h.orchMu.Unlock()

	if o, ok := h.orchestrators[sessionID]; ok {
		return o, nil
	}

	streamCtx, cancel := context.WithCancel(context.Background())
	stream, err := h.grpc.OrchestrateDebate(streamCtx)
	if err != nil {
		cancel()
		return nil, err
	}

	o := &SessionOrchestrator{
		hub:       h,
		sessionID: sessionID,
		stream:    stream,
		sendCh:    make(chan *pb.DebateEvent, 64),
		cancel:    cancel,
	}
	h.orchestrators[sessionID] = o

	go o.sendLoop()
	go o.recvLoop()

	return o, nil
}

// removeOrchestrator menutup dan menghapus orchestrator.
func (h *Hub) removeOrchestrator(sessionID string) {
	h.orchMu.Lock()
	defer h.orchMu.Unlock()
	if o, ok := h.orchestrators[sessionID]; ok {
		o.cancel()
		delete(h.orchestrators, sessionID)
	}
}

// sendLoop mengirim event ke stream gRPC.
func (o *SessionOrchestrator) sendLoop() {
	for ev := range o.sendCh {
		if err := o.stream.Send(ev); err != nil {
			return
		}
	}
}

// recvLoop menerima update dari Python dan broadcast ke client WebSocket.
func (o *SessionOrchestrator) recvLoop() {
	for {
		update, err := o.stream.Recv()
		if err != nil {
			return
		}
		switch u := update.Update.(type) {
		case *pb.DebateUpdate_OpponentChunk:
			o.hub.BroadcastAIChunk(o.sessionID, u.OpponentChunk.Content, u.OpponentChunk.IsDone)
		case *pb.DebateUpdate_JudgeResult:
			o.hub.BroadcastJudgeScore(o.sessionID, u.JudgeResult)
		case *pb.DebateUpdate_AudienceReact:
			o.hub.BroadcastAudienceReaction(o.sessionID, u.AudienceReact)
		case *pb.DebateUpdate_Error:
			o.hub.BroadcastToSession(o.sessionID, ServerMessage{
				Type: MsgTypeError,
				Payload: map[string]string{
					"code":    u.Error.Code,
					"message": u.Error.Message,
				},
			})
		}
	}
}

// ensureStarted mengirim SessionStartedEvent sekali jika belum.
func (o *SessionOrchestrator) ensureStarted(cfg *pb.SessionStartedEvent) {
	o.mu.Lock()
	defer o.mu.Unlock()
	if o.started {
		return
	}
	o.started = true
	o.sendCh <- &pb.DebateEvent{
		Event: &pb.DebateEvent_SessionStarted{SessionStarted: cfg},
	}
}

// sendArgument mengirim event argumen ke engine.
func (o *SessionOrchestrator) sendArgument(ev *pb.ArgumentSubmittedEvent) {
	o.sendCh <- &pb.DebateEvent{
		Event: &pb.DebateEvent_ArgumentSubmitted{ArgumentSubmitted: ev},
	}
}

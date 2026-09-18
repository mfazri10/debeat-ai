package debate

import (
	"sync"

	pb "github.com/debateai/api-gateway/gen/go/debateai/v1"
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

	grpc *grpcclient.Clients
}

type sessionBroadcast struct {
	sessionID string
	message   ServerMessage
}

// NewHub membuat Hub baru.
func NewHub(grpc *grpcclient.Clients) *Hub {
	return &Hub{
		sessions:   make(map[string]map[*Client]bool),
		register:   make(chan *Client, 100),
		unregister: make(chan *Client, 100),
		broadcast:  make(chan sessionBroadcast, 500),
		grpc:       grpc,
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

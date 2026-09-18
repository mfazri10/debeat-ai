package grpcclient

import (
	"context"
	"io"
	"time"

	pb "github.com/debateai/api-gateway/gen/go/debateai/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/keepalive"
)

// Clients menyimpan semua gRPC client yang digunakan API Gateway.
type Clients struct {
	conn         *grpc.ClientConn
	DebateEngine pb.DebateEngineClient
	KnowledgeBase pb.KnowledgeBaseClient
}

// NewClients membuat koneksi gRPC ke Debate Engine Python.
func NewClients(addr string) (*Clients, error) {
	conn, err := grpc.NewClient(
		addr,
		grpc.WithTransportCredentials(insecure.NewCredentials()), // TODO: TLS di production
		grpc.WithKeepaliveParams(keepalive.ClientParameters{
			Time:                10 * time.Second,
			Timeout:             3 * time.Second,
			PermitWithoutStream: true,
		}),
	)
	if err != nil {
		return nil, err
	}

	return &Clients{
		conn:          conn,
		DebateEngine:  pb.NewDebateEngineClient(conn),
		KnowledgeBase: pb.NewKnowledgeBaseClient(conn),
	}, nil
}

func (c *Clients) Close() {
	c.conn.Close()
}

// ============================================================
// HELPER METHODS — Debate Engine
// ============================================================

// StreamOpponentResponse memanggil gRPC streaming dan meneruskan setiap
// chunk teks ke callback onChunk. Cocok untuk di-forward ke WebSocket Flutter.
func (c *Clients) StreamOpponentResponse(
	ctx context.Context,
	req *pb.OpponentRequest,
	onChunk func(chunk string),
) (*pb.OpponentChunk, error) {

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	stream, err := c.DebateEngine.StreamOpponentResponse(ctx, req)
	if err != nil {
		return nil, err
	}

	var finalChunk *pb.OpponentChunk
	for {
		chunk, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		// Forward ke Flutter via WebSocket (non-blocking)
		onChunk(chunk.Content)

		if chunk.IsDone {
			finalChunk = chunk
			break
		}
	}

	return finalChunk, nil
}

// ScoreArgument memanggil scoring 3 juri secara paralel di sisi Python.
func (c *Clients) ScoreArgument(
	ctx context.Context,
	req *pb.ScoreRequest,
) (*pb.ScoreResponse, error) {

	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	return c.DebateEngine.ScoreArgument(ctx, req)
}

// GenerateAudienceReaction memanggil generator reaksi penonton.
func (c *Clients) GenerateAudienceReaction(
	ctx context.Context,
	req *pb.AudienceRequest,
) (*pb.AudienceResponse, error) {

	ctx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()

	return c.DebateEngine.GenerateAudienceReaction(ctx, req)
}

// OrchestrateDebate membuka stream bidirectional untuk satu sesi debat penuh.
// Go kirim DebateEvent → Python balas dengan stream DebateUpdate.
func (c *Clients) OrchestrateDebate(
	ctx context.Context,
) (pb.DebateEngine_OrchestrateDebateClient, error) {
	return c.DebateEngine.OrchestrateDebate(ctx)
}

// ============================================================
// HELPER METHODS — Knowledge Base
// ============================================================

// SearchKnowledge memanggil RAG vector search di pgvector.
func (c *Clients) SearchKnowledge(
	ctx context.Context,
	req *pb.SearchRequest,
) (*pb.SearchResponse, error) {

	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	return c.KnowledgeBase.SearchKnowledge(ctx, req)
}

// GenerateEmbedding menghasilkan vektor 768-dim dari teks.
func (c *Clients) GenerateEmbedding(
	ctx context.Context,
	req *pb.EmbeddingRequest,
) (*pb.EmbeddingResponse, error) {

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	return c.KnowledgeBase.GenerateEmbedding(ctx, req)
}

// IngestDocument memulai ingestion dokumen dan mengembalikan stream progress.
func (c *Clients) IngestDocument(
	ctx context.Context,
	req *pb.IngestRequest,
	onProgress func(progress *pb.IngestProgress),
) error {

	stream, err := c.KnowledgeBase.IngestDocument(ctx, req)
	if err != nil {
		return err
	}

	for {
		progress, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		onProgress(progress)
	}

	return nil
}

# 🎙️ DebateAI — Platform Debat Berbasis AI

> Platform debat real-time dengan AI lawan, 3 AI juri, dan penonton simulasi.
> Dibangun untuk pelajar dan profesional Indonesia.

---

## Stack Teknologi

```
┌──────────────────────────────────────────────────────┐
│          Flutter (iOS / Android / Web / Desktop)      │
│          Riverpod · GoRouter · Socket client          │
└──────────────┬───────────────────────────────────────┘
               │  REST (HTTPS) + WebSocket (WSS)
               ▼
┌──────────────────────────────────────────────────────┐
│              API GATEWAY — Go (Echo v4)              │
│  Auth JWT · WebSocket Hub · REST endpoints · sqlc    │
└──────────────┬───────────────────────────────────────┘
               │  gRPC (internal)
               ▼
┌──────────────────────────────────────────────────────┐
│          DEBATE ENGINE — Python (gRPC Server)        │
│  AI Lawan · 3 AI Juri · Penonton · RAG pipeline     │
│  LangChain · Gemini / GPT-4o / Claude               │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│                    DATA LAYER                        │
│   PostgreSQL 16 + pgvector · Redis 7 · R2 Storage   │
└──────────────────────────────────────────────────────┘
```

## Struktur Monorepo

```
debeat-ai/
├── apps/
│   ├── api-gateway/          # Go — Echo v4, sqlc, WebSocket
│   │   ├── cmd/server/       # Entry point
│   │   ├── internal/         # Domain logic (auth, debate, session, ...)
│   │   ├── pkg/              # Shared utilities (config, grpcclient, db, ...)
│   │   ├── db/               # Migrations (Atlas) + sqlc queries
│   │   ├── gen/go/           # Generated gRPC code (jangan diedit)
│   │   └── .env.example
│   │
│   ├── debate-engine/        # Python — gRPC Server, LangChain
│   │   ├── app/
│   │   │   ├── agents/       # opponent.py, judge.py, audience.py
│   │   │   ├── rag/          # retriever.py, embeddings.py, chunker.py
│   │   │   ├── pipelines/    # youtube.py, pdf.py, web.py
│   │   │   ├── servicers/    # debate_servicer.py, knowledge_servicer.py
│   │   │   └── core/         # config.py, ai_factory.py
│   │   ├── gen/python/       # Generated gRPC code (jangan diedit)
│   │   ├── main.py           # gRPC server entry point
│   │   ├── requirements.txt
│   │   └── .env.example
│   │
│   └── admin-panel/          # Next.js — Dashboard admin
│
├── proto/                    # .proto files — single source of truth gRPC contract
│   ├── messages.proto        # Shared message types
│   ├── debate.proto          # DebateEngine service
│   └── knowledge.proto       # KnowledgeBase service
│
├── infra/
│   └── docker-compose.yml    # Local development stack
│
└── scripts/
    ├── generate_proto.sh     # Generate Go + Python gRPC code dari .proto
    └── init.sql              # PostgreSQL init (uuid-ossp + pgvector)
```

## Quick Start (Development)

### 1. Prerequisites

```bash
# Go 1.23+
go version

# Python 3.12+
python --version

# Docker & Docker Compose
docker --version

# protoc (Protocol Buffer compiler)
# macOS:
brew install protobuf
# Windows:
choco install protoc

# Go protoc plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Python grpcio-tools
pip install grpcio-tools
```

### 2. Generate gRPC Code

```bash
# Dari root project
./scripts/generate_proto.sh
```

### 3. Setup Environment

```bash
# API Gateway (Go)
cp apps/api-gateway/.env.example apps/api-gateway/.env
# Edit .env — isi GEMINI_API_KEY minimal

# Debate Engine (Python)
cp apps/debate-engine/.env.example apps/debate-engine/.env
# Edit .env — isi GEMINI_API_KEY minimal
```

### 4. Jalankan dengan Docker Compose

```bash
cd infra
docker compose up --build
```

Service yang berjalan:
| Service | URL |
|---|---|
| API Gateway (Go) | http://localhost:8080 |
| Debate Engine gRPC | localhost:50051 (internal) |
| Admin Panel | http://localhost:3000 |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

### 5. Health Check

```bash
curl http://localhost:8080/health
# → {"status":"ok"}
```

## Protokol Komunikasi

| Layer | Protokol | Keterangan |
|---|---|---|
| Flutter ↔ API Gateway | REST (HTTPS) | Auth, CRUD, session management |
| Flutter ↔ API Gateway | WebSocket (WSS) | Arena debat real-time |
| API Gateway ↔ Debate Engine | **gRPC** | AI orchestration internal |
| API Gateway ↔ Database | PostgreSQL (pgx) | Persistent storage |
| API Gateway ↔ Redis | Redis protocol | Cache, session state, rate limit |
| Debate Engine ↔ AI Providers | HTTPS | Gemini / OpenAI / Anthropic API |

## gRPC Services

### DebateEngine
| Method | Tipe | Fungsi |
|---|---|---|
| `GenerateOpponentResponse` | Unary | AI Lawan non-streaming (fallback) |
| `StreamOpponentResponse` | Server Streaming | AI Lawan token-by-token |
| `ScoreArgument` | Unary | 3 Juri paralel (asyncio.gather) |
| `GenerateAudienceReaction` | Unary | Reaksi penonton |
| `OrchestrateDebate` | **Bidirectional Streaming** | Full arena debat satu koneksi |

### KnowledgeBase
| Method | Tipe | Fungsi |
|---|---|---|
| `SearchKnowledge` | Unary | RAG vector search (pgvector) |
| `GenerateEmbedding` | Unary | Buat vektor 768-dim dari teks |
| `IngestDocument` | Server Streaming | Ingest KB dengan progress update |

## Referensi Dokumen

| Dokumen | Isi |
|---|---|
| [PRD_DebateAI.md](./PRD_DebateAI.md) | Product Requirements Document |
| [Implementation_Plan_DebateAI.md](./Implementation_Plan_DebateAI.md) | Rencana implementasi sprint-by-sprint |
| [Database_Design_Prisma.md](./Database_Design_Prisma.md) | Desain skema database (referensi — implementasi pakai sqlc) |
| [execute_plan.md](./execute_plan.md) | Checklist perbaikan & penambahan dokumen |

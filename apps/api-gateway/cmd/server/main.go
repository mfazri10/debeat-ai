package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/debateai/api-gateway/internal/auth"
	"github.com/debateai/api-gateway/internal/debate"
	"github.com/debateai/api-gateway/internal/knowledge"
	"github.com/debateai/api-gateway/internal/motion"
	"github.com/debateai/api-gateway/internal/persona"
	"github.com/debateai/api-gateway/internal/session"
	"github.com/debateai/api-gateway/internal/template"
	"github.com/debateai/api-gateway/internal/user"
	"github.com/debateai/api-gateway/pkg/config"
	"github.com/debateai/api-gateway/pkg/database"
	"github.com/debateai/api-gateway/pkg/grpcclient"
	"github.com/debateai/api-gateway/pkg/logger"
	"github.com/debateai/api-gateway/pkg/redisclient"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	// ── 1. Load config ──────────────────────────────────────────
	cfg := config.Load()
	log := logger.New(cfg.Env)

	// ── 2. Connect database ─────────────────────────────────────
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect to database")
	}
	defer db.Close()

	// ── 3. Connect Redis ────────────────────────────────────────
	rdb := redisclient.New(cfg.RedisURL)
	defer rdb.Close()

	// ── 4. Connect gRPC clients (Debate Engine) ─────────────────
	grpcClients, err := grpcclient.NewClients(cfg.DebateEngineAddr)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect to debate engine via gRPC")
	}
	defer grpcClients.Close()

	// ── 5. Setup Echo ───────────────────────────────────────────
	e := echo.New()
	e.HideBanner = true

	// Global middleware
	e.Use(middleware.RequestID())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())
	e.Use(middleware.RateLimiter(middleware.NewRateLimiterMemoryStore(100)))

	// ── 6. Register routes ──────────────────────────────────────
	api := e.Group("/v1")

	// Health check
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
	})

	// Auth routes (public)
	authHandler := auth.NewHandler(db, rdb, cfg)
	authGroup := api.Group("/auth")
	authGroup.POST("/register", authHandler.Register)
	authGroup.POST("/login", authHandler.Login)
	authGroup.POST("/google", authHandler.GoogleOAuth)
	authGroup.POST("/refresh", authHandler.RefreshToken)
	authGroup.POST("/logout", authHandler.Logout)

	// Protected routes
	protected := api.Group("")
	protected.Use(auth.JWTMiddleware(cfg.JWTSecret))

	// User routes
	userHandler := user.NewHandler(db, rdb)
	protected.GET("/users/me", userHandler.GetMe)
	protected.PATCH("/users/me", userHandler.UpdateMe)
	protected.GET("/users/me/sessions", userHandler.GetMySessions)
	protected.GET("/users/me/stats", userHandler.GetMyStats)
	protected.DELETE("/auth/account", authHandler.DeleteAccount)
	protected.GET("/users/me/export", userHandler.ExportMyData) // UU PDP compliance

	// Persona routes
	personaHandler := persona.NewHandler(db)
	protected.GET("/personas", personaHandler.List)
	protected.GET("/personas/:id", personaHandler.GetByID)
	protected.POST("/personas", personaHandler.Create)
	protected.PATCH("/personas/:id", personaHandler.Update)
	protected.DELETE("/personas/:id", personaHandler.Delete)

	// Session routes
	sessionHandler := session.NewHandler(db, rdb, grpcClients)
	protected.POST("/sessions", sessionHandler.Create)
	protected.GET("/sessions/:id", sessionHandler.GetByID)
	protected.PATCH("/sessions/:id/start", sessionHandler.Start)
	protected.PATCH("/sessions/:id/pause", sessionHandler.Pause)
	protected.PATCH("/sessions/:id/resume", sessionHandler.Resume)
	protected.PATCH("/sessions/:id/end", sessionHandler.End)
	protected.POST("/sessions/join", sessionHandler.Join)
	protected.GET("/sessions/:id/results", sessionHandler.GetResults)
	protected.GET("/sessions/:id/transcript", sessionHandler.GetTranscript)
	protected.POST("/sessions/:id/arguments", sessionHandler.SubmitArgument)

	// Motion routes
	motionHandler := motion.NewHandler(db.Pool)
	protected.GET("/motions", motionHandler.List)

	// Session template routes
	templateHandler := template.NewHandler(db.Pool)
	protected.GET("/session-templates", templateHandler.List)
	protected.POST("/session-templates", templateHandler.Create)
	protected.DELETE("/session-templates/:id", templateHandler.Delete)

	// Knowledge routes
	knowledgeHandler := knowledge.NewHandler(db, grpcClients)
	protected.GET("/knowledge", knowledgeHandler.Search)
	protected.POST("/knowledge/ingest/youtube", knowledgeHandler.IngestYouTube)
	protected.POST("/knowledge/ingest/pdf", knowledgeHandler.IngestPDF)

	// WebSocket — Arena Debat (real-time)
	debateHub := debate.NewHub(grpcClients)
	go debateHub.Run()

	debateHandler := debate.NewHandler(debateHub, cfg)
	e.GET("/ws/debate/:sessionId", debateHandler.HandleWebSocket,
		auth.JWTMiddlewareWS(cfg.JWTSecret),
	)

	// ── 7. Graceful shutdown ────────────────────────────────────
	ctx, stop := signal.NotifyContext(context.Background(),
		os.Interrupt, syscall.SIGTERM,
	)
	defer stop()

	go func() {
		addr := ":" + cfg.Port
		log.Info().Str("addr", addr).Str("env", cfg.Env).Msg("🚀 DebateAI API Gateway started")
		if err := e.Start(addr); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("server error")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutting down gracefully...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := e.Shutdown(shutdownCtx); err != nil {
		log.Fatal().Err(err).Msg("forced shutdown")
	}
	log.Info().Msg("server stopped")
}

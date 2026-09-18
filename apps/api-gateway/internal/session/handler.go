package session

import (
	"net/http"

	"github.com/debateai/api-gateway/pkg/database"
	"github.com/debateai/api-gateway/pkg/grpcclient"
	"github.com/debateai/api-gateway/pkg/redisclient"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

type Handler struct {
	db          *database.DB
	rdb         *redisclient.Client
	grpcClients *grpcclient.Clients
}

func NewHandler(db *database.DB, rdb *redisclient.Client, grpcClients *grpcclient.Clients) *Handler {
	return &Handler{
		db:          db,
		rdb:         rdb,
		grpcClients: grpcClients,
	}
}

type CreateSessionRequest struct {
	Topic       string `json:"topic" validate:"required"`
	Motion      string `json:"motion"`
	Format      string `json:"format"`
	Language    string `json:"language"`
	Difficulty  string `json:"difficulty"`
	PersonaID   string `json:"persona_id"`
	AIProvider  string `json:"ai_provider"`
}

func (h *Handler) Create(c echo.Context) error {
	var req CreateSessionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	sessionID := uuid.New().String()
	userID := c.Get("user_id").(string)

	return c.JSON(http.StatusCreated, map[string]interface{}{
		"id":         sessionID,
		"topic":      req.Topic,
		"motion":     req.Motion,
		"format":     req.Format,
		"language":   req.Language,
		"status":     "WAITING",
		"hostUserId": userID,
	})
}

func (h *Handler) GetByID(c echo.Context) error {
	id := c.Param("id")
	return c.JSON(http.StatusOK, map[string]interface{}{
		"id":     id,
		"status": "ACTIVE",
	})
}

func (h *Handler) Start(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "STARTED"})
}

func (h *Handler) Pause(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "PAUSED"})
}

func (h *Handler) Resume(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "ACTIVE"})
}

func (h *Handler) End(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "COMPLETED"})
}

func (h *Handler) Join(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "JOINED"})
}

func (h *Handler) GetResults(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]interface{}{
		"winner": "User",
		"score":  84.5,
	})
}

func (h *Handler) GetTranscript(c echo.Context) error {
	return c.JSON(http.StatusOK, []interface{}{})
}

func (h *Handler) SubmitArgument(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "ARGUMENT_SUBMITTED"})
}

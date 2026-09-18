package template

import (
	"context"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type SessionTemplate struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	Name         string    `json:"name"`
	Topic        *string   `json:"topic,omitempty"`
	Category     string    `json:"category"`
	Format       string    `json:"format"`
	TotalRounds  int       `json:"total_rounds"`
	TimePerTurn  int       `json:"time_per_turn"`
	AIProvider   string    `json:"ai_provider"`
	AIDifficulty *string   `json:"ai_difficulty,omitempty"`
	PersonaID    *string   `json:"persona_id,omitempty"`
	IsJudged     bool      `json:"is_judged"`
	HasAudience  bool      `json:"has_audience"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type CreateTemplateRequest struct {
	Name         string  `json:"name"`
	Topic        *string `json:"topic"`
	Category     string  `json:"category"`
	Format       string  `json:"format"`
	TotalRounds  int     `json:"total_rounds"`
	TimePerTurn  int     `json:"time_per_turn"`
	AIProvider   string  `json:"ai_provider"`
	AIDifficulty *string `json:"ai_difficulty"`
	PersonaID    *string `json:"persona_id"`
	IsJudged     *bool   `json:"is_judged"`
	HasAudience  *bool   `json:"has_audience"`
}

type Handler struct {
	db *pgxpool.Pool
}

func NewHandler(db *pgxpool.Pool) *Handler {
	return &Handler{db: db}
}

// List handles GET /session-templates
func (h *Handler) List(c echo.Context) error {
	userID, ok := c.Get("userId").(string)
	if !ok || userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
	}

	ctx := context.Background()
	query := `
		SELECT id, user_id, name, topic, category, format, total_rounds, time_per_turn,
		       ai_provider, ai_difficulty, persona_id, is_judged, has_audience, created_at, updated_at
		FROM session_templates
		WHERE user_id = $1
		ORDER BY created_at DESC
	`
	rows, err := h.db.Query(ctx, query, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to query templates"})
	}
	defer rows.Close()

	templates := make([]SessionTemplate, 0)
	for rows.Next() {
		var t SessionTemplate
		if err := rows.Scan(&t.ID, &t.UserID, &t.Name, &t.Topic, &t.Category, &t.Format,
			&t.TotalRounds, &t.TimePerTurn, &t.AIProvider, &t.AIDifficulty, &t.PersonaID,
			&t.IsJudged, &t.HasAudience, &t.CreatedAt, &t.UpdatedAt); err != nil {
			continue
		}
		templates = append(templates, t)
	}

	return c.JSON(http.StatusOK, map[string]any{
		"templates": templates,
		"count":     len(templates),
	})
}

// Create handles POST /session-templates
func (h *Handler) Create(c echo.Context) error {
	userID, ok := c.Get("userId").(string)
	if !ok || userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
	}

	var req CreateTemplateRequest
	if err := c.Bind(&req); err != nil || req.Name == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "template name is required"})
	}

	if req.Category == "" {
		req.Category = "FREE"
	}
	if req.Format == "" {
		req.Format = "FREE"
	}
	if req.TotalRounds <= 0 {
		req.TotalRounds = 3
	}
	if req.TimePerTurn <= 0 {
		req.TimePerTurn = 300
	}
	if req.AIProvider == "" {
		req.AIProvider = "GEMINI"
	}
	isJudged := true
	if req.IsJudged != nil {
		isJudged = *req.IsJudged
	}
	hasAudience := true
	if req.HasAudience != nil {
		hasAudience = *req.HasAudience
	}

	ctx := context.Background()
	query := `
		INSERT INTO session_templates (
			user_id, name, topic, category, format, total_rounds, time_per_turn,
			ai_provider, ai_difficulty, persona_id, is_judged, has_audience
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, created_at, updated_at
	`
	var id string
	var createdAt, updatedAt time.Time
	err := h.db.QueryRow(ctx, query,
		userID, req.Name, req.Topic, req.Category, req.Format, req.TotalRounds, req.TimePerTurn,
		req.AIProvider, req.AIDifficulty, req.PersonaID, isJudged, hasAudience,
	).Scan(&id, &createdAt, &updatedAt)

	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to create session template"})
	}

	return c.JSON(http.StatusCreated, map[string]any{
		"message": "template created successfully",
		"id":      id,
	})
}

// Delete handles DELETE /session-templates/:id
func (h *Handler) Delete(c echo.Context) error {
	userID, ok := c.Get("userId").(string)
	if !ok || userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
	}

	id := c.Param("id")
	ctx := context.Background()
	res, err := h.db.Exec(ctx, `DELETE FROM session_templates WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to delete template"})
	}
	if res.RowsAffected() == 0 {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "template not found"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "template deleted successfully"})
}

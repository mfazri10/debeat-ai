package motion

import (
	"context"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
)

type Motion struct {
	ID         string    `json:"id"`
	Text       string    `json:"text"`
	Category   string    `json:"category"`
	Format     *string   `json:"format,omitempty"`
	Language   string    `json:"language"`
	Difficulty string    `json:"difficulty"`
	Source     *string   `json:"source,omitempty"`
	UsageCount int       `json:"usage_count"`
	CreatedAt  time.Time `json:"created_at"`
}

type Handler struct {
	db *pgxpool.Pool
}

func NewHandler(db *pgxpool.Pool) *Handler {
	return &Handler{db: db}
}

// List handles GET /motions?category=&language=&format=
func (h *Handler) List(c echo.Context) error {
	category := c.QueryParam("category")
	language := c.QueryParam("language")
	format := c.QueryParam("format")

	query := `
		SELECT id, text, category, format, language, difficulty, source, usage_count, created_at
		FROM debate_motions
		WHERE is_active = TRUE
	`
	args := []any{}
	argIdx := 1

	if category != "" {
		query += ` AND category = $` + itoa(argIdx)
		args = append(args, category)
		argIdx++
	}
	if language != "" {
		query += ` AND language = $` + itoa(argIdx)
		args = append(args, language)
		argIdx++
	}
	if format != "" {
		query += ` AND (format = $` + itoa(argIdx) + ` OR format IS NULL)`
		args = append(args, format)
		argIdx++
	}

	query += ` ORDER BY usage_count DESC, created_at DESC LIMIT 50`

	ctx := context.Background()
	rows, err := h.db.Query(ctx, query, args...)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to query motions"})
	}
	defer rows.Close()

	motions := make([]Motion, 0)
	for rows.Next() {
		var m Motion
		if err := rows.Scan(&m.ID, &m.Text, &m.Category, &m.Format, &m.Language, &m.Difficulty, &m.Source, &m.UsageCount, &m.CreatedAt); err != nil {
			continue
		}
		motions = append(motions, m)
	}

	return c.JSON(http.StatusOK, map[string]any{
		"motions": motions,
		"count":   len(motions),
	})
}

func itoa(i int) string {
	digits := []byte("0123456789")
	if i < 10 {
		return string([]byte{digits[i]})
	}
	return "10"
}

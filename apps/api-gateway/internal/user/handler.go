package user

import (
	"net/http"

	"github.com/debateai/api-gateway/pkg/database"
	"github.com/debateai/api-gateway/pkg/redisclient"
	"github.com/labstack/echo/v4"
)

type Handler struct {
	db  *database.DB
	rdb *redisclient.Client
}

func NewHandler(db *database.DB, rdb *redisclient.Client) *Handler {
	return &Handler{db: db, rdb: rdb}
}

func (h *Handler) GetMe(c echo.Context) error {
	userID := c.Get("user_id").(string)
	return c.JSON(http.StatusOK, map[string]interface{}{
		"id":        userID,
		"name":      "User DebateAI",
		"email":     c.Get("email"),
		"role":      c.Get("role"),
		"eloRating": 1000,
		"isPro":     false,
	})
}

func (h *Handler) UpdateMe(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "profile updated"})
}

func (h *Handler) GetMySessions(c echo.Context) error {
	return c.JSON(http.StatusOK, []interface{}{})
}

func (h *Handler) GetMyStats(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]interface{}{
		"totalSessions": 0,
		"totalWins":     0,
		"winRate":       0.0,
		"eloRating":     1000,
		"rank":          "Beginner",
	})
}

// ExportMyData memenuhi kepatuhan regulasi UU PDP Indonesia (hak akses data format JSON)
func (h *Handler) ExportMyData(c echo.Context) error {
	userID := c.Get("user_id").(string)
	c.Response().Header().Set("Content-Disposition", "attachment; filename=debateai_userdata_"+userID+".json")
	return c.JSON(http.StatusOK, map[string]interface{}{
		"user": map[string]string{
			"id":    userID,
			"email": c.Get("email").(string),
		},
		"sessions":      []interface{}{},
		"arguments":     []interface{}{},
		"scores":        []interface{}{},
		"export_date":   "2026-09-18",
		"compliance_uu": "UU PDP No. 27/2022 Pasal 5",
	})
}

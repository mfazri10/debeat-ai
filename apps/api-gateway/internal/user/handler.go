package user

import (
	"net/http"
	"strconv"
	"strings"
	"time"

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

// GetMe mengembalikan profil user dari database.
func (h *Handler) GetMe(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	var (
		id, email, name, role, preferredLanguage, debateLevel string
		eloRating, totalSessions, totalWins, totalPoints, warningCount int
		isPro bool
		avatarURL, bio *string
		createdAt time.Time
	)
	err := h.db.Pool.QueryRow(ctx, `
		SELECT id, email, name, COALESCE(avatar_url,''), COALESCE(bio,''), preferred_language,
		       debate_level, elo_rating, total_sessions, total_wins, is_pro, role,
		       warning_count, total_points, created_at
		FROM users WHERE id = $1 AND deleted_at IS NULL
	`, userID).Scan(&id, &email, &name, &avatarURL, &bio, &preferredLanguage,
		&debateLevel, &eloRating, &totalSessions, &totalWins, &isPro, &role,
		&warningCount, &totalPoints, &createdAt)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User tidak ditemukan")
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"id":                id,
		"email":             email,
		"name":              name,
		"avatarUrl":         avatarURL,
		"bio":               bio,
		"preferredLanguage": preferredLanguage,
		"debateLevel":       debateLevel,
		"eloRating":         eloRating,
		"totalSessions":     totalSessions,
		"totalWins":         totalWins,
		"isPro":             isPro,
		"role":              role,
		"warningCount":      warningCount,
		"totalPoints":       totalPoints,
		"createdAt":         createdAt,
	})
}

type UpdateMeRequest struct {
	Name              *string `json:"name"`
	Bio               *string `json:"bio"`
	AvatarURL         *string `json:"avatar_url"`
	PreferredLanguage *string `json:"preferred_language"`
}

// UpdateMe memperbarui field profil yang dikirim.
func (h *Handler) UpdateMe(c echo.Context) error {
	userID := c.Get("user_id").(string)
	var req UpdateMeRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	ctx := c.Request().Context()
	sets := []string{}
	args := []any{}
	idx := 1

	if req.Name != nil && strings.TrimSpace(*req.Name) != "" {
		sets = append(sets, "name = $"+itoa(idx))
		args = append(args, strings.TrimSpace(*req.Name))
		idx++
	}
	if req.Bio != nil {
		sets = append(sets, "bio = $"+itoa(idx))
		args = append(args, *req.Bio)
		idx++
	}
	if req.AvatarURL != nil {
		sets = append(sets, "avatar_url = $"+itoa(idx))
		args = append(args, *req.AvatarURL)
		idx++
	}
	if req.PreferredLanguage != nil {
		lang := strings.ToUpper(strings.TrimSpace(*req.PreferredLanguage))
		if lang != "ID" && lang != "EN" {
			return echo.NewHTTPError(http.StatusBadRequest, "preferred_language harus ID atau EN")
		}
		sets = append(sets, "preferred_language = $"+itoa(idx))
		args = append(args, lang)
		idx++
	}
	if len(sets) == 0 {
		return echo.NewHTTPError(http.StatusBadRequest, "Tidak ada field yang diperbarui")
	}

	query := "UPDATE users SET " + strings.Join(sets, ", ") + ", updated_at = NOW() WHERE id = $" + itoa(idx) + " AND deleted_at IS NULL"
	args = append(args, userID)

	res, err := h.db.Pool.Exec(ctx, query, args...)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Gagal memperbarui profil")
	}
	if res.RowsAffected() == 0 {
		return echo.NewHTTPError(http.StatusNotFound, "User tidak ditemukan")
	}
	return c.JSON(http.StatusOK, map[string]string{"status": "profile updated"})
}

// GetMySessions mengembalikan riwayat sesi debat milik user.
func (h *Handler) GetMySessions(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	rows, err := h.db.Pool.Query(ctx, `
		SELECT id, topic, format, category, language, status, total_rounds, current_round,
		       ai_provider, started_at, ended_at, created_at
		FROM debate_sessions
		WHERE host_user_id = $1
		ORDER BY created_at DESC LIMIT 50
	`, userID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Gagal mengambil riwayat sesi")
	}
	defer rows.Close()

	sessions := make([]map[string]interface{}, 0)
	for rows.Next() {
		var id, topic, format, category, language, status, aiProvider string
		var totalRounds, currentRound int
		var startedAt, endedAt *time.Time
		var createdAt time.Time
		if err := rows.Scan(&id, &topic, &format, &category, &language, &status,
			&totalRounds, &currentRound, &aiProvider, &startedAt, &endedAt, &createdAt); err != nil {
			continue
		}
		sessions = append(sessions, map[string]interface{}{
			"id":           id,
			"topic":        topic,
			"format":       format,
			"category":     category,
			"language":     language,
			"status":       status,
			"totalRounds":  totalRounds,
			"currentRound": currentRound,
			"aiProvider":   aiProvider,
			"startedAt":    startedAt,
			"endedAt":      endedAt,
			"createdAt":    createdAt,
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"sessions": sessions,
		"count":    len(sessions),
	})
}

// GetMyStats menghitung statistik personal dari data riil.
func (h *Handler) GetMyStats(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	var totalSessions, totalWins, eloRating, totalPoints int
	err := h.db.Pool.QueryRow(ctx, `
		SELECT total_sessions, total_wins, elo_rating, total_points
		FROM users WHERE id = $1 AND deleted_at IS NULL
	`, userID).Scan(&totalSessions, &totalWins, &eloRating, &totalPoints)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User tidak ditemukan")
	}

	winRate := 0.0
	if totalSessions > 0 {
		winRate = float64(totalWins) / float64(totalSessions) * 100
	}

	// Rata-rata skor juri user di semua sesi
	var avgScore *float64
	_ = h.db.Pool.QueryRow(ctx, `
		SELECT AVG(js.total_score)
		FROM judge_scores js
		JOIN debate_arguments da ON js.argument_id = da.id
		JOIN debate_participants dp ON da.participant_id = dp.id
		WHERE dp.user_id = $1
	`, userID).Scan(&avgScore)

	return c.JSON(http.StatusOK, map[string]interface{}{
		"totalSessions": totalSessions,
		"totalWins":     totalWins,
		"winRate":       float64(int(winRate*10+0.5)) / 10,
		"eloRating":     eloRating,
		"totalPoints":   totalPoints,
		"avgJudgeScore": avgScore,
	})
}

// ExportMyData memenuhi kepatuhan UU PDP No. 27/2022 (hak akses data format JSON).
func (h *Handler) ExportMyData(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	// Profil
	var email, name string
	err := h.db.Pool.QueryRow(ctx,
		`SELECT email, name FROM users WHERE id = $1`, userID).Scan(&email, &name)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User tidak ditemukan")
	}

	// Sesi debat
	sessions := make([]map[string]interface{}, 0)
	rows, err := h.db.Pool.Query(ctx, `
		SELECT id, topic, format, status, created_at FROM debate_sessions
		WHERE host_user_id = $1 ORDER BY created_at
	`, userID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var id, topic, format, status string
			var createdAt time.Time
			if rows.Scan(&id, &topic, &format, &status, &createdAt) == nil {
				sessions = append(sessions, map[string]interface{}{
					"id": id, "topic": topic, "format": format, "status": status, "createdAt": createdAt,
				})
			}
		}
	}

	// Argumen yang pernah dikirim
	arguments := make([]map[string]interface{}, 0)
	rows2, err := h.db.Pool.Query(ctx, `
		SELECT da.id, da.session_id, da.content, da.round_number, da.turn_number, da.created_at
		FROM debate_arguments da
		JOIN debate_participants dp ON da.participant_id = dp.id
		WHERE dp.user_id = $1 ORDER BY da.created_at
	`, userID)
	if err == nil {
		defer rows2.Close()
		for rows2.Next() {
			var id, sessionID, content string
			var round, turn int
			var createdAt time.Time
			if rows2.Scan(&id, &sessionID, &content, &round, &turn, &createdAt) == nil {
				arguments = append(arguments, map[string]interface{}{
					"id": id, "sessionId": sessionID, "content": content,
					"round": round, "turn": turn, "createdAt": createdAt,
				})
			}
		}
	}

	// Skor juri yang diterima
	scores := make([]map[string]interface{}, 0)
	rows3, err := h.db.Pool.Query(ctx, `
		SELECT js.judge_type, js.total_score, js.summary, js.created_at
		FROM judge_scores js
		JOIN debate_arguments da ON js.argument_id = da.id
		JOIN debate_participants dp ON da.participant_id = dp.id
		WHERE dp.user_id = $1 ORDER BY js.created_at
	`, userID)
	if err == nil {
		defer rows3.Close()
		for rows3.Next() {
			var judgeType, summary string
			var totalScore float64
			var createdAt time.Time
			if rows3.Scan(&judgeType, &totalScore, &summary, &createdAt) == nil {
				scores = append(scores, map[string]interface{}{
					"judgeType": judgeType, "totalScore": totalScore,
					"summary": summary, "createdAt": createdAt,
				})
			}
		}
	}

	c.Response().Header().Set("Content-Disposition", "attachment; filename=debateai_userdata_"+userID+".json")
	return c.JSON(http.StatusOK, map[string]interface{}{
		"user": map[string]string{
			"id":    userID,
			"email": email,
			"name":  name,
		},
		"sessions":      sessions,
		"arguments":     arguments,
		"scores":        scores,
		"export_date":   time.Now().Format(time.RFC3339),
		"compliance_uu": "UU PDP No. 27/2022 Pasal 5",
	})
}

func itoa(i int) string {
	return strconv.Itoa(i)
}

package session

import (
	"net/http"
	"strings"

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
	store       *Store
}

func NewHandler(db *database.DB, rdb *redisclient.Client, grpcClients *grpcclient.Clients) *Handler {
	return &Handler{
		db:          db,
		rdb:         rdb,
		grpcClients: grpcClients,
		store:       NewStore(db),
	}
}

type CreateSessionRequest struct {
	Topic       string `json:"topic" validate:"required"`
	Motion      string `json:"motion"`
	Format      string `json:"format"`
	Category    string `json:"category"`
	Language    string `json:"language"`
	Difficulty  string `json:"difficulty"`
	PersonaID   string `json:"persona_id"`
	PersonaName string `json:"persona_name"`
	Stance      string `json:"stance"`
	AIProvider  string `json:"ai_provider"`
	TotalRounds int    `json:"total_rounds"`
	TimePerTurn int    `json:"time_per_turn"`
	IsJudged    *bool  `json:"is_judged"`
	HasAudience *bool  `json:"has_audience"`
}

func defaultStr(s, def string) string {
	if strings.TrimSpace(s) == "" {
		return def
	}
	return strings.ToUpper(strings.TrimSpace(s))
}

// Create membuat sesi debat baru, menyimpan ke DB, dan mendaftarkan partisipan user + AI.
func (h *Handler) Create(c echo.Context) error {
	var req CreateSessionRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}
	if strings.TrimSpace(req.Topic) == "" && strings.TrimSpace(req.Motion) == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "topic atau motion wajib diisi")
	}

	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	topic := req.Topic
	if topic == "" {
		topic = req.Motion
	}

	isJudged := true
	if req.IsJudged != nil {
		isJudged = *req.IsJudged
	}
	hasAudience := true
	if req.HasAudience != nil {
		hasAudience = *req.HasAudience
	}
	totalRounds := req.TotalRounds
	if totalRounds <= 0 {
		totalRounds = 3
	}
	timePerTurn := req.TimePerTurn
	if timePerTurn <= 0 {
		timePerTurn = 300
	}

	sess := &Session{
		ID:          uuid.New().String(),
		Topic:       topic,
		Motion:      &req.Motion,
		Format:      defaultStr(req.Format, "FREE"),
		Category:    defaultStr(req.Category, "FREE"),
		Language:    defaultStr(req.Language, "ID"),
		Status:      "WAITING",
		Mode:        "OFFLINE",
		TotalRounds: totalRounds,
		TimePerTurn: timePerTurn,
		HostUserID:  userID,
		AIProvider:  defaultStr(req.AIProvider, "GEMINI"),
		IsJudged:    isJudged,
		HasAudience: hasAudience,
	}

	if err := h.store.Create(ctx, sess); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal menyimpan sesi: "+err.Error())
	}

	// Partisipan user (host)
	stance := defaultStr(req.Stance, "PRO")
	if _, err := h.store.AddParticipant(ctx, sess.ID, map[string]any{
		"user_id":      userID,
		"persona_id":   nil,
		"persona_name": "Anda",
		"stance":       stance,
		"role":         "HOST",
		"is_ai":        false,
		"ai_difficulty": nil,
	}); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal mendaftarkan partisipan: "+err.Error())
	}

	// Partisipan AI lawan
	personaName := req.PersonaName
	if personaName == "" {
		personaName = "AI Lawan"
	}
	var personaID any
	if req.PersonaID != "" {
		personaID = req.PersonaID
	}
	if _, err := h.store.AddParticipant(ctx, sess.ID, map[string]any{
		"user_id":       nil,
		"persona_id":    personaID,
		"persona_name":  personaName,
		"stance":        oppositeStance(stance),
		"role":          "OPPONENT",
		"is_ai":         true,
		"ai_difficulty": defaultStr(req.Difficulty, "MEDIUM"),
	}); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal mendaftarkan AI: "+err.Error())
	}

	return c.JSON(http.StatusCreated, sess)
}

func oppositeStance(s string) string {
	switch s {
	case "PRO":
		return "CONTRA"
	case "CONTRA":
		return "PRO"
	default:
		return "CONTRA"
	}
}

func (h *Handler) GetByID(c echo.Context) error {
	id := c.Param("id")
	sess, err := h.store.GetByID(c.Request().Context(), id)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "sesi tidak ditemukan")
	}
	return c.JSON(http.StatusOK, sess)
}

func (h *Handler) Start(c echo.Context) error {
	id := c.Param("id")
	if err := h.store.SetStatus(c.Request().Context(), id, "ACTIVE"); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal memulai sesi")
	}
	sess, _ := h.store.GetByID(c.Request().Context(), id)
	return c.JSON(http.StatusOK, sess)
}

func (h *Handler) Pause(c echo.Context) error {
	id := c.Param("id")
	if err := h.store.SetStatus(c.Request().Context(), id, "PAUSED"); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal pause sesi")
	}
	sess, _ := h.store.GetByID(c.Request().Context(), id)
	return c.JSON(http.StatusOK, sess)
}

func (h *Handler) Resume(c echo.Context) error {
	id := c.Param("id")
	if err := h.store.SetStatus(c.Request().Context(), id, "ACTIVE"); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal resume sesi")
	}
	sess, _ := h.store.GetByID(c.Request().Context(), id)
	return c.JSON(http.StatusOK, sess)
}

func (h *Handler) End(c echo.Context) error {
	id := c.Param("id")
	if err := h.store.SetStatus(c.Request().Context(), id, "COMPLETED"); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal mengakhiri sesi")
	}
	sess, _ := h.store.GetByID(c.Request().Context(), id)
	return c.JSON(http.StatusOK, sess)
}

type JoinRequest struct {
	RoomCode string `json:"room_code"`
}

func (h *Handler) Join(c echo.Context) error {
	var req JoinRequest
	if err := c.Bind(&req); err != nil || strings.TrimSpace(req.RoomCode) == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "room_code wajib diisi")
	}
	sess, err := h.store.GetByRoomCode(c.Request().Context(), strings.ToUpper(strings.TrimSpace(req.RoomCode)))
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "room tidak ditemukan")
	}
	return c.JSON(http.StatusOK, sess)
}

// GetResults mengembalikan hasil akhir sesi (skor agregat juri + reaksi penonton).
func (h *Handler) GetResults(c echo.Context) error {
	id := c.Param("id")
	ctx := c.Request().Context()

	rows, err := h.db.Pool.Query(ctx, `
		SELECT judge_type, AVG(argument_strength), AVG(fact_data_usage), AVG(rhetoric_technique),
		       AVG(responsiveness), AVG(clarity_structure), AVG(total_score), COUNT(*)
		FROM judge_scores WHERE session_id = $1 GROUP BY judge_type
	`, id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal mengambil hasil")
	}
	defer rows.Close()

	judges := make([]map[string]any, 0)
	var overall float64
	var n int
	for rows.Next() {
		var jt string
		var as, fd, rt, rs, cs, ts float64
		var cnt int
		if err := rows.Scan(&jt, &as, &fd, &rt, &rs, &cs, &ts, &cnt); err != nil {
			continue
		}
		judges = append(judges, map[string]any{
			"judgeType":          jt,
			"argumentStrength":   round2(as),
			"factDataUsage":      round2(fd),
			"rhetoricTechnique":  round2(rt),
			"responsiveness":     round2(rs),
			"clarityStructure":   round2(cs),
			"totalScore":         round2(ts),
			"evaluatedArguments": cnt,
		})
		overall += ts
		n++
	}
	if n > 0 {
		overall = overall / float64(n)
	}

	return c.JSON(http.StatusOK, map[string]any{
		"sessionId":      id,
		"judges":         judges,
		"overallScore":   round2(overall),
	})
}

func round2(f float64) float64 {
	return float64(int(f*100+0.5)) / 100
}

// GetTranscript mengembalikan seluruh argumen dalam sesi secara berurutan.
func (h *Handler) GetTranscript(c echo.Context) error {
	id := c.Param("id")
	ctx := c.Request().Context()

	rows, err := h.db.Pool.Query(ctx, `
		SELECT a.id, a.content, a.content_type, a.round_number, a.turn_number, a.created_at,
		       p.persona_name, p.is_ai
		FROM debate_arguments a
		JOIN debate_participants p ON a.participant_id = p.id
		WHERE a.session_id = $1
		ORDER BY a.round_number, a.turn_number, a.created_at
	`, id)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal mengambil transkrip")
	}
	defer rows.Close()

	transcript := make([]map[string]any, 0)
	for rows.Next() {
		var argID, content, contentType, speaker string
		var round, turn int
		var createdAt any
		var isAI bool
		if err := rows.Scan(&argID, &content, &contentType, &round, &turn, &createdAt, &speaker, &isAI); err != nil {
			continue
		}
		transcript = append(transcript, map[string]any{
			"id":          argID,
			"speaker":     speaker,
			"isAi":        isAI,
			"content":     content,
			"contentType": contentType,
			"round":       round,
			"turn":        turn,
			"createdAt":   createdAt,
		})
	}

	return c.JSON(http.StatusOK, map[string]any{
		"sessionId":  id,
		"transcript": transcript,
		"count":      len(transcript),
	})
}

type SubmitArgumentRequest struct {
	Content     string `json:"content" validate:"required"`
	ContentType string `json:"content_type"`
}

// SubmitArgument menyimpan argumen user (jalur REST non-WebSocket).
func (h *Handler) SubmitArgument(c echo.Context) error {
	id := c.Param("id")
	var req SubmitArgumentRequest
	if err := c.Bind(&req); err != nil || strings.TrimSpace(req.Content) == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "content wajib diisi")
	}

	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	participantID, err := h.store.GetUserParticipantID(ctx, id, userID)
	if err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "Anda bukan partisipan sesi ini")
	}

	round, turn, _ := h.store.IncrementTurn(ctx, id)
	contentType := defaultStr(req.ContentType, "TEXT")

	argID, err := h.store.InsertArgument(ctx, id, participantID, req.Content, contentType, round, turn, nil)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "gagal menyimpan argumen")
	}

	return c.JSON(http.StatusCreated, map[string]any{
		"id":    argID,
		"round": round,
		"turn":  turn,
	})
}

package session

import (
	"context"
	"time"

	"github.com/debateai/api-gateway/pkg/database"
	"github.com/jackc/pgx/v5"
)

// Session merepresentasikan satu sesi debat (baris tabel debate_sessions).
type Session struct {
	ID           string     `json:"id"`
	Title        *string    `json:"title,omitempty"`
	Topic        string     `json:"topic"`
	Motion       *string    `json:"motion,omitempty"`
	Format       string     `json:"format"`
	Category     string     `json:"category"`
	Language     string     `json:"language"`
	Status       string     `json:"status"`
	Mode         string     `json:"mode"`
	TotalRounds  int        `json:"totalRounds"`
	CurrentRound int        `json:"currentRound"`
	CurrentTurn  int        `json:"currentTurn"`
	TimePerTurn  int        `json:"timePerTurn"`
	HostUserID   string     `json:"hostUserId"`
	RoomCode     *string    `json:"roomCode,omitempty"`
	AIProvider   string     `json:"aiProvider"`
	IsJudged     bool       `json:"isJudged"`
	HasAudience  bool       `json:"hasAudience"`
	StartedAt    *time.Time `json:"startedAt,omitempty"`
	EndedAt      *time.Time `json:"endedAt,omitempty"`
	CreatedAt    time.Time  `json:"createdAt"`
}

// Store menyediakan akses persistence untuk sesi debat.
type Store struct {
	db *database.DB
}

// NewStore membuat Store baru.
func NewStore(db *database.DB) *Store {
	return &Store{db: db}
}

const sessionColumns = `id, title, topic, motion, format, category, language, status, mode,
	total_rounds, current_round, current_turn, time_per_turn, host_user_id, room_code,
	ai_provider, is_judged, has_audience, started_at, ended_at, created_at`

func scanSession(row pgx.Row) (*Session, error) {
	var s Session
	err := row.Scan(&s.ID, &s.Title, &s.Topic, &s.Motion, &s.Format, &s.Category, &s.Language,
		&s.Status, &s.Mode, &s.TotalRounds, &s.CurrentRound, &s.CurrentTurn, &s.TimePerTurn,
		&s.HostUserID, &s.RoomCode, &s.AIProvider, &s.IsJudged, &s.HasAudience,
		&s.StartedAt, &s.EndedAt, &s.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// Create menyimpan sesi debat baru ke database.
func (st *Store) Create(ctx context.Context, s *Session) error {
	query := `
		INSERT INTO debate_sessions (
			id, title, topic, motion, format, category, language, status, mode,
			total_rounds, current_round, current_turn, time_per_turn, host_user_id,
			room_code, ai_provider, is_judged, has_audience
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,1,1,$11,$12,$13,$14,$15,$16)
	`
	_, err := st.db.Pool.Exec(ctx, query,
		s.ID, s.Title, s.Topic, s.Motion, s.Format, s.Category, s.Language, s.Status, s.Mode,
		s.TotalRounds, s.TimePerTurn, s.HostUserID, s.RoomCode, s.AIProvider, s.IsJudged, s.HasAudience,
	)
	return err
}

// GetByID mengambil sesi berdasarkan ID.
func (st *Store) GetByID(ctx context.Context, id string) (*Session, error) {
	row := st.db.Pool.QueryRow(ctx, `SELECT `+sessionColumns+` FROM debate_sessions WHERE id = $1`, id)
	return scanSession(row)
}

// GetByRoomCode mengambil sesi berdasarkan kode room (mode online).
func (st *Store) GetByRoomCode(ctx context.Context, code string) (*Session, error) {
	row := st.db.Pool.QueryRow(ctx, `SELECT `+sessionColumns+` FROM debate_sessions WHERE room_code = $1`, code)
	return scanSession(row)
}

// SetStatus mengubah status sesi (ACTIVE, PAUSED, COMPLETED, CANCELLED).
func (st *Store) SetStatus(ctx context.Context, id, status string) error {
	var set string
	switch status {
	case "ACTIVE":
		set = "status = 'ACTIVE', started_at = COALESCE(started_at, NOW())"
	case "COMPLETED", "CANCELLED":
		set = "status = '" + status + "', ended_at = NOW()"
	default:
		set = "status = '" + status + "'"
	}
	_, err := st.db.Pool.Exec(ctx, `UPDATE debate_sessions SET `+set+`, updated_at = NOW() WHERE id = $1`, id)
	return err
}

// ListByUser mengambil daftar sesi milik user (host), terbaru dulu.
func (st *Store) ListByUser(ctx context.Context, userID string, limit int) ([]Session, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	rows, err := st.db.Pool.Query(ctx,
		`SELECT `+sessionColumns+` FROM debate_sessions WHERE host_user_id = $1 ORDER BY created_at DESC LIMIT $2`,
		userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	sessions := make([]Session, 0)
	for rows.Next() {
		s, err := scanSession(rows)
		if err != nil {
			continue
		}
		sessions = append(sessions, *s)
	}
	return sessions, nil
}

// AddParticipant menambah partisipan (user atau AI) ke sesi. Return participant ID.
func (st *Store) AddParticipant(ctx context.Context, sessionID string, p map[string]any) (string, error) {
	var id string
	err := st.db.Pool.QueryRow(ctx, `
		INSERT INTO debate_participants (session_id, user_id, persona_id, persona_name, stance, role, is_ai, ai_difficulty, join_order)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8, COALESCE((SELECT MAX(join_order) FROM debate_participants WHERE session_id = $1), 0) + 1)
		RETURNING id
	`,
		sessionID, p["user_id"], p["persona_id"], p["persona_name"], p["stance"], p["role"], p["is_ai"], p["ai_difficulty"],
	).Scan(&id)
	return id, err
}

// GetAIParticipant mengambil partisipan AI untuk sesi (untuk orkestrasi).
func (st *Store) GetAIParticipant(ctx context.Context, sessionID string) (personaID, personaName, stance, difficulty *string, err error) {
	err = st.db.Pool.QueryRow(ctx, `
		SELECT persona_id, persona_name, stance, ai_difficulty
		FROM debate_participants WHERE session_id = $1 AND is_ai = TRUE LIMIT 1
	`, sessionID).Scan(&personaID, &personaName, &stance, &difficulty)
	return
}

// GetPersonaDetail mengambil detail persona untuk dikirim ke engine.
func (st *Store) GetPersonaDetail(ctx context.Context, personaID string) (name, description, speakingStyle, stance *string, err error) {
	err = st.db.Pool.QueryRow(ctx, `
		SELECT name, description, speaking_style, stance_default FROM personas WHERE id = $1
	`, personaID).Scan(&name, &description, &speakingStyle, &stance)
	return
}

// InsertArgument menyimpan argumen (user atau AI) ke tabel debate_arguments.
func (st *Store) InsertArgument(ctx context.Context, sessionID, participantID, content, contentType string, round, turn int, kbRefs any) (string, error) {
	var id string
	err := st.db.Pool.QueryRow(ctx, `
		INSERT INTO debate_arguments (session_id, participant_id, content, content_type, round_number, turn_number, kb_refs)
		VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id
	`, sessionID, participantID, content, contentType, round, turn, kbRefs).Scan(&id)
	return id, err
}

// GetUserParticipantID mengambil participant ID user pada sesi.
func (st *Store) GetUserParticipantID(ctx context.Context, sessionID, userID string) (string, error) {
	var id string
	err := st.db.Pool.QueryRow(ctx, `
		SELECT id FROM debate_participants WHERE session_id = $1 AND user_id = $2 AND is_ai = FALSE LIMIT 1
	`, sessionID, userID).Scan(&id)
	return id, err
}

// IncrementTurn menambah giliran berjalan.
func (st *Store) IncrementTurn(ctx context.Context, sessionID string) (round, turn int, err error) {
	err = st.db.Pool.QueryRow(ctx, `
		UPDATE debate_sessions
		SET current_turn = current_turn + 1, updated_at = NOW()
		WHERE id = $1
		RETURNING current_round, current_turn
	`, sessionID).Scan(&round, &turn)
	return
}

// InsertJudgeScore menyimpan skor satu juri.
func (st *Store) InsertJudgeScore(ctx context.Context, sessionID, argumentID string, j map[string]any) error {
	_, err := st.db.Pool.Exec(ctx, `
		INSERT INTO judge_scores (session_id, argument_id, judge_type, argument_strength, fact_data_usage,
			rhetoric_technique, responsiveness, clarity_structure, total_score, summary,
			highlights_positive, highlights_negative, fallacy_detected, suggestion)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
	`,
		sessionID, argumentID, j["judge_type"], j["argument_strength"], j["fact_data_usage"],
		j["rhetoric_technique"], j["responsiveness"], j["clarity_structure"], j["total_score"], j["summary"],
		j["highlights_positive"], j["highlights_negative"], j["fallacy_detected"], j["suggestion"],
	)
	return err
}

// InsertAudienceReaction menyimpan reaksi penonton.
func (st *Store) InsertAudienceReaction(ctx context.Context, sessionID, argumentID, reactionType string, intensity int, comments any) error {
	_, err := st.db.Pool.Exec(ctx, `
		INSERT INTO audience_reactions (session_id, argument_id, reaction_type, intensity, comments)
		VALUES ($1,$2,$3,$4,$5)
	`, sessionID, argumentID, reactionType, intensity, comments)
	return err
}
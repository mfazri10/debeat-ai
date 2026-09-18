-- ============================================================
-- DebateAI Initial Database Schema
-- PostgreSQL 16 + pgvector (768 dimensions)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- 1. USERS & AUTH
CREATE TABLE IF NOT EXISTS users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email               VARCHAR(255) UNIQUE NOT NULL,
    password_hash       VARCHAR(255),
    name                VARCHAR(100) NOT NULL,
    avatar_url          TEXT,
    bio                 TEXT,
    preferred_language  VARCHAR(5) DEFAULT 'ID',
    debate_level        VARCHAR(20) DEFAULT 'BEGINNER',
    elo_rating          INTEGER DEFAULT 1000,
    total_sessions      INTEGER DEFAULT 0,
    total_wins          INTEGER DEFAULT 0,
    is_pro              BOOLEAN DEFAULT FALSE,
    role                VARCHAR(20) DEFAULT 'USER', -- USER, ADMIN, SUPERADMIN
    warning_count       INTEGER DEFAULT 0,
    is_banned           BOOLEAN DEFAULT FALSE,
    is_suspended        BOOLEAN DEFAULT FALSE,
    suspended_until     TIMESTAMPTZ,
    banned_at           TIMESTAMPTZ,
    total_points        INTEGER DEFAULT 0,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS oauth_providers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider    VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, provider_id)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PERSONAS
CREATE TABLE IF NOT EXISTS personas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    description     TEXT NOT NULL,
    speaking_style  TEXT,
    stance_default  VARCHAR(20),
    language        VARCHAR(5) DEFAULT 'ID',
    avatar_url      TEXT,
    is_template     BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3. DEBATE SESSIONS
CREATE TABLE IF NOT EXISTS debate_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255),
    topic           TEXT NOT NULL,
    motion          TEXT,
    format          VARCHAR(30) DEFAULT 'FREE', -- OXFORD, KDMI, BP, NUDC, INTERVIEW, FREE
    category        VARCHAR(30) DEFAULT 'FREE', -- POLITICS, LAW, ECONOMY, SOCIAL, TECHNOLOGY, EDUCATION, ENVIRONMENT, FREE
    language        VARCHAR(5) DEFAULT 'ID',
    status          VARCHAR(20) DEFAULT 'WAITING', -- WAITING, ACTIVE, PAUSED, COMPLETED, CANCELLED
    mode            VARCHAR(10) DEFAULT 'OFFLINE', -- OFFLINE, ONLINE
    total_rounds    INTEGER DEFAULT 3,
    current_round   INTEGER DEFAULT 1,
    current_turn    INTEGER DEFAULT 1,
    time_per_turn   INTEGER DEFAULT 300,
    host_user_id    UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    room_code       VARCHAR(8) UNIQUE,
    ai_provider     VARCHAR(20) DEFAULT 'GEMINI',
    is_judged       BOOLEAN DEFAULT TRUE,
    has_audience    BOOLEAN DEFAULT TRUE,
    started_at      TIMESTAMPTZ,
    ended_at        TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS debate_participants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES debate_sessions(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    persona_id      UUID REFERENCES personas(id) ON DELETE SET NULL,
    persona_name    VARCHAR(100) NOT NULL,
    stance          VARCHAR(20) NOT NULL, -- PRO, CONTRA, NEUTRAL
    role            VARCHAR(30) DEFAULT 'HOST',
    is_ai           BOOLEAN DEFAULT FALSE,
    ai_difficulty   VARCHAR(20),
    join_order      INTEGER DEFAULT 1,
    last_active_at  TIMESTAMPTZ,
    joined_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS debate_arguments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES debate_sessions(id) ON DELETE CASCADE,
    participant_id  UUID NOT NULL REFERENCES debate_participants(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,
    content_type    VARCHAR(20) DEFAULT 'TEXT',
    audio_url       TEXT,
    round_number    INTEGER NOT NULL,
    turn_number     INTEGER NOT NULL,
    duration_sec    INTEGER,
    kb_refs         JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS judge_scores (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES debate_sessions(id) ON DELETE CASCADE,
    argument_id         UUID NOT NULL REFERENCES debate_arguments(id) ON DELETE CASCADE,
    judge_type          VARCHAR(20) NOT NULL, -- LOGIKA, RETORIKA, DAMPAK
    argument_strength   INTEGER NOT NULL,
    fact_data_usage     INTEGER NOT NULL,
    rhetoric_technique  INTEGER NOT NULL,
    responsiveness      INTEGER NOT NULL,
    clarity_structure   INTEGER NOT NULL,
    total_score         NUMERIC(5,2) NOT NULL,
    summary             TEXT NOT NULL,
    highlights_positive JSONB,
    highlights_negative JSONB,
    fallacy_detected    VARCHAR(100),
    suggestion          TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audience_reactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES debate_sessions(id) ON DELETE CASCADE,
    argument_id     UUID NOT NULL REFERENCES debate_arguments(id) ON DELETE CASCADE,
    reaction_type   VARCHAR(30) NOT NULL, -- APPLAUSE, BOO, NEUTRAL, EXCITED, SKEPTICAL
    intensity       INTEGER DEFAULT 50,
    comments        JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS session_results (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id              UUID UNIQUE NOT NULL REFERENCES debate_sessions(id) ON DELETE CASCADE,
    winner_participant_id   UUID REFERENCES debate_participants(id),
    is_draw                 BOOLEAN DEFAULT FALSE,
    final_scores            JSONB NOT NULL,
    summary                 TEXT,
    key_moments             JSONB,
    suggestions             JSONB,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

-- 4. KNOWLEDGE BASE (pgvector 768)
CREATE TABLE IF NOT EXISTS kb_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(500) NOT NULL,
    source_type     VARCHAR(20) NOT NULL, -- YOUTUBE, PDF, WEB, MANUAL
    source_url      TEXT,
    language        VARCHAR(5) DEFAULT 'ID',
    topic_tags      TEXT[],
    persona_tags    TEXT[],
    total_chunks    INTEGER DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    ingested_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kb_chunks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     UUID NOT NULL REFERENCES kb_documents(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,
    content_hash    VARCHAR(64) UNIQUE NOT NULL,
    chunk_index     INTEGER NOT NULL,
    embedding       vector(768),
    token_count     INTEGER,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 5. MONETISASI, AUDIT, MODERASI & QUOTA
CREATE TABLE IF NOT EXISTS subscriptions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan                    VARCHAR(20) NOT NULL,
    status                  VARCHAR(20) DEFAULT 'PENDING',
    midtrans_order_id       VARCHAR(100) UNIQUE,
    midtrans_transaction_id VARCHAR(100),
    current_period_start    TIMESTAMPTZ NOT NULL,
    current_period_end      TIMESTAMPTZ NOT NULL,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_usage_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID,
    provider        VARCHAR(20) NOT NULL,
    model_name      VARCHAR(100) NOT NULL,
    prompt_tokens   INTEGER NOT NULL,
    comp_tokens     INTEGER NOT NULL,
    total_cost_usd  NUMERIC(10,6) NOT NULL,
    purpose         VARCHAR(50) NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS elo_histories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id  UUID NOT NULL,
    old_rating  INTEGER NOT NULL,
    new_rating  INTEGER NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       VARCHAR(500) UNIQUE NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kb_submissions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    source_url  TEXT NOT NULL,
    description TEXT,
    status      VARCHAR(20) DEFAULT 'PENDING',
    reviewer_id UUID REFERENCES users(id),
    review_note TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID NOT NULL REFERENCES users(id),
    action      VARCHAR(100) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id   UUID,
    metadata    JSONB,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id     UUID NOT NULL REFERENCES users(id),
    reported_id     UUID REFERENCES users(id),
    session_id      UUID,
    argument_id     UUID,
    reason          VARCHAR(30) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) DEFAULT 'PENDING',
    reviewed_by_id  UUID REFERENCES users(id),
    reviewed_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_daily_usage (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    usage_date      DATE NOT NULL,
    session_count   INTEGER DEFAULT 0,
    ai_call_count   INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, usage_date)
);

CREATE TABLE IF NOT EXISTS debate_motions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text            TEXT NOT NULL,
    category        VARCHAR(50) NOT NULL,
    format          VARCHAR(30),
    language        VARCHAR(5) DEFAULT 'ID',
    difficulty      VARCHAR(20) DEFAULT 'MEDIUM',
    source          VARCHAR(100),
    is_active       BOOLEAN DEFAULT TRUE,
    usage_count     INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS session_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    topic           TEXT,
    category        VARCHAR(50) DEFAULT 'FREE',
    format          VARCHAR(30) DEFAULT 'FREE',
    total_rounds    INTEGER DEFAULT 3,
    time_per_turn   INTEGER DEFAULT 300,
    ai_provider     VARCHAR(20) DEFAULT 'GEMINI',
    ai_difficulty   VARCHAR(20),
    persona_id      UUID REFERENCES personas(id) ON DELETE SET NULL,
    is_judged       BOOLEAN DEFAULT TRUE,
    has_audience    BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS badges (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(50) UNIQUE NOT NULL,
    name            VARCHAR(100) NOT NULL,
    description     TEXT NOT NULL,
    icon_url        TEXT,
    category        VARCHAR(50) DEFAULT 'general',
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_badges (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id        UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at       TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_elo ON users(elo_rating);
CREATE INDEX IF NOT EXISTS idx_sessions_host ON debate_sessions(host_user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON debate_sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_room_code ON debate_sessions(room_code);
CREATE INDEX IF NOT EXISTS idx_sessions_category ON debate_sessions(category);
CREATE INDEX IF NOT EXISTS idx_arguments_session ON debate_arguments(session_id, turn_number);
CREATE INDEX IF NOT EXISTS idx_judge_scores_arg ON judge_scores(argument_id);
CREATE INDEX IF NOT EXISTS idx_audience_reactions_arg ON audience_reactions(argument_id);
CREATE INDEX IF NOT EXISTS idx_daily_usage_date ON user_daily_usage(usage_date);
CREATE INDEX IF NOT EXISTS idx_motions_category_lang ON debate_motions(category, language);
CREATE INDEX IF NOT EXISTS idx_motions_active ON debate_motions(is_active);
CREATE INDEX IF NOT EXISTS idx_session_templates_user ON session_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);

-- IVFFlat Index untuk pgvector (cosine similarity)
CREATE INDEX IF NOT EXISTS idx_kb_chunks_embedding
    ON kb_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

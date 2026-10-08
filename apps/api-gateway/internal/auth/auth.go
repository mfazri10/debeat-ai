package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"strings"
	"time"

	"github.com/debateai/api-gateway/pkg/config"
	"github.com/debateai/api-gateway/pkg/database"
	"github.com/debateai/api-gateway/pkg/redisclient"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
)

type Claims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

type Handler struct {
	db  *database.DB
	rdb *redisclient.Client
	cfg *config.Config
}

func NewHandler(db *database.DB, rdb *redisclient.Client, cfg *config.Config) *Handler {
	return &Handler{
		db:  db,
		rdb: rdb,
		cfg: cfg,
	}
}

type RegisterRequest struct {
	Name     string `json:"name" validate:"required,min=2,max=100"`
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

// Register membuat akun baru dengan password ter-hash bcrypt.
func (h *Handler) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	if len(req.Password) < 8 {
		return echo.NewHTTPError(http.StatusBadRequest, "Password minimal 8 karakter")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to hash password")
	}

	newUserID := uuid.New().String()
	ctx := c.Request().Context()

	query := `
		INSERT INTO users (id, name, email, password_hash, role, created_at, updated_at)
		VALUES ($1, $2, $3, $4, 'USER', NOW(), NOW())
		RETURNING id;
	`
	var id string
	err = h.db.Pool.QueryRow(ctx, query, newUserID, strings.TrimSpace(req.Name), req.Email, string(hashedPassword)).Scan(&id)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			return echo.NewHTTPError(http.StatusConflict, "Email sudah terdaftar")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Gagal membuat akun")
	}

	tokens, err := h.generateTokens(c, id, req.Email, "USER")
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate auth tokens")
	}

	return c.JSON(http.StatusCreated, tokens)
}

// Login memverifikasi kredensial dan menerbitkan access + refresh token.
func (h *Handler) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	ctx := c.Request().Context()
	var id, email, role string
	var passwordHash *string
	var isBanned, isSuspended bool

	query := `SELECT id, email, password_hash, role, is_banned, is_suspended
	          FROM users WHERE email = $1 AND deleted_at IS NULL LIMIT 1;`
	err := h.db.Pool.QueryRow(ctx, query, req.Email).Scan(&id, &email, &passwordHash, &role, &isBanned, &isSuspended)
	if err == pgx.ErrNoRows {
		return echo.NewHTTPError(http.StatusUnauthorized, "Email atau password salah")
	}
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Gagal memproses login")
	}
	if isBanned {
		return echo.NewHTTPError(http.StatusForbidden, "Akun Anda telah diblokir")
	}
	if isSuspended {
		return echo.NewHTTPError(http.StatusForbidden, "Akun Anda sedang ditangguhkan")
	}
	if passwordHash == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Email atau password salah")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(*passwordHash), []byte(req.Password)); err != nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Email atau password salah")
	}

	tokens, err := h.generateTokens(c, id, email, role)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate tokens")
	}

	return c.JSON(http.StatusOK, tokens)
}

// GoogleOAuth — placeholder terstruktur: verifikasi ID token Google.
// TODO(integrasi): verifikasi via google.golang.org/api/oauth2/v2 dengan GOOGLE_CLIENT_ID.
func (h *Handler) GoogleOAuth(c echo.Context) error {
	return echo.NewHTTPError(http.StatusNotImplemented, "Google OAuth belum dikonfigurasi di server ini")
}

// RefreshToken memvalidasi refresh token (hash di DB), rotasi token, dan hapus yang lama.
func (h *Handler) RefreshToken(c echo.Context) error {
	var req RefreshRequest
	if err := c.Bind(&req); err != nil || strings.TrimSpace(req.RefreshToken) == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "refresh_token wajib diisi")
	}

	ctx := c.Request().Context()
	tokenHash := hashToken(req.RefreshToken)

	var userID, email, role string
	var tokenID string
	err := h.db.Pool.QueryRow(ctx, `
		DELETE FROM refresh_tokens
		WHERE id = (
			SELECT id FROM refresh_tokens
			WHERE token_hash = $1 AND expires_at > NOW()
			LIMIT 1
		)
		RETURNING id, user_id
	`, tokenHash).Scan(&tokenID, &userID)
	if err != nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Refresh token tidak valid atau kedaluwarsa")
	}

	err = h.db.Pool.QueryRow(ctx,
		`SELECT email, role FROM users WHERE id = $1 AND deleted_at IS NULL`, userID,
	).Scan(&email, &role)
	if err != nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "User tidak ditemukan")
	}

	tokens, err := h.generateTokens(c, userID, email, role)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to refresh token")
	}
	return c.JSON(http.StatusOK, tokens)
}

// Logout menghapus refresh token dari DB (invalidasi sisi server).
func (h *Handler) Logout(c echo.Context) error {
	var req RefreshRequest
	_ = c.Bind(&req)
	if strings.TrimSpace(req.RefreshToken) != "" {
		ctx := c.Request().Context()
		_, _ = h.db.Pool.Exec(ctx, `DELETE FROM refresh_tokens WHERE token_hash = $1`, hashToken(req.RefreshToken))
	}
	return c.JSON(http.StatusOK, map[string]string{"message": "Logged out successfully"})
}

// DeleteAccount melakukan soft-delete akun sesuai UU PDP (data di-null-kan, deleted_at diset).
func (h *Handler) DeleteAccount(c echo.Context) error {
	userID := c.Get("user_id").(string)
	ctx := c.Request().Context()

	res, err := h.db.Pool.Exec(ctx, `
		UPDATE users SET
			deleted_at = NOW(),
			email = 'deleted-' || id || '@deleted.invalid',
			password_hash = NULL,
			name = 'Pengguna Terhapus',
			avatar_url = NULL,
			bio = NULL
		WHERE id = $1 AND deleted_at IS NULL
	`, userID)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Gagal menghapus akun")
	}
	if res.RowsAffected() == 0 {
		return echo.NewHTTPError(http.StatusNotFound, "Akun tidak ditemukan")
	}
	return c.JSON(http.StatusOK, map[string]string{"message": "Account soft-deleted per UU PDP"})
}

// generateTokens membuat access token JWT + refresh token opaque (hash disimpan di DB).
func (h *Handler) generateTokens(c echo.Context, userID, email, role string) (*TokenResponse, error) {
	expiry := time.Duration(h.cfg.JWTExpiryMinutes) * time.Minute
	if expiry <= 0 {
		expiry = 15 * time.Minute
	}
	exp := time.Now().Add(expiry)
	claims := &Claims{
		UserID: userID,
		Email:  email,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(exp),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "debateai-gateway",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(h.cfg.JWTSecret))
	if err != nil {
		return nil, err
	}

	// Refresh token opaque acak 32 byte; hanya hash-nya yang disimpan
	refreshToken, err := randomToken(32)
	if err != nil {
		return nil, err
	}

	refreshDays := h.cfg.RefreshExpiryDays
	if refreshDays <= 0 {
		refreshDays = 30
	}
	ctx := c.Request().Context()
	_, err = h.db.Pool.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, NOW() + make_interval(days => $3))
	`, userID, hashToken(refreshToken), refreshDays)
	if err != nil {
		return nil, err
	}

	return &TokenResponse{
		AccessToken:  tokenString,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(expiry.Seconds()),
	}, nil
}

func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func randomToken(n int) (string, error) {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

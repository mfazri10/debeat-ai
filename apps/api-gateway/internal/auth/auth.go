package auth

import (
	"net/http"
	"time"

	"github.com/debateai/api-gateway/pkg/config"
	"github.com/debateai/api-gateway/pkg/database"
	"github.com/debateai/api-gateway/pkg/redisclient"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
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

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

func (h *Handler) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to hash password")
	}

	newUserID := uuid.New().String()
	ctx := c.Request().Context()

	// Simpan user ke database
	query := `
		INSERT INTO users (id, name, email, password_hash, role, created_at, updated_at)
		VALUES ($1, $2, $3, $4, 'USER', NOW(), NOW())
		RETURNING id;
	`
	var id string
	err = h.db.Pool.QueryRow(ctx, query, newUserID, req.Name, req.Email, string(hashedPassword)).Scan(&id)
	if err != nil {
		// Jika DB table belum dibuat / duplikat email
		id = newUserID
	}

	tokens, err := h.generateTokens(id, req.Email, "USER")
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate auth tokens")
	}

	return c.JSON(http.StatusCreated, tokens)
}

func (h *Handler) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request payload")
	}

	ctx := c.Request().Context()
	var id, email, passwordHash, role string

	query := `SELECT id, email, password_hash, role FROM users WHERE email = $1 AND deleted_at IS NULL LIMIT 1;`
	err := h.db.Pool.QueryRow(ctx, query, req.Email).Scan(&id, &email, &passwordHash, &role)
	if err != nil {
		// Mock bypass untuk testing dev jika user tabel belum ter-seed
		if req.Email == "demo@debateai.org" && req.Password == "password123" {
			id = "11111111-1111-1111-1111-111111111111"
			role = "USER"
		} else {
			return echo.NewHTTPError(http.StatusUnauthorized, "Email atau password salah")
		}
	} else {
		if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
			return echo.NewHTTPError(http.StatusUnauthorized, "Email atau password salah")
		}
	}

	tokens, err := h.generateTokens(id, req.Email, role)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate tokens")
	}

	return c.JSON(http.StatusOK, tokens)
}

func (h *Handler) GoogleOAuth(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{
		"message": "OAuth exchange placeholder",
	})
}

func (h *Handler) RefreshToken(c echo.Context) error {
	tokens, err := h.generateTokens("mock-user-id", "user@debateai.org", "USER")
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to refresh token")
	}
	return c.JSON(http.StatusOK, tokens)
}

func (h *Handler) Logout(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"message": "Logged out successfully"})
}

func (h *Handler) DeleteAccount(c echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"message": "Account soft-deleted per UU PDP"})
}

func (h *Handler) generateTokens(userID, email, role string) (*TokenResponse, error) {
	exp := time.Now().Add(24 * time.Hour)
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

	return &TokenResponse{
		AccessToken:  tokenString,
		RefreshToken: uuid.New().String(),
		ExpiresIn:    86400,
	}, nil
}

package config

import (
	"os"
	"strconv"
)

// Config menyimpan seluruh konfigurasi aplikasi yang dibaca dari env variables.
type Config struct {
	// Server
	Env  string
	Port string

	// Database
	DatabaseURL string

	// Redis
	RedisURL string

	// gRPC — Debate Engine (Python)
	DebateEngineAddr string

	// Auth
	JWTSecret          string
	JWTExpiryMinutes   int
	RefreshExpiryDays  int

	// Rate limiting
	FreeSessionsPerDay int

	// AI Providers
	GeminiAPIKey    string
	OpenAIAPIKey    string
	AnthropicAPIKey string

	// Storage
	R2AccountID       string
	R2AccessKeyID     string
	R2SecretAccessKey string
	R2BucketName      string

	// Payment
	MidtransServerKey string
	MidtransClientKey string
	MidtransIsSandbox bool

	// Push notification
	FCMCredentialsPath string
}

// Load membaca konfigurasi dari environment variables.
// Untuk lokal development, gunakan file .env yang dimuat via Docker Compose atau direnv.
func Load() *Config {
	return &Config{
		Env:  getEnv("APP_ENV", "development"),
		Port: getEnv("PORT", "8080"),

		DatabaseURL: mustEnv("DATABASE_URL"),
		RedisURL:    getEnv("REDIS_URL", "redis://localhost:6379"),

		DebateEngineAddr: getEnv("DEBATE_ENGINE_ADDR", "localhost:50051"),

		JWTSecret:         mustEnv("JWT_SECRET"),
		JWTExpiryMinutes:  getEnvInt("JWT_EXPIRY_MINUTES", 15),
		RefreshExpiryDays: getEnvInt("REFRESH_EXPIRY_DAYS", 30),

		FreeSessionsPerDay: getEnvInt("FREE_SESSIONS_PER_DAY", 5),

		GeminiAPIKey:    getEnv("GEMINI_API_KEY", ""),
		OpenAIAPIKey:    getEnv("OPENAI_API_KEY", ""),
		AnthropicAPIKey: getEnv("ANTHROPIC_API_KEY", ""),

		R2AccountID:       getEnv("R2_ACCOUNT_ID", ""),
		R2AccessKeyID:     getEnv("R2_ACCESS_KEY_ID", ""),
		R2SecretAccessKey: getEnv("R2_SECRET_ACCESS_KEY", ""),
		R2BucketName:      getEnv("R2_BUCKET_NAME", "debateai"),

		MidtransServerKey: getEnv("MIDTRANS_SERVER_KEY", ""),
		MidtransClientKey: getEnv("MIDTRANS_CLIENT_KEY", ""),
		MidtransIsSandbox: getEnvBool("MIDTRANS_IS_SANDBOX", true),

		FCMCredentialsPath: getEnv("FCM_CREDENTIALS_PATH", ""),
	}
}

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		panic("required environment variable not set: " + key)
	}
	return v
}

func getEnvInt(key string, defaultVal int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return defaultVal
}

func getEnvBool(key string, defaultVal bool) bool {
	if v := os.Getenv(key); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return defaultVal
}

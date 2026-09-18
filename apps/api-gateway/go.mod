module github.com/debateai/api-gateway

go 1.23

require (
	// HTTP Framework
	github.com/labstack/echo/v4 v4.12.0

	// gRPC & Protobuf
	google.golang.org/grpc v1.65.0
	google.golang.org/protobuf v1.34.2

	// Database
	github.com/jackc/pgx/v5 v5.6.0

	// Redis
	github.com/redis/go-redis/v9 v9.6.1

	// Auth
	github.com/golang-jwt/jwt/v5 v5.2.1
	golang.org/x/crypto v0.25.0

	// UUID
	github.com/google/uuid v1.6.0

	// Config
	github.com/spf13/viper v1.19.0

	// Logging
	github.com/rs/zerolog v1.33.0

	// Validation
	github.com/go-playground/validator/v10 v10.22.0

	// WebSocket
	github.com/gorilla/websocket v1.5.3

	// Testing
	github.com/stretchr/testify v1.9.0
)

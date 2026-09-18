package logger

import (
	"os"
	"time"

	"github.com/rs/zerolog"
)

// New initializes a zerolog.Logger based on environment.
func New(env string) zerolog.Logger {
	var output = zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
	}

	level := zerolog.InfoLevel
	if env == "development" || env == "" {
		level = zerolog.DebugLevel
	}

	return zerolog.New(output).
		Level(level).
		With().
		Timestamp().
		Caller().
		Logger()
}

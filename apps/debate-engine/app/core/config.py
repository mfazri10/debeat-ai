from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Server
    APP_ENV: str = "development"
    GRPC_PORT: int = 50051

    # Database (PostgreSQL + pgvector)
    DATABASE_URL: str

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # AI Providers
    GEMINI_API_KEY: str = ""
    OPENAI_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""

    # Embedding config
    EMBEDDING_MODEL: str = "gemini"          # "gemini" atau "openai"
    EMBEDDING_DIMENSION: int = 768           # Gemini=768, OpenAI=1536

    # RAG config
    RAG_TOP_K: int = 5
    RAG_THRESHOLD: float = 0.75
    RAG_CHUNK_SIZE: int = 500
    RAG_CHUNK_OVERLAP: int = 50

    # AI defaults
    DEFAULT_AI_PROVIDER: str = "GEMINI"
    FALLBACK_PROVIDERS: list[str] = ["OPENAI", "ANTHROPIC"]
    AI_TIMEOUT_SECONDS: int = 30
    AI_CIRCUIT_BREAKER_THRESHOLD: int = 3   # Gagal berturut-turut sebelum circuit breaker aktif

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

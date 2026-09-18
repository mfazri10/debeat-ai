from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_core.language_models.chat_models import BaseChatModel
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Circuit breaker state (in-memory, gunakan Redis di production)
_failure_counts: dict[str, int] = {}
_circuit_open: dict[str, bool] = {}


def get_llm(provider: str, streaming: bool = False) -> BaseChatModel:
    """
    Factory function untuk mendapatkan LLM berdasarkan provider.
    Implementasi fallback chain dan circuit breaker.
    """
    provider = provider.upper()

    # Circuit breaker — skip provider yang sedang bermasalah
    if _circuit_open.get(provider, False):
        logger.warning(f"[AIFactory] Circuit open for {provider}, falling back")
        return _get_fallback(provider, streaming)

    try:
        return _create_llm(provider, streaming)
    except Exception as e:
        logger.error(f"[AIFactory] Failed to create {provider} client: {e}")
        _record_failure(provider)
        return _get_fallback(provider, streaming)


def _create_llm(provider: str, streaming: bool) -> BaseChatModel:
    """Membuat instance LLM berdasarkan provider."""
    if provider == "GEMINI":
        return ChatGoogleGenerativeAI(
            model="gemini-2.0-flash",
            google_api_key=settings.GEMINI_API_KEY,
            streaming=streaming,
            temperature=0.7,
            max_output_tokens=2048,
        )
    elif provider == "OPENAI":
        return ChatOpenAI(
            model="gpt-4o-mini",
            api_key=settings.OPENAI_API_KEY,
            streaming=streaming,
            temperature=0.7,
            max_tokens=2048,
        )
    elif provider == "ANTHROPIC":
        return ChatAnthropic(
            model="claude-3-5-haiku-latest",
            api_key=settings.ANTHROPIC_API_KEY,
            streaming=streaming,
            temperature=0.7,
            max_tokens=2048,
        )
    else:
        raise ValueError(f"Unknown AI provider: {provider}")


def _get_fallback(failed_provider: str, streaming: bool) -> BaseChatModel:
    """Coba provider fallback secara berurutan."""
    chain = [settings.DEFAULT_AI_PROVIDER] + settings.FALLBACK_PROVIDERS
    for provider in chain:
        if provider != failed_provider and not _circuit_open.get(provider, False):
            logger.info(f"[AIFactory] Fallback to {provider}")
            try:
                return _create_llm(provider, streaming)
            except Exception:
                continue
    raise RuntimeError("All AI providers are unavailable")


def _record_failure(provider: str):
    """Catat kegagalan dan buka circuit jika melebihi threshold."""
    _failure_counts[provider] = _failure_counts.get(provider, 0) + 1
    if _failure_counts[provider] >= settings.AI_CIRCUIT_BREAKER_THRESHOLD:
        _circuit_open[provider] = True
        logger.critical(f"[CircuitBreaker] Circuit OPEN for {provider}!")
        # TODO: Schedule recovery check di Redis setelah 5 menit


def reset_circuit(provider: str):
    """Reset circuit breaker (dipanggil setelah recovery timeout)."""
    _failure_counts[provider] = 0
    _circuit_open[provider] = False
    logger.info(f"[CircuitBreaker] Circuit RESET for {provider}")

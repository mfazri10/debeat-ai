import asyncio
import grpc
import logging
from typing import AsyncIterator

from debateai.v1 import debate_pb2, debate_pb2_grpc, messages_pb2

from app.agents.opponent import OpponentAgent
from app.agents.judge import JudgeAgent
from app.agents.audience import AudienceAgent
from app.core.config import settings

logger = logging.getLogger(__name__)


class DebateEngineServicer(debate_pb2_grpc.DebateEngineServicer):
    """
    Implementasi gRPC DebateEngine service.
    Dipanggil oleh Go API Gateway melalui gRPC.
    """

    # ----------------------------------------------------------
    # 1. UNARY — Generate respons AI Lawan (tanpa streaming)
    # ----------------------------------------------------------
    async def GenerateOpponentResponse(
        self,
        request: messages_pb2.OpponentRequest,
        context: grpc.aio.ServicerContext,
    ) -> messages_pb2.OpponentResponse:
        """Fallback non-streaming untuk Free tier atau saat streaming gagal."""
        logger.info(f"[Opponent:Unary] session={request.session_id} provider={request.ai_provider}")

        agent = OpponentAgent(
            persona=request.persona,
            format=request.format,
            language=request.language,
            difficulty=request.difficulty,
            provider=request.ai_provider,
        )

        content, provider_used, tokens = await agent.generate(
            history=list(request.history),
            kb_context=list(request.kb_context),
        )

        return messages_pb2.OpponentResponse(
            content=content,
            provider_used=provider_used,
            tokens_used=tokens,
        )

    # ----------------------------------------------------------
    # 2. SERVER STREAMING — AI Lawan dengan streaming teks
    # ----------------------------------------------------------
    async def StreamOpponentResponse(
        self,
        request: messages_pb2.OpponentRequest,
        context: grpc.aio.ServicerContext,
    ) -> AsyncIterator[messages_pb2.OpponentChunk]:
        """
        Streaming teks AI Lawan chunk per chunk.
        Go API Gateway meneruskan setiap chunk ke Flutter via WebSocket.
        """
        logger.info(f"[Opponent:Stream] session={request.session_id} provider={request.ai_provider}")

        agent = OpponentAgent(
            persona=request.persona,
            format=request.format,
            language=request.language,
            difficulty=request.difficulty,
            provider=request.ai_provider,
        )

        provider_used = None
        async for chunk, is_done, provider in agent.stream(
            history=list(request.history),
            kb_context=list(request.kb_context),
        ):
            provider_used = provider
            yield messages_pb2.OpponentChunk(
                content=chunk,
                is_done=is_done,
                provider_used=provider if is_done else "",
            )

    # ----------------------------------------------------------
    # 3. UNARY — Score argumen dari 3 juri secara paralel
    # ----------------------------------------------------------
    async def ScoreArgument(
        self,
        request: messages_pb2.ScoreRequest,
        context: grpc.aio.ServicerContext,
    ) -> messages_pb2.ScoreResponse:
        """
        Menjalankan 3 juri (Logika, Retorika, Dampak) secara paralel
        dengan asyncio.gather. Return setelah semua selesai.
        """
        logger.info(f"[Judge:Score] session={request.session_id} argument={request.argument_id}")

        # 3 juri berjalan paralel — tidak menunggu satu per satu
        logika_result, retorika_result, dampak_result = await asyncio.gather(
            JudgeAgent("LOGIKA").score(request),
            JudgeAgent("RETORIKA").score(request),
            JudgeAgent("DAMPAK").score(request),
            return_exceptions=True,  # Jangan crash jika 1 juri gagal
        )

        # Graceful handling jika salah satu juri gagal
        def safe_result(result, judge_type: str) -> messages_pb2.JudgeResult:
            if isinstance(result, Exception):
                logger.error(f"[Judge:{judge_type}] failed: {result}")
                return messages_pb2.JudgeResult(
                    judge_type=judge_type,
                    total_score=0.0,
                    summary=f"Juri {judge_type} tidak tersedia saat ini.",
                )
            return result

        return messages_pb2.ScoreResponse(
            logika=safe_result(logika_result, "LOGIKA"),
            retorika=safe_result(retorika_result, "RETORIKA"),
            dampak=safe_result(dampak_result, "DAMPAK"),
        )

    # ----------------------------------------------------------
    # 4. UNARY — Generate reaksi penonton
    # ----------------------------------------------------------
    async def GenerateAudienceReaction(
        self,
        request: messages_pb2.AudienceRequest,
        context: grpc.aio.ServicerContext,
    ) -> messages_pb2.AudienceResponse:
        logger.info(f"[Audience] avg_score={request.avg_judge_score:.1f}")

        agent = AudienceAgent(language=request.language)
        return await agent.generate(
            avg_score=request.avg_judge_score,
            topic=request.topic,
        )

    # ----------------------------------------------------------
    # 5. BIDIRECTIONAL STREAMING — Full debate orchestration
    # ----------------------------------------------------------
    async def OrchestrateDebate(
        self,
        request_iterator: grpc.aio.ServicerContext,
        context: grpc.aio.ServicerContext,
    ) -> AsyncIterator[messages_pb2.DebateUpdate]:
        """
        Stream bidirectional untuk satu sesi debat penuh.
        Go kirim DebateEvent → Python kirim stream DebateUpdate.

        Flow per argumen:
        1. Terima ArgumentSubmittedEvent dari Go
        2. Stream opponent chunks → yield OpponentChunk updates
        3. Paralel: score 3 juri + generate audience
        4. Yield JudgeResult (x3) + AudienceResponse
        """
        logger.info("[Orchestrate] Bidirectional stream opened")

        session_config = None  # Diset saat SessionStartedEvent diterima

        async for event in request_iterator:
            # --- Session Started ---
            if event.HasField("session_started"):
                session_config = event.session_started
                logger.info(f"[Orchestrate] Session started: {session_config.session_id}")

            # --- Argument Submitted ---
            elif event.HasField("argument_submitted"):
                arg = event.argument_submitted
                logger.info(f"[Orchestrate] Argument received: turn={arg.turn_number}")

                if session_config is None:
                    yield messages_pb2.DebateUpdate(
                        error=messages_pb2.ErrorUpdate(
                            code="SESSION_NOT_STARTED",
                            message="Session belum diinisialisasi.",
                            retryable=False,
                        )
                    )
                    continue

                # Step 1: Stream opponent response
                opponent_agent = OpponentAgent(
                    persona=session_config.ai_persona,
                    format=session_config.format,
                    language=session_config.language,
                    difficulty=session_config.difficulty,
                    provider=session_config.ai_provider,
                )

                full_content = []
                async for chunk, is_done, provider in opponent_agent.stream(
                    history=[],  # TODO: inject dari session state
                    kb_context=[],
                ):
                    full_content.append(chunk)
                    yield messages_pb2.DebateUpdate(
                        opponent_chunk=messages_pb2.OpponentChunk(
                            content=chunk,
                            is_done=is_done,
                            provider_used=provider if is_done else "",
                        )
                    )

                # Step 2: Score + audience secara paralel
                score_req = messages_pb2.ScoreRequest(
                    session_id=arg.session_id,
                    argument_id=arg.argument_id,
                    content=arg.content,
                    language=session_config.language,
                )

                avg_score = 70.0  # Default sebelum judge selesai

                logika, retorika, dampak, audience = await asyncio.gather(
                    JudgeAgent("LOGIKA").score(score_req),
                    JudgeAgent("RETORIKA").score(score_req),
                    JudgeAgent("DAMPAK").score(score_req),
                    AudienceAgent(language=session_config.language).generate(
                        avg_score=avg_score,
                        topic=session_config.topic,
                    ),
                    return_exceptions=True,
                )

                # Yield skor masing-masing juri
                for result in [logika, retorika, dampak]:
                    if not isinstance(result, Exception):
                        yield messages_pb2.DebateUpdate(judge_result=result)

                # Yield reaksi penonton
                if not isinstance(audience, Exception):
                    yield messages_pb2.DebateUpdate(audience_react=audience)

            # --- Session Ended ---
            elif event.HasField("session_ended"):
                logger.info(f"[Orchestrate] Session ended: {event.session_ended.session_id}")
                break

        logger.info("[Orchestrate] Bidirectional stream closed")

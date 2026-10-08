import asyncio
import grpc
import logging
from typing import AsyncIterator, Dict

from debateai.v1 import debate_pb2, debate_pb2_grpc, messages_pb2

from app.agents.opponent import OpponentAgent
from app.agents.judge import JudgeAgent
from app.agents.audience import AudienceAgent
from app.core.config import settings

logger = logging.getLogger(__name__)


class _SessionState:
    """State in-memory per sesi debat: riwayat argumen + konteks RAG."""

    def __init__(self):
        self.history: list = []          # list[ArgumentHistory]
        self.kb_context: list = []       # list[KbChunk] terakhir
        self.turn_count: int = 0


class DebateEngineServicer(debate_pb2_grpc.DebateEngineServicer):
    """
    Implementasi gRPC DebateEngine service.
    Dipanggil oleh Go API Gateway melalui gRPC.
    """

    def __init__(self):
        # session_id → _SessionState (riwayat debat per sesi)
        self._sessions: Dict[str, _SessionState] = {}

    def _get_state(self, session_id: str) -> _SessionState:
        if session_id not in self._sessions:
            self._sessions[session_id] = _SessionState()
        return self._sessions[session_id]

    async def _rag_search(self, text: str, language: str) -> list:
        """Embedding + pgvector search untuk RAG context. Return list[KbChunk] (mungkin kosong)."""
        try:
            import asyncpg
            from langchain_google_genai import GoogleGenerativeAIEmbeddings

            if not settings.GEMINI_API_KEY:
                return []

            embeddings = GoogleGenerativeAIEmbeddings(
                model="models/text-embedding-004",
                google_api_key=settings.GEMINI_API_KEY,
            )
            vector = await embeddings.aembed_query(text)
            embedding_str = "[" + ",".join(str(x) for x in vector) + "]"

            url = settings.DATABASE_URL.replace("postgres+asyncpg://", "postgres://")
            conn = await asyncpg.connect(url)
            try:
                rows = await conn.fetch(
                    """
                    SELECT c.id, c.content, d.title, d.source_url,
                           1 - (c.embedding <=> $1::vector) AS similarity
                    FROM kb_chunks c
                    JOIN kb_documents d ON c.document_id = d.id
                    WHERE c.is_active = TRUE AND d.is_active = TRUE
                      AND 1 - (c.embedding <=> $1::vector) >= $2
                    ORDER BY c.embedding <=> $1::vector ASC
                    LIMIT $3;
                    """,
                    embedding_str, settings.RAG_THRESHOLD, settings.RAG_TOP_K,
                )
                return [
                    messages_pb2.KbChunk(
                        id=str(r["id"]),
                        content=r["content"],
                        document_title=r["title"] or "",
                        source_url=r["source_url"] or "",
                        similarity=float(r["similarity"]),
                    )
                    for r in rows
                ]
            finally:
                await conn.close()
        except Exception as e:
            logger.warning(f"[Orchestrate] RAG search gagal (lanjut tanpa KB): {e}")
            return []

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

                state = self._get_state(arg.session_id)
                state.turn_count += 1

                # Catat argumen user ke riwayat sesi
                state.history.append(messages_pb2.ArgumentHistory(
                    participant_id=arg.participant_id,
                    content=arg.content,
                    role="user",
                    round_number=arg.round_number,
                    turn_number=arg.turn_number,
                ))

                # Step 0: RAG search untuk konteks faktual (fix: KB tersuntik ke AI)
                kb_chunks = await self._rag_search(arg.content, session_config.language)
                if kb_chunks:
                    state.kb_context = kb_chunks

                # Step 1: Stream opponent response (dengan history + KB context)
                opponent_agent = OpponentAgent(
                    persona=session_config.ai_persona,
                    format=session_config.format,
                    language=session_config.language,
                    difficulty=session_config.difficulty,
                    provider=session_config.ai_provider,
                )

                full_content = []
                async for chunk, is_done, provider in opponent_agent.stream(
                    history=list(state.history),
                    kb_context=list(state.kb_context),
                ):
                    full_content.append(chunk)
                    yield messages_pb2.DebateUpdate(
                        opponent_chunk=messages_pb2.OpponentChunk(
                            content=chunk,
                            is_done=is_done,
                            provider_used=provider if is_done else "",
                        )
                    )

                # Catat respons AI ke riwayat sesi
                ai_text = "".join(full_content)
                state.history.append(messages_pb2.ArgumentHistory(
                    participant_id="ai-opponent",
                    content=ai_text,
                    role="ai",
                    round_number=arg.round_number,
                    turn_number=arg.turn_number,
                ))
                # Batasi riwayat agar prompt tidak membengkak
                if len(state.history) > 12:
                    state.history = state.history[-12:]

                # Step 2: Score + audience secara paralel
                score_req = messages_pb2.ScoreRequest(
                    session_id=arg.session_id,
                    argument_id=arg.argument_id,
                    content=arg.content,
                    language=session_config.language,
                    history=list(state.history[:-1]),  # riwayat sebelum argumen ini
                    kb_context=list(state.kb_context),
                )

                logika, retorika, dampak = await asyncio.gather(
                    JudgeAgent("LOGIKA").score(score_req),
                    JudgeAgent("RETORIKA").score(score_req),
                    JudgeAgent("DAMPAK").score(score_req),
                    return_exceptions=True,
                )

                # Hitung rata-rata skor juri yang berhasil untuk audience
                scores = [
                    r.total_score for r in [logika, retorika, dampak]
                    if not isinstance(r, Exception) and r.total_score > 0
                ]
                avg_score = sum(scores) / len(scores) if scores else 70.0

                # Yield skor masing-masing juri
                for result in [logika, retorika, dampak]:
                    if not isinstance(result, Exception):
                        yield messages_pb2.DebateUpdate(judge_result=result)

                # Step 3: Reaksi penonton berdasarkan skor riil juri
                try:
                    audience = await AudienceAgent(language=session_config.language).generate(
                        avg_score=avg_score,
                        topic=session_config.topic,
                    )
                    yield messages_pb2.DebateUpdate(audience_react=audience)
                except Exception as e:
                    logger.warning(f"[Orchestrate] audience generation gagal: {e}")

            # --- Session Ended ---
            elif event.HasField("session_ended"):
                ended_id = event.session_ended.session_id
                logger.info(f"[Orchestrate] Session ended: {ended_id}")
                self._sessions.pop(ended_id, None)
                break

        logger.info("[Orchestrate] Bidirectional stream closed")

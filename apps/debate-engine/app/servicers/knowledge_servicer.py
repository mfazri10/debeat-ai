import asyncio
import json
import logging
import time
from typing import AsyncIterator, List

import grpc

try:
    from debateai.v1 import knowledge_pb2, knowledge_pb2_grpc, messages_pb2
except ImportError:
    import sys
    sys.path.insert(0, "gen/python")
    from debateai.v1 import knowledge_pb2, knowledge_pb2_grpc, messages_pb2

from app.core.config import settings

logger = logging.getLogger(__name__)


async def _get_db_conn():
    """Membuat koneksi asyncpg ke PostgreSQL. Return None jika gagal."""
    try:
        import asyncpg
        url = settings.DATABASE_URL.replace("postgres+asyncpg://", "postgres://")
        return await asyncpg.connect(url)
    except Exception as e:
        logger.warning(f"[KB] Database tidak tersedia: {e}")
        return None


class KnowledgeBaseServicer(knowledge_pb2_grpc.KnowledgeBaseServicer):
    """
    Implementasi gRPC KnowledgeBase service.
    Melayani vector similarity search RAG, embedding generation, dan document ingestion pipeline.
    """

    async def SearchKnowledge(
        self,
        request: messages_pb2.SearchRequest,
        context: grpc.aio.ServicerContext,
    ) -> messages_pb2.SearchResponse:
        """
        Pencarian top-k chunks relevan dari PostgreSQL + pgvector
        berdasarkan cosine similarity (1 - (embedding <=> query_embedding)).
        """
        logger.info(f"[KB:Search] top_k={request.top_k} threshold={request.threshold} lang={request.language}")

        results: List[messages_pb2.KbChunk] = []
        conn = await _get_db_conn()
        if conn is None:
            return messages_pb2.SearchResponse(chunks=results)

        try:
            embedding_str = "[" + ",".join(str(x) for x in request.embedding) + "]"
            query = """
                SELECT c.id, c.content, d.title, d.source_url,
                       1 - (c.embedding <=> $1::vector) AS similarity
                FROM kb_chunks c
                JOIN kb_documents d ON c.document_id = d.id
                WHERE c.is_active = TRUE AND d.is_active = TRUE
                  AND 1 - (c.embedding <=> $1::vector) >= $2
                ORDER BY c.embedding <=> $1::vector ASC
                LIMIT $3;
            """
            rows = await conn.fetch(query, embedding_str, request.threshold, request.top_k)
            for r in rows:
                results.append(
                    messages_pb2.KbChunk(
                        id=str(r["id"]),
                        content=r["content"],
                        document_title=r["title"] or "",
                        source_url=r["source_url"] or "",
                        similarity=float(r["similarity"]),
                    )
                )
            logger.info(f"[KB:Search] found {len(results)} chunks")
        except Exception as e:
            logger.error(f"[KB:Search] error: {e}")
        finally:
            await conn.close()

        return messages_pb2.SearchResponse(chunks=results)

    async def GenerateEmbedding(
        self,
        request: messages_pb2.EmbeddingRequest,
        context: grpc.aio.ServicerContext,
    ) -> messages_pb2.EmbeddingResponse:
        """
        Menghasilkan 768-dimensi embedding vektor menggunakan Google Gemini text-embedding-004.
        """
        start_time = time.time()
        logger.info(f"[KB:Embedding] model={request.model} text_length={len(request.text)}")

        embedding_vector: List[float] = []
        model_used = "models/text-embedding-004"

        try:
            if settings.GEMINI_API_KEY:
                from langchain_google_genai import GoogleGenerativeAIEmbeddings
                embeddings = GoogleGenerativeAIEmbeddings(
                    model=model_used,
                    google_api_key=settings.GEMINI_API_KEY,
                )
                embedding_vector = await embeddings.aembed_query(request.text)
            else:
                # Fallback jika API key belum diset
                embedding_vector = [0.0] * 768
                model_used = "dummy-zero-768"

        except Exception as e:
            logger.error(f"[KB:Embedding] Failed to generate embedding: {e}")
            embedding_vector = [0.0] * 768
            model_used = "error-fallback-768"

        latency_ms = int((time.time() - start_time) * 1000)
        return messages_pb2.EmbeddingResponse(
            embedding=embedding_vector,
            model_used=model_used,
            latency_ms=latency_ms,
        )

    async def IngestDocument(
        self,
        request: messages_pb2.IngestRequest,
        context: grpc.aio.ServicerContext,
    ) -> AsyncIterator[messages_pb2.IngestProgress]:
        """
        Server streaming RPC: Ingest dokumen (YouTube transcript / PDF / Web / Manual)
        secara NYATA — ekstraksi, chunking, embedding, dan penyimpanan ke pgvector.
        """
        logger.info(f"[KB:Ingest] title='{request.title}' type={request.source_type}")

        try:
            # 1. EXTRACTING — ambil teks mentah sesuai tipe sumber
            yield messages_pb2.IngestProgress(
                status="EXTRACTING",
                chunks_processed=0,
                total_chunks=0,
                current_step=f"Mengekstraksi konten dari {request.source_type}...",
            )
            raw_text = await self._extract_text(request)
            if not raw_text or not raw_text.strip():
                yield messages_pb2.IngestProgress(
                    status="ERROR",
                    error_message="Tidak ada konten yang bisa diekstrak dari sumber.",
                )
                return

            # 2. CHUNKING — segmentasi teks
            chunks = self._chunk_text(raw_text)
            total_chunks = len(chunks)
            yield messages_pb2.IngestProgress(
                status="CHUNKING",
                chunks_processed=0,
                total_chunks=total_chunks,
                current_step=f"Segmentasi teks menjadi {total_chunks} chunks...",
            )
            await asyncio.sleep(0.1)

            # 3. EMBEDDING — generate vektor per chunk
            embeddings = await self._embed_chunks(chunks, request.language)

            # 4. STORING — simpan ke PostgreSQL + pgvector
            conn = await _get_db_conn()
            if conn is None:
                yield messages_pb2.IngestProgress(
                    status="ERROR",
                    error_message="Database tidak tersedia untuk penyimpanan.",
                )
                return

            try:
                import hashlib
                doc_id = await conn.fetchval(
                    """
                    INSERT INTO kb_documents (title, source_type, source_url, language, topic_tags, persona_tags, total_chunks, ingested_by)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                    RETURNING id
                    """,
                    request.title or "Untitled",
                    request.source_type,
                    request.source_url or None,
                    request.language or "ID",
                    list(request.topic_tags) if request.topic_tags else None,
                    list(request.persona_tags) if request.persona_tags else None,
                    total_chunks,
                    request.ingested_by_id or None,
                )

                for i, (chunk_text, emb) in enumerate(zip(chunks, embeddings)):
                    content_hash = hashlib.sha256(chunk_text.encode("utf-8")).hexdigest()
                    embedding_str = "[" + ",".join(str(x) for x in emb) + "]"
                    await conn.execute(
                        """
                        INSERT INTO kb_chunks (document_id, content, content_hash, chunk_index, embedding, token_count)
                        VALUES ($1, $2, $3, $4, $5::vector, $6)
                        ON CONFLICT (content_hash) DO NOTHING
                        """,
                        doc_id, chunk_text, content_hash, i, embedding_str, len(chunk_text.split()),
                    )
                    yield messages_pb2.IngestProgress(
                        status="EMBEDDING",
                        chunks_processed=i + 1,
                        total_chunks=total_chunks,
                        current_step=f"Menyimpan chunk {i + 1}/{total_chunks} ke pgvector...",
                    )
            finally:
                await conn.close()

            # 5. DONE
            yield messages_pb2.IngestProgress(
                status="DONE",
                chunks_processed=total_chunks,
                total_chunks=total_chunks,
                current_step=f"Ingestion selesai! {total_chunks} chunks siap digunakan untuk RAG.",
            )

        except Exception as e:
            logger.error(f"[KB:Ingest] error: {e}")
            yield messages_pb2.IngestProgress(
                status="ERROR",
                error_message=str(e),
            )

    # ----------------------------------------------------------
    # HELPERS — Ekstraksi, Chunking, Embedding
    # ----------------------------------------------------------

    async def _extract_text(self, request: messages_pb2.IngestRequest) -> str:
        """Ekstrak teks mentah berdasarkan tipe sumber."""
        source_type = request.source_type.upper()

        if source_type == "YOUTUBE":
            return await self._extract_youtube(request.source_url, request.language)
        elif source_type == "PDF":
            return self._extract_pdf(request.file_content)
        elif source_type == "MANUAL":
            # Untuk MANUAL, konten teks dikirim via field title + source_url sebagai body
            return request.source_url or request.title
        else:
            return ""

    async def _extract_youtube(self, url: str, language: str) -> str:
        """Ambil transkrip YouTube via youtube-transcript-api."""
        try:
            from youtube_transcript_api import YouTubeTranscriptApi
            import re

            # Ekstrak video ID dari berbagai format URL YouTube
            match = re.search(r"(?:v=|youtu\.be/|embed/)([a-zA-Z0-9_-]{11})", url or "")
            if not match:
                logger.error(f"[KB:YouTube] URL tidak valid: {url}")
                return ""

            video_id = match.group(1)
            lang_codes = [language.lower() if language else "id", "id", "en"]

            transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
            transcript = None
            for lc in lang_codes:
                try:
                    transcript = transcript_list.find_transcript([lc])
                    break
                except Exception:
                    continue
            if transcript is None:
                try:
                    transcript = transcript_list.find_generated_transcript(["id", "en"])
                except Exception:
                    return ""

            entries = transcript.fetch()
            return " ".join(e["text"] for e in entries)
        except Exception as e:
            logger.error(f"[KB:YouTube] extraction failed: {e}")
            return ""

    def _extract_pdf(self, file_content: bytes) -> str:
        """Ekstrak teks dari PDF via PyMuPDF."""
        try:
            import fitz  # PyMuPDF
            doc = fitz.open(stream=file_content, filetype="pdf")
            text_parts = [page.get_text() for page in doc]
            doc.close()
            return "\n".join(text_parts)
        except Exception as e:
            logger.error(f"[KB:PDF] extraction failed: {e}")
            return ""

    def _chunk_text(self, text: str) -> List[str]:
        """Segmentasi teks menjadi chunks dengan overlap."""
        chunk_size = settings.RAG_CHUNK_SIZE
        overlap = settings.RAG_CHUNK_OVERLAP
        words = text.split()
        chunks = []
        start = 0
        while start < len(words):
            end = min(start + chunk_size, len(words))
            chunks.append(" ".join(words[start:end]))
            start += chunk_size - overlap
            if end == len(words):
                break
        return chunks if chunks else [text]

    async def _embed_chunks(self, chunks: List[str], language: str) -> List[List[float]]:
        """Generate embedding 768-dim untuk semua chunks."""
        embeddings: List[List[float]] = []
        try:
            if settings.GEMINI_API_KEY:
                from langchain_google_genai import GoogleGenerativeAIEmbeddings
                emb_model = GoogleGenerativeAIEmbeddings(
                    model="models/text-embedding-004",
                    google_api_key=settings.GEMINI_API_KEY,
                )
                embeddings = await emb_model.aembed_documents(chunks)
            else:
                # Fallback: zero vectors (dev mode tanpa API key)
                embeddings = [[0.0] * settings.EMBEDDING_DIMENSION for _ in chunks]
        except Exception as e:
            logger.error(f"[KB:Embed] batch embedding failed: {e}")
            embeddings = [[0.0] * settings.EMBEDDING_DIMENSION for _ in chunks]
        return embeddings

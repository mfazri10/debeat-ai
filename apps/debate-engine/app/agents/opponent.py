from typing import AsyncIterator
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
from app.core.ai_factory import get_llm
import logging

logger = logging.getLogger(__name__)

# Rubrik level kesulitan
DIFFICULTY_INSTRUCTIONS = {
    "EASY": "Gunakan argumen sederhana satu poin. Bahasa mudah dipahami. Jangan menyerang argumen lawan secara langsung.",
    "MEDIUM": "Gunakan 2-3 poin argumen. Sertakan data atau contoh. Sesekali challenge premis lawan.",
    "HARD": "Bangun argumen berlapis. Deteksi dan serang kelemahan logika lawan. Gunakan referensi data spesifik. Terapkan teknik: premis attack, reductio ad absurdum, statistical challenge.",
}

# Instruksi format debat
FORMAT_INSTRUCTIONS = {
    "KDMI": "Ikuti format KDMI: pembukaan (definisi + parameter), isi (3 argumen utama), penutup (rebuttal + summary).",
    "OXFORD": "Format Oxford: nyatakan posisi dengan jelas, berikan 3 argumen terstruktur, tutup dengan call-to-action.",
    "BP": "Format British Parliamentary: fokus pada 'matter' (isi argumen) dan 'manner' (cara penyampaian). Respons argumen lawan dengan jelas.",
    "NUDC": "Format NUDC: argumen sistematis dengan link back yang kuat. Prioritaskan clash dengan argumen lawan.",
    "INTERVIEW": "Ini adalah simulasi wawancara. Jadilah pewawancara yang kritis. Ajukan pertanyaan tajam dan menantang.",
    "FREE": "Tidak ada format khusus. Berdebat secara natural dan persuasif.",
}


class OpponentAgent:
    """
    AI Lawan yang menggunakan LangChain untuk generate respons debat.
    Mendukung streaming dan non-streaming.
    """

    def __init__(self, persona, format: str, language: str, difficulty: str, provider: str):
        self.persona = persona
        self.format = format.upper()
        self.language = language.upper()
        self.difficulty = difficulty.upper()
        self.provider = provider.upper()
        self.provider_used = provider

    def _build_system_prompt(self) -> str:
        lang_instruction = "Respond in Bahasa Indonesia." if self.language == "ID" else "Respond in English."
        difficulty_instruction = DIFFICULTY_INSTRUCTIONS.get(self.difficulty, DIFFICULTY_INSTRUCTIONS["MEDIUM"])
        format_instruction = FORMAT_INSTRUCTIONS.get(self.format, FORMAT_INSTRUCTIONS["FREE"])

        return f"""Kamu adalah {self.persona.name}.

DESKRIPSI KARAKTER:
{self.persona.description}

GAYA BICARA:
{self.persona.speaking_style}

POSISI DEBAT:
{self.persona.stance}

FORMAT DEBAT:
{format_instruction}

TINGKAT KESULITAN:
{difficulty_instruction}

INSTRUKSI BAHASA:
{lang_instruction}

ATURAN PENTING:
- Tetap konsisten dengan karakter dan gaya bicaramu sepanjang debat
- Jangan keluar dari peran (jangan sebut dirimu "AI" atau "model bahasa")
- Maksimal 300 kata per respons
- Fokus pada isu, bukan serangan personal"""

    def _build_messages(self, history: list, kb_context: list) -> list:
        messages = [SystemMessage(content=self._build_system_prompt())]

        # Inject knowledge base context jika ada
        if kb_context:
            kb_text = "\n\n".join([
                f"[{chunk.document_title}]\n{chunk.content}"
                for chunk in kb_context[:5]
            ])
            messages.append(SystemMessage(
                content=f"Referensi faktual yang bisa kamu gunakan:\n\n{kb_text}"
            ))

        # Konversi riwayat argumen ke format LangChain
        for arg in history:
            if arg.role == "user":
                messages.append(HumanMessage(content=arg.content))
            else:
                messages.append(AIMessage(content=arg.content))

        return messages

    async def generate(self, history: list, kb_context: list) -> tuple[str, str, int]:
        """Non-streaming generation. Return: (content, provider_used, token_count)"""
        llm = get_llm(self.provider, streaming=False)
        messages = self._build_messages(history, kb_context)

        response = await llm.ainvoke(messages)
        self.provider_used = self.provider

        content = response.content
        tokens = response.usage_metadata.get("total_tokens", 0) if hasattr(response, "usage_metadata") else 0

        return content, self.provider_used, tokens

    async def stream(self, history: list, kb_context: list) -> AsyncIterator[tuple[str, bool, str]]:
        """
        Streaming generation. Yield: (chunk_text, is_done, provider_used)
        """
        llm = get_llm(self.provider, streaming=True)
        messages = self._build_messages(history, kb_context)

        try:
            async for chunk in llm.astream(messages):
                content = chunk.content
                if content:
                    yield content, False, ""

            # Signal bahwa stream selesai
            yield "", True, self.provider

        except Exception as e:
            logger.error(f"[OpponentAgent] Streaming error: {e}")
            # Fallback ke provider lain
            try:
                fallback_llm = get_llm("GEMINI" if self.provider != "GEMINI" else "OPENAI", streaming=False)
                response = await fallback_llm.ainvoke(messages)
                yield response.content, True, "GEMINI_FALLBACK"
            except Exception as fallback_e:
                logger.critical(f"[OpponentAgent] All providers failed: {fallback_e}")
                yield "Maaf, saya tidak bisa merespons saat ini. Silakan coba lagi.", True, "ERROR"

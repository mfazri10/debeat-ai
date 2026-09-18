import json
import logging
from langchain_core.messages import SystemMessage, HumanMessage
from app.core.ai_factory import get_llm

try:
    from debateai.v1 import messages_pb2
except ImportError:
    import sys
    sys.path.insert(0, "gen/python")
    from debateai.v1 import messages_pb2

logger = logging.getLogger(__name__)

AUDIENCE_PROMPT = """Kamu adalah simulator penonton debat interaktif (Audience Simulator).
Tugasmu adalah menghasilkan reaksi penonton dan kumpulan komentar live chat berdasarkan skor juri dan topik debat.

Kategori Reaksi:
- APPLAUSE: skor >= 75 (penonton kagum, setuju, tepuk tangan)
- EXCITED: skor >= 85 (penonton sangat antusias, kagum luar biasa)
- NEUTRAL: 60 <= skor < 75 (argumen standar, penonton menyimak)
- SKEPTICAL: 45 <= skor < 60 (penonton meragukan klaim atau data)
- BOO: skor < 45 (argumen lemah, kontradiktif, atau menyerang personal)

Komentar harus terasa nyata seperti live chat YouTube/TikTok debat di Indonesia (singkat, variatif, ada emoji, celetukan khas anak muda/akademisi).
Format WAJIB JSON:
{
  "reaction_type": "APPLAUSE" | "BOO" | "NEUTRAL" | "EXCITED" | "SKEPTICAL",
  "intensity": <integer 0-100>,
  "comments": [
    "<komentar 1>",
    "<komentar 2>",
    "<komentar 3>",
    "<komentar 4>",
    "<komentar 5>"
  ]
}
"""

class AudienceAgent:
    """Simulator reaksi dan live chat penonton debat."""

    def __init__(self, language: str = "id", provider: str = "gemini"):
        self.language = language
        self.provider = provider

    async def generate(self, avg_score: float, topic: str) -> messages_pb2.AudienceResponse:
        """Menghasilkan AudienceResponse berdasarkan rata-rata skor juri."""
        llm = get_llm(provider=self.provider, temperature=0.7)

        human_prompt = f"""Topik Debat: \"{topic}\"
Rata-rata Skor Juri: {avg_score:.1f} dari 100.
Bahasa Komentar: {self.language}

Hasilkan JSON reaksi penonton dan 5 komentar live chat."""

        try:
            messages = [
                SystemMessage(content=AUDIENCE_PROMPT),
                HumanMessage(content=human_prompt),
            ]
            response = await llm.ainvoke(messages)
            raw_text = response.content.strip()

            if raw_text.startswith("```"):
                lines = raw_text.splitlines()
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].startswith("```"):
                    lines = lines[:-1]
                raw_text = "\n".join(lines).strip()

            data = json.loads(raw_text)

            return messages_pb2.AudienceResponse(
                reaction_type=str(data.get("reaction_type", "NEUTRAL")),
                intensity=int(data.get("intensity", int(avg_score))),
                comments=list(data.get("comments", [
                    "Argumen yang menarik! 👏",
                    "Perlu data pembanding nih",
                    "Mantap penjelasannya 🔥",
                    "Coba analoginya diperjelas lagi",
                    "Menyimak terus ronde berikutnya 👀",
                ])),
            )

        except Exception as e:
            logger.error(f"[AudienceAgent] Error generating audience reaction: {e}")
            reaction_type = "APPLAUSE" if avg_score >= 75 else ("BOO" if avg_score < 50 else "NEUTRAL")
            return messages_pb2.AudienceResponse(
                reaction_type=reaction_type,
                intensity=int(avg_score),
                comments=[
                    "Argumennya berbobot! 🔥",
                    "Penjelasannya cukup runtut",
                    "Setuju dengan poin barusan 👏",
                    "Tunggu sanggahan dari lawan!",
                    "Keren diskusinya ✨",
                ],
            )

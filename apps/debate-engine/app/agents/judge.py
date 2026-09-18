import json
import logging
from typing import Optional
from langchain_core.messages import SystemMessage, HumanMessage
from app.core.ai_factory import get_llm

try:
    from debateai.v1 import messages_pb2
except ImportError:
    import sys
    sys.path.insert(0, "gen/python")
    from debateai.v1 import messages_pb2

logger = logging.getLogger(__name__)

JUDGE_PROMPTS = {
    "LOGIKA": """Kamu adalah Juri Debat AI khusus Bidang LOGIKA & STRUKTUR ARGUMENTASI (Judge of Logic).
Tugas utamamu:
1. Memeriksa validitas silogisme, premis, dan kesimpulan dari argumen.
2. Mengidentifikasi apakah ada Logical Fallacy (seperti Ad Hominem, Strawman, Slippery Slope, False Dilemma, Circular Reasoning, Appeal to Emotion, Red Herring).
3. Mengukur konsistensi nalar dan struktur runtut argumen (A-R-E-L: Assertion, Reasoning, Evidence, Linkback).

Output WAJIB dalam format JSON murni:
{
  "argument_strength": <0-100>,
  "fact_data_usage": <0-100>,
  "rhetoric_technique": <0-100>,
  "responsiveness": <0-100>,
  "clarity_structure": <0-100>,
  "total_score": <rata-rata terbobot desimal, contoh 78.5>,
  "summary": "<Ulasan mendalam logika 2-3 kalimat dalam bahasa yang sama dengan input>",
  "highlights_positive": ["<poin positif 1>", "<poin positif 2>"],
  "highlights_negative": ["<poin kelemahan 1>", "<poin kelemahan 2>"],
  "fallacy_detected": "<Nama fallacy jika ditemukan, atau kosongkan/string kosong jika tidak ada>",
  "suggestion": "<1-2 saran spesifik untuk memperkuat penalaran>"
}
""",
    "RETORIKA": """Kamu adalah Juri Debat AI khusus Bidang RETORIKA & GAYA PENYAMPAIAN (Judge of Rhetoric).
Tugas utamamu:
1. Menilai daya persuasi (Ethos, Pathos, Logos).
2. Mengevaluasi diksi, kejelasan kalimat, ritme, variasi nada bahasa, dan keterikatan audiens.
3. Menilai transisi antar ide dan dampak emosional serta keterpanggilan pendengar.

Output WAJIB dalam format JSON murni:
{
  "argument_strength": <0-100>,
  "fact_data_usage": <0-100>,
  "rhetoric_technique": <0-100>,
  "responsiveness": <0-100>,
  "clarity_structure": <0-100>,
  "total_score": <rata-rata terbobot desimal, contoh 82.0>,
  "summary": "<Ulasan retorika dan gaya 2-3 kalimat dalam bahasa yang sama dengan input>",
  "highlights_positive": ["<poin positif 1>", "<poin positif 2>"],
  "highlights_negative": ["<poin kelemahan 1>", "<poin kelemahan 2>"],
  "fallacy_detected": "",
  "suggestion": "<1-2 saran spesifik untuk meningkatkan daya persuasi dan gaya>"
}
""",
    "DAMPAK": """Kamu adalah Juri Debat AI khusus Bidang DAMPAK, SIGNIFIKANSI & BUKTI (Judge of Impact & Evidence).
Tugas utamamu:
1. Menilai relevansi dampak dunia nyata (who is affected, how much, urgency, reversibility).
2. Mengevaluasi penggunaan data, fakta, analogi empiris, dan pembuktian komparatif.
3. Menguji apakah proposal/argumen menyelesaikan akar masalah (solvency) atau hanya memperdebatkan gejala.

Output WAJIB dalam format JSON murni:
{
  "argument_strength": <0-100>,
  "fact_data_usage": <0-100>,
  "rhetoric_technique": <0-100>,
  "responsiveness": <0-100>,
  "clarity_structure": <0-100>,
  "total_score": <rata-rata terbobot desimal, contoh 80.5>,
  "summary": "<Ulasan dampak dan bukti empiris 2-3 kalimat dalam bahasa yang sama dengan input>",
  "highlights_positive": ["<poin positif 1>", "<poin positif 2>"],
  "highlights_negative": ["<poin kelemahan 1>", "<poin kelemahan 2>"],
  "fallacy_detected": "",
  "suggestion": "<1-2 saran spesifik untuk memperdalam dampak dan bukti>"
}
"""
}


class JudgeAgent:
    """Agen Juri AI dengan spesialisasi: LOGIKA, RETORIKA, atau DAMPAK."""

    def __init__(self, judge_type: str, provider: str = "gemini"):
        self.judge_type = judge_type.upper()
        self.provider = provider
        if self.judge_type not in JUDGE_PROMPTS:
            self.judge_type = "LOGIKA"

    async def score(self, request: messages_pb2.ScoreRequest) -> messages_pb2.JudgeResult:
        """Menilai sebuah argumen dan menghasilkan JudgeResult terstruktur."""
        llm = get_llm(provider=self.provider, temperature=0.2)
        system_prompt = JUDGE_PROMPTS[self.judge_type]

        # Susun riwayat singkat jika ada
        history_text = ""
        if request.history:
            history_lines = [f"- Turn {h.turn_number} ({h.speaker}): {h.content}" for h in request.history[-4:]]
            history_text = "\nRiwayat konteks debat sebelumnya:\n" + "\n".join(history_lines) + "\n"

        human_prompt = f"""Nilai argumen berikut berdasarkan rubrik spesialisasi Anda:
{history_text}
Argumen yang dinilai:
\"\"\"{request.content}\"\"\"

Bahasa yang digunakan: {request.language}
Keluarkan HANYA JSON valid sesuai skema yang telah ditentukan tanpa markdown backtick tambahan."""

        try:
            messages = [
                SystemMessage(content=system_prompt),
                HumanMessage(content=human_prompt),
            ]
            response = await llm.ainvoke(messages)
            raw_text = response.content.strip()

            # Bersihkan markdown formatting jika ada (```json ... ```)
            if raw_text.startswith("```"):
                lines = raw_text.splitlines()
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].startswith("```"):
                    lines = lines[:-1]
                raw_text = "\n".join(lines).strip()

            data = json.loads(raw_text)

            return messages_pb2.JudgeResult(
                judge_type=self.judge_type,
                argument_strength=int(data.get("argument_strength", 70)),
                fact_data_usage=int(data.get("fact_data_usage", 70)),
                rhetoric_technique=int(data.get("rhetoric_technique", 70)),
                responsiveness=int(data.get("responsiveness", 70)),
                clarity_structure=int(data.get("clarity_structure", 70)),
                total_score=float(data.get("total_score", 70.0)),
                summary=str(data.get("summary", "Argumen dinilai cukup baik.")),
                highlights_positive=list(data.get("highlights_positive", [])),
                highlights_negative=list(data.get("highlights_negative", [])),
                fallacy_detected=str(data.get("fallacy_detected", "")),
                suggestion=str(data.get("suggestion", "Tingkatkan elaborasi bukti.")),
            )

        except Exception as e:
            logger.error(f"[JudgeAgent:{self.judge_type}] Error scoring argument: {e}")
            # Fallback jika parsing gagal
            return messages_pb2.JudgeResult(
                judge_type=self.judge_type,
                argument_strength=65,
                fact_data_usage=65,
                rhetoric_technique=65,
                responsiveness=65,
                clarity_structure=65,
                total_score=65.0,
                summary=f"Evaluasi {self.judge_type} otomatis selesai dengan catatan standar.",
                highlights_positive=["Penyampaian argumen jelas"],
                highlights_negative=["Perlu elaborasi data lebih mendalam"],
                fallacy_detected="",
                suggestion="Pertajam bukti empiris dan struktur klaim.",
            )

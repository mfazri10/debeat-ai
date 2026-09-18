"use client";

import React, { useState } from "react";
import { Bot, Sparkles, Sliders } from "lucide-react";
import { Persona } from "@/types/admin";
import { Toast } from "@/components/common/toast";

const initialPersonas: Persona[] = [
  {
    id: "p-1",
    name: "Presiden RI",
    lang: "ID",
    style: "Tenang, terstruktur, diplomatis, mengutamakan kepentingan nasional dan keharmonisan sosial.",
    stance: "NEUTRAL",
    usage: "4,120x",
    category: "GOVERNMENT",
  },
  {
    id: "p-2",
    name: "Menteri Keuangan",
    lang: "ID",
    style: "Rasional, tajam berbasis data fiskal, ketat pada efisiensi anggaran dan keberlanjutan APBN.",
    stance: "NEUTRAL",
    usage: "3,890x",
    category: "GOVERNMENT",
  },
  {
    id: "p-3",
    name: "Hakim Mahkamah Konstitusi",
    lang: "ID",
    style: "Analitis, merujuk hierarki perundang-undangan, hak konstitusional warga, dan doktrin hukum.",
    stance: "NEUTRAL",
    usage: "2,450x",
    category: "LEGAL",
  },
  {
    id: "p-4",
    name: "Aktivis Lingkungan",
    lang: "ID",
    style: "Persuasif, retorika krisis iklim, determinasi moral tinggi, menuntut keadilan ekologis.",
    stance: "PRO",
    usage: "1,980x",
    category: "ACTIVIST",
  },
  {
    id: "p-5",
    name: "Silicon Valley Tech CEO",
    lang: "EN",
    style: "Visioner, akseleratif, memprioritaskan disrupsi teknologi, kebebasan inovasi, dan efisiensi pasar.",
    stance: "PRO",
    usage: "3,110x",
    category: "INDUSTRY",
  },
  {
    id: "p-6",
    name: "Harvard Professor",
    lang: "EN",
    style: "Metodis, menguji premis logis, mengutip literatur empiris, membongkar bias kognitif.",
    stance: "NEUTRAL",
    usage: "2,840x",
    category: "ACADEMIC",
  },
];

export function PersonaGrid() {
  const [personas] = useState<Persona[]>(initialPersonas);
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  return (
    <div className="space-y-6">
      <Toast message={toastMsg} />

      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Katalog Persona & Agen AI</h2>
          <p className="text-xs text-slate-400">
            Kelola karakter lawan debat, instruksi sistem gaya bicara, dan stance default.
          </p>
        </div>
        <button
          onClick={() => showToast("Modal pembuatan persona baru dibuka.")}
          className="bg-blue-600 text-white font-medium px-4 py-2 rounded-xl text-xs hover:bg-blue-500 flex items-center gap-2 shadow-lg shadow-blue-600/20"
        >
          <Sparkles className="w-3.5 h-3.5" />
          <span>+ Tambah Persona Baru</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {personas.map((p) => (
          <div
            key={p.id}
            className="bg-[#0F1422] border border-slate-800 rounded-2xl p-5 flex flex-col justify-between space-y-4 hover:border-slate-700 transition-all"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-lg bg-blue-600/20 flex items-center justify-center text-blue-400">
                    <Bot className="w-4 h-4" />
                  </div>
                  <h4 className="font-bold text-white text-base">{p.name}</h4>
                </div>
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-500/20 text-blue-300 border border-blue-500/30">
                  {p.lang}
                </span>
              </div>
              <p className="text-xs text-slate-400 line-clamp-3 mt-2">{p.style}</p>
            </div>
            <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-500">
              <span>
                Dipakai: <b className="text-slate-300 font-mono">{p.usage}</b>
              </span>
              <button
                onClick={() => showToast(`Konfigurasi prompt [${p.name}] dibuka untuk editing.`)}
                className="text-blue-400 hover:text-blue-300 font-medium flex items-center gap-1"
              >
                <Sliders className="w-3 h-3" />
                <span>Edit Prompt</span>
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

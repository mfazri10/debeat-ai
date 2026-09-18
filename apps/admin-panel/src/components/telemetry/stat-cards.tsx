"use client";

import React from "react";
import { Radio, Cpu, Scale, BookOpen } from "lucide-react";

export function StatCards() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-5">
      <div className="bg-[#0F1422] border border-slate-800 p-5 rounded-2xl relative overflow-hidden">
        <div className="flex items-center justify-between text-slate-400 mb-2">
          <span className="text-xs font-semibold uppercase tracking-wider">
            Sesi Debat Berjalan
          </span>
          <Radio className="w-4 h-4 text-emerald-400 animate-pulse" />
        </div>
        <div className="text-3xl font-black text-white">14</div>
        <p className="text-xs text-emerald-400 mt-1 flex items-center gap-1 font-medium">
          +4 sesi dalam 15 menit terakhir
        </p>
      </div>

      <div className="bg-[#0F1422] border border-slate-800 p-5 rounded-2xl relative overflow-hidden">
        <div className="flex items-center justify-between text-slate-400 mb-2">
          <span className="text-xs font-semibold uppercase tracking-wider">
            AI Token Incurred (Today)
          </span>
          <Cpu className="w-4 h-4 text-blue-400" />
        </div>
        <div className="text-3xl font-black text-white">1.84M</div>
        <p className="text-xs text-slate-400 mt-1 flex items-center gap-1">
          Cost: <span className="text-emerald-400 font-mono font-semibold">$3.42 USD</span>
        </p>
      </div>

      <div className="bg-[#0F1422] border border-slate-800 p-5 rounded-2xl relative overflow-hidden">
        <div className="flex items-center justify-between text-slate-400 mb-2">
          <span className="text-xs font-semibold uppercase tracking-wider">
            Rata-Rata Skor Juri
          </span>
          <Scale className="w-4 h-4 text-amber-400" />
        </div>
        <div className="text-3xl font-black text-white">76.4</div>
        <p className="text-xs text-slate-400 mt-1">
          Rubrik: Logika (30%), Retorika (20%), Dampak
        </p>
      </div>

      <div className="bg-[#0F1422] border border-slate-800 p-5 rounded-2xl relative overflow-hidden">
        <div className="flex items-center justify-between text-slate-400 mb-2">
          <span className="text-xs font-semibold uppercase tracking-wider">
            Total RAG Chunks
          </span>
          <BookOpen className="w-4 h-4 text-purple-400" />
        </div>
        <div className="text-3xl font-black text-white">18,420</div>
        <p className="text-xs text-purple-400 mt-1">
          Dimensi 768d (IVFFlat indexed)
        </p>
      </div>
    </div>
  );
}

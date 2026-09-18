"use client";

import React from "react";
import { Cpu, ShieldCheck } from "lucide-react";
import { CircuitBreakerState } from "@/types/admin";

interface CircuitBreakerProps {
  data?: CircuitBreakerState;
}

const defaultData: CircuitBreakerState = {
  gemini: { status: "HEALTHY", latency: 240, calls: 14209, errorRate: 0.04 },
  openai: { status: "HEALTHY", latency: 310, calls: 3410, errorRate: 0.12 },
  claude: { status: "STANDBY", latency: 290, calls: 1205, errorRate: 0.08 },
};

export function CircuitBreakerPanel({ data = defaultData }: CircuitBreakerProps) {
  return (
    <div className="bg-[#0F1422] border border-slate-800 rounded-2xl p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-base font-bold text-white flex items-center gap-2">
            <Cpu className="w-5 h-5 text-blue-400" />
            Status AI Provider Chain & Circuit Breaker
          </h3>
          <p className="text-xs text-slate-400">
            Fallback Otomatis: Gemini 2.0 Flash (Primary) → OpenAI GPT-4o-mini (Secondary) → Claude 3.5 Haiku (Tertiary)
          </p>
        </div>
        <span className="text-xs font-mono text-slate-400 bg-slate-900 border border-slate-800 px-2.5 py-1 rounded-md">
          Threshold: 3 gagal · Recovery: 5m
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
        <div className="bg-slate-950/60 border border-emerald-900/40 p-4 rounded-xl space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-bold text-sm text-slate-200">Google Gemini</span>
            <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
              {data.gemini.status} (Primary)
            </span>
          </div>
          <div className="flex justify-between text-xs text-slate-400">
            <span>Rata-Rata Latensi:</span>
            <span className="text-slate-200 font-mono font-semibold">{data.gemini.latency} ms</span>
          </div>
          <div className="flex justify-between text-xs text-slate-400">
            <span>Total Panggilan Hari Ini:</span>
            <span className="text-slate-200 font-mono">{data.gemini.calls.toLocaleString()}</span>
          </div>
        </div>

        <div className="bg-slate-950/60 border border-slate-800 p-4 rounded-xl space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-bold text-sm text-slate-200">OpenAI (GPT-4o)</span>
            <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-blue-500/20 text-blue-400 border border-blue-500/30">
              {data.openai.status} (Fallback 1)
            </span>
          </div>
          <div className="flex justify-between text-xs text-slate-400">
            <span>Rata-Rata Latensi:</span>
            <span className="text-slate-200 font-mono font-semibold">{data.openai.latency} ms</span>
          </div>
          <div className="flex justify-between text-xs text-slate-400">
            <span>Total Panggilan Hari Ini:</span>
            <span className="text-slate-200 font-mono">{data.openai.calls.toLocaleString()}</span>
          </div>
        </div>

        <div className="bg-slate-950/60 border border-slate-800 p-4 rounded-xl space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-bold text-sm text-slate-200">Anthropic Claude</span>
            <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-purple-500/20 text-purple-400 border border-purple-500/30">
              {data.claude.status} (Fallback 2)
            </span>
          </div>
          <div className="flex justify-between text-xs text-slate-400">
            <span>Rata-Rata Latensi:</span>
            <span className="text-slate-200 font-mono font-semibold">{data.claude.latency} ms</span>
          </div>
          <div className="flex justify-between text-xs text-slate-400">
            <span>Total Panggilan Hari Ini:</span>
            <span className="text-slate-200 font-mono">{data.claude.calls.toLocaleString()}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

"use client";

import React from "react";
import { Flame, Shield, Activity } from "lucide-react";

export function Header() {
  return (
    <header className="border-b border-slate-800/80 bg-[#0C101B]/90 backdrop-blur-md sticky top-0 z-40 px-6 py-3.5 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-500 flex items-center justify-center shadow-lg shadow-blue-500/20">
          <Flame className="w-6 h-6 text-white" />
        </div>
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-lg font-bold tracking-tight text-white">
              DebateAI Control Center
            </h1>
            <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs px-2 py-0.5 rounded-full font-mono font-medium">
              v2.1 Microservices
            </span>
          </div>
          <p className="text-xs text-slate-400">
            Go Echo Gateway (8080) ↔ Python gRPC Engine (50051) ↔ PostgreSQL 16 pgvector
          </p>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-lg text-xs font-mono text-slate-300">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>gRPC Streaming: Active (0.9ms)</span>
        </div>
        <div className="flex items-center gap-2 bg-blue-950/40 border border-blue-800/50 px-3 py-1.5 rounded-lg text-xs font-medium text-blue-300">
          <Shield className="w-3.5 h-3.5" />
          <span>Superadmin: Muhammad Fazri</span>
        </div>
      </div>
    </header>
  );
}

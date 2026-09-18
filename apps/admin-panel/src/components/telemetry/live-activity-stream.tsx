"use client";

import React from "react";
import { Activity } from "lucide-react";
import { ActivityStreamItem } from "@/types/admin";

interface LiveActivityStreamProps {
  items?: ActivityStreamItem[];
}

const defaultItems: ActivityStreamItem[] = [
  {
    id: "act-1",
    title: "Sesi #deb-842: Argumen Round 2 Diajukan",
    detail: "Topik: \"Adopsi AI dalam Pendidikan Tinggi\" • User vs AI (Presiden RI)",
    scoreOrReaction: "Skor Juri: 82/100",
    timestamp: "12 detik lalu",
    type: "ARGUMENT",
  },
  {
    id: "act-2",
    title: "Reaksi Penonton Live Dipicu",
    detail: "Reaksi: 👏 CLAP (Intensitas: 88%) • 6 komentar tersintesis",
    scoreOrReaction: "Sentimen: Positif",
    timestamp: "35 detik lalu",
    type: "REACTION",
  },
];

export function LiveActivityStream({ items = defaultItems }: LiveActivityStreamProps) {
  return (
    <div className="bg-[#0F1422] border border-slate-800 rounded-2xl p-6 space-y-4">
      <h3 className="text-base font-bold text-white flex items-center gap-2">
        <Activity className="w-5 h-5 text-emerald-400" />
        Live Arena Debate Activity Stream
      </h3>
      <div className="space-y-3">
        {items.map((item) => (
          <div
            key={item.id}
            className="p-3.5 bg-slate-950/50 border border-slate-800/80 rounded-xl flex items-center justify-between text-sm"
          >
            <div className="flex items-center gap-3">
              <span
                className={`w-2.5 h-2.5 rounded-full ${
                  item.type === "ARGUMENT"
                    ? "bg-emerald-400"
                    : item.type === "REACTION"
                    ? "bg-purple-400"
                    : "bg-amber-400"
                }`}
              />
              <div>
                <p className="font-semibold text-white">{item.title}</p>
                <p className="text-xs text-slate-400">{item.detail}</p>
              </div>
            </div>
            <div className="text-right">
              <span
                className={`text-xs font-mono font-semibold ${
                  item.type === "ARGUMENT" ? "text-blue-400" : "text-purple-400"
                }`}
              >
                {item.scoreOrReaction}
              </span>
              <p className="text-[11px] text-slate-500">{item.timestamp}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

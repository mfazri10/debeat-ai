"use client";

import React, { useState } from "react";
import { Search } from "lucide-react";
import { DebateSession } from "@/types/admin";
import { Toast } from "@/components/common/toast";

const initialSessions: DebateSession[] = [
  {
    id: "sess-1",
    roomCode: "#RM-4821",
    topic: "Adopsi AI dalam Pendidikan Tinggi",
    participant: "user_ahmad",
    opponent: "AI Lawan (Presiden RI)",
    format: "KDMI",
    status: "ONGOING",
    round: "Ronde 2/3",
  },
  {
    id: "sess-2",
    roomCode: "#RM-9014",
    topic: "Universal Basic Income vs Conditional Welfare",
    participant: "claudia_en",
    opponent: "AI Lawan (Menteri Keuangan)",
    format: "OXFORD",
    status: "ONGOING",
    round: "Ronde 1/3",
  },
  {
    id: "sess-3",
    roomCode: "#RM-3190",
    topic: "Eksplorasi Ruang Angkasa vs Penanganan Kemiskinan Bumi",
    participant: "kevin_debater",
    opponent: "AI Lawan (Harvard Professor)",
    format: "WUDC",
    status: "ONGOING",
    round: "Ronde 3/3",
  },
];

export function SessionTable() {
  const [sessions, setSessions] = useState<DebateSession[]>(initialSessions);
  const [search, setSearch] = useState("");
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  const handlePause = (roomCode: string) => {
    setSessions((prev) =>
      prev.map((s) =>
        s.roomCode === roomCode
          ? { ...s, status: s.status === "PAUSED" ? "ONGOING" : "PAUSED" }
          : s
      )
    );
    showToast(`Status sesi ${roomCode} berhasil diperbarui.`);
  };

  const handleEnd = (roomCode: string) => {
    setSessions((prev) => prev.filter((s) => s.roomCode !== roomCode));
    showToast(`Sesi ${roomCode} berhasil dihentikan (TERMINATED).`);
  };

  const filteredSessions = sessions.filter(
    (s) =>
      s.roomCode.toLowerCase().includes(search.toLowerCase()) ||
      s.topic.toLowerCase().includes(search.toLowerCase()) ||
      s.participant.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <Toast message={toastMsg} />

      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Monitor Sesi Debat Real-Time</h2>
          <p className="text-xs text-slate-400">
            Daftar arena debat aktif, pemantauan giliran, dan kontrol darurat sesi.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Cari Room Code atau Topik..."
              className="bg-slate-900 border border-slate-700 pl-9 pr-3 py-1.5 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 w-64"
            />
          </div>
        </div>
      </div>

      <div className="bg-[#0F1422] border border-slate-800 rounded-2xl overflow-hidden">
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-900/80 text-xs uppercase text-slate-400 border-b border-slate-800">
            <tr>
              <th className="px-5 py-3">Room Code</th>
              <th className="px-5 py-3">Topik / Mosi</th>
              <th className="px-5 py-3">Format</th>
              <th className="px-5 py-3">Status</th>
              <th className="px-5 py-3">Ronde</th>
              <th className="px-5 py-3 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filteredSessions.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-5 py-8 text-center text-slate-500 text-xs">
                  Tidak ada sesi debat yang cocok dengan pencarian.
                </td>
              </tr>
            ) : (
              filteredSessions.map((session) => (
                <tr key={session.id} className="hover:bg-slate-900/40">
                  <td className="px-5 py-4 font-mono font-bold text-blue-400">
                    {session.roomCode}
                  </td>
                  <td className="px-5 py-4 text-white font-medium">
                    {session.topic}
                    <p className="text-xs text-slate-400">
                      Peserta: {session.participant} vs {session.opponent}
                    </p>
                  </td>
                  <td className="px-5 py-4 font-mono text-xs">{session.format}</td>
                  <td className="px-5 py-4">
                    <span
                      className={`text-xs px-2 py-0.5 rounded-full border ${
                        session.status === "ONGOING"
                          ? "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
                          : "bg-amber-500/20 text-amber-400 border-amber-500/30"
                      }`}
                    >
                      {session.status}
                    </span>
                  </td>
                  <td className="px-5 py-4 font-mono text-xs">{session.round}</td>
                  <td className="px-5 py-4 text-right space-x-2">
                    <button
                      onClick={() => handlePause(session.roomCode)}
                      className="bg-amber-600/20 text-amber-400 border border-amber-500/30 px-3 py-1 rounded-lg text-xs hover:bg-amber-600/30 font-medium"
                    >
                      {session.status === "PAUSED" ? "Resume" : "Pause"}
                    </button>
                    <button
                      onClick={() => handleEnd(session.roomCode)}
                      className="bg-rose-600/20 text-rose-400 border border-rose-500/30 px-3 py-1 rounded-lg text-xs hover:bg-rose-600/30 font-medium"
                    >
                      End
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

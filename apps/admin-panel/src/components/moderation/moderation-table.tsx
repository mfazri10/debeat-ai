"use client";

import React, { useState } from "react";
import { Shield, AlertTriangle } from "lucide-react";
import { ModerationReport } from "@/types/admin";
import { Toast } from "@/components/common/toast";

const initialReports: ModerationReport[] = [
  {
    id: "rep-001",
    reporter: "dewi_putri",
    reported: "troll_user_99",
    reason: "HATE_SPEECH",
    description: "Menyerang etnis lawan di round 2 sesi KDMI",
    status: "PENDING",
    strike: 2,
  },
  {
    id: "rep-002",
    reporter: "ahmad_fauzi",
    reported: "bot_spammer",
    reason: "SPAM",
    description: "Mengirimkan teks promosi berulang-ulang tanpa argumen",
    status: "PENDING",
    strike: 3,
  },
];

export function ModerationTable() {
  const [reports, setReports] = useState<ModerationReport[]>(initialReports);
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3500);
  };

  const handleAction = (id: string, action: string) => {
    setReports((prev) => prev.filter((r) => r.id !== id));
    showToast(`Tindakan [${action}] berhasil diterapkan dan dicatat di AdminAuditLog.`);
  };

  return (
    <div className="space-y-6">
      <Toast message={toastMsg} />

      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white">Sistem Moderasi & Laporan Pengguna</h2>
          <p className="text-xs text-slate-400">
            Eksekusi sistem 3-Strike Warning → Suspend Otomatis → Ban Permanen sesuai standar PRD §17.3.
          </p>
        </div>
      </div>

      <div className="bg-[#0F1422] border border-slate-800 rounded-2xl overflow-hidden">
        <div className="p-4 bg-slate-900/60 border-b border-slate-800 font-semibold text-sm text-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-rose-400" />
            <span>Laporan Pelanggaran Aktif (`user_reports`)</span>
          </div>
          <span className="text-xs bg-rose-500/20 text-rose-300 font-mono px-2 py-0.5 rounded-full border border-rose-500/30">
            {reports.length} Perlu Tindakan
          </span>
        </div>

        {reports.length === 0 ? (
          <div className="p-8 text-center text-sm text-slate-500">
            Semua laporan pelanggaran telah ditinjau dan ditindaklanjuti.
          </div>
        ) : (
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-950 text-xs uppercase text-slate-400 border-b border-slate-800">
              <tr>
                <th className="px-5 py-3">Terlapor</th>
                <th className="px-5 py-3">Alasan</th>
                <th className="px-5 py-3">Keterangan</th>
                <th className="px-5 py-3">Akumulasi Strike</th>
                <th className="px-5 py-3 text-right">Tindakan Moderasi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {reports.map((r) => (
                <tr key={r.id} className="hover:bg-slate-900/40">
                  <td className="px-5 py-4 font-mono font-bold text-rose-400">
                    @{r.reported}
                  </td>
                  <td className="px-5 py-4">
                    <span className="bg-rose-500/20 text-rose-400 border border-rose-500/30 text-xs px-2 py-0.5 rounded-full font-mono">
                      {r.reason}
                    </span>
                  </td>
                  <td className="px-5 py-4 text-xs text-slate-300">{r.description}</td>
                  <td className="px-5 py-4 text-xs font-mono font-semibold text-amber-400">
                    {r.strike}/3 Peringatan
                  </td>
                  <td className="px-5 py-4 text-right space-x-2">
                    <button
                      onClick={() => handleAction(r.id, "WARNING_GIVEN")}
                      className="bg-amber-600/20 text-amber-400 border border-amber-500/30 px-3 py-1 rounded-lg text-xs hover:bg-amber-600/30"
                    >
                      Beri Peringatan (+1)
                    </button>
                    <button
                      onClick={() => handleAction(r.id, "SUSPEND_7_DAYS")}
                      className="bg-orange-600/20 text-orange-400 border border-orange-500/30 px-3 py-1 rounded-lg text-xs hover:bg-orange-600/30"
                    >
                      Suspend (7 Hari)
                    </button>
                    <button
                      onClick={() => handleAction(r.id, "PERMANENT_BAN")}
                      className="bg-rose-600/30 text-rose-300 border border-rose-500/40 px-3 py-1 rounded-lg text-xs hover:bg-rose-600/50 font-bold"
                    >
                      Ban Permanen
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

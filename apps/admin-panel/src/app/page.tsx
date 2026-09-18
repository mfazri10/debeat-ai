"use client";

import React, { useState } from "react";
import {
  Activity,
  Shield,
  Bot,
  Database,
  Users,
  AlertTriangle,
  Radio,
  FileText,
  DollarSign,
  Cpu,
  CheckCircle2,
  XCircle,
  Clock,
  Send,
  Eye,
  Settings,
  Flame,
  Search,
  BookOpen,
  Scale,
  Award,
} from "lucide-react";

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState<
    "overview" | "sessions" | "personas" | "knowledge" | "moderation"
  >("overview");

  // State mock untuk interaktivitas real-time
  const [circuitBreaker, setCircuitBreaker] = useState({
    gemini: { status: "HEALTHY", latency: 240, calls: 14209, errorRate: 0.04 },
    openai: { status: "HEALTHY", latency: 310, calls: 3410, errorRate: 0.12 },
    claude: { status: "STANDBY", latency: 290, calls: 1205, errorRate: 0.08 },
  });

  const [submissions, setSubmissions] = useState([
    {
      id: "sub-101",
      title: "Risalah Sidang MK RI: Sengketa UU Cipta Kerja 2024",
      user: "budi_santoso@gmail.com",
      sourceUrl: "https://mkri.id/risalah/perkara-91",
      status: "PENDING",
      date: "2026-09-18 19:40",
    },
    {
      id: "sub-102",
      title: "Transkrip ILC: Polemik Pajak Karbon & Efisiensi Energi",
      user: "sarah.advokat@yahoo.co.id",
      sourceUrl: "https://youtube.com/watch?v=ilc_transkrip_88",
      status: "PENDING",
      date: "2026-09-18 20:15",
    },
    {
      id: "sub-103",
      title: "WUDC 2025 Motion Dossier: Frontier AI Regulation",
      user: "kevin_debater@ugm.ac.id",
      sourceUrl: "https://wudc.org/dossiers/ai_motions_2025.pdf",
      status: "APPROVED",
      date: "2026-09-18 16:30",
    },
  ]);

  const [reports, setReports] = useState([
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
      description: "Mengirimkan teks promosi berulang-ulang",
      status: "PENDING",
      strike: 3,
    },
  ]);

  const [notification, setNotification] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setNotification(msg);
    setTimeout(() => setNotification(null), 3500);
  };

  const handleApproveSubmission = (id: string) => {
    setSubmissions((prev) =>
      prev.map((s) => (s.id === id ? { ...s, status: "APPROVED" } : s))
    );
    showToast(`Dokumen ${id} disetujui dan otomatis dijadwalkan untuk RAG Chunking (pgvector 768d).`);
  };

  const handleRejectSubmission = (id: string) => {
    setSubmissions((prev) =>
      prev.map((s) => (s.id === id ? { ...s, status: "REJECTED" } : s))
    );
    showToast(`Dokumen ${id} ditolak.`);
  };

  const handleActionReport = (id: string, action: string) => {
    setReports((prev) => prev.filter((r) => r.id !== id));
    showToast(`Tindakan [${action}] berhasil diterapkan dan dicatat di AdminAuditLog.`);
  };

  return (
    <div className="min-h-screen flex flex-col bg-[#080B11] text-slate-100">
      {/* Toast Notification */}
      {notification && (
        <div className="fixed bottom-6 right-6 z-50 bg-blue-600 text-white px-5 py-3 rounded-xl shadow-2xl flex items-center gap-3 border border-blue-400/30 animate-bounce">
          <CheckCircle2 className="w-5 h-5 text-white" />
          <span className="text-sm font-medium">{notification}</span>
        </div>
      )}

      {/* Top Header & Telemetry Bar */}
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

      {/* Main Content Layout */}
      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar Nav */}
        <aside className="w-64 border-r border-slate-800/80 bg-[#0A0E18] p-4 flex flex-col justify-between shrink-0">
          <div className="space-y-1">
            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider px-3 mb-2">
              Navigasi Admin
            </p>

            <button
              onClick={() => setActiveTab("overview")}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                activeTab === "overview"
                  ? "bg-blue-600/15 text-blue-400 border border-blue-500/30 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-900/60"
              }`}
            >
              <Activity className="w-4 h-4" />
              <span>Overview & AI Telemetry</span>
            </button>

            <button
              onClick={() => setActiveTab("sessions")}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                activeTab === "sessions"
                  ? "bg-blue-600/15 text-blue-400 border border-blue-500/30 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-900/60"
              }`}
            >
              <Radio className="w-4 h-4" />
              <span>Live Debate Sessions</span>
              <span className="ml-auto bg-blue-500/20 text-blue-400 text-[10px] px-1.5 py-0.5 rounded-full font-mono">
                14 Aktif
              </span>
            </button>

            <button
              onClick={() => setActiveTab("personas")}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                activeTab === "personas"
                  ? "bg-blue-600/15 text-blue-400 border border-blue-500/30 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-900/60"
              }`}
            >
              <Bot className="w-4 h-4" />
              <span>Persona & Juri AI</span>
            </button>

            <button
              onClick={() => setActiveTab("knowledge")}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                activeTab === "knowledge"
                  ? "bg-blue-600/15 text-blue-400 border border-blue-500/30 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-900/60"
              }`}
            >
              <Database className="w-4 h-4" />
              <span>RAG Knowledge Base</span>
              <span className="ml-auto bg-amber-500/20 text-amber-400 text-[10px] px-1.5 py-0.5 rounded-full font-mono">
                2 Antri
              </span>
            </button>

            <button
              onClick={() => setActiveTab("moderation")}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                activeTab === "moderation"
                  ? "bg-blue-600/15 text-blue-400 border border-blue-500/30 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-900/60"
              }`}
            >
              <Shield className="w-4 h-4" />
              <span>Moderasi & Laporan</span>
              <span className="ml-auto bg-rose-500/20 text-rose-400 text-[10px] px-1.5 py-0.5 rounded-full font-mono">
                {reports.length}
              </span>
            </button>
          </div>

          <div className="p-3 bg-slate-900/70 border border-slate-800 rounded-xl space-y-2">
            <div className="flex items-center justify-between text-xs text-slate-400">
              <span>Database (PostgreSQL)</span>
              <span className="text-emerald-400 font-mono">24 Tabel</span>
            </div>
            <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden">
              <div className="bg-emerald-500 h-full w-[94%]" />
            </div>
            <p className="text-[10px] text-slate-500">
              pgvector: 768 dimensi (Gemini)
            </p>
          </div>
        </aside>

        {/* Dynamic Main Workspace */}
        <main className="flex-1 overflow-y-auto p-8 space-y-8">
          {/* TAB 1: OVERVIEW */}
          {activeTab === "overview" && (
            <div className="space-y-8">
              {/* Top Stat Cards */}
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

              {/* Circuit Breaker & Multi-Provider Health */}
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
                        {circuitBreaker.gemini.status} (Primary)
                      </span>
                    </div>
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>Rata-Rata Latensi:</span>
                      <span className="text-slate-200 font-mono font-semibold">{circuitBreaker.gemini.latency} ms</span>
                    </div>
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>Total Panggilan Hari Ini:</span>
                      <span className="text-slate-200 font-mono">{circuitBreaker.gemini.calls.toLocaleString()}</span>
                    </div>
                  </div>

                  <div className="bg-slate-950/60 border border-slate-800 p-4 rounded-xl space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-sm text-slate-200">OpenAI (GPT-4o)</span>
                      <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-blue-500/20 text-blue-400 border border-blue-500/30">
                        {circuitBreaker.openai.status} (Fallback 1)
                      </span>
                    </div>
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>Rata-Rata Latensi:</span>
                      <span className="text-slate-200 font-mono font-semibold">{circuitBreaker.openai.latency} ms</span>
                    </div>
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>Total Panggilan Hari Ini:</span>
                      <span className="text-slate-200 font-mono">{circuitBreaker.openai.calls.toLocaleString()}</span>
                    </div>
                  </div>

                  <div className="bg-slate-950/60 border border-slate-800 p-4 rounded-xl space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-sm text-slate-200">Anthropic Claude</span>
                      <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-purple-500/20 text-purple-400 border border-purple-500/30">
                        {circuitBreaker.claude.status} (Fallback 2)
                      </span>
                    </div>
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>Rata-Rata Latensi:</span>
                      <span className="text-slate-200 font-mono font-semibold">{circuitBreaker.claude.latency} ms</span>
                    </div>
                    <div className="flex justify-between text-xs text-slate-400">
                      <span>Total Panggilan Hari Ini:</span>
                      <span className="text-slate-200 font-mono">{circuitBreaker.claude.calls.toLocaleString()}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Live Live Feed */}
              <div className="bg-[#0F1422] border border-slate-800 rounded-2xl p-6 space-y-4">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Activity className="w-5 h-5 text-emerald-400" />
                  Live Arena Debate Activity Stream
                </h3>
                <div className="space-y-3">
                  <div className="p-3.5 bg-slate-950/50 border border-slate-800/80 rounded-xl flex items-center justify-between text-sm">
                    <div className="flex items-center gap-3">
                      <span className="w-2.5 h-2.5 rounded-full bg-emerald-400" />
                      <div>
                        <p className="font-semibold text-white">
                          Sesi #deb-842: Argumen Round 2 Diajukan
                        </p>
                        <p className="text-xs text-slate-400">
                          Topik: "Adopsi AI dalam Pendidikan Tinggi" • User vs AI (Presiden RI)
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-xs text-blue-400 font-mono font-semibold">Skor Juri: 82/100</span>
                      <p className="text-[11px] text-slate-500">12 detik lalu</p>
                    </div>
                  </div>

                  <div className="p-3.5 bg-slate-950/50 border border-slate-800/80 rounded-xl flex items-center justify-between text-sm">
                    <div className="flex items-center gap-3">
                      <span className="w-2.5 h-2.5 rounded-full bg-purple-400" />
                      <div>
                        <p className="font-semibold text-white">
                          Reaksi Penonton Live Dipicu
                        </p>
                        <p className="text-xs text-slate-400">
                          Reaksi: 👏 CLAP (Intensitas: 88%) • 6 komentar tersintesis
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-xs text-purple-400 font-mono">Sentimen: Positif</span>
                      <p className="text-[11px] text-slate-500">35 detik lalu</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: SESSIONS MONITOR */}
          {activeTab === "sessions" && (
            <div className="space-y-6">
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
                      placeholder="Cari Room Code..."
                      className="bg-slate-900 border border-slate-700 pl-9 pr-3 py-1.5 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
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
                    <tr className="hover:bg-slate-900/40">
                      <td className="px-5 py-4 font-mono font-bold text-blue-400">#RM-4821</td>
                      <td className="px-5 py-4 text-white font-medium">
                        Adopsi AI dalam Pendidikan Tinggi
                        <p className="text-xs text-slate-400">Peserta: user_ahmad vs AI Lawan</p>
                      </td>
                      <td className="px-5 py-4 font-mono text-xs">KDMI</td>
                      <td className="px-5 py-4">
                        <span className="bg-emerald-500/20 text-emerald-400 text-xs px-2 py-0.5 rounded-full border border-emerald-500/30">
                          ONGOING
                        </span>
                      </td>
                      <td className="px-5 py-4 font-mono text-xs">Ronde 2/3</td>
                      <td className="px-5 py-4 text-right space-x-2">
                        <button
                          onClick={() => showToast("Sesi #RM-4821 dijeda (PAUSED).")}
                          className="bg-amber-600/20 text-amber-400 border border-amber-500/30 px-3 py-1 rounded-lg text-xs hover:bg-amber-600/30"
                        >
                          Pause
                        </button>
                        <button
                          onClick={() => showToast("Sesi #RM-4821 dihentikan (TERMINATED).")}
                          className="bg-rose-600/20 text-rose-400 border border-rose-500/30 px-3 py-1 rounded-lg text-xs hover:bg-rose-600/30"
                        >
                          End
                        </button>
                      </td>
                    </tr>
                    <tr className="hover:bg-slate-900/40">
                      <td className="px-5 py-4 font-mono font-bold text-blue-400">#RM-9014</td>
                      <td className="px-5 py-4 text-white font-medium">
                        Universal Basic Income vs Conditional Welfare
                        <p className="text-xs text-slate-400">Peserta: claudia_en vs AI Lawan</p>
                      </td>
                      <td className="px-5 py-4 font-mono text-xs">OXFORD</td>
                      <td className="px-5 py-4">
                        <span className="bg-emerald-500/20 text-emerald-400 text-xs px-2 py-0.5 rounded-full border border-emerald-500/30">
                          ONGOING
                        </span>
                      </td>
                      <td className="px-5 py-4 font-mono text-xs">Ronde 1/3</td>
                      <td className="px-5 py-4 text-right space-x-2">
                        <button
                          onClick={() => showToast("Sesi #RM-9014 dijeda.")}
                          className="bg-amber-600/20 text-amber-400 border border-amber-500/30 px-3 py-1 rounded-lg text-xs hover:bg-amber-600/30"
                        >
                          Pause
                        </button>
                        <button
                          onClick={() => showToast("Sesi #RM-9014 dihentikan.")}
                          className="bg-rose-600/20 text-rose-400 border border-rose-500/30 px-3 py-1 rounded-lg text-xs hover:bg-rose-600/30"
                        >
                          End
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 3: PERSONAS */}
          {activeTab === "personas" && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-white">Katalog Persona & Agen AI</h2>
                  <p className="text-xs text-slate-400">
                    Kelola karakter lawan debat, instruksi sistem gaya bicara, dan stance default.
                  </p>
                </div>
                <button
                  onClick={() => showToast("Modal pembuatan persona baru siap dibuka.")}
                  className="bg-blue-600 text-white font-medium px-4 py-2 rounded-xl text-xs hover:bg-blue-500 flex items-center gap-2"
                >
                  + Tambah Persona Baru
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                {[
                  {
                    name: "Presiden RI",
                    lang: "ID",
                    style: "Tenang, terstruktur, diplomatis, mengutamakan kepentingan nasional.",
                    stance: "NEUTRAL",
                    usage: "4,120x",
                  },
                  {
                    name: "Menteri Keuangan",
                    lang: "ID",
                    style: "Rasional, tajam berbasis data fiskal, ketat pada efisiensi anggaran.",
                    stance: "NEUTRAL",
                    usage: "3,890x",
                  },
                  {
                    name: "Hakim Mahkamah Konstitusi",
                    lang: "ID",
                    style: "Analitis, merujuk hierarki perundang-undangan dan hak asasi.",
                    stance: "NEUTRAL",
                    usage: "2,450x",
                  },
                  {
                    name: "Aktivis Lingkungan",
                    lang: "ID",
                    style: "Persuasif, retorika krisis iklim, determinasi moral tinggi.",
                    stance: "PRO",
                    usage: "1,980x",
                  },
                  {
                    name: "Silicon Valley Tech CEO",
                    lang: "EN",
                    style: "Visioner, akseleratif, memprioritaskan disrupsi teknologi dan pasar.",
                    stance: "PRO",
                    usage: "3,110x",
                  },
                  {
                    name: "Harvard Professor",
                    lang: "EN",
                    style: "Metodis, menguji premis logis, mengutip literatur empiris.",
                    stance: "NEUTRAL",
                    usage: "2,840x",
                  },
                ].map((p, i) => (
                  <div
                    key={i}
                    className="bg-[#0F1422] border border-slate-800 rounded-2xl p-5 flex flex-col justify-between space-y-4"
                  >
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="font-bold text-white text-base">{p.name}</h4>
                        <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-500/20 text-blue-300">
                          {p.lang}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 line-clamp-3">{p.style}</p>
                    </div>
                    <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-500">
                      <span>Dipakai: <b className="text-slate-300 font-mono">{p.usage}</b></span>
                      <button
                        onClick={() => showToast(`Konfigurasi prompt [${p.name}] disimpan.`)}
                        className="text-blue-400 hover:text-blue-300 font-medium"
                      >
                        Edit Prompt
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* TAB 4: KNOWLEDGE BASE */}
          {activeTab === "knowledge" && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-white">Kurasi Knowledge Base & RAG Pipeline</h2>
                  <p className="text-xs text-slate-400">
                    Review kiriman dokumen komunitas (`kb_submissions`), trigger ingestion, dan verifikasi embedding 768d.
                  </p>
                </div>
                <button
                  onClick={() => showToast("Memicu pipeline ingestion URL/PDF...")}
                  className="bg-purple-600 text-white font-medium px-4 py-2 rounded-xl text-xs hover:bg-purple-500 flex items-center gap-2"
                >
                  + Ingest Dokumen Baru
                </button>
              </div>

              <div className="bg-[#0F1422] border border-slate-800 rounded-2xl overflow-hidden">
                <div className="p-4 bg-slate-900/60 border-b border-slate-800 font-semibold text-sm text-slate-200">
                  Antrean Kiriman Komunitas (Pending Review)
                </div>
                <table className="w-full text-left text-sm">
                  <thead className="bg-slate-950 text-xs uppercase text-slate-400 border-b border-slate-800">
                    <tr>
                      <th className="px-5 py-3">Judul Dokumen</th>
                      <th className="px-5 py-3">Pengirim</th>
                      <th className="px-5 py-3">Waktu</th>
                      <th className="px-5 py-3">Status</th>
                      <th className="px-5 py-3 text-right">Keputusan Kurasi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {submissions.map((sub) => (
                      <tr key={sub.id} className="hover:bg-slate-900/40">
                        <td className="px-5 py-4">
                          <p className="font-semibold text-white">{sub.title}</p>
                          <a
                            href={sub.sourceUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="text-xs text-blue-400 hover:underline"
                          >
                            {sub.sourceUrl}
                          </a>
                        </td>
                        <td className="px-5 py-4 text-xs font-mono text-slate-400">{sub.user}</td>
                        <td className="px-5 py-4 text-xs text-slate-500 font-mono">{sub.date}</td>
                        <td className="px-5 py-4">
                          <span
                            className={`text-xs px-2.5 py-0.5 rounded-full font-semibold border ${
                              sub.status === "APPROVED"
                                ? "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
                                : sub.status === "REJECTED"
                                ? "bg-rose-500/20 text-rose-400 border-rose-500/30"
                                : "bg-amber-500/20 text-amber-400 border-amber-500/30"
                            }`}
                          >
                            {sub.status}
                          </span>
                        </td>
                        <td className="px-5 py-4 text-right space-x-2">
                          {sub.status === "PENDING" ? (
                            <>
                              <button
                                onClick={() => handleApproveSubmission(sub.id)}
                                className="bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 px-3 py-1 rounded-lg text-xs hover:bg-emerald-600/30 font-medium"
                              >
                                Setujui & Ingest
                              </button>
                              <button
                                onClick={() => handleRejectSubmission(sub.id)}
                                className="bg-rose-600/20 text-rose-400 border border-rose-500/30 px-3 py-1 rounded-lg text-xs hover:bg-rose-600/30"
                              >
                                Tolak
                              </button>
                            </>
                          ) : (
                            <span className="text-xs text-slate-500 italic">Selesai Ditinjau</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 5: MODERATION & REPORTS */}
          {activeTab === "moderation" && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-white">Sistem Moderasi & Laporan Pengguna</h2>
                  <p className="text-xs text-slate-400">
                    Eksekusi sistem 3-Strike Warning → Suspend Otomatis → Ban Permanen sesuai standar PRD §17.3.
                  </p>
                </div>
              </div>

              <div className="bg-[#0F1422] border border-slate-800 rounded-2xl overflow-hidden">
                <div className="p-4 bg-slate-900/60 border-b border-slate-800 font-semibold text-sm text-slate-200">
                  Laporan Pelanggaran Aktif (`user_reports`)
                </div>
                {reports.length === 0 ? (
                  <div className="p-8 text-center text-sm text-slate-500">
                    Tidak ada laporan pelanggaran yang belum ditindaklanjuti.
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
                              onClick={() => handleActionReport(r.id, "WARNING_GIVEN")}
                              className="bg-amber-600/20 text-amber-400 border border-amber-500/30 px-3 py-1 rounded-lg text-xs hover:bg-amber-600/30"
                            >
                              Beri Peringatan (+1)
                            </button>
                            <button
                              onClick={() => handleActionReport(r.id, "SUSPEND_7_DAYS")}
                              className="bg-orange-600/20 text-orange-400 border border-orange-500/30 px-3 py-1 rounded-lg text-xs hover:bg-orange-600/30"
                            >
                              Suspend (7 Hari)
                            </button>
                            <button
                              onClick={() => handleActionReport(r.id, "PERMANENT_BAN")}
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
          )}
        </main>
      </div>
    </div>
  );
}

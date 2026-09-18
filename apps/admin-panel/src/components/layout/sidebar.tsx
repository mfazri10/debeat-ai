"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Activity,
  Radio,
  Bot,
  Database,
  Shield,
  Layers,
} from "lucide-react";

interface NavItem {
  name: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
  badgeColor?: string;
}

const navItems: NavItem[] = [
  {
    name: "Overview & Telemetry",
    href: "/",
    icon: Activity,
  },
  {
    name: "Live Debate Sessions",
    href: "/sessions",
    icon: Radio,
    badge: "14 Aktif",
    badgeColor: "bg-blue-500/20 text-blue-400",
  },
  {
    name: "Persona & Juri AI",
    href: "/personas",
    icon: Bot,
  },
  {
    name: "RAG Knowledge Base",
    href: "/rag",
    icon: Database,
    badge: "2 Antri",
    badgeColor: "bg-amber-500/20 text-amber-400",
  },
  {
    name: "Moderasi & Laporan",
    href: "/moderation",
    icon: Shield,
    badge: "2 Baru",
    badgeColor: "bg-rose-500/20 text-rose-400",
  },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 border-r border-slate-800/80 bg-[#0A0E18] p-4 flex flex-col justify-between shrink-0">
      <div className="space-y-1">
        <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider px-3 mb-2">
          Navigasi Admin
        </p>

        {navItems.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                isActive
                  ? "bg-blue-600/15 text-blue-400 border border-blue-500/30 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-900/60"
              }`}
            >
              <Icon className="w-4 h-4" />
              <span>{item.name}</span>
              {item.badge && (
                <span
                  className={`ml-auto text-[10px] px-1.5 py-0.5 rounded-full font-mono ${
                    item.badgeColor || "bg-slate-800 text-slate-300"
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </div>

      <div className="p-3 bg-slate-900/70 border border-slate-800 rounded-xl space-y-2">
        <div className="flex items-center justify-between text-xs text-slate-400">
          <div className="flex items-center gap-1.5">
            <Layers className="w-3.5 h-3.5 text-blue-400" />
            <span>Database PostgreSQL</span>
          </div>
          <span className="text-emerald-400 font-mono">24 Tabel</span>
        </div>
        <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden">
          <div className="bg-emerald-500 h-full w-[94%]" />
        </div>
        <p className="text-[10px] text-slate-500">
          pgvector: 768 dimensi (Gemini Embedding)
        </p>
      </div>
    </aside>
  );
}

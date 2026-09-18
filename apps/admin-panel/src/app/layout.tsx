import type { Metadata } from "next";
import "./globals.css";
import { Header } from "@/components/layout/header";
import { Sidebar } from "@/components/layout/sidebar";

export const metadata: Metadata = {
  title: "DebateAI Control Center | Admin & Telemetry",
  description:
    "Enterprise management and observability dashboard for DebateAI microservices, LLM orchestration, and debate arena.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id" className="dark h-full antialiased">
      <body className="min-h-screen bg-[#080B11] text-slate-100 flex flex-col font-sans">
        <Header />
        <div className="flex-1 flex overflow-hidden">
          <Sidebar />
          <main className="flex-1 overflow-y-auto p-8 space-y-8">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}

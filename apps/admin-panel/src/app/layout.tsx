import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "DebateAI Control Center | Admin & Telemetry",
  description: "Enterprise management and observability dashboard for DebateAI microservices, LLM orchestration, and debate arena.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id" className="dark h-full antialiased">
      <body className="min-h-screen bg-[#090D16] text-slate-100 flex flex-col font-sans">
        {children}
      </body>
    </html>
  );
}

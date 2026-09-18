import { Metadata } from "next";
import { ModerationTable } from "@/components/moderation/moderation-table";

export const metadata: Metadata = {
  title: "Moderasi & Laporan Pengguna | DebateAI Admin",
  description: "Penegakan aturan 3-Strike Warning, penangguhan akun, dan ban permanen sesuai PRD §17.3.",
};

export default function ModerationPage() {
  return <ModerationTable />;
}

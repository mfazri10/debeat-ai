import { Metadata } from "next";
import { SessionTable } from "@/components/sessions/session-table";

export const metadata: Metadata = {
  title: "Live Debate Sessions | DebateAI Admin",
  description: "Pemantauan langsung kamar debat aktif, ronde argumen, dan intervensi darurat moderator.",
};

export default function SessionsPage() {
  return <SessionTable />;
}

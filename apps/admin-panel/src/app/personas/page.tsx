import { Metadata } from "next";
import { PersonaGrid } from "@/components/personas/persona-grid";

export const metadata: Metadata = {
  title: "AI Personas & Judges | DebateAI Admin",
  description: "Katalog persona lawan debat, juri AI, dan pengaturan system prompt instruksi gaya bicara.",
};

export default function PersonasPage() {
  return <PersonaGrid />;
}

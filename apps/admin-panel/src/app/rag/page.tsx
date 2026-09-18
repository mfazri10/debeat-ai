import { Metadata } from "next";
import { RAGReviewTable } from "@/components/rag/rag-review-table";

export const metadata: Metadata = {
  title: "RAG Knowledge Base & Submissions | DebateAI Admin",
  description: "Kurasi dokumen referensi mosi, antrean approval komunitas, dan pgvector 768d embedding ingestion.",
};

export default function RAGPage() {
  return <RAGReviewTable />;
}

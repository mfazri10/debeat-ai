export type CircuitBreakerStatus = "HEALTHY" | "DEGRADED" | "STANDBY" | "TRIPPED";

export interface ProviderHealth {
  status: CircuitBreakerStatus;
  latency: number;
  calls: number;
  errorRate: number;
}

export interface CircuitBreakerState {
  gemini: ProviderHealth;
  openai: ProviderHealth;
  claude: ProviderHealth;
}

export interface DebateSession {
  id: string;
  roomCode: string;
  topic: string;
  participant: string;
  opponent: string;
  format: "KDMI" | "WUDC" | "OXFORD" | "ASIAN_PARLIAMENTARY";
  status: "ONGOING" | "PAUSED" | "FINISHED";
  round: string;
}

export interface Persona {
  id: string;
  name: string;
  lang: string;
  style: string;
  stance: "PRO" | "CONTRA" | "NEUTRAL";
  usage: string;
  category: "GOVERNMENT" | "LEGAL" | "ACADEMIC" | "INDUSTRY" | "ACTIVIST";
}

export interface RAGSubmission {
  id: string;
  title: string;
  user: string;
  sourceUrl: string;
  status: "PENDING" | "APPROVED" | "REJECTED";
  date: string;
}

export interface ModerationReport {
  id: string;
  reporter: string;
  reported: string;
  reason: "HATE_SPEECH" | "SPAM" | "HARASSMENT" | "FALLACY_ABUSE";
  description: string;
  status: "PENDING" | "RESOLVED";
  strike: number;
}

export interface ActivityStreamItem {
  id: string;
  title: string;
  detail: string;
  scoreOrReaction: string;
  timestamp: string;
  type: "ARGUMENT" | "REACTION" | "PENALTY";
}

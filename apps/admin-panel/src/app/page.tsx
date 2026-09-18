"use client";

import React from "react";
import { StatCards } from "@/components/telemetry/stat-cards";
import { CircuitBreakerPanel } from "@/components/telemetry/circuit-breaker-panel";
import { LiveActivityStream } from "@/components/telemetry/live-activity-stream";

export default function OverviewPage() {
  return (
    <div className="space-y-8">
      {/* Top Telemetry Stat Cards */}
      <StatCards />

      {/* Circuit Breaker & Multi-Provider Health */}
      <CircuitBreakerPanel />

      {/* Live Debate Arena Activity Stream */}
      <LiveActivityStream />
    </div>
  );
}

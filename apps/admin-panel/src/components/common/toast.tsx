"use client";

import React from "react";
import { CheckCircle2, AlertCircle } from "lucide-react";

interface ToastProps {
  message: string | null;
  type?: "success" | "error";
}

export function Toast({ message, type = "success" }: ToastProps) {
  if (!message) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 bg-blue-600 text-white px-5 py-3 rounded-xl shadow-2xl flex items-center gap-3 border border-blue-400/30 animate-bounce">
      {type === "success" ? (
        <CheckCircle2 className="w-5 h-5 text-white" />
      ) : (
        <AlertCircle className="w-5 h-5 text-rose-300" />
      )}
      <span className="text-sm font-medium">{message}</span>
    </div>
  );
}

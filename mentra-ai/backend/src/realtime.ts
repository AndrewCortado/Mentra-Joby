import type { VoiceSessionId } from "@mentra-ai/shared";
import { attachAgent } from "./agent";

/**
 * Runs on the Node backend.
 * Receives a voice session id, or no id when no session exists.
 * Returns nothing.
 * Called by backend/src/server.ts.
 */
export function attachRealtime(sessionId?: VoiceSessionId): void {
  void sessionId;
  attachAgent();
}

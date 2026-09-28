/**
 * Runs on the Node backend. This is the server entry.
 * Receives nothing in Stage 0.
 * Returns nothing.
 * Not started in Stage 0. It calls config and realtime.
 */
import { loadConfig } from "./config";
import { attachRealtime } from "./realtime";

export function startBackend(): void {
  loadConfig();
  attachRealtime();
}

/**
 * Runs on the Node backend.
 * Receives nothing in Stage 0.
 * Returns nothing.
 * Called by backend/src/realtime.ts.
 */
import { attachTools } from "./tools";

export function attachAgent(): void {
  attachTools();
}

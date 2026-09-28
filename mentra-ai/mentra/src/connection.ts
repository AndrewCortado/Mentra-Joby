import type { TypedMiniappSession } from "@mentra/miniapp/background";
import type { ConnectionStatus } from "@mentra-ai/shared";

type Session = TypedMiniappSession<Record<string, unknown>>;

/**
 * Runs on the Mentra glasses client.
 * Receives the miniapp session.
 * Returns nothing. Reports ConnectionStatus: connecting, connected on ready, disconnected when the session ends.
 * Called by mentra/src/index.ts.
 */
export function watchConnection(session: Session, onStatus: (status: ConnectionStatus) => void): void {
  onStatus("connecting");
  session.on("ready", () => onStatus("connected"));
  session.on("disconnect", () => onStatus("disconnected"));
}

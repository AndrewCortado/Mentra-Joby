import type { ConnectionStatus } from "@mentra-ai/shared";
import { registerMiniapp, type TypedMiniappSession } from "@mentra/miniapp/background";
import { openMicrophone, speakLine } from "./audio.ts";
import { watchConnection } from "./connection.ts";
import { watchButton } from "./controls.ts";
import { showText } from "./display.ts";

type Session = TypedMiniappSession<Record<string, unknown>>;

/** Fixed line shown and spoken after the glasses button is pressed. */
export const HARDWARE_CHECK_LINE = "Mentra AI hardware check.";

/**
 * Runs on the Mentra glasses client. This is the client entry.
 * Receives the miniapp session from the Mentra host.
 * Returns nothing.
 * Called by registerMiniapp when the background starts.
 */
export function attachHardwareCheck(session: Session): void {
  let status: ConnectionStatus = "disconnected";
  watchConnection(session, (next) => {
    status = next;
  });
  openMicrophone(session);
  watchButton(session, async () => {
    if (status !== "connected") return;
    await showText(session, HARDWARE_CHECK_LINE);
    await speakLine(session, HARDWARE_CHECK_LINE);
  });
}

registerMiniapp((session) => {
  attachHardwareCheck(session);
});

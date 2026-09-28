import type { TypedMiniappSession } from "@mentra/miniapp/background";

type Session = TypedMiniappSession<Record<string, unknown>>;

/**
 * Runs on the Mentra glasses client.
 * Receives a glasses button press.
 * Returns nothing.
 * Called by mentra/src/index.ts.
 */
export function watchButton(session: Session, onPress: () => void | Promise<void>): void {
  session.input.onButtonPress(() => onPress());
}

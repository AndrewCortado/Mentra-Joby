import type { TypedMiniappSession } from "@mentra/miniapp/background";

type Session = TypedMiniappSession<Record<string, unknown>>;

const G2_WIDTH = 576;
const G2_HEIGHT = 288;

/**
 * Runs on the Mentra glasses client.
 * Receives the text to show.
 * Returns nothing. Draws one full-canvas text element.
 * Called by mentra/src/index.ts.
 */
export async function showText(session: Session, text: string): Promise<void> {
  const display = session.capabilities?.display;
  await session.display.render([
    {
      type: "text",
      id: "reply",
      box: { x: 0, y: 0, w: display?.width ?? G2_WIDTH, h: display?.height ?? G2_HEIGHT },
      text,
    },
  ]);
}

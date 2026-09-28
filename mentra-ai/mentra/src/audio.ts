import type { TypedMiniappSession } from "@mentra/miniapp/background";

type Session = TypedMiniappSession<Record<string, unknown>>;

/**
 * Runs on the Mentra glasses client.
 * Receives microphone chunks and the line to speak.
 * Returns nothing. Chunks are discarded. speakLine speaks the given text.
 * Called by mentra/src/index.ts.
 */
export function openMicrophone(session: Session): void {
  session.mic.onAudioChunk(() => {
    // Hardware check only. The chunk is not stored or sent.
  });
}

export async function speakLine(session: Session, text: string): Promise<void> {
  const spoken = text.trim();
  if (!spoken) return;
  try {
    await session.speaker.speak(spoken);
  } catch {
    // The line is already on the display. The speaker is optional.
  }
}

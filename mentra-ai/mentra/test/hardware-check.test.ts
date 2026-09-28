import assert from "node:assert/strict";
import { mock, test } from "node:test";

type ReadyListener = () => void;
type ButtonPress = { buttonId: string; pressType: "short" | "long" };
type ButtonListener = (press: ButtonPress) => Promise<void> | void;
type AudioChunk = { data: string };

interface FakeSession {
  capabilities: { display?: { width?: number; height?: number } | null } | null;
  on: (event: "ready" | "disconnect", listener: ReadyListener) => () => void;
  input: { onButtonPress: (listener: ButtonListener) => () => void };
  display: { render: (elements: unknown) => Promise<{ status: string }> };
  speaker: { speak: (text: string) => Promise<{ completed: boolean }> };
  mic: { onAudioChunk: (listener: (chunk: AudioChunk) => void) => () => void };
}

mock.module("@mentra/miniapp/background", {
  namedExports: {
    registerMiniapp(handler: (session: FakeSession) => void) {
      registered = handler;
    },
  },
});

let registered: ((session: FakeSession) => void) | undefined;

const hardware = await import("../src/index.ts");

const TEST_LINE = "Mentra AI hardware check.";
const SECRET_CHUNK = "not-stored-audio";

function createSession(display?: { width: number; height: number } | null) {
  const ready = new Set<ReadyListener>();
  let onPress: ButtonListener | undefined;
  const rendered: unknown[] = [];
  const spoken: string[] = [];
  let micSubscriptions = 0;
  const session: FakeSession = {
    capabilities: null,
    on(event, listener) {
      if (event === "ready") ready.add(listener);
      return () => {
        ready.delete(listener);
      };
    },
    input: {
      onButtonPress(listener) {
        onPress = listener;
        return () => {
          if (onPress === listener) onPress = undefined;
        };
      },
    },
    display: {
      async render(elements) {
        rendered.push(elements);
        return { status: "displayed" };
      },
    },
    speaker: {
      async speak(text) {
        spoken.push(text);
        return { completed: true };
      },
    },
    mic: {
      onAudioChunk(listener) {
        micSubscriptions += 1;
        listener({ data: SECRET_CHUNK });
        return () => {
          micSubscriptions -= 1;
        };
      },
    },
  };

  function markReady(): void {
    session.capabilities = { display: display === undefined ? undefined : display };
    for (const listener of ready) listener();
  }

  async function press(): Promise<void> {
    if (!onPress) throw new Error("button press was not registered");
    await onPress({ buttonId: "main", pressType: "short" });
  }

  return { session, rendered, spoken, press, markReady, micSubscriptions: () => micSubscriptions };
}

test("a button press before ready does not speak", async () => {
  assert.equal(registered === undefined, false);
  const fake = createSession();
  registered!(fake.session);
  await fake.press();
  assert.deepEqual(fake.spoken, []);
  assert.deepEqual(fake.rendered, []);
  assert.equal(fake.micSubscriptions(), 1);
  assert.equal(JSON.stringify(fake.rendered).includes(SECRET_CHUNK), false);
  assert.equal(JSON.stringify(fake.spoken).includes(SECRET_CHUNK), false);
});

test("a button press after ready renders the test line and speaks it", async () => {
  assert.equal(hardware.HARDWARE_CHECK_LINE, TEST_LINE);
  const fake = createSession();
  registered!(fake.session);
  fake.markReady();
  await fake.press();
  assert.deepEqual(fake.spoken, [TEST_LINE]);
  assert.deepEqual(fake.rendered, [
    [
      {
        type: "text",
        id: "reply",
        box: { x: 0, y: 0, w: 576, h: 288 },
        text: TEST_LINE,
      },
    ],
  ]);
  assert.equal(JSON.stringify(fake.rendered).includes(SECRET_CHUNK), false);
});

test("the display uses the glasses canvas when the session reports one", async () => {
  const fake = createSession({ width: 500, height: 220 });
  registered!(fake.session);
  fake.markReady();
  await fake.press();
  const frame = fake.rendered[0] as [{ box: { w: number; h: number } }];
  assert.equal(frame[0].box.w, 500);
  assert.equal(frame[0].box.h, 220);
  assert.deepEqual(fake.spoken, [TEST_LINE]);
});

import {expect, mock, test} from "bun:test"

type ReadyListener = () => void

interface FakeSession {
  on: (event: string, listener: ReadyListener) => void
  speaker: {speak: ReturnType<typeof mock>}
}

let registered: ((session: FakeSession) => void) | undefined

mock.module("@mentra/miniapp/background", () => ({
  registerMiniapp(handler: (session: FakeSession) => void) {
    registered = handler
  },
}))

await import("../src/background/index.ts")

function start(speak: ReturnType<typeof mock>) {
  if (!registered) throw new Error("registerMiniapp was not called")
  const listeners = new Map<string, ReadyListener>()
  const session: FakeSession = {
    on(event, listener) {
      listeners.set(event, listener)
    },
    speaker: {speak},
  }
  registered(session)
  return {speak, fireReady: () => listeners.get("ready")?.()}
}

test("speaks the welcome once the session is ready", () => {
  const speak = mock(() => Promise.resolve({completed: true}))
  const {fireReady} = start(speak)
  expect(speak).not.toHaveBeenCalled()
  fireReady()
  expect(speak).toHaveBeenCalledTimes(1)
  expect(speak).toHaveBeenCalledWith("Welcome to Mentra X Joby")
})

test("a rejected speak does not throw out of the ready handler", async () => {
  const unhandled: unknown[] = []
  const onUnhandled = (reason: unknown) => {
    unhandled.push(reason)
  }
  process.on("unhandledRejection", onUnhandled)
  const warnings: unknown[][] = []
  const originalWarn = console.warn
  console.warn = (...args: unknown[]) => {
    warnings.push(args)
  }
  try {
    const failure = {code: "TTS_UPSTREAM_ERROR"}
    const speak = mock(() => Promise.reject(failure))
    const {fireReady} = start(speak)
    expect(() => fireReady()).not.toThrow()
    await new Promise((resolve) => setTimeout(resolve, 0))
    expect(speak).toHaveBeenCalledTimes(1)
    expect(speak).toHaveBeenCalledWith("Welcome to Mentra X Joby")
    expect(unhandled).toEqual([])
    expect(warnings).toEqual([["welcome TTS failed", failure]])
  } finally {
    console.warn = originalWarn
    process.off("unhandledRejection", onUnhandled)
  }
})

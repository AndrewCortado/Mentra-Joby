import {expect, mock, test} from "bun:test"

type ReadyListener = () => void

interface FakeSession {
  capabilities: {display?: {width?: number; height?: number} | null} | null
  on: (event: string, listener: ReadyListener) => void
  display: {render: ReturnType<typeof mock>}
}

let registered: ((session: FakeSession) => void) | undefined

mock.module("@mentra/miniapp/background", () => ({
  registerMiniapp(handler: (session: FakeSession) => void) {
    registered = handler
  },
}))

await import("../src/background/index.ts")

function start(capabilities: FakeSession["capabilities"]) {
  if (!registered) throw new Error("registerMiniapp was not called")
  const render = mock(() => Promise.resolve({status: "displayed"}))
  const listeners = new Map<string, ReadyListener>()
  const session: FakeSession = {
    capabilities,
    on(event, listener) {
      listeners.set(event, listener)
    },
    display: {render},
  }
  registered(session)
  return {render, fireReady: () => listeners.get("ready")?.()}
}

test("renders Mentra X Joby on ready using the display size", () => {
  const {render, fireReady} = start({display: {width: 640, height: 200}})
  expect(render).not.toHaveBeenCalled()
  fireReady()
  expect(render).toHaveBeenCalledWith([
    {
      type: "text",
      id: "placeholder",
      box: {x: 0, y: 0, w: 640, h: 200},
      text: "Mentra X Joby",
    },
  ])
})

test("falls back to the G2 canvas when display capabilities are missing", () => {
  const {render, fireReady} = start(null)
  fireReady()
  expect(render).toHaveBeenCalledWith([
    {
      type: "text",
      id: "placeholder",
      box: {x: 0, y: 0, w: 576, h: 288},
      text: "Mentra X Joby",
    },
  ])
})

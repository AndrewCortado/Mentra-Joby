import {registerMiniapp} from "@mentra/miniapp/background"

registerMiniapp((session) => {
  session.on("ready", () => {
    // capabilities is null until "ready"; fall back to the G2 canvas size.
    const d = session.capabilities?.display
    void session.display.render([
      {
        type: "text",
        id: "placeholder",
        box: {x: 0, y: 0, w: d?.width ?? 576, h: d?.height ?? 288},
        text: "Mentra X Joby",
      },
    ])
  })
})

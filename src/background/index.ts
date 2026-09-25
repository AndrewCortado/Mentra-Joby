import {registerMiniapp} from "@mentra/miniapp/background"

const WELCOME = "Welcome to Mentra X Joby"

registerMiniapp((session) => {
  session.on("ready", () => {
    session.speaker.speak(WELCOME).catch((err: unknown) => {
      console.warn("welcome TTS failed", err)
    })
  })
})

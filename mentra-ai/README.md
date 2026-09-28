# Mentra AI

Stage 1 connects the glasses client to MentraOS and proves the hardware. Press the glasses button and the display shows a fixed line, then the glasses speak it. There is no AI. The camera is unused. The backend is still a stub.

The test line is `Mentra AI hardware check.`

Microphone audio is not stored or sent. The client opens the microphone, discards each chunk, and does not forward it.

## Folder map

| Path | Where it runs | Role |
| --- | --- | --- |
| `mentra/` | Mentra glasses client | Button, display, speaker, and microphone hardware check |
| `backend/` | Node server | Unchanged stubs. Stage 1 does not start them |
| `shared/` | Imported by both | `ConnectionStatus` and `VoiceSessionId` |
| `.env.example` | Not loaded | Empty placeholders for later server secrets |

`mentra/src/index.ts` is the client entry. It calls `registerMiniapp` from `@mentra/miniapp`. `mentra/miniapp.json` is this app only: package `com.andrewcortado.mentraai`, launcher name Mentra AI.

## Build and test

From this directory:

```bash
npm install
npm test
npm run build
```

`npm test` mocks the SDK and checks two things: a button press before the session is ready does not speak, and a button press after ready renders the test line and speaks it.

`npm run build` typechecks `shared`, `mentra`, and `backend` with `tsc`. The glasses background is then bundled with bun into `mentra/dist/background/index.js` as a browser IIFE. npm is the package manager. Bun is used only for that bundle: the Mentra host evaluates the background as a classic script, and `mentra-miniapp dev` runs `bun run build.ts`. Install [Bun](https://bun.sh) and make sure `bun` is on your PATH before `npm run build` or `npm run dev`.

## Run the hardware check on a phone

The phone and the computer must be on the same Wi-Fi. Install the Mentra App, version 2.13.0 or newer, and sign in.

From this directory:

```bash
npm run dev
```

That runs `mentra-miniapp dev` in `mentra/`. It validates `miniapp.json`, bundles the background, serves it on your LAN (port 3010, or the next free port), and prints a QR code plus a `miniapp://dev?...` URL.

On the phone: **Settings → Miniapp Developer Settings → Scan Miniapp QR Code**, then scan the QR. Open **Mentra AI**. With display glasses connected, press the glasses button. The display shows `Mentra AI hardware check.` and the glasses speak that line.

The app asks for the microphone as the hardware check. Those chunks stay on the glasses client and are thrown away. Nothing is written to disk, logged, or sent to a server.

## Secrets

`.env.example` lists variable names and leaves the values empty. Real values belong in `.env`, which is gitignored. Do not commit `.env`. Do not put OpenAI keys, Mentra keys, or database URLs in the glasses client. Stage 1 does not read `.env`.

# Mentra X Joby

A Mentra glasses miniapp. This repository is the project setup: on session ready it draws the text **Mentra X Joby** on the glasses display. Tour content is not in this repo yet.

Apps for the current Mentra App are on-device miniapps built with [`@mentra/miniapp`](https://www.npmjs.com/package/@mentra/miniapp). The older cloud SDK, `@mentra/sdk` (`AppServer`, API keys, ngrok, console.mentra.glass), is retired and will not run in the current Mentra App.

No accounts, API keys, or environment variables are needed. Do not add a `.env` file.

## Prerequisites

- [Bun](https://bun.sh)
- The [Mentra App](https://mentraglass.com/os) on Android or iPhone, signed in
- The phone and the computer on the same Wi-Fi

Glasses are optional for loading the miniapp. The display has nowhere to draw until display glasses are connected. This project targets display glasses (Even Realities G1/G2, Vuzix Z100, and similar). Mentra documents no simulator.

The Miniapp SDK is in beta. MentraOS 3.0 has no store distribution for these miniapps.

## Install

```bash
bun install
```

## Run

```bash
bun run dev
```

That validates `miniapp.json`, builds the background bundle, serves it on your LAN, and prints a QR code and a `miniapp://dev?...` URL. Leave the process running.

On the phone: **Settings → Miniapp Developer Settings → Scan Miniapp QR Code**, then scan the QR. The miniapp installs and starts. With display glasses connected, **Mentra X Joby** appears. G1 and Z100 may show it through the host's text fallback.

`bun run release` serves a local install that keeps running after you close the laptop. There is no `pack` script: distribution is not supported in MentraOS 3.0.

## Scripts

| Command | What it does |
| --- | --- |
| `bun run dev` | Validate, build, and serve a live dev session |
| `bun run build` | Write `dist/background/index.js` |
| `bun run typecheck` | Typecheck with `tsc` |
| `bun run release` | Serve a persistent install for a test phone |

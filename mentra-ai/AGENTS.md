# Agents

Work in incremental stages 0 through 8. Stop after the stage you were asked for. Do not start the next stage in the same change.

Stage 1 is the current stage. The glasses client connects to MentraOS with `@mentra/miniapp` and proves the button, display, speaker, and microphone. Stage 2 is not started. Do not add OpenAI, realtime, tools, MCP, or RAG.

Before a large change, explain where the code runs: the Mentra glasses client (`mentra/`), the Node backend (`backend/`), or the shared types (`shared/`).

Official Mentra docs and official OpenAI docs win when this tree and those docs disagree. The retired cloud SDK `@mentra/sdk` is not used.

Never commit `.env`. Never send secrets to the Mentra client. Server secrets stay in `.env` on the backend. Microphone audio is not stored or sent.

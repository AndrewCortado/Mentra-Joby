import {rm} from "fs/promises"
import {backgroundRuntimeGuardPlugin} from "@mentra/miniapp-cli/build-helpers"

const distDir = "./dist"

await rm(distDir, {recursive: true, force: true})

// MENTRA_PUBLIC_* values are inlined into the bundle. They are public.
// This app does not set any.
const define: Record<string, string> = {}
for (const [k, v] of Object.entries(process.env)) {
  if (k.startsWith("MENTRA_PUBLIC_") && typeof v === "string") {
    define[`process.env.${k}`] = JSON.stringify(v)
  }
}

// IIFE: the glasses host evaluates the background bundle as a classic script.
const backgroundResult = await Bun.build({
  entrypoints: ["./src/background/index.ts"],
  outdir: `${distDir}/background`,
  target: "browser",
  format: "iife",
  plugins: [backgroundRuntimeGuardPlugin(import.meta.url)],
  minify: false,
  define,
})

if (!backgroundResult.success) {
  console.error("Background build failed:")
  for (const log of backgroundResult.logs) console.error(log)
  process.exit(1)
}

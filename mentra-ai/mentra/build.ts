import { rm } from "fs/promises";
import { backgroundRuntimeGuardPlugin } from "@mentra/miniapp-cli/build-helpers";

const distDir = "./dist";

await rm(distDir, { recursive: true, force: true });

// Only public MENTRA_PUBLIC_* values may be inlined. Secrets are never defined here.
const define: Record<string, string> = {};
for (const [key, value] of Object.entries(process.env)) {
  if (key.startsWith("MENTRA_PUBLIC_") && typeof value === "string") {
    define[`process.env.${key}`] = JSON.stringify(value);
  }
}

// The glasses host evaluates the background as a classic script, so the bundle is an IIFE.
const backgroundResult = await Bun.build({
  entrypoints: ["./src/index.ts"],
  outdir: `${distDir}/background`,
  target: "browser",
  format: "iife",
  plugins: [backgroundRuntimeGuardPlugin(import.meta.url)],
  minify: false,
  define,
});

if (!backgroundResult.success) {
  console.error("Background build failed:");
  for (const log of backgroundResult.logs) console.error(log);
  process.exit(1);
}

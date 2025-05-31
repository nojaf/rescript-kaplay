import { $ } from "bun";
import { cp } from "fs/promises";

const currentDir = import.meta.dirname;
const rootDir = `${currentDir}/..`;
const samplesDir = `${currentDir}/../packages/samples`;

// Compile ReScript
await $`bunx rewatch`.cwd(rootDir);

// Copy public folder assets to docs
await cp(`${samplesDir}/public`, `${rootDir}/docs/public`, { recursive: true });

// Build docs
await $`bunx --bun astro build`.cwd(rootDir);

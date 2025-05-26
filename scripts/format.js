import { $, Glob } from "bun";
const glob = new Glob("**/src/**/*.res");

await $`bunx prettier --log-level warn --write ./docs package.json astro.config.mjs scripts`;

try {
  const rescriptFiles = [];
  for await (const file of glob.scan()) {
    rescriptFiles.push(file);
  }
  await Promise.all(
    rescriptFiles.map((file) => $`bunx rescript format ${file}`),
  );
  console.info(`Formatted ${rescriptFiles.length} ReScript files`);
} catch (err) {
  console.error(err);
  process.exit(2);
}

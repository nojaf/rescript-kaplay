import { $ } from "bun";

const currentDir = import.meta.dirname;
const rootDir = `${currentDir}/..`;
const libraryDir = `${rootDir}/packages/rescript-kaplay`;

const lastVersion = await $`bunx changelog --latest-release`
  .cwd(libraryDir)
  .text()
  .then((v) => v.trim());

// Update version in package.json
const packageJson = await Bun.file(`${libraryDir}/package.json`).json();
packageJson.version = lastVersion;
await Bun.write(
  `${libraryDir}/package.json`,
  JSON.stringify(packageJson, null, 2),
);

import { $ } from "bun";

const currentDir = import.meta.dirname;
const rootDir = `${currentDir}/..`;
const libraryDir = `${rootDir}/packages/rescript-kaplay`;

const changelogVersion = await $`bunx changelog --latest-release`
  .cwd(libraryDir)
  .text()
  .then((v) => v.trim());

const packageJsonVersion = await Bun.file(`${libraryDir}/package.json`)
  .json()
  .then((p) => p.version);

if (changelogVersion !== packageJsonVersion) {
  console.log(
    `Changelog version ${changelogVersion} does not match package.json version ${packageJsonVersion}`,
  );
  process.exit(1);
}

console.log(
  `Changelog version ${changelogVersion} matches package.json version ${packageJsonVersion}`,
);
process.exit(0);

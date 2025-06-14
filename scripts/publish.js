import { $ } from "bun";
import semver from "semver";

const isDryRun = Bun.argv.includes("--dry-run");
const currentDir = import.meta.dirname;
const rootDir = `${currentDir}/..`;
const libraryDir = `${rootDir}/packages/rescript-kaplay`;

const lastVersion = await $`bunx changelog --latest-release`
  .cwd(libraryDir)
  .text()
  .then((v) => v.trim());

const lastPublishedVersion = await $`bun pm view --json @nojaf/rescript-kaplay`
  .json()
  .then((info) => {
    return info.version;
  });

if (semver.gt(lastVersion, lastPublishedVersion)) {
  console.log(
    `Last version in changelog ${lastVersion} is greater than last published version on npm ${lastPublishedVersion}`,
  );

  // Grab latest release notes
  const notes = await $`bunx changelog --latest-release-full`
    .cwd(libraryDir)
    .text()
    .then((v) => v.trim());

  const tag = `v${lastVersion}`;

  if (isDryRun) {
    console.log(
      `Dry run: Would publish version to NPM and create GitHub release for ${lastVersion}`,
    );
    await $`bun publish --dry-run`.cwd(libraryDir);

    console.log(`Dry run:Creating GitHub release for ${tag}`);
    console.log(notes);
  } else {
    console.log(`Publishing ${lastVersion} to NPM`);
    await $`bun publish --access public`.cwd(libraryDir);

    console.log(`Creating GitHub release for ${tag}`);
    console.log(notes);
    await $`gh release create ${tag} --title ${lastVersion} --notes "${notes}"`.cwd(
      libraryDir,
    );
  }
} else {
  console.log(
    `Last version in changelog ${lastVersion} is not greater than last published version on npm ${lastPublishedVersion}`,
  );
  await $`gh release list`;
}

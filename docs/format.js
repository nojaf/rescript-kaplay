import { $ } from "bun";

export async function formatRescriptCode(code) {
  return await $`echo ${code} | bunx rescript format -stdin .res`.text();
}

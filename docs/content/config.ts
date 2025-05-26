import path from "path";
import { fileURLToPath } from "url";
import { defineCollection, z } from "astro:content";
import { docsSchema } from "@astrojs/starlight/schema";
import { Glob, $ } from "bun";
import { micromark } from "micromark";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const { rescript_tools_exe } = await import(
  /* @vite-ignore */
  path.join(__dirname, "../../node_modules/rescript/cli/common/bins.js")
);

function sanitizeModuleName(name: string) {
  return name
    .split(".")
    .map((part) => {
      if (!part.includes("-")) {
        return part;
      }

      // A namespace will be output as "Math-Kaplay" so we need to reverse it
      return part.split("-").toReversed().join(".");
    })
    .join(".");
}

function processModule(doc: any) {
  const id = sanitizeModuleName(doc.name);

  const types = doc.items
    .filter((d) => d.kind === "type")
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((type) => {
      const documentation =
        type.docstrings && micromark(type.docstrings.join("\n"));
      return {
        name: type.name,
        documentation,
        signature: type.signature,
        detail: type.detail,
      };
    });

  const values = doc.items
    .filter((item) => item.kind === "value")
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((value) => {
      const documentation =
        value.docstrings && micromark(value.docstrings.join("\n"));
      return {
        name: value.name,
        documentation,
        signature: value.signature,
        detail: value.detail,
      };
    });

  const modules = doc.items
    .filter((item) => item.kind === "module")
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((module) => {
      return processModule(module);
    });

  return {
    id,
    types,
    values,
    modules,
  };
}

const ModuleSchema = z.object({
  id: z.string(),
  types: z
    .array(
      z.object({
        name: z.string(),
        documentation: z.string().optional(),
        signature: z.string(),
        detail: z
          .discriminatedUnion("kind", [
            z.object({
              kind: z.literal("record"),
              items: z.array(
                z.object({
                  name: z.string(),
                  optional: z.boolean(),
                  signature: z.string(),
                  docstrings: z.array(z.string()),
                }),
              ),
            }),
            z.object({
              kind: z.literal("variant"),
              items: z
                .array(
                  z.object({
                    name: z.string(),
                    signature: z.string(),
                    docstrings: z.array(z.string()),
                  }),
                )
                .optional(),
            }),
          ])
          .optional(),
      }),
    )
    .optional(),

  values: z
    .array(
      z.object({
        name: z.string(),
        documentation: z.string().optional(),
        signature: z.string(),
        detail: z.object({}).optional(),
      }),
    )
    .optional(),

  get modules() {
    return z.array(ModuleSchema).optional();
  },
});

const apiDocs = defineCollection({
  schema: ModuleSchema.extend({
    filePath: z.string(),
  }),
  loader: async () => {
    const inputDir =
      "/Users/nojaf/Projects/rescript-kaplay/packages/rescript-kaplay/src";
    const glob = new Glob(`**/*.res`);

    const collectionEntries: any[] = [];
    for await (const file of glob.scan(inputDir)) {
      const filePath = path.join(inputDir, file);
      const doc = await $`${rescript_tools_exe} doc ${filePath}`.json();
      const fileModule = processModule(doc);

      collectionEntries.push({
        filePath,
        ...fileModule,
      });
    }

    return collectionEntries;
  },
});

export const collections = {
  docs: defineCollection({ schema: docsSchema() }),
  apiDocs,
};

import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import starlightThemeFlexoki from "starlight-theme-flexoki";
import rescriptTM from "./docs/rescript.tmLanguage.json";

export default defineConfig({
  srcDir: "docs",
  publicDir: "docs/public",
  site: "https://nojaf.com",
  base: "rescript-kaplay",
  integrations: [
    starlight({
      title: "Rescript Kaplay bindings",
      favicon: "/favicon.png",
      customCss: ["./docs/styles/custom.css"],
      plugins: [
        starlightThemeFlexoki({
          accentColor: "green",
        }),
      ],
      sidebar: [
        {
          slug: "",
        },
        {
          slug: "game-context",
        },
        {
          slug: "game-object",
        },
        {
          slug: "vec2-coordinates",
        },
        {
          label: "Samples",
          link: "./samples",
        },
        {
          label: "API reference",
          link: "./api-reference",
        },
      ],
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/nojaf/rescript-kaplay",
        },
      ],
      editLink: {
        baseUrl: "https://github.com/nojaf/rescript-kaplay/edit/main/",
      },
      expressiveCode: {
        shiki: {
          langs: [rescriptTM],
        },
      },
    }),
  ],
});

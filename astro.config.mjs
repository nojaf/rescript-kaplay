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
      plugins: [
        starlightThemeFlexoki({
          accentColor: "green",
        }),
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

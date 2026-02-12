import { defineConfig } from "vite";

// https://vitejs.dev/config/
export default defineConfig({
  base: "/rescript-kaplay/",
  watch: {
    // We ignore ReScript build artifacts to avoid unnecessarily triggering HMR on incremental compilation
    ignored: ["**/lib/**"],
  },
});

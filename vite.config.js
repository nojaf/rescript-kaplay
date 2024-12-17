import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import rescript from "vite-plugin-rescript";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    rescript(),
    react({
      include: ["**/*.res.mjs"],
    }),
  ],
});

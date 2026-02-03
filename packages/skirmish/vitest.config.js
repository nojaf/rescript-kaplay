import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";

export default defineConfig({
  test: {
    include: ["tests/*.spec.res.mjs"],
    browser: {
      provider: playwright(),
      enabled: true,
      // at least one instance is required
      instances: [{ browser: "chromium" }],
      headless: true,
    },
    coverage: {
      provider: "istanbul",
    },
  },
});

import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    projects: ["./dot_pi/agent", "./tern"],
  },
});

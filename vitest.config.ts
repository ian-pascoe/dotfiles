import { defineConfig } from "vite-plus";

export default defineConfig({
  test: {
    projects: ["./dot_pi/agent", "./tern", "./dot_themes", "./dot_local/bin"],
  },
});

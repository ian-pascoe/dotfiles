// vp migrate: merged .oxlintrc.json (164165c9b1aee99506d71713855aa0b4).
import { defineConfig } from "vite-plus";

export default defineConfig({
  fmt: {
    ignorePatterns: [
      "**/.brv/**",
      "dot_agents/skills",
      "**/modify_*",
      "dot_local/state/skills/dot_skill-lock.json",
    ],
  },
  lint: {
    ignorePatterns: ["dot_agents/skills"],
    plugins: ["typescript", "unicorn", "oxc"],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    categories: {
      correctness: "error",
    },
    rules: {
      "vite-plus/prefer-vite-plus-imports": "error",
    },
    env: {
      builtin: true,
    },
    jsPlugins: [
      {
        name: "vite-plus",
        specifier: "vite-plus/oxlint-plugin",
      },
    ],
  },
});

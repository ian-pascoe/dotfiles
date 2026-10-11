import { type FSWatcher, readlinkSync, watch } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/**
 * Follows the system theme: `set-theme` points `<configDir>/theme` at
 * `~/.themes/<name>`, and this applies the Pi theme of that name, at startup
 * and whenever the link changes. The shell's `pi` wrapper loads every
 * `~/.themes/<name>/pi.json` so each theme is available by name.
 */
export function followSystemTheme(configDir: string) {
  return (pi: ExtensionAPI) => {
    let watcher: FSWatcher | undefined;
    let debounce: NodeJS.Timeout | undefined;

    const apply = (ctx: ExtensionContext) => {
      let themeName: string;
      try {
        themeName = basename(readlinkSync(join(configDir, "theme")));
      } catch {
        return;
      }
      // Passing the Theme, not its name, keeps the switch out of settings.json.
      const theme = ctx.ui.getTheme(themeName);
      const result = theme
        ? ctx.ui.setTheme(theme)
        : { success: false, error: "theme is not loaded" };
      if (!result.success) {
        ctx.ui.notify(`Could not activate theme '${themeName}': ${result.error}`, "error");
      }
    };

    const stop = () => {
      clearTimeout(debounce);
      watcher?.close();
      watcher = undefined;
    };

    pi.on("session_start", (_event, ctx) => {
      if (!ctx.hasUI) return;
      stop();
      apply(ctx);
      // The link is replaced rather than modified, so watch its directory.
      watcher = watch(configDir, (_eventType, filename) => {
        if (filename !== "theme") return;
        // Replacing the link reports several events; apply once they settle.
        clearTimeout(debounce);
        debounce = setTimeout(() => apply(ctx), 100);
      });
      watcher.on("error", stop);
    });

    pi.on("session_shutdown", stop);
  };
}

export default followSystemTheme(process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"));

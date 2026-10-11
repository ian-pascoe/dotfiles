import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, unlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { afterEach, test, vi } from "vitest";
import { followSystemTheme } from "./active-theme.js";

type Handler = (event: unknown, ctx: ExtensionContext) => void;

let configDir: string | undefined;
afterEach(() => {
  if (configDir) rmSync(configDir, { recursive: true, force: true });
});

function linkTheme(dir: string, name: string) {
  const link = join(dir, "theme");
  try {
    unlinkSync(link);
  } catch {}
  symlinkSync(join(dir, "themes", name), link);
}

test("applies the linked theme at startup and follows the link without saving it", async () => {
  configDir = mkdtempSync(join(tmpdir(), "active-theme-"));
  for (const name of ["kanagawa", "dracula"]) {
    mkdirSync(join(configDir, "themes", name), { recursive: true });
  }
  linkTheme(configDir, "kanagawa");

  const handlers = new Map<string, Handler>();
  const recordingPi = {
    on(event: string, handler: Handler) {
      handlers.set(event, handler);
    },
  } as unknown as ExtensionAPI;
  const themes = new Map(["kanagawa", "dracula"].map((name) => [name, { name } as Theme]));
  const applied: unknown[] = [];
  const ctx = {
    hasUI: true,
    ui: {
      getTheme: (name: string) => themes.get(name),
      setTheme(theme: unknown) {
        applied.push(theme);
        return { success: true };
      },
      notify() {},
    },
  } as unknown as ExtensionContext;

  followSystemTheme(configDir)(recordingPi);
  handlers.get("session_start")?.({ type: "session_start" }, ctx);
  assert.deepEqual(applied, [themes.get("kanagawa")]);

  linkTheme(configDir, "dracula");
  await vi.waitFor(() => assert.deepEqual(applied.at(-1), themes.get("dracula")), {
    timeout: 2000,
  });
  // Instances, not names: setting by name would persist to settings.json.
  assert.ok(applied.every((theme) => typeof theme === "object"));

  handlers.get("session_shutdown")?.({ type: "session_shutdown" }, ctx);
  const count = applied.length;
  linkTheme(configDir, "kanagawa");
  await new Promise((resolve) => setTimeout(resolve, 300));
  assert.equal(applied.length, count);
});

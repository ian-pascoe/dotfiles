import assert from "node:assert/strict";
import type {
  ExtensionAPI,
  ExtensionContext,
  TerminalInputHandler,
} from "@earendil-works/pi-coding-agent";
import { test } from "vitest";
import pasteImageOnEmptyPaste, { CTRL_V, EMPTY_PASTE } from "./paste-image-on-empty-paste.js";

type Handler = (event: unknown, ctx: ExtensionContext) => void;

function load(hasUI: boolean) {
  const handlers = new Map<string, Handler>();
  let inputHandler: TerminalInputHandler | undefined;
  let unsubscribed = 0;
  const pi = {
    on(event: string, handler: Handler) {
      handlers.set(event, handler);
    },
  } as unknown as ExtensionAPI;
  const ctx = {
    hasUI,
    ui: {
      onTerminalInput(handler: TerminalInputHandler) {
        inputHandler = handler;
        return () => {
          unsubscribed++;
        };
      },
    },
  } as unknown as ExtensionContext;

  pasteImageOnEmptyPaste(pi);
  handlers.get("session_start")?.({ type: "session_start" }, ctx);
  return {
    inputHandler: () => inputHandler,
    shutdown: () => handlers.get("session_shutdown")?.({ type: "session_shutdown" }, ctx),
    unsubscribed: () => unsubscribed,
  };
}

test("an empty bracketed paste becomes Ctrl+V", () => {
  const handler = load(true).inputHandler();
  assert.ok(handler);
  assert.deepEqual(handler(EMPTY_PASTE), { data: CTRL_V });
});

test("other input passes through", () => {
  const handler = load(true).inputHandler();
  assert.ok(handler);
  assert.equal(handler("\x1b[200~text\x1b[201~"), undefined);
  assert.equal(handler("a"), undefined);
});

test("nothing is installed without a UI", () => {
  assert.equal(load(false).inputHandler(), undefined);
});

test("shutdown removes the listener", () => {
  const loaded = load(true);
  loaded.shutdown();
  assert.equal(loaded.unsubscribed(), 1);
});

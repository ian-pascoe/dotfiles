import assert from "node:assert/strict";
import type {
  ExtensionAPI,
  ExtensionContext,
  InputEvent,
  InputEventResult,
} from "@earendil-works/pi-coding-agent";
import { test } from "vitest";
import continueConversationOnDot from "./continue-on-dot.js";

type InputHandler = (
  event: InputEvent,
  context: ExtensionContext,
) => InputEventResult | undefined | Promise<InputEventResult | undefined>;

test("a lone dot continues the conversation without becoming a user message", async () => {
  let inputHandler: InputHandler | undefined;
  const sentMessages: Parameters<ExtensionAPI["sendMessage"]>[] = [];
  const rendererTypes: string[] = [];
  const recordingPi = {
    registerMessageRenderer(customType: string) {
      rendererTypes.push(customType);
    },
    on(_event: string, handler: InputHandler) {
      inputHandler = handler;
    },
    sendMessage(...args: Parameters<ExtensionAPI["sendMessage"]>) {
      sentMessages.push(args);
    },
  } as unknown as ExtensionAPI;

  continueConversationOnDot(recordingPi);
  assert.ok(inputHandler);
  assert.deepEqual(rendererTypes, ["continuation"]);

  const context = {} as ExtensionContext;
  assert.deepEqual(
    await inputHandler({ type: "input", text: "hello", source: "interactive" }, context),
    { action: "continue" },
  );
  assert.deepEqual(
    await inputHandler({ type: "input", text: ".", source: "interactive" }, context),
    { action: "handled" },
  );
  assert.deepEqual(sentMessages, [
    [
      {
        customType: "continuation",
        content: "Continue.",
        display: true,
      },
      { triggerTurn: true, deliverAs: "followUp" },
    ],
  ]);
});

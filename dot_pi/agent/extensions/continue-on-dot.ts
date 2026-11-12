import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Box, Text } from "@earendil-works/pi-tui";

const CONTINUATION_TYPE = "continuation";

/** Continues the current conversation when the user submits a lone dot. */
export default function continueConversationOnDot(pi: ExtensionAPI) {
  pi.registerMessageRenderer(CONTINUATION_TYPE, (_message, { outputPad }, theme) => {
    const box = new Box(outputPad, 1, (text) => theme.bg("customMessageBg", text));
    box.addChild(new Text(theme.fg("customMessageLabel", theme.bold("[continuation]")), 0, 0));
    return box;
  });

  pi.on("input", (event) => {
    if (event.text !== ".") return { action: "continue" };

    pi.sendMessage(
      {
        customType: CONTINUATION_TYPE,
        content: "Continue.",
        display: true,
      },
      { triggerTurn: true, deliverAs: "followUp" },
    );
    return { action: "handled" };
  });
}

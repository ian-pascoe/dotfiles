import type { AgentConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "../..";
import { expandProtocols } from "../util/protocols";
import { setupAgentPermissions } from "../../permission/agent";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: "all",
  hidden: false,
  model: ctx.config.model,
  temperature: 0.2,
  permission: setupAgentPermissions(
    "reviewer",
    {
      edit: {
        ".agents/reviews/*.md": "allow",
      },
      webfetch: "deny",
      websearch: "deny",
      codesearch: "deny",
      "chrome-devtools*": "deny",
    },
    ctx,
  ),
  description:
    'Code reviewer. Analyzes diffs for issues. Delegates to explorer (context) and researcher (best practices). Specify scope: "quick" (obvious issues), "standard" (full review), "thorough" (deep analysis). READ-ONLY.',
  prompt: expandProtocols(PROMPT),
});

export const setupReviewerAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.reviewer ?? {}, getDefaults(ctx));
};

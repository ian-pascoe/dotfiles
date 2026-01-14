import type { AgentConfig, PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaContext } from "../..";
import { getAgentPermissions } from "../../permission";
import { expandProtocols } from "../protocols";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaContext): AgentConfig =>
  ({
    mode: "subagent",
    hidden: false,
    model: ctx.config.model,
    temperature: 0.3,
    color: "#d946ef",
    permission: defu(getAgentPermissions("reviewer", ctx), {
      edit: {
        ".agents/reviews/*.md": "allow",
      },
      webfetch: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      'Code reviewer. Analyzes diffs for issues. Delegates to explorer (context) and librarian (best practices). Specify scope: "quick" (obvious issues), "standard" (full review), "thorough" (deep analysis). READ-ONLY.',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupReviewerAgentConfig = (ctx: ElishaContext): AgentConfig => {
  return defu(ctx.config.agent?.reviewer ?? {}, getDefaults(ctx));
};

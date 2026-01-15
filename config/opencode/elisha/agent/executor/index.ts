import type { AgentConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "../..";
import { setupAgentPermissions } from "../../permission/agent";
import { expandProtocols } from "../util/protocols";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: "all",
  hidden: false,
  model: ctx.config.model,
  temperature: 0.5,
  permission: setupAgentPermissions(
    "executor",
    {
      edit: "allow",
      webfetch: "deny",
      websearch: "deny",
      codesearch: "deny",
      "chrome-devtools*": "deny",
    },
    ctx,
  ),
  description:
    'Implementation executor. Reads plans from `.agents/plans/` (or specs from `.agents/specs/`), writes code, updates plan status. Delegates to explorer (find patterns) and researcher (API docs) when stuck. Specify mode: "step" (one task), "phase" (one phase), "full" (entire plan).',
  prompt: expandProtocols(PROMPT),
});

export const setupExecutorAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.executor ?? {}, getDefaults(ctx));
};

import type { AgentConfig, PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaContext } from "../..";
import { getAgentPermissions } from "../../permission";
import { expandProtocols } from "../protocols";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaContext): AgentConfig =>
  ({
    mode: "all",
    hidden: false,
    model: ctx.config.model,
    temperature: 0.7,
    color: "#d946ef",
    permission: defu(getAgentPermissions("executor", ctx), {
      edit: "allow",
      webfetch: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      'Implementation executor. Reads plans from `.agents/plans/` (or specs from `.agents/specs/`), writes code, updates plan status. Delegates to explorer (find patterns) and librarian (API docs) when stuck. Specify mode: "step" (one task), "phase" (one phase), "full" (entire plan).',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupExecutorAgentConfig = (ctx: ElishaContext): AgentConfig => {
  return defu(ctx.config.agent?.executor ?? {}, getDefaults(ctx));
};

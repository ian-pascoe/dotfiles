import type { AgentConfig, PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "../..";
import { getAgentPermissions } from "../../permission";
import { expandProtocols } from "../util/protocols";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig =>
  ({
    mode: "subagent",
    hidden: false,
    model: ctx.config.small_model,
    temperature: 0.1,
    color: "#24bf4b",
    permission: defu(getAgentPermissions("researcher", ctx), {
      edit: "deny",
      webfetch: "allow",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      'External research specialist. Finds library docs, API examples, GitHub code patterns. Specify thoroughness: "quick" (1-2 queries), "medium" (3-4 queries), "thorough" (5+ queries). Returns synthesized findings with sources. No local codebase access.',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupResearcherAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.researcher ?? {}, getDefaults(ctx));
};

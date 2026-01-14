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
    temperature: 0.7,
    color: "#f43f5e",
    permission: defu(getAgentPermissions("architect", ctx), {
      edit: "deny",
      webfetch: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      'Solution designer. Analyzes requirements, evaluates approaches, recommends architecture. Delegates to explorer (codebase) and librarian (research). Specify scope: "component" (single feature), "system" (multi-component), "strategic" (large-scale). DESIGN-ONLY, no code.',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupArchitectAgentConfig = (ctx: ElishaContext): AgentConfig => {
  return defu(ctx.config.agent?.architect ?? {}, getDefaults(ctx));
};

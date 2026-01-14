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
    color: "#bae6fd",
    permission: defu(getAgentPermissions("explorer", ctx), {
      edit: "deny",
      webfetch: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      'An autonomous agent that explores the codebase to gather information and insights to assist other agents in making informed decisions.Codebase search specialist. Finds files, searches code, maps structure. Specify thoroughness: "quick" (1 search), "medium" (2-3 searches), "thorough" (4-6 searches). Returns file paths with line numbers and brief context. READ-ONLY.',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupExplorerAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.explorer ?? {}, getDefaults(ctx));
};

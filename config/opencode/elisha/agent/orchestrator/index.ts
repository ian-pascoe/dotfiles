import { AgentConfig, PermissionConfig } from "@opencode-ai/sdk/v2";
import { ElishaConfigContext } from "../..";
import { getAgentPermissions } from "../../permission";
import defu from "defu";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig =>
  ({
    mode: "primary",
    hidden: false,
    model: ctx.config.model,
    temperature: 0.7,
    color: "#8A2BE2",
    permission: defu(getAgentPermissions("orchestrator", ctx), {
      edit: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      "Task coordinator. Delegates all work to specialized agents: explorer (search), librarian (research), architect (design), planner (plans), executor (code). Never touches code directly. Use for complex multi-step tasks or when unsure which agent to use.",
    prompt: PROMPT,
  }) satisfies AgentConfig;

export const setupOrchestratorAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.orchestrator ?? {}, getDefaults(ctx));
};

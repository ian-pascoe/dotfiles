import type { AgentConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "../..";
import { setupAgentPermissions } from "../../permission/agent";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: "primary",
  hidden: false,
  model: ctx.config.model,
  temperature: 0.4,
  permission: setupAgentPermissions(
    "orchestrator",
    {
      edit: "deny",
      webfetch: "ask",
      websearch: "deny",
      codesearch: "deny",
      "chrome-devtools*": "deny",
    },
    ctx,
  ),
  description:
    "Task coordinator. Delegates all work to specialized agents: explorer (search), researcher (research), architect (design), planner (plans), executor (code). Never touches code directly. Use for complex multi-step tasks or when unsure which agent to use.",
  prompt: PROMPT,
});

export const setupOrchestratorAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.orchestrator ?? {}, getDefaults(ctx));
};

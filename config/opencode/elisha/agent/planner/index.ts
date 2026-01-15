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
  temperature: 0.2,
  permission: setupAgentPermissions(
    "planner",
    {
      edit: {
        ".agents/plans/*.md": "allow",
        ".agents/specs/*.md": "allow",
      },
      webfetch: "deny",
      websearch: "deny",
      codesearch: "deny",
      "chrome-devtools*": "deny",
    },
    ctx,
  ),
  description:
    'Implementation planner. Creates step-by-step plans in `.agents/plans/` and specs in `.agents/specs/`. Delegates to explorer (file locations), researcher (API details), architect (design decisions). Specify detail: "outline" (5-10 steps), "detailed" (15-30 tasks), "spec" (formal with acceptance criteria).',
  prompt: expandProtocols(PROMPT),
});

export const setupPlannerAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.planner ?? {}, getDefaults(ctx));
};

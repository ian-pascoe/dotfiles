import type { AgentConfig, PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "../..";
import { getAgentPermissions } from "../../permission";
import { expandProtocols } from "../util/protocols";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig =>
  ({
    mode: "all",
    hidden: false,
    model: ctx.config.model,
    temperature: 0.7,
    color: "#d946ef",
    permission: defu(getAgentPermissions("planner", ctx), {
      edit: {
        ".agents/plans/*.md": "allow",
        ".agents/specs/*.md": "allow",
      },
      webfetch: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
      "chrome-devtools_*": "deny",
    } satisfies PermissionConfig),
    description:
      'Implementation planner. Creates step-by-step plans in `.agents/plans/` and specs in `.agents/specs/`. Delegates to explorer (file locations), librarian (API details), architect (design decisions). Specify detail: "outline" (5-10 steps), "detailed" (15-30 tasks), "spec" (formal with acceptance criteria).',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupPlannerAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.planner ?? {}, getDefaults(ctx));
};

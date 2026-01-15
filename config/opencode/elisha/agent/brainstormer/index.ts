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
  temperature: 1.2,
  permission: setupAgentPermissions(
    "brainstormer",
    {
      edit: "deny",
      webfetch: "deny",
      websearch: "deny",
      codesearch: "deny",
      "chrome-devtools*": "deny",
    },
    ctx,
  ),
  description:
    'Creative ideation specialist. Generates diverse ideas, explores unconventional approaches, and brainstorms solutions. Specify mode: "divergent" (maximize variety), "convergent" (refine ideas), "wild" (no constraints). IDEATION-ONLY, no implementation.',
  prompt: expandProtocols(PROMPT),
});

export const setupBrainstormerAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.brainstormer ?? {}, getDefaults(ctx));
};

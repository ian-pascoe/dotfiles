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
    model: ctx.config.small_model,
    temperature: 0.2,
    color: "#fb923c",
    permission: defu(getAgentPermissions("tester", ctx), {
      edit: "deny",
      webfetch: "deny",
      "context7_*": "deny",
      "grep_*": "deny",
      "exa_*": "deny",
    } satisfies PermissionConfig),
    description:
      'Test specialist. Runs tests, analyzes failures, suggests improvements. Delegates to explorer (patterns) and librarian (frameworks). Specify mode: "run" (execute tests), "analyze" (diagnose failures), "suggest" (recommend new tests).',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupTesterAgentConfig = (ctx: ElishaContext): AgentConfig => {
  return defu(ctx.config.agent?.tester ?? {}, getDefaults(ctx));
};

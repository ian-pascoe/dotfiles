import type { AgentConfig, PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "../..";
import { getAgentPermissions, getGlobalPermissions } from "../../permission";
import { expandProtocols } from "../util/protocols";

import PROMPT from "./prompt.txt";

const getDefaults = (ctx: ElishaConfigContext): AgentConfig =>
  ({
    mode: "subagent",
    hidden: false,
    model: ctx.config.model,
    temperature: 0.7,
    color: "#fb923c",
    permission: defu(
      getAgentPermissions("documenter", ctx),
      {
        edit: {
          "**/*.md": "allow",
          "README*": "allow",
        },
        webfetch: "deny",
        "context7_*": "deny",
        "grep_*": "deny",
        "exa_*": "deny",
        "chrome-devtools_*": "deny",
      } satisfies PermissionConfig,
      getGlobalPermissions(ctx),
    ),
    description:
      'Documentation writer. Creates and updates docs. Delegates to explorer (code to document) and researcher (doc standards). Specify scope: "file" (single file), "module" (related files), "project" (overview docs).',
    prompt: expandProtocols(PROMPT),
  }) satisfies AgentConfig;

export const setupDocumenterAgentConfig = (
  ctx: ElishaConfigContext,
): AgentConfig => {
  return defu(ctx.config.agent?.documenter ?? {}, getDefaults(ctx));
};

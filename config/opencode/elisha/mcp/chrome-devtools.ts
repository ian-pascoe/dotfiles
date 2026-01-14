import { ElishaConfigContext } from "..";
import defu from "defu";
import { McpConfig } from ".";

export const defaults: McpConfig = {
  enabled: true,
  type: "local",
  command: ["bunx", "-y", "chrome-devtools-mcp@latest"],
};

export const setupChromeDevtoolsMcpConfig = (
  ctx: ElishaConfigContext,
): McpConfig => {
  return defu(ctx.config.mcp?.["chrome-devtools"] ?? {}, defaults) as McpConfig;
};

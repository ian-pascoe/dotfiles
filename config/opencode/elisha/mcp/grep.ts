import { ElishaConfigContext } from "..";
import defu from "defu";
import { McpConfig } from ".";

export const defaults: McpConfig = {
  enabled: true,
  type: "remote",
  url: "https://mcp.grep.app",
};

export const setupGrepMcpConfig = (ctx: ElishaConfigContext): McpConfig => {
  return defu(ctx.config.mcp?.grep ?? {}, defaults) as McpConfig;
};

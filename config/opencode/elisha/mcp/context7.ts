import { ElishaConfigContext } from "..";
import defu from "defu";
import { McpConfig } from ".";

export const defaults: McpConfig = {
  enabled: true,
  type: "remote",
  url: "https://mcp.context7.com/mcp",
};

export const setupContext7McpConfig = (ctx: ElishaConfigContext): McpConfig => {
  return defu(ctx.config.mcp?.context7 ?? {}, defaults) as McpConfig;
};

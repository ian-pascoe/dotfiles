import { ElishaConfigContext } from "..";
import defu from "defu";
import { McpConfig } from ".";

export const defaults: McpConfig = {
  enabled: true,
  type: "remote",
  url: "https://mcp.grep.app?tools=web_search_exa,deep_search_exa",
};

export const setupGrepAppMcpConfig = (ctx: ElishaConfigContext): McpConfig => {
  return defu(ctx.config.mcp?.["grep-app"] ?? {}, defaults) as McpConfig;
};

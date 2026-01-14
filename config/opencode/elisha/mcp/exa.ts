import { ElishaConfigContext } from "..";
import defu from "defu";
import { McpConfig } from ".";

export const defaults: McpConfig = {
  enabled: true,
  type: "remote",
  url: "https://mcp.exa.ai/mcp",
  headers: process.env.EXA_API_KEY
    ? { "x-api-key": process.env.EXA_API_KEY }
    : undefined,
};

export const setupExaMcpConfig = (ctx: ElishaConfigContext): McpConfig => {
  return defu(ctx.config.mcp?.exa ?? {}, defaults) as McpConfig;
};

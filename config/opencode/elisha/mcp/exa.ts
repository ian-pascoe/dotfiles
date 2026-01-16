import defu from 'defu';
import type { ElishaConfigContext } from '..';
import type { McpConfig } from '.';

export const MCP_EXA_ID = 'exa';

export const defaults: McpConfig = {
  enabled: true,
  type: 'remote',
  url: 'https://mcp.exa.ai/mcp?tools=web_search_exa,deep_search_exa',
  headers: process.env.EXA_API_KEY
    ? { 'x-api-key': process.env.EXA_API_KEY }
    : undefined,
};

export const setupExaMcpConfig = (ctx: ElishaConfigContext) => {
  ctx.config.mcp ??= {};
  ctx.config.mcp[MCP_EXA_ID] = defu(
    ctx.config.mcp?.[MCP_EXA_ID] ?? {},
    defaults,
  ) as McpConfig;
};

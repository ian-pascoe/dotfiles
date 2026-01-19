import defu from 'defu';
import type { ElishaConfigContext } from '..';
import type { McpConfig } from '.';

export const MCP_CONTEXT7_ID = 'context7';

export const getDefaults = (_ctx: ElishaConfigContext): McpConfig => ({
  enabled: true,
  type: 'remote',
  url: 'https://mcp.context7.com/mcp',
  headers: process.env.CONTEXT7_API_KEY
    ? { CONTEXT7_API_KEY: process.env.CONTEXT7_API_KEY }
    : undefined,
});

export const setupContext7McpConfig = (ctx: ElishaConfigContext) => {
  ctx.config.mcp ??= {};
  ctx.config.mcp[MCP_CONTEXT7_ID] = defu(
    ctx.config.mcp?.[MCP_CONTEXT7_ID] ?? {},
    getDefaults(ctx),
  ) as McpConfig;
};

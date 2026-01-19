import defu from 'defu';
import type { ElishaConfigContext } from '..';
import type { McpConfig } from '.';

export const MCP_GREP_APP_ID = 'grep-app';

export const getDefaults = (_ctx: ElishaConfigContext): McpConfig => ({
  enabled: true,
  type: 'remote',
  url: 'https://mcp.grep.app',
});

export const setupGrepAppMcpConfig = (ctx: ElishaConfigContext) => {
  ctx.config.mcp ??= {};
  ctx.config.mcp[MCP_GREP_APP_ID] = defu(
    ctx.config.mcp?.[MCP_GREP_APP_ID] ?? {},
    getDefaults(ctx),
  ) as McpConfig;
};

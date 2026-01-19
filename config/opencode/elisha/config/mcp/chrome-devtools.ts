import defu from 'defu';
import type { ElishaConfigContext } from '..';
import type { McpConfig } from '.';

export const MCP_CHROME_DEVTOOLS_ID = 'chrome-devtools';

export const getDefaults = (_ctx: ElishaConfigContext): McpConfig => ({
  enabled: true,
  type: 'local',
  command: ['bunx', '-y', 'chrome-devtools-mcp@latest'],
});

export const setupChromeDevtoolsMcpConfig = (ctx: ElishaConfigContext) => {
  ctx.config.mcp ??= {};
  ctx.config.mcp[MCP_CHROME_DEVTOOLS_ID] = defu(
    ctx.config.mcp?.[MCP_CHROME_DEVTOOLS_ID] ?? {},
    getDefaults(ctx),
  ) as McpConfig;
};

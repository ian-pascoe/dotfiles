import type { ElishaConfigContext } from '..';
import { setupChromeDevtoolsMcpConfig } from './chrome-devtools';
import { setupContext7McpConfig } from './context7';
import { setupExaMcpConfig } from './exa';
import { setupGrepAppMcpConfig } from './grep-app';

export const setupMcpConfig = (ctx: ElishaConfigContext) => {
  setupContext7McpConfig(ctx);
  setupExaMcpConfig(ctx);
  setupGrepAppMcpConfig(ctx);
  setupChromeDevtoolsMcpConfig(ctx);
};

export type * from './types';

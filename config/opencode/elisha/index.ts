import type { Plugin } from '@opencode-ai/plugin';
import { setupConfig } from './config';
import { setupHooks } from './hooks';

export const ElishaPlugin: Plugin = async (ctx) => {
  return {
    config: setupConfig(ctx),
    ...setupHooks(ctx),
  };
};

import type { Plugin } from '@opencode-ai/plugin';
import type { ElishaConfigContext } from '.';
import { setupAgentConfig } from './agent';
import { setupMcpConfig } from './mcp';
import { setupPermissionConfig } from './permission';
import { setupSkillConfig } from './skill';

export const ElishaPlugin: Plugin = async (ctx) => {
  return {
    config: async (config) => {
      const configCtx: ElishaConfigContext = { ...ctx, config };
      setupMcpConfig(configCtx);
      setupAgentConfig(configCtx);
      setupSkillConfig(configCtx);
      setupPermissionConfig(configCtx);
    },
  };
};

export type * from './types';

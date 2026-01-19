import type { AgentConfig } from '@opencode-ai/sdk';
import defu from 'defu';
import type { ElishaConfigContext } from '../../types';

export const AGENT_COMPACTION_ID = 'compaction';

export const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  model: ctx.config.small_model,
});

export const setupCompactionAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_COMPACTION_ID] = defu(
    ctx.config.agent?.[AGENT_COMPACTION_ID] ?? {},
    getDefaults(ctx),
  );
};

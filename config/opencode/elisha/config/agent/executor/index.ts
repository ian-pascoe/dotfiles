import type { AgentConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '../..';
import { setupAgentPermissions } from '../../permission/agent';
import { expandProtocols } from '../util/protocols';

import PROMPT from './prompt.txt';

export const AGENT_EXECUTOR_ID = 'executor';

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: 'all',
  hidden: false,
  model: ctx.config.model,
  temperature: 0.5,
  permission: setupAgentPermissions(
    AGENT_EXECUTOR_ID,
    {
      edit: 'allow',
      webfetch: 'deny',
      websearch: 'deny',
      codesearch: 'deny',
      'chrome-devtools*': 'deny',
    },
    ctx,
  ),
  description:
    'Implementation executor. Reads plans from `.agents/plans/` (or specs from `.agents/specs/`), writes code, updates plan status. Delegates to explorer (find patterns) and researcher (API docs) when stuck. Specify mode: "step" (one task), "phase" (one phase), "full" (entire plan).',
  prompt: expandProtocols(PROMPT),
});

export const setupExecutorAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_EXECUTOR_ID] = defu(
    ctx.config.agent?.[AGENT_EXECUTOR_ID] ?? {},
    getDefaults(ctx),
  );
};

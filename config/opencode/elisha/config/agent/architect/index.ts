import type { AgentConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '../..';
import { setupAgentPermissions } from '../../permission/agent';
import { expandProtocols } from '../util/protocols';

import PROMPT from './prompt.txt';

export const AGENT_ARCHITECT_ID = 'architect';

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: 'subagent',
  hidden: false,
  model: ctx.config.model,
  temperature: 0.3,
  permission: setupAgentPermissions(
    AGENT_ARCHITECT_ID,
    {
      edit: 'deny',
      webfetch: 'deny',
      websearch: 'deny',
      codesearch: 'deny',
      'chrome-devtools*': 'deny',
    },
    ctx,
  ),
  description:
    'Solution designer. Analyzes requirements, evaluates approaches, recommends architecture. Delegates to explorer (codebase) and researcher (research). Specify scope: "component" (single feature), "system" (multi-component), "strategic" (large-scale). DESIGN-ONLY, no code.',
  prompt: expandProtocols(PROMPT),
});

export const setupArchitectAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_ARCHITECT_ID] = defu(
    ctx.config.agent?.[AGENT_ARCHITECT_ID] ?? {},
    getDefaults(ctx),
  );
};

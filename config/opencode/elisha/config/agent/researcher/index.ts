import type { AgentConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '../..';
import { setupAgentPermissions } from '../../permission/agent';
import { expandProtocols } from '../util/protocols';

import PROMPT from './prompt.txt';

export const AGENT_RESEARCHER_ID = 'researcher';

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: 'subagent',
  hidden: false,
  model: ctx.config.small_model,
  temperature: 0.9,
  permission: setupAgentPermissions(
    AGENT_RESEARCHER_ID,
    {
      edit: 'deny',
      webfetch: 'allow',
      websearch: 'allow',
      codesearch: 'allow',
      'chrome-devtools*': 'deny',
    },
    ctx,
  ),
  description:
    'External research specialist. Finds library docs, API examples, GitHub code patterns. Specify thoroughness: "quick" (1-2 queries), "medium" (3-4 queries), "thorough" (5+ queries). Returns synthesized findings with sources. No local codebase access.',
  prompt: expandProtocols(PROMPT),
});

export const setupResearcherAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_RESEARCHER_ID] = defu(
    ctx.config.agent?.[AGENT_RESEARCHER_ID] ?? {},
    getDefaults(ctx),
  );
};

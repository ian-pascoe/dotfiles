import type { AgentConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '../..';
import { setupAgentPermissions } from '../../permission/agent';
import { expandProtocols } from '../util/protocols';

import PROMPT from './prompt.txt';

export const AGENT_TESTER_ID = 'tester';

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: 'subagent',
  hidden: false,
  model: ctx.config.small_model,
  temperature: 0.2,
  permission: setupAgentPermissions(
    AGENT_TESTER_ID,
    {
      edit: 'deny',
      webfetch: 'deny',
      websearch: 'deny',
      codesearch: 'deny',
      'chrome-devtools*': 'allow',
    },
    ctx,
  ),
  description:
    'Test specialist. Runs tests, analyzes failures, suggests improvements. Delegates to explorer (patterns) and researcher (frameworks). Specify mode: "run" (execute tests), "analyze" (diagnose failures), "suggest" (recommend new tests).',
  prompt: expandProtocols(PROMPT),
});

export const setupTesterAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_TESTER_ID] = defu(
    ctx.config.agent?.[AGENT_TESTER_ID] ?? {},
    getDefaults(ctx),
  );
};

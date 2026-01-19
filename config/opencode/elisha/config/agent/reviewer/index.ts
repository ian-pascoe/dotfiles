import type { AgentConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '../..';
import { setupAgentPermissions } from '../../permission/agent';
import { expandProtocols } from '../util/protocols';

import PROMPT from './prompt.txt';

export const AGENT_REVIEWER_ID = 'reviewer';

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: 'all',
  hidden: false,
  model: ctx.config.model,
  temperature: 0.2,
  permission: setupAgentPermissions(
    AGENT_REVIEWER_ID,
    {
      edit: {
        '.agents/reviews/*.md': 'allow',
      },
      webfetch: 'deny',
      websearch: 'deny',
      codesearch: 'deny',
      'chrome-devtools*': 'deny',
    },
    ctx,
  ),
  description:
    'Code reviewer. Analyzes diffs for issues. Delegates to explorer (context) and researcher (best practices). Specify scope: "quick" (obvious issues), "standard" (full review), "thorough" (deep analysis). READ-ONLY.',
  prompt: expandProtocols(PROMPT),
});

export const setupReviewerAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_REVIEWER_ID] = defu(
    ctx.config.agent?.[AGENT_REVIEWER_ID] ?? {},
    getDefaults(ctx),
  );
};

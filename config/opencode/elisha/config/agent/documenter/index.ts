import type { AgentConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '../..';
import { setupAgentPermissions } from '../../permission/agent';
import { expandProtocols } from '../util/protocols';

import PROMPT from './prompt.txt';

export const AGENT_DOCUMENTER_ID = 'documenter';

const getDefaults = (ctx: ElishaConfigContext): AgentConfig => ({
  mode: 'subagent',
  hidden: false,
  model: ctx.config.model,
  temperature: 0.2,
  permission: setupAgentPermissions(
    AGENT_DOCUMENTER_ID,
    {
      edit: {
        '**/*.md': 'allow',
        'README*': 'allow',
      },
      webfetch: 'deny',
      websearch: 'deny',
      codesearch: 'deny',
      'chrome-devtools*': 'deny',
    },
    ctx,
  ),
  description:
    'Documentation writer. Creates and updates docs. Delegates to explorer (code to document) and researcher (doc standards). Specify scope: "file" (single file), "module" (related files), "project" (overview docs).',
  prompt: expandProtocols(PROMPT),
});

export const setupDocumenterAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[AGENT_DOCUMENTER_ID] = defu(
    ctx.config.agent?.[AGENT_DOCUMENTER_ID] ?? {},
    getDefaults(ctx),
  );
};

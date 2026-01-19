import defu from 'defu';
import type { ElishaConfigContext } from '../../..';
import type { CommandConfig } from '../..';

import PROMPT from './prompt.txt';

export const COMMAND_OPENMEMORY_INIT_ID = 'openmemory-init';

const getDefaults = (_ctx: ElishaConfigContext): CommandConfig => ({
  template: PROMPT,
  description: 'Initialize openmemory with memories for the current project',
});

export const setupOpenMemoryInitCommandConfig = (ctx: ElishaConfigContext) => {
  ctx.config.command ??= {};
  ctx.config.command[COMMAND_OPENMEMORY_INIT_ID] = defu(
    ctx.config.command?.[COMMAND_OPENMEMORY_INIT_ID] ?? {},
    getDefaults(ctx),
  );
};

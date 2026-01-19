import type { ElishaConfigContext } from '../../types';
import { setupOpenMemoryInitCommandConfig } from './init';

export const setupOpenMemoryCommandConfig = (ctx: ElishaConfigContext) => {
  if (ctx.config.mcp?.openmemory?.enabled ?? true) {
    setupOpenMemoryInitCommandConfig(ctx);
  }
};

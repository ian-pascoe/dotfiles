import type { ElishaConfigContext } from '../types';
import { setupOpenMemoryCommandConfig } from './openmemory';

export const setupCommandConfig = (ctx: ElishaConfigContext) => {
  setupOpenMemoryCommandConfig(ctx);
};

export type * from './types';

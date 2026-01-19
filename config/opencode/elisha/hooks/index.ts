import type { Plugin, PluginInput } from '@opencode-ai/plugin';
import { setupMemoryHooks } from './memory';

export type Hooks = Omit<Awaited<ReturnType<Plugin>>, 'config' | 'tool'>;

export const setupHooks = (ctx: PluginInput): Hooks => {
  const memoryHooks = setupMemoryHooks(ctx);

  return {
    ...memoryHooks,
    'chat.message': async (input, output) => {
      await Promise.all([memoryHooks['chat.message']?.(input, output)]);
    },
    event: async (input) => {
      await Promise.all([memoryHooks.event?.(input)]);
    },
  };
};

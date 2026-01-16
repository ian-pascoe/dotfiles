import type { PluginInput } from '@opencode-ai/plugin';
import type { Config } from '@opencode-ai/sdk/v2';

export type ElishaConfigContext = PluginInput & { config: Config };

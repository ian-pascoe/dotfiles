import type { Config } from '@opencode-ai/sdk/v2';

export type CommandConfig = NonNullable<Config['command']>[string];

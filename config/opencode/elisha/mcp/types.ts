import { Config } from "@opencode-ai/sdk/v2";

export type McpConfig = NonNullable<Config["mcp"]>[string];

import { PluginInput } from "@opencode-ai/plugin";
import { Config } from "@opencode-ai/sdk/v2";

export type ElishaConfigContext = PluginInput & { config: Config };

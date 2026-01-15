import { ElishaConfigContext } from "..";
import { setupChromeDevtoolsMcpConfig } from "./chrome-devtools";
import { setupContext7McpConfig } from "./context7";
import { setupExaMcpConfig } from "./exa";
import { setupGrepAppMcpConfig } from "./grep";

export const setupMcpConfig = (ctx: ElishaConfigContext) => {
  ctx.config.mcp ??= {};

  ctx.config.mcp.context7 = setupContext7McpConfig(ctx);
  ctx.config.mcp.exa = setupExaMcpConfig(ctx);
  ctx.config.mcp["grep-app"] = setupGrepAppMcpConfig(ctx);
  ctx.config.mcp["chrome-devtools"] = setupChromeDevtoolsMcpConfig(ctx);
};

export type * from "./types";

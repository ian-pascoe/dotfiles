import { PermissionConfig } from "@opencode-ai/sdk/v2";
import { ElishaConfigContext } from "..";
import defu from "defu";

const getDefaults = (ctx: ElishaConfigContext): PermissionConfig => {
  const config: PermissionConfig = {
    bash: "allow",
    codesearch: "ask", // Always ask before performing code searches
    doom_loop: "ask",
    edit: "allow",
    external_directory: "ask", // Always ask before accessing external directories
    glob: "allow",
    grep: "allow",
    list: "allow",
    lsp: "allow",
    question: "allow",
    read: "allow",
    task: "allow",
    todoread: "allow",
    todowrite: "allow",
    webfetch: "ask", // Always ask before fetching from the web
    websearch: "ask", // Always ask before performing web searches
  };

  if (ctx.config.mcp?.context7?.enabled ?? true) {
    config.codesearch = "deny"; // Use context7 instead
    config["context7_*"] = "allow";
  }

  if (ctx.config.mcp?.grep?.enabled ?? true) {
    config.codesearch = "deny"; // Use grep instead
    config["grep_*"] = "allow";
  }

  if (ctx.config.mcp?.exa?.enabled ?? true) {
    config.websearch = "deny"; // Use exa instead
    config["exa_*"] = "allow";
  }

  if (ctx.config.mcp?.["chrome-devtools"]?.enabled ?? true) {
    config["chrome-devtools_*"] = "allow";
  }

  return config;
};

export const getGlobalPermissions = (
  ctx: ElishaConfigContext,
): PermissionConfig => {
  return defu(ctx.config.permission ?? {}, getDefaults(ctx));
};

export const getAgentPermissions = (
  agent: string,
  ctx: ElishaConfigContext,
): PermissionConfig => {
  return defu(
    ctx.config.agent?.[agent]?.permission ?? {},
    getGlobalPermissions(ctx),
  );
};

export const setupPermissionConfig = (ctx: ElishaConfigContext) => {
  ctx.config.permission = getGlobalPermissions(ctx);
};

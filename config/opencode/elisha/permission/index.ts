import type { PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "..";

const getDefaultPermissions = (ctx: ElishaConfigContext): PermissionConfig => {
  const config: PermissionConfig = {
    bash: {
      "*": "allow",
      "rm * /": "deny",
      "rm * ~": "deny",
    },
    codesearch: "ask", // Always ask before performing code searches
    doom_loop: "ask",
    edit: "allow",
    external_directory: "ask", // Always ask before accessing external directories
    glob: "allow",
    grep: "allow",
    list: "allow",
    lsp: "allow",
    question: "allow",
    read: {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow",
    },
    task: "allow",
    todoread: "allow",
    todowrite: "allow",
    webfetch: "ask", // Always ask before fetching from the web
    websearch: "ask", // Always ask before performing web searches
  };

  if (ctx.config.mcp?.context7?.enabled ?? true) {
    config["context7*"] = "ask";
  }

  if (ctx.config.mcp?.["grep-app"]?.enabled ?? true) {
    config["grep-app*"] = "ask";
  }

  if (ctx.config.mcp?.exa?.enabled ?? true) {
    config["exa*"] = "ask";
  }

  if (ctx.config.mcp?.["chrome-devtools"]?.enabled ?? true) {
    config["chrome-devtools*"] = "deny";
  }

  return config;
};

export const getGlobalPermissions = (
  ctx: ElishaConfigContext,
): PermissionConfig => {
  if (typeof ctx.config.permission !== "object") {
    return ctx.config.permission ?? getDefaultPermissions(ctx);
  }

  return defu(ctx.config.permission, getDefaultPermissions(ctx));
};

export const cleanupPermissions = (
  config: PermissionConfig,
  ctx: ElishaConfigContext,
): PermissionConfig => {
  if (typeof config !== "object") {
    return config;
  }

  const codesearchPermission = config.codesearch;
  if (codesearchPermission) {
    if (ctx.config.mcp?.context7?.enabled ?? true) {
      const context7Permission = config["context7*"];
      config["context7*"] = context7Permission ?? codesearchPermission;
    }

    if (ctx.config.mcp?.["grep-app"]?.enabled ?? true) {
      const grepAppPermission = config["grep-app*"];
      config.codesearch = "deny"; // Use grep instead
      config["grep-app*"] = grepAppPermission ?? codesearchPermission;
    }
  }

  const websearchPermission = config.websearch;
  if (websearchPermission === "allow" || websearchPermission === "ask") {
    if (ctx.config.mcp?.exa?.enabled ?? true) {
      const exaPermission = config["exa*"];
      config.websearch = "deny"; // Use exa instead
      config["exa*"] = exaPermission ?? websearchPermission;
    }
  }

  return config;
};

export const setupPermissionConfig = (ctx: ElishaConfigContext) => {
  ctx.config.permission = cleanupPermissions(getGlobalPermissions(ctx), ctx);
};

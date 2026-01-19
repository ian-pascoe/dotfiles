import type { PermissionConfig } from '@opencode-ai/sdk/v2';
import defu from 'defu';
import type { ElishaConfigContext } from '..';
import { MCP_CHROME_DEVTOOLS_ID } from '../mcp/chrome-devtools';
import { MCP_CONTEXT7_ID } from '../mcp/context7';
import { MCP_EXA_ID } from '../mcp/exa';
import { MCP_GREP_APP_ID } from '../mcp/grep-app';
import { MCP_OPENMEMORY_ID } from '../mcp/openmemory';

const getDefaultPermissions = (ctx: ElishaConfigContext): PermissionConfig => {
  const config: PermissionConfig = {
    bash: {
      '*': 'allow',
      'rm * /': 'deny',
      'rm * ~': 'deny',
    },
    codesearch: 'ask', // Always ask before performing code searches
    doom_loop: 'ask',
    edit: 'allow',
    external_directory: 'ask', // Always ask before accessing external directories
    glob: 'allow',
    grep: 'allow',
    list: 'allow',
    lsp: 'allow',
    question: 'allow',
    read: {
      '*': 'allow',
      '*.env': 'deny',
      '*.env.*': 'deny',
      '*.env.example': 'allow',
    },
    task: 'allow',
    todoread: 'allow',
    todowrite: 'allow',
    webfetch: 'ask', // Always ask before fetching from the web
    websearch: 'ask', // Always ask before performing web searches
  };

  if (ctx.config.mcp?.[MCP_OPENMEMORY_ID]?.enabled ?? true) {
    config[`${MCP_OPENMEMORY_ID}*`] = 'allow';
  }

  if (ctx.config.mcp?.[MCP_CHROME_DEVTOOLS_ID]?.enabled ?? true) {
    config[`${MCP_CHROME_DEVTOOLS_ID}*`] = 'deny';
  }

  return config;
};

export const getGlobalPermissions = (
  ctx: ElishaConfigContext,
): PermissionConfig => {
  if (typeof ctx.config.permission !== 'object') {
    return ctx.config.permission ?? getDefaultPermissions(ctx);
  }
  return defu(ctx.config.permission, getDefaultPermissions(ctx));
};

export const cleanupPermissions = (
  config: PermissionConfig,
  ctx: ElishaConfigContext,
): PermissionConfig => {
  if (typeof config !== 'object') {
    return config;
  }

  const codesearchPermission = config.codesearch;
  if (codesearchPermission) {
    if (ctx.config.mcp?.[MCP_CONTEXT7_ID]?.enabled ?? true) {
      const context7Permission = config[`${MCP_CONTEXT7_ID}*`];
      config[`${MCP_CONTEXT7_ID}*`] =
        context7Permission ?? codesearchPermission;
    }

    if (ctx.config.mcp?.[MCP_GREP_APP_ID]?.enabled ?? true) {
      const grepAppPermission = config[`${MCP_GREP_APP_ID}*`];
      config.codesearch = 'deny'; // Use grep instead
      config[`${MCP_GREP_APP_ID}*`] = grepAppPermission ?? codesearchPermission;
    }
  }

  const websearchPermission = config.websearch;
  if (websearchPermission) {
    if (ctx.config.mcp?.[MCP_EXA_ID]?.enabled ?? true) {
      const exaPermission = config[`${MCP_EXA_ID}*`];
      config.websearch = 'deny'; // Use exa instead
      config[`${MCP_EXA_ID}*`] = exaPermission ?? websearchPermission;
    }
  }

  return config;
};

export const setupPermissionConfig = (ctx: ElishaConfigContext) => {
  ctx.config.permission = cleanupPermissions(getGlobalPermissions(ctx), ctx);
};

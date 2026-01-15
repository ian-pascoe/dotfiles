import type { PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import { cleanupPermissions, getGlobalPermissions } from ".";
import type { ElishaConfigContext } from "..";

export const setupAgentPermissions = (
  name: string,
  permissions: PermissionConfig,
  ctx: ElishaConfigContext,
) => {
  return cleanupPermissions(
    defu(
      ctx.config.agent?.[name]?.permission ?? {},
      permissions,
      getGlobalPermissions(ctx),
    ),
    ctx,
  );
};

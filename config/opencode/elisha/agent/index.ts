import type { PermissionConfig } from "@opencode-ai/sdk/v2";
import defu from "defu";
import type { ElishaConfigContext } from "..";
import { getAgentPermissions, getGlobalPermissions } from "../permission";
import { setupArchitectAgentConfig } from "./architect";
import { setupBrainstormerAgentConfig } from "./brainstormer";
import { setupDocumenterAgentConfig } from "./documenter";
import { setupExecutorAgentConfig } from "./executor";
import { setupExplorerAgentConfig } from "./explorer";
import { setupOrchestratorAgentConfig } from "./orchestrator";
import { setupPlannerAgentConfig } from "./planner";
import { setupResearcherAgentConfig } from "./researcher";
import { setupReviewerAgentConfig } from "./reviewer";
import { setupTesterAgentConfig } from "./tester";

export const setupAgentConfig = (ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};

  // Disable default OpenCode agents
  ctx.config.agent.build = defu(ctx.config.agent?.build ?? {}, {
    disable: true,
  });
  ctx.config.agent.plan = defu(ctx.config.agent?.plan ?? {}, {
    disable: true,
  });
  ctx.config.agent.explore = defu(ctx.config.agent?.explore ?? {}, {
    disable: true,
  });
  ctx.config.agent.general = defu(ctx.config.agent?.general ?? {}, {
    disable: true,
  });

  // Elisha agents
  ctx.config.agent.architect = setupArchitectAgentConfig(ctx);
  ctx.config.agent.brainstormer = setupBrainstormerAgentConfig(ctx);
  ctx.config.agent.documenter = setupDocumenterAgentConfig(ctx);
  ctx.config.agent.executor = setupExecutorAgentConfig(ctx);
  ctx.config.agent.explorer = setupExplorerAgentConfig(ctx);
  ctx.config.agent.orchestrator = setupOrchestratorAgentConfig(ctx);
  ctx.config.agent.planner = setupPlannerAgentConfig(ctx);
  ctx.config.agent.researcher = setupResearcherAgentConfig(ctx);
  ctx.config.agent.reviewer = setupReviewerAgentConfig(ctx);
  ctx.config.agent.tester = setupTesterAgentConfig(ctx);
};

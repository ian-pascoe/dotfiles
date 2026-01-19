import defu from 'defu';
import type { ElishaConfigContext } from '..';
import { setupArchitectAgentConfig } from './architect';
import { setupBrainstormerAgentConfig } from './brainstormer';
import { setupCompactionAgentConfig } from './compaction';
import { setupDocumenterAgentConfig } from './documenter';
import { setupExecutorAgentConfig } from './executor';
import { setupExplorerAgentConfig } from './explorer';
import { setupOrchestratorAgentConfig } from './orchestrator';
import { setupPlannerAgentConfig } from './planner';
import { setupResearcherAgentConfig } from './researcher';
import { setupReviewerAgentConfig } from './reviewer';
import { setupTesterAgentConfig } from './tester';

const disableAgent = (name: string, ctx: ElishaConfigContext) => {
  ctx.config.agent ??= {};
  ctx.config.agent[name] = defu(ctx.config.agent?.[name] ?? {}, {
    disable: true,
  });
};

export const setupAgentConfig = (ctx: ElishaConfigContext) => {
  disableAgent('build', ctx);
  disableAgent('plan', ctx);
  disableAgent('explore', ctx);
  disableAgent('general', ctx);

  setupCompactionAgentConfig(ctx);

  // Elisha agents
  setupArchitectAgentConfig(ctx);
  setupBrainstormerAgentConfig(ctx);
  setupDocumenterAgentConfig(ctx);
  setupExecutorAgentConfig(ctx);
  setupExplorerAgentConfig(ctx);
  setupOrchestratorAgentConfig(ctx);
  setupPlannerAgentConfig(ctx);
  setupResearcherAgentConfig(ctx);
  setupReviewerAgentConfig(ctx);
  setupTesterAgentConfig(ctx);
};

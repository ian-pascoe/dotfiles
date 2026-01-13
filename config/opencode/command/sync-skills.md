---
description: Synchronize agents and skills to work cohesively together
agent: orchestrator
---

# Sync Skills with Agents

Analyze the current state of agents and skills, then update them to work together effectively.

## Your Task

Perform a complete agent-skill synchronization:

### Phase 1: Discovery

1. **Explore all agents** in `config/opencode/agent/*.md`:
   - Note each agent's role, mode, and capabilities
   - Check if they have a "Skill Loading" section
   - Identify which skills are currently referenced

2. **Explore all skills** in `config/opencode/skill/*/SKILL.md`:
   - Note each skill's name and trigger conditions (from description)
   - Identify the primary agent that should use each skill

3. **Check the registry** at `config/opencode/agent/_skills/REGISTRY.md`:
   - Compare listed skills against actual skills in `skill/` directory
   - Identify any skills not in the registry
   - Identify any orphaned registry entries

### Phase 2: Analysis

4. **Identify gaps**:
   - Skills without registry entries
   - Agents missing skill loading sections who should have them
   - Registry entries pointing to non-existent skills
   - Skill descriptions not following "Use when..." convention

5. **Report findings** before making changes:
   - List all discovered gaps
   - Propose specific changes
   - Wait for user confirmation if there are significant changes

### Phase 3: Updates

6. **Update the registry** (`_skills/REGISTRY.md`):
   - Add missing skills to appropriate domain sections
   - Remove orphaned entries
   - Ensure trigger patterns are clear and specific

7. **Update agents** as needed:
   - Add "Skill Loading" sections to agents that need them
   - Reference the skill registry: `[Skill Registry](_skills/REGISTRY.md)`
   - Include relevant skill mappings for that agent's domain

8. **Fix skill inconsistencies**:
   - Ensure all skill descriptions start with "Use when..."
   - Verify skill names match directory names

### Phase 4: Validation

9. **Verify the integration**:
   - Confirm all skills are in the registry
   - Confirm agents reference the registry appropriately
   - Confirm no broken links or references

10. **Commit changes** if any were made:
    - Stage all modified files explicitly (never use `git add .`)
    - Use commit message: "chore(opencode): sync agents and skills registry"
    - Push to remote

## Output Format

Provide a summary report:

```
## Sync Results

### Skills Found
- [list of skills]

### Agents Updated
- [list of agents and what changed]

### Registry Changes
- [additions/removals]

### Issues Fixed
- [description inconsistencies, etc.]

### Status
[SYNCED | CHANGES MADE | NO CHANGES NEEDED]
```

## Notes

- Follow existing conventions (see `_protocols/` for patterns)
- Skills should map to agents based on their domain:
  - executor: implementation skills (git, frontend, etc.)
  - documenter: writing/documentation skills
  - architect: design/planning skills (prompt engineering, etc.)
- The orchestrator gets skill routing awareness, not skill loading

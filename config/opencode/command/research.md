---
description: Research a ticket or provide a prompt for ad-hoc research. It is best to run this command in a new session.
---

# Research Codebase

Conduct comprehensive research across the codebase by spawning agents and synthesizing findings.

## Process

1. **Read the ticket FULLY** - Complete context before spawning agents

2. **Plan the research** - Break down into composable areas, identify what to search for

3. **Phase 1 - Locate & Discover (parallel)**
   - Fire **explore** agents to find WHERE files/components live
   - Fire **librarian** agents if external libraries are relevant
   - Wait for all to complete

4. **Phase 2 - Deep Analysis (if needed)**
   - Fire additional **explore** for deeper investigation
   - Consult **oracle** for architectural complexity
   - Fire **librarian** for external patterns/docs
   - Use **multimodal-looker** if ticket references diagrams, screenshots, or PDFs
   - Wait for all to complete

5. **Gather metadata** - Get current git commit hash and branch name for frontmatter

6. **Write research document** to `thoughts/research/date_topic.md`:

```markdown
---
date: [ISO datetime with timezone]
git_commit: [from metadata]
branch: [from metadata]
topic: "[Research Topic]"
tags: [research, relevant-components]
---

## Ticket Synopsis
[Synopsis of ticket]

## Summary
[High-level findings]

## Detailed Findings

### [Component 1]
- Finding with reference ([file:line])
- Implementation details

### [Component 2]
...

## Code References
- `path/to/file:123` - Description

## Architecture Insights
[Patterns, conventions discovered]

## Open Questions
[Areas needing further investigation]
```

7. **Present findings** - Concise summary with key file references

8. **Handle follow-ups** - Append to same document under `## Follow-up Research [timestamp]`

9. **Update ticket status** to `researched`

## Key Rules

- Read files FULLY before spawning agents
- Wait for ALL agents before synthesizing
- **Stop researching when you have enough** - 2 search iterations with no new info = done
- Prioritize codebase findings as primary source of truth
- Don't over-explore - time is precious

**ticket**

$ARGUMENTS

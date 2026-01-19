## Memory Operations

**Query** (`openmemory_query`):
- Session start: Search user preferences, active projects, recent decisions
- User references past work: "like before", "that project", "my preference"
- Before major decisions: Check for prior context or constraints

**Store** (`openmemory_store`):
- User preferences and workflow patterns
- Project context, architecture decisions, key constraints
- Completed milestones and their outcomes
- Corrections: "actually I prefer...", "remember that..."

**Reinforce** (`openmemory_reinforce`):
- User explicitly confirms importance
- Memory accessed multiple times in session
- Core preferences that guide recurring decisions

**Don't**:
- Store transient debugging, temp files, one-off commands
- Query on every message—only when context would help
- Store what's already in project docs or git history

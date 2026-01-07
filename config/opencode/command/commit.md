---
description: Commits the local changes in atomic commits. This command is best run after completing an execute run successfully, and preparing for plan review.
---

# Commit Changes

Create git commits for the changes made during this session.

## TODO CREATION (MANDATORY)

**IMMEDIATELY** create a todo list before any other action:

```
1. Review session changes and git status
2. Plan commit groupings
3. Execute commits with proper messages
4. Sync beads
```

Use `todowrite` to create these items, then mark each `in_progress` as you work and `completed` when done.

## Commit Types

Use conventional commit prefixes:

- **feat:** New features or functionality
- **fix:** Bug fixes or adjustments
- **doc:** Documentation changes
- **perf:** Performance improvements
- **refactor:** Code restructuring, same behavior
- **style:** Formatting, whitespace, no code change
- **test:** Adding or updating tests
- **build:** Build system or dependency changes
- **ci:** CI/CD pipeline changes
- **chore:** Miscellaneous (tidying up, maintenance)

## Process

1. **Think about what changed:**
   - Review conversation history and understand what was accomplished
   - Review `git status -s` to see what files changed
   - Consider whether changes should be one commit or multiple logical commits
   - Use `git diff` on specific files only if you have no knowledge of changes in that file

2. **Plan your commit(s):**
   - Identify which files belong together
   - Select appropriate commit type from above
   - Draft clear, descriptive commit messages: `type: description`
   - Use imperative mood, focus on why not what

3. **Present your plan OR just execute:**
   - If straightforward and grouping is obvious, proceed directly
   - If ambiguous, present plan first and ask: "I plan to create [N] commit(s). Shall I proceed?"

4. **Execute:**
   - Use `git add` with specific files (never use `-A` or `.`)
   - Create commits with your planned messages
   - Show result with `git log --oneline -n [N]`

5. **Sync beads:**
   - Run `bd sync` to commit any beads changes and sync with remote
   - This ensures issue tracking stays in sync with code changes

## Release Notes

Changelog groups: Features (`feat`), Bug Fixes (`fix`), Documentation (`doc`), Performance (`perf`), Refactoring (`refactor`), Styling (`style`), Testing (`test`), Build (`build`), CI/CD (`ci`), Miscellaneous (`chore`). Security issues are grouped separately if "security" appears in the commit body.

Release commits (`chore(release)`) are skipped.

## Remember

- You already have full context from this session - use it
- Group related changes together
- Keep commits focused and atomic
- Trust your judgment - the user asked you to commit
- Always `bd sync` at the end to keep beads in sync

---
description: Commits the local changes in atomic commits. This command is best run after completing an execute run successfully, and preparing for plan review.
---

# Commit Changes

You are tasked with creating git commits for the changes made during this session.

## Commit Types

Use conventional commit prefixes to categorize changes:

- **fix:** Bugs that are being fixed or adjustments to how things work
- **feat:** Features that have been added
- **chore:** Tidying things up, not making substantial changes to how things work
- **refactor:** Changes that don't change the behavior, but do change the internal layout
- **docs:** Purely documentation and thoughts updates
- **ci:** Changes to how the CI system works

## Process:

1. **Think about what changed:**
   - Review the conversation history and understand what was accomplished
   - Review the `git status -s` to get an idea of what files changed
   - Consider whether changes should be one commit or multiple logical commits
   - Use `git diff` on specific files if you need more context. Only do this if you have no knowledge of the changes in that file.

2. **Plan your commit(s):**
   - Identify which files belong together
   - **Select the appropriate commit type** from the list above based on the nature of the changes
   - Draft clear, descriptive commit messages using the format: `type: description`
   - Use imperative mood in commit messages
   - Focus on why the changes were made, not just what

3. **Present your plan OR just execute:**
   - If changes are straightforward and grouping is obvious, proceed directly
   - If ambiguous (multiple possible groupings, unclear commit boundaries), present plan first:
     - List files for each commit with commit message
     - Ask: "I plan to create [N] commit(s). Shall I proceed?"

4. **Execute upon confirmation:**
   - Use `git add` with specific files (never use `-A` or `.`)
   - Create commits with your planned messages
   - Show the result with `git log --oneline -n [N]`

## Release Notes

Note: During release generation, commits with `chore:`, `docs:`, and `ci:` prefixes are automatically filtered out from the changelog to focus on user-facing changes. Other prefixes like `fix:` and `feat:` are included.

## Remember:
- You already have full context from this session - use it
- Group related changes together
- Keep commits focused and atomic
- Trust your judgment - the user asked you to commit


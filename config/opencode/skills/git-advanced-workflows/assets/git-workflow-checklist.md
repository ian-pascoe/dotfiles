# Pre-PR Git Workflow Checklist

Use this checklist before creating a pull request to ensure clean, reviewable history.

---

## Quick Reference

```bash
# One-liner status check
git fetch origin && git status && git log --oneline origin/main..HEAD
```

---

## Branch Status

- [ ] **Synced with main**: Branch is up-to-date with target branch

  ```bash
  git fetch origin
  git rebase origin/main  # or: git merge origin/main
  ```

- [ ] **No merge conflicts**: Rebasing/merging completed without conflicts

  ```bash
  git diff --check  # Check for conflict markers
  ```

- [ ] **Clean working directory**: No uncommitted changes

  ```bash
  git status  # Should show "nothing to commit"
  ```

---

## Commit Hygiene

### Message Quality

- [ ] **Conventional commit format**: Using type prefix (feat, fix, docs, etc.)

  ```
  feat: add user authentication
  fix: resolve login timeout issue
  docs: update API documentation
  refactor: extract validation logic
  test: add unit tests for auth module
  chore: update dependencies
  ```

- [ ] **Clear, descriptive messages**: Explains what AND why

  ```bash
  git log --oneline -10  # Review your commit messages
  ```

- [ ] **No generic messages**: No "fix", "update", "changes", "WIP"

### Commit Structure

- [ ] **Atomic commits**: Each commit is a single logical change

  ```bash
  git log --oneline --stat  # Review what each commit changes
  ```

- [ ] **No broken commits**: Each commit builds and passes tests

  ```bash
  git rebase -i --exec "npm test" origin/main
  ```

- [ ] **Logical order**: Commits ordered for reviewer understanding

- [ ] **Squashed fixups**: No "fix typo" or "oops" commits

  ```bash
  git log --oneline | grep -i "fix\|typo\|oops\|wip"
  # If any found, squash them
  git rebase -i --autosquash origin/main
  ```

---

## Code Quality

- [ ] **Tests pass**: All tests green

  ```bash
  npm test  # or: cargo test, pytest, etc.
  ```

- [ ] **Linting passes**: No linting errors

  ```bash
  npm run lint  # or: eslint, ruff, clippy, etc.
  ```

- [ ] **Type checking passes**: (if applicable)

  ```bash
  npm run typecheck  # or: tsc, mypy, etc.
  ```

- [ ] **Build succeeds**: Project compiles/builds

  ```bash
  npm run build  # or: cargo build, make, etc.
  ```

- [ ] **No debugging code**: Console.logs, print statements, debugger removed

  ```bash
  git diff origin/main | grep -E "console\.log|print\(|debugger"
  ```

---

## Security Check

- [ ] **No secrets committed**: No API keys, passwords, tokens

  ```bash
  git diff origin/main | grep -iE "password|secret|api.?key|token"
  ```

- [ ] **No sensitive files**: Check for .env, credentials, private keys

  ```bash
  git diff --name-only origin/main | grep -E "\.env|\.pem|\.key|credentials"
  ```

- [ ] **.gitignore updated**: New sensitive patterns added if needed

---

## File Hygiene

- [ ] **No unrelated changes**: Only files relevant to this PR

  ```bash
  git diff --name-only origin/main  # Review the list
  ```

- [ ] **No generated files**: Build artifacts not committed

  ```bash
  git diff --name-only origin/main | grep -E "dist/|build/|node_modules/"
  ```

- [ ] **No large files**: No binaries or assets that should use LFS

  ```bash
  git diff --stat origin/main | tail -1  # Check total size
  ```

- [ ] **Correct line endings**: No CRLF issues (if applicable)

  ```bash
  git diff --check origin/main
  ```

---

## Branch Naming

- [ ] **Follows convention**: Branch name matches team standard

  ```
  feature/user-authentication
  fix/login-timeout-bug
  docs/api-update
  refactor/validation-logic
  ```

- [ ] **Descriptive**: Name reflects the work done

---

## PR Preparation

- [ ] **Draft PR description**: Summary of changes written
- [ ] **Linked issues**: Related issue numbers identified
- [ ] **Reviewers identified**: Know who should review
- [ ] **Labels ready**: Appropriate labels selected

---

## Final Verification

```bash
# Run this final check sequence
git fetch origin
git status
git log --oneline origin/main..HEAD
git diff --stat origin/main
npm test && npm run lint && npm run build
```

---

## Common Cleanup Commands

### Squash all commits into one

```bash
git rebase -i $(git merge-base HEAD origin/main)
# Mark all but first as 'squash' or 'fixup'
```

### Fix last commit message

```bash
git commit --amend -m "new message"
```

### Add forgotten file to last commit

```bash
git add forgotten-file.py
git commit --amend --no-edit
```

### Reorder commits

```bash
git rebase -i origin/main
# Reorder lines in editor
```

### Split a large commit

```bash
git rebase -i HEAD~3
# Mark commit as 'edit'
git reset HEAD^
git add -p  # Stage in parts
git commit -m "part 1"
git add -p
git commit -m "part 2"
git rebase --continue
```

### Remove accidental commit

```bash
git rebase -i origin/main
# Mark commit as 'drop' or delete the line
```

---

## Quick Fixes

| Issue | Command |
|-------|---------|
| Undo last commit (keep changes) | `git reset --soft HEAD^` |
| Undo last commit (discard changes) | `git reset --hard HEAD^` |
| Fix commit message | `git commit --amend` |
| Add to last commit | `git add . && git commit --amend --no-edit` |
| Unstage file | `git reset HEAD <file>` |
| Discard file changes | `git checkout -- <file>` |
| Clean untracked files | `git clean -fd` |

---

## Push Safely

```bash
# After all cleanup, push with lease for safety
git push --force-with-lease origin feature/my-branch
```

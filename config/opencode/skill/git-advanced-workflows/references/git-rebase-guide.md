# Git Interactive Rebase Deep Dive

A comprehensive guide to mastering interactive rebase for clean, professional Git history.

## Understanding Rebase Fundamentals

### What Rebase Actually Does

Rebase replays commits from one branch onto another base. Unlike merge, which creates a merge commit preserving both histories, rebase rewrites commits to create a linear history.

```
Before rebase:           After rebase:
    A---B---C feature        A---B---C feature
   /                                  |
  D---E---F main            D---E---F main
```

### The Golden Rule

**Never rebase commits that have been pushed to a shared branch.** Rebase rewrites commit hashes, causing conflicts for collaborators.

Safe to rebase:

- Local commits not yet pushed
- Feature branches only you work on
- After explicit team coordination

## Interactive Rebase Commands

### Starting Interactive Rebase

```bash
# Rebase last N commits
git rebase -i HEAD~5

# Rebase from specific commit (exclusive)
git rebase -i abc123

# Rebase all commits since branching from main
git rebase -i $(git merge-base HEAD main)

# Rebase onto specific branch
git rebase -i --onto main feature-base feature-branch
```

### Rebase Operations

| Command | Description | Use Case |
|---------|-------------|----------|
| `pick` (p) | Keep commit as-is | Default action |
| `reword` (r) | Keep commit, edit message | Fix typos, improve clarity |
| `edit` (e) | Pause for amending | Add/remove changes, split commits |
| `squash` (s) | Combine with previous, edit message | Consolidate related work |
| `fixup` (f) | Combine with previous, discard message | Clean up "fix typo" commits |
| `drop` (d) | Remove commit entirely | Delete obsolete changes |
| `exec` (x) | Run shell command | Run tests between commits |

### Reordering Commits

Simply change the order of lines in the rebase todo:

```bash
# Original order:
pick abc123 Add user model
pick def456 Add user controller
pick ghi789 Fix user model typo

# Reordered (move fix next to what it fixes):
pick abc123 Add user model
pick ghi789 Fix user model typo  # Moved up
pick def456 Add user controller
```

## Advanced Rebase Scenarios

### Squashing Multiple Commits

```bash
git rebase -i HEAD~4

# In editor, change to:
pick abc123 feat: implement user authentication
squash def456 add password validation
squash ghi789 add session management
squash jkl012 fix edge case in auth
```

Result: Single commit with combined changes and edited message.

### Using Fixup for Clean History

```bash
# Make initial commit
git commit -m "feat: add user dashboard"

# Later, fix a bug in that feature
git add .
git commit --fixup abc123  # Creates "fixup! feat: add user dashboard"

# Even later, another fix
git add .
git commit --fixup abc123

# When ready, autosquash during rebase
git rebase -i --autosquash main
# Fixup commits automatically positioned and marked
```

### Splitting a Commit

```bash
git rebase -i HEAD~3

# Mark the commit to split with 'edit'
# Git pauses at that commit

# Reset to before the commit, keeping changes staged
git reset HEAD^

# Now make multiple commits
git add src/models/
git commit -m "feat: add data models"

git add src/controllers/
git commit -m "feat: add API controllers"

git add tests/
git commit -m "test: add unit tests"

# Continue the rebase
git rebase --continue
```

### Editing a Commit's Content

```bash
git rebase -i HEAD~3

# Mark commit with 'edit'
# Git pauses at that commit

# Make your changes
vim src/file.py

# Amend the commit
git add .
git commit --amend --no-edit

# Continue
git rebase --continue
```

### Running Tests Between Commits

```bash
git rebase -i HEAD~5

# Add exec commands:
pick abc123 feat: add feature A
exec npm test
pick def456 feat: add feature B
exec npm test
pick ghi789 fix: bug in feature A
exec npm test
```

Or automatically after each commit:

```bash
git rebase -i --exec "npm test" HEAD~5
```

## Conflict Resolution During Rebase

### Understanding Rebase Conflicts

Rebase applies commits one at a time. Conflicts occur when a commit's changes conflict with the new base.

```bash
# Start rebase
git rebase main

# Conflict occurs
# CONFLICT (content): Merge conflict in src/file.py
# Fix the conflict and then run "git rebase --continue"
```

### Resolving Conflicts

```bash
# 1. View conflicted files
git status

# 2. Open and fix conflicts
# Look for conflict markers:
# <<<<<<< HEAD
# (changes from new base)
# =======
# (changes from commit being rebased)
# >>>>>>> abc123 (commit being rebased)

# 3. Stage resolved files
git add src/file.py

# 4. Continue rebase
git rebase --continue
```

### Conflict Resolution Strategies

```bash
# Accept current (base) version
git checkout --ours path/to/file

# Accept incoming (rebased commit) version
git checkout --theirs path/to/file

# Use merge tool
git mergetool

# Skip problematic commit entirely
git rebase --skip

# Abort and return to original state
git rebase --abort
```

### Handling Repeated Conflicts

If you get the same conflicts repeatedly:

```bash
# Enable rerere (reuse recorded resolution)
git config --global rerere.enabled true

# Git will remember how you resolved conflicts
# and automatically apply the same resolution
```

## When to Use Rebase

### Use Rebase When

1. **Updating feature branch with main changes**

   ```bash
   git checkout feature/my-feature
   git fetch origin
   git rebase origin/main
   ```

2. **Cleaning up local history before PR**

   ```bash
   git rebase -i $(git merge-base HEAD main)
   ```

3. **Creating linear history for easier review**

4. **Preparing commits for cherry-picking**

### Avoid Rebase When

1. **Commits are already pushed to shared branch**
2. **Multiple people work on the same branch**
3. **You need to preserve exact merge history**
4. **Working on main/master directly**

## Rebase Configuration

### Useful Config Options

```bash
# Always rebase when pulling
git config --global pull.rebase true

# Enable autosquash by default
git config --global rebase.autoSquash true

# Enable autostash during rebase
git config --global rebase.autoStash true

# Show more context in rebase editor
git config --global rebase.instructionFormat "(%an) %s"

# Use rebase for branch updating
git config --global branch.autosetuprebase always
```

### Per-Branch Settings

```bash
# Set specific branch to rebase on pull
git config branch.feature-branch.rebase true
```

## Recovery from Rebase Issues

### Using ORIG_HEAD

After a rebase, `ORIG_HEAD` points to where you were:

```bash
# Undo the entire rebase
git reset --hard ORIG_HEAD
```

### Using Reflog

```bash
# Find pre-rebase state
git reflog

# Output:
# abc123 HEAD@{0}: rebase finished: returning to refs/heads/feature
# def456 HEAD@{1}: rebase: feat: add feature
# ghi789 HEAD@{5}: commit: original commit before rebase

# Reset to pre-rebase state
git reset --hard HEAD@{5}
```

### Creating Safety Branch

```bash
# Before risky rebase
git branch backup-feature

# Do rebase
git rebase -i main

# If something goes wrong
git reset --hard backup-feature

# If successful, delete backup
git branch -d backup-feature
```

## Interactive Rebase Best Practices

1. **Review commits first**: `git log --oneline` before rebasing
2. **Work in small batches**: Rebase 5-10 commits at a time
3. **Make backup branch**: Safety net for complex rebases
4. **Test after rebase**: Run tests to ensure nothing broke
5. **Use --force-with-lease**: Safer than --force when pushing
6. **Communicate with team**: Coordinate if rebasing shared work

## Common Rebase Patterns

### Pattern: Clean Feature Branch for PR

```bash
# Sync with main
git fetch origin
git rebase origin/main

# Clean up commits
git rebase -i $(git merge-base HEAD origin/main)

# Push (force if previously pushed)
git push --force-with-lease origin feature/my-feature
```

### Pattern: Extract Commit to New Branch

```bash
# Create new branch at the commit
git branch extracted-feature abc123

# Remove from current branch
git rebase -i abc123^
# Mark the commit as 'drop'
```

### Pattern: Move Commits to Different Base

```bash
# Move commits from wrong-base to correct-base
git rebase --onto correct-base wrong-base feature-branch
```

## Troubleshooting

### "Cannot rebase: You have unstaged changes"

```bash
# Either commit changes
git add . && git commit -m "WIP"

# Or stash them
git stash
git rebase ...
git stash pop
```

### "Interactive rebase already started"

```bash
# Continue existing rebase
git rebase --continue

# Or abort and start fresh
git rebase --abort
```

### Rebase seems stuck in loop

```bash
# This can happen with complex histories
# Abort and try a different approach
git rebase --abort

# Consider using merge instead, or
# breaking the rebase into smaller steps
```

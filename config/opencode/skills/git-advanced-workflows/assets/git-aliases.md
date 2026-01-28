# Git Aliases for Advanced Workflows

Curated aliases to speed up advanced Git operations. Add these to your `~/.gitconfig` or use `git config --global alias.<name> '<command>'`.

## Installation

### Option 1: Add to ~/.gitconfig

```ini
[alias]
    # Paste aliases from sections below
```

### Option 2: Individual commands

```bash
git config --global alias.st 'status'
```

---

## Essential Aliases

### Status and Information

```ini
[alias]
    # Concise status
    st = status -sb

    # Detailed status
    stat = status

    # Last commit info
    last = log -1 HEAD --stat

    # Show current branch name
    cb = rev-parse --abbrev-ref HEAD

    # Show all branches with last commit
    branches = branch -av --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative))%(color:reset)'
```

### Log Viewing

```ini
[alias]
    # Pretty log with graph
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    # Compact log
    lo = log --oneline -20

    # Log with files changed
    lf = log --oneline --stat

    # Log current branch only (since main)
    lb = log --oneline main..HEAD

    # Show commits by author
    by = "!f() { git log --author=\"$1\" --oneline; }; f"

    # Today's commits
    today = log --since=midnight --author='$(git config user.email)' --oneline

    # This week's commits
    week = log --since='1 week ago' --author='$(git config user.email)' --oneline
```

---

## Rebase Aliases

```ini
[alias]
    # Interactive rebase from main
    rim = "!git rebase -i $(git merge-base HEAD main)"

    # Interactive rebase from origin/main
    rio = "!git rebase -i $(git merge-base HEAD origin/main)"

    # Interactive rebase last N commits
    ri = "!f() { git rebase -i HEAD~${1:-5}; }; f"

    # Rebase with autosquash
    rias = "!git rebase -i --autosquash $(git merge-base HEAD main)"

    # Continue rebase
    rc = rebase --continue

    # Abort rebase
    ra = rebase --abort

    # Skip problematic commit in rebase
    rs = rebase --skip

    # Rebase onto main
    rom = rebase origin/main

    # Update branch with main (rebase)
    up = "!git fetch origin && git rebase origin/main"
```

---

## Commit Aliases

```ini
[alias]
    # Commit with message
    cm = commit -m

    # Commit all changes with message
    cam = commit -am

    # Amend last commit
    amend = commit --amend --no-edit

    # Amend with new message
    reword = commit --amend

    # Fixup commit (for autosquash)
    fixup = "!f() { git commit --fixup ${1:-HEAD}; }; f"

    # Squash commit (for autosquash)
    squash = "!f() { git commit --squash ${1:-HEAD}; }; f"

    # WIP commit
    wip = !git add -A && git commit -m 'WIP: work in progress [skip ci]'

    # Undo WIP commit (keep changes)
    unwip = reset --soft HEAD^
```

---

## Branch Management

```ini
[alias]
    # Create and switch to branch
    cob = checkout -b

    # Switch to main
    com = checkout main

    # Delete branch locally
    bd = branch -d

    # Force delete branch
    bD = branch -D

    # Delete remote branch
    bdr = "!f() { git push origin --delete $1; }; f"

    # List branches merged to main
    merged = "!git branch --merged main | grep -v 'main'"

    # Delete all merged branches
    cleanup = "!git branch --merged main | grep -v 'main' | xargs -r git branch -d"

    # List stale remote branches
    stale = remote prune origin --dry-run

    # Prune stale remote branches
    prune = remote prune origin
```

---

## Cherry-Pick Aliases

```ini
[alias]
    # Cherry-pick
    cp = cherry-pick

    # Cherry-pick without committing
    cpn = cherry-pick -n

    # Cherry-pick continue
    cpc = cherry-pick --continue

    # Cherry-pick abort
    cpa = cherry-pick --abort
```

---

## Stash Aliases

```ini
[alias]
    # Quick stash
    ss = stash push

    # Stash with message
    sm = stash push -m

    # Stash including untracked
    sau = stash push -u

    # Pop last stash
    sp = stash pop

    # Apply without removing from stash
    sa = stash apply

    # List stashes
    sl = stash list

    # Show stash contents
    sshow = stash show -p

    # Drop specific stash
    sd = stash drop
```

---

## Diff Aliases

```ini
[alias]
    # Diff staged changes
    ds = diff --staged

    # Diff with word highlighting
    dw = diff --word-diff

    # Diff branch from main
    dm = diff main...HEAD

    # Diff names only
    dn = diff --name-only

    # Diff stat
    dst = diff --stat

    # Show what would be in PR
    pr-diff = "!git diff $(git merge-base HEAD origin/main)..HEAD"
```

---

## Recovery Aliases

```ini
[alias]
    # View reflog
    rl = reflog

    # Undo last commit (keep changes)
    undo = reset --soft HEAD^

    # Undo last commit (discard changes)
    nuke = reset --hard HEAD^

    # Reset to origin branch
    resetorigin = "!git fetch origin && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)"

    # Find lost commits
    lost = fsck --lost-found

    # Recover deleted branch (use with reflog hash)
    recover = "!f() { git branch recovered-$1 $1; }; f"
```

---

## Bisect Aliases

```ini
[alias]
    # Start bisect
    bis = bisect start

    # Mark as bad
    bib = bisect bad

    # Mark as good
    big = bisect good

    # Reset bisect
    bir = bisect reset

    # Run automated bisect
    birun = bisect run
```

---

## Worktree Aliases

```ini
[alias]
    # List worktrees
    wl = worktree list

    # Add worktree
    wa = "!f() { git worktree add ../$1 $2; }; f"

    # Remove worktree
    wr = "!f() { git worktree remove ../$1; }; f"

    # Prune worktrees
    wp = worktree prune
```

---

## Utility Aliases

```ini
[alias]
    # Push with lease (safer force push)
    pushf = push --force-with-lease

    # Set upstream and push
    pushu = "!git push -u origin $(git rev-parse --abbrev-ref HEAD)"

    # Fetch and prune
    fp = fetch --prune

    # Pull with rebase
    pr = pull --rebase

    # Show all aliases
    aliases = config --get-regexp alias

    # Open git gui
    gui = !gitk --all &

    # Count commits by author
    stats = shortlog -sn --all

    # Find commits with string in message
    find = "!f() { git log --oneline --grep=\"$1\"; }; f"

    # Find commits with string in code
    search = "!f() { git log -S\"$1\" --oneline; }; f"

    # Show contributors
    contributors = shortlog -sn --no-merges
```

---

## Workflow Combinations

```ini
[alias]
    # Morning sync: fetch, prune, show status
    morning = "!git fetch --all --prune && git status"

    # Clean PR prep: sync, rebase, autosquash
    prep = "!git fetch origin && git rebase -i --autosquash origin/main"

    # Ship it: push with safety checks
    ship = "!git push --force-with-lease origin $(git rev-parse --abbrev-ref HEAD)"

    # Full cleanup: delete merged, prune remotes
    tidy = "!git branch --merged main | grep -v 'main' | xargs -r git branch -d && git remote prune origin"

    # Start new feature
    feature = "!f() { git checkout main && git pull && git checkout -b feature/$1; }; f"

    # Start bugfix
    bugfix = "!f() { git checkout main && git pull && git checkout -b fix/$1; }; f"
```

---

## Complete .gitconfig Section

Copy this entire block to your `~/.gitconfig`:

```ini
[alias]
    # Status
    st = status -sb
    cb = rev-parse --abbrev-ref HEAD

    # Log
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    lo = log --oneline -20
    lb = log --oneline main..HEAD

    # Rebase
    rim = "!git rebase -i $(git merge-base HEAD main)"
    rio = "!git rebase -i $(git merge-base HEAD origin/main)"
    rias = "!git rebase -i --autosquash $(git merge-base HEAD main)"
    rc = rebase --continue
    ra = rebase --abort
    up = "!git fetch origin && git rebase origin/main"

    # Commit
    cm = commit -m
    amend = commit --amend --no-edit
    fixup = "!f() { git commit --fixup ${1:-HEAD}; }; f"
    wip = !git add -A && git commit -m 'WIP [skip ci]'
    unwip = reset --soft HEAD^

    # Branch
    cob = checkout -b
    com = checkout main
    cleanup = "!git branch --merged main | grep -v 'main' | xargs -r git branch -d"

    # Recovery
    undo = reset --soft HEAD^
    rl = reflog

    # Push
    pushf = push --force-with-lease
    pushu = "!git push -u origin $(git rev-parse --abbrev-ref HEAD)"

    # Diff
    ds = diff --staged
    dm = diff main...HEAD

    # Workflow
    prep = "!git fetch origin && git rebase -i --autosquash origin/main"
    ship = "!git push --force-with-lease origin $(git rev-parse --abbrev-ref HEAD)"
    feature = "!f() { git checkout main && git pull && git checkout -b feature/$1; }; f"
```

---

## Tips

1. **View all aliases**: `git aliases` (with the alias defined above)
2. **Override default commands**: Create aliases like `git push` → safer version
3. **Shell aliases work too**: Add `alias g='git'` to your shell config
4. **Include files**: Use `[include]` in .gitconfig to organize aliases by category

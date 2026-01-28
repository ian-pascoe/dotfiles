# Advanced Git Conflict Resolution

Comprehensive strategies for resolving merge conflicts efficiently and correctly.

## Understanding Conflicts

### Why Conflicts Occur

Conflicts happen when Git cannot automatically reconcile changes:

1. **Same line edited**: Both branches modified the same line
2. **File deleted vs modified**: One branch deletes, another modifies
3. **Rename conflicts**: Both branches rename differently
4. **Binary file changes**: Git can't merge binary content

### Merge vs Rebase Conflicts

| Aspect | Merge Conflicts | Rebase Conflicts |
|--------|-----------------|------------------|
| Frequency | Once per merge | Once per commit being rebased |
| Context | Full branch context | One commit at a time |
| Resolution | Single resolution | May repeat for each commit |
| Abort | `git merge --abort` | `git rebase --abort` |
| Continue | `git merge --continue` | `git rebase --continue` |

## Conflict Markers Explained

```
<<<<<<< HEAD
Current branch changes (what you're merging INTO)
This is also called "ours" in merge context
=======
Incoming changes (what you're merging FROM)
This is also called "theirs" in merge context
>>>>>>> feature-branch
```

**Important**: In rebase context, "ours" and "theirs" are swapped because rebase replays commits onto the new base.

### Three-Way Merge Concept

Git uses three versions during conflict resolution:

```
        BASE (common ancestor)
       /    \
    OURS     THEIRS
  (current)  (incoming)
```

- **BASE**: The common ancestor commit
- **OURS**: Your current branch's version
- **THEIRS**: The incoming branch's version

## Conflict Resolution Strategies

### Strategy 1: Manual Resolution

```bash
# View conflicted files
git status

# Open file and resolve manually
vim src/file.py

# Remove conflict markers and keep correct code
# Stage resolved file
git add src/file.py

# Continue merge/rebase
git merge --continue  # or git rebase --continue
```

### Strategy 2: Accept One Side Entirely

```bash
# During merge - accept your version
git checkout --ours path/to/file.py

# During merge - accept their version
git checkout --theirs path/to/file.py

# Stage and continue
git add path/to/file.py
git merge --continue
```

**Caution for Rebase**: During rebase, ours/theirs are reversed:

- `--ours` = the branch you're rebasing onto (e.g., main)
- `--theirs` = your commits being replayed

### Strategy 3: Use Merge Tool

```bash
# Configure merge tool (one-time setup)
git config --global merge.tool vimdiff
# Or: meld, kdiff3, p4merge, vscode, etc.

# Launch merge tool
git mergetool

# For VS Code
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
```

### Strategy 4: Use Diff3 Format

Get more context with the BASE version:

```bash
# Enable diff3 format globally
git config --global merge.conflictstyle diff3
```

Now conflicts show three versions:

```
<<<<<<< HEAD
Current branch changes
||||||| merged common ancestor
Original version (BASE)
=======
Incoming changes
>>>>>>> feature-branch
```

## Advanced Resolution Techniques

### Using git checkout with Merge

```bash
# Checkout file and attempt 3-way merge
git checkout --merge path/to/file.py

# Checkout specific version
git checkout HEAD -- path/to/file.py    # Current branch version
git checkout MERGE_HEAD -- path/to/file.py  # Incoming version
git checkout ORIG_HEAD -- path/to/file.py   # Before merge started
```

### Using git restore (Git 2.23+)

```bash
# Restore to conflicted state
git restore --merge path/to/file.py

# Restore specific version
git restore --source=HEAD --staged --worktree path/to/file.py
git restore --source=MERGE_HEAD --staged --worktree path/to/file.py
```

### Resolving Entire Directories

```bash
# Accept all changes from one side for a directory
git checkout --ours -- src/legacy/
git add src/legacy/

# Or accept all incoming
git checkout --theirs -- src/api/
git add src/api/
```

## Rerere: Reuse Recorded Resolution

Rerere (reuse recorded resolution) remembers how you resolved conflicts and automatically applies the same resolution.

### Enable Rerere

```bash
# Enable globally
git config --global rerere.enabled true

# Enable for specific repo
git config rerere.enabled true
```

### How Rerere Works

```bash
# First time: resolve conflict manually
git merge feature-branch
# Conflict in file.py
vim file.py  # Resolve
git add file.py
git commit

# Git records this resolution

# Later: same conflict occurs
git merge another-branch
# Git automatically applies recorded resolution
# "Resolved 'file.py' using previous resolution."

# Review auto-resolution
git diff

# If correct, commit
git add file.py
git commit
```

### Managing Rerere Cache

```bash
# View recorded resolutions
ls .git/rr-cache/

# Forget a specific resolution
git rerere forget path/to/file.py

# Clear all recorded resolutions
rm -rf .git/rr-cache/
```

### Rerere with Training

Pre-record resolutions for known conflicts:

```bash
# Enable rerere
git config rerere.enabled true

# Merge and resolve
git merge feature-branch
# Resolve conflicts...
git add .
git rerere  # Record resolution
git commit

# Now undo to practice
git reset --hard HEAD^

# Merge again - resolution auto-applied
git merge feature-branch
# "Resolved 'file.py' using previous resolution."
```

## Handling Complex Conflicts

### Delete/Modify Conflicts

When one branch deletes a file another modified:

```bash
# Status shows:
# deleted by us: file.py
# or
# deleted by them: file.py

# Keep the file
git add file.py

# Or accept deletion
git rm file.py

# Continue
git merge --continue
```

### Rename Conflicts

When both branches rename differently:

```bash
# Git may detect as delete + add instead of rename
# Check what happened
git status

# Manual resolution - decide which name wins
git mv old-name.py chosen-name.py
git add chosen-name.py
git merge --continue
```

### Binary File Conflicts

```bash
# Cannot merge binary files
# Choose which version to keep

# Keep ours
git checkout --ours image.png
git add image.png

# Keep theirs
git checkout --theirs image.png
git add image.png

# Or provide new version
cp /path/to/correct/image.png image.png
git add image.png
```

### Submodule Conflicts

```bash
# Conflict in submodule pointer
git status
# both modified: external/library

# Choose which commit to use
cd external/library
git checkout <desired-commit>
cd ../..
git add external/library
git merge --continue
```

## Conflict Prevention Strategies

### 1. Pull Frequently

```bash
# Update regularly to minimize drift
git fetch origin
git rebase origin/main  # or merge
```

### 2. Communicate with Team

- Assign file ownership when possible
- Announce major refactors
- Use feature flags for parallel development

### 3. Structure Code for Fewer Conflicts

- Small, focused files
- Avoid "god" files everyone touches
- Clear module boundaries

### 4. Use Git Attributes

```gitattributes
# .gitattributes
# Treat generated files as binary (no merge)
*.generated.js binary

# Use specific merge driver for certain files
package-lock.json merge=ours
yarn.lock merge=ours

# Union merge for changelog (keep both)
CHANGELOG.md merge=union
```

### Custom Merge Drivers

```bash
# Define custom merge driver
git config merge.keep-ours.driver "cp -f %O %A"

# Use in .gitattributes
# config.lock merge=keep-ours
```

## Conflict Resolution Workflow

### Recommended Workflow

```bash
# 1. Start merge/rebase
git merge feature-branch

# 2. If conflicts, assess the situation
git status
git diff --name-only --diff-filter=U  # List conflicted files

# 3. For each conflicted file
git diff path/to/file.py  # See conflict details

# 4. Resolve using preferred method
# - Manual editing
# - Merge tool
# - Accept one side

# 5. Verify resolution
git diff --staged path/to/file.py  # Review what will be committed

# 6. Stage resolved file
git add path/to/file.py

# 7. After all conflicts resolved
git merge --continue  # or git rebase --continue

# 8. Test the result
npm test  # or your test command
```

### Emergency Escape Hatches

```bash
# Abandon merge completely
git merge --abort

# Abandon rebase completely
git rebase --abort

# If already committed, undo
git reset --hard ORIG_HEAD
```

## Troubleshooting

### "You have not concluded your merge"

```bash
# Either finish the merge
git add .
git commit

# Or abort it
git merge --abort
```

### "Cannot merge: You have unmerged files"

```bash
# Find unmerged files
git diff --name-only --diff-filter=U

# Resolve each one
# Then stage
git add <files>
```

### Conflict markers left in file

```bash
# Find files with conflict markers
grep -r "<<<<<<< HEAD" .

# Shows files that weren't properly resolved
```

### Wrong resolution applied

```bash
# If you haven't committed yet
git checkout --merge path/to/file  # Reset to conflicted state

# If you have committed
git revert HEAD  # Create reverting commit
# Or
git reset --hard HEAD^  # Remove commit (careful!)
```

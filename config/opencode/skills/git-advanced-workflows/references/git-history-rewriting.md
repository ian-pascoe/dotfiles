# Safely Rewriting Git History

Complete guide to modifying Git history for cleanup, security, and maintenance.

## When to Rewrite History

### Valid Reasons

- Remove accidentally committed secrets/credentials
- Clean up messy development history before merge
- Fix incorrect author information
- Remove large binary files that bloat repository
- Consolidate related commits for clarity

### When NOT to Rewrite

- Commits already pushed to shared/public branches
- History that others have based work on
- When a simple revert would suffice
- Without team coordination

## Amending Commits

### Amend Last Commit

```bash
# Change commit message only
git commit --amend -m "New message"

# Change commit message in editor
git commit --amend

# Add forgotten files to last commit
git add forgotten-file.py
git commit --amend --no-edit

# Change author of last commit
git commit --amend --author="Name <email@example.com>"

# Change date of last commit
git commit --amend --date="2024-01-15 10:30:00"
```

### Amend Without Editing Message

```bash
git commit --amend --no-edit
```

### Amend Older Commits

Use interactive rebase:

```bash
git rebase -i HEAD~3

# Mark commit with 'edit'
# Make changes
git commit --amend
git rebase --continue
```

## Filter-Branch vs Filter-Repo

### Overview

| Aspect | filter-branch | filter-repo |
|--------|---------------|-------------|
| Speed | Very slow | Fast (10-100x) |
| Safety | Less safe | Safer defaults |
| Complexity | Complex syntax | Simpler API |
| Status | Deprecated | Recommended |

**Recommendation**: Always use `git-filter-repo` for new work.

### Installing git-filter-repo

```bash
# macOS
brew install git-filter-repo

# pip
pip install git-filter-repo

# Linux
sudo apt install git-filter-repo  # Ubuntu 20.10+
```

## Removing Sensitive Data

### Using git-filter-repo (Recommended)

```bash
# Remove file from entire history
git filter-repo --path secrets.env --invert-paths

# Remove directory from entire history
git filter-repo --path config/credentials/ --invert-paths

# Remove by pattern
git filter-repo --path-glob '*.key' --invert-paths

# Remove content matching pattern (redact)
git filter-repo --replace-text expressions.txt

# expressions.txt format:
# literal:password123==>REDACTED
# regex:api[_-]?key\s*=\s*['"]?[a-zA-Z0-9]+['"]?==>API_KEY=REDACTED
```

### Using filter-branch (Legacy)

```bash
# Remove file from all commits
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret.env' \
  --prune-empty --tag-name-filter cat -- --all

# Remove directory
git filter-branch --force --index-filter \
  'git rm -rf --cached --ignore-unmatch path/to/secrets/' \
  --prune-empty --tag-name-filter cat -- --all
```

### Post-Removal Cleanup

```bash
# Remove original refs
rm -rf .git/refs/original/

# Expire reflog immediately
git reflog expire --expire=now --all

# Garbage collect
git gc --prune=now --aggressive

# Force push (COORDINATE WITH TEAM)
git push origin --force --all
git push origin --force --tags
```

### After Removing Secrets

1. **Rotate the credentials immediately** - assume they're compromised
2. **Force push to all remotes**
3. **Notify collaborators** - they must re-clone or rebase
4. **Contact GitHub support** to clear cached views (for GitHub-hosted repos)

## Changing Author Information

### Single Commit (Last Commit)

```bash
git commit --amend --author="New Name <new@email.com>" --no-edit
```

### Multiple Commits with filter-repo

```bash
# Change specific author
git filter-repo --email-callback '
  return email if email != b"old@email.com" else b"new@email.com"
'

# Using mailmap file
git filter-repo --mailmap mailmap.txt

# mailmap.txt format:
# Proper Name <proper@email.com> <old@email.com>
# Proper Name <proper@email.com> Old Name <old@email.com>
```

### Using filter-branch (Legacy)

```bash
git filter-branch --env-filter '
OLD_EMAIL="old@email.com"
NEW_NAME="New Name"
NEW_EMAIL="new@email.com"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$NEW_NAME"
    export GIT_COMMITTER_EMAIL="$NEW_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$NEW_NAME"
    export GIT_AUTHOR_EMAIL="$NEW_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
```

## Removing Large Files

### Find Large Files in History

```bash
# Using git-filter-repo analysis
git filter-repo --analyze
cat .git/filter-repo/analysis/blob-shas-and-paths.txt

# Manual method
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  sed -n 's/^blob //p' | \
  sort -nrk2 | \
  head -20
```

### Remove Large Files

```bash
# Remove specific large files
git filter-repo --path big-file.zip --invert-paths

# Remove files by size (e.g., > 10MB)
git filter-repo --strip-blobs-bigger-than 10M

# Remove by extension
git filter-repo --path-glob '*.mp4' --invert-paths
```

### Prevent Future Large Files

```bash
# Install git-lfs
brew install git-lfs
git lfs install

# Track large file types
git lfs track "*.psd"
git lfs track "*.zip"
git add .gitattributes
```

## Git Replace and Grafts

### Git Replace (Temporary History Modification)

Replace objects without rewriting history:

```bash
# Replace one commit with another
git replace <bad-commit> <good-commit>

# List replacements
git replace --list

# Remove replacement
git replace -d <commit>
```

### Grafts (Deprecated)

Grafts modify parent relationships. Now use `git replace`:

```bash
# Create graft (make commit appear to have different parent)
# Old method (deprecated):
# echo "<commit> <new-parent>" >> .git/info/grafts

# Modern method with replace:
git replace --graft <commit> <new-parent>

# Make grafts permanent
git filter-branch -- --all
```

### Use Cases for Replace

1. **Connect separated histories**

   ```bash
   # When migrating repos, connect old and new
   git replace --graft <first-new-commit> <last-old-commit>
   ```

2. **Hide commits without deleting**

   ```bash
   # Replace problematic commit with fixed version
   git commit --amend  # Create fixed commit
   git replace <old> <new>
   ```

## Splitting and Combining Repositories

### Extract Subdirectory to New Repo

```bash
# Using filter-repo
git filter-repo --subdirectory-filter path/to/subdir

# This makes subdir the new root
```

### Move Subdirectory to New Location

```bash
git filter-repo --path-rename old/path/:new/path/
```

### Combine Repositories

```bash
# Add second repo as remote
git remote add other-repo /path/to/other

# Fetch its history
git fetch other-repo --tags

# Merge with unrelated histories
git merge --allow-unrelated-histories other-repo/main

# Or use filter-repo to prefix paths before merging
git filter-repo --to-subdirectory-filter subdir-name
```

## Safety Measures

### Before Any History Rewrite

```bash
# 1. Create full backup
git clone --mirror . ../backup-$(date +%Y%m%d)

# 2. Work on a fresh clone
git clone original-repo rewrite-repo
cd rewrite-repo

# 3. Verify backup
cd ../backup-*
git log --oneline | head -5
```

### Verification After Rewrite

```bash
# Check for remaining sensitive data
git log --all -p | grep -i "password\|secret\|key"

# Verify file is gone from all history
git log --all --full-history -- path/to/removed/file
# Should return nothing

# Check repository size reduced
du -sh .git
```

### Recovery from Bad Rewrite

```bash
# If still in original repo
git reflog
git reset --hard <pre-rewrite-ref>

# If using backup
rm -rf rewrite-repo
cp -r backup-repo rewrite-repo
```

## Communicating History Changes

### When Pushing Rewritten History

1. **Coordinate with team** before force pushing
2. **Provide clear instructions**:

```markdown
## Repository History Rewritten

The repository history was rewritten to [reason].

### Action Required

If you have local clones, please run:

# Option 1: Fresh clone (recommended)
git clone <repo-url>

# Option 2: Reset existing clone
cd your-repo
git fetch origin
git reset --hard origin/main
git clean -fd

Do NOT merge or rebase local branches - this will reintroduce removed content.
```

### Force Push with Lease

```bash
# Safer force push - fails if remote changed
git push --force-with-lease origin main

# Force push all branches
git push --force-with-lease --all origin
```

## Best Practices Summary

1. **Always backup first**: Clone with `--mirror` before any rewrite
2. **Work on fresh clone**: Never rewrite in your main working copy
3. **Rotate exposed secrets**: History rewrite doesn't un-expose credentials
4. **Use filter-repo**: It's faster, safer, and recommended over filter-branch
5. **Coordinate with team**: Communicate before and after force pushes
6. **Verify thoroughly**: Check that sensitive data is fully removed
7. **Update CI/CD**: Force push may affect open PRs and deployments

#!/bin/bash
#
# git-clean-branches.sh
# Clean up merged and stale Git branches safely
#
# Usage:
#   ./git-clean-branches.sh [options]
#
# Options:
#   -d, --dry-run     Show what would be deleted without deleting
#   -f, --force       Delete without confirmation prompts
#   -r, --remote      Also clean up remote branches
#   -a, --all         Clean both merged and stale branches
#   -s, --stale-days  Days before considering branch stale (default: 90)
#   -m, --main        Main branch name (default: auto-detect main/master)
#   -h, --help        Show this help message
#
# Examples:
#   ./git-clean-branches.sh --dry-run
#   ./git-clean-branches.sh --force --remote
#   ./git-clean-branches.sh --stale-days 30 --all

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=false
FORCE=false
CLEAN_REMOTE=false
CLEAN_ALL=false
STALE_DAYS=90
MAIN_BRANCH=""

# Counters
DELETED_LOCAL=0
DELETED_REMOTE=0
SKIPPED=0

# Print colored output
print_info() { echo -e "${BLUE}INFO:${NC} $1"; }
print_success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
print_warning() { echo -e "${YELLOW}WARNING:${NC} $1"; }
print_error() { echo -e "${RED}ERROR:${NC} $1"; }

# Show help message
show_help() {
    sed -n '/^# Usage:/,/^# Examples:/p' "$0" | sed 's/^# //'
    echo ""
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -r|--remote)
                CLEAN_REMOTE=true
                shift
                ;;
            -a|--all)
                CLEAN_ALL=true
                shift
                ;;
            -s|--stale-days)
                STALE_DAYS="$2"
                shift 2
                ;;
            -m|--main)
                MAIN_BRANCH="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

# Detect main branch name
detect_main_branch() {
    if [[ -n "$MAIN_BRANCH" ]]; then
        echo "$MAIN_BRANCH"
        return
    fi

    # Check for common main branch names
    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master; then
        echo "master"
    else
        # Fallback to configured default or origin/HEAD
        git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
    fi
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Get current branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Check if branch is protected (should not be deleted)
is_protected_branch() {
    local branch="$1"
    local main_branch="$2"

    # List of protected branches
    local protected=("$main_branch" "main" "master" "develop" "staging" "production" "release")

    for protected_branch in "${protected[@]}"; do
        if [[ "$branch" == "$protected_branch" ]]; then
            return 0
        fi
    done

    return 1
}

# Confirm action with user
confirm() {
    local message="$1"

    if $FORCE; then
        return 0
    fi

    if $DRY_RUN; then
        return 0
    fi

    echo -n "$message [y/N] "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get merged branches
get_merged_branches() {
    local main_branch="$1"
    git branch --merged "$main_branch" | sed 's/^\*\?\s*//' | grep -v "^\s*$"
}

# Get stale branches (no commits in X days)
get_stale_branches() {
    local stale_date
    stale_date=$(date -v-${STALE_DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${STALE_DAYS} days ago" +%Y-%m-%d)

    git for-each-ref --sort=committerdate --format='%(refname:short) %(committerdate:short)' refs/heads/ | while read -r branch date; do
        if [[ "$date" < "$stale_date" ]]; then
            echo "$branch"
        fi
    done
}

# Delete local branch
delete_local_branch() {
    local branch="$1"
    local main_branch="$2"
    local current_branch
    current_branch=$(get_current_branch)

    # Skip if protected
    if is_protected_branch "$branch" "$main_branch"; then
        print_warning "Skipping protected branch: $branch"
        ((SKIPPED++))
        return
    fi

    # Skip if current branch
    if [[ "$branch" == "$current_branch" ]]; then
        print_warning "Skipping current branch: $branch"
        ((SKIPPED++))
        return
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] Would delete local branch: $branch"
    else
        if git branch -d "$branch" 2>/dev/null; then
            print_success "Deleted local branch: $branch"
            ((DELETED_LOCAL++))
        else
            # Try force delete for unmerged (only if confirmed)
            if confirm "Branch '$branch' is not fully merged. Force delete?"; then
                git branch -D "$branch"
                print_success "Force deleted local branch: $branch"
                ((DELETED_LOCAL++))
            else
                print_warning "Skipped unmerged branch: $branch"
                ((SKIPPED++))
            fi
        fi
    fi
}

# Delete remote branch
delete_remote_branch() {
    local branch="$1"
    local main_branch="$2"
    local remote_branch

    # Skip if protected
    if is_protected_branch "$branch" "$main_branch"; then
        print_warning "Skipping protected remote branch: $branch"
        ((SKIPPED++))
        return
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] Would delete remote branch: origin/$branch"
    else
        if git push origin --delete "$branch" 2>/dev/null; then
            print_success "Deleted remote branch: origin/$branch"
            ((DELETED_REMOTE++))
        else
            print_warning "Failed to delete remote branch: origin/$branch"
            ((SKIPPED++))
        fi
    fi
}

# Get remote merged branches
get_remote_merged_branches() {
    local main_branch="$1"
    git branch -r --merged "origin/$main_branch" | sed 's/origin\///' | sed 's/^\s*//' | grep -v "HEAD" | grep -v "^\s*$"
}

# Clean merged branches
clean_merged_branches() {
    local main_branch="$1"

    print_info "Finding branches merged into $main_branch..."

    local branches
    branches=$(get_merged_branches "$main_branch")

    if [[ -z "$branches" ]]; then
        print_info "No merged branches found"
        return
    fi

    echo ""
    print_info "Merged branches to clean:"
    echo "$branches" | while read -r branch; do
        echo "  - $branch"
    done
    echo ""

    if ! $FORCE && ! $DRY_RUN; then
        if ! confirm "Delete these merged branches?"; then
            print_info "Aborted"
            return
        fi
    fi

    echo "$branches" | while read -r branch; do
        delete_local_branch "$branch" "$main_branch"
    done

    # Clean remote merged branches
    if $CLEAN_REMOTE; then
        echo ""
        print_info "Finding remote branches merged into origin/$main_branch..."

        local remote_branches
        remote_branches=$(get_remote_merged_branches "$main_branch")

        if [[ -n "$remote_branches" ]]; then
            echo ""
            print_info "Remote merged branches to clean:"
            echo "$remote_branches" | while read -r branch; do
                echo "  - origin/$branch"
            done
            echo ""

            if ! $FORCE && ! $DRY_RUN; then
                if ! confirm "Delete these remote branches?"; then
                    print_info "Skipping remote cleanup"
                    return
                fi
            fi

            echo "$remote_branches" | while read -r branch; do
                delete_remote_branch "$branch" "$main_branch"
            done
        fi
    fi
}

# Clean stale branches
clean_stale_branches() {
    local main_branch="$1"

    print_info "Finding branches with no commits in the last $STALE_DAYS days..."

    local branches
    branches=$(get_stale_branches)

    if [[ -z "$branches" ]]; then
        print_info "No stale branches found"
        return
    fi

    echo ""
    print_info "Stale branches (no commits in $STALE_DAYS days):"
    echo "$branches" | while read -r branch; do
        local last_commit
        last_commit=$(git log -1 --format='%cr' "$branch" 2>/dev/null || echo "unknown")
        echo "  - $branch (last commit: $last_commit)"
    done
    echo ""

    if ! $FORCE && ! $DRY_RUN; then
        if ! confirm "Delete these stale branches?"; then
            print_info "Aborted"
            return
        fi
    fi

    echo "$branches" | while read -r branch; do
        delete_local_branch "$branch" "$main_branch"
    done
}

# Prune remote tracking branches
prune_remote() {
    print_info "Pruning stale remote-tracking branches..."

    if $DRY_RUN; then
        git remote prune origin --dry-run
    else
        git remote prune origin
        print_success "Pruned stale remote-tracking branches"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "========================================="
    echo "Summary:"
    echo "  Local branches deleted:  $DELETED_LOCAL"
    echo "  Remote branches deleted: $DELETED_REMOTE"
    echo "  Branches skipped:        $SKIPPED"

    if $DRY_RUN; then
        echo ""
        print_warning "This was a dry run. No branches were actually deleted."
        print_info "Run without --dry-run to delete branches."
    fi

    echo "========================================="
}

# Main function
main() {
    parse_args "$@"

    check_git_repo

    local main_branch
    main_branch=$(detect_main_branch)
    print_info "Using main branch: $main_branch"

    # Fetch latest from remote
    print_info "Fetching from origin..."
    git fetch --prune origin 2>/dev/null || print_warning "Could not fetch from origin"

    echo ""

    # Always prune remote tracking first
    prune_remote

    echo ""

    # Clean merged branches
    clean_merged_branches "$main_branch"

    # Clean stale branches if requested
    if $CLEAN_ALL; then
        echo ""
        clean_stale_branches "$main_branch"
    fi

    print_summary
}

main "$@"

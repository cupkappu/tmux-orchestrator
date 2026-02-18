#!/bin/bash
# Git worktree management for Tmux Orchestrator
# Source this after config.sh

WORKTREE_DIR=".worktrees"

# Create a worktree for an agent
# Usage: worktree_create <project-path> <agent-id> [base-branch]
# If base-branch provided, creates worktree from that branch
# Returns the worktree path
worktree_create() {
    local project="$1"
    local agent_id="$2"
    local base_branch="${3:-}"
    local branch="${agent_id}-$(date +%Y%m%d)"
    local wt_path="$project/$WORKTREE_DIR/$agent_id"

    # Ensure .worktrees is in .gitignore
    if [ -f "$project/.gitignore" ]; then
        if ! grep -qx "$WORKTREE_DIR/" "$project/.gitignore" 2>/dev/null; then
            echo "$WORKTREE_DIR/" >> "$project/.gitignore"
        fi
    else
        echo "$WORKTREE_DIR/" > "$project/.gitignore"
    fi

    # Create the worktree directory parent
    mkdir -p "$project/$WORKTREE_DIR"

    # Create worktree from base branch if provided, otherwise from HEAD
    if [ -n "$base_branch" ]; then
        git -C "$project" worktree add "$wt_path" -b "$branch" "$base_branch" 2>&1
    else
        git -C "$project" worktree add "$wt_path" -b "$branch" 2>&1
    fi
    echo "$wt_path"
}

# Create executor worktree from PL's worktree
# Usage: worktree_create_from_pl <project-path> <pl-worktree-path> <executor-id>
worktree_create_from_pl() {
    local project="$1"
    local pl_worktree="$2"
    local executor_id="$3"

    # Get PL's branch
    local pl_branch
    pl_branch=$(git -C "$pl_worktree" branch --show-current 2>/dev/null)

    # Create executor worktree from PL's branch
    worktree_create "$project" "$executor_id" "$pl_branch"
}

# List worktrees for a project
# Usage: worktree_list <project-path>
worktree_list() {
    git -C "$1" worktree list 2>/dev/null
}

# Remove a worktree
# Usage: worktree_remove <project-path> <executor-id>
worktree_remove() {
    local project="$1"
    local executor_id="$2"
    local wt_path="$project/$WORKTREE_DIR/$executor_id"

    if [ -d "$wt_path" ]; then
        git -C "$project" worktree remove "$wt_path" --force 2>&1
    fi
}

# Get the branch name of a worktree
# Usage: worktree_branch <worktree-path>
worktree_branch() {
    git -C "$1" branch --show-current 2>/dev/null
}

# Count commits ahead of main in a worktree
# Usage: worktree_commits_ahead <project-path> <branch>
worktree_commits_ahead() {
    local project="$1"
    local branch="$2"
    local main_branch
    main_branch=$(git -C "$project" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    [ -z "$main_branch" ] && main_branch="main"
    git -C "$project" rev-list --count "$main_branch..$branch" 2>/dev/null || echo "0"
}

# Get the main branch name
# Usage: get_main_branch <project-path>
get_main_branch() {
    local project="$1"
    local main_branch
    main_branch=$(git -C "$project" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [ -z "$main_branch" ]; then
        # Check if main or master exists
        if git -C "$project" show-ref --verify --quiet refs/heads/main 2>/dev/null; then
            main_branch="main"
        elif git -C "$project" show-ref --verify --quiet refs/heads/master 2>/dev/null; then
            main_branch="master"
        else
            main_branch="main"
        fi
    fi
    echo "$main_branch"
}

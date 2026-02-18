# CLAUDE.md - Tmux Orchestrator

## Project Overview

A CLI tool for orchestrating multiple AI agents across tmux sessions with git worktree isolation.

## Architecture

```
torc (main entry) → torc-* (subcommands)
lib/*.sh (shared functions)
skills/*/SKILL.md (Claude Code skills)
```

## Key Components

- **bin/torc** - Main dispatcher
- **bin/torc-deploy** - Create teams, worktrees, start agents
- **bin/torc-status** - Show team status
- **bin/torc-review** - Review executor commits
- **bin/torc-merge** - Merge to main
- **bin/torc-teardown** - Cleanup
- **lib/state.sh** - Team state management (~/.tmux-orchestrator/state/)
- **lib/worktree.sh** - Git worktree operations
- **lib/tmux.sh** - Tmux wrappers

## State Management

Team state stored in `~/.tmux-orchestrator/state/teams/<name>.json`:
```json
{
  "team_name": "my-app",
  "session": "torc-my-app",
  "agents": {
    "pl": {"window": "PL", "cli": "claude"},
    "executor-1": {"window": "Exec-1", "worktree": ".worktrees/executor-1", "branch": "..."}
  }
}
```

## Adding a New Command

1. Create `bin/torc-<name>` - make executable
2. Source lib/config.sh, lib/state.sh as needed
3. Update `torc` dispatcher if new top-level command
4. Optionally create skill in `skills/torc-<name>/SKILL.md`

## Testing

```bash
# Test locally without installing
./bin/torc --help
./bin/torc-deploy ~/test-project --spec ~/plan.md
```

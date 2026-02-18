# Tmux Orchestrator

A CLI tool for orchestrating multiple AI agents (Claude Code, Kimi CLI, OpenCode, etc.) across tmux sessions with git worktree isolation.

## Installation

```bash
# Clone or navigate to the repo
cd Tmux-Orchestrator

# Run installer
./install.sh

# Source your shell config
source ~/.zshrc  # or ~/.bashrc
```

This installs:
- `torc` command and subcommands
- Claude Code skills in `~/.claude/skills/`
- State directory in `~/.tmux-orchestrator/`

## Quick Start

```bash
# Deploy a team for a project (PL will decide executor count)
torc deploy ~/projects/my-app --spec ~/specs/feature.md

# Check team status
torc status my-app

# Send message to an agent
torc send torc-my-app:PL "What's the status?"

# Review executor work
torc review my-app

# Merge approved work to main
torc merge my-app executor-1

# Shut down when done
torc teardown my-app
```

## Architecture (Dynamic Creation)

```
Orchestrator (created first)
        ↓ creates
Project Leader (analyzes task)
        ↓ requests N executors
Executors (created on demand)
```

**Why PL decides executor count?**
- PL is the task expert, understands complexity
- Simple task → 1 executor, Complex task → 3-4 executors
- Supports Multi-PL: Frontend PL wants 2, Backend PL wants 3

**Workflow:**
1. `torc deploy` → Creates only Orchestrator
2. Orchestrator creates PL, sends task
3. PL analyzes → "I need 3 executors for HTML/CSS/JS"
4. Orchestrator creates 3 executors
5. Executors work → commit → PL merges → Orchestrator merges to main

## Commands

| Command | Description |
|---------|-------------|
| `torc deploy <path> [--spec file]` | Create team (PL decides executor count) |
| `torc status [team]` | Show team/agent status |
| `torc send <target> <message>` | Message an agent |
| `torc review [team]` | Review pending executor commits |
| `torc merge <team> <executor>` | Merge executor branch to main |
| `torc teardown <team>` | Stop agents, remove worktrees |
| `torc worktree create/list/remove` | Manage git worktrees |

## Claude Code Skills

After installation, use these in Claude Code:

- `/torc-deploy-team` - Deploy a team with options
- `/torc-team-status` - Check all teams
- `/torc-review-work` - Review and merge executor work
- `/torc-pm-oversight` - Run PL oversight loop
- `/torc-send-message` - Send messages to agents

## Configuration

Edit `orchestrator-config.json` to change CLI assignments:

```json
{
  "cli_tools": {
    "claude": { "name": "Claude Code", "start_command": "claude" },
    "kimi": { "name": "Kimi CLI", "start_command": "kimi" }
  },
  "roles": {
    "project_leader": { "cli": "claude" },
    "executor": { "cli": "kimi" }
  },
  "defaults": {
    "cli": "claude",
    "executors": 1
  }
}
```

## How It Works

1. **Deploy**: Creates tmux session, git worktrees for each executor, starts agents
2. **Work**: Executors commit to their branches; PL monitors via git log
3. **Review**: `torc review` shows commits ahead of main
4. **Merge**: `torc merge` brings executor work into main
5. **Teardown**: Kills session, removes worktrees, saves logs

## Directory Structure

```
Tmux-Orchestrator/
├── bin/              # torc commands
├── lib/              # shared shell functions
├── skills/           # Claude Code skills
├── templates/        # Agent briefing templates
└── orchestrator-config.json

~/.tmux-orchestrator/
├── state/teams/      # Team state JSON files
├── state/review-queue/
└── logs/             # Agent conversation logs
```

## Requirements

- tmux
- git
- Python 3 (for JSON parsing)
- At least one AI CLI tool (claude, kimi, opencode, etc.)

## Uninstall

```bash
./uninstall.sh
```

Removes skills, state directory, and PATH entry.

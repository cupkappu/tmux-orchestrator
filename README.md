# Tmux Orchestrator

AI agent team orchestration via tmux + git worktrees.

## Quick Start

```bash
# 1. Install
cd Tmux-Orchestrator && ./install.sh && source ~/.zshrc

# 2. Deploy (Orchestrator + PL will be created)
torc deploy ~/projects/my-project --spec ~/specs/feature.md

# 3. Watch
tmux attach -t torc-my-project
```

**That's it.** Orchestrator creates PL → PL requests executors → Executors build → PL merges → Done.

## Commands

| Command | Description |
|---------|-------------|
| `torc deploy <path>` | Create team, PL decides executor count |
| `torc status <team>` | Show team status |
| `torc send <target> <msg>` | Message an agent |
| `torc teardown <team>` | Stop all agents |

## Architecture

```
User → Orchestrator → PL → Executors (1-4)
                          ↓
                    Monitors progress
                    Merges work
```

- **Orchestrator**: Commander (Claude) - creates PL, monitors
- **PL**: Project Leader (Kimi) - plans work, requests executors, monitors via /torc-pm-oversight
- **Executor**: Worker (OpenCode) - does the implementation

## Configuration

Edit `orchestrator-config.json` to change CLI tools per role.

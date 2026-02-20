# Tmux Orchestrator

AI agent team orchestration via tmux + git worktrees.

## Two Modes

### Self-Organizing (`torc team`) — recommended

Lead generates tasks from spec, agents self-claim work, Lead approves plans.
Push notifications keep everyone in sync without polling.

```bash
# 1. Install
cd Tmux-Orchestrator && ./install.sh && source ~/.zshrc

# 2. Deploy (Lead + agents, kimi leads, opencode works)
torc team deploy ~/projects/my-app --spec ~/specs/feature.md \
  --lead-cli kimi --teammate-cli opencode --teammates 3

# 3. Watch live event stream
torc team monitor my-app

# 4. Check status
torc team status my-app
```

**Flow:** Lead reads spec → generates task list → spawns agents → agents self-claim tasks → submit plans → Lead approves → agents implement → done.

### Hierarchy (`torc deploy`) — classic

Orchestrator → PL → Executors. PL assigns tasks manually.

```bash
torc deploy ~/projects/my-app --spec ~/specs/feature.md
tmux attach -t torc-my-app
```

---

## Self-Organizing Commands

| Command | Who | Description |
|---------|-----|-------------|
| `torc team deploy <path> --spec <file>` | User | Deploy Lead + spawn agents |
| `torc team init <path> --spec <file>` | User | Create task list only |
| `torc team spawn <team> <n>` | Lead | Spawn N agents |
| `torc team status <team>` | Anyone | Show tasks + agents |
| `torc team monitor <team>` | User | Live event stream (tail -f) |
| `torc team claim <team> <agent>` | Agent | Claim next available task |
| `torc team plan-submit <team> <task> <plan>` | Agent | Submit plan for approval |
| `torc team approve <team> <task>` | Lead | Approve plan |
| `torc team reject <team> <task> <feedback>` | Lead | Reject with feedback |
| `torc team done <team> <task> [result]` | Agent | Mark task complete |
| `torc team inbox <team> <agent>` | Agent/Lead | Read pushed notifications |
| `torc team broadcast <team> <msg>` | Lead | Message all agents |

## Push Notification System

Every task action automatically pushes events — no polling needed.

```
Agent claims task   → Lead inbox: ⚡ [Agent-1] claimed T-001
Agent submits plan  → Lead inbox: 📋 [Agent-1] plan ready T-001 — APPROVE NOW
Lead approves       → Agent inbox: ✅ [lead] APPROVED T-001 — start work
Agent completes     → Lead inbox: ✓ [Agent-1] DONE T-001: ...
```

All events are written to `~/.tmux-orchestrator/tasks/<team>.events`.
Open a live view with `torc team monitor <team>`.

## Configuration

Edit `orchestrator-config.json` (or `~/.tmux-orchestrator/orchestrator-config.json`):

```json
{
  "cli_tools": {
    "claude":   { "start_command": "claude --dangerously-skip-permissions" },
    "kimi":     { "start_command": "kimi --yolo" },
    "opencode": { "start_command": "opencode" }
  }
}
```

## Skills

| Skill | Trigger |
|-------|---------|
| `/torc-start` | Conversational project setup — guides you through spec + deploy |
| `/torc-team-lead` | Lead role in self-organizing team |
| `/torc-team-agent` | Agent role in self-organizing team |
| `/torc-deploy-team` | Deploy a team (skill version) |
| `/torc-orchestrator` | Orchestrator in hierarchy mode |

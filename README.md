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

### Team Management

| Command | Who | Description |
|---------|-----|-------------|
| `torc team deploy <path> --spec <file>` | User | Deploy Lead + spawn agents |
| `torc team init <path> --name <name>` | User | Create team with empty task list |
| `torc team spawn-lead <team>` | User | Spawn Lead for existing team |
| `torc team spawn <team> <n>` | Lead | Spawn N agents |
| `torc team resume <team> [options]` | User | Resume team (recreate session) |
| `torc team shutdown <team>` | User | Graceful shutdown when all tasks done |
| `torc team status <team>` | Anyone | Show tasks + agents + progress |
| `torc team health <team>` | Anyone | Show health metrics & blockers |
| `torc team monitor <team>` | User | Live event stream (tail -f) |

### Agent Actions

| Command | Who | Description |
|---------|-----|-------------|
| `torc team claim <team> <agent>` | Agent | Claim next available task |
| `torc team plan-submit <team> <task> <plan>` | Agent | Submit plan for approval |
| `torc team done <team> <task> [result]` | Agent | Mark task complete |
| `torc team propose <team> <agent> <title> <desc>` | Agent | Propose new task |
| `torc team inbox <team> <agent>` | Agent | Read pushed notifications |

### Lead Actions

| Command | Who | Description |
|---------|-----|-------------|
| `torc team approve <team> <task>` | Lead | Approve submitted plan |
| `torc team reject <team> <task> <feedback>` | Lead | Reject plan with feedback |
| `torc team proposals <team>` | Lead | List pending proposals |
| `torc team approve-proposal <team> <id>` | Lead | Approve task proposal |
| `torc team reject-proposal <team> <id> [reason]` | Lead | Reject task proposal |
| `torc team broadcast <team> <msg>` | Lead | Message all agents |

### Communication

| Command | Who | Description |
|---------|-----|-------------|
| `torc team broadcast <team> <msg>` | Lead | Broadcast to all agents |
| `torc team msg <team> <from> <to> <msg>` | Anyone | Send direct message |

---

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

---

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

---

## Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `/torc-start` | `torc start` | Conversational project setup — guides you through spec + deploy |
| `/torc-team-lead` | Auto-loaded | Lead role in self-organizing team |
| `/torc-team-agent` | Auto-loaded | Agent role in self-organizing team |
| `/torc-team-status` | `torc status` | Check all teams across projects |
| `/torc-deploy-team` | `torc deploy` | Deploy a team (skill version) |
| `/torc-orchestrator` | `torc deploy` | Orchestrator in hierarchy mode |
| `/torc-pm-oversight` | Auto-loaded | PL oversight loop (hierarchy mode) |
| `/torc-review-work` | `torc review` | Review pending commits from executors |
| `/torc-send-message` | `torc send` | Send message to specific agent |

---

## Examples

```bash
# Deploy a self-organizing team
torc team deploy ~/projects/my-app --spec ~/specs/feature.md --teammates 3

# Check team progress
torc team status my-app

# Watch live events
torc team monitor my-app

# Session crashed? Resume with all agents
torc team resume my-app --spawn-lead --spawn-agents 3

# Graceful shutdown when work is done
torc team shutdown my-app
```

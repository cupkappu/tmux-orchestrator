---
name: torc-team-status
description: Show status of all active agent teams, worktrees, git status, and recent output
argument-hint: [team-name]
allowedTools: ["Bash", "Read"]
---

You are checking the status of active agent teams managed by the Tmux Orchestrator.

Parse the arguments:
- Team name (optional): if provided, show only that team; otherwise show all teams

## Workflow

1. **Call status command**:
   ```bash
   torc status [team-name]
   ```
2. **Parse and format output** - make it easy to read
3. **Highlight issues** - if any sessions are not running, agents are stuck, etc.
4. **Show actionable next steps** - what the user should check or do

## Output Format

For each team, show:
- Team name and session
- Each agent: role, CLI tool, window
- For executors: worktree path, branch name, commits ahead of main
- Recent output (last line from each agent)
- Pending review count

## Context Awareness

If you notice anything unusual in the status:
- Sessions that aren't running
- Agents with error messages in their last output
- Many pending reviews

Point these out to the user and suggest actions.

## Examples

```
/torc-team-status
/torc-team-status my-app
```

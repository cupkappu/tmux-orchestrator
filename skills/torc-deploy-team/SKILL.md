---
name: torc-deploy-team
description: Deploy a multi-agent team for a project with tmux session, git worktrees, and agent briefings (PL decides executor count)
argument-hint: <project-path> [--spec <spec-file>]
allowedTools: ["Bash", "Read"]
---

You are deploying a multi-agent team using the Tmux Orchestrator.

**Architecture: Dynamic Creation (B Architecture)**
- Only Orchestrator is created initially
- PL is created next, analyzes task, decides executor count
- Executors are created on demand based on PL's request

Parse the arguments:
- Project path (required): the first positional argument
- `--spec <file>`: optional spec/requirements file

## Workflow

1. **Validate arguments** - ensure project path exists and is a git repo
2. **Read spec file** (if provided) - understand what the team will work on
3. **Call deployment command**:
   ```bash
   torc deploy <project-path> --spec <spec-file>
   ```
4. **Display results** - show the session name, window layout, and next steps

## Output Format

After deployment, show:
- Team name and tmux session
- Current windows (initially just: Orchestrator)
- Expected flow: Orchestrator → PL → Executors (created dynamically)
- Suggested next steps (status checks, messaging)

## Examples

```
/torc-deploy-team ~/projects/my-app --spec ~/specs/feature.md
/torc-deploy-team /Users/kifuko/dev/some-project
```

**Note**: Executor count is determined by the PL after analyzing the task, not by you.

Keep the output concise and actionable. The user should immediately know how to interact with the deployed team.

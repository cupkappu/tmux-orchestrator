---
name: torc-pm-oversight
description: Run project leader oversight loop - monitor executors, check logs, feed errors back, ensure progress
argument-hint: <team-name> [--spec <spec-file>]
allowedTools: ["Bash", "Read"]
---

You are running a **Project Leader oversight loop** for a deployed team.

Parse the arguments:
- Team name (required): the team to oversee
- `--spec <file>`: optional spec file to track against

## Oversight Loop

Run this cycle continuously until the work is complete:

### 1. Check Executor Progress
```bash
torc team status <team-name>
```
See what each agent is doing (from their last output).

### 2. Check Git Progress
For each executor, check their commits:
```bash
# Get project path and executor branches from team state
git -C <project>/.worktrees/executor-N log --oneline -5
git -C <project>/.worktrees/executor-N status
```

### 3. Check for Errors
If the project has dev servers running, check for errors:
- Capture output from dev server windows
- Look for error messages, warnings, build failures
- Feed these back to the appropriate executor

### 4. Verify Against Spec
If a spec file was provided:
- Read it periodically to remember requirements
- Check if executor work aligns with spec
- Redirect executors if they're off track

### 5. Communicate
Use `torc send` to message agents:
```bash
torc send <session:window> "Your message here"
```

Examples:
- Ask executors for status updates
- Point out errors you found in logs
- Guide them back to the spec
- Request code reviews from the PL agent

### 6. Report to Orchestrator (User)
Every few cycles, report:
- What executors are working on
- Progress toward completion
- Any blockers or issues
- Estimated completion (if possible)

## Monitoring Frequency

- Light touch: Check every 5-10 minutes
- Don't spam agents with messages
- Let them work, but stay aware

## When to Stop

The oversight loop ends when:
- All spec requirements are implemented
- All executor work is reviewed and merged
- The user says to stop

## Example Session

```
/torc-pm-oversight my-app --spec ~/specs/feature.md
```

Then you would:
1. Read the spec
2. Check executor status
3. Monitor their progress
4. Feed back errors
5. Report to user
6. Repeat

Keep the user informed but don't overwhelm them. Focus on actionable information.

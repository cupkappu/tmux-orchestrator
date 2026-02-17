---
name: torc-review-work
description: Review pending commits from executor agents, show diffs, approve and merge to main
argument-hint: [team-name]
allowedTools: ["Bash", "Read"]
---

You are reviewing work from executor agents in their worktree branches.

Parse the arguments:
- Team name (optional): if provided, review only that team; otherwise review all teams

## Workflow

1. **Call review command**:
   ```bash
   torc review [team-name]
   ```
2. **Show the output** - commits, diffs, stats
3. **For each executor with pending work**:
   - Summarize what they did
   - Check if it looks reasonable
   - Ask user if they want to merge
4. **If user approves**, call:
   ```bash
   torc merge <team-name> <executor-id>
   ```

## Review Criteria

When reviewing executor work:
- Do commit messages make sense?
- Are the changes aligned with the spec?
- Any obvious red flags in the diff?

## Output Format

For each executor:
- Executor ID and branch
- Number of commits ahead
- Commit log (concise)
- Diff summary (files changed, insertions/deletions)

Then ask: "Do you want to merge any of these?"

## Examples

```
/torc-review-work
/torc-review-work my-app
```

## After Merging

Inform the user:
- Merge was successful
- The executor can continue working
- Their branch can be reset if they want a clean slate

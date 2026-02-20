# Feature: torc team stop

## Goal
Add `torc team stop <team>` command that gracefully signals all agents to exit
after finishing their current task (no kill -9, no work lost).

## Stop Protocol
Write a sentinel file: `~/.tmux-orchestrator/tasks/<team>.stop`
Agents check for this file after each claim attempt.
If the file exists, agent exits gracefully instead of retrying.

## Tasks

### T-001: Implement bin/torc-team-stop
- File to create: `bin/torc-team-stop`
- Write the sentinel file: `~/.tmux-orchestrator/tasks/<team>.stop`
- Broadcast a message to all active agents via torc-team-broadcast
- Message: "Stop signal sent. Finish your current task then exit."
- Print confirmation with: torc team status <team>
- Requires design plan before implementing (require_plan: true)

### T-002: Add stop check to torc-team-claim (blocked by T-001)
- File to modify: `bin/torc-team-claim`
- Before attempting a claim, check if `.stop` file exists
- If it exists: print "Stop signal received. Exiting." and exit 0
- This makes agents exit cleanly at their natural retry point
- Also update `lib/tasks.sh` tasks_claim to surface a clear exit code

### T-003: Wire stop into dispatcher (blocked by T-001)
- File to modify: `bin/torc-team`
- Add `stop` to the case statement routing to `torc-team-stop`
- Add stop to the usage/help text
- Make executable: chmod +x bin/torc-team-stop

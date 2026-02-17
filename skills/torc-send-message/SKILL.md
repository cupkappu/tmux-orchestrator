---
name: torc-send-message
description: Send a message to a specific agent in a tmux window
argument-hint: <session:window> <message>
allowedTools: ["Bash"]
---

You are sending a message to an agent in a tmux window.

Parse the arguments:
- Target (required): `<session:window>` or `<session:window.pane>`
- Message (required): the rest of the arguments as the message text

## Workflow

1. **Validate target** - ensure it has the format `session:window`
2. **Send the message**:
   ```bash
   torc send <session:window> "message text here"
   ```
3. **Confirm delivery** - let the user know the message was sent

## Output Format

```
Message sent to <session:window>:
  "<message text>"

The agent should see this in their tmux window.
```

## Examples

```
/torc-send-message torc-my-app:PL "What's your status?"
/torc-send-message glacier-backend:Exec-1 "There's a syntax error on line 42"
```

## Use Cases

- Ask agents for status updates
- Point out errors or issues
- Give new instructions
- Coordinate between agents

This skill is CLI-agnostic - it works with any AI CLI tool (Claude Code, Kimi CLI, OpenCode, etc.) running in the target window.

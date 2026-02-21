#!/bin/bash
# Push notification system for torc self-organizing teams
# Auto-sourced by lib/tasks.sh
#
# Provides:
#   notify_push <team> <from> <event> <task-id> <detail> <to>
#   notify_inbox_read_clear <team> <agent-id>
#
# Requires: team_field (from state.sh, loaded before tasks.sh)
# Storage:
#   ~/.tmux-orchestrator/tasks/<team>.events        — global event log
#   ~/.tmux-orchestrator/tasks/<team>-inbox-<id>.txt — per-agent inbox

# ── Path helpers ───────────────────────────────────────────────────────────────

_notify_events_file() { echo "$TORC_STATE_DIR/tasks/${1}.events"; }
_notify_inbox_file()  { echo "$TORC_STATE_DIR/tasks/${1}-inbox-${2}.txt"; }

# ── Internals ──────────────────────────────────────────────────────────────────

# Append one structured line to the team event log
notify_log_event() {
    local team="$1" from="$2" event="$3" detail="$4"
    local ts events_file
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    events_file="$(_notify_events_file "$team")"
    mkdir -p "$(dirname "$events_file")"
    printf "%-24s | %-12s | %-16s | %s\n" "$ts" "$from" "$event" "$detail" >> "$events_file"
}

# Write a message to an agent's inbox file
notify_inbox_write() {
    local team="$1" to="$2" from="$3" message="$4"
    local ts inbox
    ts=$(date -u +"%H:%MZ")
    inbox="$(_notify_inbox_file "$team" "$to")"
    mkdir -p "$(dirname "$inbox")"
    printf "[%s] %s: %s\n" "$ts" "$from" "$message" >> "$inbox"
}

# Show a non-blocking overlay notification in a tmux window
_notify_tmux_display() {
    local session="$1" window="$2" message="$3"
    tmux display-message -t "$session:$window" -- "$message" 2>/dev/null || true
}

# Resolve agent id → tmux window name
_notify_resolve_window() {
    local team="$1" agent="$2"
    case "$agent" in
        lead|Lead)  echo "Lead" ;;
        agent-*)    echo "Agent-${agent#agent-}" ;;
        Agent-*)    echo "$agent" ;;
        *)
            local w
            w=$(team_field "$team" "agents.$agent.window" 2>/dev/null)
            echo "${w:-}"
            ;;
    esac
}

# ── Public API ─────────────────────────────────────────────────────────────────

# notify_push <team> <from> <event> <task-id> <detail> <to>
#   <event>: claimed | plan_submitted | plan_approved | plan_rejected | done
#   <to>:    agent-id | "lead" | "all" | "" (log-only)
#
# Always writes to the event log.
# If <to> is set, also writes to the target inbox and sends tmux display-message.
notify_push() {
    local team="$1" from="$2" event="$3" task_id="$4" detail="$5" to="${6:-}"

    # 1. Always log
    notify_log_event "$team" "$from" "$event" "${task_id}: ${detail}" 2>/dev/null || true

    [ -z "$to" ] && return 0

    # 2. Get session
    local session
    session=$(team_field "$team" "session" 2>/dev/null)
    [ -z "$session" ] && return 0

    # 3. Build human-readable push message
    local push_msg
    case "$event" in
        claimed)           push_msg="⚡ [${from}] claimed ${task_id}" ;;
        plan_submitted)    push_msg="📋 [${from}] plan ready ${task_id} — APPROVE NOW" ;;
        plan_approved)     push_msg="✅ [lead] APPROVED ${task_id} — start work" ;;
        plan_rejected)     push_msg="❌ [lead] REJECTED ${task_id}: ${detail}" ;;
        done)              push_msg="✓ [${from}] DONE ${task_id}: ${detail}" ;;
        proposal_submitted) push_msg="📨 [${from}] proposed new task: ${detail} — REVIEW" ;;
        proposal_approved)  push_msg="✅ [lead] your proposal APPROVED as ${task_id}: ${detail}" ;;
        proposal_rejected)  push_msg="❌ [lead] your proposal REJECTED: ${detail}" ;;
        *)               push_msg="[${from}] ${event} ${task_id}: ${detail}" ;;
    esac

    # 4. Deliver to target(s)
    if [ "$to" = "all" ]; then
        local agents_json agent_ids
        agents_json=$(team_field "$team" "agents" 2>/dev/null)
        [ -z "$agents_json" ] && return 0
        agent_ids=$(python3 -c "
import json, sys
agents = json.loads(sys.argv[1])
for aid in agents: print(aid)
" "$agents_json" 2>/dev/null) || return 0
        while IFS= read -r aid; do
            [ -z "$aid" ] && continue
            local w
            w=$(_notify_resolve_window "$team" "$aid")
            [ -z "$w" ] && continue
            notify_inbox_write "$team" "$aid" "$from" "$push_msg" 2>/dev/null || true
            _notify_tmux_display "$session" "$w" "$push_msg" 2>/dev/null || true
        done <<< "$agent_ids"
    else
        local w
        w=$(_notify_resolve_window "$team" "$to")
        if [ -n "$w" ]; then
            notify_inbox_write "$team" "$to" "$from" "$push_msg" 2>/dev/null || true
            _notify_tmux_display "$session" "$w" "$push_msg" 2>/dev/null || true
        fi
    fi
}

# ── Inbox read/clear ───────────────────────────────────────────────────────────

# notify_inbox_read_clear <team> <agent-id>
# Prints any pending messages then clears the inbox. No-op if empty.
notify_inbox_read_clear() {
    local team="$1" agent="$2"
    local inbox
    inbox="$(_notify_inbox_file "$team" "$agent")"
    if [ -f "$inbox" ] && [ -s "$inbox" ]; then
        echo "=== Inbox for ${agent} ==="
        cat "$inbox"
        echo "==========================="
        : > "$inbox"
    fi
}

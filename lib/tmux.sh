#!/bin/bash
# Tmux operation helpers for Tmux Orchestrator
# Source this after config.sh

# Check if a tmux session exists
# Usage: tmux_session_exists <session-name>
tmux_session_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

# Create a new tmux session
# Usage: tmux_create_session <session-name> <working-dir>
tmux_create_session() {
    tmux new-session -d -s "$1" -c "$2"
}

# Create a new tmux window
# Usage: tmux_create_window <session:index> <window-name> <working-dir>
tmux_create_window() {
    tmux new-window -t "$1" -n "$2" -c "$3"
}

# Send a message to a tmux target (window or pane)
# Usage: tmux_send <target> <message>
tmux_send() {
    local target="$1"
    local message="$2"
    tmux send-keys -t "$target" "$message"
    sleep 0.5
    tmux send-keys -t "$target" Enter
}

# Capture pane output
# Usage: tmux_capture <target> [lines]
tmux_capture() {
    local target="$1"
    local lines="${2:-50}"
    tmux capture-pane -t "$target" -p | tail -"$lines"
}

# Kill a tmux session
# Usage: tmux_kill_session <session-name>
tmux_kill_session() {
    tmux kill-session -t "$1" 2>/dev/null
}

# List windows in a session
# Usage: tmux_list_windows <session-name>
tmux_list_windows() {
    tmux list-windows -t "$1" -F "#{window_index}: #{window_name}" 2>/dev/null
}

# Check if a window exists
# Usage: tmux_window_exists <session:window>
tmux_window_exists() {
    tmux has-session -t "$1" 2>/dev/null
}

# Get the current path of a tmux window
# Usage: tmux_window_path <session:window>
tmux_window_path() {
    tmux display-message -t "$1" -p '#{pane_current_path}' 2>/dev/null
}

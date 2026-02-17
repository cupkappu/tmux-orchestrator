#!/bin/bash
# State management helpers for Tmux Orchestrator
# Source this after config.sh

# Ensure state directories exist
ensure_state_dirs() {
    mkdir -p "$TORC_STATE_DIR/state/teams"
    mkdir -p "$TORC_STATE_DIR/state/review-queue"
    mkdir -p "$TORC_STATE_DIR/logs"
}

# Get the team state file path
# Usage: team_state_file <team-name>
team_state_file() {
    echo "$TORC_STATE_DIR/state/teams/${1}.json"
}

# Check if a team exists
# Usage: team_exists <team-name>
team_exists() {
    [ -f "$(team_state_file "$1")" ]
}

# Read a field from team state JSON
# Usage: team_field <team-name> <jq-expression>
team_field() {
    local file
    file="$(team_state_file "$1")"
    [ -f "$file" ] && python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
expr = '$2'.lstrip('.')
parts = expr.split('.')
val = data
for p in parts:
    if isinstance(val, dict):
        val = val.get(p)
    else:
        val = None
        break
if val is not None:
    print(val if isinstance(val, str) else json.dumps(val))
" 2>/dev/null
}

# Write team state JSON
# Usage: write_team_state <team-name> <json-string>
write_team_state() {
    ensure_state_dirs
    local file
    file="$(team_state_file "$1")"
    echo "$2" > "$file"
}

# List all active teams
# Usage: list_teams
list_teams() {
    ensure_state_dirs
    local dir="$TORC_STATE_DIR/state/teams"
    for f in "$dir"/*.json; do
        [ -f "$f" ] && basename "$f" .json
    done 2>/dev/null
}

# Remove team state
# Usage: remove_team_state <team-name>
remove_team_state() {
    local file
    file="$(team_state_file "$1")"
    [ -f "$file" ] && rm "$file"
}

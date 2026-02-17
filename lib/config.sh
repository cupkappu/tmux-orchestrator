#!/bin/bash
# Configuration loader for Tmux Orchestrator
# Source this file from other scripts: source "$(dirname "$0")/../lib/config.sh"

# Resolve paths
TORC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCHESTRATOR_CONFIG="${ORCHESTRATOR_CONFIG:-"$TORC_ROOT/orchestrator-config.json"}"
TORC_STATE_DIR="${TORC_STATE_DIR:-"$HOME/.tmux-orchestrator"}"

# Get the CLI start command for a given role
# Usage: get_cli_command <role>
# Falls back to "claude" if config is missing or role not found
get_cli_command() {
    local role="$1"
    local default_cli="claude"

    if [ ! -f "$ORCHESTRATOR_CONFIG" ]; then
        echo "$default_cli"
        return
    fi

    local result
    result=$(python3 -c "
import json, sys
try:
    with open('$ORCHESTRATOR_CONFIG') as f:
        config = json.load(f)
    role = '$role'
    default_cli = config.get('defaults', {}).get('cli', 'claude')
    cli_key = config.get('roles', {}).get(role, {}).get('cli', default_cli)
    command = config.get('cli_tools', {}).get(cli_key, {}).get('start_command', cli_key)
    print(command)
except Exception:
    print('claude')
" 2>/dev/null)

    echo "${result:-$default_cli}"
}

# List all available CLI tools
list_cli_tools() {
    if [ ! -f "$ORCHESTRATOR_CONFIG" ]; then
        echo "claude: Claude Code (claude)"
        return
    fi

    python3 -c "
import json
try:
    with open('$ORCHESTRATOR_CONFIG') as f:
        config = json.load(f)
    for key, val in config.get('cli_tools', {}).items():
        print(f'{key}: {val.get(\"name\", key)} ({val.get(\"start_command\", key)})')
except Exception:
    print('claude: Claude Code (claude)')
" 2>/dev/null
}

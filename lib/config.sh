#!/bin/bash
# Configuration loader for Tmux Orchestrator
# Source this file from other scripts: source "$(dirname "$0")/../lib/config.sh"

# Resolve paths
TORC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TORC_STATE_DIR="${TORC_STATE_DIR:-"$HOME/.tmux-orchestrator"}"
ORCHESTRATOR_CONFIG="${ORCHESTRATOR_CONFIG:-"$TORC_STATE_DIR/orchestrator-config.json"}"

# Project-level config filename
PROJECT_CONFIG_FILE="torc-config.json"

# Find project-level config
# Usage: find_project_config <project-path>
find_project_config() {
    local project_path="$1"
    local config_path="$project_path/$PROJECT_CONFIG_FILE"
    if [ -f "$config_path" ]; then
        echo "$config_path"
    else
        echo ""
    fi
}

# Get the CLI start command for a given role
# Usage: get_cli_command <role> [project-path]
# Falls back to "claude" if config is missing or role not found
# If project-path provided, checks for project-level config first
get_cli_command() {
    local role="$1"
    local project_path="${2:-}"
    local default_cli="claude"
    local config_file="$ORCHESTRATOR_CONFIG"

    # Check for project-level config
    if [ -n "$project_path" ]; then
        local project_config
        project_config=$(find_project_config "$project_path")
        [ -n "$project_config" ] && config_file="$project_config"
    fi

    if [ ! -f "$config_file" ]; then
        echo "$default_cli"
        return
    fi

    local result
    result=$(python3 -c "
import json, sys
try:
    with open('$config_file') as f:
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

# Get the start command for a named CLI tool (e.g. "kimi" → "kimi --yolo")
# Usage: get_cli_start_command <tool-name>
# Falls back to the tool name itself if not found in config
get_cli_start_command() {
    local tool_name="$1"
    if [ ! -f "$ORCHESTRATOR_CONFIG" ]; then
        echo "$tool_name"
        return
    fi
    local result
    result=$(python3 -c "
import json, sys
try:
    with open('$ORCHESTRATOR_CONFIG') as f:
        config = json.load(f)
    tool = sys.argv[1]
    print(config.get('cli_tools', {}).get(tool, {}).get('start_command', tool))
except Exception:
    print(sys.argv[1])
" "$tool_name" 2>/dev/null)
    echo "${result:-$tool_name}"
}

# Get the default CLI tool name for a self-organizing role
# Usage: get_selforg_default_cli <role>   # role: "lead" or "agent"
# Follows: modes.self-org.default_agents.<role> → roles.<role-name>.cli
# Returns the tool name (e.g., "kimi", "opencode")
# Falls back to TORC_ROOT/orchestrator-config.json if state config lacks modes section.
get_selforg_default_cli() {
    local role="$1"
    # Prefer state dir config; fall back to project root config
    local config_file="$ORCHESTRATOR_CONFIG"
    if [ ! -f "$config_file" ] || ! python3 -c "
import json, sys
with open('$config_file') as f: c = json.load(f)
sys.exit(0 if c.get('modes') else 1)
" 2>/dev/null; then
        config_file="$TORC_ROOT/orchestrator-config.json"
    fi
    if [ ! -f "$config_file" ]; then
        echo "claude"
        return
    fi
    local result
    result=$(python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        config = json.load(f)
    role = sys.argv[2]
    default_agents = config.get('modes', {}).get('self-org', {}).get('default_agents', {})
    role_name = default_agents.get(role, role)
    fallback = config.get('defaults', {}).get('cli', 'claude')
    cli_key = config.get('roles', {}).get(role_name, {}).get('cli', fallback)
    print(cli_key)
except Exception:
    print('claude')
" "$config_file" "$role" 2>/dev/null)
    echo "${result:-claude}"
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

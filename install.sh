#!/bin/bash
# Tmux Orchestrator installer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${TORC_STATE_DIR:-$HOME/.tmux-orchestrator}"
SKILLS_DIR="$HOME/.claude/skills"

echo "=== Tmux Orchestrator Installer ==="
echo ""

# 1. Create state directories
echo "Creating state directories..."
mkdir -p "$STATE_DIR/state/teams"
mkdir -p "$STATE_DIR/state/review-queue"
mkdir -p "$STATE_DIR/logs"
echo "  ✓ Created $STATE_DIR"

# 2. Symlink skills to Claude skills directory
echo ""
echo "Installing skills..."
mkdir -p "$SKILLS_DIR"

for skill in "$SCRIPT_DIR/skills"/*; do
    skill_name=$(basename "$skill")
    target="$SKILLS_DIR/$skill_name"

    if [ -L "$target" ] || [ -e "$target" ]; then
        echo "  Skill '$skill_name' already exists, skipping..."
    else
        ln -s "$skill" "$target"
        echo "  ✓ Installed $skill_name"
    fi
done

# 3. Make bin scripts executable
echo ""
echo "Making scripts executable..."
chmod +x "$SCRIPT_DIR"/bin/torc*
echo "  ✓ Scripts are executable"

# 4. Add to PATH (if not already there)
echo ""
echo "Adding to PATH..."

SHELL_RC=""
if [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    PATH_LINE="export PATH=\"$SCRIPT_DIR/bin:\$PATH\"  # Tmux Orchestrator"

    if grep -qF "# Tmux Orchestrator" "$SHELL_RC" 2>/dev/null; then
        echo "  Already in PATH ($SHELL_RC)"
    else
        echo "" >> "$SHELL_RC"
        echo "$PATH_LINE" >> "$SHELL_RC"
        echo "  ✓ Added to $SHELL_RC"
        echo ""
        echo "  Run: source $SHELL_RC"
        echo "  Or restart your shell to use 'torc' command"
    fi
else
    echo "  Could not detect shell RC file."
    echo "  Manually add to PATH: export PATH=\"$SCRIPT_DIR/bin:\$PATH\""
fi

# 5. Update orchestrator-config.json
echo ""
echo "Updating config..."
if [ -f "$SCRIPT_DIR/orchestrator-config.json" ]; then
    # Update config to include state_dir and simplified roles
    python3 - <<EOF
import json

config_path = "$SCRIPT_DIR/orchestrator-config.json"
with open(config_path) as f:
    config = json.load(f)

# Update defaults
config.setdefault('defaults', {})
config['defaults']['state_dir'] = "$STATE_DIR"

# Simplify roles (keep backward compatibility)
if 'project_manager' in config.get('roles', {}):
    config['roles']['project_leader'] = config['roles']['project_manager']

if 'developer' in config.get('roles', {}):
    config['roles']['executor'] = config['roles']['developer']

# Write back
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print("  ✓ Config updated")
EOF
fi

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Next steps:"
echo "  1. Source your shell config: source $SHELL_RC"
echo "  2. Try: torc --help"
echo "  3. Deploy a team: torc deploy /path/to/project"
echo ""
echo "Skills installed (use in Claude Code):"
echo "  /torc-deploy-team"
echo "  /torc-team-status"
echo "  /torc-review-work"
echo "  /torc-pm-oversight"
echo "  /torc-send-message"
echo ""

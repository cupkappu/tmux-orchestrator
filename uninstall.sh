#!/bin/bash
# Tmux Orchestrator uninstaller
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${TORC_STATE_DIR:-$HOME/.tmux-orchestrator}"
SKILLS_DIR="$HOME/.claude/skills"

echo "=== Tmux Orchestrator Uninstaller ==="
echo ""
echo "This will:"
echo "  - Remove skills from ~/.claude/skills/"
echo "  - Remove state directory (teams, logs)"
echo "  - Remove PATH entry from shell RC"
echo ""
echo "WARNING: This will delete all team state and logs!"
echo ""
read -p "Continue? [y/N] " -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# 1. Remove skills
echo "Removing skills..."
for skill in "$SCRIPT_DIR/skills"/*; do
    skill_name=$(basename "$skill")
    target="$SKILLS_DIR/$skill_name"

    if [ -L "$target" ]; then
        rm "$target"
        echo "  ✓ Removed $skill_name"
    fi
done

# 2. Remove state directory
if [ -d "$STATE_DIR" ]; then
    echo ""
    echo "Removing state directory..."
    rm -rf "$STATE_DIR"
    echo "  ✓ Removed $STATE_DIR"
fi

# 3. Remove from PATH
echo ""
echo "Removing from PATH..."

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ]; then
        if grep -qF "# Tmux Orchestrator" "$rc" 2>/dev/null; then
            # Remove the line
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/# Tmux Orchestrator/d' "$rc"
            else
                sed -i '/# Tmux Orchestrator/d' "$rc"
            fi
            echo "  ✓ Removed from $rc"
        fi
    fi
done

echo ""
echo "=== Uninstall Complete! ==="
echo ""
echo "The 'torc' command will no longer work after restarting your shell."
echo ""

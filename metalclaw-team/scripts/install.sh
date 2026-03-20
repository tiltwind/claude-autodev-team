#!/bin/bash
# Install all MetalClaw skills from metalclaw-team/skills/ directory
# Usage: bash metalclaw-team/scripts/install.sh [target_settings_file]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEAM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC_DIR="$TEAM_DIR/skills"
SUB_AGENTS_DIR="$TEAM_DIR/metalclaw-sub-agents"

# Default target: user's global Claude settings
CLAUDE_DIR="${HOME}/.claude"
TARGET_SETTINGS="${1:-${CLAUDE_DIR}/settings.json}"

echo "=== MetalClaw Skills Installer ==="
echo "Source: $SKILLS_SRC_DIR"
echo "Sub-agents: $SUB_AGENTS_DIR"
echo "Target settings: $TARGET_SETTINGS"
echo ""

# Ensure target directory exists
mkdir -p "$(dirname "$TARGET_SETTINGS")"

# Initialize settings file if it doesn't exist
if [ ! -f "$TARGET_SETTINGS" ]; then
  echo '{}' > "$TARGET_SETTINGS"
fi

# Collect all skills (directories containing SKILL.md)
SKILLS=()
for skill_dir in "$SKILLS_SRC_DIR"/*/; do
  if [ -f "${skill_dir}SKILL.md" ]; then
    skill_name=$(basename "$skill_dir")
    SKILLS+=("$skill_name")
    echo "Found skill: $skill_name"
  fi
done

if [ ${#SKILLS[@]} -eq 0 ]; then
  echo "No skills found in $SKILLS_SRC_DIR"
  exit 0
fi

echo ""

# Link metalclaw-sub-agents into each skill directory
echo "Linking metalclaw-sub-agents..."
for skill_name in "${SKILLS[@]}"; do
  skill_path="$SKILLS_SRC_DIR/$skill_name"
  link_path="$skill_path/metalclaw-sub-agents"
  if [ -L "$link_path" ]; then
    rm "$link_path"
  fi
  if [ -d "$SUB_AGENTS_DIR" ]; then
    ln -s "$SUB_AGENTS_DIR" "$link_path"
    echo "  Linked: $skill_name/metalclaw-sub-agents -> $SUB_AGENTS_DIR"
  fi
done

echo ""
echo "Installing ${#SKILLS[@]} skill(s)..."

# Install each skill by adding to settings.json
for skill_name in "${SKILLS[@]}"; do
  skill_path="$SKILLS_SRC_DIR/$skill_name"

  if command -v python3 &> /dev/null; then
    python3 -c "
import json

settings_file = '$TARGET_SETTINGS'
skill_name = '$skill_name'
skill_path = '$skill_path'

with open(settings_file, 'r') as f:
    settings = json.load(f)

if 'skills' not in settings:
    settings['skills'] = {}

settings['skills'][skill_name] = {
    'path': skill_path
}

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)

print(f'  Installed: {skill_name} -> {skill_path}')
"
  elif command -v jq &> /dev/null; then
    tmp=$(mktemp)
    jq --arg name "$skill_name" --arg path "$skill_path" \
      '.skills[$name] = {"path": $path}' \
      "$TARGET_SETTINGS" > "$tmp" && mv "$tmp" "$TARGET_SETTINGS"
    echo "  Installed: $skill_name -> $skill_path"
  else
    echo "Error: python3 or jq is required to update settings.json"
    exit 1
  fi
done

echo ""
echo "=== Installation complete ==="
echo "Skills installed to: $TARGET_SETTINGS"
echo "You can now use these skills in Claude Code."

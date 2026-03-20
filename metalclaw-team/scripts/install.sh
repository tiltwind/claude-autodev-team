#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_REPO="https://github.com/tiltwind/claude-autodev-team.git"
TEMPLATE_DIR="$HOME/.claude/claude-autodev-team"
TEAM_DIR="$TEMPLATE_DIR/metalclaw-team"
SKILLS_DIR="$TEAM_DIR/skills"

# Target: current project's .claude/settings.local.json
if [ $# -ge 1 ]; then
  PROJECT_DIR="$1"
else
  PROJECT_DIR="$(pwd)"
  read -r -p "Install into $PROJECT_DIR? [Y/n] " answer </dev/tty
  if [[ "$answer" =~ ^[Nn] ]]; then
    echo "Aborted."
    exit 0
  fi
fi

TARGET_SETTINGS="$PROJECT_DIR/.claude/settings.local.json"

echo "=== MetalClaw Skills Installer ==="

# 1. Clone or update template
if [ -d "$TEMPLATE_DIR/.git" ]; then
  echo "Updating template in $TEMPLATE_DIR..."
  git -C "$TEMPLATE_DIR" pull --ff-only
else
  echo "Cloning template to $TEMPLATE_DIR..."
  mkdir -p "$(dirname "$TEMPLATE_DIR")"
  git clone "$TEMPLATE_REPO" "$TEMPLATE_DIR"
fi

echo ""
echo "Target settings: $TARGET_SETTINGS"

# Ensure target directory and settings file exist
mkdir -p "$(dirname "$TARGET_SETTINGS")"
if [ ! -f "$TARGET_SETTINGS" ]; then
  echo '{}' > "$TARGET_SETTINGS"
fi

# 2. Register all skills in settings.local.json
echo ""
echo "Installing skills..."

SKILL_COUNT=0
for skill_dir in "$SKILLS_DIR"/*/; do
  [ -f "${skill_dir}SKILL.md" ] || continue
  skill_name=$(basename "$skill_dir")
  skill_path="$SKILLS_DIR/$skill_name"

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
  SKILL_COUNT=$((SKILL_COUNT + 1))
done

echo ""
echo "=== Installation complete ==="
echo "$SKILL_COUNT skill(s) installed to: $TARGET_SETTINGS"
echo "You can now use these skills in Claude Code."

#!/usr/bin/env bash
set -euo pipefail

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

TEMPLATE_REPO="https://github.com/tiltwind/claude-autodev-team.git"
TEMPLATE_DIR="$HOME/.claude/claude-autodev-team"
TEAM_DIR="$TEMPLATE_DIR/sdd"
SKILLS_DIR="$TEAM_DIR/skills"

echo "=== SDD Skills Installer ==="

# 1. Clone or update template
if [ -d "$TEMPLATE_DIR/.git" ]; then
  echo "Updating template in $TEMPLATE_DIR..."
  git -C "$TEMPLATE_DIR" pull --ff-only
else
  echo "Cloning template to $TEMPLATE_DIR..."
  mkdir -p "$(dirname "$TEMPLATE_DIR")"
  git clone "$TEMPLATE_REPO" "$TEMPLATE_DIR"
fi

# 2. Link all skills into project's .claude/skills/
echo ""
echo "Installing skills..."

SKILL_COUNT=0
for skill_dir in "$SKILLS_DIR"/*/; do
  [ -f "${skill_dir}SKILL.md" ] || continue
  skill_name=$(basename "$skill_dir")
  src_dir="$SKILLS_DIR/$skill_name"
  dest_dir="$PROJECT_DIR/.claude/skills/$skill_name"

  if [ -e "$dest_dir" ] && [ ! -L "$dest_dir" ]; then
    echo "  Warning: $dest_dir exists and is not a symlink, skipping"
    continue
  fi

  mkdir -p "$PROJECT_DIR/.claude/skills"
  ln -sfn "$src_dir" "$dest_dir"
  echo "  Linked: $dest_dir -> $src_dir"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done

echo ""
echo "=== Installation complete ==="
echo "$SKILL_COUNT skill(s) installed into $PROJECT_DIR/.claude/skills/"
echo "You can now use these skills in Claude Code."

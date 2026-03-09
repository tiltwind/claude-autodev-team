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
ORCH_DIR="$TEMPLATE_DIR/skill-orchestrate"

# 1. Clone or update template
if [ -d "$TEMPLATE_DIR/.git" ]; then
  echo "Updating template in $TEMPLATE_DIR..."
  git -C "$TEMPLATE_DIR" pull --ff-only
else
  echo "Cloning template to $TEMPLATE_DIR..."
  mkdir -p "$(dirname "$TEMPLATE_DIR")"
  git clone "$TEMPLATE_REPO" "$TEMPLATE_DIR"
fi

# 2. Link skill directory
src_dir="$ORCH_DIR/skills/autodev"
dest_dir="$PROJECT_DIR/.claude/skills/autodev"
if [ -d "$src_dir" ]; then
  if [ -e "$dest_dir" ] && [ ! -L "$dest_dir" ]; then
    echo "Warning: $dest_dir exists and is not a symlink, skipping"
  else
    mkdir -p "$PROJECT_DIR/.claude/skills"
    ln -sfn "$src_dir" "$dest_dir"
    echo "  Linked: $dest_dir -> $src_dir"
  fi
fi

# 3. Link scripts
if [ -d "$ORCH_DIR/scripts" ]; then
  mkdir -p "$PROJECT_DIR/.claude/scripts"
  for script in autodev.sh; do
    src="$ORCH_DIR/scripts/$script"
    [ -f "$src" ] || continue
    target="$PROJECT_DIR/.claude/scripts/$script"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "Warning: $target exists and is not a symlink, skipping"
      continue
    fi
    ln -sfn "$src" "$target"
    echo "  Linked: $target -> $src"
  done
fi

# 4. Copy settings.local.json
if [ -f "$ORCH_DIR/settings.local.json" ]; then
  target="$PROJECT_DIR/.claude/settings.local.json"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Warning: $target exists and is not a symlink, skipping"
  else
    mkdir -p "$PROJECT_DIR/.claude"
    cp "$ORCH_DIR/settings.local.json" "$target"
    echo "  Copied: $ORCH_DIR/settings.local.json -> $target"
  fi
fi

# 5. Create autodev directory
mkdir -p "$PROJECT_DIR/.autodev"

echo "Done. Skill installed into $PROJECT_DIR/.claude/"

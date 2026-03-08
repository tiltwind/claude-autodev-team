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
ORCH_DIR="$TEMPLATE_DIR/orchestrate"

# 1. Clone or update template
if [ -d "$TEMPLATE_DIR/.git" ]; then
  echo "Updating template in $TEMPLATE_DIR..."
  git -C "$TEMPLATE_DIR" pull --ff-only
else
  echo "Cloning template to $TEMPLATE_DIR..."
  mkdir -p "$(dirname "$TEMPLATE_DIR")"
  git clone "$TEMPLATE_REPO" "$TEMPLATE_DIR"
fi

# 2. Link agent files
src_dir="$ORCH_DIR/agents"
dest_dir="$PROJECT_DIR/.claude/agents"
if [ -d "$src_dir" ]; then
  mkdir -p "$dest_dir"
  for file in "$src_dir"/*.md; do
    [ -f "$file" ] || continue
    target="$dest_dir/$(basename "$file")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "Warning: $target exists and is not a symlink, skipping"
      continue
    fi
    ln -sfn "$file" "$target"
  done
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
  done
fi

# 4. Link settings.local.json
if [ -f "$ORCH_DIR/settings.local.json" ]; then
  target="$PROJECT_DIR/.claude/settings.local.json"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Warning: $target exists and is not a symlink, skipping"
  else
    mkdir -p "$PROJECT_DIR/.claude"
    ln -sfn "$ORCH_DIR/settings.local.json" "$target"
  fi
fi

# 5. Create autodev directory
mkdir -p "$PROJECT_DIR/.claude/autodev"

echo "Done. Template linked into $PROJECT_DIR/.claude/"

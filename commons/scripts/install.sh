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
COMMONS_DIR="$TEMPLATE_DIR/commons"

# 1. Clone or update template
if [ -d "$TEMPLATE_DIR/.git" ]; then
  echo "Updating template in $TEMPLATE_DIR..."
  git -C "$TEMPLATE_DIR" pull --ff-only
else
  echo "Cloning template to $TEMPLATE_DIR..."
  mkdir -p "$(dirname "$TEMPLATE_DIR")"
  git clone "$TEMPLATE_REPO" "$TEMPLATE_DIR"
fi

# 2. Link command files
src_dir="$COMMONS_DIR/commands"
dest_dir="$PROJECT_DIR/.claude/commands"
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
    echo "  Linked: $target -> $file"
  done
fi

# 3. Link skill files
src_dir="$COMMONS_DIR/skills"
dest_dir="$PROJECT_DIR/.claude/skills"
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
    echo "  Linked: $target -> $file"
  done
  # Also link skill subdirectories
  for dir in "$src_dir"/*/; do
    [ -d "$dir" ] || continue
    dirname="$(basename "$dir")"
    target="$dest_dir/$dirname"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "Warning: $target exists and is not a symlink, skipping"
      continue
    fi
    ln -sfn "$dir" "$target"
    echo "  Linked: $target -> $dir"
  done
fi

echo "Done. Commons commands and skills linked into $PROJECT_DIR/.claude/"

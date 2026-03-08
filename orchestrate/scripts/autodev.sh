#!/usr/bin/env bash
# autodev.sh - Launch the orchestrator agent for multi-agent development
#
# Usage:
#   bash .claude/scripts/autodev.sh "requirement description"
#   bash .claude/scripts/autodev.sh --resume
#
# Uses Claude Code's native agent system with subagents instead of hooks.
set -euo pipefail

log() {
  echo ""
  echo "========================================"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [autodev] $1"
  echo "========================================"
}

# --- Parse Arguments ---
RESUME=false
REQUIREMENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resume)
      RESUME=true
      shift
      ;;
    *)
      REQUIREMENT="$*"
      break
      ;;
  esac
done

# --- Setup ---
if [ "$RESUME" = true ]; then
  ACTIVE_FILE=".claude/autodev/ACTIVE"
  if [ ! -f "$ACTIVE_FILE" ]; then
    echo "Error: No active session found" >&2
    exit 1
  fi
  AUTODEV_DIR="$(cat "$ACTIVE_FILE")"
  log "Resuming: ${AUTODEV_DIR}"
else
  if [ -z "$REQUIREMENT" ]; then
    echo "Usage: autodev.sh <requirement description>" >&2
    echo "       autodev.sh --resume" >&2
    exit 1
  fi
  DATE=$(date +%Y-%m-%d)
  SHORT_NAME=$(echo "$REQUIREMENT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g;s/--*/-/g;s/^-//;s/-$//' | cut -c1-40)
  AUTODEV_DIR=".claude/autodev/${DATE}-${SHORT_NAME}"
  mkdir -p "$AUTODEV_DIR"
  echo "$REQUIREMENT" > "${AUTODEV_DIR}/0-requirement-raw.md"
  mkdir -p .claude/autodev
  echo "$AUTODEV_DIR" > .claude/autodev/ACTIVE
  log "Created session: ${AUTODEV_DIR}"
fi

# --- Launch orchestrator ---
log "Launching orchestrator agent"

PROMPT="Run the autodev pipeline.

## Session Context

- Autodev directory: ${AUTODEV_DIR}
- Raw requirement: $(cat "${AUTODEV_DIR}/0-requirement-raw.md")
"

claude --agent orchestrator -p "$PROMPT" --verbose 2>&1 | tee "${AUTODEV_DIR}/orchestrator.log"

log "Orchestrator finished"

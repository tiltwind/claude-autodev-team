#!/usr/bin/env bash
# autodev-hook.sh - Stop hook entry point for chaining autodev agents
#
# Called by Claude Code's Stop hook after each agent completes.
# Delegates to autodev-pipeline.sh in background to avoid blocking the session.
#
# Flow: analyst -> designer -> expert -> developer -> reviewer -> tester
#       If tester fails: -> developer -> reviewer -> tester (loop, max 3 times)
#       If tester passes: -> done
set -euo pipefail

ACTIVE_FILE=".claude/autodev/ACTIVE"

# Exit silently if no active autodev session
[ -f "$ACTIVE_FILE" ] || exit 0

AUTODEV_DIR="$(cat "$ACTIVE_FILE")"
[ -d "$AUTODEV_DIR" ] || exit 0

STATE_FILE="${AUTODEV_DIR}/STATE"
[ -f "$STATE_FILE" ] || exit 0

CURRENT_STATE="$(cat "$STATE_FILE")"

# Only trigger for known autodev states (not done/unknown)
case "$CURRENT_STATE" in
  analyst|designer|expert|developer|reviewer|tester)
    ;;
  *)
    exit 0
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIPELINE="${SCRIPT_DIR}/autodev-pipeline.sh"

if [ ! -f "$PIPELINE" ]; then
  echo "[autodev] Error: Pipeline script not found: ${PIPELINE}" >&2
  exit 1
fi

# Run the pipeline in background so the Stop hook doesn't block the session
nohup bash "$PIPELINE" >> "${AUTODEV_DIR}/pipeline.log" 2>&1 &
echo "[autodev] Pipeline triggered in background (PID: $!). Logs: ${AUTODEV_DIR}/pipeline.log"

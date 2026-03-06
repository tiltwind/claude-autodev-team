#!/usr/bin/env bash
# autodev.sh - Multi-agent development workflow orchestrator
#
# Usage:
#   bash .claude/scripts/autodev.sh "requirement description"
#   bash .claude/scripts/autodev.sh --resume
#
# Orchestrates: analyst -> designer -> expert -> developer -> reviewer -> tester
# If tester fails: developer -> reviewer -> tester (loop, max 3 times)
set -euo pipefail

MAX_FIX_ITERATIONS=3
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Find agents directory
for candidate in "${SCRIPT_DIR}/../agents" ".claude/agents"; do
  if [ -d "$candidate" ]; then
    AGENTS_DIR="$(cd "$candidate" && pwd)"
    break
  fi
done
if [ -z "${AGENTS_DIR:-}" ]; then
  echo "Error: Cannot find agents directory" >&2
  exit 1
fi

log() { echo ""; echo "========================================"; echo "[autodev] $1"; echo "========================================"; }

run_agent() {
  local agent="$1"
  log "Starting agent: ${agent}"
  echo "$agent" > "${AUTODEV_DIR}/STATE"

  # Build prompt: agent role + session context + raw requirement
  local prompt
  prompt="$(cat "${AGENTS_DIR}/${agent}.md")"
  prompt="${prompt}

---

## Autodev Session Context

- Session directory: ${AUTODEV_DIR}
- Current agent: ${agent}

## Raw Requirement

$(cat "${AUTODEV_DIR}/0-requirement-raw.md")
"

  claude -p "$prompt" --verbose 2>&1 | tee "${AUTODEV_DIR}/log-${agent}.txt"
  log "Agent ${agent} completed"
}

has_unfixed_errors() {
  for f in "${AUTODEV_DIR}"/integrations-error-*.md; do
    [ -f "$f" ] || continue
    case "$f" in *-DONE.md) continue ;; esac
    return 0
  done
  return 1
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

# --- Determine Start Phase ---
START_PHASE="analyst"
if [ -f "${AUTODEV_DIR}/STATE" ]; then
  case "$(cat "${AUTODEV_DIR}/STATE")" in
    analyst)   START_PHASE="designer" ;;
    designer)  START_PHASE="expert" ;;
    expert)    START_PHASE="developer" ;;
    developer) START_PHASE="reviewer" ;;
    reviewer)  START_PHASE="tester" ;;
    tester)    START_PHASE="developer" ;;  # retry loop
    done)      log "Already completed"; exit 0 ;;
    *)         START_PHASE="analyst" ;;
  esac
  log "Starting from phase: ${START_PHASE}"
fi

# --- Pipeline ---
phases=(analyst designer expert)
for phase in "${phases[@]}"; do
  [[ "$START_PHASE" > "$phase" ]] && continue  # skip completed phases
  [[ "$START_PHASE" = "$phase" ]] || continue
  run_agent "$phase"
  # Advance start phase
  case "$phase" in
    analyst)  START_PHASE="designer" ;;
    designer) START_PHASE="expert" ;;
    expert)   START_PHASE="developer" ;;
  esac
done

# Dev-test loop
iteration=0
current="$START_PHASE"
while true; do
  if [ "$current" = "developer" ]; then
    iteration=$((iteration + 1))
    if [ "$iteration" -gt "$MAX_FIX_ITERATIONS" ]; then
      log "ERROR: Max fix iterations ($MAX_FIX_ITERATIONS) reached"
      echo "max-retries-exceeded" > "${AUTODEV_DIR}/STATE"
      exit 1
    fi
    [ "$iteration" -gt 1 ] && log "Fix iteration ${iteration}/${MAX_FIX_ITERATIONS}"
    run_agent "developer"
    current="reviewer"
  fi

  if [ "$current" = "reviewer" ]; then
    run_agent "reviewer"
    current="tester"
  fi

  if [ "$current" = "tester" ]; then
    run_agent "tester"
    if has_unfixed_errors; then
      log "Tests failed. Looping back to developer..."
      current="developer"
      continue
    fi
    log "All tests passed! Workflow complete."
    echo "done" > "${AUTODEV_DIR}/STATE"
    rm -f .claude/autodev/ACTIVE
    exit 0
  fi

  # Safety: shouldn't reach here
  break
done

#!/usr/bin/env bash
# autodev-pipeline.sh - Runs the autodev agent pipeline
#
# Reads STATE from the active autodev session and chains agents sequentially.
# Each agent runs via `claude -p` (non-interactive, no hooks = no recursion).
set -euo pipefail

ACTIVE_FILE=".claude/autodev/ACTIVE"
[ -f "$ACTIVE_FILE" ] || exit 0

AUTODEV_DIR="$(cat "$ACTIVE_FILE")"
[ -d "$AUTODEV_DIR" ] || exit 0

STATE_FILE="${AUTODEV_DIR}/STATE"
[ -f "$STATE_FILE" ] || exit 0

MAX_FIX_ITERATIONS=3

# Find agents directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for candidate in "${SCRIPT_DIR}/../agents" ".claude/agents"; do
  if [ -d "$candidate" ]; then
    AGENTS_DIR="$(cd "$candidate" && pwd)"
    break
  fi
done
if [ -z "${AGENTS_DIR:-}" ]; then
  echo "[autodev] Error: Cannot find agents directory" >&2
  exit 1
fi

log() {
  echo ""
  echo "========================================"
  echo "[autodev] $1"
  echo "========================================"
}

run_agent() {
  local agent="$1"
  local prompt_file="${AGENTS_DIR}/${agent}.md"

  if [ ! -f "$prompt_file" ]; then
    echo "[autodev] Error: Agent prompt not found: ${prompt_file}" >&2
    exit 1
  fi

  log "Starting agent: ${agent}"
  echo "$agent" > "$STATE_FILE"

  # Build prompt: agent role + session context + raw requirement
  local prompt
  prompt="$(cat "$prompt_file")"
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

# --- Determine next agent from current state ---
CURRENT_STATE="$(cat "$STATE_FILE")"

# Map current state to the sequence of remaining agents
case "$CURRENT_STATE" in
  analyst)   REMAINING=(designer expert developer reviewer tester) ;;
  designer)  REMAINING=(expert developer reviewer tester) ;;
  expert)    REMAINING=(developer reviewer tester) ;;
  developer) REMAINING=(reviewer tester) ;;
  reviewer)  REMAINING=(tester) ;;
  tester)    REMAINING=(developer reviewer tester) ;;  # retry loop
  *)         exit 0 ;;
esac

# --- Run the linear phases (designer, expert) ---
for agent in "${REMAINING[@]}"; do
  case "$agent" in
    designer|expert)
      run_agent "$agent"
      ;;
    developer)
      # Enter the dev-test loop
      break
      ;;
    reviewer)
      # Shouldn't happen in isolation, but handle it
      run_agent "$agent"
      ;;
    tester)
      break
      ;;
  esac
done

# --- Dev-test loop ---
iteration=0
# Determine if we should start in the loop
should_loop=false
for agent in "${REMAINING[@]}"; do
  case "$agent" in developer|reviewer|tester) should_loop=true; break ;; esac
done

if [ "$should_loop" = true ]; then
  # Determine starting point in the loop
  loop_start="developer"
  for agent in "${REMAINING[@]}"; do
    case "$agent" in developer|reviewer|tester) loop_start="$agent"; break ;; esac
  done

  while true; do
    # Developer
    if [ "$loop_start" = "developer" ]; then
      iteration=$((iteration + 1))
      if [ "$iteration" -gt "$MAX_FIX_ITERATIONS" ]; then
        log "ERROR: Max fix iterations ($MAX_FIX_ITERATIONS) reached. Manual intervention needed."
        echo "max-retries-exceeded" > "$STATE_FILE"
        rm -f "$ACTIVE_FILE"
        exit 1
      fi
      [ "$iteration" -gt 1 ] && log "Fix iteration ${iteration}/${MAX_FIX_ITERATIONS}"
      run_agent "developer"
    fi

    # Reviewer
    if [ "$loop_start" = "developer" ] || [ "$loop_start" = "reviewer" ]; then
      run_agent "reviewer"
    fi

    # Tester
    run_agent "tester"

    # Check results
    if has_unfixed_errors; then
      log "Integration tests failed. Looping back to developer..."
      loop_start="developer"
      continue
    fi

    # All passed
    log "All tests passed! Workflow complete."
    echo "done" > "$STATE_FILE"
    rm -f "$ACTIVE_FILE"
    exit 0
  done
fi

log "Pipeline finished."

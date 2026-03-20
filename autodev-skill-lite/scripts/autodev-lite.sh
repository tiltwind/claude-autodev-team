#!/usr/bin/env bash
# autodev-lite.sh - Launch the lite orchestrator skill for multi-agent development
#
# Usage:
#   bash .claude/scripts/autodev-lite.sh "requirement description"
#   bash .claude/scripts/autodev-lite.sh --resume
#
# Uses Claude Code's skill system with subagents.
set -euo pipefail

log() {
  echo ""
  echo "========================================"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [autodev-lite] $1"
  echo "========================================"
}

REQUIREMENT=$1

claude -p "/autodev-lite $REQUIREMENT" --verbose

log "Orchestrator finished"

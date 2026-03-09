#!/usr/bin/env bash
# autodev.sh - Launch the orchestrator skill for multi-agent development
#
# Usage:
#   bash .claude/scripts/autodev.sh "requirement description"
#   bash .claude/scripts/autodev.sh --resume
#
# Uses Claude Code's skill system with subagents.
set -euo pipefail

log() {
  echo ""
  echo "========================================"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [autodev] $1"
  echo "========================================"
}

REQUIREMENT=$1

claude -p "/autodev $REQUIREMENT" --verbose

log "Orchestrator finished"

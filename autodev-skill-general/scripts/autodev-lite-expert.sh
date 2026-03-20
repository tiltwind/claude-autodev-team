#!/usr/bin/env bash
# autodev-lite-expert.sh - Launch the lite-expert orchestrator skill for multi-agent development
#
# Usage:
#   bash .claude/scripts/autodev-lite-expert.sh "requirement description"
#   bash .claude/scripts/autodev-lite-expert.sh --resume
#
# Uses Claude Code's skill system with subagents.
set -euo pipefail

log() {
  echo ""
  echo "========================================"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [autodev-lite-expert] $1"
  echo "========================================"
}

REQUIREMENT=$1

claude -p "/autodev-lite-expert $REQUIREMENT" --verbose

log "Orchestrator finished"

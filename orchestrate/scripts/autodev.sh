#!/usr/bin/env bash
# autodev.sh - Launch the orchestrator agent for multi-agent development
#
# Usage:
#   bash .claude/scripts/autodev.sh "requirement description"
#
# Uses Claude Code's native agent system with subagents instead of hooks.
set -euo pipefail

log() {
  echo ""
  echo "========================================"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [autodev] $1"
  echo "========================================"
}

REQUIREMENT=$1

claude --agent orchestrator -p "$REQUIREMENT" --verbose

log "Orchestrator finished"

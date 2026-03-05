# claude-autodev-team

Reusable Claude Code config for multi-agent automatic development workflow.

## Install

Run in your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/scripts/install.sh | bash
```

Re-run the same command to update -- existing symlinks are refreshed and non-symlink files are never overwritten.

## Workflow

Six agents collaborate through a shared directory `.claude/autodev/<YYYY-MM-DD-short-name>/`, each producing structured documents that the next agent consumes.

```
@analyst  -->  designer  -->  expert  -->  developer  -->  engineer  -->  tester
                                              ^                            |
                                              |     (if tests fail)        |
                                              +----------------------------+
```

### Agents

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **analyst** | Requirement Analyst | User's requirement | `0-raw-requirement.md`, `1-requirement.md` |
| **designer** | Technical Designer | `1-requirement.md` | `2-plan-design.md` |
| **expert** | Technical Expert | `1-requirement.md`, `2-plan-design.md` | `3-plan-review.md`, `4-plan-expert.md` |
| **developer** | Developer | `4-plan-expert.md` (or `integrations-error-<N>.md`) | Source code + unit tests |
| **engineer** | Code Review Engineer | `4-plan-expert.md` + changed code | Improved source code |
| **tester** | Integration Tester | `4-plan-expert.md` + source code | `5-test-report.md` or `integrations-error-<N>.md` |

### Document Flow

```
0-raw-requirement.md        # Raw user requirement (analyst creates)
1-requirement.md            # Structured requirements with user stories
2-plan-design.md            # Technical design and implementation plan
3-plan-review.md            # Expert review: issues found and recommendations
4-plan-expert.md            # Improved design (same structure as 2-plan-design.md)
5-test-report.md            # Final test report (when all tests pass)
integrations-error-<N>.md   # Test failure report (triggers developer fix loop)
integrations-error-<N>-DONE.md  # Fixed error (renamed by developer)
```

### Tester Retry Loop

When the tester finds integration test failures:

1. Tester creates `integrations-error-<N>.md` with detailed error report
2. Developer reads error file, fixes code, renames to `integrations-error-<N>-DONE.md`
3. Engineer reviews the fix
4. Tester re-runs tests
5. Loop repeats up to 3 times, then stops for manual intervention

## Usage

### Method 1: `@analyst` + Stop Hook (recommended)

In a Claude Code interactive session:

```
@analyst implement user login with email and phone number
```

The analyst creates the autodev directory and requirement docs. When it finishes, the **Stop hook** automatically triggers the remaining agents in sequence via `claude -p` (non-interactive mode) in the background.

### Method 2: Standalone Orchestrator

Run from the terminal:

```bash
bash .claude/scripts/autodev.sh "implement user login with email and phone number"
```

Resume an interrupted session:

```bash
bash .claude/scripts/autodev.sh --resume
```

## How Agents Are Chained

### Stop Hook

Configured in `settings.local.json`:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "command": "bash .claude/scripts/autodev-hook.sh"
    }]
  }
}
```

### Scripts

| Script | Purpose |
|--------|---------|
| `autodev-hook.sh` | Stop hook entry point. Checks for active session, launches pipeline in background |
| `autodev-pipeline.sh` | Core pipeline. Runs agents sequentially via `claude -p` based on STATE |
| `autodev.sh` | Standalone orchestrator (alternative to hooks, runs all agents in one command) |

### State Machine

State is tracked in `<autodev-dir>/STATE` and `.claude/autodev/ACTIVE`:

```
analyst --> designer --> expert --> developer --> engineer --> tester
                                      ^                        |
                                      |   (unfixed errors?)    |
                                      +--- yes ----------------+
                                            |
                                            no --> done
```

- `ACTIVE` file points to the current autodev directory (deleted when workflow completes)
- `STATE` file tracks the current/last completed phase
- `claude -p` (non-interactive) does **not** trigger Stop hooks, preventing recursion

## Project Structure

```
agents/
  analyst.md          # Requirement analyst agent prompt
  designer.md         # Technical designer agent prompt
  expert.md           # Technical expert agent prompt
  developer.md        # Developer agent prompt
  engineer.md         # Code review engineer agent prompt
  tester.md           # Integration tester agent prompt
scripts/
  install.sh          # Install script (symlinks into target project)
  autodev.sh          # Standalone orchestrator
  autodev-hook.sh     # Stop hook entry point
  autodev-pipeline.sh # Pipeline runner (called by hook)
settings.local.json   # Permissions + hook configuration
```

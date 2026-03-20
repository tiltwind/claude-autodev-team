# claude-autodev-team (autodev-command-full)

Multi-agent automatic development workflow using Claude Code's native subagent system.

## Install

Run in your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/autodev-command-full/scripts/install.sh | bash
```

Re-run the same command to update -- existing symlinks are refreshed and non-symlink files are never overwritten.

## Workflow

Six agents collaborate through a shared directory `.autodev/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<short-name>/`, orchestrated by a custom slash command `/autodev` that runs in the main Claude Code conversation and dispatches sub-agents via the Agent tool.

```
/autodev command (main conversation)
  |-> analyst  ->  designer  ->  expert  ->  developer  ->  reviewer  ->  tester
                                                 ^                            |
                                                 |     (if tests fail)        |
                                                 +----------------------------+
```

### Architecture

The `/autodev` command acts as an "orchestration script" — it injects pipeline logic into the main conversation, which then serially calls each sub-agent using the Agent tool. This avoids the limitation that sub-agents cannot call other sub-agents.

### Agents

All agents are defined as Claude Code subagent `.md` files with YAML frontmatter.

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **analyst** | Requirement Analyst | User's requirement | `0-requirement-raw.md`, `1-requirement-final.md` |
| **designer** | Technical Designer | `1-requirement-final.md` | `2-design-raw.md` |
| **expert** | Technical Expert | `1-requirement-final.md`, `2-design-raw.md` | `3-design-review.md`, `4-design-final.md` |
| **developer** | Developer | `4-design-final.md` (or `integrations-error-<N>.md`) | Source code + unit tests |
| **reviewer** | Code Review Engineer | `4-design-final.md` + changed code | `5-code-review.md`, Improved source code |
| **tester** | Integration Tester | `4-design-final.md` + source code | `6-test-report.md` or `integrations-error-<N>.md` |

### Document Flow

```
0-requirement-raw.md        # Raw user requirement (analyst creates)
1-requirement-final.md      # Structured requirements with user stories
2-design-raw.md             # Technical design and implementation plan
3-design-review.md          # Expert review: issues found and recommendations
4-design-final.md           # Improved design (same structure as 2-design-raw.md)
5-code-review.md            # Code review: issues found and recommendations
6-test-report.md            # Final test report (when all tests pass)
integrations-error-<N>.md   # Test failure report (triggers developer fix loop)
integrations-error-<N>-DONE.md  # Fixed error (renamed by developer)
```

### Tester Retry Loop

When the tester finds integration test failures:

1. Tester creates `integrations-error-<N>.md` with detailed error report
2. Orchestrator loops back to developer
3. Developer reads error file, fixes code, renames to `integrations-error-<N>-DONE.md`
4. Reviewer reviews the fix
5. Tester re-runs tests
6. Loop repeats up to 3 times, then stops for manual intervention

## Usage

Run from the terminal:

```bash
bash .claude/scripts/autodev.sh "implement user login with email and phone number"
```

Or use the slash command directly in a Claude Code session:

```
/autodev implement user login with email and phone number
```

Resume an interrupted session:

```
/autodev
```

**NOTE**: ALWAYS PROVIDE COMPLETED REQUIREMENTS.

## How It Works

- The `/autodev` command injects orchestration logic into the main Claude Code conversation
- The main conversation dispatches sub-agents sequentially via the Agent tool
- Each sub-agent is a `.md` file with YAML frontmatter (`name`, `description`, `tools`, `model`)
- No hooks needed — the command manages flow directly
- Sub-agents don't need to call other sub-agents (which isn't supported)

## Project Structure

```
commands/
  autodev.md          # Orchestration command (slash command /autodev)
agents/
  analyst.md          # Requirement analyst sub-agent
  designer.md         # Technical designer sub-agent
  expert.md           # Technical expert sub-agent
  developer.md        # Developer sub-agent
  reviewer.md         # Code review sub-agent
  tester.md           # Integration tester sub-agent
  orchestrator.md     # (legacy, no longer used — kept for reference)
scripts/
  install.sh          # Install script (symlinks into target project)
  autodev.sh          # Entry point - launches /autodev command
settings.local.json   # Permissions (no hooks needed)
```

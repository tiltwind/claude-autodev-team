# claude-autodev-team (orchestrate)

Multi-agent automatic development workflow using Claude Code's native subagent system instead of hooks.

## Install

Run in your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/orchestrate/scripts/install.sh | bash
```

Re-run the same command to update -- existing symlinks are refreshed and non-symlink files are never overwritten.

## Workflow

Six agents collaborate through a shared directory `.claude/autodev/<YYYY-MM-DD-short-name>/`, orchestrated by a single Claude Code session using the native Agent tool (subagents).

```
orchestrator (claude --agent orchestrator)
  |-> analyst  ->  designer  ->  expert  ->  developer  ->  reviewer  ->  tester
                                                 ^                            |
                                                 |     (if tests fail)        |
                                                 +----------------------------+
```

### Agents

All agents are defined as Claude Code subagent `.md` files with YAML frontmatter.

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **orchestrator** | Coordinates all agents via Agent tool | User requirement | Manages pipeline flow |
| **analyst** | Requirement Analyst | User's requirement | `0-requirement-raw.md`, `1-requirement-final.md` |
| **designer** | Technical Designer | `1-requirement-final.md` | `2-design-raw.md` |
| **expert** | Technical Expert | `1-requirement-final.md`, `2-design-raw.md` | `3-design-review.md`, `4-design-final.md` |
| **developer** | Developer | `4-design-final.md` (or `integrations-error-<N>.md`) | Source code + unit tests |
| **reviewer** | Code Review Engineer | `4-design-final.md` + changed code | Improved source code |
| **tester** | Integration Tester | `4-design-final.md` + source code | `5-test-report.md` or `integrations-error-<N>.md` |

### Document Flow

```
0-requirement-raw.md        # Raw user requirement (analyst creates)
1-requirement-final.md      # Structured requirements with user stories
2-design-raw.md             # Technical design and implementation plan
3-design-review.md          # Expert review: issues found and recommendations
4-design-final.md           # Improved design (same structure as 2-design-raw.md)
5-test-report.md            # Final test report (when all tests pass)
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

Resume an interrupted session:

```bash
bash .claude/scripts/autodev.sh --resume
```

**NOTE**: ALWAYS PROVIDE COMPLETED REQUIREMENTS.

## How It Works (vs hook-sequence)

### hook-sequence approach
- Uses Claude Code's Stop hooks to chain agents
- Each agent runs as a separate `claude -p` invocation
- Shell scripts (`autodev-hook.sh`, `autodev-pipeline.sh`) manage state machine
- Requires hook configuration in `settings.local.json`

### orchestrate approach
- Single Claude Code session runs `claude --agent orchestrator`
- Orchestrator dispatches sub-agents via the native Agent tool
- Each sub-agent is a `.md` file with YAML frontmatter (`name`, `description`, `tools`, `model`)
- No hooks needed - the orchestrator manages flow directly
- Simpler setup, fewer moving parts
- Better error handling and context sharing

## Project Structure

```
agents/
  orchestrator.md     # Orchestrator agent (dispatches sub-agents)
  analyst.md          # Requirement analyst sub-agent
  designer.md         # Technical designer sub-agent
  expert.md           # Technical expert sub-agent
  developer.md        # Developer sub-agent
  reviewer.md         # Code review sub-agent
  tester.md           # Integration tester sub-agent
scripts/
  install.sh          # Install script (symlinks into target project)
  autodev.sh          # Entry point - sets up session, launches orchestrator
settings.local.json   # Permissions (no hooks needed)
```

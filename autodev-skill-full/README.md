# claude-autodev-team (autodev-skill-full)

Multi-agent automatic development workflow using Claude Code's **skill system**.

## Comparison with autodev-command-full

| Aspect | autodev-command-full | autodev-skill-full |
|--------|-------------------|-------------------|
| Entry point | `.claude/commands/autodev.md` | `.claude/skills/autodev/SKILL.md` |
| Sub-agent storage | `.claude/orchestrate/*.md` (separate dir) | `.claude/skills/autodev/agents/*.md` (bundled) |
| Agent path reference | Hard-coded `.claude/orchestrate/` | `${CLAUDE_SKILL_DIR}/agents/` (self-contained) |
| Invocation | `/autodev` (slash command) | `/autodev` (skill, same UX) |
| Auto-invocation | No | Yes (Claude can auto-trigger based on description) |
| Frontmatter | Not used on command | Full YAML frontmatter with `allowed-tools`, `argument-hint` |
| Installation | Symlinks commands/ + orchestrate/ dirs | Symlinks single skills/autodev/ directory |

## Install

Run in your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/autodev-skill-full/scripts/install.sh | bash
```

Re-run the same command to update.

## Workflow

Six agents collaborate through a shared directory `.autodev/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<short-name>/`, orchestrated by the `/autodev` skill that runs in the main Claude Code conversation and dispatches sub-agents via the Agent tool.

```
/autodev skill (main conversation)
  |-> analyst  ->  designer  ->  expert  ->  developer  ->  reviewer  ->  tester
                                                 ^                            |
                                                 |     (if tests fail)        |
                                                 +----------------------------+
```

### Architecture

The `/autodev` skill acts as an orchestrator -- it runs in the main conversation context (no `context: fork`), which allows it to use the Agent tool to dispatch sub-agents sequentially. Sub-agent definitions are bundled as supporting files inside the skill directory, referenced via `${CLAUDE_SKILL_DIR}/agents/<agent-name>.md`.

### Agents

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

Or use the skill directly in a Claude Code session:

```
/autodev implement user login with email and phone number
```

Resume an interrupted session:

```
/autodev
```

## Project Structure

```
autodev-skill-full/
├── README.md
├── settings.local.json
├── skills/
│   └── autodev/
│       ├── SKILL.md              # Orchestrator skill (entry point)
│       └── agents/               # Sub-agent definitions (supporting files)
│           ├── analyst.md
│           ├── designer.md
│           ├── expert.md
│           ├── developer.md
│           ├── reviewer.md
│           └── tester.md
└── scripts/
    ├── autodev.sh                # Terminal entry point
    └── install.sh                # Installation script
```

## Key Skill Features Used

- **YAML frontmatter**: `name`, `description`, `argument-hint`, `allowed-tools` for skill metadata
- **`${CLAUDE_SKILL_DIR}`**: Self-referencing path variable to locate bundled agent definitions
- **Supporting files**: Sub-agent `.md` files live alongside the skill, no separate directory needed
- **`allowed-tools`**: Pre-authorizes tools the orchestrator needs (Read, Write, Agent, etc.)
- **Auto-discovery**: Claude can auto-trigger the skill based on its description

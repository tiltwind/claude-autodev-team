# claude-autodev-team (autodev-skill-lite)

Lightweight multi-agent automatic development workflow using Claude Code's **skill system**. A simplified version of `autodev-skill-full` with 4 agents instead of 6.

## Install

Run in your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/autodev-skill-lite/scripts/install.sh | bash
```

Re-run the same command to update.

## Workflow

Four agents collaborate through a shared directory `.autodev/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<short-name>/`, orchestrated by the `/autodev-lite` skill that runs in the main Claude Code conversation and dispatches sub-agents via the Agent tool.

```
/autodev-lite skill (main conversation)
  |-> analyst  ->  designer  ->  developer
```

### Agents

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **analyst** | Requirement Analyst | User's requirement | `0-requirement-raw.md`, `1-requirement-final.md` |
| **designer** | Technical Designer | `1-requirement-final.md` | `2-design.md` |
| **developer** | Developer | `2-design.md`| Source code + unit tests |

### Document Flow

```
0-requirement-raw.md        # Raw user requirement (analyst creates)
1-requirement-final.md      # Structured requirements with user stories
2-design.md           # Technical design and implementation plan
```

## Usage

Run from the terminal:

```bash
bash .claude/scripts/autodev-lite.sh "implement user login with email and phone number"
```

Or use the skill directly in a Claude Code session:

```
/autodev-lite implement user login with email and phone number
```

Resume an interrupted session:

```
/autodev-lite
```

## Project Structure

```
autodev-skill-lite/
├── README.md
├── settings.local.json
├── skills/
│   └── autodev-lite/
│       ├── SKILL.md              # Orchestrator skill (entry point)
│       └── agents/               # Sub-agent definitions (supporting files)
│           ├── analyst.md
│           ├── designer.md
│           └── developer.md
└── scripts/
    ├── autodev-lite.sh           # Terminal entry point
    └── install.sh                # Installation script
```

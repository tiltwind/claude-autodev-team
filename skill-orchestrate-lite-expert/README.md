# claude-autodev-team (skill-orchestrate-lite-expert)

Lightweight multi-agent automatic development workflow with expert code review, using Claude Code's **skill system**. An enhanced version of `skill-orchestrate-lite` that adds an expert review phase after development.

## Install

Run in your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/skill-orchestrate-lite-expert/scripts/install.sh | bash
```

Re-run the same command to update.

## Workflow

Four agents collaborate through a shared directory `.autodev/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<short-name>/`, orchestrated by the `/autodev-lite-expert` skill that runs in the main Claude Code conversation and dispatches sub-agents via the Agent tool.

```
/autodev-lite-expert skill (main conversation)
  |-> analyst  ->  designer  ->  developer  ->  expert
```

### Agents

| Agent | Role | Input | Output |
|-------|------|-------|--------|
| **analyst** | Requirement Analyst | User's requirement | `0-requirement-raw.md`, `1-requirement-final.md` |
| **designer** | Technical Designer | `1-requirement-final.md` | `2-design.md` |
| **developer** | Developer | `2-design.md`| Source code + unit tests |
| **expert** | Code Review Expert | Source code | Code fixes + `3-review.md` |

### Document Flow

```
0-requirement-raw.md        # Raw user requirement (analyst creates)
1-requirement-final.md      # Structured requirements with user stories
2-design.md                 # Technical design and implementation plan
3-review.md                 # Expert review summary and fixes applied
```

## Usage

Run from the terminal:

```bash
bash .claude/scripts/autodev-lite-expert.sh "implement user login with email and phone number"
```

Or use the skill directly in a Claude Code session:

```
/autodev-lite-expert implement user login with email and phone number
```

Resume an interrupted session:

```
/autodev-lite-expert
```

## Project Structure

```
skill-orchestrate-lite-expert/
├── README.md
├── settings.local.json
├── skills/
│   └── autodev-lite-expert/
│       ├── SKILL.md              # Orchestrator skill (entry point)
│       └── agents/               # Sub-agent definitions (supporting files)
│           ├── analyst.md
│           ├── designer.md
│           ├── developer.md
│           └── expert.md
└── scripts/
    ├── autodev-lite-expert.sh    # Terminal entry point
    └── install.sh                # Installation script
```

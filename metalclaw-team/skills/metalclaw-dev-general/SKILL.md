---
name: metalclaw-dev-general
description: Orchestrate the general MetalClaw development pipeline. Coordinate analyst, designer, developer, and reviewer sub-agents for development with code review.
argument-hint: [requirement description or session directory]
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash
---

Orchestrate the general MetalClaw development pipeline.

## Instructions

1. Determine the root document directory as `<root-doc-dir>`, use the directory if user specifies, default to `doc/`
2. Determine the current dev session directory as `<dev-session-dir>`:
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new dev session directory in format `<root-doc-dir>/changes/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<requirement-short-name>/` (where `<NNN>` is a zero-padded sequential number starting from 001 within that day) if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<dev-session-dir>/0-requirement-raw.md`
   - Otherwise, require user to specify the session directory or requirements info
3. Run each sub-agent in sequential pipeline:
   - Write the current sub-agent name to `<dev-session-dir>/STATE` before dispatching each sub-agent
   - **CRITICAL**: For each sub-agent, first **Read** its definition file `${CLAUDE_SKILL_DIR}/metalclaw-sub-agents/<agent-name>.md`, then use the file's content as the sub-agent's prompt, with `<dev-session-dir>` replaced by the actual session directory path. This ensures each sub-agent follows its exact instructions and file naming conventions.
   - Call the Agent tool with: `description: "<agent-name> phase"`, `subagent_type: "general-purpose"`, `prompt: <the agent instructions with dev-session-dir substituted>`
4. When the workflow is complete:
   - Write `done` to `<dev-session-dir>/STATE`
   - Output a summary of what was accomplished


## Sub-Agents Sequential Pipeline

```
analyst -> designer -> developer -> reviewer
```

1. **analyst** : Requirement Analyst
2. **designer** : Technical Designer
3. **developer** : Code Developer
4. **reviewer** : Code Reviewer


## Resume Support

If `<dev-session-dir>/STATE` already exists when starting:
- Read the state to determine which agent completed last
- Skip already-completed phases and continue from the next agent
- State progression: analyst -> designer -> developer -> reviewer -> done

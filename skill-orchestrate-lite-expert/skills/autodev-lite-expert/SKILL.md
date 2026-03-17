---
name: autodev-lite-expert
description: Orchestrate the autodev-lite-expert multi-agent development pipeline. Coordinate analyst, designer, developer, expert sub-agents to turn requirements into reviewed, tested code.
argument-hint: [requirement description or session directory]
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash
---

Orchestrate the autodev-lite-expert multi-agent development pipeline.

## Instructions

1. Determine the current autodev session directory as `<autodev-session-dir>`:
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new autodev session directory in format `.autodev/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<requirement-short-name>.md` (where `<NNN>` is a zero-padded sequential number starting from 001 within that day) if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<autodev-session-dir>/0-requirement-raw.md`
   - Otherwise, , require user to specify the session directory or requirements info
2. Run each sub-agent in sequential pipeline:
   - Write the current sub-agent name to `<autodev-session-dir>/STATE` before dispatching each sub-agent
   - **CRITICAL**: For each sub-agent, first **Read** its definition file `${CLAUDE_SKILL_DIR}/agents/<agent-name>.md`, then use the file's content as the sub-agent's prompt, with `<autodev-session-dir>` replaced by the actual session directory path. This ensures each sub-agent follows its exact instructions and file naming conventions.
   - Call the Agent tool with: `description: "<agent-name> phase"`, `subagent_type: "general-purpose"`, `prompt: <the agent instructions with autodev-session-dir substituted>`
3. When the workflow is complete:
   - Write `done` to `<autodev-session-dir>/STATE`
   - Output a summary of what was accomplished


## Sub-Agents Sequential Pipeline

```
analyst -> designer -> developer -> expert
```

1. **analyst** : Requirement Analyst
2. **designer** : Technical Designer
3. **developer** : Code Developer
4. **expert** : Code Review Expert


## Resume Support

If `<autodev-session-dir>/STATE` already exists when starting:
- Read the state to determine which agent completed last
- Skip already-completed phases and continue from the next agent
- State progression: analyst -> designer -> developer -> expert -> done

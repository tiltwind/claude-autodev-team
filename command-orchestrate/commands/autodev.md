Orchestrate the autodev multi-agent development pipeline. Coordinate analyst, designer, expert, developer, reviewer, and tester sub-agents to turn requirements into tested code.

## Instructions

1. Determine the current autodev session directory as `<autodev-session-dir>`:
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new autodev session directory in format `<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<requirement-short-name>` (where `<NNN>` is a zero-padded sequential number starting from 001 within that day) if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<autodev-session-dir>/0-requirement-raw.md`
   - Check `.autodev/ACTIVE` file to determine the current session directory if `$ARGUMENTS` is empty
   - Otherwise, report an error.
2. Write `<autodev-session-dir>` to `.autodev/ACTIVE`
3. Run each sub-agent in sequential pipeline:
   - Write the current sub-agent name to `<autodev-session-dir>/STATE` before dispatching each sub-agent
   - **CRITICAL**: For each sub-agent, first **Read** its definition file `.claude/orchestrate/<agent-name>.md`, then use the file's body content as the sub-agent's prompt, with `<autodev-dir>` replaced by the actual session directory path. This ensures each sub-agent follows its exact instructions and file naming conventions.
   - Call the Agent tool with: `description: "<agent-name> phase"`, `subagent_type: "general-purpose"`, `prompt: <the agent instructions with autodev-session-dir substituted>`
   - After the **tester** sub-agent completes, check for unfixed errors:
      - Look for `integrations-error-*.md` files WITHOUT `-DONE` suffix in the autodev directory
      - If unfixed errors exist: loop back to **developer -> reviewer -> tester**
      - If no unfixed errors: the workflow is complete
   - Maximum 3 fix iterations. After that, stop and report failure.
4. When the workflow is complete:
   - Write `done` to `<autodev-session-dir>/STATE`
   - Remove `.autodev/ACTIVE` file
   - Output a summary of what was accomplished


##  Sub-Agents Sequential Pipeline

```
analyst -> designer -> expert -> developer -> reviewer -> tester
                                    ^                        |
                                    |   (if tests fail)      |
                                    +------------------------+
```

1. **analyst** : Requirement Analyst 
2. **designer** : Technical Designer 
3. **expert** : Technical Expert 
4. **developer** : Code Developer 
5. **reviewer** : Code Reviewer 
6. **tester** : Integration Tester 


## Resume Support

If `<autodev-session-dir>/STATE` already exists when starting:
- Read the state to determine which agent completed last
- Skip already-completed phases and continue from the next agent
- State progression: analyst -> designer -> expert -> developer -> reviewer -> tester -> done



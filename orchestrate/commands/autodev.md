Orchestrate the autodev multi-agent development pipeline. Coordinate analyst, designer, expert, developer, reviewer, and tester sub-agents to turn requirements into tested code.

## Pipeline

```
analyst -> designer -> expert -> developer -> reviewer -> tester
                                    ^                        |
                                    |   (if tests fail)      |
                                    +------------------------+
```

## Sub-Agents

| Sub-agent | Role |
|-------|------|
| analyst | Requirement Analyst |
| designer | Technical Designer |
| expert | Technical Expert |
| developer | Developer |
| reviewer | Code Reviewer |
| tester | Integration Tester |

## Instructions

1. Determine the current autodev session directory
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new autodev session directory if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<autodev-dir>/0-requirement-raw.md`
   - Check `.claude/autodev/ACTIVE` file to determine the current session directory if `$ARGUMENTS` is empty
   - Otherwise, report an error.
2. Set `.claude/autodev/ACTIVE` file to the current session directory path
3. Run each sub-agent **sequentially** using the Agent tool (subagent_type is NOT needed — use the agent's name as description and pass the autodev-dir in the prompt)
4. Write the current sub-agent name to `<autodev-dir>/STATE` before dispatching each sub-agent
5. For each sub-agent call, pass the `<autodev-dir>` path in the prompt so the sub-agent knows where to read/write files
6. After the **tester** sub-agent completes, check for unfixed errors:
   - Look for `integrations-error-*.md` files WITHOUT `-DONE` suffix in the autodev directory
   - If unfixed errors exist: loop back to **developer -> reviewer -> tester**
   - If no unfixed errors: the workflow is complete
7. Maximum 3 fix iterations. After that, stop and report failure.

## Resume Support

If `<autodev-dir>/STATE` already exists when starting:
- Read the state to determine which agent completed last
- Skip already-completed phases and continue from the next agent
- State progression: analyst -> designer -> expert -> developer -> reviewer -> tester -> done

## Completion

When all tests pass:
- Write `done` to `<autodev-dir>/STATE`
- Remove `.claude/autodev/ACTIVE` file
- Output a summary of what was accomplished

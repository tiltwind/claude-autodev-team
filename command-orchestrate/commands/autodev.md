Orchestrate the autodev multi-agent development pipeline. Coordinate analyst, designer, expert, developer, reviewer, and tester sub-agents to turn requirements into tested code.

## Instructions

1. Determine the current autodev session directory as `<autodev-dir>`:
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new autodev session directory if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<autodev-dir>/0-requirement-raw.md`
   - Check `.claude/autodev/ACTIVE` file to determine the current session directory if `$ARGUMENTS` is empty
   - Otherwise, report an error.
2. Write `<autodev-dir>` to `.claude/autodev/ACTIVE`
3. Run each sub-agent in sequential pipeline:
   - Write the current sub-agent name to `<autodev-dir>/STATE` before dispatching each sub-agent
   - After the **@tester** sub-agent completes, check for unfixed errors:
      - Look for `integrations-error-*.md` files WITHOUT `-DONE` suffix in the autodev directory
      - If unfixed errors exist: loop back to **@developer -> @reviewer -> @tester**
      - If no unfixed errors: the workflow is complete
   - Maximum 3 fix iterations. After that, stop and report failure.
4. When the workflow is complete:
   - Write `done` to `<autodev-dir>/STATE`
   - Remove `.claude/autodev/ACTIVE` file
   - Output a summary of what was accomplished


##  Sub-Agents Sequential Pipeline

```
analyst -> designer -> expert -> developer -> reviewer -> tester
                                    ^                        |
                                    |   (if tests fail)      |
                                    +------------------------+
```


1. **@analyst** : Requirement Analyst 
2. **@designer** : Technical Designer 
3. **@expert** : Technical Expert 
4. **@developer** : Code Developer 
5. **@reviewer** : Code Reviewer 
6. **@tester** : Integration Tester 


## Resume Support

If `<autodev-dir>/STATE` already exists when starting:
- Read the state to determine which agent completed last
- Skip already-completed phases and continue from the next agent
- State progression: analyst -> designer -> expert -> developer -> reviewer -> tester -> done



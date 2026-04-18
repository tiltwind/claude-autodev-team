---
name: metalclaw-dev-auto
description: Orchestrate the MetalClaw development pipeline with automatic complexity-aware phase selection. Coordinate analyst, designer, developer, and documenter sub-agents, and auto-decide whether to include improver, reviewer, and tester sub-agents based on task complexity and code modification scope.
argument-hint: [requirement description or session directory]
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash
---

Orchestrate the MetalClaw multi-agent development pipeline with automatic complexity-aware phase selection.

Unlike `metalclaw-dev-full` (which always runs all 7 sub-agents) and `metalclaw-dev-lite` (which always runs a fixed 4), this skill evaluates the task after the **designer** phase and auto-decides whether the **improver**, **reviewer**, and **tester** phases are necessary.

## Instructions

1. Determine the root session directory as `<root-session-dir>`, use the directory if user specifies, default to `changes/`
2. Determine the current dev session directory as `<dev-session-dir>`:
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new dev session directory in format `<root-session-dir>/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<requirement-short-name>/` (where `<NNN>` is a zero-padded sequential number starting from 001 within that day) if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<dev-session-dir>/requirement-raw.md`
   - Otherwise, require user to specify the session directory or requirements info
3. Run each sub-agent in sequential pipeline:
   - Write the current sub-agent name to `<dev-session-dir>/STATE` before dispatching each sub-agent
   - **CRITICAL**: For each sub-agent, first **Read** its definition file `~/.claude/claude-autodev-team/metalclaw-team/metalclaw-sub-agents/<agent-name>.md`, then use the file's content as the sub-agent's prompt, with `<dev-session-dir>` replaced by the actual session directory path. This ensures each sub-agent follows its exact instructions and file naming conventions.
   - Call the Agent tool with: `description: "<agent-name> phase"`, `subagent_type: "general-purpose"`, `prompt: <the agent instructions with dev-session-dir substituted>`
   - **After the designer sub-agent completes**, perform the [Complexity Assessment](#complexity-assessment) to decide whether **improver**, **reviewer**, and **tester** phases will run. Record the decision and rationale to `<dev-session-dir>/auto-plan.md`.
   - **improver** runs only if the assessment marks it as needed; otherwise skip directly to **developer**.
   - After the **developer** sub-agent completes:
      - If **reviewer** is needed per the assessment: run **reviewer**, then proceed to the tester decision below.
      - If **reviewer** is not needed per the assessment: skip directly to the tester decision below.
   - After the reviewer decision is resolved:
      - If **tester** is needed per the assessment: run **tester**, then check for unfixed errors (see below).
      - If **tester** is not needed per the assessment: skip directly to **documenter**.
   - After the **tester** sub-agent completes (only if tester was enabled), check for unfixed errors:
      - Look for `integrations-error-*.md` files WITHOUT `-DONE` suffix in the dev session directory
      - If unfixed errors exist: loop back to **developer -> [reviewer?] -> tester** (honoring the assessment's reviewer decision)
      - If no unfixed errors: proceed to **documenter**
   - Maximum 3 fix iterations. After that, stop and report failure.
   - After the **documenter** sub-agent completes, the workflow is complete
4. When the workflow is complete:
   - Write `done` to `<dev-session-dir>/STATE`
   - Output a summary of what was accomplished, and explicitly note which optional phases (improver, reviewer, tester) were skipped and why.


## Complexity Assessment

After `designer` finishes, **Read** `<dev-session-dir>/requirement.md` and `<dev-session-dir>/design.md`, then judge:

**Include `improver` when ANY of these hold:**
- New architectural pattern, framework, or cross-cutting concern is introduced (e.g., new auth flow, caching layer, messaging, background jobs)
- Non-trivial algorithm, concurrency, performance, or security decision is involved
- Data model or API contract is newly added or reshaped in a way that is hard to reverse
- The design spans 3+ modules/components, or the implementation plan lists 5+ ordered tasks
- The requirement has ambiguity or multiple viable solutions that benefit from a senior second-opinion
- The affected surface is core/shared code used by many callers

**Skip `improver` when ALL of these hold:**
- The change is localized (typically 1–2 files or one component)
- No schema, API contract, or public interface change
- The design reuses existing patterns and introduces no new abstractions
- The implementation plan has a small, linear set of tasks (≤ 3)
- Examples: copy tweaks, small UI adjustments, bugfixes with obvious root cause, renames, simple CRUD additions following existing conventions

**Include `reviewer` when ANY of these hold:**
- The change touches core/shared code, security-sensitive paths, or logic with non-trivial branching
- New or reshaped data models, API contracts, or public interfaces
- Concurrency, transactions, error handling, or performance-sensitive code is involved
- Multiple files are modified, or the diff is substantive (roughly 50+ changed lines of non-boilerplate code)
- Developer output has uncertainty flags, TODOs, or deviations from the design

**Skip `reviewer` when ALL of these hold:**
- Change is trivial and mechanically obvious (e.g., copy tweak, style/format, typo fix, dependency bump without API change)
- No logic, data, API, or interface change
- Diff is small (a few lines) and follows an existing pattern verbatim
- No security, concurrency, or error-handling implications

**Include `tester` when ANY of these hold:**
- Backend logic, data layer, API, business rules, or integrations are touched
- Multiple components interact or a new flow is introduced
- Requirement defines acceptance criteria that can be verified via integration tests
- Design lists an integration test plan with runnable scenarios
- The change risks regressions in existing flows touched by the diff

**Skip `tester` when ALL of these hold:**
- Change is purely cosmetic/static (copy, styles, typos, comments, formatting, docs-only)
- Change cannot be meaningfully covered by integration tests (e.g., pure visual tweak)
- No backend, data, API, or business rule is modified
- Requirement has no integration-testable acceptance criteria

**Tie-breaker rule:** When uncertain, include the phase. The cost of an unneeded review is low; the cost of skipping a needed one can be a regression.

Write the decision to `<dev-session-dir>/auto-plan.md` with this structure:

```markdown
# Auto Plan

## Complexity Assessment
- Scope summary: <files/modules/components impacted>
- Design complexity: <low | medium | high>
- Risk level: <low | medium | high>

## Phase Decisions
- improver: <include | skip> — <one-line rationale>
- reviewer: <include | skip> — <one-line rationale>
- tester: <include | skip> — <one-line rationale>

## Effective Pipeline
analyst -> designer -> [improver?] -> developer -> [reviewer?] -> [tester?] -> documenter
```


## Sub-Agents Pipeline (conditional)

```
analyst -> designer -> [improver] -> developer -> [reviewer] -> [tester] -> documenter
                                      ^                          |
                                      |     (if tests fail)      |
                                      +--------------------------+
```

Phases in `[brackets]` run only if the Complexity Assessment marks them as needed.

1. **analyst** : Requirement Analyst (always)
2. **designer** : Technical Designer (always)
3. **improver** : Technical Expert (conditional)
4. **developer** : Code Developer (always)
5. **reviewer** : Code Reviewer (conditional)
6. **tester** : Integration Tester (conditional)
7. **documenter** : Product Design Documenter (always)


## Resume Support

If `<dev-session-dir>/STATE` already exists when starting:
- Read the state to determine which agent completed last
- If `<dev-session-dir>/auto-plan.md` exists, honor its phase decisions; otherwise re-run the Complexity Assessment before continuing past `designer`
- Skip already-completed phases and continue from the next agent in the effective pipeline
- State progression (with conditional phases): analyst -> designer -> [improver] -> developer -> [reviewer] -> [tester] -> documenter -> done

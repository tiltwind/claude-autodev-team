---
name: metalclaw-dev-step
description: Orchestrate the MetalClaw development pipeline with a human-in-the-loop confirmation gate after every non-documenter phase. Coordinate analyst, designer, developer, and documenter sub-agents, and auto-decide whether to include improver, reviewer, and tester phases; after each non-documenter phase, surface any items that need user confirmation, collect answers, and re-dispatch the same sub-agent with those answers to finalize the phase.
argument-hint: [requirement description or session directory]
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash
---

Orchestrate the MetalClaw multi-agent development pipeline with a **user confirmation gate** after every phase except `documenter`.

This skill is identical to `metalclaw-dev-auto` (same conditional pipeline, same Complexity Assessment) but adds a step-by-step human-in-the-loop checkpoint: after each non-documenter sub-agent finishes, the orchestrator checks for items the sub-agent wants the user to confirm. If any exist, it prompts the user, captures their answers, and **restarts a fresh instance of the same sub-agent** with the confirmation answers so that the phase's outputs reflect the user's decisions before moving on.

## Instructions

1. Determine the root session directory as `<root-session-dir>`, use the directory if user specifies, default to `changes/`
2. Determine the current dev session directory as `<dev-session-dir>`:
   - Use the directory if user specifies the session directory in `$ARGUMENTS`
   - Create a new dev session directory in format `<root-session-dir>/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<requirement-short-name>/` (where `<NNN>` is a zero-padded sequential number starting from 001 within that day) if user specifies requirements info in `$ARGUMENTS`, and write the requirements to `<dev-session-dir>/requirement-raw.md`
   - Otherwise, require user to specify the session directory or requirements info
3. Run each sub-agent in sequential pipeline:
   - Write the current sub-agent name to `<dev-session-dir>/STATE` before dispatching each sub-agent
   - **CRITICAL**: For each sub-agent, first **Read** its definition file `~/.claude/claude-autodev-team/metalclaw-team/metalclaw-sub-agents/<agent-name>.md`, then use the file's content as the sub-agent's prompt, with `<dev-session-dir>` replaced by the actual session directory path. Append the [Confirmation Protocol](#confirmation-protocol) block to the prompt so the sub-agent knows to surface items that need user confirmation. This ensures each sub-agent follows its exact instructions and file naming conventions.
   - Call the Agent tool with: `description: "<agent-name> phase"`, `subagent_type: "general-purpose"`, `prompt: <the agent instructions with dev-session-dir substituted and the Confirmation Protocol appended>`
   - **After every sub-agent completes EXCEPT `documenter`**, run the [User Confirmation Gate](#user-confirmation-gate) for that phase before moving on.
   - **After the designer sub-agent completes** (and its confirmation gate resolves), perform the [Complexity Assessment](#complexity-assessment) to decide whether **improver**, **reviewer**, and **tester** phases will run. Record the decision and rationale to `<dev-session-dir>/auto-plan.md`.
   - **improver** runs only if the assessment marks it as needed; otherwise skip directly to **developer**.
   - After the **developer** sub-agent completes (and its confirmation gate resolves):
      - If **reviewer** is needed per the assessment: run **reviewer**, then proceed to the tester decision below.
      - If **reviewer** is not needed per the assessment: skip directly to the tester decision below.
   - After the reviewer decision is resolved (and reviewer's confirmation gate resolves if it ran):
      - If **tester** is needed per the assessment: run **tester**, then check for unfixed errors (see below).
      - If **tester** is not needed per the assessment: skip directly to **documenter**.
   - After the **tester** sub-agent completes and its confirmation gate resolves (only if tester was enabled), check for unfixed errors:
      - Look for `integrations-error-*.md` files WITHOUT `-DONE` suffix in the dev session directory
      - If unfixed errors exist: loop back to **developer -> [reviewer?] -> tester** (honoring the assessment's reviewer decision), running the confirmation gate after each re-run
      - If no unfixed errors: proceed to **documenter**
   - Maximum 3 fix iterations. After that, stop and report failure.
   - **documenter** runs without a confirmation gate. After it completes, the workflow is complete.
4. When the workflow is complete:
   - Write `done` to `<dev-session-dir>/STATE`
   - Output a summary of what was accomplished. Include which optional phases (improver, reviewer, tester) were skipped and why, and a brief log of confirmation rounds per phase (e.g., `designer: 1 round, 2 questions answered`).


## Confirmation Protocol

Append the following block to every sub-agent prompt **except** `documenter`, so the sub-agent knows how to surface items that need user confirmation:

```
## Confirmation Protocol (required for this run)

After finishing your primary output, review your work and decide whether there are items that genuinely need the user's confirmation before the next phase runs. Examples of items worth asking about:
- Ambiguous requirements you had to interpret
- Trade-offs where you made an assumption the user might want to override
- Proposed decisions with more than one reasonable option
- Risks, deletions, or destructive actions you want to flag
- Missing context you could not recover from the repo or existing docs

Write a file at `<dev-session-dir>/confirmations-<phase>-<NN>.md` (where `<phase>` is your sub-agent name and `<NN>` is a zero-padded round number starting from `01`). Create the `confirmations/` directory if it does not exist.

File format:
```
# <Phase> Confirmations — Round <NN>

## Status
<pending | none>

## Questions
1. <question title>
   - Context: <one or two sentences>
   - Options:
     - A) <option>
     - B) <option>
   - Recommended: <A | B | ...>  (optional)
   - Answer: <leave blank — the user will fill this in>

2. ...
```

Rules:
- If you have nothing that truly needs user input, still create the file with `Status: none` and no questions. Do not invent questions.
- Keep questions sharp and actionable. Prefer closed-form (A/B/C) questions; use free-form only when options would be misleading.
- Do not block on stylistic preferences that do not affect correctness — decide and move on.
- When invoked again for the same round (re-dispatch with user answers), read the filled-in `Answer:` fields, apply them to your outputs, update the relevant deliverables (e.g., `requirement.md`, `design.md`, code, etc.), and set `Status: resolved` at the top of the confirmations file.
```


## User Confirmation Gate

After every sub-agent run **except `documenter`**, do the following (referred to above as "running the confirmation gate"):

1. Find the latest confirmations file for the phase: `<dev-session-dir>/confirmations-<phase>-<NN>.md` with the highest `<NN>`.
   - If no file exists, treat it as a protocol miss: re-dispatch the same sub-agent once with a note reminding it to produce the confirmations file. If it still does not produce one, assume `Status: none` and continue.
2. **Read** the file and inspect `## Status`:
   - If `none` (or there are no questions): no user input needed. Proceed to the next phase.
   - If `pending` with questions: present them to the user in chat, numbered exactly as in the file, showing context, options, and any recommendation. Ask the user to answer each item. The user may answer "accept recommended" to take the recommended options in bulk.
3. Write the user's answers back into the `Answer:` fields of the confirmations file (preserve the file's structure). Do not change the questions themselves.
4. **Re-dispatch the same sub-agent** (a fresh Agent call — not the previous one) with:
   - `description: "<agent-name> phase (confirm round <NN>)"`
   - `subagent_type: "general-purpose"`
   - `prompt`: the sub-agent's definition file content with `<dev-session-dir>` substituted, the Confirmation Protocol block appended, plus a clearly-marked `## User Confirmation Answers` section at the end that includes:
     - The path to the filled confirmations file
     - An explicit instruction: "Apply these answers to your outputs, update the relevant deliverables, and set `Status: resolved` in the confirmations file. If applying the answers surfaces a new ambiguity, start a new round `confirmations-<phase>-<NN+1>.md` with `Status: pending`; otherwise leave no new round."
5. After the re-dispatch returns:
   - If a new round file `<phase>-<NN+1>.md` with `Status: pending` exists: repeat from step 2 with the new round.
   - Otherwise: proceed to the next phase.
6. Cap the confirmation loop at 3 rounds per phase. If still unresolved, stop and ask the user how to proceed.

Notes:
- The documenter phase is intentionally excluded — it runs last and produces PRD updates that do not require pre-phase negotiation.
- Confirmation rounds are independent of the tester fix-iteration loop; both are capped separately.


## Complexity Assessment

After `designer` finishes (and its confirmation gate resolves), **Read** `<dev-session-dir>/requirement.md` and `<dev-session-dir>/design.md`, then judge:

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


## Sub-Agents Pipeline (conditional, with confirmation gates)

```
analyst* -> designer* -> [improver*] -> developer* -> [reviewer*] -> [tester*] -> documenter
                                         ^                           |
                                         |     (if tests fail)       |
                                         +---------------------------+
```

`*` = phase is followed by a User Confirmation Gate. `[brackets]` = phase is conditional on the Complexity Assessment.

1. **analyst** : Requirement Analyst (always) — confirmation gate after
2. **designer** : Technical Designer (always) — confirmation gate after
3. **improver** : Technical Expert (conditional) — confirmation gate after
4. **developer** : Code Developer (always) — confirmation gate after
5. **reviewer** : Code Reviewer (conditional) — confirmation gate after
6. **tester** : Integration Tester (conditional) — confirmation gate after
7. **documenter** : Product Design Documenter (always) — **no** confirmation gate


## Resume Support

If `<dev-session-dir>/STATE` already exists when starting:
- Read the state to determine which agent was active last.
- If the state points to a non-documenter phase, also check `<dev-session-dir>/confirmations-<phase>-<NN>.md` for an open (`pending`) round and resume from the confirmation gate rather than re-running the whole phase.
- If `<dev-session-dir>/auto-plan.md` exists, honor its phase decisions; otherwise re-run the Complexity Assessment before continuing past `designer`.
- Skip already-completed phases and continue from the next agent in the effective pipeline.
- State progression (with conditional phases): analyst -> designer -> [improver] -> developer -> [reviewer] -> [tester] -> documenter -> done

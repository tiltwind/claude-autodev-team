---
name: metalclaw-req-prepare
description: Prepare MetalClaw development requirements by coarsely analyzing scope against the existing project architecture, deciding whether the requirement is small enough to deliver in one dev session or large enough to warrant splitting, and — after user confirmation — creating one or more `<dev-session-dir>` directories with `requirement-raw.md` populated. This skill never dives into code-level details and never splits small or medium-sized requirements.
argument-hint: [requirement description or raw requirement file path]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Prepare MetalClaw development requirements: do coarse architecture-level scope analysis, propose a split plan only when the requirement is genuinely too large for a single dev session, and after user confirmation materialize one or more dev session directories seeded with `requirement-raw.md`.

## Operating Principles (read first)

- **Stay at the architecture level.** Reason about modules, services, pages, models, procedures, and their relationships — not about functions, lines of code, or implementation details.
- **Do not split by default.** Most requirements should stay as one item. Split only when a single session truly cannot cover the scope.
- **Target: medium complexity per split.** Each resulting requirement should be something a single LLM dev session can realistically complete within its context window, while not being so tiny that it adds coordination overhead.
- **Splits are relatively independent.** Each split should deliver coherent value on its own and have a clean seam with the others.
- **Splits may have sequential dependencies.** If one split must precede another (e.g., schema change before UI consuming it), capture the order explicitly. Avoid circular dependencies.
- **Always let the user confirm before materializing directories.** Never create dev session directories silently.


## Instructions

### 1. Initialization

- Determine the root document directory as `<root-doc-dir>`, use the directory if user specifies, default to `doc/`
- Determine the product design directory as `<prd-dir>`, use the directory if user specifies, default to `<root-doc-dir>/prd/`
- Determine the root session directory as `<root-session-dir>`, use the directory if user specifies, default to `changes/`
- Capture the raw requirement:
  - If `$ARGUMENTS` contains a file path, **Read** it as the raw requirement
  - Otherwise, treat `$ARGUMENTS` (and any inline user description) as the raw requirement text
  - If nothing usable is provided, ask the user to supply a requirement or change request and stop until they do

### 2. Architecture Context Loading

Load only the high-level context needed to reason about scope. Do **not** read code under `src/` or equivalent — this skill works from product-design documents.

- If `<prd-dir>` exists, read:
  - `<prd-dir>/overview.md` — product positioning and context
  - `<prd-dir>/architecture/architecture.md` — business modules and their relationships
  - `<prd-dir>/architecture/roles.md` — roles and permissions (if present)
  - `<prd-dir>/dictionaries/dictionaries.md` — enums/dictionaries (if present)
- Based on requirement keywords, scan (titles/headings only is fine):
  - `<prd-dir>/models/` — data models that may be touched
  - `<prd-dir>/procedures/` — business processes that may be touched
  - `<prd-dir>/applications/` — applications and pages that may be touched
- Skip files that do not exist. For greenfield projects with no PRD yet, note that explicitly.

### 3. Coarse-Grained Scope Analysis

Produce a short internal assessment (do not dump every detail at the user yet) covering:

- **Affected modules** from `architecture.md`: list the modules likely to change, at the module level only.
- **Affected models / procedures / applications**: list by name, no field-level detail.
- **Cross-cutting concerns**: auth, permissions, dictionaries, shared infrastructure — yes/no and which.
- **Independent capability count**: roughly how many distinct user-facing capabilities or flows are introduced.
- **External integrations**: any new third-party or internal service touchpoints.
- **Sequencing constraints**: which parts must land before others.

### 4. Split Decision

Decide between **single requirement** and **split requirement** using these rules. Apply them at module/capability granularity, never at file/function granularity.

**Keep as a single requirement when ANY of these hold (and none of the "Split" rules clearly apply):**
- Scope is confined to a single module or a tightly coupled module pair
- Introduces at most one new capability / user-facing flow
- No cross-cutting rework across multiple applications
- A single dev session can plausibly analyze → design → implement → document it end-to-end
- The requirement is small, focused, or a bugfix-like change — do not split these

**Propose splitting when ALL of these hold:**
- The requirement introduces 2+ distinct capabilities that can be delivered and validated independently, OR spans 3+ modules that each require non-trivial work
- At least one clean architectural seam exists (e.g., schema layer vs. API layer vs. UI, or independent domain subfeatures)
- A single session would likely exceed what can be kept coherent in one context window at the design/implementation level
- Each proposed split can stand on its own as a meaningfully shippable step

**Tie-breaker:** If uncertain, prefer **not splitting**. An oversized single requirement can be re-run later; an unnecessary split multiplies coordination cost and risks inconsistency.

**Never split just because:**
- The requirement touches multiple files (that is not a split reason at the architecture level)
- You want "smaller PRs" — that is a delivery concern, not a requirement-scoping concern
- Different parts use different technologies — shared context still applies

### 5. Present the Plan and Get User Confirmation

Output a concise plan to the user in chat. Keep it terse; this is a decision document, not a design.

**If single:**

```
## Requirement Scope (single)

- Short name: <kebab-case-name>
- Summary: <1–2 sentences>
- Affected modules: <module-a, module-b>
- Key models/procedures/applications: <...>
- Complexity: <small | medium>
- Why not split: <one sentence>

Proceed to create 1 dev session directory? (yes / no / adjust)
```

**If split:**

```
## Requirement Scope (split into N)

Overall summary: <1–2 sentences>

Proposed splits:

1. <short-name-1>
   - Summary: <1–2 sentences>
   - Affected modules: <...>
   - Depends on: <none | split-#>
2. <short-name-2>
   - Summary: <1–2 sentences>
   - Affected modules: <...>
   - Depends on: <none | split-#>
...

Dependency order: <e.g., 1 -> 2 -> 3, or "1 and 2 independent, 3 depends on both">

Proceed to create N dev session directories in this order? (yes / no / adjust)
```

Wait for the user's response. Accept adjustments (rename, merge, reorder, drop, add). Iterate until the user approves explicitly. Never materialize directories before explicit approval.

### 6. Materialize Dev Session Directories

Once the user approves:

- Compute today's date folder: `<root-session-dir>/<YYYY>/<MM>/<DD>/`
- Determine the next available `<NNN>` (zero-padded, starting at `001` within the day, continuing past any existing sessions for the same date)
- For **each** approved requirement (single or split), in dependency order:
  - Directory: `<root-session-dir>/<YYYY>/<MM>/<DD>/YYYY-MM-DD-<NNN>-<short-name>/`
    - Increment `<NNN>` per directory so that dependency order matches directory order when read alphabetically
  - Write `<dev-session-dir>/requirement-raw.md` using the template below

`requirement-raw.md` template:

```markdown
# Requirement: <Short Name>

## Summary
<1–3 sentences describing what this split delivers.>

## Original Request
<Verbatim or lightly-cleaned raw requirement text from the user. If split, include the portion relevant to this split plus a one-line pointer back to the overall request.>

## Scope (coarse)
- Affected modules: <list>
- Likely models / procedures / applications touched: <list>
- Cross-cutting concerns: <list or "none">
- Out of scope for this requirement: <list or "none">

## Dependencies
<If split, list the prior dev session directories this requirement depends on, by relative path. If none, write "none".>

## Notes
<Any user clarifications captured during the confirmation round. Optional.>
```

Rules for writing the file:
- Stay at architecture granularity. Do not enumerate files, classes, or code-level tasks — those belong to the `designer` phase.
- If the user provided clarifications during confirmation, capture them under **Notes** verbatim.
- Do not invent acceptance criteria or user stories here — that is the `analyst` phase's job.

### 7. Completion

Output a short summary:

- List each created directory path
- Restate the dependency order
- Suggest the next step: run `metalclaw-dev-auto`, `metalclaw-dev-step`, `metalclaw-dev-full`, or `metalclaw-dev-lite` against each directory in order (caller's choice)

Do **not** automatically trigger any downstream skill — this skill ends at directory materialization.


## What This Skill Does NOT Do

- Does not read code or dive into implementation details
- Does not produce structured requirements, user stories, acceptance criteria, or designs (those belong to `analyst` / `designer`)
- Does not run sub-agents
- Does not split small or medium requirements just to "be safe"
- Does not materialize directories without explicit user approval

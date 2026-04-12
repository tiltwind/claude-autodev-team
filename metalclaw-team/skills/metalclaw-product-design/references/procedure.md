### Process & Rule

**Path**: `<prd-dir>/procedures/<business-group>/<module>/procedure-<procedure-name>.md`

One file per process.

```markdown
# <Process Name>

## Overview
Business purpose and applicable scenarios

## Participating Roles

| Role | Responsibilities |
|------|------------------|

## Process Steps

### Step 1: <Step Name>
- **Executing Role**:
- **Description**:
- **Input**:
- **Output**:
- **Model State Changes**:

### Step N: ...

## Business Rules

| Rule ID | Rule Name | Rule Description | Applicable Scenario |
|---------|-----------|------------------|---------------------|

## Exception Handling
Describe possible exceptions and how they are handled

## Flowchart
Describe the sequence and branching logic using mermaid flowchart syntax
```

**Principles:**
- Process steps must be consistent with model state transitions
- Business rules must be clear and verifiable
- Exception handling paths must be complete
- Use business language, no technical implementation
- Create new files for new processes; update existing files for existing processes
- Keep `procedures/procedures.md` and `procedures/<business-group>/procedures-<business-group>.md` in sync when adding or updating processes

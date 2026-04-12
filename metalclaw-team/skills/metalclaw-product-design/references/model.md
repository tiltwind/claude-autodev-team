### Model

**Path**: `<prd-dir>/models/<business-group>/<module>/model-<model-name>.md`

One file per model.

```markdown
# <Model Name>

## Overview
Business meaning and purpose of the model

## Attributes

| Attribute | Description | Type | Required | Notes |
|-----------|-------------|------|----------|-------|

## State Definitions

| State | Description | Notes |
|-------|-------------|-------|

## State Transitions

| Current State | Trigger Action | Target State | Preconditions | Post Actions |
|---------------|----------------|--------------|---------------|--------------|

## Relationships

| Related Model | Relationship Type | Description |
|---------------|-------------------|-------------|
```

**Principles:**
- Use business-semantic types for attributes (e.g., text, number, date, enum, reference to XX model), not technical types (e.g., varchar, int)
- For enum type attributes, reference dictionary definitions in `<prd-dir>/dictionaries/` rather than listing values inline
- State transitions must clearly describe trigger conditions and preconditions
- Create new files for new models; update existing files for existing models
- Keep `models/models.md` and `models/<business-group>/models-<business-group>.md` in sync when adding or updating models
- No database design or technical implementation details

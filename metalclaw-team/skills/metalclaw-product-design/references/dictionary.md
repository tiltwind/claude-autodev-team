### Dictionary

**Path**: `<prd-dir>/dictionaries/<business-group>/dictionary-<dictionary-name>.md`

```markdown
# <Dictionary Name>

## Overview
Business meaning and usage scenarios of this dictionary

## Values

| Value | Label | Description | Sort Order | Notes |
|-------|-------|-------------|------------|-------|
```

**Principles:**
- Each dictionary represents a single enum or constant group (e.g., order statuses, payment methods, user types)
- Models should reference dictionary names rather than duplicating enum values inline
- Keep `dictionaries/dictionaries.md` in sync when adding or updating dictionaries
- Values should use business-meaningful identifiers, not technical codes

### Architecture

**Path**: `<prd-dir>/architecture/architecture.md`

```markdown
# Product Architecture

## Product Overview
Overall positioning and core value of the product

## Business Modules

### <Business Group Name>
- **Description**: Business group description

#### <Module Name>
- **Responsibilities**: Core responsibilities of the module
- **Features**:
  - Feature 1
  - Feature 2
- **Related Models**: Core models involved
- **Related Processes**: Core processes involved

## Business Module Relationship Diagram
Describe dependencies and interactions between business groups and modules using mermaid syntax
```

**Principles:**
- Role definitions must be clear with no overlapping responsibilities; manage roles in `architecture/roles.md` independently
- Functional modules must be well-partitioned with high cohesion
- Architecture describes product functionality, not technical architecture (no services, databases, middleware, etc.)
- For initial design, create the complete architecture document; for changes, update only affected sections

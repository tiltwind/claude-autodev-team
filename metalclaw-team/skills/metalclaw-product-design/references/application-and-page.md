### Application & Page

**Application types:** Each application type has its own directory under `<prd-dir>/applications/<app-type>/`. Common types include (not limited to):

| Directory | Application Type | Description |
|-----------|-----------------|-------------|
| `<prd-dir>/applications/wxa/` | WeChat Mini Program | Mini program within the WeChat ecosystem |
| `<prd-dir>/applications/app/` | Mobile App | Standalone mobile application |
| `<prd-dir>/applications/h5/` | H5 Pages | Mobile web application |
| `<prd-dir>/applications/web-admin/` | Web Admin | Backend management web application |
| `<prd-dir>/applications/desktop/` | Desktop App | Desktop application |

New application types can be added by creating a new `<app-type>/` directory following the same structure.

**Application framework**: `<prd-dir>/applications/<app-type>/application-<app-type>.md`

```markdown
# <Application Name>

## Application Overview
Positioning, target users, core scenarios

## Target User Roles
System roles this application serves

## Page Framework

### Navigation Structure
Describe the overall navigation pattern (e.g., bottom tabs, sidebar, tab bar, etc.)

### Page Map

| Page | Path | Description | Module |
|------|------|-------------|--------|

### Global Components
Describe reusable global components (e.g., top navigation bar, bottom action bar, etc.)
```

**Page design**: `<prd-dir>/applications/<app-type>/pages/<business-group>/<module>/<NNN>-<page-name>.md`

```markdown
# <Page Name>

## Page Description
Purpose and entry points of the page

## Access Permissions
Which roles can access this page

## Page Structure

### Section 1: <Section Name>
- **Position**: Location within the page
- **Content**:
  - Display element 1: description
  - Display element 2: description
- **Interactions**:
  - Action 1: tap/swipe/etc. -> effect description
  - Action 2: -> effect description

### Section N: ...

## Feature Descriptions

### Feature 1: <Feature Name>
- **Trigger**: How the user triggers this feature
- **Business Logic**: Business rules to execute (reference processes and rules)
- **Related Models**: Associated data models and state changes
- **Feedback**: User feedback on success/failure

### Feature N: ...

## Data Display Rules
- **Default Sort**: Field and order (e.g., created_at descending)
- **Pagination**: Pagination strategy (e.g., paged with 20 items per page / infinite scroll)
- **Search & Filters**: Available search fields and filter conditions
- **Empty State**: What to display when no data matches
- **Error State**: What to display on data loading failure

## Page States
Describe display variations under different conditions (e.g., empty state, loading, data list, etc.)

## Page Navigation
Describe pages that can be navigated to from this page and their trigger conditions
```

**Principles:**
- Page design focuses on information display and user interaction, no technical implementation
- Reference existing models, processes, and rules for consistency
- Structure pages by sections, clearly describing content and interactions in each section
- Create new files for new pages; update existing files for existing pages
- Keep `application-<app-type>.md` page map, `pages/pages-<application-name>.md`, `pages/<business-group>/pages-<business-group>.md` and `pages/<business-group>/<module>/pages-module-<module-name>.md` in sync when adding or updating pages

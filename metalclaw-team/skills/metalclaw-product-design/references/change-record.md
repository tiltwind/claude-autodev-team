### Change Record

**Path**: `<root-session-dir>/changes/<YYYY>/<MM>/<DD>/<YYYY-MM-DD-NNN-req-name>/`

- `requirement-raw.md` — original requirement from user
- `requirement.md` — structured requirement document

**Structured requirement format:**

```markdown
## <Requirement Title>

### Background & Objectives
### User Stories & Acceptance Criteria
### Scope Boundaries
### System Roles
### Models & States
### Business Processes & Rules
### Applications & Pages
### Non-functional Requirements
- **Data Scale**: Expected data volume and growth (e.g., max list items, concurrent users)
- **Performance Expectations**: Response time requirements for key operations
- **Data Security & Privacy**: Fields requiring masking, encryption, or access control
- **Compatibility**: Minimum supported platform versions or browsers
```
As a software developer. Your job is to implement code according to the design and write unit tests.

## Startup

1. Read `.claude/autodev/ACTIVE` to get current autodev directory path
2. Read `<current-autodev-dir>/4-design-final.md` for the final design
3. Check if any `<current-autodev-dir>/integrations-error-*.md` files exist (WITHOUT `-DONE` suffix) - these are bugs to fix
4. Write `developer` to `<current-autodev-dir>/STATE`

## Task

### Normal Development Mode (no unfixed error files)
1. Implement the design `4-design-final.md`
2. Write unit tests and verify they pass

### Bug Fix Mode (unfixed integrations-error files exist)
1. Read all `integrations-error-*.md` files (WITHOUT `-DONE` suffix)
2. Analyze each error and identify root cause
3. Fix the code issues
4. Re-run the failing tests to verify fixes
5. Rename each fixed error file: `integrations-error-<N>.md` -> `integrations-error-<N>-DONE.md`

## Output

- Source code and Unit test files
- If fixing bugs: rename error files to add `-DONE` suffix

After completing, output:
```
[autodev:developer:done] <dir-path>
```

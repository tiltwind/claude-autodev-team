Step 1: git  diff
Step 2: Review the diff output. Determine the commit type and message.
    - Types: feat | fix | refactor | docs | test | chore
    - Format: <type>: <short description>
    - NEVER stage .env, credentials, or secret files
Step 3: git  add -A
Step 4: git  commit -m "<your commit message>"
    - NO `Co-Authored-By` in the commit message
Step 5: git  push
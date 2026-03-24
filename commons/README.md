# Commons

Shared commands and skills that can be installed into any project.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/tiltwind/claude-autodev-team/main/commons/scripts/install.sh | bash
```

This creates symlinks in the project's `.claude/commands/` and `.claude/skills/` directories pointing back to commons, so updates to commons are reflected everywhere.

## Structure

```
commons/
├── commands/       # Slash commands (.md files)
│   └── gitpush.md  # Git diff, commit, and push workflow
├── skills/         # Skills (.md files or subdirectories)
└── scripts/
    └── install.sh  # Symlink commands & skills into a project
```

## Adding new commands or skills

1. Add a `.md` file to `commands/` or `skills/`
2. Re-run `install.sh` on each project to pick up the new files

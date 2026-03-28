# Obsidian Vault — Rules

This vault is the agent's persistent brain. All relevant knowledge between sessions lives here.

## Structure

```
boot/           → Read ALWAYS on startup (state, identity, stack)
projects/       → One directory per project
knowledge/      → Tech, patterns, general solutions
queue/          → Pending tasks, follow-ups, reminders
logs/           → Session and work log
scratch/        → Temporary WIP, cleaned periodically
vault/          → Sensitive data, never leaves the VPS
```

## Conventions

- File names: kebab-case (e.g., `my-project.md`, `drizzle-migrations.md`)
- Frontmatter: always include `tags` and `updated` at minimum
- Links: use [[wikilinks]]
- Dates in file names: YYYY-MM-DD (e.g., `2026-03-28.md`)

## Rules

1. `boot/state.md` is read on startup and updated at the end of every significant work
2. Don't create new folders unless necessary — use the existing structure
3. Flat over nested — don't nest more than 2 levels (area/project/file)
4. If something in `scratch/` is finalized, move it to its proper place
5. `vault/` is never committed, never shared, never mentioned
6. Don't duplicate information from code or git — reference instead of copying
7. Delete obsolete notes instead of accumulating clutter

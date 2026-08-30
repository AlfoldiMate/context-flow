---
description: Inspect, tidy, or migrate this project's agmem memory — show what the store holds, consolidate duplicates and contradictions, import a legacy LEDGER.md.
argument-hint: "[show | tidy | import]"
allowed-tools: Read, Bash, Glob, mcp__agmem__context, mcp__agmem__recall, mcp__agmem__inspect, mcp__agmem__consolidate, mcp__agmem__remember, mcp__agmem__reflect, mcp__agmem__forget
---

# agmem

Operate on this project's memory store according to `$ARGUMENTS` (default:
`show`). The space derives from the repo automatically; you never name it
except where noted.

## show

`inspect` with `ref: "stats"` for the counts, then `context` with no query for
the general briefing. Report: live claims by kind for this project's space and
`user`, the briefing itself, and one line of assessment — is anything in it
stale, wrong, or contradicted by what the repo says right now? A claim worth
doubting gets `inspect` on its id (provenance and correction history), not a
hedge.

## tidy

Run `consolidate`, then judge each list — it decides nothing itself, and empty
lists are the healthy outcome, not a failure:

- **near_duplicates** — merge a group with one `remember`: the wording worth
  keeping, `supersedes` set to every other member's id. Check
  `min_similarity` first: it is the weakest pair anywhere in the group, so a
  low value means the cluster chained through a middle claim and may be two
  claims, not one. Never `forget` a duplicate — that deletes the history the
  merge exists to keep.
- **contradictions** — read both; nothing has judged that they disagree. When
  one is wrong, send the right one with the wrong one's id in `supersedes`.
  When both are right (scope differs), leave them.
- **stale_contexts** — a `fast` claim recall kept alive: if it proved durable,
  re-store it with a slower `decay_class` (superseding the fast one); if it
  was scaffolding, `forget` it.

Report what you merged, corrected, and expired, in at most five lines.

## import

One-time migration of pre-agmem file memory. Resolve the legacy paths:

```bash
nu "$CLAUDE_PROJECT_DIR/.claude/hooks/scripts/ctx-flow-paths.nu"
```

Then, for whichever of these exist — `LEDGER=`, every file under
`.claude/notes/state/`, and every `.claude/playbooks/<role>.md`:

1. Read the file. Distil each entry into one atomic, third-person claim —
   ledger decisions and map entries → `fact` (set `valid_from` from the
   entry's date where it carries one), gotchas → `lesson`, playbook rules →
   `lesson` tagged `role:<role>`, branch state → `fact` with `decay_class:
   fast` tagged with that branch's `branch:<slug>` tag. A rule the ledger
   states as binding every session → `instruction`, sparingly.
2. Send each file's claims in one `remember` call with the raw file text as
   the `episode`, so every imported claim stays provenanced to what it came
   from. Read the reply: `duplicates` means the store already knew it — fine,
   move on.
3. Skip what the repo already records (git history, code, CLAUDE.md) and any
   entry whose reason has evaporated — import is also a prune, and dropping
   entries is normal.
4. Rename each imported file to `<name>.imported` in place — keep it on disk;
   the `.imported` suffix is what stops a second import and marks the store
   as the live copy. Deleting is the user's call, later.

Report per file: entries seen, claims stored, entries dropped. If none of the
legacy files exist, say the project has no pre-agmem memory and stop.

Never `forget --purge` anything during any of these modes without the user
confirming first.

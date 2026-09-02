---
description: Store the session's durable state in agmem so you can safely /clear instead of letting /compact fire.
argument-hint: "[optional: what to emphasise]"
allowed-tools: Read, Bash, Glob, Grep, mcp__agmem__recall, mcp__agmem__remember, mcp__agmem__reflect, mcp__agmem__inspect, mcp__agmem__consolidate
---

# Checkpoint

Store memory so that a fresh session — with none of this context — could pick
the work up without asking a single question. Memory lives in **agmem**: the
space derives from the repo's shared git dir, so every branch and worktree
writes to one store and there are no paths to resolve. You do the distilling;
agmem stores what you send and never rewrites it.

Get the branch tag first — the same resolver the SessionStart nudge uses, so
the two sides cannot drift:

```bash
nu "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/scripts/ctx-flow-paths.nu"
```

`TAG=` is the tag for branch-scoped claims (empty on a detached HEAD — then
everything is durable or nothing). Ignore `LEDGER=`/`STATE=`; they are legacy
locations for `/agmem import`.

## The ritual, in order

1. **Distil.** List what this session established that is durable and
   **non-obvious**: decisions *and their reasons* (the reason is the valuable
   half — "used a channel because the mutex version deadlocked under the retry
   path", never just "used a channel"); corrected assumptions (the
   highest-value entry type — a fresh session will make the same wrong
   assumption); map facts for files whose purpose their path does not state;
   gotchas that cost real time and would again. One atomic, self-contained
   claim per entry, third person, meaningful with no conversation around it.

2. **Recall before writing.** For each topic you are about to store, `recall`
   it first. This step gets skipped under momentum — measured, not
   hypothetical — and skipping it stores contradictions instead of
   corrections. A claim that updates an earlier one is sent with `supersedes:
   [<old id>]`, which closes the old claim but keeps it readable and dated.

3. **Store with the right kind** (table below), batched into as few `remember`
   calls as the content allows. Then **read the reply**: `duplicates` were
   *not* written and `related` sit alongside what was — if either contains a
   claim yours contradicts, re-send with `supersedes` set to its id, or the
   live claim is still the wrong one.

4. **A conclusion you worked out goes through `reflect` instead.** If one of
   your candidates is something you concluded *from* what step 2 returned —
   the cause behind three separate failures, what a preference and a
   constraint mean taken together — store that one with `reflect`: the
   insight, and `derived_from` set to the ids you drew it from. Same write,
   with the evidence attached, so a later session can check the conclusion
   rather than take it on faith. Something you were simply told is not this;
   it belongs in the batch above.

5. **Branch state.** What is done *and verified*, the immediate next action,
   what is blocked on what — as `fact`s with `decay_class: fast` and the
   `TAG=` tag. They fade in days and are pruned automatically, which is the
   point: branch state should die with the branch.

6. **Gate proposed learnings** (section below).

If `$ARGUMENTS` is non-empty, make sure that topic is covered explicitly.

## What kind

| What | kind | decay | tags / entities |
|---|---|---|---|
| Decision + reason, corrected assumption, map fact | `fact` | default | entities: the subsystem or file |
| Gotcha, hard-won how-to | `lesson` | default (slow) | — |
| Standing rule for every future session | `instruction` | pinned — lands in every briefing, so be sparing | — |
| Role-specific learning (accepted `LEARNED:`) | `lesson` | default | tag `role:<agent>` |
| Branch state (Done/Next/Blocked) | `fact` | `fast` | the `TAG=` tag |
| A conclusion drawn *from stored memories* | use `reflect` with `derived_from` | — | — |

Verbatim text worth keeping as ground truth — an error transcript, a user
requirement stated exactly — goes in the same `remember` call as `episode`;
every claim in that call is provenanced to it. Sparingly: episodes are for
text whose exact wording matters, not a session diary.

## What to leave out

Anything git records. Anything the code says plainly. Anything true only for
the current turn. Narrative of what happened — memory holds state, not logs.
Long tool output is not memory at all: it goes to a file under
`.claude/notes/` with a one-line pointer claim if it needs finding again.

## Proposed learnings

Subagents may end a response with `LEARNED: <claim> — <evidence>`. Those are
**proposals**. This command is where they are accepted or dropped — that
separation is deliberate: the agent proposing a rule is often the cheapest,
least informed thing in the system, and rules it writes bind every future run.

For each proposal from this session, apply all four tests. Store it only if it
passes all of them:

1. **Durable** — true of this project, not of this task.
2. **Non-obvious** — not something the repo, a type, or a test already says.
3. **Earned** — seen more than once, or once at real cost. A single cheap
   surprise is an anecdote.
4. **Actionable** — it changes what a future run would *do*. "The parser is
   complex" changes nothing.

An accepted proposal becomes a `lesson` tagged `role:<agent>`, with the
evidence in the claim itself ("… — proved by the 2026-08-30 retry-path
deadlock"), because a rule whose reason is invisible cannot be pruned honestly
later. A proposal that binds *every* session, not just one role, becomes an
`instruction` — rare, and worth a second look before pinning.

Before storing, `recall` with the same `role:` tag: if an existing rule
contradicts the new one, resolve it now with `supersedes` — two opposing rules
are worse than neither.

**Dropping a proposal is the common outcome and needs no justification.** Say
how many you saw and how many you kept, and move on.

## Legacy files

If `.claude/notes/LEDGER.md` exists, this checkout predates agmem — run
`/agmem import` once to move its contents into the store.

## Then

Report in three lines: how many claims stored by kind, how many superseded,
and proposals seen vs kept. Then tell the user they can safely `/clear` — and
that this is better than letting auto-compaction fire, because the memory is
now in the store and the SessionStart hook will point the next session at it.

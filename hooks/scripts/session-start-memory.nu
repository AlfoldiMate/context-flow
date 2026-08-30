#!/usr/bin/env nu
# SessionStart: put the session's memory in front of it. Durable state lives
# in agmem — a per-project space derived from the repo's shared git dir — and
# since agmem 0.1.2 the briefing is *pushed*: `agmem context` prints the same
# block the MCP `context` tool assembles, so the hook injects it before the
# first token instead of hoping the model calls the tool. The one-shot rides
# the shared daemon (attaching, or starting one the session then reuses), so
# it never contends with the session's own agmem for the store.
#
# Every miss degrades one step, never breaks the start: an older binary or an
# unreachable store falls back to the pull nudge (the MCP path still works),
# no binary at all reports memory offline, and the branch tag is pre-computed
# in all three shapes so the write side (/checkpoint) and the read side
# (recall) agree on it.
#
# When the session (re)starts because of a compaction, the payload says so
# (`source: "compact"`), so the truncation warning needs no marker file.
const COMMON = path self "_common.nu"
use $COMMON *

const HEADER = ("Durable project memory lives in agmem, not in this window. Before the first "
    + "move, call mcp__agmem__context with a short query naming the work at hand, and treat "
    + "the briefing as established fact — do not re-derive what it records; verify a specific "
    + "claim only before acting on it. mcp__agmem__recall reaches what the briefing omits; ask "
    + "in words, not keywords. A claim that turns out to be stale is corrected with remember + "
    + "supersedes (its id ends its line), never worked around. /checkpoint stores this "
    + "session's durable state back. If no mcp__agmem__* tools are in this session, the server "
    + "is not registered — /ctx-flow-doctor prints the fix.")

const FOOTER = ("The block above is this project's memory briefing (agmem). Treat it as "
    + "established fact — do not re-derive what it records; verify a specific claim only "
    + "before acting on it. mcp__agmem__recall reaches what it omits; ask in words, not "
    + "keywords. A claim that turns out to be stale is corrected with remember + supersedes "
    + "(its id ends its line), never worked around. /checkpoint stores this session's durable "
    + "state back.")

const OFFLINE = ("Durable project memory is configured to live in agmem, but no agmem binary "
    + "is on PATH — memory is offline this session. /ctx-flow-doctor prints the fix.")

const COMPACTED = ("NOTE: context was compacted immediately before this. Anything not in agmem "
    + "or on disk is gone — re-read files before assuming their contents, and do not trust "
    + "remembered line numbers.")

# The briefing block, or null when this binary or this store cannot serve one
# — an old agmem refuses the subcommand and a broken store exits non-zero, and
# both leave the pull path as good as it ever was.
def brief [cwd: string]: nothing -> any {
    let r = try { do { cd $cwd; ^agmem context } | complete }
    if ($r.exit_code? | default 1) == 0 and ($r.stdout | str trim | is-not-empty) {
        $r.stdout | str trim
    } else { null }
}

def prime [p: record] {
    let cwd = cwd-of $p
    let branch = branch-of $cwd

    let branch_note = if $branch == null { "" } else {
        ($" In-flight state for the current branch \(($branch)) carries the tag "
            + $"branch:(slug $branch) — recall with that tag when resuming work here.")
    }

    let memory = if (which agmem | is-empty) { [$OFFLINE] } else {
        let block = brief $cwd
        if $block == null { [$"($HEADER)($branch_note)"] } else {
            [$"($block)\n\n($FOOTER)($branch_note)"]
        }
    }

    let warn = if ($p.source? | default "") == "compact" { [$COMPACTED] } else { [] }
    let mismatch = layout-check $cwd
    let parts = $warn
        | append (if $mismatch == null { [] } else { [$mismatch] })
        | append $memory
    if ($parts | is-not-empty) { context "SessionStart" ($parts | str join "\n\n") }
}

def main []: any -> nothing {
    let p = $in | payload
    try { prime $p }
}

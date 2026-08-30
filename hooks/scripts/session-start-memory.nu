#!/usr/bin/env nu
# SessionStart: point the session at its memory. Durable state lives in agmem
# — a per-project space derived from the repo's shared git dir — and agmem is
# pull-based: the model has to call mcp__agmem__context to get its briefing. A
# hook cannot make an MCP call, but it can say so deterministically at every
# start, with the branch tag pre-computed so the write side (/checkpoint) and
# the read side (recall) agree on it. This is the half of the loop that makes
# /clear cheap — clear the window, and the first move brings memory back.
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

const OFFLINE = ("Durable project memory is configured to live in agmem, but no agmem binary "
    + "is on PATH — memory is offline this session. /ctx-flow-doctor prints the fix.")

const COMPACTED = ("NOTE: context was compacted immediately before this. Anything not in agmem "
    + "or on disk is gone — re-read files before assuming their contents, and do not trust "
    + "remembered line numbers.")

def prime [p: record] {
    let cwd = cwd-of $p
    let branch = branch-of $cwd

    let memory = if (which agmem | is-empty) { [$OFFLINE] } else {
        let branch_note = if $branch == null { "" } else {
            ($" In-flight state for the current branch \(($branch)) carries the tag "
                + $"branch:(slug $branch) — recall with that tag when resuming work here.")
        }
        [$"($HEADER)($branch_note)"]
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

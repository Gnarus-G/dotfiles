---
name: fix-loop
description: Keep finding and fixing problems toward a stated goal without waiting for a prompt per step — find the next issue, fix it in a worktree, /ship it, re-check, repeat. Use when told "let's continue identifying and fixing issues", "keep going until X passes", or "pick the next low hanging fruit".
---

# fix-loop

Invoked as `/fix-loop [goal]`. Without a goal, read the active goal file
(`/goal`). The loop ends when the goal's check passes or a stop condition
hits — not when one fix lands.

## Each round

1. **Look.** Re-read the goal file. Check the current state against it:
   UI errors, failing tests or checks, logs, open issues assigned to or
   authored by the user (only those).
2. **Pick one** problem: the cheapest one that moves the goal. Say which
   and why in one line.
3. **Root cause** before fixing (`systematic-debugging`). The fix removes
   the cause; no band-aids, no arbitrary timers or sleeps.
4. **Fix** in a worktree, one small PR, test first where it helps.
5. **`/ship`** it to the environment the goal names.
6. **Re-check** the thing from step 1. Show before/after.
7. **Clean old noise** the fix made obsolete (stale records, old errors) so
   the next look is honest.

Repeat. Between rounds print one status line:
`round N · fixed <x> (#PR) · next: <y> · goal: <met | not met: why>`.

## Stop and ask

- A decision only the user can make (design trade-off, scope, money).
- Two rounds in a row did not move the goal.
- Anything `/ship` stops on.
- A problem outside the goal's scope: file an issue, link it, move on.

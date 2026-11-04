---
name: goal
description: Keep one written file per effort with the goal, the fixed facts and the user's corrections, and re-read it before planning, proposing or declaring done. Use when starting or resuming a multi-day effort, when the user restates a goal or constraint, when the user corrects a fact ("I already told you", "remember", "we never need that"), or before saying work is finished.
---

# goal

Most rework comes from forgetting what was already decided, not from bad
code. This skill writes decisions down and reads them back.

## The file

`plans/<effort>.goal.md` in the repo (or `~/.claude/goals/<effort>.md`
outside a repo). Short. Shape:

```markdown
# <effort>

Goal: <one sentence: what done looks like>
Done when: <the check that proves it>

## Facts (do not re-ask, do not contradict) — example entries
- Book depth is 100. Never test or mention 1000/2000.
- Every connection is a raced pool of redundant sockets. Never one socket.
- Crypto markets only.
- Never touch the mainnet env.

## Out of scope
- <thing> — <why>

## Corrections log
- 2026-10-30: proposed one socket; user: "we always race connections".
```

## When to use it

- **Start/resume an effort:** read it; if missing, write it from the user's
  words and the issue, show it, ask for one-line confirmation.
- **The user states a constraint or corrects you:** add it to Facts and the
  Corrections log in the same turn. Say "added to goal file".
- **Before a plan, proposal or recommendation:** check it against Facts.
  If it conflicts, drop it or say why the fact should change.
- **Before saying done:** run the "Done when" check and show the result.
- **Scope drift:** work not serving the goal gets an issue, not a detour.

Keep the file under ~40 lines. Delete facts that stop being true.

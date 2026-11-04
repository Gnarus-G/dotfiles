---
name: where-are-we
description: One status report for the current effort — the goal, what is done, what is left, what is blocked and on whom — gathered from plans, issues, PRs, checklists and deployed state. Use when asked "what's next?", "what's left, across everything, unchecked/undone?", "where are we?", "what have we accomplished?", "are we done?", or after a break ("catch up to speed").
---

# where-are-we

Read-only. Invoked as `/where-are-we [issue|plan]`. Without an argument,
use the active goal file (`/goal`), else the plan or issue this session
worked on.

## Gather (in parallel)

- Goal file and the plan (e.g. `plans/`, `docs/`).
- The tracking issue: body checkboxes and the latest status comment.
- Open PRs of this effort (`gh pr list --author @me`, linked PRs): CI state,
  unanswered reviews, merged-but-not-deployed.
- What actually runs in each environment vs. merged main.
- Checklists or sheets the effort keeps.
- Waiting on others: vendor threads, teammates' PRs, pending logins.

Docs and checkboxes lag reality. A row is "done" only with evidence you
looked at this session (merged PR, running build, passing run).

## Report shape

```
Goal: <one sentence>

Done
- <item> — <evidence: PR / run / deploy>

Left (cheapest first)
- <item> — <next action>

Blocked
- <item> — waiting on <who/what> since <date>

Next: <the one thing to do now>
```

Then fix drift you found: tick checkboxes that are done, update the plan's
"what's left". Say what you changed. Do not start the next item unless
asked.

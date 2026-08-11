---
name: commit
description: Use when asked to commit or create a commit; stages session changes and infers conventions from repository history.
---

# Commit

## Routing

If you are the primary agent, do not run Git commands for this workflow;
delegate to the custom `commit` subagent and include the exact paths changed in
this session. If that subagent is unavailable, report that instead of executing
the workflow inline.

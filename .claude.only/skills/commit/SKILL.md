---
name: commit
description: Use when asked to commit or create a commit; stages session changes and infers conventions from repository history.
context: fork
model: haiku
effort: low
background: false
---

# Commit

Use the conversation and tool history to identify the exact files changed in
this session; never guess from the worktree.

Run exactly one command: `git-ac -y -- <paths>`, replacing `<paths>` with only
those files, then report its commit hash and subject; do not inspect the
repository or run any other command.

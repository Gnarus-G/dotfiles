---
name: commit
description: Use when asked to commit or create a commit; stages session changes and infers conventions from repository history.
---

# Commit

Use the conversation and tool history to identify the exact files changed in
this session; never guess from the worktree.

Run exactly one command directly: `git-ac -y -- <paths>`, replacing `<paths>`
with only those files, each quoted as a separate shell argument, then report
its commit hash and subject; do not inspect the repository or run any other
command.

`git-ac` generates the message through the Codex subscription first and falls
back to Ollama on failure; do not select a model or start another agent around
it, since that agent can fail before reaching the fallback.

If no exact paths are known, ask for them; if the command fails, report its
output without retrying or changing the requested scope.

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

If you are the `commit` subagent, stage and commit the paths supplied by the
delegating agent using the workflow below.

## Workflow

1. Treat only paths named in the delegation prompt as session changes; inspect
   `git status --short` plus their staged and unstaged diffs.
2. If no paths were supplied, stop and report that without staging or
   committing; never guess from the worktree.
3. Stage exactly those files with `git add -- <paths>`; never use `git add -A`,
   `git add .`, or include unrelated changes already present in the worktree.
4. Inspect the resulting staged diff and recent commit messages, preferring
   history touching the same files or subsystem when useful; stop if the staged
   diff contains changes outside this session.
5. Infer the repository's conventions from history, including subject format,
   prefixes or scopes, capitalization, mood, body usage, and line length.
6. Write a message that describes the staged change and its purpose while
   following those inferred conventions; do not mention the model or include
   Markdown commentary.
7. Commit non-interactively without amending or bypassing hooks, then report
   the new commit hash and subject.

Do not commit suspected secrets, unrelated staged changes, merge conflicts, or
changes the user did not authorize; report the issue instead.

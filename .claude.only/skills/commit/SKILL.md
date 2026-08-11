---
name: commit
description: Use when asked to commit or create a commit; stages session changes and infers conventions from repository history.
context: fork
model: haiku
effort: low
background: false
---

# Commit

Stage and commit the files changed in this session.

1. Use the conversation and tool history to identify the files changed in this
   session; inspect `git status --short` plus their staged and unstaged diffs.
2. If no session changes can be identified, stop without staging or committing;
   never guess from the worktree.
3. Stage exactly those files with `git add -- <paths>`; never use `git add -A`,
   `git add .`, or include unrelated worktree changes.
4. Inspect the resulting staged diff and relevant recent commit messages; stop
   if the staged diff contains changes outside this session.
5. Infer subject format, prefixes or scopes, capitalization, mood, body usage,
   and line length from repository history.
6. Commit non-interactively without amending or bypassing hooks, then report
   the new commit hash and subject.

Do not commit suspected secrets, unrelated changes, merge conflicts, or changes
the user did not authorize.

---
description: Use when the user asks to commit; stage exact session files and infer repository conventions from history.
mode: subagent
model: openai/gpt-5.6-luna
permission:
  edit: deny
  bash:
    "*": deny
    "git add*": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git commit*": allow
---

You are the `commit` subagent; load and execute the `commit` skill workflow,
treating only paths named in the delegation prompt as session changes.

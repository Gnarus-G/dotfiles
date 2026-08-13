---
name: claude-implement
description: Use when large code work or other token-heavy drudgery can be offloaded to Claude to save Codex tokens.
---

# Claude Implement

Delegate with enough context for Claude to work independently:

```bash
cd /path/to/project
claude -p "<task and context>" \
  --model opus \
  --dangerously-skip-permissions
```

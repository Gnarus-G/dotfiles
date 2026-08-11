---
name: codex-implement
description: Use when implementation can be offloaded to Codex to save Claude tokens.
---

# Codex Implement

Delegate with enough context for Codex to implement and verify the change:

```bash
codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" \
  -s danger-full-access -C /path/to/project \
  "<task, context, and expected result>"
```

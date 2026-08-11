---
name: codex-computer-use
description: Use when runtime or UI verification can be offloaded to Codex to save Claude tokens.
---

# Codex Computer Use

Delegate the verification with enough context for Codex to work independently:

```bash
codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" \
  -s danger-full-access -C /path/to/project \
  "Run <command>, test <flow>, and report what worked or failed."
```

---
name: codex-second-opinion
description: Use when an independent code check can be offloaded to Codex to save Claude tokens.
---

# Codex Second Opinion

Ask a neutral question so Codex reaches its own conclusion:

```bash
codex exec -m gpt-5.6-sol -c model_reasoning_effort="high" \
  -s danger-full-access -C /path/to/project "<neutral question>"
```

Check its conclusion against the code before reporting it.

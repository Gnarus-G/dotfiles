---
name: codex-review
description: Use when a code review can be offloaded to Codex to save Claude tokens.
---

# Codex Review

Delegate the diff and ask only for concrete current failures relevant to the stated goal and realistically reachable scenarios:

```bash
{ echo "Find concrete correctness bugs in this diff that are relevant to its stated goal and realistically reachable scenarios. Omit speculative corrections and report no issues if none exist.";
  git diff main...HEAD;
} | codex exec -m gpt-5.6-sol -c model_reasoning_effort="high" \
  --skip-git-repo-check -
```

Verify every finding and discard false positives, findings outside the goal, hypothetical scenarios we will not hit, and non-YAGNI suggestions.

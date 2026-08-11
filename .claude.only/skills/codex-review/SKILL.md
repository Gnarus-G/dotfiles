---
name: codex-review
description: Use when a diff needs an independent, correctness-focused Codex review whose findings will be verified and filtered for YAGNI.
---

# Codex Review

Delegate correctness and logic review to `codex exec` with high reasoning.
Keep API design, naming, and other taste-sensitive review inline.

## Workflow

1. Identify the diff, commit, or files to review.
2. Create an artifact directory: `ARTIFACTS=$(mktemp -d /tmp/codex-review.XXXX)`.
3. Prefer piping the diff through stdin:

   ```bash
   { echo "Review this diff for correctness bugs. Give file, line, severity,
      and a concrete current failure scenario for each finding. Do not suggest
      speculative hardening, future-proofing, cleanup, or unrelated changes.
      Explicitly report no issues if no current bug exists.";
      git diff main...HEAD;
   } | codex exec -m gpt-5.6-sol -c model_reasoning_effort="high" \
     --skip-git-repo-check - > "$ARTIFACTS/report.md"
   ```

   Use `danger-full-access` in a scratch worktree only when repository context
   is necessary.

4. Verify every finding against the code before presenting it. Discard false
   positives and anything without a concrete failure in the current scope,
   including speculative hardening, future-proofing, and cleanup.
5. Present only verified, YAGNI-compliant findings.

Include relevant project rules in the prompt and split large diffs by area.
Treat Codex as an extra reviewer, never the sole review for critical changes.

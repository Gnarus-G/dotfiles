---
name: codex-second-opinion
description: Use when a disputed or consequential code claim needs an independent Codex opinion.
---

# Codex Second Opinion

Ask `codex exec` with high reasoning to reach a conclusion from the code alone.
Do not reveal your conclusion or use this skill for style opinions.

## Workflow

1. Turn the claim into neutral, falsifiable questions with function names or
   line numbers.
2. Prefer piping enough labeled code through stdin to support or refute the claim:

     ```bash
      { echo "<neutral questions>";
        echo "=== <file and lines> ===";
        sed -n '<start>,<end>p' <file>;
      } | codex exec -m gpt-5.6-sol -c model_reasoning_effort="high" \
        - 2>/dev/null
      ```

   Use `danger-full-access` in a scratch worktree only when whole-repo context
   is necessary.
3. Require citations and `not found` instead of guessing.
4. Re-read cited code yourself, especially when Codex disagrees.
5. Report whether the independent opinion agreed or disagreed and why you
   accepted or rejected it.

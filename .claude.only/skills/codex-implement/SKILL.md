---
name: codex-implement
description: Use when Codex can implement a bounded task with a clear specification and objective checks.
---

# Codex Implement

Delegate mechanical, repetitive, or clear-spec implementation to `codex exec`
with medium reasoning. Keep exploratory, hot-path, and taste-sensitive work inline.

## Workflow

1. State the exact change and verification command. Do not delegate an
   implementation whose completion criteria are unclear.
2. Create a worktree:

   ```bash
   git -C <repo> worktree add /tmp/codex-impl-<topic> -b codex/<topic>
   ```

3. Run Codex in the worktree:

   ```bash
   codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" \
     -s danger-full-access -C /tmp/codex-impl-<topic> \
      "<exact change, relevant files, verification command, and commit message>"
   ```

4. Review the diff and run the verification yourself.
5. Merge or discard the worktree, then remove it and run `git worktree prune`.

Give Codex one self-contained task per invocation. Never use the main working
tree, let Codex push, or delegate correctness-critical code.

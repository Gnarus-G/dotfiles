---
name: claude-implement
description: Use when Claude should handle implementation or analysis in an isolated worktree.
---

# Claude Implement

Delegate through `claude -p` and choose the cheapest suitable model:

- **Haiku 4.5:** short, straightforward tasks.
- **Sonnet 5:** well-defined, medium-sized tasks.
- **Opus 5:** complex or judgment-heavy tasks.

Use Codex for mechanical work and keep hot-path edits inline.

## Workflow

1. State the outcome, relevant constraints, and verification command.
2. Create a worktree:

   ```bash
   git -C <repo> worktree add /tmp/claude-impl-<topic> -b claude/<topic>
   ```

3. Run Claude headless:

   ```bash
    claude -p "<exact task, files, constraints, check, and commit message>" \
      --model <model> \
     --dangerously-skip-permissions \
     -C /tmp/claude-impl-<topic>
   ```

4. Review the diff and run the verification yourself.
5. Merge or discard the worktree, then remove it and run `git worktree prune`.

Give Claude one self-contained task per invocation. Never use the main working
tree or let Claude push.

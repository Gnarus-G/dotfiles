---
name: claude-implement
description: Use when a large coding task or other token-heavy drudgery should be delegated to Claude.
---

# Claude Implement

Delegate large implementations, broad codebase work, repetitive edits, and
token-heavy analysis through `claude -p`; choose the cheapest suitable model:

- **Haiku 4.5:** short, straightforward tasks.
- **Sonnet 5:** well-defined, medium-sized tasks.
- **Opus 5:** complex or judgment-heavy tasks.

Keep small tasks and precision-sensitive hot-path edits inline.

## Workflow

1. State the outcome, relevant constraints, and verification command.
2. Run Claude headless in the target project:

   ```bash
    claude -p "<exact task, files, constraints, check, and commit message>" \
      --model <model> \
      --dangerously-skip-permissions \
      -C /path/to/project
   ```

3. Review the diff and run the verification yourself.

Give Claude one self-contained task per invocation and do not let it push.

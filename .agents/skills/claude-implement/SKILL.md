---
name: claude-implement
description: Delegate taste-sensitive or judgment-heavy implementation to Claude Opus 4.8 via the headless `claude -p` CLI — API/SDK design, naming, UX, copy, code-quality decisions, and exploratory work where the spec emerges while coding. Use when the task needs taste or judgment that bounded Codex work does not. Claude works in an isolated git worktree; you review and verify the result before it merges.
---

# Claude Implement

Delegate to Claude Opus via `claude -p` (headless print mode). Good fits:

- **Taste-sensitive implementation** — API/SDK design, naming, UX, copy,
  and code-quality judgment. Claude has higher taste than GPT-5.6 Sol here.
- **Judgment-heavy or exploratory work** — the spec emerges while coding,
  or correctness depends on tradeoffs that cannot be reduced to objective
  done-criteria.

Bad fits: bounded mechanical implementation, bulk analysis, large logs or
specs, and conclusion-only digging. Route those to Codex; use Claude when its
judgment or taste changes the result, not merely to save context.

## Workflow

1. **Scope the task.** State the design judgment Claude owns and write
   objective done-criteria it can self-check ("compiles with `cargo check -p
   X`", "tests pass").

2. **Isolate writes in a worktree** so Claude never touches your working
   tree:

   ```bash
   git -C <repo> worktree add /tmp/claude-impl-<topic> -b claude/<topic>
   ```

3. **Run Claude headless with Opus.** `-p` prints and exits;
   `--dangerously-skip-permissions` lets it edit/run without prompts:

   ```bash
   claude -p "<one plain paragraph: exact task, files/paths, the check
     command to run, and — for implementation — commit the result with
     message '<msg>'. If you cannot complete it, say exactly what
     blocked you.>" \
     --model opus \
     --dangerously-skip-permissions \
     -C /tmp/claude-impl-<topic>
   ```

4. **Review the result yourself.** Read the diff
   (`git diff main...claude/<topic>`) — you own final correctness, taste,
   and conformance with the repo.

5. **Run the verification** (the done-criteria commands) yourself; don't
   trust the claim that they passed.

6. Merge/rebase per the repo's rules, or discard — a dead worktree costs
   nothing. Clean up: `git worktree remove --force ... && git worktree
   prune`.

## Prompting

- Fully self-contained: Claude can't see your session. Include paths,
  exact commands, expected outcome, and any project constraints that
  matter for THIS task.
- One task per invocation. A list of tasks becomes a loop of separate
  `claude -p` calls, not one mega-prompt (drift, timeouts).
- Require an explicit **"blocked by X"** statement when it cannot complete
  the task.
- A nonzero exit doesn't always mean failure — check the worktree diff or
  the returned text before rerunning.

## Guardrails

- Never point Claude at your main working tree or let it push.
- Escalate to Claude for quality, not to dodge bounded work — if you can
  hit the bar yourself, do it; Claude tokens cost real money.

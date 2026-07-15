---
name: claude-implement
description: Delegate implementation or analysis to Claude via the headless `claude -p` CLI. Use Haiku 4.5 for short, straightforward, latency-sensitive tasks; Sonnet 5 for well-defined medium-length work; and Opus 4.8 for complex tasks needing deeper reasoning, stronger judgment, or greater reliability. Claude works in an isolated git worktree for writes; you review and verify the result.
---

# Claude Implement

Delegate through `claude -p` (headless print mode). Choose the cheapest model
that can hit the bar:

- **Haiku 4.5** — short, straightforward work where speed matters:
  classification, extraction, concise summaries, simple transformations, and
  bounded subagent tasks. Avoid it for sustained reasoning or taste.
- **Sonnet 5** — well-defined, medium-length implementation or analysis with
  a clear outcome. It balances speed, cost, and capability.
- **Opus 4.8** — complex or demanding work needing deeper reasoning, stronger
  judgment, or greater reliability: API/SDK design, naming, UX, copy,
  code-quality decisions, and exploratory implementation where the spec
  emerges while coding.

Bad fits: bounded mechanical implementation and conclusion-only bulk analysis.
Route those to Codex. Keep precision work such as hot-path edits inline.

## Workflow

1. **Scope the task.** State the outcome Claude owns and write objective
   done-criteria it can self-check ("compiles with `cargo check -p X`",
   "tests pass"). Pick Haiku 4.5 for short straightforward work, Sonnet 5 for
   coherent medium-length tasks, and Opus 4.8 when complexity, stakes, or
   judgment warrants escalation.

2. **Isolate writes in a worktree** so Claude never touches your working
   tree:

   ```bash
   git -C <repo> worktree add /tmp/claude-impl-<topic> -b claude/<topic>
   ```

3. **Run Claude headless.** `-p` prints and exits;
   `--dangerously-skip-permissions` lets it edit/run without prompts. Set
   `<model>` to `haiku`, `sonnet`, or `opus` according to the routing above:

   ```bash
   claude -p "<one plain paragraph: exact task, files/paths, the check
     command to run, and — for implementation — commit the result with
     message '<msg>'. If you cannot complete it, say exactly what
     blocked you.>" \
     --model <model> \
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
- Use the cheapest tier suited to the task: Haiku 4.5 for short straightforward
  work, Sonnet 5 for coherent medium tasks, and Opus 4.8 when deeper capability
  changes the expected result.

---
name: claude-implement
description: Delegate implementation or high-token work to Claude (Opus 4.8) via the headless `claude -p` CLI — taste-sensitive code (API/SDK design, naming, UX, copy), tricky work needing judgment, and token-heavy digging (reading many files, large logs/specs) you want kept out of your own context. Use when the task needs quality Codex can't reliably hit, or would burn a lot of your context to read. Claude does the work and returns a conclusion; you review the result before it merges.
---

# Claude Implement

Delegate to Claude Opus via `claude -p` (headless print mode). Good fits:

- **Taste-sensitive implementation** — API/SDK design, naming, UX, copy,
  code-quality judgment. Claude has higher taste than GPT-5.5 here.
- **Judgment-heavy or exploratory work** — the spec emerges while coding,
  or correctness matters more than the token cost.
- **High-token digging** — reading many files, large logs/specs/diffs,
  bulk analysis. Offload it so your own context stays clean; Claude reads
  everything and returns just the conclusion.

Bad fits: bounded mechanical work you can do yourself (migrations, bulk
repetitive edits, compiles-and-passes-to-spec) — keep those on Codex, it's
cheaper-per-quality for grunt work.

## Workflow

1. **Scope the task.** For implementation, write done-criteria Claude can
   self-check ("compiles with `cargo check -p X`", "tests pass"). For a
   read/analysis task, state exactly what conclusion you want back and in
   what shape (a list, a diff, a yes/no with evidence).

2. **Isolate writes in a worktree** so Claude never touches your working
   tree (skip for read-only tasks):

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

   For a read-only dig, drop `-C`/worktree and point it at the repo;
   add `--output-format json` if you want to parse the result.

4. **Review the result yourself.** For code, read the diff
   (`git diff main...claude/<topic>`) — you own final correctness and that
   it fits the repo. For analysis, sanity-check the conclusion against a
   spot source before acting on it.

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
- Require an explicit **"nothing found" / "blocked by X"** statement so an
  empty result isn't mistaken for failure.
- A nonzero exit doesn't always mean failure — check the worktree diff or
  the returned text before rerunning.

## Guardrails

- Never point Claude at your main working tree or let it push.
- Escalate to Claude for quality, not to dodge bounded work — if you can
  hit the bar yourself, do it; Claude tokens cost real money.

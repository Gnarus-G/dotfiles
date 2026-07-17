---
name: codex-implement
description: Delegate a bounded, well-specified implementation task to the Codex CLI (GPT-5.6 Sol, medium reasoning) in a git worktree — mechanical migrations, clear-spec implementations, repetitive multi-file edits, and test scaffolding from a known pattern. Use when the task has a crisp spec and objective done-criteria (compiles, tests pass) and does not need this conversation's judgment or taste. The invoking agent reviews and verifies the result before it merges.
---

# Codex Implement

Delegate bounded implementation to `codex exec` (GPT-5.6 Sol, medium reasoning). Good fits:
mechanical migrations, implement-to-spec, bulk repetitive edits.
Bad fits: anything needing taste (API design, naming, UX), hot-path code, or
exploratory work where the spec emerges while coding. Keep precision and
taste-sensitive work inline.

## Workflow

1. **Bound the task.** Write done-criteria codex can self-check:
   "compiles with `cargo check -p X`", "`cargo nextest run -p X` passes",
   "every call site of Y updated". If you can't state the criteria,
   the task isn't bounded — don't delegate it.
2. **Isolate in a worktree** so codex never touches the working tree:

   ```bash
   git -C <repo> worktree add /tmp/codex-impl-<topic> -b codex/<topic>
   ```

3. **Run codex with write access in that worktree** (the bwrap sandbox
   is broken on this box; full-access is required for writes anyway):

   ```bash
   codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" \
     -s danger-full-access -C /tmp/codex-impl-<topic> \
     "<one plain paragraph: exact change, files/pattern, the check
      command to run, and: commit the result with message '<msg>'.
      If you cannot complete it, say exactly what blocked you.>"
   ```

4. **Review the diff yourself** (`git diff main...codex/<topic>`) — the
   invoking agent owns correctness and style conformance. Optionally run
   codex-review for an independent pass.
5. **Run the verification** (the done-criteria commands) yourself;
   don't trust codex's claim that they passed.
6. Merge/rebase per the repo's rules, or discard — a dead worktree
   costs nothing. Clean up: `git worktree remove --force ... && git
   worktree prune`.

## Prompting

- Fully self-contained: paths, exact commands, expected outcome,
  project constraints that matter for THIS task (inline the relevant
  CLAUDE.md rules — codex can't see them).
- One task per invocation. A list of tasks becomes a loop of separate
  `codex exec` calls, not one mega-prompt (timeouts, drift).
- A nonzero exit doesn't mean failure — check the worktree diff and
  any report file before rerunning.

## Guardrails

- Never point codex at the main working tree or let it push.
- Trading-correctness-critical code (order routing, fills, fees, sim
  determinism) is not delegable — repo rules require judgment codex
  doesn't have.

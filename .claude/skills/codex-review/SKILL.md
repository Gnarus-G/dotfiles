---
name: codex-review
description: Independent code review of a diff by the Codex CLI (GPT-5.6 Sol, high reasoning) — uncommitted changes, a branch diff against main, a specific commit, or a named implementation. Use when the user asks for a second pass, when a change is broad enough that another perspective helps, before opening a PR on nontrivial work, or as a correctness-focused pass before taste-sensitive review. Treat Codex as an extra reviewer whose findings the invoking agent verifies before presenting.
---

# Codex Review

Delegate diff review to `codex exec` (GPT-5.6 Sol, high reasoning). It's an independent
reviewer, not an oracle: verify its findings against the code before
presenting them. It is strongest on correctness and logic, and weakest on API
design and naming; keep taste-sensitive review with Opus/Fable.

## Workflow

1. Identify the review target: uncommitted changes, `main..HEAD`, a
   commit SHA, or specific files.
2. Create an artifact dir: `ARTIFACTS=$(mktemp -d /tmp/codex-review.XXXX)`
3. Run codex. The bwrap sandbox is broken on this box, so either pipe
   the diff in (preferred — bounded, no repo access needed):

   ```bash
   { echo "Review this diff for correctness bugs, silent-fallback
     behavior, dropped errors, and logic errors. For each finding give
     file, line, severity, and a concrete failure scenario. If you find
     no issues, say so explicitly and state what you reviewed.";
     git diff main...HEAD;
   } | codex exec -m gpt-5.6-sol -c model_reasoning_effort="high" \
     --skip-git-repo-check - > "$ARTIFACTS/report.md"
   ```

   or, when the review needs surrounding context beyond the diff, run
   in the repo with `codex exec -m gpt-5.6-sol -c
   model_reasoning_effort="high" -s danger-full-access -C <repo> "..."`
   (use a scratch worktree if it must not touch the working tree).

4. Read the report. **Verify each finding against the code** — codex
   findings on unfamiliar codebases include plausible-but-wrong ones.
5. Present verified findings, attributed ("independent GPT-5.6 Sol review
   flagged..."), and note dismissed false positives briefly.

## Prompting

- One plain paragraph: what diff, what to look for, output format.
- Include project-specific review rules inline (e.g. Ramp's no-silent-
  fallback, no `let _ =` on Result) — codex can't see CLAUDE.md.
- Always require the explicit "no issues found" statement.
- Large diffs: split by area into separate `codex exec` calls rather
  than one mega-review; long runs time out.

## When NOT to use

- Taste-heavy review (API shape, naming, UX copy) — keep on Claude/Opus.
- As the _only_ review for trading-correctness-critical changes — it's
  an extra pass, not a replacement for the project code-reviewer agent.

---
name: full-send
description: Take a GitHub issue all the way to a proven deploy — plan, approve, implement test-first in a worktree, open the PR, self-review with /gnarus-review, then /ship — pausing only to approve the plan. Use when told "full send", "take it all the way", or "work and ship #N".
argument-hint: <issue number or URL>
---

# full-send

Issue in, proven deploy out. The user approves the plan once; after that,
stop only where a step below or `/ship` says to.

## 1. Understand the issue

- Fetch it: `gh issue view <n> --json number,title,body,state,url`. If no
  issue was given, ask which one; do not pick. If it is closed, confirm.
- Read `/goal` for the effort if one exists. Ask about anything unclear now,
  not halfway through.

## 2. Plan, then pause

Find the root cause (keep asking why until it is the mechanism, not a
symptom), or for a feature, the reason it is needed. Present about half a
page:

- **Issue** — one or two sentences.
- **Cause / why** — the mechanism, with `file:line`.
- **Plan** — the smallest change that removes the cause, and the test that
  will prove it.

**Wait for approval.** No worktree, no code before it.

## 3. Implement

- Work in a fresh worktree on a branch named `<type>/<slug>`
  (`fix/`, `feat/`, `chore/`, `refactor/`).
- Test first (`tdd`): write the test, see it fail for the right reason,
  then make it pass. Prefer tests through real APIs over mocks.
- Keep it `/simple`: nothing the issue does not need.

## 4. Check locally

Run what CI runs, plus format and lint (for Rust: `cargo fmt --check`,
`cargo clippy --all-targets -- -D warnings`, `cargo test`). All green before
pushing. Run the thing for real where you can and keep the evidence.

## 5. Open the PR

- Read the full diff first. No debug prints, stray files, secrets or WIP
  commits.
- Push and open the PR. Body: the problem first in plain words, then the
  fix, then how it was tested. Link the issue (`Closes #<n>` when it is in
  the same repo).

## 6. Self-review

Run `/gnarus-review` on the PR. Fix the findings, push, wait for CI green.
Stop and ask only if a finding needs the user's call (scope, design
trade-off, a rule that might be wrong).

## 7. Ship

Run `/ship` on the PR: merge, deploy, prove, record, remove the worktree.

## 8. Report

One block: issue, PR, what deployed where, the proof.

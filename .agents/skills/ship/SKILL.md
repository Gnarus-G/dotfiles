---
name: ship
description: Land a change end to end — rebase, wait for CI, squash merge, deploy (roll) the build to the target environment, prove it works there, record the change, update the issue, clean the worktree. Use when told "squash merge when green", "roll it to staging/testnet", "merge and roll", "go ahead with the plan and approve", or "ship it".
---

# ship

One command for the sequence that otherwise takes four prompts. Invoked as
`/ship [PR...] [env]`. `env` defaults to the environment named in the plan
or issue; ask only if none is named.
`/ship --merge-only [PR...]` stops after the squash merge: skip steps 5–7
(deploy, prove, record), then clean up and report.

How to deploy and approve is the repo's business: follow its ops docs or
skills (e.g. a deploy/ops skill, a runbook). This skill is the order and the
stop conditions.

`/full-send` takes an issue through implementation and then runs `/ship`.

## Hard limits

- **Never touch production** unless the user says so in this session.
- **Never merge before the work is done.** Unfinished slices, failing
  checks or unanswered review comments block the merge.
- Respect environment reservations or freezes noted in the repo or by the
  user: deploy to the next environment down and stop there.
- Do not restart or stop services you were not asked to touch.

## Steps

1. **Rebase** on `origin/main`. Resolve conflicts; re-run local tests.
2. **Pre-merge gate.** All must hold:
   - `/simple` and a code review ran on the final diff; findings are fixed.
   - Bot and human reviews on the PR (`gh pr view --comments`) are read;
     each is fixed or answered with a reason.
   - If the PR build can be deployed without merging, it was tested in a
     non-production environment **before** merging.
3. **Wait for CI** with a watched wait, not a silent poller. On red: read
   the log, fix, push, wait again. Report the failing job if it is not ours.
4. **Squash merge** (`gh pr merge --squash --delete-branch`).
5. **Deploy** once the main build lands, using the repo's process
   (plan → user approval if required → apply). Confirm the target runs the
   new build.
6. **Prove it.** Run the check that matches the change — integration test,
   probe, before/after payload, log line, screenshot — and show the result.
   "It's deployed" is not proof.
7. **Record.** If the repo keeps an environment or ops log, add the change
   in the same session. Post a short status comment on the issue with the
   PR, what was deployed where, and the proof.
8. **Clean up** the worktree and local branch.
9. **Report** in one block: merged PRs, what deployed where, proof, what is
   next. Continue with the next item if the user said "keep going".

## Stop and ask

- A login or password prompt: hand it off per the user's instructions
  (e.g. a tmux window), wait for "logged in", then continue.
- Real money or real users at risk.
- The proof fails. Do not deploy further; say what failed.

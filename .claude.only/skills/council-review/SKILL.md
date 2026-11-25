---
name: council-review
description: Run every code review through a council — a Fable subagent and Codex GPT review independently in parallel, then Claude verifies each finding against the code before reporting. Use for any review of a PR, branch, diff or commit, including a fix Claude wrote, and when told "council", "review with fable and codex", or "make sure reviews go through a council".
---

# Council review

Two independent reviewers, one judge. Fable and Codex each review the same
change without seeing the other's output or your opinion. You read the
critical path yourself while they run, then verify each finding against
the code. Nothing a member says is true until you have checked it.

This skill is the review step. It works inside other review skills
(`gnarus-review`, `/code-review`) and before pushing a fix you wrote.

## 1. Pin the change and the goal

- PR: `gh pr view <n>` (body, every comment), `gh pr diff <n>`, and fetch
  the head branch so members can read whole files.
- Local work: the commit (`git show HEAD`) or `git diff <base>...HEAD`.
- Write the goal in one or two sentences, with the external rule it must
  meet quoted word for word (an exchange's stated limit, a spec line, an
  issue's acceptance). Members judge findings against this goal.

## 2. Launch both members in one message

Run them in the background and in parallel, one pair per PR.

**Fable** — Agent tool, `subagent_type: "council-reviewer"`,
`run_in_background: true`. Its model and effort come from the managed
`profiles/core/.claude/agents/council-reviewer.md` source. Brief:

- Read-only: do not edit, commit, push or post.
- Where the code is: repo path, the branch ref, and how to read it
  (`git show "<ref>:<path>"`), the diff command, the PR body command.
- The goal and the quoted rule from step 1.
- Numbered areas to check, phrased as questions, not answers:
  correctness against the rule, paths that bypass the change, state
  across reconnect/re-index/restart, hot-path allocations if the repo bans
  them, whether the tests fail without the change and what they miss,
  repo rules the change breaks, whether a simpler design is correct.
- Output: only concrete, reachable findings, each with severity
  (blocker / should-fix / nit), `file:line`, a quoted snippet and a
  scenario with numbers. Say plainly when an area is clean. Word cap
  (400–600).

Give it the code, never your conclusion. A member handed your hypothesis
tends to return it confirmed.

**Codex** — Bash, `run_in_background: true`, output to a project-local
scratch file:

```bash
{ echo "Goal: <goal and quoted rule>. Find concrete correctness bugs in this diff that are relevant to the goal and realistically reachable. You may read the repo; the branch is <ref> (git show <ref>:<path>). Omit speculative corrections; report no issues if none exist. For each finding: file:line, snippet, concrete scenario with numbers.";
  <diff command>;
} | codex exec --profile review \
  --skip-git-repo-check - > <scratch>/codex-<n>.txt 2>&1
```

The profile is installed from `profiles/core/.codex/review.config.toml`.
Both review configurations are machine-gated in `machine_plan.py`; edit
their source files to change model and effort. Their explicit review choices
are independent of the general-agent defaults.

Read only the final answer: the text after the last line that is exactly
`codex`. Codex's local sandbox sometimes fails to start; it then reads the
PR through GitHub and cannot run tests. Report that limit.

## 3. Read the critical path yourself while they run

Do not duplicate their full review. Read the one or two paths a finding
would hinge on (the admission check, the send and the charge, the index
lifecycle) so you can confirm or reject what comes back. Never poll a
member's output file; wait for its notification.

## 4. Verify every finding

For each finding, open the cited `file:line` and check the scenario.
Sort it:

- **Confirmed** — the code does what the finding says, and the scenario
  is reachable under the stated goal.
- **Discarded** — false, outside the goal, hypothetical, an operator's
  deliberate choice, or a non-YAGNI suggestion. Say why in one line.
- **Pre-existing** — real but not introduced by the change. List
  separately; never block on it.
- **Decision** — a trade-off (headroom, a dropped limit, a policy) that
  the code cannot settle. Give your recommendation, and put it to the
  user or the PR author.

A finding both members raise independently is the strongest signal, but
it still needs your check. A finding from one member is not weaker for
it.

## 5. Report

Per PR, in the session's response format:

- Verdict: approve / request changes / needs discussion.
- Each confirmed finding with `file:line`, the snippet, which member
  found it (Fable, Codex, both, you), and the fix.
- What was checked and clean, so the reader knows the coverage.
- Discarded and pre-existing findings, one line each with the reason.
- What no member ran (tests, a tool that failed).

Ask before posting. When posting, one review per PR that names the council
("Fable and Codex reviewed independently; each finding verified against
the branch"). A PR you authored gets a comment, not an approval.

## 6. A fix you write goes through the council too

After you fix findings, commit, then run steps 2–4 on that commit before
pushing. Push only after the council's confirmed findings are fixed or
recorded as decisions.

## Traps

- zsh treats `$B:r…` in `git show $B:rust/...` as a history modifier.
  Quote it: `git show "${B}:rust/..."`.
- A merged PR gets no council retroactively unless asked; say which
  merged changes skipped it.
- Delete scratch output files once the review is posted.

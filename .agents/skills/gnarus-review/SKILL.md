---
name: gnarus-review
description: Review a PR the way gnarus does — problem statement first, then correctness, tests, simplicity and repo rules, with bot reviews folded in. Use when told "review this PR", "you know my review style", "you know what to look for", "is it simple?", or given PR links or a screenshot of PRs to review.
---

# gnarus-review

Invoked as `/gnarus-review <PR...>`. One PR at a time, in simple sentences.

## For each PR

1. **Problem statement first.** In two or three plain sentences: what was
   broken or missing, and for whom. Link the issue. If you cannot state it,
   say so — that is a finding.
2. **Is it the right fix?** Does it remove the cause, or patch a symptom?
   Is there a smaller fix? Does it fight a documented rule in the repo
   (CLAUDE.md/AGENTS.md, required-features docs, ADRs, glossary)?
3. **Is it tested?** Name the test that would fail without the change.
   Integration or end-to-end coverage where the change touches external
   behavior. "It runs in staging" counts only with a run id or log.
4. **Is it simple?** Run `/simple` and a code review. Flag code the goal
   does not need, hasty abstraction (prefer duplication until a stable
   abstraction emerges), arbitrary timers, hot-path allocations, and any
   repo-specific bans.
5. **Bot reviews.** Read every bot and human comment on the PR. Say which
   are right, which are wrong and why.
6. **Verdict:** approve / request changes / needs discussion, with the
   two or three findings that matter. No speculative findings.

Show code or payloads for every finding — `file:line` plus the snippet.

## After

Ask before posting. When told to post, post findings as one review on the
PR. When told to take over the PR, fix in a worktree and `/ship`.

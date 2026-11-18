## About me

I'm `gnarus`. I prefer simple, maintainable software and especially enjoy Rust.

## Coding preferences

- Keep changes small and focused; apply YAGNI.
- Prefer AHA over reflexive DRY.
- Prefer squash merges when merging Git branches or pull requests.
- When reviewing, report realistic findings relevant to the goal.
- Never hardcode API keys or read or display their values.
- Show concrete results alongside recommendations.
- Always squash-merge branches and pull requests, including feature branches
  into an integration branch (`git merge --squash <branch>` then commit,
  `gh pr merge --squash`); never land `--no-ff` merge commits.
- When working through an epic, commit each logical unit as it lands instead
  of piling everything up in one commit at the end.

Run short noninteractive commands directly; ask for input only when necessary.

## Subagents

- Fan out to subagents when your harness provides them: launch independent
  tasks as parallel subagents in one batch, and hand work to a subagent whose
  model or effort fits it better than your own.
- Give each subagent a self-contained prompt (goal, paths, constraints, what
  to report back); keep judgment-heavy or tightly coupled steps inline.

## Worktrees

- Create worktrees with `git wt -b <branch>` for a new branch, or `git wt`
  without `-b` to use the selected base directly. Remove selected worktrees
  with `git wt rm`; do not use raw `git worktree` or harness-specific worktree
  tools.
- Base selection uses `fzf`, so run creation in an interactive terminal and
  work in the printed `Created worktree: <path>` directory.

## Evidence-first responses

All responses, including updates, use only these headings with short, unbolded ID bullets:
- **Facts:** F1... — observations with inline evidence; attribute user reports.
- **Premises:** P1... — statements offered as reasons supporting a conclusion;
  state origin, evidence or assumption status, and uncertainty.
- **Questions:** Q1... — missing information you cannot obtain yourself.
- **Conclusions:** C1... — inferences or proposed actions; cite supporting
  F/P IDs and qualify certainty and limits.

Premises may be facts, assumptions, definitions, principles, or conditionals;
if–then form is optional. Facts used as premises retain F IDs without repetition.

Omit empty headings. Restart IDs per response; keep them stable within it.
Lead with the useful supported answer. Use plain words; omit filler, repetition,
and unrequested detail. A single item may use one labeled line instead.
Give updates only for decisions, blockers, or meaningful findings; report
completion once, without repeating earlier summaries.
Never sacrifice evidence or accuracy for brevity. Memory, plausibility, earlier
assistant assertions, and illustrations are not verification.
Nest verbatim code, commands, tables, and drafts under an item.
Before sending, check labels, sources, counterexamples, hidden assumptions,
and inference strength; correct or downgrade unsupported claims.
This overrides one-sentence defaults and other skills' prose formats.
`/fc [IDs]` or `/fact-check [IDs]` invokes `fact-check` on the last response;
no IDs means all facts and premises. Codex uses `$fc` or `$fact-check`.

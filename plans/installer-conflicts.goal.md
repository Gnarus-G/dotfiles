# Installer conflict resolution

Status: implemented and verified; the user completed the work install in `Whatever:dotfiles-conflicts` (pane `%5`).

Goal: Restore interactive overwrite, absorb, and skip without mixing user input into the pure machine planner.
Done when: sandbox tests prove choices, cancellation, noninteractive refusal, and undo; the real installer prompts in tmux.

## Facts
- Unresolved conflicts block the plan; terminal users can now resolve them before writes.
- Overwrite must preserve the original path for undo, including the text of an external symlink.
- Absorb copies local content into the source; directory absorption retains repository-only entries.
- Collect choices before changing anything; quit or EOF cancels the run.
- Keep machine scoping and the existing journal.
- Existing staged Claude subagent changes belong to the preceding task.

## Verification
- 59 installer tests passed; the existing OpenCode context7 inventory failure was excluded after confirming it still fails.
- Ruff lint and formatting passed for the changed implementation and new tests.
- Documentation links and `./dev --help` passed; the real installer displayed the four-choice prompt.
- The work install applied 32 effects, and the user's second run applied zero effects.
- Implementation and usage: [conflict resolution](../MACHINE_PLAN.md#resolve-local-conflicts).

# Claude subagent models

Status: configuration implemented; local installation blocked by existing external skill symlinks.

Goal: Use Claude models for native subagent roles on work and remote.
Done when: the [scope test](<code:tests/machine_plan_test.py#def test_claude_subagent_models_on_work_and_remote(machine, tmp_path):>) and all three machine previews pass.

## Facts
- General-purpose defaults to Opus; Explore defaults to Sonnet.
- The main model can be Fable and remains independently selected.
- Home keeps its existing Claude configuration.

## Corrections log
- 2026-11-09: The user expanded the original work-only scope to remote too.

## Verification
- All three scope cases passed; Claude validated the Explore definition.
- The suite had 45 passes and one unrelated failure for the unmanaged OpenCode context7 skill.
- Formatting and documentation links passed; Ruff reported the existing unused `paint` import.
- Local previews found 16 external skill symlinks on work and 18 on home and remote; nothing was installed.

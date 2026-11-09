# Machine-specific dotfiles

Preview before installing; this prints the effects against your actual home
without changing it:

```sh
python3 -B machine_preview.py work
python3 -B machine_preview.py home
python3 -B machine_preview.py remote
```

Apply the corresponding machine policy with `./dev --machine remote`,
`./dev --machine home`, or `./dev --machine work`; `./dev` requires
`--machine`. You can first exercise installation in a separate home with
`./dev --machine remote --home /path/to/sandbox-home`.

The inventory covers agent skills, tools, instructions, and configs. Remote receives core agent
instructions and config without desktop, speech, tmux, or Herdr integration;
home and work receive the existing desktop sources, with the work-only Ghostty
launcher added on work. Tests enumerate the skill sources and OpenCode
configuration tree to catch inventory omissions.
`~/.gitconfig` is machine-local and is not installed from the ignored repo file.

One main branch holds both common sources and scoped overlays:

| Output | Shared source | Desktop addition |
| --- | --- | --- |
| Claude / Pi prompt | `profiles/core/instructions.md` | `profiles/desktop/instructions.md` |
| Codex prompt | Shared + desktop prompt | `profiles/desktop/codex.md` |
| Claude settings | `profiles/core/.claude/settings.json` | `.claude/settings.json` |
| OpenCode JSON | `profiles/core/.config/opencode/opencode.json` | `profiles/desktop/.config/opencode/opencode.json` |

`machine_bundle.py` composes these in memory for the preview. Installation
writes only the five machine-specific outputs under the ignored
`.machine-generated/<machine>/` directory and links them into the home. JSON
objects merge recursively; arrays and scalars replace their base values.
The `machine-config` skill describes where to put a new tool's instructions,
JSON fields, and capability links. For example, the desktop MCP servers
appear in home/work OpenCode config but not in remote's rendered config.

MCP servers live once in `.config/mcp/mcp.json`. Pi and OpenCode read the
linked file; `mcp_servers.py` merges the same entries into `~/.claude.json`
and `~/.codex/config.toml`, which those harnesses own and rewrite.

## Resolve local conflicts

In a terminal, `./dev --machine work` asks how to resolve each conflict:

```text
Choose [o / a / s / q] (Enter = skip):
```

Choices are collected before writes; quit or EOF cancels the run
([cancellation test](<code:tests/machine_conflicts_test.py#def test_cancel_after_first_choice_changes_nothing(sandbox, answer):>)).
Skip leaves that target alone for this run
([choice test](<code:tests/machine_conflicts_test.py#def test_collect_choices_before_writes_and_skip_one_target(sandbox):>)).

Overwrite saves the original file, directory, or link before installing the repository link
([link test](<code:tests/machine_conflicts_test.py#def test_overwrite_and_undo_preserve_external_symlink(sandbox, destination):>)).
Absorb copies local content into the repository source, keeping repository-only directory entries, then installs the link
([absorb test](<code:tests/machine_conflicts_test.py#def test_absorb_merges_directory_and_undo_restores_both_sides(sandbox):>)).
`./dev undo --machine work` restores both originals; backups remain under
`~/.local/state/dotfiles/backups/` ([backup implementation](<code:machine_conflicts.py#def save(root: Path, home: Path, where: str, target: str, expects: str)>)).

For scripts, `--non-interactive` refuses conflicts; input without a terminal does the same
([CLI test](<code:tests/machine_conflicts_test.py#def test_cli_prompts_only_when_interactive(>)).
Generated outputs cannot be absorbed: edit their profiles instead
([generated-source test](<code:tests/machine_conflicts_test.py#def test_generated_configuration_cannot_be_absorbed(sandbox):>)).
Parent-directory links cannot be overwritten through a child target
([parent-link test](<code:tests/machine_conflicts_test.py#def test_parent_link_conflict_cannot_be_overwritten(sandbox):>)).
Unresolved conflicts still block all effects.

Restart OpenCode after installation so it reloads its machine-specific config.

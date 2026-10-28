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
JSON fields, and capability links. For example, the desktop Convex MCP entry
appears in home/work OpenCode config but not in remote's rendered config.

Foreign files or links and missing sources block **all**
effects. The installer checks the plan again immediately before mutation, and
a second run makes no changes.

Restart OpenCode after installation so it reloads its machine-specific config.

# Agent Configuration

Configuration for AI coding assistants (OpenCode, Claude Code, etc). The `dev` script symlinks these files to your home directory for automatic discovery.

## Quick Start

```bash
python3 -B machine_preview.py work  # Preview machine-specific changes
./dev --machine work                  # Install after reviewing the preview
./dev undo --machine work             # Revert the last install
```

Choose `remote`, `home`, or `work` for the machine; see `MACHINE_PLAN.md` for
the migration details. `./dev` requires `--machine`. Installs print each
applied effect and journal its inverse to
`~/.local/state/dotfiles/history.jsonl` for `undo`.

## Symlinked Configuration

| Source                   | Target                     | Description         |
| ------------------------ | -------------------------- | ------------------- |
| `.config/nvim/`          | `~/.config/nvim`           | Neovim config       |
| `.config/mcp/mcp.json`   | `~/.config/mcp/mcp.json`, `~/.pi/agent/mcp.json` | MCP server list for Pi and OpenCode |
| `.machine-generated/<machine>/opencode.json` | `~/.config/opencode/opencode.json` | OpenCode settings |
| `.config/awesome/`       | `~/.config/awesome`        | Awesome WM theme    |
| `.config/hypr/`          | `~/.config/hypr`           | Hyprland config     |
| `.config/waybar/`        | `~/.config/waybar`         | Waybar config       |
| `.config/dunst/`         | `~/.config/dunst`          | Notifications       |
| `.config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal    |
| `.zshrc`                 | `~/.zshrc`                 | Shell configuration |

On home, OpenCode's `general` agent uses `ollama-cloud/glm-5.3` and `explore`
uses `ollama-cloud/glm-5.3-flash`; other agents keep their defaults.
On work, the [OpenCode overlay](profiles/work/.config/opencode/opencode.json)
sets `general` to `openai/gpt-6.1-sol#high` and `explore` to `openai/gpt-6.1-sol#low`.

On work and remote, Claude's native `general-purpose` defaults to Opus through
`CLAUDE_CODE_SUBAGENT_MODEL`; a user-level `Explore` override selects Sonnet
([scope test](<code:tests/machine_plan_test.py#def test_claude_subagent_models_on_work_and_remote(machine, tmp_path):>)).
The main model is selected independently, including Fable with `/model fable`;
an explicit model on a delegation takes precedence over these defaults.

fx rejects symlinked settings, so `./dev` merges `.fx/settings.json` into
`~/.fx/settings.json` on every machine, preserving unrelated local settings;
Ollama Cloud authentication uses `OLLAMA_API_KEY`.
The shared fx `commit` profile lives in `.fx/agents/commit/` and is linked to
`~/.fx/agents/commit` on every machine; saved profiles require an fx version
that supports agent profiles (the installed 0.0.16 does not).
The commit skills in every harness run `git-ac` directly: message generation
uses the Codex subscription first and falls back to Ollama, without requiring
another model-backed agent to launch; Pi's `commit` tool uses the same command.

## Skills

Skills are specialized instructions loaded by AI assistants for specific tasks.

### Skill Source Sets

| Source                    | Consumers                    |
| ------------------------- | ---------------------------- |
| `.agents/skills/`         | Claude, Codex, and OpenCode  |
| `.claude.only/skills/`    | Claude only                  |
| `.codex.only/skills/`     | Codex-compatible agents only |

OpenCode disables automatic `.claude`/`.agents` discovery and receives a
reconciled projection of shared skills under `~/.config/opencode/skills`.

### MCP Servers

`.config/mcp/mcp.json` is the single list of MCP servers. Pi and OpenCode read
the linked file; Claude Code and Codex own their config files, so the same
entries are merged into `~/.claude.json` and `~/.codex/config.toml` on every
install. Add a server once, in `.config/mcp/mcp.json`.

### Adding Shared Skills

1. Create directory: `.agents/skills/<skill-name>/`
2. Add `SKILL.md` with YAML frontmatter:

   ```yaml
   ---
   name: my-skill
   description: Short description shown in skill list
   ---
   # Skill instructions here
   ```

3. Run `./dev --machine home` (or the appropriate machine) to sync
4. Skill auto-discovered on next session

## Files

| File                         | Purpose                                    |
| ---------------------------- | ------------------------------------------ |
| `AGENTS.md`                  | Project instructions for AI assistants     |
| `.claude/CLAUDE.md`          | Claude-only system instructions            |
| `.codex/AGENTS.md`           | Codex-only system instructions             |
| `profiles/core/instructions.md` | Base instructions for Claude, Codex, OpenCode, and Pi |
| `dev`                        | Symlink and skill composition script       |

## Response Length — **ONE SENTENCE BY DEFAULT**

**Unless the user explicitly requests otherwise, every user-facing response must be exactly one concise sentence.** Do not add explanations, summaries, progress narration, headings, or follow-up offers; this default is mandatory and takes precedence over general readability guidance.

## Guidelines

- Make minimal, targeted changes
- Treat code the current goal does not need as a cost and a smell; apply YAGNI and do not overshoot
- Always prefer AHA (Avoid Hasty Abstractions) over reflexive DRY: tolerate duplication until a clear, stable abstraction emerges
- Keep review findings relevant to the goal and realistic scenarios; omit speculative corrections and hypothetical findings
- Run available linters/typecheckers after edits
- Research unfamiliar tools before implementing
- Show the consequence, not the idea: a recommendation ships with its concrete result in the same message — the sample payload before and after a schema change, the topic line for a feed name, the `--help` line for a CLI change, a small table for numbers, a web artifact for anything two-dimensional. Prose that describes a shape without showing it is a wasted round trip.

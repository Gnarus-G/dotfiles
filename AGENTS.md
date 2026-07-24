# Agent Configuration

Configuration for AI coding assistants (OpenCode, Claude Code, etc). The `dev` script symlinks these files to your home directory for automatic discovery.

## Quick Start

```bash
./dev  # Sync all dotfiles to ~
```

## Symlinked Configuration

| Source                   | Target                     | Description         |
| ------------------------ | -------------------------- | ------------------- |
| `.config/nvim/`          | `~/.config/nvim`           | Neovim config       |
| `.config/opencode/`      | `~/.config/opencode`       | OpenCode settings   |
| `.config/awesome/`       | `~/.config/awesome`        | Awesome WM theme    |
| `.config/leftwm/`        | `~/.config/leftwm`         | LeftWM config       |
| `.config/eww/`           | `~/.config/eww`            | Eww widgets         |
| `.config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal    |
| `.zshrc`                 | `~/.zshrc`                 | Shell configuration |
| `.gitconfig`             | `~/.gitconfig`             | Git settings        |

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

3. Run `./dev` to sync
4. Skill auto-discovered on next session

## Files

| File                         | Purpose                                    |
| ---------------------------- | ------------------------------------------ |
| `AGENTS.md`                  | Project instructions for AI assistants     |
| `.claude/CLAUDE.md`          | Claude-only system instructions            |
| `.codex/AGENTS.md`           | Codex-only system instructions             |
| `.config/opencode/system.md` | OpenCode and Pi system instructions        |
| `dev`                        | Symlink and skill composition script       |

## Response Length — **ONE SENTENCE BY DEFAULT**

**Unless the user explicitly requests otherwise, every user-facing response must be exactly one concise sentence.** Do not add explanations, summaries, progress narration, headings, or follow-up offers; this default is mandatory and takes precedence over general readability guidance.

## Guidelines

- Make minimal, targeted changes
- Run available linters/typecheckers after edits
- Research unfamiliar tools before implementing

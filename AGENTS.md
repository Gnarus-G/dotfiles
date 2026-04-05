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
| `.config/mcphub/`        | `~/.config/mcphub`         | MCP Hub servers     |
| `.config/opencode/`      | `~/.config/opencode`       | OpenCode settings   |
| `.config/awesome/`       | `~/.config/awesome`        | Awesome WM theme    |
| `.config/leftwm/`        | `~/.config/leftwm`         | LeftWM config       |
| `.config/eww/`           | `~/.config/eww`            | Eww widgets         |
| `.config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal    |
| `.zshrc`                 | `~/.zshrc`                 | Shell configuration |
| `.gitconfig`             | `~/.gitconfig`             | Git settings        |

## Skills

Skills are specialized instructions loaded by AI assistants for specific tasks.

### Adding Skills

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

| File        | Purpose                                    |
| ----------- | ------------------------------------------ |
| `AGENTS.md` | Instructions for AI assistants (this file) |
| `system.md` | System-level configuration for OpenCode    |
| `dev`       | Symlink script                             |

## Guidelines

- Make minimal, targeted changes
- Run available linters/typecheckers after edits
- Research unfamiliar tools before implementing

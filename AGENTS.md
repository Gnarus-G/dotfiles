# Agent Configuration

This repository contains configuration for AI agents and assistants. The `dev` script symlinks these files to your home directory.

## Quick Start

```bash
./dev  # Run from repo root to sync all dotfiles
```\n
## Directory Structure

### Agent Skills (`.agents/skills/`)

Skills are automatically discovered by agent frameworks:

| Source | Symlink Target | Used By |
|--------|---------------|---------|
| `.agents/skills/` | `~/.agents/skills` | General agent tools |
| `.agents/skills/` | `~/.claude/skills` | Claude Code |
| `.agents/skills/` | `~/.config/opencode/skills` | OpenCode |

**Available Skills:**
- `coolify-cli` - Coolify deployment management
- `create-pr` - Pull request creation workflows
- `frontend-design` - UI/UX design patterns
- `functional-programming` - FP principles and patterns
- `ollama-amd-gpu-installation` - Ollama setup for AMD GPUs
- `refactoring-expert` - Code refactoring techniques
- `skill-creator` - Creating new agent skills
- `svelte5-best-practices` - Svelte 5 development
- `systematic-debugging` - Debugging methodologies
- `test-driven-development` - TDD workflows
- `tmux-processes` - Tmux pane management

### OpenCode (`.config/opencode/`)

OpenCode IDE configuration:

| Source | Target | Purpose |
|--------|--------|---------|
| `.config/opencode/` | `~/.config/opencode` | Main config directory |
| `plugins/` | `~/.config/opencode/plugins` | Custom plugins (tmux, worktree) |
| `skills/` | `~/.config/opencode/skills` | Agent skills (symlinked from `.agents/skills`) |
| `system.md` | `~/.config/opencode/system.md` | System instructions |
| `opencode.json` | `~/.config/opencode/opencode.json` | OpenCode settings |
| `oh-my-opencode.json` | `~/.config/opencode/oh-my-opencode.json` | Agent configurations |

### Other Configurations

| Source | Target | Tool |
|--------|--------|------|
| `.config/nvim/` | `~/.config/nvim` | Neovim |
| `.config/mcphub/` | `~/.config/mcphub` | MCP Hub |
| `.config/awesome/` | `~/.config/awesome` | Awesome WM |
| `.config/leftwm/` | `~/.config/leftwm` | LeftWM |
| `.config/eww/` | `~/.config/eww` | Eww widgets |
| `.config/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal |
| `.zshrc` | `~/.zshrc` | Zsh shell |
| `.gitconfig` | `~/.gitconfig` | Git |

## Adding New Skills

1. Create a new directory under `.agents/skills/<skill-name>/`
2. Add a `SKILL.md` file with YAML frontmatter:
   ```yaml
   ---
   name: my-skill
   description: What this skill does
   ---
   
   # Skill content here
   ```
3. Run `./dev` to sync
4. The skill will be auto-discovered by OpenCode/Claude Code

## See Also

- `dev` - The sync script that manages all these symlinks
- `.config/opencode/plugins/` - Custom OpenCode plugins

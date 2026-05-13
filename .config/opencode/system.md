# System Instructions

## Information & Research

- **Library docs**: Use `context7_resolve-library-id` → `context7_query-docs` for library/framework documentation
- **Default to research**: When uncertain about a tool, pattern, or best practice, research first rather than guessing

## Skills

- **Tmux**: Use `tmux-processes` skill if working in tmux environment to manage panes effectively for workflows involving multiple files/screens/tabs
- **Consiceness**: Use `caveman` skill.
- **Confidence**: Use TDD, systematic-debugging, and or syllogism to do RCA's or other debugging.

## Workflow Quality

- **Validate changes**: After editing files, run available linters/typecheckers to catch issues early
- **Follow conventions**: Check neighboring files, existing imports, and project-specific patterns before writing code
- **Announce completion**: Use `tts-mcp` to verbally announce when finishing multi-step plans

## API keys

- **Never hardcode** real API keys in repo files; use environment variables instead
- Never attempt to read the values of API keys. Do not expose them in the chat.

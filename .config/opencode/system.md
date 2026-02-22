# System Instructions

## Information & Research

- **Web search**: Use `ez-web-search-mcp_search` for general queries, current information, or tools not in Context7
- **Library docs**: Use `context7-mcp_resolve-library-id` → `context7-mcp_query-docs` for library/framework documentation
- **Default to research**: When uncertain about a tool, pattern, or best practice, research first rather than guessing

## Skills

- **Committing**: Always invoke `git-commit` skill when asked to commit changes
- **Code design**: Use `functional-programming` or `refactoring-expert` skill when planning or designing code changes
- **Skill creation**: Use `skill-creator` skill when creating new skills

## Workflow Quality

- **Validate changes**: After editing files, run available linters/typecheckers to catch issues early
- **Follow conventions**: Check neighboring files, existing imports, and project-specific patterns before writing code
- **Announce completion**: Use `tts-mcp` to verbally announce when finishing multi-step plans

## Proactive Defaults

- For new skills: Research first with web search or Context7
- For refactoring: Load the appropriate skill before proposing changes
- For unfamiliar tools: Research before implementing

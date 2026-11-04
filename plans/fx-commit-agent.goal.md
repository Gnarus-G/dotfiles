# fx commit agent

Goal: Provide a repository-managed custom commit subagent for fx, like the existing Codex commit agent.
Done when: The profile is installed by all machine inventories, focused tests pass, and runtime support is checked.

## Facts
- Profile source: `.fx/agents/commit/{profile.json,prompt.md}`.
- Run only `git-ac -y -- <paths>` for exact parent-supplied paths.
- Inherit the parent's model and permissions; allow only shell, no MCP servers.
- Installed fx 0.0.16 rejects `--profile`; saved-profile runtime use requires a supporting fx version.

## Out of scope
- Automatically upgrading fx or changing commit message generation.
- Committing unrelated worktree edits.

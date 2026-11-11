# fx commit agent

Goal: All harnesses commit through Codex subscription-backed git-ac with Ollama fallback, without a model-dependent wrapper blocking it.
Done when: Shared and Claude skills run git-ac directly, Pi's tool does likewise, all machine inventories pass, and subscription/fallback checks pass.

## Facts
- Profile source: `.fx/agents/commit/{profile.json,prompt.md}`.
- Run only `git-ac -y -- <paths>` for exact parent-supplied paths.
- The optional fx profile inherits the parent's model and permissions; allow only shell, no MCP servers.
- Commit skills in all harnesses now invoke git-ac directly, without a model-backed wrapper; Pi's commit tool does the same.
- Message generation uses the Codex subscription first, then Ollama on failure.
- OpenCode's optional explicit commit subagent uses OpenAI rather than Ollama.
- Installed fx 0.0.16 rejects `--profile`; saved-profile runtime use requires a supporting fx version.

## Out of scope
- Automatically upgrading fx or changing commit message generation.
- Committing unrelated worktree edits.

## Corrections log
- 2026-11-11: User: all harnesses must use Codex with Ollama fallback; an Ollama wrapper had failed before git-ac could run.

## Verification
- 66 Python checks pass, including git-ac subscription/fallback subprocess tests and all machine inventory tests.
- Two Pi tool checks pass: exact argument/cwd/signal forwarding and success/failure output.
- Pi extension strict typecheck and Python lint/format checks pass.
- All three machine previews inspected; home install needs zero effects because affected sources are already linked.

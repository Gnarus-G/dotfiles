# OpenCode subagent models

Goal: Configure OpenCode's home subagents to use GPT-6.2 Sol at the user-specified reasoning efforts.
Done when: Home resolves GPT-6.2 Sol at `high` for `general` and `low` for `explore`, and the machine-scope tests pass.

## Facts
- Home selects GPT-6.2 Sol at `high` for General and `low` for Explore.
- Work retains its `medium`/`low` effort split on OpenAI; remote has no `general` or `explore` model overrides.
- Do not equate a model's default variant with the user's preferred variant.
- Build and Plan are primary agents; General and Explore are subagents. Do not assume General should receive the strongest or most expensive model.
- A subagent inherits the parent session's model when it has no configured override.

## Out of scope
- Applying Ollama Cloud subagent routing to work or remote.
- Treating Kimi or its default variant as required without user approval.

## Corrections log
- 2026-11-14: User emphasized: "ollama-cloud subagent routing is only for home profile/machine."
- 2026-11-14: User challenged the selection: "I didn't say I wanted the default, or that I wanted kimi."
- 2026-11-14: User challenged the quality-first General assumption: "isn't that reserved for the Build/Plan agents?"
- 2026-11-14: User approved DeepSeek V4.1 Flash 1017 at `high` for General with "do it."
- 2026-11-20: User switched both home subagents to GPT-6.2 and specified `high` and `low`, respectively.

## Verification
- All 71 targeted tests passed; the remote, home, and work previews completed.
- `opencode debug agent` resolved home General and Explore to `openai/gpt-6.2-sol`, at `high` and `low` respectively.

# OpenCode subagent models

Goal: Compare the pictured models and configure user-approved models for OpenCode's `general` and `explore` subagents on home only.
Done when: Home resolves the user-approved models and efforts, work and remote remain unchanged, and the machine-scope tests pass.

## Facts
- Ollama Cloud subagent routing belongs only in the home profile and home machine.
- Work retains its OpenAI subagent routing; remote has no `general` or `explore` model overrides.
- Home selects DeepSeek V4.1 Flash 1017 at `high` for General and `low` for Explore; the user approved this recommendation.
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

## Verification
- All 52 machine-plan and agent-config tests passed; all three previews completed.
- OpenCode resolves home General to DeepSeek 1017/`high` and Explore to DeepSeek 1017/`low`; a live High request returned `OK`.

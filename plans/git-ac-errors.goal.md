# git-ac error presentation

Status: committed locally as `a6ff03b`; tests, lint, formatting, and live fx generation passed; publication pending.

Goal: Explain provider failures in one readable message with commands that help the user recover.
Done when: a local HTTP 429 reproduction exits nonzero without a traceback, preserves staging, and shows recovery commands.

## Facts
- The screenshot showed a missing OpenAI key fallback followed by an uncaught Ollama HTTP 429.
- Generation now uses fx with a Codex subscription; the default model falls back to Ollama if fx fails.
- Explicitly selected models do not fall back; subscription authentication uses `fx login codex`.
- Name the actual provider and model, and explain why fallback happened.
- A 429 can mean rate limiting or exhausted quota; do not claim a more specific cause without evidence.
- Do not expose API credentials or raw provider responses.
- Recovery commands must preserve explicitly selected paths.
- Keep unrelated working-tree and staged changes intact.

## Verification
- Three alternating live trials per tool used the same prompt, model, and reasoning effort: fx median 3.194 seconds, Pi median 5.331 seconds.
- The installed git-ac completed three live dry runs through fx in 3.2–4.4 seconds end-to-end.
- Fifteen git-ac tests passed, including a real subprocess against a local HTTP 429 server and simulated fx responses.
- The [regression test](<code:tests/git_ac_test.py#def test_429_explains_fallback_and_preserves_staging(tmp_path, failing_provider):>) verifies the nonzero exit, preserved staging, absent traceback, and recovery commands.
- Ruff lint and formatting passed; the installed executable points to the edited source.
- The [fx dry-run test](<code:tests/git_ac_fx_test.py#def test_dry_run_uses_subscription_and_only_final_output(workspace):>) verifies subscription routing and use of the final response only.
- The [default-model test](<code:tests/git_ac_fx_test.py#def test_default_model_falls_back_to_ollama(workspace):>) verifies fallback to Ollama.
- The [explicit-model test](<code:tests/git_ac_fx_test.py#def test_explicit_model_failure_never_commits_or_falls_back(>) verifies that an explicit model failure neither commits nor falls back.

## Left
- Commit the Minuet OpenAI/Gemini configuration cleanup and this status correction.
- Publish the local commits when requested; no tracking issue or open PR was found during the status check.

---
name: codex-computer-use
description: Use when Codex should verify a running app, browser flow, screenshot, or other runtime behavior.
---

# Codex Computer Use

Delegate runtime and UI verification to `codex exec` with medium reasoning.
Do not use this skill to edit code.

## Workflow

1. Define the app, command, URL, flow, and expected behavior.
2. Create an artifact directory: `ARTIFACTS=$(mktemp -d /tmp/codex-verify.XXXX)`.
3. Run Codex with a self-contained prompt:

   ```bash
   codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" \
     -s danger-full-access -C /path/to/project \
      "Run <command>, open <URL>, and test <flow>. Save screenshots and a
       report describing what worked or failed in $ARTIFACTS."
   ```

4. Read the report and inspect the screenshots; verify important claims yourself.
5. Report findings with paths to the artifacts.

The local sandbox cannot read files, so use `danger-full-access` only where
repo access is acceptable. Split long flows, require an explicit clean result,
and check the artifact directory even after a nonzero exit.

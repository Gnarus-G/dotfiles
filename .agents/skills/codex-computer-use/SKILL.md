---
name: codex-computer-use
description: Shell out to the Codex CLI (GPT-5.5) for local app verification that needs computer use — browser automation, running and inspecting apps, capturing screenshots, exercising UI flows, or independent runtime inspection. Use when the user asks to test a flow, verify UI behavior, inspect a running app, capture screenshots, or confirm implemented behavior end-to-end. Also the route for token-heavy verification (many screenshots, long logs) that would burn Claude usage.
---

# Codex Computer Use

Delegate runtime/UI verification to `codex exec` (GPT-5.5) instead of doing it
with Claude tools. Codex usage is cheap; treat it as an independent verifier
whose claims you check before reporting.

## When

- Testing or verifying a user-facing flow in a running app
- Browser automation, screenshots, visual inspection
- Independent "does this actually work?" pass after implementing a change
- Token-heavy inspection: long logs, many screenshots, big artifacts

Not for: writing or editing code in this repo (do that yourself or use a
worktree), or quick single-page checks where `claude-in-chrome` is faster.

## Workflow

1. Identify the verification target: app, URL, flow, expected behavior.
2. Create a scratch artifact dir for Codex's report and screenshots:
   `ARTIFACTS=$(mktemp -d /tmp/codex-verify.XXXX)`
3. Run Codex non-interactively with a simple, self-contained prompt:

   ```bash
   codex exec -s danger-full-access \
     -C /path/to/project \
     "Start the app with <command>. Open <URL>. Exercise <flow>.
      Capture screenshots of each step into $ARTIFACTS.
      Write a short report to $ARTIFACTS/report.md describing what you
      observed, what worked, and what failed.
      If everything works and you find no issues, say that explicitly
      and describe exactly what you tested."
   ```

   - Read-only inspection (logs, artifacts, no app control): use
     `codex exec -s read-only` instead.
   - Attach reference images with `-i screenshot.png` when comparing
     against an expected state.
4. Read `$ARTIFACTS/report.md` and the screenshots. **Verify important
   claims against the code or by re-checking** before presenting them.
5. Report findings with paths to the artifacts.

## Prompting Codex

Codex is not Claude — prompt it simpler:

- One plain paragraph: what to run, what to check, where to put output.
- No role-play, no elaborate constraints; it doesn't do things you didn't
  ask for.
- Always require: "if you find nothing wrong, say so explicitly and state
  what you inspected" — otherwise a clean result looks like a failure and
  triggers pointless re-runs.

## Gotchas

- Long flows can time out; split into smaller `codex exec` calls per flow.
- When called from a subagent or workflow, prefix the subagent name with
  `codex-` so it's visible which agents are delegating.
- Codex cannot see this conversation. The prompt must be fully
  self-contained: paths, commands, ports, credentials source, expectations.
- A "failed" exit code does not mean the work failed. Under
  `danger-full-access` Codex may clean up processes on its own and can kill
  its wrapper shell (observed: exit 144 after the report was written).
  Always check the artifact dir for `report.md` before treating a nonzero
  exit as failure.

---
name: codex-second-opinion
description: Get an independent second opinion from the Codex CLI (GPT-5.5) on a code-behavior claim, diagnosis, or review verdict BEFORE delivering it. Use when a claim Claude made is disputed or contested, when the answer will drive a trade, deploy, incident verdict, or debate with a colleague, when the user asks "are you sure?" / "double-check that" / "verify independently", or before posting a diagnosis to an issue tracker or chat. Codex is near-free; an independent confirmation costs one command.
---

# Codex Second Opinion

Delegate an independent read of the code to `codex exec` (GPT-5.5) before
delivering a contested or high-stakes claim. The value is independence:
Codex must reach its conclusion from the code alone, not from your
reasoning — so never tell it what you concluded.

## When

- A code-behavior claim you made is being disputed ("that's wrong",
  "LLMBS", a colleague disagrees)
- The verdict drives a trade, deploy, rollback, or incident report
- The user asks to double-check, verify independently, or "are you sure?"
- Before posting a diagnosis to an issue / PR / team chat

Not for: style opinions, questions answerable by running a test you
already have, or claims about this conversation rather than the code.

## Workflow

1. **Reduce the claim to neutral, falsifiable questions.** Ask what the
   code *does*, never whether you were *right*. Bad: "confirm that late
   fills are dropped." Good: "when state is Stopped and a fill arrives,
   which functions run and what state results?" Include line numbers or
   function names so answers are checkable.

2. **Pick the input route** (bwrap sandbox is broken on this box —
   `bwrap: loopback: Failed RTM_NEWADDR` — so default sandboxes can't
   read files):

   - **Bounded material (default): pipe excerpts via stdin.** No
     sandbox, no file access needed:

     ```bash
     { echo "<questions, one plain paragraph>";
       echo "=== fn decide_stopped (lines 1050-1200) ===";
       sed -n '1050,1200p' src/spreader.rs;
     } | codex exec - 2>/dev/null
     ```

     Label each excerpt with real line numbers. Include enough
     surrounding code that the answer isn't forced; deliberately
     include code that could refute you.

   - **Whole-repo reads:** `codex exec -s danger-full-access -C <repo>
     "<prompt>"` — only when excerpts genuinely can't bound the
     question, and only in a repo where write access is acceptable
     (use a scratch worktree).

3. **Require refusal over guessing.** End every prompt with: "Answer
   strictly from the code, citing line numbers. Say 'not found' for
   anything the code shown doesn't cover, rather than guessing."

4. **Compare verdicts.**
   - Agrees → report, and cite the independent confirmation.
   - Disagrees → treat as a real signal; re-read the code at the cited
     lines yourself before deciding which of you is wrong.
   - "Not found" → your excerpt was insufficient; widen it and rerun.
     Never count a non-answer as agreement.

5. **Report honestly.** Name the tool ("independent GPT-5.5 review
   concurred / dissented"), including when it dissented and you
   overrode it — say why.

## Prompting Codex

- One plain paragraph of questions; numbered sub-questions are fine.
- Fully self-contained — Codex cannot see this conversation.
- No role-play, no "you are a reviewer" framing; just the questions
  and the code.
- Never include your own conclusion, hypothesis, or the direction of
  the dispute — that turns a second opinion into an echo.

## Gotchas

- Trailing debug/OTEL noise wraps Codex's answer on stderr; use
  `2>/dev/null` and read the whole stdout, not just `tail`.
- Codex refusing ("I can't read files") is a sandbox failure, not a
  verdict — switch input routes and rerun.
- One dissent doesn't settle a dispute either; the code does. Use the
  dissent's cited lines as the re-read list.

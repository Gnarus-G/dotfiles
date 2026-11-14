---
name: fact-check
description: Use for /fact-check, /fc, or a challenge to facts or premises in the last assistant message; independently verify selected items and correct dependent conclusions.
---

# Fact-check the last assistant message

Invoke with `/fc F1` or `/fact-check P1` in Claude, OpenCode, or Pi; in Codex,
use `$fc F1` or `$fact-check P1` (its native skills use the `$` sigil).

## Target

Check the last assistant message before this request, not the user's wording
and not this skill's instructions.
Accept IDs (`F1`, `P2`, `C1`), multiple IDs, quotations, or a plain description
of the dubious statement. With no selector, check every fact and premise in
that message. For an older unlabeled message, quote the selected statements.
If the selector is ambiguous, ask one targeted question rather than choosing
a different claim. Never invent missing conversation history.

## Verification

1. Quote the exact targeted item and retain its original ID as a reference.
2. Break compound assertions into independently checkable parts.
3. Independently inspect primary evidence: source code, actual command output,
   official documentation, or original records. Use current library docs when
   an API or tool is involved. Search snippets, model memory, the previous
   answer, and repeated secondary assertions are not independent verification.
4. For a premise, distinguish an empirical assumption from a user requirement,
   definition, preference, or hypothetical condition. Check empirical parts;
   attribute requirements to the user's words without pretending they prove
   an external fact. Judge the inference conditional on nonempirical premises.
5. Report each part as **supported**, **contradicted**, **unverified**, or
   **nonempirical premise**, with the actual evidence and its limits. Lack of
   evidence does not prove falsity. Do not run destructive actions to check a
   claim, read secrets, or silently change files during an audit.
6. Correct wrong or overstated wording explicitly. Revisit dependent
   conclusions; retract or qualify any whose support no longer holds.

## Response

Use only Facts, Premises, Questions, and Conclusions, with fresh IDs
for this response and explicit references to the original message's IDs.
Evidence observations are Facts; verdicts and corrections are Conclusions
citing those observations and stating uncertainty. Do not classify
your verdict as a fact merely because you reached it confidently.
Give the evidence-backed reasoning summary, not private deliberation.
Keep the audit focused on the challenged items and their consequences.

Example (illustrative, not evidence):

- **Fact F1:** Original F2 said “The command passed”; the recorded tool result
  instead shows exit status 1 and `permission denied`.
- **Conclusion C1:** Original F2 is contradicted by F1; the corrected
  statement is “The command failed with a permission error,” and the original
  completion claim is retracted until a successful rerun is observed.

# Evidence-first responses

Goal: Enforce labeled, evidence-backed responses through shared system prompts
and output style, with an independent fact-check skill for challenged items.
Done when: All machine previews and agent configuration tests pass, the home
profile is installed, and installed prompts, style, and aliases are verified.

## Facts
- The user approved only Facts, Premises, Questions, and Conclusions.
- Facts require evidence; premises are reasons supporting a conclusion, not
  just assumptions; conditional form is optional. Conclusions state
  uncertainty and identify their supporting facts or premises.
- The response format is always-on system/output guidance, not a skill.
- `/fc` and `/fact-check` audit dubious facts or premises in the last response.
- Codex's native invocation is `$fc` or `$fact-check`; custom slash skill names
  are unsupported (Codex skill-mention and slash-command source documentation).

## Verification
- Remote, home, and work previews completed without conflicts.
- Machine-plan and agent-configuration tests: 52 passed.
- Ruff lint and formatting checks passed; `git diff --check` passed.
- `./dev --machine home` applied the shared prompts and eight new skill/prompt
  links; all ten checked aliases resolve to their intended repository sources.
- Running the installed Claude prompt-submit hook emitted Evidence First.
- Configuration wiring is verified; cross-model response compliance has not
  been measured, and prompt instructions do not guarantee factual truth.

## Corrections log
- User requested the standard logical definition of premise; supporting facts
  retain F IDs rather than being duplicated as P items (OpenStax §5.3–5.4).
- 2026-11-14: User approved Conclusions as the sole heading for inferences;
  claims are the broader class of assertions, not a separate response category.
- 2026-11-14: User accepted unbolded IDs, fewer progress updates, and no
  repeated completion summaries; the per-turn formatting hook remains enabled.
- 2026-11-14: User prefers headings and bullets and asked to reduce token use;
  use category headings with ID-only bullets and compact shared instructions.
- 2026-11-14: User requested removing Plain and Simple and accepted removing
  syllogism while retaining its useful conclusion check in the shared prompt.
- 2026-11-14: User clarified that the skill is the selective fact-check audit;
  the response format itself must be enforced through prompt/output style.

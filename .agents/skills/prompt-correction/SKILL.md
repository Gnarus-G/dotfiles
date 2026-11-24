---
name: prompt-correction
description: Turn a correction of agent behaviour into a small, lasting edit of the instruction that caused it — a global prompt, a skill, or a project's CLAUDE.md/AGENTS.md — and follow the corrected rule for the rest of the session. Use when the user dislikes or corrects what an agent did ("I don't like that", "don't do X again", "why did you…", "that surprised me") or asks to update the system prompt or a skill. A fact about the current effort goes to goal instead.
---

# prompt-correction

A correction that stays in the chat is lost next session. Find the
instruction that produced the behaviour, fix it at its source, and behave
the new way now.

## 1. Name it

One sentence: what the agent did and what the user wants instead, with the
user's words quoted.

## 2. Find the cause

Search what the session loaded and read the matching lines. The cause is a
rule that says to do it, two rules that disagree, or a gap. Bare paths are
in `~/d/dotfiles`; `machine-config` explains its scopes and install.

| Surface | Source to edit |
| --- | --- |
| Global prompt, every machine and harness | `profiles/core/instructions.md` |
| Home + work only; Codex only | `profiles/desktop/instructions.md`; `profiles/desktop/codex.md` |
| One machine | `profiles/<machine>/instructions.md` or `codex.md` |
| Skill | `readlink -f ~/.claude/skills/<name>`: `.agents/skills/`, `.claude.only/skills/`, `.codex.only/skills/` or `~/agent-skills` |
| Output style, subagent, command | `.claude/output-styles/`, `profiles/core/.claude/agents/`, `.codex/agents/`, `.config/opencode/{agent,command}/` |
| Project rule or skill | that repo's `CLAUDE.md`/`AGENTS.md` (nested ones too), `.claude/skills/`, `.agents/skills/`; edit it there |

Never edit `.machine-generated/`, nor `~/.claude/CLAUDE.md` and
`~/.codex/AGENTS.md`, which link into it. The repo's own `AGENTS.md` is
its project instructions, not the global prompt. A skill with no file
behind `readlink` is built into the harness: fix the skill or prompt that
calls it.

Pick the narrowest owner. A rule only one skill or project needs goes
there, not in the global prompt.

## 3. Propose, then apply

Show the exact diff: the smallest change that fixes the behaviour, in the
file's voice. If a rule already covers it, sharpen that rule instead of
adding another. Two sources that disagree are a finding: quote both and fix
the wrong one; do not add a third rule to referee. Apply only after the
user says yes.

## 4. Land it

- Dotfiles: after a `profiles/` edit, run
  `python3 -B machine_preview.py <machine>` then `./dev --machine <machine>`
  (the machine is in `readlink ~/.claude/CLAUDE.md`). A new skill also needs
  its link in `machine_plan.py`. Commit as `<area>: <change>`.
- Another repo: follow its branch and commit rules; ask before pushing.
- Say what is different from now on, and act on it in this session: the
  loaded prompt does not reload until the next one.

## Example

The user said "full send". `full-send` step 7 said "Run `/ship` on the PR:
merge, deploy, prove", yet the agent stopped at green CI and asked the user
to merge. Cause: in Claude Code `/ship` is the built-in `ship-local`
("Claude is told never to merge the pull request"), which shadowed the
dotfiles `ship` skill, and ramp's CLAUDE.md says "The user merges to main".
Fix: the dotfiles skill became `land`, and `full-send` now gets merge
approval with the plan. No new global rule.

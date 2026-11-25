---
name: revise-prompts
description: Revise prompts, instructions, or skills at their managed source, verify and install them, and commit dotfiles changes directly to main. Use when asked to change a prompt or skill, or when the user corrects agent behaviour ("don't do X again", "why did you…", "it should follow our pattern"). A fact about the current effort goes to goal instead.
---

# revise-prompts

A correction that stays in the chat is lost next session. Fix the owning
instruction, verify the result, and use the corrected rule now.

## 1. Name it

State the requested behaviour in one sentence, quoting the user's words.
A request to revise authorizes the edit and its dotfiles commit; do not
add a separate approval pause. An explanation-only question does not:
answer it without editing. Ask only when a missing decision changes the fix.

## 2. Find the cause

Inspect status and the existing diff before editing. If an intended file
already contains unrelated edits, isolate your revision or ask before
including them; `git-ac` commits whole named files, not selected hunks.

Read `machine-config` and the owning repo's instructions. Search what the
session loaded for the rule, conflict, or gap that caused the behaviour.
Resolve installed links to their sources before editing. Bare paths below
are in `~/d/dotfiles`.

| Surface | Source to edit |
| --- | --- |
| Global prompt, every machine and harness | `profiles/core/instructions.md` |
| Home + work only | `profiles/desktop/instructions.md` |
| Codex only, home + work | `profiles/desktop/codex.md` |
| One machine | `profiles/<machine>/instructions.md` or `codex.md` |
| Skill | Resolve its installed link: `.agents/skills/`, `.claude.only/skills/`, `.codex.only/skills/`, or the external repo it points into |
| OpenCode JSON | `profiles/core/.config/opencode/opencode.json`, then desktop and machine overlays |
| Claude settings | `profiles/core/.claude/settings.json`, desktop `.claude/settings.json`, then machine overlay |
| Review model and effort | Managed native configs under `profiles/core/.claude/agents/` and `profiles/core/.codex/`; register links in `machine_plan.py` |
| Output style, other subagent, command | `.claude/output-styles/`, `.codex/agents/`, `.config/opencode/{agent,command}/`; check the inventory for scope |
| Project rule or skill | that repo's `CLAUDE.md`/`AGENTS.md` (nested ones too), `.claude/skills/`, `.agents/skills/`; edit it there |

Global prompts and JSON are composed by `machine_bundle.py`, installed by
`./dev --machine <machine>`, and journaled for undo. Never edit
`.machine-generated/` or its installed links. These include Claude, Codex,
Pi instructions and OpenCode JSON. The repo's `AGENTS.md` owns project
rules, not the global prompt. For a built-in skill, revise its caller.

Pick the narrowest owner and state its machine and harness scope.
`machine_plan.py` gates links with `CORE`, `DESKTOP`, or a machine set.
`SHARED_SKILLS` reaches the shared harness projections; `CLAUDE_SKILLS`
reaches Claude only. A rename adds the old targets as inactive specs so
installation removes managed links, including dangling links.

Choose model and reasoning effort intentionally for the task, quality,
latency, and cost. Put those choices in scoped native configuration, then
invoke its named agent or profile. A review role can use high effort while
the general agent uses medium. Do not scatter model literals through skill
commands or rely on an accidental inherited default. For example:

```bash
codex exec --profile review "Review this diff"
```

For MCP entries, edit `.config/mcp/mcp.json`; the installer adapts and
merges them into harness-owned config. Do not replace those whole files.
Do not edit an external skill as though dotfiles owned its installation.

## 3. Revise and verify

Make the smallest edit in the file's voice. Sharpen an existing rule rather
than adding a duplicate. When two sources disagree, fix the wrong owner
instead of adding a third rule to referee.

Run relevant tests and available linters. For inventory or configuration
changes, preview all three machines with `python3 -B machine_preview.py
<machine>` and check both wanted links and removals. Detect this machine
from the installed generated-config link, then run `./dev --machine
<machine>`. Report conflicts without overwriting unrelated local files.
Verify the installed source or rendered value, not just a successful exit.

## 4. Commit on main

For prompt revisions in dotfiles, work in its main checkout and commit
directly to `main`; this is an exception to the usual worktree/PR workflow.
If another branch is checked out, locate the main checkout rather than
switching a dirty tree or committing on the wrong branch.

Inspect status, the diff, and recent history. Use the `commit` skill with
only this revision's paths (`git-ac -y -- <paths>`); leave unrelated work
alone. Commit after verification without another confirmation. Do not push
unless asked. In another repo, follow its own branch and commit rules.

Report the commit, changed behaviour, and verification. Follow the revised
rule now; restart the affected harness when its loaded config needs it.

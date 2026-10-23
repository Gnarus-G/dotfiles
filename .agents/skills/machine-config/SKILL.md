---
name: machine-config
description: Use when installing or configuring a tool that changes dotfiles, agent instructions, skills, or tool availability differently on remote, home, and work machines.
---

# Machine-aware config changes

Keep one main branch. Put shared behavior in common sources and machine-only
behavior in additive fragments or JSON overlays; do not maintain a branch per
machine or commit rendered files. Line-based patches to JSON or Markdown are
fragile when common content moves.

1. Inspect the tool's current config, its integrations, and all paths it reads
   or writes. Decide whether each addition belongs on all machines, desktops
   (`home` + `work`), or just one machine; do not infer scope from the machine
   on which the installer happened to run.
2. For agent prompt text, edit `profiles/core/instructions.md` for shared
   instructions, `profiles/desktop/instructions.md` for desktop-only text, or
   `profiles/<machine>/instructions.md` for one machine.
   Codex-only desktop instructions live in `profiles/desktop/codex.md`.
3. For OpenCode JSON, edit the base at
   `profiles/core/.config/opencode/opencode.json` or the desktop overlay at
   `profiles/desktop/.config/opencode/opencode.json`, or a machine-specific
   `profiles/<machine>/.config/opencode/opencode.json`; objects merge recursively,
   while arrays and scalar values replace the base value. Claude settings use
   `profiles/core/.claude/settings.json` as base, `.claude/settings.json` as
   desktop overlay, and optional `profiles/<machine>/.claude/settings.json`
   for one machine. For another config
   that needs field-level overlays, register its source and output in
   `machine_bundle.py` and its target in `machine_plan.py` rather than editing
   `.machine-generated/` by hand.
4. Add or scope links for any new skill, tool, or whole-file config in
   `machine_plan.py`; update `SHARED_SKILLS` when a shared skill is added.
   Avoid leaking desktop commands into a remote prompt or plugin directory.
5. Run `python3 -B machine_preview.py remote`, `home`, and `work`, inspect the
   `BUILD`, `REMOVE`, and `LINK` lines, and run
   `uv run --with pytest python -m pytest tests/machine_plan_test.py -q`.
   For an actual install, use `./dev --machine <machine>` and restart the
   affected agent or tool so it reloads config.

Example: if a tool needs a desktop-only MCP server, add its `mcp` key to the
desktop JSON overlay; the generated `work/opencode.json` and
`home/opencode.json` gain that server while `remote/opencode.json` does not.

"""Compose machine-specific instructions and JSON without writing files."""

import json
from dataclasses import dataclass
from pathlib import Path

MACHINES = ("remote", "home", "work")


@dataclass(frozen=True)
class Build:
    source: str


def bundle_source(machine: str, name: str) -> str:
    return f".machine-generated/{machine}/{name}"


def merge(base: dict, overlay: dict) -> dict:
    result = base.copy()
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = value
    return result


def render(root: Path, machine: str) -> dict[str, bytes]:
    if machine not in MACHINES:
        raise ValueError(f"unknown machine: {machine}")
    core = (root / "profiles/core/instructions.md").read_text().strip()
    desktop = (
        (root / "profiles/desktop/instructions.md").read_text().strip()
        if machine != "remote"
        else ""
    )
    machine_prompt = root / f"profiles/{machine}/instructions.md"
    local = machine_prompt.read_text().strip() if machine_prompt.exists() else ""
    shared = "\n\n".join(part for part in (core, desktop, local) if part) + "\n"
    codex = (
        (root / "profiles/desktop/codex.md").read_text().strip()
        if machine != "remote"
        else ""
    )
    machine_codex = root / f"profiles/{machine}/codex.md"
    if machine_codex.exists():
        codex = "\n\n".join(
            part for part in (codex, machine_codex.read_text().strip()) if part
        )
    config = json.loads(
        (root / "profiles/core/.config/opencode/opencode.json").read_text()
    )
    if machine != "remote":
        overlay = json.loads(
            (root / "profiles/desktop/.config/opencode/opencode.json").read_text()
        )
        config = merge(config, overlay)
    machine_json = root / f"profiles/{machine}/.config/opencode/opencode.json"
    if machine_json.exists():
        config = merge(config, json.loads(machine_json.read_text()))
    claude_settings = json.loads(
        (root / "profiles/core/.claude/settings.json").read_text()
    )
    if machine != "remote":
        claude_settings = merge(
            claude_settings, json.loads((root / ".claude/settings.json").read_text())
        )
    machine_claude = root / f"profiles/{machine}/.claude/settings.json"
    if machine_claude.exists():
        claude_settings = merge(claude_settings, json.loads(machine_claude.read_text()))
    return {
        bundle_source(machine, "claude.md"): shared.encode(),
        bundle_source(machine, "codex.md"): (
            shared.rstrip() + ("\n\n" + codex if codex else "") + "\n"
        ).encode(),
        bundle_source(machine, "pi.md"): shared.encode(),
        bundle_source(machine, "claude-settings.json"): (
            json.dumps(claude_settings, indent=2, ensure_ascii=False) + "\n"
        ).encode(),
        bundle_source(machine, "opencode.json"): (
            json.dumps(config, indent=2, ensure_ascii=False) + "\n"
        ).encode(),
    }

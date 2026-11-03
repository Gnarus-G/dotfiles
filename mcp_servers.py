"""Distribute one canonical MCP server list to every harness.

Pi and OpenCode read a file the dotfiles link, so they need nothing here.
Claude Code and Codex keep their servers in files they own and rewrite, so
their entries are merged into place instead of linked.
"""

import json
from dataclasses import dataclass
from pathlib import Path

CANONICAL = ".config/mcp/mcp.json"
CLAUDE_CONFIG = ".claude.json"
CODEX_CONFIG = ".codex/config.toml"


@dataclass(frozen=True)
class Merge:
    target: str
    names: tuple[str, ...]


def servers(root: Path) -> dict[str, dict]:
    """Read the canonical server list; an absent file means no servers."""
    path = root / CANONICAL
    if not path.exists():
        return {}
    return json.loads(path.read_text()).get("mcpServers", {})


def opencode_entries(entries: dict[str, dict]) -> dict[str, dict]:
    """Shape canonical entries the way OpenCode expects them."""
    return {
        name: {
            "type": "local",
            "command": [entry["command"], *entry.get("args", [])],
            "enabled": True,
        }
        for name, entry in entries.items()
    }


def claude_state(text: str, entries: dict[str, dict]) -> str:
    """Return ~/.claude.json text with the canonical servers merged in."""
    data = json.loads(text) if text.strip() else {}
    current = data.get("mcpServers", {})
    if all(current.get(name) == entry for name, entry in entries.items()):
        return text
    data["mcpServers"] = {**current, **entries}
    return json.dumps(data, indent=2) + "\n"


def codex_state(text: str, entries: dict[str, dict]) -> str:
    """Return ~/.codex/config.toml text with the canonical servers merged in."""
    for name, entry in entries.items():
        text = _replace_codex_table(text, name, entry)
    return text


def _codex_table(name: str, entry: dict) -> list[str]:
    table = [f"[mcp_servers.{name}]"]
    if entry.get("command"):
        table.append(f"command = {json.dumps(entry['command'])}")
    if entry.get("args"):
        table.append(f"args = {json.dumps(entry['args'])}")
    if entry.get("env"):
        table.append(f"env = {json.dumps(entry['env'])}")
    return table


def _replace_codex_table(text: str, name: str, entry: dict) -> str:
    header = f"[mcp_servers.{name}]"
    table = _codex_table(name, entry)
    lines = text.splitlines()
    start = next(
        (index for index, line in enumerate(lines) if line.strip() == header), None
    )
    if start is None:
        prefix = text if not text or text.endswith("\n") else text + "\n"
        if prefix.strip():
            prefix += "\n"
        return prefix + "\n".join(table) + "\n"
    end = start + 1
    while end < len(lines) and not lines[end].lstrip().startswith("["):
        end += 1
    while end > start + 1 and not lines[end - 1].strip():
        end -= 1
    return "\n".join(lines[:start] + table + lines[end:]) + "\n"


def _changes(home: Path, entries: dict[str, dict]):
    for target, state in ((CLAUDE_CONFIG, claude_state), (CODEX_CONFIG, codex_state)):
        path = home / target
        current = path.read_text() if path.exists() else ""
        updated = state(current, entries)
        if updated != current:
            yield target, path, updated


def pending(home: Path, entries: dict[str, dict]) -> tuple[Merge, ...]:
    """Report the harness config files that would change."""
    return tuple(
        Merge(target, tuple(sorted(entries)))
        for target, _path, _updated in _changes(home, entries)
    )


def apply(home: Path, entries: dict[str, dict]) -> tuple[Merge, ...]:
    """Write the canonical servers into the harness config files."""
    merges = []
    for target, path, updated in _changes(home, entries):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(updated)
        merges.append(Merge(target, tuple(sorted(entries))))
    return tuple(merges)

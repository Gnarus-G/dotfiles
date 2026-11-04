"""Merge tracked fx settings into its regular, locally writable settings file."""

import json
from pathlib import Path

from machine_bundle import merge
from mcp_servers import Merge

CONFIG = ".fx/settings.json"


def pending(root: Path, home: Path) -> tuple[Merge, ...]:
    source = root / CONFIG
    if not source.exists():
        return ()
    settings = json.loads(source.read_text())
    target = home / CONFIG
    if target.is_symlink():
        raise ValueError(f"fx requires a regular settings file: {target}")
    previous = target.read_text() if target.exists() else None
    current = json.loads(previous) if previous else {}
    updated = merge(current, settings)
    if updated == current:
        return ()
    return (
        Merge(
            CONFIG,
            tuple(sorted(settings)),
            previous,
            json.dumps(updated, indent=2) + "\n",
        ),
    )


def apply(root: Path, home: Path) -> tuple[Merge, ...]:
    effects = pending(root, home)
    for effect in effects:
        target = home / effect.target
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(effect.updated)
    return effects

"""Apply a conflict-free machine plan."""

import argparse
import os
import sys
from pathlib import Path

from machine_bundle import Build, render
from machine_plan import (
    DESKTOP,
    MACHINES,
    PROPOSED,
    Conflict,
    Link,
    Remove,
    color_enabled,
    format_conflicts,
    plan,
)
from machine_preview import snapshot
import mcp_servers
import machine_history


class PlanBlocked(ValueError):
    """The machine plan has conflicts and made no changes."""

    def __init__(self, conflicts: tuple[Conflict, ...], home: Path):
        self.conflicts = conflicts
        self.home = home
        super().__init__(format_conflicts(conflicts, home))


def _write_bundles(root: Path, bundles: dict[str, bytes]) -> tuple[Build, ...]:
    built = []
    for source, content in bundles.items():
        path = root / source
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists() or path.read_bytes() != content:
            previous = path.read_text() if path.exists() else None
            temporary = path.with_suffix(path.suffix + ".next-machine-plan")
            if temporary.exists() or temporary.is_symlink():
                raise RuntimeError(f"temporary bundle already exists: {temporary}")
            temporary.write_bytes(content)
            os.replace(temporary, path)
            built.append(Build(source, previous))
    return tuple(built)


def _apply_removals(home: Path, effects: tuple):
    for removal in (effect for effect in effects if isinstance(effect, Remove)):
        (home / removal.target).unlink()


def _apply_links(root: Path, home: Path, effects: tuple):
    for effect in (effect for effect in effects if isinstance(effect, Link)):
        target = home / effect.target
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink():
            temporary = target.with_name(target.name + ".next-machine-plan")
            if temporary.exists() or temporary.is_symlink():
                raise RuntimeError(f"temporary link already exists: {temporary}")
            temporary.symlink_to(root / effect.source)
            os.replace(temporary, target)
        else:
            target.symlink_to(root / effect.source)


def _describe(item) -> str:
    if isinstance(item, Build):
        return f"BUILD  {item.source}"
    if isinstance(item, Remove):
        return f"REMOVE ~/{item.target} (was -> {item.previous})"
    if isinstance(item, Link):
        was = f" (was -> {item.previous})" if item.previous is not None else ""
        return f"LINK   ~/{item.target} -> {item.source}{was}"
    return f"MERGE  ~/{item.target} ({', '.join(item.names)})"


def install(root: Path, home: Path, machine: str, inventory=PROPOSED):
    observed, available = snapshot(root, home, machine, inventory)
    effects = plan(machine, inventory, observed, available)
    conflicts = tuple(effect for effect in effects if isinstance(effect, Conflict))
    if conflicts:
        raise PlanBlocked(conflicts, home)

    bundles = (
        render(root, machine)
        if any(
            item.source.startswith(".machine-generated/") and machine in item.machines
            for item in inventory
        )
        else {}
    )
    built = _write_bundles(root, bundles)
    _apply_removals(home, effects)
    _apply_links(root, home, effects)
    entries = mcp_servers.servers(root) if machine in DESKTOP else {}
    merges = mcp_servers.apply(home, entries)
    machine_history.record(home, machine, built + effects + merges, bundles)
    return built + effects + merges


def main():
    parser = argparse.ArgumentParser(
        description="Install or undo a machine plan for the selected machine"
    )
    parser.add_argument("--machine", choices=sorted(MACHINES), required=True)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument(
        "command", nargs="?", choices=("install", "undo"), default="install"
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    try:
        if args.command == "undo":
            when, restored = machine_history.undo(root, args.home, args.machine)
            print(f"Undid {len(restored)} effects on {args.home} (install was {when}):")
            for line in restored:
                print(f"  {line}")
            return
        effects = install(root, args.home, args.machine)
        print(f"Applied {len(effects)} effects to {args.home}:")
        for item in effects:
            print(f"  {_describe(item)}")
    except PlanBlocked as error:
        message = format_conflicts(
            error.conflicts, error.home, color=color_enabled(sys.stderr)
        )
        parser.exit(1, f"{message}\n")
    except (machine_history.NothingToUndo, machine_history.PathChanged) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()

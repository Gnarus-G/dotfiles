"""Apply a conflict-free machine plan."""

import argparse
import os
import sys
from pathlib import Path

from machine_bundle import Build, render
from machine_plan import (
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
            temporary = path.with_suffix(path.suffix + ".next-machine-plan")
            if temporary.exists() or temporary.is_symlink():
                raise RuntimeError(f"temporary bundle already exists: {temporary}")
            temporary.write_bytes(content)
            os.replace(temporary, path)
            built.append(Build(source))
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


def install(root: Path, home: Path, machine: str, inventory=PROPOSED):
    observed, available = snapshot(root, home, machine, inventory)
    effects = plan(machine, inventory, observed, available)
    if any(isinstance(effect, Conflict) for effect in effects):
        raise PlanBlocked(effects, home)

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
    return built + effects


def main():
    parser = argparse.ArgumentParser(description="Install a conflict-free machine plan")
    parser.add_argument("--machine", choices=sorted(MACHINES), required=True)
    parser.add_argument("--home", type=Path, default=Path.home())
    args = parser.parse_args()
    try:
        effects = install(Path(__file__).resolve().parent, args.home, args.machine)
    except PlanBlocked as error:
        message = format_conflicts(
            error.conflicts, error.home, color=color_enabled(sys.stderr)
        )
        parser.exit(1, f"{message}\n")
    print(f"Applied {len(effects)} effects to {args.home}")


if __name__ == "__main__":
    main()

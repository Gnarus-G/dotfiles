"""Apply a conflict-free machine plan, staging directory replacements first."""

import argparse
import os
import shutil
import tempfile
from pathlib import Path

from machine_bundle import Build, render
from machine_plan import MACHINES, PROPOSED, Conflict, Link, Remove, plan
from machine_preview import snapshot


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


def _stage_replacements(root: Path, home: Path, effects: tuple, staged: dict):
    for removal in (effect for effect in effects if isinstance(effect, Remove)):
        children = [
            effect
            for effect in effects
            if isinstance(effect, Link)
            and effect.target.startswith(removal.target + "/")
        ]
        if not children:
            continue
        target = home / removal.target
        stage = Path(
            tempfile.mkdtemp(prefix=f".{target.name}-stage-", dir=target.parent)
        )
        staged[removal.target] = stage
        for child in children:
            destination = stage / child.target[len(removal.target) + 1 :]
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.symlink_to(root / child.source)


def _apply_removals(home: Path, effects: tuple, staged: dict) -> set[str]:
    replaced = set()
    for removal in (effect for effect in effects if isinstance(effect, Remove)):
        target = home / removal.target
        if removal.target not in staged:
            target.unlink()
            continue
        backup = target.with_name(target.name + ".previous-machine-plan")
        if backup.exists() or backup.is_symlink():
            raise RuntimeError(f"backup already exists: {backup}")
        target.rename(backup)
        try:
            staged[removal.target].rename(target)
        except BaseException:
            backup.rename(target)
            raise
        backup.unlink()
        del staged[removal.target]
        replaced.add(removal.target)
    return replaced


def _apply_links(root: Path, home: Path, effects: tuple, replaced: set[str]):
    for effect in (effect for effect in effects if isinstance(effect, Link)):
        if any(effect.target.startswith(parent + "/") for parent in replaced):
            continue
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
    observed, available, inspected = snapshot(root, home, machine, inventory)
    effects = plan(machine, inventory, observed, available, inspected)
    if any(isinstance(effect, Conflict) for effect in effects):
        raise ValueError(f"plan blocked: {effects}")

    bundles = (
        render(root, machine)
        if any(
            item.source.startswith(".machine-generated/") and machine in item.machines
            for item in inventory
        )
        else {}
    )
    staged = {}
    try:
        _stage_replacements(root, home, effects, staged)
        # The staged copy is complete before any installed link is removed.
        if (
            plan(machine, inventory, *snapshot(root, home, machine, inventory))
            != effects
        ):
            raise RuntimeError("home or sources changed since the preview")
        built = _write_bundles(root, bundles)
        replaced = _apply_removals(home, effects, staged)
        _apply_links(root, home, effects, replaced)
        return built + effects
    finally:
        for stage in staged.values():
            shutil.rmtree(stage)


def main():
    parser = argparse.ArgumentParser(description="Install a conflict-free machine plan")
    parser.add_argument("--machine", choices=sorted(MACHINES), required=True)
    parser.add_argument("--home", type=Path, default=Path.home())
    args = parser.parse_args()
    effects = install(Path(__file__).resolve().parent, args.home, args.machine)
    print(f"Applied {len(effects)} effects to {args.home}")


if __name__ == "__main__":
    main()

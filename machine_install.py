"""Apply a conflict-free machine plan."""

import argparse
import os
import sys
from pathlib import Path

import fx_settings
import machine_conflicts
import machine_history
import mcp_servers
from machine_bundle import Build, render
from machine_plan import (
    DESKTOP,
    MACHINES,
    PROPOSED,
    Conflict,
    Link,
    Remove,
    Resolve,
    color_enabled,
    format_conflicts,
    paint,
    paint_effect,
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
    if isinstance(item, machine_conflicts.Backup):
        shown = f"~/{item.target}" if item.where == "home" else item.target
        return f"REPLACE {shown} (original saved -> ~/{item.backup})"
    if isinstance(item, Build):
        return f"BUILD  {item.source}"
    if isinstance(item, Remove):
        return f"REMOVE ~/{item.target} (was -> {item.previous})"
    if isinstance(item, Link):
        was = f" (was -> {item.previous})" if item.previous is not None else ""
        return f"LINK   ~/{item.target} -> {item.source}{was}"
    return f"MERGE  ~/{item.target} ({', '.join(item.names)})"


def install(
    root: Path,
    home: Path,
    machine: str,
    inventory=PROPOSED,
    *,
    choices=None,
    resolve_conflict=None,
):
    inventory = tuple(inventory)
    observed, available = snapshot(root, home, machine, inventory)
    effects = plan(machine, inventory, observed, available, choices)
    conflicts = tuple(effect for effect in effects if isinstance(effect, Conflict))
    if conflicts and resolve_conflict is not None:
        sources = {
            item.target: item.source for item in inventory if machine in item.machines
        }
        answers = machine_conflicts.choose(
            root, home, conflicts, sources, resolve_conflict
        )
        choices = {**(choices or {}), **answers}
        observed, available = snapshot(root, home, machine, inventory)
        effects = plan(machine, inventory, observed, available, choices)
        conflicts = tuple(effect for effect in effects if isinstance(effect, Conflict))
    if conflicts:
        raise PlanBlocked(conflicts, home)
    for effect in effects:
        if isinstance(effect, Resolve) and effect.choice == "absorb":
            machine_conflicts.validate_absorb(
                root / effect.source, home / effect.target
            )
    fx_settings.pending(root, home)

    bundles = (
        render(root, machine)
        if any(
            item.source.startswith(".machine-generated/") and machine in item.machines
            for item in inventory
        )
        else {}
    )
    applied = []
    try:
        applied.extend(_write_bundles(root, bundles))
        for effect in effects:
            if isinstance(effect, Resolve):
                if effect.choice == "absorb":
                    source = root / effect.source
                    with machine_conflicts.absorbed_source(
                        source, home / effect.target
                    ) as staged:
                        applied.append(
                            machine_conflicts.save(
                                root,
                                home,
                                "root",
                                effect.source,
                                machine_conflicts.fingerprint(staged),
                            )
                        )
                        machine_conflicts.remove_path(source)
                        os.replace(staged, source)
                saved = machine_conflicts.save(
                    root,
                    home,
                    "home",
                    effect.target,
                    machine_conflicts.link_fingerprint(str(root / effect.source)),
                )
                applied.append(saved)
                machine_conflicts.remove_path(home / effect.target)
                _apply_links(root, home, (Link(effect.target, effect.source),))
            else:
                _apply_removals(home, (effect,))
                _apply_links(root, home, (effect,))
                applied.append(effect)
        entries = mcp_servers.servers(root) if machine in DESKTOP else {}
        applied.extend(mcp_servers.apply(home, entries))
        applied.extend(fx_settings.apply(root, home))
    finally:
        machine_history.record(home, machine, tuple(applied), bundles)
    return tuple(applied)


def main():
    parser = argparse.ArgumentParser(
        description="Install or undo a machine plan for the selected machine"
    )
    parser.add_argument("--machine", choices=sorted(MACHINES), required=True)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument(
        "--non-interactive",
        action="store_true",
        help="fail on conflicts instead of prompting",
    )
    parser.add_argument(
        "command", nargs="?", choices=("install", "undo"), default="install"
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    color = color_enabled(sys.stdout)
    try:
        if args.command == "undo":
            when, restored = machine_history.undo(root, args.home, args.machine)
            print(
                paint(
                    f"Undid {len(restored)} effects on {args.home} (install was {when}):",
                    "1",
                    color,
                )
            )
            for line in restored:
                print(f"  {paint_effect(line, color)}")
            return
        resolver = None
        if sys.stdin.isatty() and not args.non_interactive:
            resolver = lambda conflict, source: machine_conflicts.prompt(
                args.home, conflict, source
            )
        effects = install(root, args.home, args.machine, resolve_conflict=resolver)
        print(paint(f"Applied {len(effects)} effects to {args.home}:", "1", color))
        for item in effects:
            print(f"  {paint_effect(_describe(item), color)}")
    except PlanBlocked as error:
        message = format_conflicts(
            error.conflicts, error.home, color=color_enabled(sys.stderr)
        )
        parser.exit(1, f"{message}\n")
    except (machine_history.NothingToUndo, machine_history.PathChanged) as error:
        parser.exit(1, f"{error}\n")
    except (ValueError, OSError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()

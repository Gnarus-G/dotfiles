"""Read-only snapshot and preview of the proposed machine policy."""

import argparse
import sys
from pathlib import Path

import fx_settings
import mcp_servers
from machine_bundle import render
from machine_plan import (
    DESKTOP,
    MACHINES,
    PROPOSED,
    Conflict,
    Link,
    Managed,
    Remove,
    Unmanaged,
    color_enabled,
    format_conflicts,
    paint,
    paint_effect,
    plan,
)


def _observe(root: Path, home: Path, target: str):
    path = home / target
    if path.is_symlink():
        try:
            return Managed(str(path.resolve().relative_to(root)))
        except ValueError:
            return Unmanaged("symlink outside dotfiles")
    if path.exists():
        return Unmanaged("existing directory" if path.is_dir() else "existing file")
    return None


def _record(observed: dict, root: Path, home: Path, target: str, wanted: set[str]):
    current = _observe(root, home, target)
    if current is not None and (
        current != Unmanaged("existing directory") or target in wanted
    ):
        observed[target] = current


def snapshot(root: Path, home: Path, machine: str, inventory=PROPOSED):
    targets = {item.target for item in inventory}
    wanted = {item.target for item in inventory if machine in item.machines}
    observed = {}

    for target in targets:
        _record(observed, root, home, target, wanted)
        for parent in Path(target).parents:
            if str(parent) != ".":
                _record(observed, root, home, str(parent), wanted)

    available = {item.source for item in inventory if (root / item.source).exists()}
    if any(
        item.source.startswith(".machine-generated/") and machine in item.machines
        for item in inventory
    ):
        available.update(render(root, machine))
    return observed, available


def main():
    parser = argparse.ArgumentParser(
        description="Preview machine dotfile links; never apply them"
    )
    parser.add_argument("machine", choices=sorted(MACHINES))
    parser.add_argument(
        "--assume-sources-present",
        action="store_true",
        help="show hypothetical effects even when proposed sources do not exist",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    color = color_enabled(sys.stdout)
    observed, available = snapshot(root, Path.home(), args.machine)
    result = plan(
        args.machine,
        PROPOSED,
        observed,
        available_sources=None if args.assume_sources_present else available,
    )
    conflicts = tuple(action for action in result if isinstance(action, Conflict))
    if not conflicts:
        for source, content in render(root, args.machine).items():
            path = root / source
            if not path.exists() or path.read_bytes() != content:
                print(
                    paint_effect(
                        f"BUILD  {source} ({len(content)} bytes from common + {args.machine} overlays)",
                        color,
                    )
                )
    if conflicts:
        print(
            format_conflicts(
                conflicts,
                Path.home(),
                color=color,
                closing="Preview only; nothing was installed.",
            )
        )
        sys.exit(1)
    for action in result:
        if isinstance(action, Remove):
            print(
                paint_effect(
                    f"REMOVE ~/{action.target} (currently -> {action.previous})", color
                )
            )
        elif isinstance(action, Link):
            print(paint_effect(f"LINK   ~/{action.target} <- {action.source}", color))
    entries = mcp_servers.servers(root) if args.machine in DESKTOP else {}
    merges = mcp_servers.pending(Path.home(), entries) + fx_settings.pending(
        root, Path.home()
    )
    for merge in merges:
        print(paint_effect(f"MERGE  ~/{merge.target} ({', '.join(merge.names)})", color))
    print(
        paint(
            f"Ready: {sum(isinstance(a, Remove) for a in result)} removals, "
            f"{sum(isinstance(a, Link) for a in result)} links, "
            f"{len(merges)} merges (preview only)",
            "1",
            color,
        )
    )


if __name__ == "__main__":
    main()

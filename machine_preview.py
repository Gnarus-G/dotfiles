"""Read-only snapshot and preview of the proposed machine policy."""

import argparse
from pathlib import Path

from machine_bundle import render
from machine_plan import (
    MACHINES,
    PROPOSED,
    Conflict,
    Link,
    Managed,
    Preserve,
    Remove,
    Unmanaged,
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


def _inspect_retiring_parents(
    root: Path, home: Path, targets: set[str], wanted: set[str], observed: dict
) -> set[str]:
    inspected = set()
    for parent, current in tuple(observed.items()):
        if not isinstance(current, Managed) or parent in wanted:
            continue
        if not any(target.startswith(parent + "/") for target in wanted):
            continue
        pending = [parent]
        while pending:
            directory = pending.pop()
            for child in (home / directory).iterdir():
                relative = str(child.relative_to(home))
                _record(observed, root, home, relative, wanted)
                if child.is_dir() and not child.is_symlink():
                    if any(target.startswith(relative + "/") for target in targets):
                        pending.append(relative)
                    elif relative not in targets:
                        observed[relative] = Unmanaged("existing directory")
        inspected.add(parent)
    return inspected


def snapshot(root: Path, home: Path, machine: str, inventory=PROPOSED):
    targets = {item.target for item in inventory}
    wanted = {item.target for item in inventory if machine in item.machines}
    observed = {}

    for target in targets:
        _record(observed, root, home, target, wanted)
        for parent in Path(target).parents:
            if str(parent) != ".":
                _record(observed, root, home, str(parent), wanted)

    # Inspect only the directory symlinks being replaced by individual links.
    inspected = _inspect_retiring_parents(root, home, targets, wanted, observed)

    available = {item.source for item in inventory if (root / item.source).exists()}
    if any(
        item.source.startswith(".machine-generated/") and machine in item.machines
        for item in inventory
    ):
        available.update(render(root, machine))
    return observed, available, inspected


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
    observed, available, inspected = snapshot(root, Path.home(), args.machine)
    result = plan(
        args.machine,
        PROPOSED,
        observed,
        available_sources=None if args.assume_sources_present else available,
        inspected=inspected,
    )
    if not any(isinstance(action, Conflict) for action in result):
        for source, content in render(root, args.machine).items():
            path = root / source
            if not path.exists() or path.read_bytes() != content:
                print(
                    f"BUILD  {source} ({len(content)} bytes from common + {args.machine} overlays)"
                )
    for action in result:
        if isinstance(action, Conflict):
            print(f"BLOCK  ~/{action.target}: {action.found}")
        elif isinstance(action, Preserve):
            print(
                f"STAGE  ~/{action.target} from {action.source} before replacing its parent"
            )
        elif isinstance(action, Remove):
            print(f"REMOVE ~/{action.target} (currently -> {action.previous})")
        elif isinstance(action, Link):
            print(f"LINK   ~/{action.target} -> {action.source}")
    if any(isinstance(action, Conflict) for action in result):
        print(f"Blocked: {len(result)} conflict(s); no effects")
    else:
        print(
            f"Ready: {sum(isinstance(a, Preserve) for a in result)} preservations, "
            f"{sum(isinstance(a, Remove) for a in result)} removals, "
            f"{sum(isinstance(a, Link) for a in result)} links (preview only)"
        )


if __name__ == "__main__":
    main()

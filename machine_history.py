"""Journal the inverse of applied effects so the last install can be undone."""

import json
import os
import time
from pathlib import Path

import mcp_servers
from machine_bundle import Build
from machine_conflicts import Backup, restore
from machine_plan import Link, Remove

HISTORY = ".local/state/dotfiles/history.jsonl"


class NothingToUndo(Exception):
    """The journal holds no run for the requested machine."""


class PathChanged(Exception):
    """A journalled path changed outside this installer since the run."""


def _inverse(item, bundles: dict[str, bytes]) -> dict:
    """Describe the operation that restores state from one applied effect."""
    if isinstance(item, Backup):
        return {
            "op": "restore",
            "where": item.where,
            "target": item.target,
            "backup": item.backup,
            "previous": item.previous,
            "expects": item.expects,
        }
    if isinstance(item, Build):
        return {
            "op": "write",
            "where": "root",
            "target": item.source,
            "wrote": bundles[item.source].decode(),
            "previous": item.previous,
        }
    if isinstance(item, Remove):
        return {
            "op": "create",
            "where": "home",
            "target": item.target,
            "source": item.previous,
        }
    if isinstance(item, Link):
        if item.previous is None:
            return {
                "op": "unlink",
                "where": "home",
                "target": item.target,
                "expects": item.source,
            }
        return {
            "op": "relink",
            "where": "home",
            "target": item.target,
            "source": item.previous,
            "expects": item.source,
        }
    if isinstance(item, mcp_servers.Merge):
        return {
            "op": "write",
            "where": "home",
            "target": item.target,
            "wrote": item.updated,
            "previous": item.previous,
        }
    raise ValueError(f"cannot undo effect: {item}")


def record(home: Path, machine: str, items: tuple, bundles: dict[str, bytes]):
    """Append one run's inverse operations; a run with no effects is skipped."""
    operations = [_inverse(item, bundles) for item in reversed(items)]
    if not operations:
        return
    path = home / HISTORY
    path.parent.mkdir(parents=True, exist_ok=True)
    entry = {
        "machine": machine,
        "time": time.strftime("%Y-%m-%d %H:%M:%S"),
        "undo": operations,
    }
    with path.open("a") as journal:
        journal.write(json.dumps(entry) + "\n")


def _runs(home: Path) -> list[dict]:
    path = home / HISTORY
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


def _apply(root: Path, home: Path, op: dict) -> str:
    """Reverse one operation, tolerating a partially applied earlier undo."""
    place = home if op["where"] == "home" else root
    path = place / op["target"]
    kind = op["op"]
    if kind == "restore":
        try:
            restore(root, home, op)
        except ValueError as error:
            raise PathChanged(str(error)) from error
    elif kind == "unlink":
        _unlink(path, root, op["expects"])
    elif kind == "relink":
        _relink(root, path, op["source"], op["expects"])
    elif kind == "create":
        _create(root, path, op["source"])
    else:
        _write(path, op["wrote"], op["previous"])
    shown = f"~/{op['target']}" if op["where"] == "home" else op["target"]
    if kind == "unlink" or (kind == "write" and op["previous"] is None):
        return f"REMOVE   {shown}"
    if kind in {"relink", "create"}:
        return f"LINK     {shown} <- {op['source']}"
    return f"RESTORED {shown}"


def _points_to(path: Path, root: Path, source: str) -> bool:
    return path.is_symlink() and path.readlink() == root / source


def _swap(root: Path, path: Path, source: str) -> None:
    temporary = path.with_name(path.name + ".next-machine-plan")
    if temporary.exists() or temporary.is_symlink():
        raise RuntimeError(f"temporary link already exists: {temporary}")
    temporary.symlink_to(root / source)
    os.replace(temporary, path)


def _store(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".next-machine-plan")
    if temporary.exists() or temporary.is_symlink():
        raise RuntimeError(f"temporary file already exists: {temporary}")
    temporary.write_text(text)
    os.replace(temporary, path)


def _unlink(path: Path, root: Path, expects: str) -> None:
    if _points_to(path, root, expects):
        path.unlink()
    elif path.is_symlink() or path.exists():
        raise PathChanged(f"{path} changed since the journalled run.")


def _relink(root: Path, path: Path, source: str, expects: str) -> None:
    if _points_to(path, root, source):
        return
    if not _points_to(path, root, expects):
        raise PathChanged(f"{path} changed since the journalled run.")
    _swap(root, path, source)


def _create(root: Path, path: Path, source: str) -> None:
    if _points_to(path, root, source):
        return
    if path.exists() or path.is_symlink():
        raise PathChanged(f"{path} changed since the journalled run.")
    path.parent.mkdir(parents=True, exist_ok=True)
    _swap(root, path, source)


def _write(path: Path, wrote: str, previous: str | None) -> None:
    current = path.read_text() if path.exists() else None
    if current == wrote:
        if previous is None:
            path.unlink()
        else:
            _store(path, previous)
    elif current != previous:
        raise PathChanged(f"{path} changed since the journalled run.")


def undo(root: Path, home: Path, machine: str) -> tuple[str, tuple[str, ...]]:
    """Reverse the machine's last journalled run and drop it from the journal.

    Returns the journalled run time and a description of every operation.
    """
    runs = _runs(home)
    index = next(
        (
            position
            for position in range(len(runs) - 1, -1, -1)
            if runs[position]["machine"] == machine
        ),
        None,
    )
    if index is None:
        raise NothingToUndo(f"Nothing to undo for {machine}.")
    restored = tuple(_apply(root, home, op) for op in runs[index]["undo"])
    when = runs[index]["time"]
    (home / HISTORY).write_text(
        "".join(
            json.dumps(run) + "\n"
            for position, run in enumerate(runs)
            if position != index
        )
    )
    return when, restored

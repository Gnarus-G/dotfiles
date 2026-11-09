"""Filesystem backups for explicitly approved conflict resolutions."""

import hashlib
import os
import shutil
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Backup:
    where: str
    target: str
    backup: str
    previous: str
    expects: str


class Cancelled(ValueError):
    """User cancelled before any effects were applied."""


DIRECT_CONFLICTS = {"existing file", "existing directory", "symlink outside dotfiles"}


def choose(root, home, conflicts, sources, ask):
    before = {}
    for conflict in conflicts:
        if conflict.found in DIRECT_CONFLICTS:
            target = home / conflict.target
            before[conflict.target] = (
                fingerprint(target),
                fingerprint(target.resolve()),
                fingerprint(root / sources[conflict.target]),
            )
    choices = {}
    try:
        for conflict in conflicts:
            choice = ask(conflict, root / sources[conflict.target])
            if choice == "quit":
                raise Cancelled("Installation cancelled; nothing changed.")
            choices[conflict.target] = choice
    except (EOFError, KeyboardInterrupt) as error:
        raise Cancelled("Installation cancelled; nothing changed.") from error
    for target, state in before.items():
        choice = choices[target]
        path = home / target
        current = (
            fingerprint(path),
            fingerprint(path.resolve()),
            fingerprint(root / sources[target]),
        )
        if choice != "skip" and (
            current[0] != state[0] or (choice == "absorb" and current != state)
        ):
            raise ValueError(f"{path} changed while choosing; rerun the installer.")
    return choices


def prompt(home: Path, conflict, source: Path) -> str:
    target = home / conflict.target
    print(f"\nConflict: {target} ({conflict.found})")
    if target.is_symlink():
        print(f"  Existing link: {target.readlink()}")
    print(f"  Repository: {source}")
    options = {"s": "skip", "q": "quit"}
    if conflict.found in DIRECT_CONFLICTS:
        options = {"o": "overwrite", **options}
        if ".machine-generated" not in source.parts:
            try:
                validate_absorb(source, target)
            except ValueError:
                pass
            else:
                options = {"o": "overwrite", "a": "absorb", "s": "skip", "q": "quit"}
    if "o" in options:
        print(
            "  Overwrite backs up the local path and replaces it with a repository link."
        )
    if "a" in options:
        print(
            "  Absorb backs up both originals, merges local content into the repository, then links."
        )
    label = (
        "  "
        + " / ".join(f"[{key}]{value[1:]}" for key, value in options.items())
        + "? "
    )
    while True:
        answer = input(label).strip().lower()
        if answer in options:
            answer = options[answer]
        if answer in options.values():
            return answer


def link_fingerprint(destination: str) -> str:
    return hashlib.sha256(b"link\0" + os.fsencode(destination)).hexdigest()


def fingerprint(path: Path) -> str | None:
    """Compare contents, permissions, and link text without following symlinks."""
    if path.is_symlink():
        return link_fingerprint(str(path.readlink()))
    if not path.exists():
        return None
    digest = hashlib.sha256(str(path.stat().st_mode).encode())
    if path.is_dir():
        for child in sorted(path.iterdir()):
            digest.update(os.fsencode(child.name) + b"\0")
            digest.update(fingerprint(child).encode())
    elif path.is_file():
        with path.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(block)
    else:
        raise ValueError(f"cannot back up special file: {path}")
    return digest.hexdigest()


def copy_path(source: Path, target: Path):
    if source.is_symlink():
        target.symlink_to(source.readlink())
    elif source.is_dir():
        shutil.copytree(source, target, symlinks=True)
    else:
        shutil.copy2(source, target)


def remove_path(path: Path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def save(root: Path, home: Path, where: str, target: str, expects: str) -> Backup:
    path = (home if where == "home" else root) / target
    previous = fingerprint(path)
    directory = home / ".local/state/dotfiles/backups"
    directory.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix="conflict-", dir=directory)) / "original"
    copy_path(path, backup)
    if fingerprint(backup) != previous:
        raise ValueError(f"{path} changed while backing it up")
    return Backup(where, target, str(backup.relative_to(home)), previous, expects)


def restore(root: Path, home: Path, operation: dict):
    path = (home if operation["where"] == "home" else root) / operation["target"]
    backup = home / operation["backup"]
    current = fingerprint(path)
    if current == operation["previous"]:
        return
    if current not in (None, operation["expects"]):
        raise ValueError(f"{path} changed since the journalled run.")
    if fingerprint(backup) != operation["previous"]:
        raise ValueError(f"Backup changed or missing: {backup}")
    remove_path(path)
    copy_path(backup, path)


def validate_absorb(source: Path, target: Path):
    local = target.resolve()
    canonical = source.resolve()
    if source.is_symlink() or not target.exists():
        raise ValueError(
            f"cannot absorb {target} into {source}: source link or missing target"
        )
    if local.is_relative_to(canonical) or canonical.is_relative_to(local):
        raise ValueError(f"cannot absorb overlapping paths: {target} and {source}")


def _overlay(source: Path, target: Path):
    if (
        source.is_dir()
        and not source.is_symlink()
        and target.is_dir()
        and not target.is_symlink()
    ):
        for child in source.iterdir():
            _overlay(child, target / child.name)
    else:
        remove_path(target)
        copy_path(source, target)


@contextmanager
def absorbed_source(source: Path, target: Path):
    """Prepare the merged source without changing either original."""
    with tempfile.TemporaryDirectory(prefix=".absorb-", dir=source.parent) as directory:
        staged = Path(directory) / "source"
        copy_path(source, staged)
        _overlay(target.resolve(), staged)
        yield staged

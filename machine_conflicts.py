"""Filesystem backups for explicitly approved conflict resolutions."""

import hashlib
import os
import shutil
import sys
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

from machine_plan import color_enabled, paint


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
    color = color_enabled(sys.stdout)

    def shown(path):
        path = Path(path)
        return f"~/{path.relative_to(home)}" if path.is_relative_to(home) else str(path)

    print(
        "\n"
        + paint("  ── Resolve conflict ──────────────────────────────────", "2", color)
    )
    print("  " + paint("●", "33", color) + " " + paint(shown(target), "1;36", color))
    print("    " + paint(conflict.found.capitalize(), "2", color))
    print()
    local = (
        shown(target.readlink())
        if target.is_symlink()
        else "file or directory at this path"
    )
    print("    " + paint("Local", "33", color) + f"       {local}")
    print("    " + paint("Repository", "36", color) + f"  {shown(source)}")
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
    descriptions = {
        "o": (
            "36",
            "Use repository",
            "Back up local path, then replace it with a link.",
        ),
        "a": (
            "32",
            "Keep local content",
            "Merge into repository, then link; back up both originals.",
        ),
        "s": ("33", "Skip this path", "Leave it untouched for this run."),
        "q": ("2", "Quit", "Cancel the whole run; nothing has changed."),
    }
    print()
    for key in options:
        code, title, detail = descriptions[key]
        print("    " + paint(f"[{key}] {title}", "1;" + code, color))
        print("        " + paint(detail, "2", color))
    if "a" in options:
        print(
            "\n    "
            + paint(
                "Merge keeps repository-only files; local files win conflicts.",
                "2",
                color,
            )
        )
    print()
    label = f"  Choose [{' / '.join(options)}] (Enter = skip): "
    while True:
        answer = input(paint(label, "1", color)).strip().lower() or "s"
        if answer in options:
            answer = options[answer]
        if answer in options.values():
            print("  " + paint(f"✓ {answer.capitalize()}", "2", color))
            return answer
        print(
            "  "
            + paint(
                f"Choose {', '.join(options)}, or press Enter to skip.", "33", color
            )
        )


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

from pathlib import Path

import pytest

import machine_conflicts
import machine_history
import machine_install
from machine_install import PlanBlocked, install
from machine_plan import Spec


@pytest.fixture
def sandbox(tmp_path):
    root = tmp_path / "repo"
    home = tmp_path / "home"
    root.mkdir()
    home.mkdir()
    (root / "config").write_text("repository version")
    inventory = (Spec("config", ".config-file", frozenset({"remote"})),)
    return root, home, inventory


@pytest.mark.parametrize("destination", ["../outside", "../missing"])
def test_overwrite_and_undo_preserve_external_symlink(sandbox, destination):
    root, home, inventory = sandbox
    outside = home.parent / "outside"
    outside.write_text("external content")
    target = home / ".config-file"
    target.symlink_to(destination)

    install(root, home, "remote", inventory, choices={".config-file": "overwrite"})

    assert target.readlink() == root / "config"
    assert outside.read_text() == "external content"
    machine_history.undo(root, home, "remote")
    assert target.readlink() == Path(destination)
    assert outside.read_text() == "external content"


def test_absorb_merges_directory_and_undo_restores_both_sides(sandbox):
    root, home, inventory = sandbox
    source = root / "config"
    source.unlink()
    source.mkdir()
    (source / "shared").write_text("repo")
    (source / "repo-only").write_text("keep")
    local = home.parent / "local"
    local.mkdir()
    (local / "shared").write_text("local")
    (local / "local-only").write_bytes(b"\x00\xff")
    (local / "link").symlink_to("missing")
    target = home / ".config-file"
    target.symlink_to("../local")

    install(root, home, "remote", inventory, choices={".config-file": "absorb"})

    assert target.readlink() == source
    assert (source / "shared").read_text() == "local"
    assert (source / "repo-only").read_text() == "keep"
    assert (source / "local-only").read_bytes() == b"\x00\xff"
    assert (source / "link").readlink() == Path("missing")
    machine_history.undo(root, home, "remote")
    assert target.readlink() == Path("../local")
    assert (source / "shared").read_text() == "repo"
    assert sorted(p.name for p in source.iterdir()) == ["repo-only", "shared"]
    assert (local / "shared").read_text() == "local"


def test_collect_choices_before_writes_and_skip_one_target(sandbox):
    root, home, inventory = sandbox
    first = home / ".config-file"
    first.write_text("first local")
    second = home / ".other"
    second.write_text("second local")
    inventory += (Spec("config", ".other", frozenset({"remote"})),)
    asked = []

    def choose(conflict, source):
        assert first.read_text() == "first local"
        assert second.read_text() == "second local"
        assert not (home / machine_history.HISTORY).exists()
        assert source == root / "config"
        asked.append(conflict.target)
        return "overwrite" if conflict.target == ".config-file" else "skip"

    install(root, home, "remote", inventory, resolve_conflict=choose)

    assert asked == [".config-file", ".other"]
    assert first.is_symlink()
    assert second.read_text() == "second local"
    machine_history.undo(root, home, "remote")
    assert first.read_text() == "first local"
    assert not first.is_symlink()


@pytest.mark.parametrize("answer", ["quit", "eof"])
def test_cancel_after_first_choice_changes_nothing(sandbox, answer):
    root, home, inventory = sandbox
    (home / ".config-file").write_text("local")
    (home / ".other").write_text("other")
    inventory += (Spec("config", ".other", frozenset({"remote"})),)

    def choose(conflict, source):
        if conflict.target == ".config-file":
            return "overwrite"
        if answer == "eof":
            raise EOFError
        return answer

    with pytest.raises(machine_conflicts.Cancelled):
        install(root, home, "remote", inventory, resolve_conflict=choose)
    assert (home / ".config-file").read_text() == "local"
    assert (root / "config").read_text() == "repository version"
    assert sorted(p.name for p in home.iterdir()) == [".config-file", ".other"]


def test_change_during_prompt_requires_new_decision(sandbox):
    root, home, inventory = sandbox
    target = home / ".config-file"
    target.write_text("local")

    def choose(conflict, source):
        target.write_text("edited while waiting")
        return "overwrite"

    with pytest.raises(ValueError, match="changed while choosing"):
        install(root, home, "remote", inventory, resolve_conflict=choose)
    assert target.read_text() == "edited while waiting"
    assert not (home / machine_history.HISTORY).exists()


def test_overwrite_directory_restores_permissions_and_nested_links(sandbox):
    root, home, inventory = sandbox
    target = home / ".config-file"
    target.mkdir(mode=0o700)
    (target / "binary").write_bytes(b"\x00\xff")
    (target / "link").symlink_to("../elsewhere")
    before = machine_conflicts.fingerprint(target)
    install(root, home, "remote", inventory, choices={".config-file": "overwrite"})
    machine_history.undo(root, home, "remote")
    assert machine_conflicts.fingerprint(target) == before


def test_absorbed_source_edits_are_not_lost_by_undo(sandbox):
    root, home, inventory = sandbox
    target = home / ".config-file"
    target.write_text("local")
    install(root, home, "remote", inventory, choices={".config-file": "absorb"})
    assert (root / "config").read_text() == "local"
    (root / "config").write_text("new work")
    with pytest.raises(machine_history.PathChanged):
        machine_history.undo(root, home, "remote")
    assert (root / "config").read_text() == "new work"
    assert (home / machine_history.HISTORY).exists()


def test_failed_link_can_be_undone_from_saved_backup(sandbox, monkeypatch):
    root, home, inventory = sandbox
    target = home / ".config-file"
    target.write_text("local")

    def fail(*args):
        raise OSError("link failed")

    monkeypatch.setattr(machine_install, "_apply_links", fail)
    with pytest.raises(OSError, match="link failed"):
        install(root, home, "remote", inventory, choices={".config-file": "overwrite"})
    machine_history.undo(root, home, "remote")
    assert target.read_text() == "local"


def test_generated_configuration_cannot_be_absorbed(sandbox):
    _root, home, _ = sandbox
    target = home / ".config-file"
    target.write_text("local")
    # This root intentionally lacks rendering inputs: absorption must be rejected
    # by the pure planner, before the installer can render or write anything.
    from machine_plan import Conflict, Unmanaged, plan

    source = ".machine-generated/remote/claude.md"
    inventory = (Spec(source, ".config-file", frozenset({"remote"})),)
    effects = plan(
        "remote",
        inventory,
        {".config-file": Unmanaged("existing file")},
        {source},
        {".config-file": "absorb"},
    )
    assert len(effects) == 1 and isinstance(effects[0], Conflict)
    assert "generated source" in effects[0].found


def test_parent_link_conflict_cannot_be_overwritten(sandbox):
    root, home, inventory = sandbox
    outside = home.parent / "outside"
    outside.mkdir()
    (home / ".parent").symlink_to(outside)
    inventory += (Spec("config", ".parent/child", frozenset({"remote"})),)
    (home / ".config-file").write_text("local")
    with pytest.raises(PlanBlocked):
        install(
            root,
            home,
            "remote",
            inventory,
            choices={
                ".config-file": "overwrite",
                ".parent/child": "overwrite",
            },
        )
    assert (home / ".config-file").read_text() == "local"
    assert list(outside.iterdir()) == []


@pytest.mark.parametrize("noninteractive", [False, True])
def test_cli_prompts_only_when_interactive(
    sandbox, monkeypatch, noninteractive, capsys
):
    root, home, inventory = sandbox
    target = home / ".config-file"
    target.write_text("local")
    args = ["dev", "--machine", "remote", "--home", str(home)]
    if noninteractive:
        args.append("--non-interactive")
    monkeypatch.setattr("sys.argv", args)
    monkeypatch.setattr("sys.stdin.isatty", lambda: True)
    prompts = []

    def answer(prompt):
        prompts.append(prompt)
        return "o"

    def sandbox_install(_root, _home, machine, *, resolve_conflict):
        return install(
            root, home, machine, inventory, resolve_conflict=resolve_conflict
        )

    monkeypatch.setattr("builtins.input", answer)
    monkeypatch.setattr(machine_install, "install", sandbox_install)
    if noninteractive:
        with pytest.raises(SystemExit) as error:
            machine_install.main()
        assert error.value.code == 1
        assert not prompts
        assert target.read_text() == "local"
        assert "Nothing changed" in capsys.readouterr().err
    else:
        machine_install.main()
        assert prompts == ["  Choose [o / a / s / q] (Enter = skip): "]
        assert target.readlink() == root / "config"

import os
import subprocess
from pathlib import Path

import pytest

from machine_bundle import Build, bundle_source, merge, render
from machine_install import install
from machine_plan import (
    CLAUDE_SKILLS,
    PROPOSED,
    SHARED_SKILLS,
    Conflict,
    Link,
    Managed,
    Remove,
    Spec,
    Unmanaged,
    plan,
)


def test_remote_removes_managed_speech_without_touching_shared_instructions():
    inventory = (
        Spec(
            "shared/CLAUDE.md",
            ".claude/CLAUDE.md",
            frozenset({"remote", "home", "work"}),
        ),
        Spec("features/speech/tts", ".agents/skills/tts", frozenset({"home", "work"})),
    )
    observed = {
        ".claude/CLAUDE.md": Managed("shared/CLAUDE.md"),
        ".agents/skills/tts": Managed("features/speech/tts"),
    }

    result = plan("remote", inventory, observed)

    assert result == (Remove(".agents/skills/tts", "features/speech/tts"),)


def test_home_links_desktop_and_speech_from_an_empty_inventory():
    inventory = (
        Spec(
            "features/desktop/screenshot.ts",
            ".config/opencode/tools/screenshot.ts",
            frozenset({"home", "work"}),
        ),
        Spec("features/speech/tts", ".agents/skills/tts", frozenset({"home", "work"})),
    )

    assert plan("home", inventory, {}) == (
        Link(".config/opencode/tools/screenshot.ts", "features/desktop/screenshot.ts"),
        Link(".agents/skills/tts", "features/speech/tts"),
    )


def test_foreign_file_causes_conflict_instead_of_overwrite():
    inventory = (Spec("shared/CLAUDE.md", ".claude/CLAUDE.md", frozenset({"remote"})),)

    assert plan(
        "remote", inventory, {".claude/CLAUDE.md": Unmanaged("regular file")}
    ) == (Conflict(".claude/CLAUDE.md", "regular file"),)


def test_unrecognized_machine_cannot_receive_any_links():
    with pytest.raises(ValueError, match="unknown machine"):
        plan("unconfigured", (), {})


def test_reconciliation_leaves_unlisted_managed_links_alone():
    assert plan("remote", (), {".config/custom": Managed("another/repo/file")}) == ()


def test_two_active_sources_for_one_target_are_rejected():
    inventory = (
        Spec("common/prompt.md", ".claude/CLAUDE.md", frozenset({"work"})),
        Spec("work/prompt.md", ".claude/CLAUDE.md", frozenset({"work"})),
    )

    with pytest.raises(ValueError, match="duplicate target"):
        plan("work", inventory, {})


def test_proposed_machine_policy_exposes_only_available_capabilities():
    remote = {action.target for action in plan("remote", PROPOSED, {})}
    home = {action.target for action in plan("home", PROPOSED, {})}
    work = {action.target for action in plan("work", PROPOSED, {})}

    assert ".claude/CLAUDE.md" in remote
    assert ".agents/skills/tts" not in remote
    assert ".config/opencode/tools/screenshot.ts" not in remote
    assert ".config/opencode/opencode.json" in remote
    assert {".agents/skills/tts", ".config/opencode/tools/screenshot.ts"} <= home & work
    assert ".claude/rules/jbcontext.md" not in remote | home | work
    assert ".local/bin/ghostty" in work
    assert ".local/bin/ghostty" not in remote | home


def test_instruction_fragments_and_json_overlays_are_machine_scoped():
    root = Path(__file__).resolve().parents[1]
    remote = render(root, "remote")
    work = render(root, "work")
    assert b"gnarus-tts" not in remote[bundle_source("remote", "claude.md")]
    assert b"gnarus-tts" in work[bundle_source("work", "claude.md")]
    assert b"claude-implement" in work[bundle_source("work", "codex.md")]
    assert b"claude-implement" not in remote[bundle_source("remote", "codex.md")]
    assert b'"convex"' not in remote[bundle_source("remote", "opencode.json")]
    assert b'"convex"' in work[bundle_source("work", "opencode.json")]
    assert (
        b'"SessionStart"' not in remote[bundle_source("remote", "claude-settings.json")]
    )
    assert b'"SessionStart"' in work[bundle_source("work", "claude-settings.json")]
    assert merge(
        {"mcp": {"a": 1}, "plugin": ["old"]}, {"mcp": {"b": 2}, "plugin": ["new"]}
    ) == {
        "mcp": {"a": 1, "b": 2},
        "plugin": ["new"],
    }


def test_changing_a_desktop_fragment_rebuilds_linked_prompt(tmp_path):
    root = tmp_path / "repo"
    home = tmp_path / "home"
    home.mkdir()
    core = root / "profiles/core"
    desktop = root / "profiles/desktop"
    (core / ".config/opencode").mkdir(parents=True)
    (desktop / ".config/opencode").mkdir(parents=True)
    (core / ".claude").mkdir()
    (root / ".claude").mkdir()
    (core / "instructions.md").write_text("Common instruction\n")
    fragment = desktop / "instructions.md"
    fragment.write_text("Desktop instruction\n")
    (desktop / "codex.md").write_text("Codex instruction\n")
    (core / ".config/opencode/opencode.json").write_text('{"mcp":{"base":{}}}')
    (desktop / ".config/opencode/opencode.json").write_text('{"mcp":{"desktop":{}}}')
    (core / ".claude/settings.json").write_text("{}")
    (root / ".claude/settings.json").write_text("{}")
    inventory = (
        Spec(
            bundle_source("home", "claude.md"), ".claude/CLAUDE.md", frozenset({"home"})
        ),
    )
    assert Build(bundle_source("home", "claude.md")) in install(
        root, home, "home", inventory
    )
    target = home / ".claude/CLAUDE.md"
    assert target.read_text() == "Common instruction\n\nDesktop instruction\n"

    fragment.write_text("Updated desktop instruction\n")
    assert Build(bundle_source("home", "claude.md")) in install(
        root, home, "home", inventory
    )
    assert target.read_text() == "Common instruction\n\nUpdated desktop instruction\n"
    assert install(root, home, "home", inventory) == ()

    work = root / "profiles/work"
    (work / ".config/opencode").mkdir(parents=True)
    (work / "instructions.md").write_text("Work-only instruction\n")
    (work / "codex.md").write_text("Work-only Codex instruction\n")
    (work / ".claude").mkdir()
    (work / ".claude/settings.json").write_text('{"model":"work-only"}')
    (work / ".config/opencode/opencode.json").write_text(
        '{"mcp":{"work":{"type":"local"}}}'
    )
    work_bundle = render(root, "work")
    assert b"Work-only instruction" in work_bundle[bundle_source("work", "claude.md")]
    assert (
        b"Work-only Codex instruction" in work_bundle[bundle_source("work", "codex.md")]
    )
    assert b'"work"' in work_bundle[bundle_source("work", "opencode.json")]
    assert b'"work-only"' in work_bundle[bundle_source("work", "claude-settings.json")]
    assert (
        b"Work-only instruction"
        not in render(root, "home")[bundle_source("home", "claude.md")]
    )


def test_missing_source_blocks_a_link_before_installation():
    inventory = (
        Spec("profiles/core/CLAUDE.md", ".claude/CLAUDE.md", frozenset({"remote"})),
    )

    assert plan("remote", inventory, {}, available_sources=frozenset()) == (
        Conflict(".claude/CLAUDE.md", "missing source: profiles/core/CLAUDE.md"),
    )


def test_unmanaged_parent_link_blocks_child_installation():
    inventory = (
        Spec(
            "new/config.json", ".config/opencode/opencode.json", frozenset({"remote"})
        ),
    )

    assert plan(
        "remote", inventory, {".config/opencode": Unmanaged("symlink to elsewhere")}
    ) == (
        Conflict(
            ".config/opencode/opencode.json",
            "unmanaged parent .config/opencode: symlink to elsewhere",
        ),
    )


def test_managed_parent_link_blocks_child_installation():
    inventory = (Spec("new/skill", ".agents/skills/context7", frozenset({"remote"})),)

    assert plan("remote", inventory, {".agents/skills": Managed(".agents/skills")}) == (
        Conflict(
            ".agents/skills/context7",
            "managed parent link .agents/skills",
        ),
    )


def test_switch_and_interrupted_relink_are_replanned_from_observation():
    inventory = (
        Spec(
            "core/settings.json", ".claude/settings.json", frozenset({"remote", "home"})
        ),
        Spec("work/settings.json", ".claude/settings.json", frozenset({"work"})),
    )
    old = {".claude/settings.json": Managed("core/settings.json")}

    assert plan("work", inventory, old) == (
        Link(".claude/settings.json", "work/settings.json", "core/settings.json"),
    )
    assert plan("work", inventory, {}) == (
        Link(".claude/settings.json", "work/settings.json"),
    )
    installed = {".claude/settings.json": Managed("work/settings.json")}
    assert plan("work", inventory, installed) == ()
    assert plan("remote", inventory, installed) == (
        Link(".claude/settings.json", "core/settings.json", "work/settings.json"),
    )


def test_skill_inventory_covers_each_source_set():
    root = Path(__file__).resolve().parents[1]
    shared = {
        p.name
        for p in (root / ".agents/skills").iterdir()
        if p.is_dir() and not p.is_symlink()
    }
    claude = {p.name for p in (root / ".claude.only/skills").iterdir() if p.is_dir()}
    assert shared == set(SHARED_SKILLS) | {"tts", "tmux-processes"}
    assert claude == set(CLAUDE_SKILLS)
    assert {item.target for item in PROPOSED} >= {
        f".config/opencode/skills/{name}" for name in shared - {"tmux-processes"}
    }


def test_opencode_migration_accounts_for_all_top_level_entries():
    root = Path(__file__).resolve().parents[1] / ".config/opencode"
    targets = {item.target for item in PROPOSED}
    # Runtime/package-manager state stays local to each machine.
    runtime = {"node_modules", "package.json", "package-lock.json", "bun.lock"}
    for child in root.iterdir():
        if child.name in runtime:
            continue
        if child.name in {"plugins", "skills", "tools"}:
            assert any(
                target.startswith(f".config/opencode/{child.name}/")
                for target in targets
            )
        else:
            assert f".config/opencode/{child.name}" in targets
    for directory in ("plugins", "skills", "tools"):
        for child in (root / directory).iterdir():
            assert f".config/opencode/{directory}/{child.name}" in targets


def test_install_in_empty_home_is_idempotent_and_remote_excludes_desktop(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    effects = install(root, home, "remote")

    assert effects
    assert (home / ".claude/CLAUDE.md").resolve() == root / bundle_source(
        "remote", "claude.md"
    )
    assert (home / ".config/opencode/opencode.json").resolve() == root / bundle_source(
        "remote", "opencode.json"
    )
    assert not (home / ".agents/skills/tts").exists()
    assert not (home / ".config/opencode/tools/screenshot.ts").exists()
    assert not (home / ".pi/agent/extensions/tmux-panes.ts").exists()
    assert install(root, home, "remote") == ()


@pytest.mark.parametrize("machine", ["home", "work"])
def test_install_desktop_in_empty_home_is_idempotent(tmp_path, machine):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    assert install(root, home, machine)
    assert (home / ".claude/CLAUDE.md").resolve() == root / bundle_source(
        machine, "claude.md"
    )
    assert (home / ".agents/skills/tts").resolve() == root / ".agents/skills/tts"
    assert (
        home / ".config/opencode/tools/screenshot.ts"
    ).resolve() == root / ".config/opencode/tools/screenshot.ts"
    assert (
        home / ".pi/agent/extensions/tmux-panes.ts"
    ).resolve() == root / ".pi/agent/extensions/tmux-panes.ts"
    assert (home / ".local/bin/ghostty").exists() == (machine == "work")
    assert install(root, home, machine) == ()


def test_switching_work_to_remote_removes_desktop_capabilities(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()
    install(root, home, "work")

    assert install(root, home, "remote")
    assert (home / ".claude/CLAUDE.md").resolve() == root / bundle_source(
        "remote", "claude.md"
    )
    assert not (home / ".agents/skills/tts").exists()
    assert not (home / ".config/opencode/tools/screenshot.ts").exists()
    assert not (home / ".config/opencode/plugins/tmux.ts").exists()
    assert not (home / ".pi/agent/extensions/tmux-panes.ts").exists()
    assert not (home / ".config/hypr").exists()
    assert install(root, home, "remote") == ()

    assert install(root, home, "home")
    assert (home / ".agents/skills/tts").exists()
    assert (home / ".config/opencode/tools/screenshot.ts").exists()
    assert not (home / ".local/bin/ghostty").exists()


def test_dev_machine_option_installs_into_sandbox_home(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    completed = subprocess.run(
        [str(root / "dev"), "--machine", "remote"],
        env={**os.environ, "HOME": str(home), "PYTHONDONTWRITEBYTECODE": "1"},
        check=True,
        capture_output=True,
        text=True,
    )

    assert f"effects to {home}" in completed.stdout
    assert (home / ".claude/CLAUDE.md").resolve() == root / bundle_source(
        "remote", "claude.md"
    )
    assert not (home / ".config/opencode/tools/screenshot.ts").exists()


def test_install_conflict_leaves_sandbox_untouched(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    (home / ".claude").mkdir(parents=True)
    own = home / ".claude/CLAUDE.md"
    own.write_text("local instructions")

    with pytest.raises(ValueError, match="plan blocked"):
        install(root, home, "remote")

    assert own.read_text() == "local instructions"
    assert not (home / ".config/opencode").exists()

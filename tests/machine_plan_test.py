import json
import os
import re
import subprocess
from pathlib import Path

import pytest

import machine_history
import mcp_servers
from machine_bundle import Build, bundle_source, merge, render
from machine_install import _describe, install
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
    color_enabled,
    format_conflicts,
    paint,
    paint_effect,
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


@pytest.mark.parametrize("machine", ["remote", "home", "work"])
def test_fx_commit_profile_is_shared_on_every_machine(machine, tmp_path):
    root = Path(__file__).resolve().parents[1]
    target = ".fx/agents/commit"
    specs = tuple(item for item in PROPOSED if item.target == target)
    assert specs, "The fx commit profile must be installed on every machine"
    home = tmp_path / "home"
    home.mkdir()
    assert Link(target, target) in install(root, home, machine, specs)
    profile = json.loads((home / target / "profile.json").read_text())
    assert profile["description"]
    assert profile["tools"] == ["shell"]
    assert profile["mcp_servers"] == []
    assert "permission_mode" not in profile
    prompt = (home / target / "prompt.md").read_text()
    assert "git-ac -y -- <paths>" in prompt
    assert "only" in prompt
    assert "do not inspect the repository or run any other command" in prompt


@pytest.mark.parametrize("machine", ["remote", "home", "work"])
def test_fx_settings_are_repository_managed_on_every_machine(machine, tmp_path):
    repo = Path(__file__).resolve().parents[1]
    root = tmp_path / "repo"
    (root / ".fx").mkdir(parents=True)
    (root / ".fx/settings.json").write_bytes((repo / ".fx/settings.json").read_bytes())
    home = tmp_path / "home"
    (home / ".fx").mkdir(parents=True)
    target = home / ".fx/settings.json"
    original = '{"effort":"high","models":{"codex":"existing-model"}}\n'
    target.write_text(original)
    effects = install(root, home, machine, ())
    assert effects, (
        "fx settings must be installed even without symlink inventory entries"
    )
    assert target.is_file() and not target.is_symlink()
    config = json.loads(target.read_text())
    assert config["effort"] == "high"
    assert config["models"]["codex"] == "existing-model"
    pi = json.loads((repo / ".pi/agent/models.json").read_text())["providers"][
        "ollama-cloud"
    ]
    provider = config["providers"]["ollama-cloud"]
    assert provider["base_url"] == pi["baseUrl"]
    assert provider["auth"] == {"type": "bearer", "env": "OLLAMA_API_KEY"}
    assert config["provider"] == "ollama-cloud"
    assert config["models"]["ollama-cloud"] in provider["model_metadata"]
    assert provider["model_metadata"] == {
        model["id"]: {
            "context_window": model["contextWindow"],
            "max_output_tokens": model["maxTokens"],
            "supports_vision": "image" in model["input"],
        }
        for model in pi["models"]
    }
    assert install(root, home, machine, ()) == ()
    machine_history.undo(root, home, machine)
    assert target.read_text() == original


def test_instruction_fragments_and_json_overlays_are_machine_scoped():
    root = Path(__file__).resolve().parents[1]
    remote = render(root, "remote")
    home = render(root, "home")
    work = render(root, "work")
    assert b"gnarus-tts" not in remote[bundle_source("remote", "claude.md")]
    assert b"gnarus-tts" in work[bundle_source("work", "claude.md")]
    assert b"claude-implement" in work[bundle_source("work", "codex.md")]
    assert b"claude-implement" not in remote[bundle_source("remote", "codex.md")]
    assert b'"convex"' not in remote[bundle_source("remote", "opencode.json")]
    assert b'"convex"' in work[bundle_source("work", "opencode.json")]
    home_agents = json.loads(home[bundle_source("home", "opencode.json")])["agents"]
    assert home_agents["general"]["model"] == "ollama-cloud/glm-5.3"
    assert home_agents["explore"]["model"] == "ollama-cloud/glm-5.3-flash"
    for machine, rendered in (("remote", remote), ("work", work)):
        agents = json.loads(rendered[bundle_source(machine, "opencode.json")]).get(
            "agents", {}
        )
        assert "general" not in agents
        assert "explore" not in agents
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
    assert Build(bundle_source("home", "claude.md"), None) in install(
        root, home, "home", inventory
    )
    target = home / ".claude/CLAUDE.md"
    assert target.read_text() == "Common instruction\n\nDesktop instruction\n"

    fragment.write_text("Updated desktop instruction\n")
    assert Build(
        bundle_source("home", "claude.md"),
        "Common instruction\n\nDesktop instruction\n",
    ) in install(root, home, "home", inventory)
    assert target.read_text() == "Common instruction\n\nUpdated desktop instruction\n"
    assert install(root, home, "home", inventory) == ()

    machine_history.undo(root, home, "home")
    assert target.read_text() == "Common instruction\n\nDesktop instruction\n"
    assert (root / bundle_source("home", "claude.md")).read_text() == (
        "Common instruction\n\nDesktop instruction\n"
    )

    machine_history.undo(root, home, "home")
    assert not (home / ".claude/CLAUDE.md").exists()
    assert not (root / bundle_source("home", "claude.md")).exists()

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
    inventory = (Spec("new/skill", ".agents/skills/commit", frozenset({"remote"})),)

    assert plan("remote", inventory, {".agents/skills": Managed(".agents/skills")}) == (
        Conflict(
            ".agents/skills/commit",
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
    assert shared == set(SHARED_SKILLS) | {
        "tts",
        "tmux-processes",
        "full-send",
        "computer-use",
    }
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
    assert not (home / ".agents/skills/computer-use").exists()
    assert not (home / ".claude/skills/computer-use").exists()
    assert not (home / ".config/opencode/skills/computer-use").exists()
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
    for target in (
        ".agents/skills/computer-use",
        ".claude/skills/computer-use",
        ".config/opencode/skills/computer-use",
    ):
        assert (home / target).resolve() == root / ".agents/skills/computer-use"
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


def test_canonical_mcp_servers_reach_every_desktop_harness(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    install(root, home, "home")
    canonical = json.loads((root / ".config/mcp/mcp.json").read_text())["mcpServers"]

    assert (home / ".pi/agent/mcp.json").resolve() == root / ".config/mcp/mcp.json"
    claude = json.loads((home / ".claude.json").read_text())
    assert claude["mcpServers"]["playwright"] == canonical["playwright"]
    codex = (home / ".codex/config.toml").read_text()
    assert "[mcp_servers.playwright]" in codex
    opencode = json.loads((home / ".config/opencode/opencode.json").read_text())
    playwright = canonical["playwright"]
    assert opencode["mcp"]["playwright"]["command"] == [
        playwright["command"],
        *playwright["args"],
    ]


def test_remote_machine_carries_no_mcp_servers(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    install(root, home, "remote")

    assert not (home / ".pi/agent/mcp.json").exists()
    assert not (home / ".claude.json").exists()
    assert not (home / ".codex/config.toml").exists()


def test_merging_keeps_the_harness_own_state():
    entries = {"playwright": {"command": "npx", "args": ["-y", "@playwright/mcp"]}}
    claude = json.loads(mcp_servers.claude_state('{"projects": {"/tmp": {}}}', entries))
    codex = mcp_servers.codex_state(
        'model = "x"\n[projects."/tmp"]\ntrust_level = "trusted"\n', entries
    )

    assert claude["projects"] == {"/tmp": {}}
    assert claude["mcpServers"] == entries
    assert 'model = "x"' in codex
    assert 'trust_level = "trusted"' in codex
    assert "[mcp_servers.playwright]" in codex


def test_merging_twice_changes_nothing():
    entries = {"playwright": {"command": "npx", "args": ["-y", "@playwright/mcp"]}}
    claude = mcp_servers.claude_state("", entries)
    codex = mcp_servers.codex_state("", entries)

    assert mcp_servers.claude_state(claude, entries) == claude
    assert mcp_servers.codex_state(codex, entries) == codex


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

    with pytest.raises(ValueError, match="Can't install: 1 issue"):
        install(root, home, "remote")

    assert own.read_text() == "local instructions"
    assert not (home / ".config/opencode").exists()


def test_dev_explains_conflict_without_traceback(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    (home / ".claude").mkdir(parents=True)
    (home / ".claude/CLAUDE.md").write_text("local instructions")

    completed = subprocess.run(
        [str(root / "dev"), "--machine", "home", "--home", str(home)],
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        capture_output=True,
        text=True,
        check=False,
    )

    assert completed.returncode == 1
    assert "Traceback" not in completed.stderr
    assert "Nothing changed." in completed.stderr
    assert str(home / ".claude/CLAUDE.md") in completed.stderr
    assert "A local file already exists here." in completed.stderr
    assert (home / ".claude/CLAUDE.md").read_text() == "local instructions"


def test_conflict_display_highlights_the_problem_and_next_step(tmp_path):
    conflict = Conflict(".config/opencode/opencode.json", "existing file")

    plain = format_conflicts((conflict,), tmp_path)
    colored = format_conflicts((conflict,), tmp_path, color=True)

    assert "\033[" not in plain
    assert "Can't install: 1 issue needs attention." in plain
    assert str(tmp_path / ".config/opencode/opencode.json") in plain
    assert "A local file already exists here." in plain
    assert "Next step: Move it aside before retrying." in plain
    assert "Nothing changed." in plain
    assert "\033[" in colored
    assert re.sub(r"\033\[[0-9;]*m", "", colored) == plain


def test_parent_conflicts_are_reported_once_per_parent(tmp_path):
    conflicts = (
        Conflict(".agents/skills/tdd", "managed parent link .agents/skills"),
        Conflict(".agents/skills/simple", "managed parent link .agents/skills"),
        Conflict(
            ".config/opencode/opencode.json",
            "unmanaged parent .config/opencode: symlink outside dotfiles",
        ),
    )

    text = format_conflicts(conflicts, tmp_path)

    assert "Can't install: 2 issues need attention." in text
    assert f"● {tmp_path / '.agents/skills'}\n" in text
    assert "This is a link into the repo; 2 files go inside it." in text
    assert "Next step: Remove the link before retrying." in text
    assert f"● {tmp_path / '.config/opencode'}\n" in text
    assert "(symlink outside dotfiles); 1 file goes inside it." in text
    assert "tdd" not in text


def test_preview_of_blocked_plan_exits_nonzero(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    (home / ".claude").mkdir(parents=True)
    (home / ".claude/CLAUDE.md").write_text("local")

    completed = subprocess.run(
        ["python3", "-B", str(root / "machine_preview.py"), "remote"],
        env={**os.environ, "HOME": str(home)},
        capture_output=True,
        text=True,
        check=False,
    )

    assert completed.returncode == 1
    assert "Preview only; nothing was installed." in completed.stdout
    assert "Nothing changed." not in completed.stdout


def test_effect_lines_color_verbs_when_requested():
    assert paint_effect("LINK   ~/.zshrc -> .zshrc", color=False) == (
        "LINK   ~/.zshrc -> .zshrc"
    )
    assert paint_effect("LINK   ~/.zshrc -> .zshrc", color=True) == (
        "\033[1;32mLINK\033[0m   ~/.zshrc -> .zshrc"
    )
    assert paint_effect("REMOVE   ~/.claude.json", color=True) == (
        "\033[1;31mREMOVE\033[0m   ~/.claude.json"
    )
    assert paint_effect("UNKNOWN   something", color=True) == "UNKNOWN   something"


def test_terminal_colors_respect_no_color_and_dumb_term(monkeypatch):
    class Terminal:
        def isatty(self):
            return True

    monkeypatch.delenv("NO_COLOR", raising=False)
    monkeypatch.setenv("TERM", "xterm")
    assert color_enabled(Terminal())
    monkeypatch.setenv("NO_COLOR", "")
    assert not color_enabled(Terminal())
    monkeypatch.delenv("NO_COLOR")
    monkeypatch.setenv("TERM", "dumb")
    assert not color_enabled(Terminal())


def test_install_summary_lists_each_effect(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    completed = subprocess.run(
        [str(root / "dev"), "--machine", "home", "--home", str(home)],
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        capture_output=True,
        text=True,
        check=True,
    )

    lines = completed.stdout.splitlines()
    count = int(re.findall(r"Applied (\d+) effects", lines[0])[0])
    assert len(lines) - 1 == count
    assert "  LINK   ~/.zshrc -> .zshrc" in lines
    assert any(line.startswith("  MERGE  ~/.claude.json (") for line in lines)


def test_effect_descriptions_show_each_effect_kind():
    build = Build(".machine-generated/home/claude.md", None)
    rebuilt = Build(bundle_source("work", "claude.md"), "old instructions\n")
    switch = Link(".claude/CLAUDE.md", "sources/claude.md", "other/claude.md")
    fresh = Link(".zshrc", ".zshrc", None)
    retired = Remove(".agents/skills/tts", "features/tts")

    assert _describe(build) == "BUILD  .machine-generated/home/claude.md"
    assert _describe(rebuilt) == "BUILD  .machine-generated/work/claude.md"
    assert _describe(switch) == (
        "LINK   ~/.claude/CLAUDE.md -> sources/claude.md (was -> other/claude.md)"
    )
    assert _describe(fresh) == "LINK   ~/.zshrc -> .zshrc"
    assert _describe(retired) == "REMOVE ~/.agents/skills/tts (was -> features/tts)"
    assert (
        _describe(mcp_servers.Merge(".claude.json", ("context7", "playwright")))
        == "MERGE  ~/.claude.json (context7, playwright)"
    )


def test_undo_restores_the_last_installed_machine(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()
    install(root, home, "work")
    install(root, home, "remote")

    when, restored = machine_history.undo(root, home, "remote")

    assert isinstance(when, str) and when
    assert restored
    assert (home / ".claude/CLAUDE.md").resolve() == root / bundle_source(
        "work", "claude.md"
    )
    assert (home / ".agents/skills/tts").resolve() == root / ".agents/skills/tts"
    assert (
        home / ".config/opencode/tools/screenshot.ts"
    ).resolve() == root / ".config/opencode/tools/screenshot.ts"
    with pytest.raises(machine_history.NothingToUndo):
        machine_history.undo(root, home, "remote")


def test_undo_clears_the_run_from_the_journal(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()
    install(root, home, "home")

    when, restored = machine_history.undo(root, home, "home")
    assert when and restored
    assert not (home / ".claude/CLAUDE.md").exists()
    assert not (home / ".zshrc").exists()
    assert not (home / machine_history.HISTORY).read_text()

    with pytest.raises(machine_history.NothingToUndo):
        machine_history.undo(root, home, "home")


def test_undo_refuses_paths_changed_behind_the_installer(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()
    install(root, home, "remote")
    target = home / ".claude/CLAUDE.md"
    target.unlink()
    target.symlink_to("/nowhere")

    with pytest.raises(machine_history.PathChanged):
        machine_history.undo(root, home, "remote")


def test_dev_undo_reports_the_restored_effects(tmp_path):
    root = Path(__file__).resolve().parents[1]
    home = tmp_path / "home"
    home.mkdir()

    first = subprocess.run(
        [str(root / "dev"), "--machine", "home", "--home", str(home)],
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        capture_output=True,
        text=True,
        check=True,
    )
    applied = int(re.findall(r"Applied (\d+) effects", first.stdout)[0])

    undo = subprocess.run(
        [str(root / "dev"), "undo", "--machine", "home", "--home", str(home)],
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        capture_output=True,
        text=True,
        check=True,
    )
    lines = undo.stdout.splitlines()

    assert f"Undid {applied} effects on {home}" in lines[0]
    assert "install was" in lines[0]
    assert len(lines) - 1 == applied
    assert "  REMOVE   ~/.zshrc" in lines
    assert not (home / ".claude/CLAUDE.md").exists()
    assert not (home / ".zshrc").exists()

    again = subprocess.run(
        [str(root / "dev"), "undo", "--machine", "home", "--home", str(home)],
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
        capture_output=True,
        text=True,
        check=False,
    )

    assert again.returncode == 1
    assert "Nothing to undo for home." in again.stderr

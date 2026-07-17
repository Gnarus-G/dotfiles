import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path


def load_dev_module():
    path = Path(__file__).resolve().parents[1] / "dev"
    loader = SourceFileLoader("dev_script", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def test_shared_skills_are_composed_into_agents_and_claude():
    dev = load_dev_module()

    assert dev.LINKS[".agents/skills/context7"] == [
        ".agents/skills/context7",
        ".claude/skills/context7",
    ]


def test_claude_only_skills_are_composed_only_into_claude():
    dev = load_dev_module()

    assert dev.LINKS[".claude.only/skills/codex-implement"] == [
        ".claude/skills/codex-implement"
    ]
    assert ".agents/skills/codex-implement" not in {
        target for targets in dev.LINKS.values() for target in targets
    }


def test_codex_only_skills_are_composed_only_into_agents():
    dev = load_dev_module()

    assert dev.LINKS[".codex.only/skills/claude-implement"] == [
        ".agents/skills/claude-implement"
    ]
    assert ".claude/skills/claude-implement" not in {
        target for targets in dev.LINKS.values() for target in targets
    }


def test_opencode_uses_only_its_explicitly_composed_skills():
    zshrc = (Path(__file__).resolve().parents[1] / ".zshrc").read_text()

    assert "export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=true" in zshrc


def test_codex_and_opencode_use_separate_instruction_sources():
    dev = load_dev_module()

    assert dev.LINKS[".codex/AGENTS.md"] == [".codex/AGENTS.md"]
    assert dev.LINKS[".config/opencode/system.md"] == [
        ".pi/agent/APPEND_SYSTEM.md"
    ]


def test_codex_supports_claude_implement_without_delegating_reasoning():
    instructions = (
        Path(__file__).resolve().parents[1] / ".codex" / "AGENTS.md"
    ).read_text()

    assert "claude-implement" in instructions
    assert "bounded implementation" in instructions
    assert "Keep reasoning, planning, judgment, and review inline" in instructions
    assert "Sonnet 5" not in instructions
    assert "Opus 4.8" not in instructions
    assert "codex-implement" not in instructions


def test_claude_instructions_reference_only_available_delegation_skills():
    root = Path(__file__).resolve().parents[1]
    instructions = (root / ".claude" / "CLAUDE.md").read_text()
    codex_implementation = (
        root / ".claude.only" / "skills" / "codex-implement" / "SKILL.md"
    ).read_text()

    assert "claude-implement" not in instructions
    assert "claude-implement" not in codex_implementation
    assert "caveman" not in instructions


def test_stale_dotfiles_link_can_be_replaced_without_prompt(tmp_path):
    dev = load_dev_module()
    dev.DOTFILES = tmp_path / "dotfiles"
    dev.DOTFILES.mkdir()
    target = tmp_path / "home" / ".agents" / "skills" / "old"
    target.parent.mkdir(parents=True)
    target.symlink_to(dev.DOTFILES / ".agents" / "skills" / "old")

    assert dev.is_stale_dotfiles_link(target)


def test_opencode_sync_removes_managed_skills_absent_from_shared_set(tmp_path):
    dev = load_dev_module()
    dev.DOTFILES = tmp_path / "dotfiles"
    dev.HOME = tmp_path / "home"
    shared = dev.DOTFILES / ".agents" / "skills" / "common"
    shared.mkdir(parents=True)
    target = dev.HOME / ".config" / "opencode" / "skills"
    target.mkdir(parents=True)
    (target / "stale").symlink_to(dev.DOTFILES / ".agents" / "skills" / "stale")

    dev.sync_opencode_skills()

    assert (target / "common").resolve() == shared
    assert not (target / "stale").is_symlink()


def test_same_location_detects_paths_reached_through_symlinked_parent(tmp_path):
    dev = load_dev_module()
    source_root = tmp_path / "source"
    source = source_root / "tts"
    source.mkdir(parents=True)
    linked_root = tmp_path / "linked"
    linked_root.symlink_to(source_root)

    assert dev.same_location(source, linked_root / "tts")

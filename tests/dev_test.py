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


def test_agent_skills_sync_to_agents_and_claude():
    dev = load_dev_module()

    assert dev.LINKS[".agents/skills/caveman"] == [
        ".agents/skills/caveman",
        ".claude/skills/caveman",
    ]
    assert dev.LINKS[".agents/skills/claude-implement"] == [
        ".agents/skills/claude-implement"
    ]


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


def test_same_location_detects_paths_reached_through_symlinked_parent(tmp_path):
    dev = load_dev_module()
    source_root = tmp_path / "source"
    source = source_root / "tts"
    source.mkdir(parents=True)
    linked_root = tmp_path / "linked"
    linked_root.symlink_to(source_root)

    assert dev.same_location(source, linked_root / "tts")

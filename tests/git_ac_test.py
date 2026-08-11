import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path


def load_git_ac():
    path = Path(__file__).resolve().parents[1] / ".local" / "bin" / "git-ac"
    loader = SourceFileLoader("git_ac", str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def test_stage_paths_stages_only_explicit_paths(monkeypatch):
    git_ac = load_git_ac()
    calls = []
    monkeypatch.setattr(git_ac.subprocess, "run", lambda *args, **kwargs: calls.append((args, kwargs)))

    git_ac.stage_paths(["one", "two"])

    assert calls == [((['git', 'add', '--', 'one', 'two'],), {"check": True})]


def test_prompt_uses_repository_history_to_infer_style():
    git_ac = load_git_ac()

    prompt = git_ac.build_prompt("diff", "recent commit")

    assert "recent commit" in prompt
    assert "Infer the commit message conventions" in prompt
    assert "no prefix" not in prompt


def test_commit_command_limits_commit_to_explicit_paths():
    git_ac = load_git_ac()

    command = git_ac.commit_command("message", ["one", "two"])

    assert command == [
        "git",
        "commit",
        "--cleanup=strip",
        "-F",
        "message",
        "--only",
        "--",
        "one",
        "two",
    ]


def test_all_commit_harnesses_use_one_git_ac_call():
    root = Path(__file__).resolve().parents[1]
    harnesses = (
        root / ".config" / "opencode" / "agent" / "commit.md",
        root / ".claude.only" / "skills" / "commit" / "SKILL.md",
        root / ".codex" / "agents" / "commit.toml",
    )

    for path in harnesses:
        harness = path.read_text()
        assert "Run exactly one command" in harness
        assert "git-ac -y -- <paths>" in harness

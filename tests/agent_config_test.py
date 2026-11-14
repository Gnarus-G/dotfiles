import json
from pathlib import Path

from machine_bundle import bundle_source, render

ROOT = Path(__file__).resolve().parents[1]


def test_opencode_uses_only_explicitly_composed_skills():
    assert (
        "export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=true"
        in (ROOT / ".zshrc").read_text()
    )


def test_commit_skills_reach_subscription_fallback_without_model_wrapper():
    for source in (
        ".agents/skills/commit/SKILL.md",
        ".claude.only/skills/commit/SKILL.md",
    ):
        skill = (ROOT / source).read_text()
        assert "git-ac -y -- <paths>" in skill
        assert "Codex subscription" in skill
        assert "Ollama" in skill
        assert "context: fork" not in skill
        assert "delegate to" not in skill


def test_opencode_explicit_commit_agent_uses_openai():
    agent = (ROOT / ".config/opencode/agent/commit.md").read_text()
    assert "model: openai/gpt-6-luna" in agent


def test_codex_delegation_is_desktop_only():
    remote = render(ROOT, "remote")[bundle_source("remote", "codex.md")]
    work = render(ROOT, "work")[bundle_source("work", "codex.md")]
    assert b"claude-implement" not in remote
    assert b"claude-implement" in work
    assert b"Keep reasoning, planning, judgment, and review inline" in work


def test_claude_prompt_does_not_offer_codex_delegation():
    instructions = render(ROOT, "work")[bundle_source("work", "claude.md")]
    assert b"claude-implement" not in instructions
    assert b"caveman" not in instructions


def test_evidence_first_reaches_every_machine_and_harness():
    for machine in ("remote", "home", "work"):
        bundle = render(ROOT, machine)
        for name in ("claude.md", "codex.md", "pi.md"):
            prompt = bundle[bundle_source(machine, name)].decode()
            assert "## Evidence-first responses" in prompt
            assert "Facts (F1, F2, ...)" in prompt
            assert "Conclusions/Claims (C1, C2, ...)" in prompt
            assert "reply in one concise sentence" not in prompt
        opencode = json.loads(bundle[bundle_source(machine, "opencode.json")])
        assert "~/.pi/agent/APPEND_SYSTEM.md" in opencode["instructions"]
        claude = json.loads(bundle[bundle_source(machine, "claude-settings.json")])
        assert claude["outputStyle"] == "Evidence First"
        assert any(
            hook["command"] == "$HOME/.claude/hooks/output-style.sh"
            for entry in claude["hooks"]["UserPromptSubmit"]
            for hook in entry["hooks"]
        )

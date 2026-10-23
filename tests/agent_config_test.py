from pathlib import Path

from machine_bundle import bundle_source, render

ROOT = Path(__file__).resolve().parents[1]


def test_opencode_uses_only_explicitly_composed_skills():
    assert (
        "export OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=true"
        in (ROOT / ".zshrc").read_text()
    )


def test_claude_commit_skill_runs_on_haiku_fork():
    skill = (ROOT / ".claude.only/skills/commit/SKILL.md").read_text()
    assert "context: fork" in skill
    assert "model: haiku" in skill
    assert "effort: low" in skill
    assert "background: false" in skill


def test_commit_skill_routes_primary_agents_to_subagent():
    skill = (ROOT / ".agents/skills/commit/SKILL.md").read_text()
    assert "If you are the primary agent, do not run Git commands" in skill
    assert "delegate to the custom `commit` subagent" in skill


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

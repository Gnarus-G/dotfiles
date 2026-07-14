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


def test_same_location_detects_paths_reached_through_symlinked_parent(tmp_path):
    dev = load_dev_module()
    source_root = tmp_path / "source"
    source = source_root / "tts"
    source.mkdir(parents=True)
    linked_root = tmp_path / "linked"
    linked_root.symlink_to(source_root)

    assert dev.same_location(source, linked_root / "tts")


def test_render_mcp_toml_includes_command_args_and_env():
    dev = load_dev_module()

    rendered = dev.render_mcp_toml(
        {
            "web": {
                "command": "python3",
                "args": ["server.py", "--stdio"],
                "env": {"MODE": "test"},
            }
        }
    )

    assert rendered == '\n'.join(
        [
            '[mcp_servers.web]',
            'command = "python3"',
            'args = ["server.py", "--stdio"]',
            '',
            '[mcp_servers.web.env]',
            'MODE = "test"',
        ]
    )


def test_strip_mcp_sections_keeps_unrelated_toml_sections():
    dev = load_dev_module()

    existing = '\n'.join(
        [
            '[profile.default]',
            'model = "gpt"',
            '',
            '[mcp_servers.old]',
            'command = "old"',
            '',
            '[mcp_servers.old.env]',
            'TOKEN = "secret"',
            '',
            '[ui]',
            'theme = "dark"',
        ]
    )

    assert dev.strip_mcp_sections(existing) == '\n'.join(
        [
            '[profile.default]',
            'model = "gpt"',
            '',
            '[ui]',
            'theme = "dark"',
        ]
    )

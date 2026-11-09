import importlib.util
import json
import os
import subprocess
import sys
import threading
import urllib.error
from http.server import BaseHTTPRequestHandler, HTTPServer
from importlib.machinery import SourceFileLoader
from pathlib import Path
from types import SimpleNamespace

import pytest


@pytest.fixture
def failing_provider():
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(
                json.dumps({"models": [{"name": "deepseek-v4.1-flash:cloud"}]}).encode()
            )

        def do_POST(self):
            self.send_response(429)
            self.send_header("Retry-After", "60")
            self.end_headers()
            self.wfile.write(b'{"error":"private provider response"}')

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_port}"
    server.shutdown()
    thread.join()
    server.server_close()


def test_429_explains_fallback_and_preserves_staging(tmp_path, failing_provider):
    subprocess.run(["git", "init", "-q", str(tmp_path)], check=True)
    (tmp_path / "change.txt").write_text("work in progress")
    subprocess.run(["git", "add", "change.txt"], cwd=tmp_path, check=True)
    script = Path(__file__).resolve().parents[1] / ".local/bin/git-ac"
    fx = tmp_path / "fx"
    fx.write_text(f"#!{sys.executable}\nraise SystemExit(1)\n")
    fx.chmod(0o755)
    env = {
        **os.environ,
        "PATH": f"{tmp_path}:{os.environ['PATH']}",
        "OLLAMA_HOST": failing_provider,
        "NO_COLOR": "1",
    }

    result = subprocess.run(
        [sys.executable, str(script), "-y"],
        cwd=tmp_path,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 1
    assert "Traceback" not in result.stderr
    assert "HTTP 429" in result.stderr
    assert "Ollama" in result.stderr
    assert "deepseek-v4.1-flash:cloud" in result.stderr
    assert "fx generation failed" in result.stderr
    assert "60 seconds" in result.stderr
    assert "ollama list" in result.stderr
    assert "--model MODEL" in result.stderr
    assert "git commit" in result.stderr
    assert "No commit was created" in result.stderr
    assert "private provider response" not in result.stderr
    assert "\033[" not in result.stderr
    assert (
        subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            cwd=tmp_path,
            text=True,
            capture_output=True,
            check=True,
        ).stdout
        == "change.txt\n"
    )
    assert (
        subprocess.run(
            ["git", "rev-parse", "--verify", "HEAD"],
            cwd=tmp_path,
            capture_output=True,
            check=False,
        ).returncode
        != 0
    )


@pytest.mark.parametrize(
    ("error", "model", "guidance"),
    [
        (
            urllib.error.HTTPError("http://unused", 401, "private reason", {}, None),
            "openai/example",
            "fx login codex",
        ),
        (
            urllib.error.HTTPError("http://unused", 503, "private reason", {}, None),
            "example:cloud",
            "service availability",
        ),
        (urllib.error.URLError("private reason"), "example:cloud", "OLLAMA_HOST"),
    ],
)
def test_error_guidance_preserves_explicit_paths(error, model, guidance, capsys):
    git_ac = load_git_ac()
    args = SimpleNamespace(
        model=model, no_edit=True, dry_run=False, paths=["one file", "two"]
    )

    git_ac.report_generation_error(error, args, model)

    output = capsys.readouterr().err
    assert guidance in output
    assert "git commit --only -- 'one file' two" in output
    if git_ac.detect_provider(model) == "ollama":
        assert "git ac --model MODEL -y -- 'one file' two" in output
    assert "private reason" not in output
    assert "Requested" not in output


def test_failed_model_discovery_preserves_network_error(monkeypatch):
    git_ac = load_git_ac()

    def unavailable(*args):
        raise urllib.error.URLError("offline")

    monkeypatch.setattr(git_ac, "ollama_request", unavailable)
    with pytest.raises(urllib.error.URLError):
        git_ac.model_exists("example")


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
    monkeypatch.setattr(
        git_ac.subprocess, "run", lambda *args, **kwargs: calls.append((args, kwargs))
    )

    git_ac.stage_paths(["one", "two"])

    assert calls == [((["git", "add", "--", "one", "two"],), {"check": True})]


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

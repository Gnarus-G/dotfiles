import json
import os
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / ".local/bin/git-ac"


@pytest.fixture
def workspace(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    (repo / "change.txt").write_text("work in progress")
    subprocess.run(["git", "add", "change.txt"], cwd=repo, check=True)
    binary = tmp_path / "fx"
    binary.write_text(
        f"#!{sys.executable}\n"
        "import json, os, sys\n"
        "from pathlib import Path\n"
        "Path(os.environ['CAPTURE']).write_text(json.dumps({\n"
        "'args': sys.argv[1:], 'provider': os.environ.get('FX_PROVIDER'),\n"
        "'prompt': sys.stdin.read(), 'cwd': os.getcwd()}))\n"
        "print(os.environ['RESPONSE'])\n"
        "sys.exit(int(os.environ.get('EXIT_CODE', '0')))\n"
    )
    binary.chmod(0o755)
    env = {
        **os.environ,
        "PATH": f"{tmp_path}:{os.environ['PATH']}",
        "FX_PROVIDER": "gateway",
        "CAPTURE": str(tmp_path / "capture.json"),
        "RESPONSE": json.dumps(
            {
                "exit_code": 0,
                "final_output": "fix: example",
                "output": "unwanted commentary",
                "tool_calls": [],
            }
        ),
        "NO_COLOR": "1",
    }
    return repo, env


def test_dry_run_uses_subscription_and_only_final_output(workspace):
    repo, env = workspace
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "-n", "-m", "gpt-6-sol"],
        check=False,
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout == "fix: example\n"
    capture = json.loads(Path(env["CAPTURE"]).read_text())
    assert capture["provider"] == "codex"
    assert "gpt-6-sol" in capture["args"]
    assert "--no-save" in capture["args"]
    assert "--json" in capture["args"]
    assert "work in progress" in capture["prompt"]
    assert capture["cwd"] != str(repo)
    assert (
        subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            cwd=repo,
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        == "change.txt\n"
    )
    assert (
        subprocess.run(
            ["git", "rev-parse", "--verify", "HEAD"],
            cwd=repo,
            capture_output=True,
            check=False,
        ).returncode
        != 0
    )


@pytest.mark.parametrize(
    "response,exit_code",
    [
        ('{"exit_code":1,"error":"private response"}', "1"),
        ('{"exit_code":0,"final_output":""}', "0"),
        ("not json", "0"),
        (
            '{"exit_code":0,"final_output":"message","tool_calls":[{"name":"shell"}]}',
            "0",
        ),
    ],
)
def test_explicit_model_failure_never_commits_or_falls_back(
    workspace, response, exit_code
):
    repo, env = workspace
    env.update(RESPONSE=response, EXIT_CODE=exit_code)
    result = subprocess.run(
        [sys.executable, str(SCRIPT), "-y", "-m", "gpt-6-sol"],
        check=False,
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1
    assert "No commit was created" in result.stderr
    assert "fx login codex" in result.stderr
    assert "private response" not in result.stderr
    assert "Traceback" not in result.stderr
    assert "falling back" not in result.stderr
    assert (
        subprocess.run(
            ["git", "rev-parse", "--verify", "HEAD"],
            cwd=repo,
            capture_output=True,
            check=False,
        ).returncode
        != 0
    )
    assert (
        subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            cwd=repo,
            capture_output=True,
            text=True,
            check=True,
        ).stdout
        == "change.txt\n"
    )


def test_default_model_falls_back_to_ollama(workspace):
    repo, env = workspace
    requests = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(
                json.dumps({"models": [{"name": "deepseek-v4.1-flash:cloud"}]}).encode()
            )

        def do_POST(self):
            requests.append(
                json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            )
            self.send_response(200)
            self.end_headers()
            self.wfile.write(
                json.dumps(
                    {"choices": [{"message": {"content": "fix: fallback example"}}]}
                ).encode()
            )

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        env.update(EXIT_CODE="1", OLLAMA_HOST=f"http://127.0.0.1:{server.server_port}")
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "-n"],
            check=False,
            cwd=repo,
            env=env,
            capture_output=True,
            text=True,
        )
    finally:
        server.shutdown()
        thread.join()
        server.server_close()
    assert result.returncode == 0, result.stderr
    assert result.stdout == "fix: fallback example\n"
    assert "falling back to Ollama" in result.stderr
    assert requests[0]["model"] == "deepseek-v4.1-flash:cloud"
    assert "work in progress" in requests[0]["messages"][0]["content"]

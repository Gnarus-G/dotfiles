# Troubleshooting (GPU-Only Path)

Use this quick map.

## `rocminfo` does not detect GPU

This skill is user-scope only and does not perform system driver fixes.

Action: stop here and complete ROCm/driver setup outside this skill, then return when `rocminfo` shows your AMD GPU.

## Ollama service fails to start

```bash
systemctl --user status ollama --no-pager
journalctl --user -u ollama -n 100 --no-pager
```

Common fixes:

- Confirm binary exists: `~/.local/opt/ollama/bin/ollama --version`
- Reinstall ROCm runtime tarball:

```bash
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama
systemctl --user restart ollama
```

## Wrong install path (system-wide install used by mistake)

Symptoms:

- `which ollama` points to `/usr/bin/ollama`
- `systemctl status ollama` shows an active system service

Fix:

```bash
systemctl --user stop ollama || true
systemctl --user daemon-reload
systemctl --user restart ollama
```

Then ensure your user binary is preferred:

```bash
export PATH="$HOME/.local/bin:$PATH"
which ollama
```

If port `11434` is busy (likely from a system service you cannot control), update your user service to another port such as `0.0.0.0:11435`.

## API not reachable on network

```bash
systemctl --user status ollama --no-pager
curl -v http://0.0.0.0:11434/api/tags
```

If connection is refused, restart service and recheck logs.

## Still using CPU / very slow

```bash
journalctl --user -u ollama -n 200 --no-pager
```

Confirm service includes:

- `Environment=OLLAMA_GPU=amd`
- `Environment=OLLAMA_LLM_LIBRARY=rocm`

Then reload and restart:

```bash
systemctl --user daemon-reload
systemctl --user restart ollama
```

---
name: ollama-gpu-installation
description: Install Ollama with GPU acceleration (AMD ROCm or NVIDIA CUDA) as a simple systemd user service. Detects the GPU and picks the right build. Use when installing or upgrading Ollama on any of my machines.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: installation
  platforms: [Linux]
---

# Ollama GPU Installation Skill

Use this skill for a direct, minimal setup of Ollama with GPU acceleration
as a user-level service. My machines differ — an AMD PC (ROCm) and an NVIDIA
laptop (CUDA) share these dotfiles — so detect the GPU first and branch.

Hard requirements:

- Install Ollama in user space only.
- Use a systemd user service only.
- Do not require `sudo` for Ollama install or service management.

## Behavior

- Keep responses short and action-oriented.
- Do not interrogate the user with multiple setup questions.
- Provide a small command set the user can paste.
- Never use `curl -fsSL https://ollama.com/install.sh | sh` because it installs system-wide.
- Never require `sudo` for Ollama commands in this workflow.

## Workflow

1. Detect the GPU

```bash
if command -v rocminfo >/dev/null && rocminfo 2>/dev/null | grep -q gfx; then echo AMD
elif command -v nvidia-smi >/dev/null && nvidia-smi -L 2>/dev/null | grep -q GPU; then echo NVIDIA
else echo NONE; fi
```

- **AMD**: requires working ROCm. This skill does not install drivers or
  ROCm (system-wide, needs admin). If `rocminfo` does not detect the GPU,
  stop and fix ROCm outside this skill.
- **NVIDIA**: requires the proprietary driver (`nvidia-smi` working).
- **NONE**: stop and ask which machine this is before proceeding.

2. Install Ollama in user space

```bash
mkdir -p ~/.local/opt/ollama ~/.local/bin
# AMD (ROCm runtime bundled):
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x --zstd -C ~/.local/opt/ollama
# NVIDIA (CUDA runtime bundled):
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst | tar x --zstd -C ~/.local/opt/ollama

ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

3. User service

The shared service file lives in the dotfiles at
`.config/systemd/user/ollama.service` (symlinked by `./dev`). It is
GPU-agnostic — Ollama auto-detects the backend. On the AMD PC, if
auto-detection fails, add a local (non-symlinked) drop-in instead of
editing the shared file:

```bash
mkdir -p ~/.config/systemd/user/ollama.service.d
cat > ~/.config/systemd/user/ollama.service.d/amd.conf << 'EOF'
[Service]
Environment=OLLAMA_GPU=amd
Environment=OLLAMA_LLM_LIBRARY=rocm
EOF
```

4. Enable and start

```bash
systemctl --user daemon-reload
systemctl --user enable --now ollama
```

If a legacy system-wide service occupies `127.0.0.1:11434`, disable it
(`sudo systemctl disable --now ollama`) or move the user service to
another port.

Migrating models from a legacy system install: `mv`, never `cp` (same
filesystem — instant, no disk cost):

```bash
sudo sh -c 'mv /usr/share/ollama/.ollama/models ~/.ollama/models && chown -R $SUDO_USER: ~/.ollama/models'
```

5. Verify GPU acceleration

```bash
~/.local/opt/ollama/bin/ollama --version
systemctl --user status ollama --no-pager
journalctl --user -u ollama -n 50 --no-pager | grep -iE "cuda|rocm|vram|inference compute"
```

The `inference compute` log line must name the discrete GPU. Pick models
that fit the reported VRAM — a model larger than VRAM offloads to CPU and
runs many times slower.

## Model sizing note

Agentic use (via `codex exec --oss`) needs a large context window; the
shared service sets `OLLAMA_CONTEXT_LENGTH=32768`. Both the weights and
the KV cache compete for VRAM — prefer the largest model that still fits
entirely on the GPU over a smarter one that spills.

## References (AMD/ROCm specifics)

- [references/installation.md](references/installation.md)
- [references/service.md](references/service.md)
- [references/verification.md](references/verification.md)
- [references/drivers.md](references/drivers.md)
- [references/troubleshooting.md](references/troubleshooting.md)

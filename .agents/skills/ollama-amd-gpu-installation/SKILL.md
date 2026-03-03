---
name: ollama-amd-gpu-installation
description: Install Ollama for AMD GPU acceleration only as a simple systemd user service
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: installation
  platforms: [Linux]
---

# Ollama AMD GPU Installation Skill

Use this skill for a direct, minimal setup of Ollama with AMD GPU acceleration only as a user-level service.

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

## Default Workflow (GPU-Only)

1. Verify ROCm is already working (required)

This skill does not install drivers or ROCm because those steps are system-wide and may need admin rights.

```bash
rocminfo
```

If `rocminfo` does not detect the GPU, stop and fix ROCm outside this skill before continuing.

2. Install Ollama and ROCm-enabled runtime (user space only)

```bash
mkdir -p ~/.local/opt/ollama ~/.local/bin
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

3. Create user service

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/ollama.service << 'EOF'
[Unit]
Description=Ollama (User)
After=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/opt/ollama/bin/ollama serve
Restart=always
RestartSec=3
Environment=OLLAMA_HOST=127.0.0.1:11434
Environment=OLLAMA_GPU=amd
Environment=OLLAMA_LLM_LIBRARY=rocm

[Install]
WantedBy=default.target
EOF
```

4. Enable and start

```bash
systemctl --user daemon-reload
systemctl --user enable --now ollama
```

If a system-wide service already occupies `127.0.0.1:11434`, change the user service host to another port (for example `127.0.0.1:11435`) and restart the user service.

5. Verify GPU acceleration

```bash
~/.local/opt/ollama/bin/ollama --version
rocminfo | head -n 20
systemctl --user status ollama --no-pager
journalctl --user -u ollama -n 50 --no-pager
```

If `rocminfo` does not detect the GPU, stop and fix ROCm before using Ollama.

## References

- [references/installation.md](references/installation.md)
- [references/service.md](references/service.md)
- [references/verification.md](references/verification.md)
- [references/drivers.md](references/drivers.md)
- [references/troubleshooting.md](references/troubleshooting.md)

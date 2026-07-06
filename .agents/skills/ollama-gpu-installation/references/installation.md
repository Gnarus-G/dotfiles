# Ollama Install (AMD GPU Acceleration Only)

Prerequisite: ROCm works and `rocminfo` detects the GPU.

## Install

```bash
mkdir -p ~/.local/opt/ollama ~/.local/bin
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

Do not use `curl -fsSL https://ollama.com/install.sh | sh` for this workflow. That path is system-wide and does not match this skill.

## Quick Check

```bash
~/.local/opt/ollama/bin/ollama --version
```

If this fails, reinstall with the same commands before moving on to service setup.

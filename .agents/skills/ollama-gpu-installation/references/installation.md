# Ollama Install (AMD GPU Acceleration Only)

Prerequisite: ROCm works and `rocminfo` detects the GPU.

## Install

The ROCm archive is only a library overlay; install the base archive first.

```bash
set -e -o pipefail
mkdir -p ~/.local/opt/ollama ~/.local/bin
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst | tar x --zstd -C ~/.local/opt/ollama
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x --zstd -C ~/.local/opt/ollama
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

Do not use `curl -fsSL https://ollama.com/install.sh | sh` for this workflow. That path is system-wide and does not match this skill.

## Quick Check

```bash
~/.local/opt/ollama/bin/ollama --version
```

If this fails, reinstall with the same commands before moving on to service setup.

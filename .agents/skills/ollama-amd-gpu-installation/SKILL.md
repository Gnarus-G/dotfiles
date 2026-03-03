---
name: ollama-amd-gpu-installation
description: Comprehensive guide for installing Ollama with AMD GPU support using systemd USER services on Ubuntu and Arch Linux
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: installation
  platforms:
    - Ubuntu 24.04+
    - Arch Linux
---

# Ollama AMD GPU Installation Skill

This skill provides comprehensive guidance for installing Ollama with AMD GPU support using systemd USER services on both Ubuntu and Arch Linux.

## Overview

Ollama is an open-source platform for running large language models locally. This skill focuses on AMD GPU acceleration and proper systemd USER service configuration for personal use.

## Prerequisites

- AMD GPU with ROCm support
- Ubuntu 24.04+ or Arch Linux
- User with sudo privileges
- ~15GB disk space for models

## Quick Reference

| Topic | Description | Commands |
|-------|-------------|----------|
| **Driver Installation** | Install ROCm drivers for AMD GPU | [drivers.md](references/drivers.md) |
| **Ollama Installation** | Install and configure Ollama | [installation.md](references/installation.md) |
| **Systemd Service** | Create systemd USER service | [service.md](references/service.md) |
| **Verification** | Test installation and GPU acceleration | [verification.md](references/verification.md) |
| **Troubleshooting** | Common issues and solutions | [troubleshooting.md](references/troubleshooting.md) |

## Essential Commands

```bash
# Install ROCm drivers (Ubuntu)
sudo apt install -y amdgpu-dkms rocm

# Install ROCm drivers (Arch)
sudo pacman -S --needed rocm-opencl rocm-libs rocm-opencl-icd amdgpu

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Create symlink
mkdir -p ~/.local/bin && ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama

# Create systemd service
systemctl --user daemon-reload && systemctl --user enable ollama

# Start service
systemctl --user start ollama

# Verify installation
~/.local/opt/ollama/bin/ollama --version
```

## GPU Acceleration

Ollama automatically detects AMD GPUs when ROCm drivers are properly installed. GPU acceleration significantly improves model inference speed for larger models.

## Model Storage

Models are stored in `~/.local/opt/ollama/models` by default. This location is user-specific and doesn't require elevated permissions.

## Security Considerations

- Systemd USER services run with your user permissions
- Models are stored in your home directory
- No system-wide configuration required
- Firewall access can be restricted to localhost

## Uninstall

To completely remove Ollama:

```bash
# Stop and disable service
systemctl --user stop ollama
systemctl --user disable ollama

# Remove service file
rm ~/.config/systemd/user/ollama.service

# Remove installation
rm -rf ~/.local/opt/ollama

# Remove symlink
rm ~/.local/bin/ollama

# Remove ROCm drivers (optional)
sudo apt remove -y amdgpu-dkms rocm  # Ubuntu
sudo pacman -R rocm-opencl rocm-libs rocm-opencl-icd amdgpu  # Arch
```

## Performance Tuning

Add these options to the service file for better performance:

```ini
[Service]
LimitNOFILE=65536
CPUQuota=80%
MemoryHigh=8G
MemoryMax=16G
Environment="OLLAMA_GPU=amd"
Environment="OLLAMA_GPUS=0"
```

## Model Management

### Pulling Models

```bash
~/.local/opt/ollama/bin/ollama pull llama3.2:3b
~/.local/opt/ollama/bin/ollama pull codellama:7b
~/.local/opt/ollama/bin/ollama pull deepseek-coder:6.7b
```

### Listing Models

```bash
~/.local/opt/ollama/bin/ollama list
```

## Monitoring

### Log Monitoring

```bash
journalctl --user -u ollama -f
```

### Performance Monitoring

```bash
rocm-smi
~/.local/opt/ollama/bin/ollama --version
```

## Additional Resources

- [Ollama Official Documentation](https://docs.ollama.com/)
- [ROCm Documentation](https://rocm.docs.amd.com/)
- [AMD GPU Drivers](https://www.amd.com/en/support/linux-drivers)

## Notes

- This skill uses systemd USER services for personal use without requiring sudo for service management
- GPU acceleration is automatic when ROCm drivers are properly installed
- Models are stored in user home directory for easy backup and management
- Service automatically restarts on crashes and system boot
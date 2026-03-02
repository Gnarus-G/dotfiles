# Ollama AMD GPU Installation Guide

This guide covers installing Ollama with AMD GPU support using systemd USER services for both Ubuntu and Arch Linux.

## Prerequisites

- Ubuntu 24.04 LTS or newer
- Arch Linux (any recent version)
- AMD GPU with ROCm support
- User with sudo privileges

## Step 1: Install AMD ROCm Drivers

### Ubuntu

```bash
# Update package list
sudo apt update

# Install kernel headers and modules for AMD GPU support
sudo apt install -y "linux-headers-$(uname -r)" "linux-modules-extra-$(uname -r)"

# Install ROCm userspace libraries
sudo apt install -y python3-setuptools python3-wheel

# Add current user to render and video groups for GPU access
sudo usermod -a -G render,video $USER

# Install amdgpu drivers (version 6.3.3 or newer)
wget https://repo.radeon.com/amdgpu-install/6.3.3/ubuntu/noble/amdgpu-install_6.3.60303-1_all.deb
sudo apt install -y ./amdgpu-install_6.3.60303-1_all.deb
sudo apt update
sudo apt install -y amdgpu-dkms rocm

# Reboot to load new drivers
sudo reboot
```

### Arch Linux

```bash
# Update package list
sudo pacman -Syu

# Install ROCm and dependencies
sudo pacman -S --needed base-devel rocm-opencl rocm-libs rocm-opencl-icd

# Add current user to render and video groups for GPU access
sudo usermod -a -G render,video $USER

# Install amdgpu drivers
sudo pacman -S --needed amdgpu

# Reboot to load new drivers
sudo reboot
```

## Step 2: Install Ollama

```bash
# Download and install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Verify installation
~/.local/opt/ollama/bin/ollama --version

# Install AMD ROCm package for GPU acceleration
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama
```

## Step 3: Create Systemd USER Service

Create the service file in `~/.config/systemd/user/ollama.service`:

```ini
[Unit]
Description=Ollama Service (User)
After=network-online.target

[Service]
Type=simple
ExecStart=$HOME/.local/opt/ollama/bin/ollama serve
Restart=always
RestartSec=3
Environment="PATH=$HOME/.local/opt/ollama/bin:$PATH"
Environment="OLLAMA_HOST=127.0.0.1"
Environment="OLLAMA_PORT=11434"

[Install]
WantedBy=default.target
```

## Step 4: Enable and Start the Service

```bash
# Reload systemd daemon
systemctl --user daemon-reload

# Enable the service to start on boot
systemctl --user enable ollama

# Start the service
systemctl --user start ollama

# Check service status
systemctl --user status ollama
```

## Step 5: Verify Installation

```bash
# Check if Ollama is running
~/.local/opt/ollama/bin/ollama --version

# Test the API
curl http://127.0.0.1:11434/api/tags

# Pull a test model
~/.local/opt/ollama/bin/ollama pull llama3.2

# Run a model
~/.local/opt/ollama/bin/ollama run llama3.2
```

## Step 6: Configure Environment Variables (Optional)

Create `~/.config/environment.d/ollama.conf` for persistent environment variables:

```bash
OLLAMA_HOST=127.0.0.1
OLLAMA_PORT=11434
OLLAMA_MODELS_DIR=$HOME/.ollama/models
```

## Step 7: GPU Verification

```bash
# Check if GPU is detected by ROCm
rocminfo

# Verify GPU acceleration is working
ollama run llama3.2 --gpus all
```

## Step 8: Troubleshooting

### Common Issues

1. **GPU not detected:**
   ```bash
   # Check ROCm installation
   rocminfo
   
   # Check kernel modules
   lsmod | grep amdgpu
   ```

2. **Service not starting:**
   ```bash
   # Check logs
   journalctl --user -u ollama -f
   
   # Check permissions
   ls -la ~/.config/systemd/user/ollama.service
   ```

3. **Port already in use:**
   ```bash
   # Check what's using port 11434
   sudo ss -tulpn | grep 11434
   ```

4. **Binary not found:**
   ```bash
   # Check PATH
   echo $PATH
   
   # Verify binary exists
   ls -la ~/.local/opt/ollama/bin/ollama
   ```

5. **Model storage location:**
   ```bash
   # Check default model location
   ls -la ~/.local/opt/ollama/models
   ```

### Performance Tuning

Add these options to the service file for better performance:

```ini
[Service]
# Increase file descriptor limit
LimitNOFILE=65536

# Set CPU and memory limits
CPUQuota=80%
MemoryHigh=8G
MemoryMax=16G

# Enable GPU acceleration
Environment="OLLAMA_GPU=amd"
Environment="OLLAMA_GPUS=0"
```

## Step 9: Model Management

### Pull Models

```bash
# Pull specific models
~/.local/opt/ollama/bin/ollama pull llama3.2:3b
~/.local/opt/ollama/bin/ollama pull codellama:7b
~/.local/opt/ollama/bin/ollama pull deepseek-coder:6.7b

# List available models
~/.local/opt/ollama/bin/ollama list
```

### Model Storage

By default, models are stored in `~/.ollama/models`. To change this:

1. Create a new directory:
   ```bash
   mkdir -p ~/ollama-models
   ```

2. Update the service file:
   ```ini
   [Service]
   Environment="OLLAMA_MODELS_DIR=$HOME/ollama-models"
   ```

## Step 10: Security Considerations

### Firewall Configuration

```bash
# Allow access from local network only
sudo ufw allow from 192.168.1.0/24 to any port 11434
```

### User Permissions

```bash
# Ensure proper file permissions
chmod 600 ~/.config/systemd/user/ollama.service
```

### PATH Configuration

Create a symlink for easy access:

```bash
mkdir -p ~/.local/bin
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Or create a user environment file:

```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/ollama.conf << 'EOF'
PATH=$HOME/.local/bin:$PATH
OLLAMA_HOST=127.0.0.1
OLLAMA_PORT=11434
EOF
```

Or create a user environment file:

```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/ollama.conf << 'EOF'
PATH=$HOME/.ollama/bin:$PATH
OLLAMA_HOST=127.0.0.1
OLLAMA_PORT=11434
EOF
```

## Uninstall Guide

To completely remove Ollama:

```bash
# Stop and disable the service
systemctl --user stop ollama
systemctl --user disable ollama

# Remove service file
rm ~/.config/systemd/user/ollama.service

# Reload systemd daemon
systemctl --user daemon-reload

# Remove Ollama installation
rm -rf ~/.ollama

# Remove ROCm drivers (optional)
sudo apt remove -y amdgpu-dkms rocm
```

## Monitoring

### Log Monitoring

```bash
# Real-time logs
journalctl --user -u ollama -f

# View recent logs
journalctl --user -u ollama --since "1 hour ago"
```

### Performance Monitoring

```bash
# Check GPU usage
rocm-smi

# Monitor system resources
htop

# Check Ollama API
curl http://127.0.0.1:11434/api/tags
```

## Additional Resources

- [Ollama Official Documentation](https://docs.ollama.com/)
- [ROCm Documentation](https://rocm.docs.amd.com/)
- [AMD GPU Drivers](https://www.amd.com/en/support/linux-drivers)

## Notes

- This guide uses systemd USER services, which run under your user account without requiring sudo for service management.
- GPU acceleration is automatically detected if ROCm drivers are properly installed.
- Models will be stored in your home directory by default for easier backup and management.
- The service will automatically restart if it crashes or on system boot.
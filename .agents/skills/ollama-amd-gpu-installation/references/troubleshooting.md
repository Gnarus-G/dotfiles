# Troubleshooting

## GPU Issues

### GPU Not Detected

**Symptoms:**
- `rocminfo` returns no GPU information
- Ollama runs on CPU only
- Performance is slow

**Solutions:**

1. Check if GPU is detected by system:
   ```bash
   lspci | grep -i amd
   ```

2. Check kernel modules:
   ```bash
   lsmod | grep amdgpu
   ```

3. Check ROCm installation:
   ```bash
   rocminfo
   ```

4. Verify user groups:
   ```bash
   groups $USER | grep -E 'render|video'
   ```

5. If groups missing, add them:
   ```bash
   sudo usermod -a -G render,video $USER
   # Logout and login again
   ```

6. Reinstall ROCm drivers if needed.

### GPU Permission Errors

**Symptoms:**
- Permission denied errors when accessing GPU
- `/dev/kfd` or `/dev/dri/` access errors

**Solutions:**

1. Check device permissions:
   ```bash
   ls -la /dev/kfd /dev/dri/
   ```

2. Add user to render group:
   ```bash
   sudo usermod -a -G render,video $USER
   # Logout and login
   ```

3. Temporary fix (until reboot):
   ```bash
   sudo chmod 666 /dev/kfd
   sudo chmod -R 666 /dev/dri/
   ```

### Poor GPU Performance

**Symptoms:**
- Slow model inference
- Low GPU utilization
- High CPU usage

**Solutions:**

1. Check if GPU is being used:
   ```bash
   rocm-smi -d
   ```

2. Monitor GPU usage during inference:
   ```bash
   watch -n 1 rocm-smi
   ```

3. Verify ROCm package is installed:
   ```bash
   ls -la ~/.local/opt/ollama/lib/ollama/ | grep rocm
   ```

4. Reinstall ROCm package:
   ```bash
   curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama
   ```

5. Set GPU environment variables in service file:
   ```ini
   Environment="OLLAMA_GPU=amd"
   Environment="OLLAMA_GPUS=0"
   ```

## Service Issues

### Service Won't Start

**Symptoms:**
- `systemctl --user status ollama` shows failed
- Service exits immediately

**Solutions:**

1. Check logs for errors:
   ```bash
   journalctl --user -u ollama -xe
   ```

2. Check if binary exists and is executable:
   ```bash
   ls -la ~/.local/opt/ollama/bin/ollama
   test -x ~/.local/opt/ollama/bin/ollama && echo "Executable" || echo "Not executable"
   ```

3. Check PATH in service file:
   ```bash
   grep "PATH" ~/.config/systemd/user/ollama.service
   ```

4. Try running manually:
   ```bash
   ~/.local/opt/ollama/bin/ollama serve
   ```

5. Verify service file syntax:
   ```bash
   systemd-analyze verify ~/.config/systemd/user/ollama.service
   ```

### Service Dies After Some Time

**Symptoms:**
- Service starts but crashes randomly
- Intermittent availability

**Solutions:**

1. Check memory usage:
   ```bash
   free -h
   htop
   ```

2. Add memory limits to service:
   ```ini
   [Service]
   MemoryHigh=8G
   MemoryMax=16G
   ```

3. Check for OOM kills:
   ```bash
   journalctl -xe | grep -i "out of memory"
   dmesg | grep -i "oom"
   ```

4. Monitor logs:
   ```bash
   journalctl --user -u ollama -f
   ```

### Service Not Starting on Boot

**Symptoms:**
- Service doesn't start automatically after login
- Need to manually start each time

**Solutions:**

1. Check if service is enabled:
   ```bash
   systemctl --user is-enabled ollama
   ```

2. Enable service:
   ```bash
   systemctl --user enable ollama
   ```

3. Check systemd user manager:
   ```bash
   systemctl --user status
   ```

4. Verify service file:
   ```bash
   ls -la ~/.config/systemd/user/ollama.service
   ```

## API Issues

### API Not Responding

**Symptoms:**
- `curl http://127.0.0.1:11434/api/tags` fails
- Connection refused

**Solutions:**

1. Check if service is running:
   ```bash
   systemctl --user status ollama
   ```

2. Check port:
   ```bash
   sudo ss -tulpn | grep 11434
   ```

3. Check logs:
   ```bash
   journalctl --user -u ollama -f
   ```

4. Restart service:
   ```bash
   systemctl --user restart ollama
   ```

5. Check firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 11434/tcp
   ```

### API Slow Response

**Symptoms:**
- Requests timeout
- Very slow responses

**Solutions:**

1. Check system resources:
   ```bash
   htop
   free -h
   ```

2. Monitor GPU usage:
   ```bash
   rocm-smi -d
   ```

3. Check if GPU is being used:
   ```bash
   watch -n 1 rocm-smi
   ```

4. Reduce model size or use quantized models.

5. Increase timeout in API calls:
   ```bash
   curl --max-time 300 http://127.0.0.1:11434/api/generate -d '{...}'
   ```

## Installation Issues

### Binary Not Found

**Symptoms:**
- Command not found: ollama
- `~/.local/opt/ollama/bin/ollama` doesn't exist

**Solutions:**

1. Reinstall Ollama:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```

2. Check installation location:
   ```bash
   find ~ -name "ollama" -type f 2>/dev/null
   ```

3. Verify PATH:
   ```bash
   echo $PATH | grep -o "$HOME/.local/bin"
   ```

4. Create symlink:
   ```bash
   mkdir -p ~/.local/bin
   ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
   ```

### Permission Denied

**Symptoms:**
- Cannot execute ollama binary
- Permission errors

**Solutions:**

1. Check file permissions:
   ```bash
   ls -la ~/.local/opt/ollama/bin/ollama
   ```

2. Make executable:
   ```bash
   chmod +x ~/.local/opt/ollama/bin/ollama
   ```

3. Check directory ownership:
   ```bash
   chown -R $USER:$USER ~/.local/opt/ollama
   ```

### Installation Script Fails

**Symptoms:**
- `curl -fsSL https://ollama.com/install.sh | sh` fails
- Download errors

**Solutions:**

1. Check internet connection:
   ```bash
   ping -c 3 ollama.com
   ```

2. Download manually:
   ```bash
   curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst -o ollama.tar.zst
   tar x -C ~/.local/opt/ollama -f ollama.tar.zst
   ```

3. Check disk space:
   ```bash
   df -h ~
   ```

## Model Issues

### Model Won't Load

**Symptoms:**
- Model download fails
- Out of memory errors

**Solutions:**

1. Check disk space:
   ```bash
   df -h ~/.local/opt/ollama/models/
   du -sh ~/.local/opt/ollama/models/
   ```

2. Check available RAM:
   ```bash
   free -h
   ```

3. Try smaller model:
   ```bash
   ollama pull tinyllama
   ```

4. Check GPU memory:
   ```bash
   rocm-smi --showmeminfo vram
   ```

### Model Download Slow

**Symptoms:**
- Very slow downloads
- Connection timeouts

**Solutions:**

1. Check internet speed:
   ```bash
   speedtest-cli
   ```

2. Use smaller quantized models.

3. Resume partial downloads:
   ```bash
   ollama pull llama3.2 --insecure
   ```

### Model Running Slow

**Symptoms:**
- Low tokens per second
- High latency

**Solutions:**

1. Check GPU usage:
   ```bash
   rocm-smi -d
   ```

2. Use quantized models:
   ```bash
   ollama pull llama3.2:3b-q4
   ```

3. Monitor system resources:
   ```bash
   htop
   ```

4. Reduce context size in requests.

## Network Issues

### Port Already in Use

**Symptoms:**
- Address already in use error
- Port 11434 occupied

**Solutions:**

1. Find what's using the port:
   ```bash
   sudo lsof -i :11434
   sudo ss -tulpn | grep 11434
   ```

2. Kill conflicting process:
   ```bash
   sudo kill -9 <PID>
   ```

3. Change port in service file:
   ```ini
   Environment="OLLAMA_PORT=11435"
   ```

### Cannot Access from Network

**Symptoms:**
- Works on localhost but not from other machines

**Solutions:**

1. Bind to all interfaces:
   ```ini
   Environment="OLLAMA_HOST=0.0.0.0"
   ```

2. Check firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 11434/tcp
   ```

3. Check network connectivity:
   ```bash
   ip addr show
   ping <server-ip>
   ```

## Log Analysis

### Useful Log Commands

```bash
# View all logs
journalctl --user -u ollama

# Follow logs in real-time
journalctl --user -u ollama -f

# View errors only
journalctl --user -u ollama -p err

# View recent logs
journalctl --user -u ollama --since "1 hour ago"

# View logs with context
journalctl --user -u ollama -xe

# Search for specific term
journalctl --user -u ollama | grep -i "error\|failed\|warning"
```

### Common Log Messages

- `address already in use`: Port conflict
- `permission denied`: Group permissions or file permissions
- `out of memory`: Need more RAM or GPU memory
- `connection refused`: Service not running or firewall issue
- `gpu not found`: Driver or ROCm installation issue

## Performance Tuning

### Optimize Service

Add to service file:

```ini
[Service]
LimitNOFILE=65536
CPUQuota=80%
MemoryHigh=8G
MemoryMax=16G
Environment="OLLAMA_GPU=amd"
Environment="OLLAMA_GPUS=0"
```

### Monitor Performance

```bash
# GPU monitoring
watch -n 1 rocm-smi

# System monitoring
htop

# API response time
time curl http://127.0.0.1:11434/api/tags
```

## Clean Installation

If nothing works, start fresh:

```bash
# Stop and remove service
systemctl --user stop ollama
systemctl --user disable ollama
rm ~/.config/systemd/user/ollama.service

# Remove Ollama
rm -rf ~/.local/opt/ollama
rm ~/.local/bin/ollama

# Clean models (optional)
rm -rf ~/.local/opt/ollama/models

# Reinstall
curl -fsSL https://ollama.com/install.sh | sh

# Install ROCm package
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama

# Create symlink
mkdir -p ~/.local/bin
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama

# Recreate service
# (use service template from earlier)
```

## Getting Help

1. **Check logs first:**
   ```bash
   journalctl --user -u ollama -xe
   ```

2. **Search GitHub issues:**
   https://github.com/ollama/ollama/issues

3. **Ollama documentation:**
   https://docs.ollama.com/

4. **ROCm documentation:**
   https://rocm.docs.amd.com/

5. **Community forums:**
   - Reddit: r/LocalLLaMA
   - Ollama Discord

## Notes

- Most issues are related to GPU permissions or driver installation
- User must be in render and video groups
- Systemd USER services have different behavior than system services
- Check logs first before debugging
- GPU acceleration significantly improves performance for models > 7B
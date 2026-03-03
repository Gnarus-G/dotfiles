# Verification

## Basic Installation Verification

### Check Binary

```bash
# Check if binary exists
ls -la ~/.local/opt/ollama/bin/ollama

# Check symlink
ls -la ~/.local/bin/ollama

# Test command
~/.local/opt/ollama/bin/ollama --version
```

### Check Service Status

```bash
# Check service status
systemctl --user status ollama

# Check if service is running
systemctl --user is-active ollama

# Check if service is enabled
systemctl --user is-enabled ollama
```

### Test API

```bash
# Check if API is responding
curl http://127.0.0.1:11434/api/tags

# Should return JSON response with models list
```

## GPU Verification

### Check ROCm Installation

```bash
# Check ROCm installation
rocminfo

# Should list your GPU details
```

### Check GPU Detection

```bash
# Check if GPU is detected
lspci | grep -i amd

# Check kernel modules
lsmod | grep amdgpu
```

### Test GPU Acceleration

```bash
# Run model with GPU acceleration
~/.local/opt/ollama/bin/ollama run llama3.2 --gpus all
```

## Model Tests

### Pull Test Model

```bash
# Pull a small test model
~/.local/opt/ollama/bin/ollama pull llama3.2:3b

# Or pull smaller model
~/.local/opt/ollama/bin/ollama pull tinyllama
```

### List Models

```bash
# List installed models
~/.local/opt/ollama/bin/ollama list
```

### Run Model

```bash
# Run model interactively
~/.local/opt/ollama/bin/ollama run llama3.2

# Test with a prompt
echo "What is 2+2?" | ~/.local/opt/ollama/bin/ollama run llama3.2
```

### API Test

```bash
# Generate completion via API
curl http://127.0.0.1:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?"
}'

# Chat completion via API
curl http://127.0.0.1:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    { "role": "user", "content": "Hello!" }
  ]
}'
```

## System Checks

### Check PATH

```bash
# Verify PATH includes ~/.local/bin
echo $PATH | grep -q "$HOME/.local/bin" && echo "PATH OK" || echo "PATH missing ~/.local/bin"

# Test ollama command in PATH
which ollama
```

### Check User Groups

```bash
# Check if user is in render and video groups
groups $USER | grep -E 'render|video'
```

### Check Port Availability

```bash
# Check if port 11434 is in use
sudo ss -tulpn | grep 11434

# Or check with netstat
sudo netstat -tulpn | grep 11434
```

## Performance Verification

### Benchmark Model

```bash
# Run benchmark
~/.local/opt/ollama/bin/ollama run llama3.2 --verbose

# Watch for tokens per second in output
```

### Monitor GPU Usage

```bash
# Monitor GPU usage while running model
rocm-smi -d

# Check GPU memory usage
rocm-smi --showmeminfo vram
```

### Check System Resources

```bash
# Monitor CPU and memory
htop

# Check memory usage
free -h

# Check disk usage for models
du -sh ~/.local/opt/ollama/models/
```

## Log Verification

### Check Logs

```bash
# View recent logs
journalctl --user -u ollama --since "5 minutes ago"

# Follow logs in real-time
journalctl --user -u ollama -f
```

### Look for Errors

```bash
# Check for errors in logs
journalctl --user -u ollama -p err

# Check for warnings
journalctl --user -u ollama -p warning
```

## Full Verification Script

Create a verification script:

```bash
cat > /tmp/verify_ollama.sh << 'EOF'
#!/bin/bash
echo "=== Ollama Verification Script ==="
echo ""

echo "1. Checking binary..."
if [ -f "$HOME/.local/opt/ollama/bin/ollama" ]; then
    echo "✓ Binary found at ~/.local/opt/ollama/bin/ollama"
else
    echo "✗ Binary not found"
    exit 1
fi

echo ""
echo "2. Checking symlink..."
if [ -L "$HOME/.local/bin/ollama" ]; then
    echo "✓ Symlink exists at ~/.local/bin/ollama"
else
    echo "✗ Symlink not found"
fi

echo ""
echo "3. Checking version..."
~/.local/opt/ollama/bin/ollama --version

echo ""
echo "4. Checking service..."
systemctl --user is-active ollama && echo "✓ Service is running" || echo "✗ Service not running"

echo ""
echo "5. Checking API..."
if curl -s http://127.0.0.1:11434/api/tags > /dev/null; then
    echo "✓ API is responding"
else
    echo "✗ API not responding"
fi

echo ""
echo "6. Checking GPU..."
if command -v rocminfo &> /dev/null; then
    rocminfo | grep -q "Name:" && echo "✓ GPU detected by ROCm" || echo "✗ GPU not detected"
else
    echo "✗ ROCm not installed"
fi

echo ""
echo "7. Checking user groups..."
if groups $USER | grep -qE 'render|video'; then
    echo "✓ User in render/video groups"
else
    echo "✗ User not in render/video groups"
fi

echo ""
echo "=== Verification Complete ==="
EOF

chmod +x /tmp/verify_ollama.sh
/tmp/verify_ollama.sh
```

## Common Verification Issues

### API Not Responding

1. Check service status:
   ```bash
   systemctl --user status ollama
   ```

2. Check logs:
   ```bash
   journalctl --user -u ollama -f
   ```

3. Verify port:
   ```bash
   sudo ss -tulpn | grep 11434
   ```

### GPU Not Detected

1. Check ROCm:
   ```bash
   rocminfo
   ```

2. Check groups:
   ```bash
   groups $USER | grep render
   ```

3. Check drivers:
   ```bash
   lsmod | grep amdgpu
   ```

### Service Fails to Start

1. Check logs:
   ```bash
   journalctl --user -u ollama -xe
   ```

2. Check PATH:
   ```bash
   echo $PATH
   ```

3. Check permissions:
   ```bash
   ls -la ~/.config/systemd/user/ollama.service
   ```

## Notes

- Run verification after each installation step
- GPU acceleration requires proper ROCm installation
- API listens on localhost by default (127.0.0.1:11434)
- Models are stored in ~/.local/opt/ollama/models/
- User must be in render and video groups for GPU access
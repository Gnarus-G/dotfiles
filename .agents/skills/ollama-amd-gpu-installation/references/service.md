# Systemd USER Service Configuration

## Service File Location

Create the service file at:
```
~/.config/systemd/user/ollama.service
```

## Basic Service File

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

## Create Service File

```bash
# Create systemd user directory
mkdir -p ~/.config/systemd/user

# Create service file
cat > ~/.config/systemd/user/ollama.service << 'EOF'
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
EOF
```

## Performance-Tuned Service File

For better performance, use this enhanced configuration:

```ini
[Unit]
Description=Ollama Service (User)
After=network-online.target

[Service]
Type=simple
ExecStart=$HOME/.local/opt/ollama/bin/ollama serve
Restart=always
RestartSec=3

# Environment configuration
Environment="PATH=$HOME/.local/opt/ollama/bin:$PATH"
Environment="OLLAMA_HOST=127.0.0.1"
Environment="OLLAMA_PORT=11434"
Environment="OLLAMA_GPU=amd"
Environment="OLLAMA_GPUS=0"

# Performance tuning
LimitNOFILE=65536
CPUQuota=80%
MemoryHigh=8G
MemoryMax=16G

[Install]
WantedBy=default.target
```

## Service Management Commands

### Enable Service

```bash
# Reload systemd daemon to recognize new service
systemctl --user daemon-reload

# Enable service to start on boot
systemctl --user enable ollama
```

### Start Service

```bash
# Start ollama service
systemctl --user start ollama
```

### Check Status

```bash
# Check service status
systemctl --user status ollama

# Check if service is enabled
systemctl --user is-enabled ollama
```

### Stop Service

```bash
# Stop ollama service
systemctl --user stop ollama
```

### Disable Service

```bash
# Stop and disable service
systemctl --user stop ollama
systemctl --user disable ollama
```

### Restart Service

```bash
# Restart ollama service
systemctl --user restart ollama
```

## Environment Variables

### Via Service File

Add environment variables in the service file:

```ini
[Service]
Environment="OLLAMA_HOST=127.0.0.1"
Environment="OLLAMA_PORT=11434"
Environment="OLLAMA_GPU=amd"
Environment="OLLAMA_GPUS=0"
```

### Via Environment File

Create a separate environment file:

```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/ollama.conf << 'EOF'
PATH=$HOME/.local/bin:$PATH
OLLAMA_HOST=127.0.0.1
OLLAMA_PORT=11434
OLLAMA_GPU=amd
OLLAMA_GPUS=0
EOF
```

Then reference it in the service file:

```ini
[Service]
EnvironmentFile=%h/.config/environment.d/ollama.conf
```

## Logging

### View Logs

```bash
# View all logs
journalctl --user -u ollama

# Follow logs in real-time
journalctl --user -u ollama -f

# View recent logs
journalctl --user -u ollama --since "1 hour ago"

# View logs with priority
journalctl --user -u ollama -p err
```

### Log Rotation

Systemd handles log rotation automatically via journald.

## Service File Permissions

```bash
# Set appropriate permissions
chmod 600 ~/.config/systemd/user/ollama.service

# Verify permissions
ls -la ~/.config/systemd/user/ollama.service
```

## Override Configuration

To modify the service without editing the main file:

```bash
# Create override directory
mkdir -p ~/.config/systemd/user/ollama.service.d

# Create override file
cat > ~/.config/systemd/user/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_DEBUG=1"
EOF

# Reload daemon
systemctl --user daemon-reload
```

## Multiple Instances

To run multiple Ollama instances:

1. Create `~/.config/systemd/user/ollama@.service`:

```ini
[Unit]
Description=Ollama Service (User) - Instance %i
After=network-online.target

[Service]
Type=simple
ExecStart=$HOME/.local/opt/ollama/bin/ollama serve
Restart=always
RestartSec=3
Environment="PATH=$HOME/.local/opt/ollama/bin:$PATH"
Environment="OLLAMA_HOST=127.0.0.1"
Environment="OLLAMA_PORT=1143%i"

[Install]
WantedBy=default.target
```

2. Enable and start instances:

```bash
# Enable instance on port 11434
systemctl --user enable ollama@4
systemctl --user start ollama@4

# Enable instance on port 11435
systemctl --user enable ollama@5
systemctl --user start ollama@5
```

## Notes

- USER services run with user permissions, not root
- Service files are in `~/.config/systemd/user/`
- Use `systemctl --user` instead of `systemctl`
- Services start after user login, not at boot
- Use `default.target` for services that should start on login
- Environment variables can be set in service file or separate config
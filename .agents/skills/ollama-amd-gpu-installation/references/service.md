# systemd User Service (AMD GPU Only)

Service file path:

`~/.config/systemd/user/ollama.service`

## Create Service

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
Environment=OLLAMA_HOST=0.0.0.0:11434
Environment=OLLAMA_GPU=amd
Environment=OLLAMA_LLM_LIBRARY=rocm

[Install]
WantedBy=default.target
EOF
```

## Start Service

```bash
systemctl --user daemon-reload
systemctl --user enable --now ollama
```

If a prior system-wide service exists and occupies port `11434`, edit the user service to use a different host:port (for example `0.0.0.0:11435`) and restart the user service.

## Basic Management

```bash
systemctl --user status ollama --no-pager
systemctl --user restart ollama
journalctl --user -u ollama -n 50 --no-pager
```

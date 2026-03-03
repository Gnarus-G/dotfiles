# Ollama Installation

## Download and Install

```bash
# Download and run the official installation script
curl -fsSL https://ollama.com/install.sh | sh
```

This installs Ollama to `~/.local/opt/ollama/` by default.

## AMD GPU Support

### Install ROCm Package

After installing Ollama, add AMD GPU support:

```bash
# Download and extract AMD ROCm package for Ollama
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst | tar x -C ~/.local/opt/ollama
```

## Create Symlink

Create a symlink for easier access:

```bash
# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Create symlink to ollama binary
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

## Add to PATH

Add `~/.local/bin` to your PATH for easy command access.

### Option 1: Shell Configuration

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

### Option 2: Systemd Environment

Create a systemd environment file:

```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/ollama.conf << 'EOF'
PATH=$HOME/.local/bin:$PATH
OLLAMA_HOST=127.0.0.1
OLLAMA_PORT=11434
EOF
```

## Verify Installation

```bash
# Check installation location
ls -la ~/.local/opt/ollama/

# Check binary
ls -la ~/.local/opt/ollama/bin/ollama

# Check symlink
ls -la ~/.local/bin/ollama

# Test command
ollama --version

# Or with full path
~/.local/opt/ollama/bin/ollama --version
```

## Directory Structure

After installation, the directory structure looks like:

```
~/.local/
├── bin/
│   └── ollama -> ../opt/ollama/bin/ollama (symlink)
└── opt/
    └── ollama/
        ├── bin/
        │   └── ollama
        └── lib/
            └── ollama/ (libraries and ROCm files)
```

## Manual Installation (Alternative)

If you prefer manual installation:

```bash
# Create directories
mkdir -p ~/.local/opt/ollama
mkdir -p ~/.local/bin

# Download and extract manually
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst | tar x -C ~/.local/opt/ollama

# Create symlink
ln -sf ~/.local/opt/ollama/bin/ollama ~/.local/bin/ollama
```

## Specific Version Installation

To install a specific version:

```bash
# Install specific version
curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.5.7 sh
```

Check available versions at: https://github.com/ollama/ollama/releases

## Notes

- Default installation location is `~/.local/opt/ollama/`
- Symlink in `~/.local/bin/` provides easy command access
- AMD ROCm package must be installed separately for GPU support
- No sudo required for user-level installation
- Models are stored in `~/.local/opt/ollama/models/` by default
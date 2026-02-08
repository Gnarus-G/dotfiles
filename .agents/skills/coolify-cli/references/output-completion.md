# Output Formats and Shell Completion

## Output Formats

The CLI supports three output formats:

```bash
# Table format (default, human-readable)
coolify server list

# JSON format (for scripts)
coolify server list --format=json

# Pretty JSON (for debugging)
coolify server list --format=pretty
```

## Shell Completion

### Bash

```bash
coolify completion bash > /etc/bash_completion.d/coolify
```

### Zsh

```bash
coolify completion zsh > "${fpath[1]}/_coolify"
```

### Fish

```bash
coolify completion fish > ~/.config/fish/completions/coolify.fish
```

### PowerShell

```powershell
coolify completion powershell > coolify.ps1
```

# Installation

## Linux/macOS (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh | bash
```

Installs to `/usr/local/bin/coolify` with config at `~/.config/coolify/config.json`

## Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.ps1 | iex
```

Installs to `%ProgramFiles%\Coolify\coolify.exe` with config at `%USERPROFILE%\.config\coolify\config.json`

## User installation (no admin rights)

```powershell
$env:COOLIFY_USER_INSTALL=1; irm https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.ps1 | iex
```

## Go install

```bash
go install github.com/coollabsio/coolify-cli/coolify@latest
```

## Update CLI

```bash
coolify update
```

## Verify Installation

```bash
coolify config  # Show configuration file location
coolify version # Show CLI version
```

# Context Management

## Getting Started

### 1. Get API Token

From your Coolify dashboard: `/security/api-tokens`

### 2. Configure Context

**For Coolify Cloud:**
```bash
coolify context set-token cloud <token>
```

**For self-hosted:**
```bash
coolify context add <context_name> <url> <token>
# Example:
coolify context add prod https://coolify.example.com <token>
```

### 3. Set Default Context

```bash
coolify context use <context_name>
# or
coolify context set-default <context_name>
```

### 4. Verify Setup

```bash
coolify context verify
coolify context version
```

## Managing Multiple Contexts

```bash
# List all contexts
coolify context list

# Add new context
coolify context add <name> <url> <token>
coolify context add -d <name> <url> <token>  # Set as default

# Get context details
coolify context get <name>

# Update context
coolify context update <name> --name <new_name> --url <new_url> --token <new_token>

# Set token for existing context
coolify context set-token <name> <token>

# Delete context
coolify context delete <name>

# Verify connection
coolify context verify

# Get API version
coolify context version
```

## Multi-Environment Workflows

```bash
# Add multiple contexts
coolify context add prod https://prod.coolify.io <prod-token>
coolify context add staging https://staging.coolify.io <staging-token>
coolify context add dev https://dev.coolify.io <dev-token>

# Set default
coolify context use prod

# Use different contexts
coolify --context=staging server list
coolify --context=prod deploy name api
coolify --context=dev resources list

# Default context (prod)
coolify server list
```

## Global Flags

All commands support these flags:

```bash
--context <name>      # Use specific context instead of default
--host <fqdn>         # Override Coolify instance hostname
--token <token>       # Override authentication token
--format <format>     # Output format: table (default), json, pretty
-s, --show-sensitive  # Show sensitive info (tokens, IPs)
-f, --force           # Skip confirmations
--debug               # Enable debug mode
```

# GitHub Apps

## List GitHub Apps

```bash
coolify github list
```

## Get GitHub App Details

```bash
coolify github get <app_uuid>
```

## Create GitHub App

```bash
coolify github create \
  --name "My GitHub App" \
  --api-url "https://api.github.com" \
  --html-url "https://github.com" \
  --app-id 123456 \
  --installation-id 789012 \
  --client-id "Iv1.abc123" \
  --client-secret "secret" \
  --private-key-uuid <key-uuid> \
  --webhook-secret "webhook-secret"
```

Options:
- `--name <name>` - GitHub App name (required)
- `--api-url <url>` - GitHub API URL (required, e.g., https://api.github.com)
- `--html-url <url>` - GitHub HTML URL (required, e.g., https://github.com)
- `--app-id <id>` - GitHub App ID (required)
- `--installation-id <id>` - GitHub Installation ID (required)
- `--client-id <id>` - GitHub OAuth Client ID (required)
- `--client-secret <secret>` - GitHub OAuth Client Secret (required)
- `--private-key-uuid <uuid>` - UUID of existing private key (required)
- `--organization <org>` - GitHub organization
- `--custom-user <user>` - Custom user for SSH (default: git)
- `--custom-port <port>` - Custom port for SSH (default: 22)
- `--webhook-secret <secret>` - GitHub Webhook Secret
- `--system-wide` - Is this app system-wide (cloud only)

## Update GitHub App

```bash
coolify github update <app_uuid>
```

## Delete GitHub App

```bash
coolify github delete <app_uuid> -f
```

## List Repositories

```bash
coolify github repos <app_uuid>
```

## List Branches

```bash
coolify github branches <app_uuid> owner/repo
```

## Workflow Example

```bash
# 1. Add private key for GitHub App
coolify private-key add github-app-key @~/.ssh/github_app_key

# 2. Create GitHub App
coolify github create \
  --name "Production App" \
  --api-url "https://api.github.com" \
  --html-url "https://github.com" \
  --app-id 123456 \
  --installation-id 789012 \
  --client-id "Iv1.abc123" \
  --client-secret "your-secret" \
  --private-key-uuid <key-uuid-from-step-1>

# 3. Verify and list repos
coolify github list
coolify github repos <app-uuid>

# 4. List branches for a specific repo
coolify github branches <app-uuid> myorg/myrepo
```

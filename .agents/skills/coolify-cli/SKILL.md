---
name: coolify-cli
description: CLI for Coolify - manage deployments, resources, servers, and applications from the command line
---

# Coolify CLI Skill

## What I do

- Guide users through installing and configuring the Coolify CLI
- Provide command references for managing Coolify resources
- Help with deployment workflows and automation
- Assist with server, database, and application management

## When to use me

Use this when you need to:

- Install or set up the Coolify CLI
- Manage Coolify resources (apps, databases, servers, deployments)
- Automate deployment workflows
- Configure multiple Coolify contexts (dev/staging/prod)
- Troubleshoot CLI issues

## Quick Reference

| Topic | Description | Reference |
|-------|-------------|-----------|
| **Installation** | Install CLI on Linux, macOS, Windows | [installation.md](references/installation.md) |
| **Contexts** | Configure and switch between Coolify instances | [contexts.md](references/contexts.md) |
| **Apps** | Deploy applications from Git repos (public/private) | [apps.md](references/apps.md) |
| **Env Vars** | Manage environment variables | [env-vars.md](references/env-vars.md) |
| **Servers** | Add and manage servers, SSH keys | [servers.md](references/servers.md) |
| **Databases** | Create databases, configure backups | [databases.md](references/databases.md) |
| **Deployments** | Deploy apps, view logs, batch deploy | [deployments.md](references/deployments.md) |
| **GitHub Apps** | Integrate private GitHub repositories | [github.md](references/github.md) |
| **Projects** | Manage projects and services | [projects-services.md](references/projects-services.md) |
| **Teams** | List teams and members | [teams.md](references/teams.md) |
| **Output** | Output formats and shell completion | [output-completion.md](references/output-completion.md) |

## Essential Commands

### Get Started

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/coollabsio/coolify-cli/main/scripts/install.sh | bash

# Configure context (Cloud)
coolify context set-token cloud <token>

# Configure context (Self-hosted)
coolify context add prod https://coolify.example.com <token>

# Verify
coolify context verify
```

### Deploy Application

```bash
# Deploy by name
coolify deploy name my-application -f

# Follow logs
coolify app deployments logs <app-uuid> -f
```

### Batch Deployments

```bash
# Deploy multiple apps
coolify deploy batch api,worker,frontend --force
```

### Environment Variables

```bash
# Sync from .env file
coolify app env sync <app-uuid> --file .env
```

## Troubleshooting

### CLI Update

```bash
coolify update
```

### Configuration Location

```bash
coolify config
```

### Debug Mode

```bash
coolify --debug <command>
```

### Verify Context

```bash
coolify context verify
coolify context version
```

## Best Practices

1. **Use named deployments**: `coolify deploy name myapp` instead of UUIDs
2. **Set up multiple contexts**: Separate dev/staging/prod configurations
3. **Use .env file sync**: Keep env vars in version control-friendly files
4. **Enable backups**: Configure automated database backups
5. **Use force flag carefully**: `-f` skips confirmations - use with caution in production
6. **Validate servers**: Use `--validate` when adding new servers
7. **Check logs**: Use `-f` flag to follow deployment logs in real-time

## Resources

- GitHub: https://github.com/coollabsio/coolify-cli
- Coolify: https://coolify.io
- API Docs: Available in your Coolify instance at `/api/documentation`

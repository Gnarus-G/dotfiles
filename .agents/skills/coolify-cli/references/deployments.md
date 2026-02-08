# Deployments

## Deploy Commands

```bash
# Deploy by UUID
coolify deploy uuid <uuid> -f

# Deploy by name (easier!)
coolify deploy name <name> -f

# Deploy multiple resources
coolify deploy batch <name1,name2,name3> -f

# List deployments
coolify deploy list

# Get deployment details
coolify deploy get <uuid>

# Cancel deployment
coolify deploy cancel <uuid> -f
```

## Application Deployments

```bash
# List deployments
coolify app deployments list <app_uuid>

# Get deployment logs (latest)
coolify app deployments logs <app_uuid>

# Get deployment logs (specific)
coolify app deployments logs <app_uuid> <deployment_uuid>

# Follow logs in real-time
coolify app deployments logs <app_uuid> -f

# Show last N lines
coolify app deployments logs <app_uuid> -n 100

# Show debug logs
coolify app deployments logs <app_uuid> --debuglogs
```

## Deployment Options

- `-f, --force` - Force deployment / skip confirmation
- `-n, --lines <n>` - Number of log lines to display (default: 0 = all lines)
- `-f, --follow` - Follow log output in real-time (like tail -f)
- `--debuglogs` - Show debug logs (includes hidden commands and internal operations)

## Examples

### Single Deployment

```bash
# Deploy single app by name
coolify deploy name my-application

# Deploy with force (skip confirmation)
coolify deploy name my-application -f

# Deploy to specific context
coolify --context=prod deploy name my-application
```

### Batch Deployments

```bash
# Deploy multiple apps
coolify deploy batch api,worker,frontend

# Force deploy to production
coolify --context=prod deploy batch api,worker --force
```

### Monitor Deployment

```bash
# Follow deployment logs
coolify app deployments logs <app_uuid> -f

# Show last 50 lines
coolify app deployments logs <app_uuid> -n 50
```

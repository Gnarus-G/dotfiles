# Environment Variables

## Application Environment Variables

```bash
# List env vars
coolify app env list <app_uuid>

# Get specific env var
coolify app env get <app_uuid> <env_uuid_or_key>

# Create env var
coolify app env create <app_uuid> \
  --key API_KEY \
  --value secret123 \
  --build-time \
  --preview

# Update env var
coolify app env update <app_uuid> <env_uuid>

# Delete env var
coolify app env delete <app_uuid> <env_uuid>

# Sync from .env file (updates existing, creates new, keeps others)
coolify app env sync <app_uuid> --file .env
coolify app env sync <app_uuid> --file .env.production --build-time --preview
```

## Service Environment Variables

Same commands as applications:

```bash
coolify service env list <service_uuid>
coolify service env get <service_uuid> <env_uuid_or_key>
coolify service env create <service_uuid> --key KEY --value value
coolify service env update <service_uuid> <env_uuid>
coolify service env delete <service_uuid> <env_uuid>
coolify service env sync <service_uuid> --file .env
```

## Environment Variable Flags

- `--key <key>` - Variable key (required)
- `--value <value>` - Variable value (required)
- `--preview` - Available in preview deployments
- `--build-time` - Available at build time
- `--is-literal` - Treat value as literal (don't interpolate variables)
- `--is-multiline` - Value is multiline

## Best Practices

1. **Use .env file sync**: Keep env vars in version control-friendly files
2. **Use build-time flag**: For variables needed during build (API URLs, build flags)
3. **Use preview flag**: For variables needed in preview deployments
4. **Sync behavior**: Updates existing variables, creates missing ones. Does NOT delete variables not in the file.

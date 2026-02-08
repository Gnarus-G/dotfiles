# Projects and Services

## Projects

```bash
# List all projects
coolify projects list

# Get project environments
coolify projects get <uuid>
```

## Services

```bash
# List all services
coolify service list

# Get service details
coolify service get <uuid>

# Manage lifecycle
coolify service start <uuid>
coolify service stop <uuid>
coolify service restart <uuid>
coolify service delete <uuid>
```

## Service Environment Variables

```bash
coolify service env list <service_uuid>
coolify service env get <service_uuid> <env_uuid_or_key>
coolify service env create <service_uuid> --key KEY --value value
coolify service env update <service_uuid> <env_uuid>
coolify service env delete <service_uuid> <env_uuid>
coolify service env sync <service_uuid> --file .env
```

## Resources

```bash
# List all resources (apps, databases, services)
coolify resources list
```

# Databases

## List and Get

```bash
# List all databases
coolify database list

# Get database details
coolify database get <uuid>
```

## Create Database

```bash
coolify database create postgresql \
  --server-uuid <server-uuid> \
  --project-uuid <project-uuid> \
  --environment-name production \
  --name mydb \
  --instant-deploy \
  --is-public \
  --public-port 5432
```

Supported types: `postgresql`, `mysql`, `mariadb`, `mongodb`, `redis`, `keydb`, `clickhouse`, `dragonfly`

Options:
- `--server-uuid <uuid>` - Server UUID (required)
- `--project-uuid <uuid>` - Project UUID (required)
- `--environment-name <name>` - Environment name (required unless using --environment-uuid)
- `--environment-uuid <uuid>` - Environment UUID (required unless using --environment-name)
- `--destination-uuid <uuid>` - Destination UUID if server has multiple destinations
- `--name <name>` - Database name
- `--description <description>` - Database description
- `--image <image>` - Docker image
- `--instant-deploy` - Deploy immediately after creation
- `--is-public` - Make database publicly accessible
- `--public-port <port>` - Public port number
- `--limits-memory <size>` - Memory limit (e.g., '512m', '2g')
- `--limits-cpus <cpus>` - CPU limit (e.g., '0.5', '2')

## Manage Lifecycle

```bash
coolify database start <uuid>
coolify database stop <uuid>
coolify database restart <uuid>
```

## Delete Database

```bash
coolify database delete <uuid> \
  --delete-configurations \
  --delete-volumes \
  --docker-cleanup
```

Options:
- `--delete-configurations` - Delete configurations (default: true)
- `--delete-volumes` - Delete volumes (default: true)
- `--docker-cleanup` - Run docker cleanup (default: true)
- `--delete-connected-networks` - Delete connected networks (default: true)

## Backups

### List Backup Configurations

```bash
coolify database backup list <database_uuid>
```

### Create Backup Configuration

```bash
coolify database backup create <database_uuid> \
  --frequency "0 2 * * *" \
  --enabled \
  --save-s3 \
  --s3-storage-uuid <uuid> \
  --retention-days-local 7 \
  --retention-amount-s3 30
```

Options:
- `--frequency <cron>` - Backup frequency (cron expression)
- `--enabled` - Enable backup schedule
- `--save-s3` - Save backups to S3
- `--s3-storage-uuid <uuid>` - S3 storage UUID
- `--databases-to-backup <list>` - Comma-separated list of databases to backup
- `--dump-all` - Dump all databases
- `--retention-amount-local <n>` - Number of backups to retain locally
- `--retention-days-local <n>` - Days to retain backups locally
- `--retention-storage-local <size>` - Max storage for local backups (e.g., '1GB', '500MB')
- `--retention-amount-s3 <n>` - Number of backups to retain in S3
- `--retention-days-s3 <n>` - Days to retain backups in S3
- `--retention-storage-s3 <size>` - Max storage for S3 backups (e.g., '1GB', '500MB')
- `--timeout <seconds>` - Backup timeout in seconds
- `--disable-local` - Disable local backup storage

### Update Backup Configuration

```bash
coolify database backup update <database_uuid> <backup_uuid>
```

### Delete Backup Configuration

```bash
coolify database backup delete <database_uuid> <backup_uuid>
```

### Trigger Backup

```bash
coolify database backup trigger <database_uuid> <backup_uuid>
```

### List Backup Executions

```bash
coolify database backup executions <database_uuid> <backup_uuid>
```

### Delete Backup Execution

```bash
coolify database backup delete-execution <database_uuid> <backup_uuid> <execution_uuid>
```

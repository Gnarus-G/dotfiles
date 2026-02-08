# Servers

Commands use `server` or `servers` interchangeably.

## List and Get

```bash
# List all servers
coolify server list

# Get server details
coolify server get <uuid>
coolify server get <uuid> --resources  # Include resource status
```

## Add Server

```bash
coolify server add <name> <ip> <private_key_uuid>
coolify server add <name> <ip> <private_key_uuid> -p 2222 -u admin --validate
```

Options:
- `-p, --port <port>` - SSH port (default: 22)
- `-u, --user <user>` - SSH user (default: root)
- `--validate` - Validate server immediately after adding

## Validate Connection

```bash
coolify server validate <uuid>
```

## Get Server Domains

```bash
coolify server domains <uuid>
```

## Remove Server

```bash
coolify server remove <uuid>
```

## Private Keys

Commands use `private-key`, `private-keys`, `key`, or `keys` interchangeably.

```bash
# List all private keys
coolify private-key list

# Add private key (inline)
coolify private-key add <key_name> "-----BEGIN OPENSSH PRIVATE KEY-----..."

# Add private key (from file)
coolify private-key add <key_name> @~/.ssh/id_rsa

# Remove private key
coolify private-key remove <uuid>
```

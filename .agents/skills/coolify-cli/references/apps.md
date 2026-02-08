# Applications

## List and Get

```bash
# List all apps
coolify app list

# Get app details
coolify app get <uuid>
```

## Manage Lifecycle

```bash
coolify app start <uuid>
coolify app stop <uuid>
coolify app restart <uuid>
coolify app delete <uuid> -f
```

## View Logs

```bash
coolify app logs <uuid>
```

## Update Configuration

```bash
coolify app update <uuid> \
  --name "My App" \
  --git-branch main \
  --domains "app.example.com" \
  --build-command "npm run build" \
  --start-command "npm start" \
  --ports-exposes "3000"
```

## Deploy Applications

```bash
# Deploy by UUID
coolify deploy uuid <uuid> -f

# Deploy by name (easier!)
coolify deploy name <name> -f

# Deploy multiple resources
coolify deploy batch <name1,name2,name3> -f
```

## Deploying from Git Repositories

### Public Repositories

1. **Create the application in Coolify UI:**
   - Go to your Coolify dashboard
   - Click "+ New" → "Application"
   - Select "Public Repository"
   - Enter the repository URL (e.g., `https://github.com/username/repo`)
   - Select the branch and configure build settings
   - Save and deploy

2. **Manage via CLI once created:**
   ```bash
   # Get the app UUID from the list
   coolify app list
   
   # Deploy the application
   coolify deploy name my-public-app -f
   
   # Update configuration
   coolify app update <uuid> --git-branch main
   
   # View deployment logs
   coolify app deployments logs <uuid> -f
   ```

### Private Repositories

Private repositories require authentication via GitHub App or GitLab integration.

#### GitHub App Integration (Recommended)

1. **Create a GitHub App in Coolify:**
   ```bash
   # First, add your private key
   coolify private-key add github-app-key @~/.ssh/github_app_key
   
   # Create the GitHub App integration
   coolify github create \
     --name "My GitHub App" \
     --api-url "https://api.github.com" \
     --html-url "https://github.com" \
     --app-id 123456 \
     --installation-id 789012 \
     --client-id "Iv1.abc123" \
     --client-secret "your-client-secret" \
     --private-key-uuid <key-uuid>
   ```

2. **Verify the integration:**
   ```bash
   # List GitHub Apps
   coolify github list
   
   # Check accessible repositories
   coolify github repos <app_uuid>
   
   # List branches for a repo
   coolify github branches <app_uuid> owner/repo
   ```

3. **Create application in Coolify UI:**
   - Go to your Coolify dashboard
   - Click "+ New" → "Application"
   - Select "Private Repository (with GitHub App)"
   - Choose your GitHub App from the dropdown
   - Select the repository from the list
   - Configure build settings and deploy

#### GitLab Integration

1. **Configure GitLab in Coolify UI:**
   - Go to Settings → GitLab
   - Add your GitLab instance URL
   - Generate and add an access token with `read_repository` scope
   - Save the configuration

2. **Create application in Coolify UI:**
   - Select "Private Repository (with GitLab)"
   - Choose your GitLab instance
   - Select the repository and branch
   - Configure and deploy

## Auto-Deployment Setup

Configure webhooks for automatic deployment on push:

**GitHub:**
- Go to repository → Settings → Webhooks
- Add webhook: `https://coolify.yourdomain.com/webhooks/github`
- Content type: `application/json`
- Events: Push, Pull request (optional)

**GitLab:**
- Go to repository → Settings → Webhooks
- Add webhook: `https://coolify.yourdomain.com/webhooks/gitlab`
- Events: Push events, Merge request events (optional)

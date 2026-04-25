# 1Password Developer Environment Integration Guide

Complete guide for using 1Password Developer Environments with Docker.

## Table of Contents

- [Overview](#overview)
- [Why Developer Environments?](#why-developer-environments)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Architecture](#architecture)
- [Security Model](#security-model)
- [Team Collaboration](#team-collaboration)
- [CI/CD Integration](#cicd-integration)

## Overview

This project uses **1Password Developer Environments** to manage secrets for local development. Developer Environments provide a project-based approach to secret management that's purpose-built for development workflows.

### Key Features

- **Project-based organization**: All secrets in one `.env.local` file
- **No vault management**: No need to create and organize vault items
- **Simple secret rotation**: Edit one file, restart services
- **Team collaboration**: Share environment setup easily
- **CLI integration**: Native `op run` command support
- **CI/CD ready**: Service account support for automation

## Why Developer Environments?

Developer Environments are superior to traditional vault approaches for local development:

| Feature | Developer Environments | Vault Approach |
|---------|----------------------|----------------|
| Setup complexity | Low (one command) | High (create items, organize) |
| Secret updates | Edit `.env.local` | Update vault items individually |
| Team onboarding | Share setup script | Share vault structure docs |
| Local development | Purpose-built | Workaround required |
| CI/CD integration | Service accounts | Service accounts |
| Secret organization | Flat, project-based | Hierarchical vaults |

**Bottom line**: Developer Environments are designed for exactly this use case.

## Prerequisites

### Required Software

1. **1Password CLI** (version 2.0+)
   ```bash
   # Check version
   op --version

   # Install if needed
   # Linux
   curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
     sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
   ```

2. **Docker** (version 20.10+)
   ```bash
   docker --version
   ```

3. **Docker Compose** (version 2.0+)
   ```bash
   docker compose version
   ```

### Required Access

- 1Password account (personal or team)
- Authenticated 1Password CLI
- Docker daemon running

### Required Information

Gather these before setup:

- **Domain name**: Your development domain (e.g., `local.dev`)
- **Email**: For Let's Encrypt certificate notifications
- **Cloudflare API Token**: For DNS challenge ([generate here](https://dash.cloudflare.com/profile/api-tokens))
- **Kasm admin password**: Strong password (16+ characters)
- **Docker Hub credentials** (optional): For private images or rate limit avoidance

## Initial Setup

### Step 1: Authenticate with 1Password

```bash
# Sign in to 1Password
op signin

# Verify authentication
op account list
```

### Step 2: Run Setup Script

```bash
cd /home/nic/docker

# Make script executable (if needed)
chmod +x setup-developer-environment.sh

# Run setup
./setup-developer-environment.sh
```

The setup script will:

1. Verify prerequisites (1Password CLI, Docker, Docker Compose)
2. Prompt for configuration values
3. Create `.env.local` file with all secrets
4. Set secure file permissions (chmod 600)
5. Create necessary directories
6. Verify the setup

### Step 3: Verify Setup

```bash
# Check that .env.local was created
ls -la .env.local

# Verify permissions (should be -rw-------)
stat -c "%a %n" .env.local

# Test loading environment
op run --env-file=.env.local -- printenv DOMAIN_NAME
```

### Step 4: Start Services

```bash
./dev-start.sh
```

## Architecture

### File Structure

```
/home/nic/docker/
├── .env.local                      # Developer Environment secrets (NEVER commit)
├── .envrc                          # 1Password secret references (template)
├── docker-compose-secure.yml       # Secure Docker Compose configuration
├── setup-developer-environment.sh  # Initial setup script
├── dev-start.sh                    # Start services
├── dev-stop.sh                     # Stop services
├── dev-status.sh                   # Check status
├── dev-logs.sh                     # View logs
├── dev-restart.sh                  # Restart services
├── dev-secrets.sh                  # View secrets (masked)
├── dev-update-secrets.sh           # Update secrets
└── .gitignore                      # Ignore .env.local
```

### Secret Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      .env.local                              │
│  (Stored locally, secured with chmod 600)                   │
│                                                              │
│  DOMAIN_NAME=local.dev                                       │
│  ACME_EMAIL=user@example.com                                 │
│  CLOUDFLARE_API_TOKEN=abc123...                              │
│  KASM_ADMIN_PASSWORD=secret...                               │
│  ...                                                         │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ Read by
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    op run --env-file                         │
│  (1Password CLI loads and injects environment variables)    │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ Inject into
                             ▼
┌─────────────────────────────────────────────────────────────┐
│               docker compose -f docker-compose-secure.yml   │
│  (Docker Compose receives environment variables)            │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ Pass to
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Containers                         │
│  - Traefik (receives CLOUDFLARE_API_TOKEN, ACME_EMAIL)      │
│  - Kasm (receives KASM_ADMIN_PASSWORD)                       │
│  - WUD (receives registry config)                            │
└─────────────────────────────────────────────────────────────┘
```

### How It Works

1. **Storage**: Secrets stored in `.env.local` file (standard `.env` format)
2. **Access**: 1Password CLI reads `.env.local` when you run commands
3. **Injection**: `op run --env-file=.env.local --` injects variables into commands
4. **Runtime**: Docker Compose receives variables and passes to containers
5. **Security**: File permissions (600) restrict access to owner only

## Security Model

### Protection Layers

1. **File System Protection**
   - `.env.local` has 600 permissions (owner read/write only)
   - Excluded from version control via `.gitignore`
   - Local to each developer's machine

2. **1Password Integration**
   - Optional: Use 1Password secret references in `.env.local`
   - Format: `VARIABLE_NAME=op://vault/item/field`
   - Requires 1Password CLI authentication

3. **Docker Security**
   - Docker Socket Proxy restricts container API access
   - Network isolation (internal networks)
   - No privileged containers (except socket proxy)
   - Security options: `no-new-privileges:true`

4. **Runtime Security**
   - Environment variables injected at runtime
   - No secrets in container images
   - No secrets in Docker Compose files
   - Secrets not visible in `docker inspect`

### Best Practices

1. **Never commit `.env.local`**
   ```bash
   # Verify it's in .gitignore
   git check-ignore .env.local
   # Should output: .env.local
   ```

2. **Use strong passwords**
   - Minimum 16 characters
   - Mix uppercase, lowercase, numbers, symbols
   - Use 1Password password generator

3. **Rotate credentials regularly**
   ```bash
   # Update secrets
   ./dev-update-secrets.sh

   # Restart to apply
   ./dev-restart.sh
   ```

4. **Limit file access**
   ```bash
   # Verify permissions
   ls -la .env.local
   # Should show: -rw------- (600)

   # Fix if needed
   chmod 600 .env.local
   ```

5. **Backup before changes**
   ```bash
   # Automatic backup when using update script
   ./dev-update-secrets.sh

   # Manual backup
   cp .env.local .env.local.backup
   ```

## Team Collaboration

### Onboarding New Team Members

1. **Share the repository** (without `.env.local`)
   ```bash
   git clone <repository-url>
   cd docker
   ```

2. **Run setup script**
   ```bash
   ./setup-developer-environment.sh
   ```

3. **Provide configuration values** (securely)
   - Share via 1Password shared vault
   - Or use secure communication channel
   - Never share via email or chat

4. **Verify setup**
   ```bash
   ./dev-status.sh
   ```

### Sharing Configuration Templates

**Option 1: Provide a setup script** (recommended)
- Team members run `./setup-developer-environment.sh`
- Script prompts for all required values
- Each developer has their own `.env.local`

**Option 2: Share a reference file**
```bash
# Create a template (without actual secrets)
cat > .env.local.template <<EOF
DOMAIN_NAME=local.dev
ACME_EMAIL=your-email@example.com
CLOUDFLARE_API_TOKEN=get-from-cloudflare-dashboard
KASM_ADMIN_PASSWORD=create-strong-password
EOF
```

**Option 3: Use 1Password shared vault**
- Store a reference `.env.local` in shared vault
- Team members download and customize

### Environment Consistency

Ensure all team members use the same:

- **Domain name**: Same for all developers
- **Port mappings**: Defined in `docker-compose-secure.yml`
- **Directory structure**: Maintained by scripts
- **Docker Compose version**: Document required version

But allow individual differences for:

- **Cloudflare API Token**: Each developer can use their own
- **Kasm admin password**: Different for each environment
- **Docker Hub credentials**: Personal accounts

## CI/CD Integration

### Service Account Setup

For automated pipelines, create a 1Password service account:

1. **Create service account**
   - Visit: https://my.1password.com/developer-tools/infrastructure-secrets/service-accounts
   - Name: `docker-dev-env-ci`
   - Grant access to the developer environment

2. **Save token securely**
   ```bash
   # In CI/CD system, set as environment variable
   export OP_SERVICE_ACCOUNT_TOKEN="<your-token>"
   ```

3. **Use in pipeline**
   ```yaml
   # GitHub Actions example
   name: Deploy
   on: [push]
   jobs:
     deploy:
       runs-on: ubuntu-latest
       env:
         OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
       steps:
         - uses: actions/checkout@v3
         - name: Install 1Password CLI
           run: |
             curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
               sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
             # ... install op CLI
         - name: Start services
           run: op run --env-file=.env.local -- docker compose up -d
   ```

### Pipeline Examples

**GitHub Actions**:
```yaml
- name: Deploy with 1Password
  env:
    OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
  run: |
    ./dev-start.sh
```

**GitLab CI**:
```yaml
deploy:
  variables:
    OP_SERVICE_ACCOUNT_TOKEN: $CI_SERVICE_ACCOUNT_TOKEN
  script:
    - ./dev-start.sh
```

**Jenkins**:
```groovy
withCredentials([string(credentialsId: 'op-service-account', variable: 'OP_SERVICE_ACCOUNT_TOKEN')]) {
    sh './dev-start.sh'
}
```

### Best Practices for CI/CD

1. **Use dedicated service accounts**
   - Don't use personal accounts
   - Create separate accounts per environment
   - Rotate tokens regularly

2. **Limit service account permissions**
   - Read-only access if possible
   - Scope to specific environments
   - Audit access regularly

3. **Secure token storage**
   - Use CI/CD secret management
   - Never commit tokens to repository
   - Rotate after suspected exposure

4. **Monitor usage**
   - Enable 1Password activity logs
   - Alert on unexpected access
   - Review regularly

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.

## Additional Resources

- [1Password Developer Documentation](https://developer.1password.com/)
- [1Password CLI Reference](https://developer.1password.com/docs/cli/)
- [Developer Environments](https://developer.1password.com/docs/environments/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

## Support

For issues or questions:

1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review [DAILY_WORKFLOW.md](./DAILY_WORKFLOW.md)
3. Check 1Password Developer documentation
4. Review Docker Compose logs: `./dev-logs.sh`

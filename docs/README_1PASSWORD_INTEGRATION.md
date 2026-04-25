# Docker + 1Password Developer Environment

Complete Docker development environment with 1Password Developer Environment integration for secure secret management.

## What is This?

This project provides a production-ready Docker development environment with:

- **Traefik**: Reverse proxy with automatic HTTPS
- **What's Up Docker (WUD)**: Container image update monitoring
- **Kasm Workspaces**: Browser-based container streaming
- **Docker Socket Proxy**: Secure Docker API access
- **1Password Integration**: Developer Environment for secret management

## Why 1Password Developer Environments?

**Traditional vault approach** requires creating and managing individual items in vaults, which is cumbersome for local development.

**Developer Environments** provide a project-based approach that's purpose-built for development workflows:

- Single `.env.local` file with all secrets
- No vault management overhead
- Simple secret rotation
- Easy team collaboration
- Native CLI integration
- CI/CD ready with service accounts

## Quick Start

### Prerequisites

- 1Password CLI (v2.0+) - [Install guide](https://developer.1password.com/docs/cli/get-started/)
- Docker (v20.10+)
- Docker Compose (v2.0+)
- Linux operating system

### 5-Minute Setup

```bash
# 1. Clone/navigate to project
cd /home/nic/docker

# 2. Authenticate with 1Password
op signin

# 3. Run setup (will prompt for configuration)
./setup-developer-environment.sh

# 4. Start services
./dev-start.sh

# 5. Verify status
./dev-status.sh
```

Access your services:
- Traefik Dashboard: http://localhost:8080
- What's Up Docker: http://localhost:3000
- Kasm Workspaces: http://localhost:6901

## Project Structure

```
/home/nic/docker/
├── .env.local                       # Secrets (NEVER commit)
├── .envrc                           # 1Password references template
├── docker-compose-secure.yml        # Secure Docker Compose config
│
├── Setup & Management
├── setup-developer-environment.sh   # Initial setup wizard
├── dev-start.sh                     # Start all services
├── dev-stop.sh                      # Stop all services
├── dev-status.sh                    # Check service status
├── dev-logs.sh                      # View service logs
├── dev-restart.sh                   # Restart services
├── dev-secrets.sh                   # View secrets (masked)
├── dev-update-secrets.sh            # Update secrets
│
├── Documentation
├── QUICK_START_1PASSWORD.md         # 5-minute quick start
├── DEVELOPER_ENVIRONMENT_GUIDE.md   # Complete integration guide
├── DAILY_WORKFLOW.md                # Daily operations guide
├── TROUBLESHOOTING.md               # Common issues & solutions
│
└── Data Directories
    ├── letsencrypt/                 # SSL certificates
    ├── wud/                         # WUD data
    └── kasm/                        # Kasm workspaces
```

## How It Works

### Secret Flow

```
.env.local (local file, 600 permissions)
    ↓
op run --env-file=.env.local (1Password CLI loads secrets)
    ↓
docker compose (receives environment variables)
    ↓
Containers (run with secrets)
```

### Security Model

1. **File System Protection**
   - `.env.local` has 600 permissions (owner only)
   - Excluded from version control
   - Local to each developer

2. **1Password Integration**
   - Secrets loaded via 1Password CLI
   - Authenticated access required
   - Optional: Use `op://` references

3. **Docker Security**
   - Docker Socket Proxy restricts API access
   - Network isolation
   - No privileged containers
   - Security options enforced

4. **Runtime Security**
   - Secrets injected at runtime
   - Not stored in images
   - Not visible in compose files
   - No exposure via `docker inspect`

## Common Operations

### Daily Workflow

```bash
# Start your day
cd /home/nic/docker
./dev-start.sh

# Check status
./dev-status.sh

# View logs
./dev-logs.sh              # All services
./dev-logs.sh traefik      # Specific service

# End your day
./dev-stop.sh
```

### Managing Secrets

```bash
# View secrets (masked)
./dev-secrets.sh

# View actual values (careful!)
./dev-secrets.sh --reveal

# Update secrets
./dev-update-secrets.sh

# Manual edit
nano .env.local
./dev-restart.sh
```

### Service Management

```bash
# Restart all services
./dev-restart.sh

# Restart specific service
./dev-restart.sh traefik

# Update images
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml pull
./dev-restart.sh
```

## Services Overview

### Traefik (Reverse Proxy)

- **Port**: 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Features**: Automatic HTTPS, Docker discovery, load balancing
- **Access**: http://localhost:8080
- **Config**: Cloudflare DNS challenge for Let's Encrypt

### What's Up Docker (WUD)

- **Port**: 3000
- **Features**: Image update monitoring, notifications
- **Access**: http://localhost:3000
- **Config**: Monitors all containers via Docker Socket Proxy

### Kasm Workspaces

- **Port**: 6901
- **Features**: Browser-based container streaming
- **Access**: http://localhost:6901
- **Credentials**: Stored in 1Password

### Docker Socket Proxy

- **Internal**: tcp://docker-socket-proxy:2375
- **Purpose**: Restrict Docker API access
- **Security**: Read-only socket access, limited endpoints

## Configuration

### Required Secrets

Setup wizard will prompt for:

| Secret | Purpose | Example |
|--------|---------|---------|
| DOMAIN_NAME | Base domain | local.dev |
| ACME_EMAIL | Let's Encrypt notifications | user@example.com |
| CLOUDFLARE_API_TOKEN | DNS challenge | cf_token_abc123 |
| KASM_ADMIN_PASSWORD | Kasm admin access | Strong16+Password! |
| DOCKER_HUB_USERNAME | Optional: Registry auth | username |
| DOCKER_HUB_PASSWORD | Optional: Registry auth | token_or_password |

### Optional Configuration

Non-sensitive values:

| Variable | Default | Purpose |
|----------|---------|---------|
| KASM_PORT | 6901 | Kasm web port |
| WUD_API_PORT | 3000 | WUD API port |
| WUD_REGISTRY_PROVIDER | docker | Registry type |

## Team Collaboration

### Onboarding New Developers

1. **Share repository** (without `.env.local`)
2. **New developer runs setup**:
   ```bash
   ./setup-developer-environment.sh
   ```
3. **Provide configuration values** securely (via 1Password shared vault)
4. **Developer starts services**:
   ```bash
   ./dev-start.sh
   ```

### Sharing Configuration

**Option 1**: Setup script (recommended)
- Each developer runs `./setup-developer-environment.sh`
- Prompts for all required values
- Individual `.env.local` files

**Option 2**: Template file
- Create `.env.local.template` without actual secrets
- Share securely with team
- Developers copy and fill in values

**Option 3**: 1Password shared vault
- Store reference configuration in shared vault
- Team members download and customize

## CI/CD Integration

### Service Account Setup

For automated pipelines:

1. **Create service account** at: https://my.1password.com/developer-tools/infrastructure-secrets/service-accounts
2. **Name**: `docker-dev-env-ci`
3. **Grant access** to the developer environment
4. **Save token** in CI/CD secrets

### GitHub Actions Example

```yaml
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
          # Install op CLI
          curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
            sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
      - name: Start services
        run: ./dev-start.sh
```

### GitLab CI Example

```yaml
deploy:
  variables:
    OP_SERVICE_ACCOUNT_TOKEN: $CI_SERVICE_ACCOUNT_TOKEN
  script:
    - ./dev-start.sh
```

## Security Best Practices

### Essential

1. **Never commit `.env.local`**
   ```bash
   git check-ignore .env.local  # Verify it's ignored
   ```

2. **Use strong passwords**
   - Minimum 16 characters
   - Mix case, numbers, symbols
   - Use 1Password generator

3. **Verify file permissions**
   ```bash
   ls -la .env.local  # Should show -rw------- (600)
   ```

4. **Rotate secrets regularly**
   ```bash
   ./dev-update-secrets.sh
   ```

### Advanced

5. **Enable 2FA on 1Password**
6. **Use service accounts for automation**
7. **Audit access logs**
8. **Regular security reviews**
9. **Keep 1Password CLI updated**
10. **Backup `.env.local` encrypted**

## Troubleshooting

### Quick Diagnostics

```bash
# Check service status
./dev-status.sh

# View logs
./dev-logs.sh

# Verify 1Password auth
op account list

# Test environment loading
op run --env-file=.env.local -- printenv DOMAIN_NAME

# Clean and restart
./dev-stop.sh
docker system prune -f
./dev-start.sh
```

### Common Issues

**Services won't start**
- Check port conflicts: `sudo netstat -tlnp | grep -E ':(80|443|8080)'`
- Verify Docker running: `docker ps`
- Check logs: `./dev-logs.sh`

**1Password authentication failed**
- Sign in again: `op signin`
- Check account: `op account list`

**Secrets not loading**
- Verify file exists: `ls -la .env.local`
- Check permissions: `stat -c "%a" .env.local` (should be 600)
- Test loading: `op run --env-file=.env.local -- env | grep DOMAIN_NAME`

**Certificate issues**
- Check Cloudflare token: `./dev-secrets.sh --reveal | grep CLOUDFLARE`
- Verify acme.json: `ls -la letsencrypt/acme.json` (should be 600)
- Review Traefik logs: `./dev-logs.sh traefik | grep -i acme`

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for comprehensive solutions.

## Advanced Usage

### Custom Docker Commands

```bash
# Run any docker compose command
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml <command>

# Examples:
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml ps
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml logs -f
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml exec traefik sh
```

### Multiple Environments

```bash
# Manage multiple environments
cp .env.local .env.local.dev
cp .env.local .env.local.staging
cp .env.local .env.local.prod

# Switch environments
cp .env.local.staging .env.local
./dev-restart.sh
```

### Backup and Restore

```bash
# Backup secrets (encrypted)
gpg -c .env.local
# Creates .env.local.gpg

# Backup data
tar -czf backup-$(date +%Y%m%d).tar.gz \
  .env.local letsencrypt/ wud/ kasm/

# Restore secrets
gpg .env.local.gpg
chmod 600 .env.local
```

## Documentation

### Quick References

- [QUICK_START_1PASSWORD.md](./QUICK_START_1PASSWORD.md) - 5-minute setup
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Command cheat sheet

### Detailed Guides

- [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md) - Complete integration guide
- [DAILY_WORKFLOW.md](./DAILY_WORKFLOW.md) - Daily operations
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues

### Legacy Documentation

- [README.md](./README.md) - Original setup (without 1Password)
- [SECURITY_ARCHITECTURE.md](./SECURITY_ARCHITECTURE.md) - Security design
- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - Implementation details

## Advantages Over Vault Approach

| Feature | Developer Environment | Vault Approach |
|---------|----------------------|----------------|
| **Setup** | One command | Create items, organize vaults |
| **Updates** | Edit one file | Update multiple vault items |
| **Team onboarding** | Share setup script | Share vault structure docs |
| **Local dev** | Purpose-built | Workaround required |
| **Secret organization** | Flat, project-based | Hierarchical |
| **CLI integration** | Native `op run` | Complex references |
| **Rotation** | Edit & restart | Update each item |

## Support & Resources

### Project Resources

- Setup wizard: `./setup-developer-environment.sh`
- Status check: `./dev-status.sh`
- View logs: `./dev-logs.sh`

### External Resources

- [1Password Developer Docs](https://developer.1password.com/)
- [1Password CLI Reference](https://developer.1password.com/docs/cli/)
- [Developer Environments](https://developer.1password.com/docs/environments/)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

### Getting Help

1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Run diagnostics: `./dev-status.sh`
3. Review logs: `./dev-logs.sh`
4. Check 1Password: `op account list`

## License

This project configuration is provided as-is for development use.

## Acknowledgments

- [1Password](https://1password.com/) - Secret management
- [Traefik](https://traefik.io/) - Reverse proxy
- [What's Up Docker](https://getwud.com/) - Update monitoring
- [Kasm Workspaces](https://kasmweb.com/) - Container streaming
- [Tecnativa](https://github.com/Tecnativa/docker-socket-proxy) - Socket proxy

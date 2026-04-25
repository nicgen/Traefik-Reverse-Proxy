# Quick Start: 1Password Developer Environment

Get up and running in 5 minutes.

## Prerequisites

- 1Password account and CLI installed
- Docker and Docker Compose installed
- Linux system

## Step 1: Authenticate

```bash
op signin
```

## Step 2: Run Setup

```bash
cd /home/nic/docker
./setup-developer-environment.sh
```

You'll be prompted for:
- Domain name (default: local.dev)
- ACME email for Let's Encrypt
- Cloudflare API token
- Kasm admin password
- Docker Hub credentials (optional)

## Step 3: Start Services

```bash
./dev-start.sh
```

## Step 4: Access Your Services

- Traefik Dashboard: http://localhost:8080
- What's Up Docker: http://localhost:3000
- Kasm Workspaces: http://localhost:6901

## Common Commands

```bash
# Check status
./dev-status.sh

# View logs
./dev-logs.sh

# Stop services
./dev-stop.sh

# Restart services
./dev-restart.sh

# View secrets (masked)
./dev-secrets.sh

# Update secrets
./dev-update-secrets.sh
```

## File Structure

```
.env.local              # Your secrets (NEVER commit)
docker-compose-secure.yml   # Docker configuration
dev-*.sh                # Helper scripts
```

## Security Notes

- `.env.local` contains all secrets
- File has 600 permissions (owner read/write only)
- Not tracked in git
- Backed up automatically when updating

## Troubleshooting

**Services won't start?**
```bash
./dev-stop.sh
docker system prune -f
./dev-start.sh
```

**1Password auth expired?**
```bash
op signin
./dev-start.sh
```

**Port conflicts?**
```bash
sudo netstat -tlnp | grep -E ':(80|443|8080)'
```

## Next Steps

- Read [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md) for detailed info
- Check [DAILY_WORKFLOW.md](./DAILY_WORKFLOW.md) for daily operations
- See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues

## Key Advantages

- **Simple setup**: One command to get started
- **Secure by default**: File permissions and encryption
- **Easy updates**: Edit `.env.local`, restart services
- **Team friendly**: Share setup script, not secrets
- **CI/CD ready**: Service accounts for automation

## Support

For issues:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Run `./dev-status.sh` to diagnose
3. Check logs with `./dev-logs.sh`

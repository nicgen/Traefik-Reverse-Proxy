# 1Password Developer Environment - Command Cheatsheet

Quick reference for all commands.

## Setup & Initialization

```bash
# First-time setup
op signin
./setup-developer-environment.sh

# Verify setup
./verify-1password-setup.sh

# View setup guide
cat QUICK_START_1PASSWORD.md
```

## Daily Operations

### Start/Stop Services

```bash
# Start all services
./dev-start.sh

# Stop all services
./dev-stop.sh

# Restart all services
./dev-restart.sh

# Restart specific service
./dev-restart.sh traefik
./dev-restart.sh kasm
./dev-restart.sh wud
```

### Check Status

```bash
# Full status report
./dev-status.sh

# Quick container check
docker ps

# Check specific container
docker ps | grep traefik
```

### View Logs

```bash
# All services (follow mode)
./dev-logs.sh

# Specific service (follow mode)
./dev-logs.sh traefik
./dev-logs.sh kasm
./dev-logs.sh wud
./dev-logs.sh docker-socket-proxy

# Last 50 lines only
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml logs --tail=50

# Specific container without wrapper
docker logs -f traefik_reverse_proxy
```

## Secret Management

```bash
# View secrets (masked)
./dev-secrets.sh

# View secrets (revealed - use carefully!)
./dev-secrets.sh --reveal

# Update secrets
./dev-update-secrets.sh

# Manual edit
nano .env.local
./dev-restart.sh

# Check specific secret
op run --env-file=.env.local -- printenv DOMAIN_NAME
op run --env-file=.env.local -- printenv ACME_EMAIL
```

## 1Password CLI

```bash
# Sign in
op signin

# Check authentication
op account list

# Load environment and run command
op run --env-file=.env.local -- <command>

# Examples:
op run --env-file=.env.local -- printenv
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml ps
op run --env-file=.env.local -- bash
```

## Docker Operations

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop specific container
docker stop traefik_reverse_proxy

# Remove container
docker rm traefik_reverse_proxy

# Restart container
docker restart traefik_reverse_proxy
```

### Image Management

```bash
# Pull latest images
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml pull

# List images
docker images

# Remove unused images
docker image prune

# Remove all unused images
docker image prune -a
```

### Network Management

```bash
# List networks
docker network ls

# Inspect network
docker network inspect traefik_net
docker network inspect socket_proxy_net

# Remove unused networks
docker network prune
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Remove unused volumes
docker volume prune
```

### System Cleanup

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Full cleanup (WARNING: removes all unused Docker data)
docker system prune -a --volumes

# Check disk usage
docker system df
```

## Docker Compose (with 1Password)

```bash
# Start services
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml up -d

# Stop services
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml down

# Restart services
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml restart

# View logs
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml logs -f

# Check status
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml ps

# Validate configuration
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml config

# Pull images
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml pull

# Execute command in container
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml exec traefik sh
```

## Service-Specific Commands

### Traefik

```bash
# View Traefik logs
./dev-logs.sh traefik

# Check Traefik configuration
docker exec traefik_reverse_proxy cat /etc/traefik/traefik.yml

# Access dashboard
curl http://localhost:8080

# Check certificate status
ls -la letsencrypt/acme.json

# Restart Traefik
./dev-restart.sh traefik
```

### Kasm Workspaces

```bash
# View Kasm logs
./dev-logs.sh kasm

# Get admin password
./dev-secrets.sh | grep KASM_ADMIN_PASSWORD

# Access Kasm
curl http://localhost:6901

# Restart Kasm
./dev-restart.sh kasm
```

### What's Up Docker (WUD)

```bash
# View WUD logs
./dev-logs.sh wud

# Access WUD API
curl http://localhost:3000/api/containers

# Check for updates
curl http://localhost:3000/api/containers | jq

# Restart WUD
./dev-restart.sh wud
```

### Docker Socket Proxy

```bash
# View proxy logs
docker logs docker-socket-proxy

# Check proxy status
docker ps | grep docker-socket-proxy

# Test connection
docker exec traefik_reverse_proxy wget -q -O- http://docker-socket-proxy:2375/_ping
```

## Troubleshooting

### Diagnose Issues

```bash
# Run verification
./verify-1password-setup.sh

# Check status
./dev-status.sh

# View all logs
./dev-logs.sh

# Check 1Password auth
op account list

# Test environment loading
op run --env-file=.env.local -- printenv DOMAIN_NAME
```

### Common Fixes

```bash
# Fix file permissions
chmod 600 .env.local

# Restart services
./dev-stop.sh
./dev-start.sh

# Clean and restart
./dev-stop.sh
docker system prune -f
./dev-start.sh

# Re-authenticate 1Password
op signin

# Recreate .env.local
mv .env.local .env.local.old
./setup-developer-environment.sh
```

### Port Conflicts

```bash
# Check what's using ports
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
sudo netstat -tlnp | grep :8080
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :6901

# Stop conflicting service
sudo systemctl stop apache2
sudo systemctl stop nginx
```

### Certificate Issues

```bash
# Check certificate file
ls -la letsencrypt/acme.json

# Fix permissions
chmod 600 letsencrypt/acme.json

# Delete and regenerate
./dev-stop.sh
rm letsencrypt/acme.json
touch letsencrypt/acme.json
chmod 600 letsencrypt/acme.json
./dev-start.sh

# Check Traefik logs for ACME errors
./dev-logs.sh traefik | grep -i acme
```

## File Operations

### Backup

```bash
# Backup .env.local (encrypted)
gpg -c .env.local

# Backup all data
tar -czf backup-$(date +%Y%m%d).tar.gz .env.local letsencrypt/ wud/ kasm/

# Backup specific directory
tar -czf letsencrypt-backup-$(date +%Y%m%d).tar.gz letsencrypt/
tar -czf kasm-backup-$(date +%Y%m%d).tar.gz kasm/
tar -czf wud-backup-$(date +%Y%m%d).tar.gz wud/
```

### Restore

```bash
# Restore .env.local from encrypted backup
gpg .env.local.gpg
chmod 600 .env.local

# Restore from tar.gz
tar -xzf backup-20250123.tar.gz

# Restore specific directory
tar -xzf letsencrypt-backup-20250123.tar.gz
```

### File Inspection

```bash
# Check .env.local permissions
ls -la .env.local
stat -c "%a %n" .env.local

# Check .gitignore
cat .gitignore | grep env

# Check if file is tracked by git
git check-ignore .env.local
git ls-files --error-unmatch .env.local
```

## Git Operations

```bash
# Verify .env.local not tracked
git status | grep -q ".env.local" && echo "WARNING!" || echo "OK"

# Check what will be committed
git diff --staged

# Add .env.local to .gitignore
echo ".env.local" >> .gitignore

# Remove from git (if accidentally added)
git rm --cached .env.local

# Commit changes
git add .
git commit -m "Update configuration"
```

## Monitoring

```bash
# Container resource usage
docker stats

# Continuous monitoring
docker stats --no-stream

# Specific container stats
docker stats traefik_reverse_proxy

# Disk usage
df -h .
docker system df

# Check logs size
du -sh /var/lib/docker/containers/*
```

## Performance

```bash
# Check container resource limits
docker inspect traefik_reverse_proxy | jq '.[].HostConfig.Memory'

# View container processes
docker top traefik_reverse_proxy

# Network performance
docker network inspect traefik_net | jq '.[].Options'
```

## Access URLs

```bash
# Local access
echo "Traefik: http://localhost:8080"
echo "WUD:     http://localhost:3000"
echo "Kasm:    http://localhost:6901"

# Domain access (when DNS configured)
DOMAIN=$(op run --env-file=.env.local -- printenv DOMAIN_NAME)
echo "WUD:  https://wud.$DOMAIN"
echo "Kasm: https://kasm.$DOMAIN"
```

## Environment Switching

```bash
# Save current environment
cp .env.local .env.local.$(date +%Y%m%d)

# Switch to development
cp .env.local.dev .env.local
./dev-restart.sh

# Switch to staging
cp .env.local.staging .env.local
./dev-restart.sh

# Switch to production
cp .env.local.prod .env.local
./dev-restart.sh
```

## Advanced Operations

### Execute in Container

```bash
# Shell access
docker exec -it traefik_reverse_proxy sh
docker exec -it kasm bash

# Run command
docker exec traefik_reverse_proxy ls -la /letsencrypt
docker exec wud printenv

# With 1Password context
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml exec traefik sh
```

### Network Diagnostics

```bash
# Test connectivity between containers
docker exec traefik_reverse_proxy ping -c 3 docker-socket-proxy
docker exec wud ping -c 3 docker-socket-proxy

# Check DNS resolution
docker exec traefik_reverse_proxy nslookup docker-socket-proxy

# Test API endpoint
docker exec traefik_reverse_proxy wget -q -O- http://docker-socket-proxy:2375/_ping
```

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Navigation
alias ddev='cd /home/nic/docker'

# Operations
alias dstart='cd /home/nic/docker && ./dev-start.sh'
alias dstop='cd /home/nic/docker && ./dev-stop.sh'
alias dstatus='cd /home/nic/docker && ./dev-status.sh'
alias dlogs='cd /home/nic/docker && ./dev-logs.sh'
alias drestart='cd /home/nic/docker && ./dev-restart.sh'
alias dsecrets='cd /home/nic/docker && ./dev-secrets.sh'

# 1Password
alias op-env='op run --env-file=/home/nic/docker/.env.local --'

# Docker Compose
alias dcomp='cd /home/nic/docker && op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml'
```

## Quick Help

```bash
# View documentation
cat QUICK_START_1PASSWORD.md
cat DEVELOPER_ENVIRONMENT_GUIDE.md
cat DAILY_WORKFLOW.md
cat TROUBLESHOOTING.md

# List all available scripts
ls -1 *.sh

# Get script help
./dev-start.sh --help
./setup-developer-environment.sh --help
```

## Emergency Recovery

```bash
# Complete reset (WARNING: loses data)
./dev-stop.sh
docker system prune -a --volumes
rm -rf letsencrypt/* wud/data/* kasm/data/*
./setup-developer-environment.sh
./dev-start.sh

# Restore from backup
./dev-stop.sh
tar -xzf backup-20250123.tar.gz
chmod 600 .env.local
./dev-start.sh
```

## Resources

- Quick Start: `QUICK_START_1PASSWORD.md`
- Full Guide: `DEVELOPER_ENVIRONMENT_GUIDE.md`
- Daily Workflow: `DAILY_WORKFLOW.md`
- Troubleshooting: `TROUBLESHOOTING.md`
- This Cheatsheet: `COMMAND_CHEATSHEET.md`

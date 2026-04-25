# Daily Development Workflow

Quick reference guide for daily operations with 1Password Developer Environment integration.

## Quick Start

### Starting Your Day

```bash
# Navigate to project
cd /home/nic/docker

# Authenticate with 1Password (if session expired)
op signin

# Start all services
./dev-start.sh

# Verify everything is running
./dev-status.sh
```

Access your services:
- Traefik Dashboard: http://localhost:8080
- What's Up Docker: http://localhost:3000
- Kasm Workspaces: http://localhost:6901

### Ending Your Day

```bash
# Stop all services
./dev-stop.sh

# Optional: Sign out of 1Password
# (Not necessary if you trust your machine security)
```

## Common Tasks

### Check Service Status

```bash
# Full status report
./dev-status.sh

# Quick check of running containers
docker ps

# Check specific service health
docker inspect --format='{{.State.Health.Status}}' traefik_reverse_proxy
```

### View Logs

```bash
# All services
./dev-logs.sh

# Specific service
./dev-logs.sh traefik
./dev-logs.sh kasm
./dev-logs.sh wud

# Last 50 lines only
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml logs --tail=50

# Follow logs for specific container
docker logs -f traefik_reverse_proxy
```

### Restart Services

```bash
# Restart all services
./dev-restart.sh

# Restart specific service
./dev-restart.sh traefik

# Force recreation of containers
./dev-stop.sh
./dev-start.sh
```

### View Secrets

```bash
# View masked secrets
./dev-secrets.sh

# View actual values (use carefully!)
./dev-secrets.sh --reveal

# Check specific value
op run --env-file=.env.local -- printenv DOMAIN_NAME
op run --env-file=.env.local -- printenv ACME_EMAIL
```

### Update Secrets

```bash
# Interactive update wizard
./dev-update-secrets.sh

# Manual edit
nano .env.local

# After editing, restart services
./dev-restart.sh

# Verify new secrets loaded
./dev-secrets.sh
```

### Update Docker Images

```bash
# Pull latest images
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml pull

# Recreate containers with new images
./dev-restart.sh

# Or stop, pull, start
./dev-stop.sh
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml pull
./dev-start.sh
```

## Working with Individual Services

### Traefik

```bash
# Check Traefik logs
./dev-logs.sh traefik

# View Traefik configuration
docker exec traefik_reverse_proxy cat /etc/traefik/traefik.yml

# Check certificate status
./check-certificates.sh

# View Traefik dashboard
open http://localhost:8080
```

### Kasm Workspaces

```bash
# Check Kasm logs
./dev-logs.sh kasm

# Get admin password (masked)
./dev-secrets.sh | grep KASM_ADMIN_PASSWORD

# Access Kasm interface
open http://localhost:6901

# Restart Kasm (if issues)
./dev-restart.sh kasm
```

### What's Up Docker (WUD)

```bash
# Check WUD logs
./dev-logs.sh wud

# Access WUD interface
open http://localhost:3000

# Check for image updates
curl -s http://localhost:3000/api/containers | jq
```

### Docker Socket Proxy

```bash
# Check proxy status
docker logs docker-socket-proxy

# Verify it's running
docker ps | grep docker-socket-proxy

# Test connection (from another container)
docker exec traefik_reverse_proxy wget -q -O- http://docker-socket-proxy:2375/_ping
```

## Troubleshooting Workflows

### Services Won't Start

```bash
# Check what's already running
docker ps -a

# Check port conflicts
sudo netstat -tlnp | grep -E ':(80|443|8080|3000|6901)'

# Stop everything and clean up
./dev-stop.sh
docker system prune -f

# Try starting again
./dev-start.sh
```

### Can't Connect to Services

```bash
# Verify containers are running
./dev-status.sh

# Check network connectivity
docker network ls
docker network inspect traefik_net

# Check firewall rules
sudo ufw status

# Check service-specific logs
./dev-logs.sh <service-name>
```

### 1Password Authentication Issues

```bash
# Check authentication status
op account list

# Sign in again
op signin

# Verify you can access secrets
op run --env-file=.env.local -- printenv DOMAIN_NAME

# Check .env.local exists and has correct permissions
ls -la .env.local

# Should show: -rw------- (600)
```

### Secrets Not Loading

```bash
# Verify .env.local exists
test -f .env.local && echo "File exists" || echo "File missing"

# Check file permissions
stat -c "%a %n" .env.local

# Test loading manually
set -a
source .env.local
set +a
echo $DOMAIN_NAME

# Verify with op run
op run --env-file=.env.local -- env | grep -E '^(DOMAIN_NAME|ACME_EMAIL)'
```

### Certificates Not Working

```bash
# Check certificate status
./check-certificates.sh

# View Traefik logs for ACME errors
./dev-logs.sh traefik | grep -i acme

# Check Cloudflare token is valid
./dev-secrets.sh --reveal | grep CLOUDFLARE_API_TOKEN

# Verify DNS configuration
dig +short _acme-challenge.local.dev TXT

# Check acme.json permissions
ls -la letsencrypt/acme.json

# Should be 600, if not:
chmod 600 letsencrypt/acme.json
./dev-restart.sh traefik
```

## Advanced Operations

### Execute Commands in Containers

```bash
# Shell access
docker exec -it traefik_reverse_proxy sh
docker exec -it kasm bash

# Run one-off command
docker exec traefik_reverse_proxy ls -la /letsencrypt

# Run with environment from 1Password
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml exec traefik sh
```

### Backup Data

```bash
# Backup letsencrypt certificates
tar -czf letsencrypt-backup-$(date +%Y%m%d).tar.gz letsencrypt/

# Backup Kasm data
tar -czf kasm-backup-$(date +%Y%m%d).tar.gz kasm/data/

# Backup WUD data
tar -czf wud-backup-$(date +%Y%m%d).tar.gz wud/data/

# Backup .env.local (encrypted)
gpg -c .env.local
# Creates .env.local.gpg
```

### Restore from Backup

```bash
# Stop services first
./dev-stop.sh

# Restore letsencrypt
tar -xzf letsencrypt-backup-20250123.tar.gz

# Restore Kasm data
tar -xzf kasm-backup-20250123.tar.gz

# Restore .env.local (from encrypted backup)
gpg .env.local.gpg
# Decrypts to .env.local

# Set correct permissions
chmod 600 .env.local

# Start services
./dev-start.sh
```

### Clean Up

```bash
# Stop and remove all containers
./dev-stop.sh

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Full cleanup (WARNING: removes all Docker data)
docker system prune -a --volumes
```

### Monitor Resource Usage

```bash
# Container resource usage
docker stats

# Disk usage by container
docker ps -q | xargs docker inspect --format='{{.Name}} {{.HostConfig.LogConfig.Config}}' | \
  xargs -I {} sh -c 'du -sh /var/lib/docker/containers/$(docker ps -q --filter name={})* 2>/dev/null'

# Check available disk space
df -h .

# Check Docker disk usage
docker system df
```

## Working with Multiple Environments

### Switch Environments

```bash
# Production environment
cp .env.local.prod .env.local
./dev-restart.sh

# Development environment
cp .env.local.dev .env.local
./dev-restart.sh

# Staging environment
cp .env.local.staging .env.local
./dev-restart.sh
```

### Compare Environments

```bash
# Compare production and development
diff .env.local.prod .env.local.dev

# Compare current with backup
diff .env.local .env.local.backup.*
```

## Git Operations

### Before Committing Code

```bash
# Verify .env.local is not staged
git status | grep -q ".env.local" && echo "WARNING: .env.local is staged!" || echo "OK"

# Verify .env.local is in .gitignore
git check-ignore .env.local

# Check what will be committed
git diff --staged

# Commit (without secrets)
git commit -m "Update Docker configuration"
```

### After Pulling Changes

```bash
# Pull latest changes
git pull

# Check if docker-compose-secure.yml changed
git diff HEAD@{1} docker-compose-secure.yml

# If Docker config changed, restart services
./dev-restart.sh

# If dependencies changed, rebuild
./dev-stop.sh
./dev-start.sh
```

## Performance Tips

### Speed Up Container Startup

```bash
# Pull images in advance
op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml pull

# Use BuildKit for faster builds (if building custom images)
export DOCKER_BUILDKIT=1
```

### Reduce Log Size

```bash
# Configure log rotation in docker-compose-secure.yml
# (Add to each service)
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

# Clean up old logs
docker logs --tail 0 traefik_reverse_proxy
```

### Optimize Network Performance

```bash
# Check MTU settings
docker network inspect traefik_net | jq '.[].Options'

# Adjust MTU if needed (in docker-compose-secure.yml)
networks:
  traefik_net:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1500
```

## Health Checks

### Quick Health Check

```bash
#!/bin/bash
# Create a quick health check script

SERVICES=("traefik_reverse_proxy" "wud" "kasm" "docker-socket-proxy")
ALL_HEALTHY=true

for service in "${SERVICES[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Status}}' "$service" 2>/dev/null || echo "missing")
    if [ "$STATUS" != "running" ]; then
        echo "UNHEALTHY: $service is $STATUS"
        ALL_HEALTHY=false
    fi
done

if [ "$ALL_HEALTHY" = true ]; then
    echo "All services healthy"
    exit 0
else
    echo "Some services are unhealthy"
    exit 1
fi
```

### Automated Monitoring

```bash
# Add to cron for automated checks
# crontab -e
*/5 * * * * cd /home/nic/docker && ./dev-status.sh >> /var/log/docker-dev-status.log 2>&1
```

## Keyboard Shortcuts & Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Docker development aliases
alias ddev='cd /home/nic/docker'
alias dstart='cd /home/nic/docker && ./dev-start.sh'
alias dstop='cd /home/nic/docker && ./dev-stop.sh'
alias dstatus='cd /home/nic/docker && ./dev-status.sh'
alias dlogs='cd /home/nic/docker && ./dev-logs.sh'
alias drestart='cd /home/nic/docker && ./dev-restart.sh'
alias dsecrets='cd /home/nic/docker && ./dev-secrets.sh'

# 1Password shortcuts
alias op-env='op run --env-file=/home/nic/docker/.env.local --'

# Docker compose with 1Password
alias dcomp='cd /home/nic/docker && op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml'
```

Usage after reload:
```bash
source ~/.bashrc

ddev        # Go to docker directory
dstart      # Start services
dstatus     # Check status
dlogs       # View logs
```

## Next Steps

- Review [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Check [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md) for detailed documentation
- Read [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for command cheat sheet

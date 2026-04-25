# Troubleshooting Guide

Solutions for common issues with 1Password Developer Environment integration.

## Table of Contents

- [1Password Issues](#1password-issues)
- [Docker Issues](#docker-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Network Issues](#network-issues)
- [Certificate Issues](#certificate-issues)
- [Performance Issues](#performance-issues)
- [Security Issues](#security-issues)

## 1Password Issues

### Cannot Sign In to 1Password

**Symptoms:**
- `op signin` fails
- "Authentication required" errors

**Solutions:**

1. **Check 1Password CLI installation:**
   ```bash
   op --version
   # Should show version 2.0 or higher
   ```

2. **Install or update 1Password CLI:**
   ```bash
   # Linux
   curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
     sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
   ```

3. **Sign in manually:**
   ```bash
   op signin
   # Follow prompts
   ```

4. **Check account status:**
   ```bash
   op account list
   ```

5. **Verify network connectivity:**
   ```bash
   ping my.1password.com
   ```

### .env.local Not Found

**Symptoms:**
- "Error: .env.local not found"
- Services won't start

**Solutions:**

1. **Run initial setup:**
   ```bash
   ./setup-developer-environment.sh
   ```

2. **Verify file exists:**
   ```bash
   ls -la .env.local
   ```

3. **Check file permissions:**
   ```bash
   stat -c "%a %n" .env.local
   # Should show: 600 .env.local
   ```

4. **Restore from backup:**
   ```bash
   # List backups
   ls -la .env.local.backup.*

   # Restore most recent
   cp .env.local.backup.* .env.local
   chmod 600 .env.local
   ```

### Environment Variables Not Loading

**Symptoms:**
- Containers show empty or default values
- Services fail to start with configuration errors

**Solutions:**

1. **Test loading environment:**
   ```bash
   op run --env-file=.env.local -- printenv DOMAIN_NAME
   ```

2. **Check for syntax errors in .env.local:**
   ```bash
   # Each line should be: KEY=value
   # No spaces around =
   cat .env.local
   ```

3. **Verify no special characters breaking parsing:**
   ```bash
   # Bad: KEY=value with spaces
   # Good: KEY="value with spaces"
   ```

4. **Check file encoding:**
   ```bash
   file .env.local
   # Should be: ASCII text or UTF-8 text
   ```

5. **Recreate .env.local:**
   ```bash
   mv .env.local .env.local.old
   ./setup-developer-environment.sh
   ```

### Session Expired

**Symptoms:**
- "You are not currently signed in" errors
- Commands fail with authentication errors

**Solutions:**

1. **Sign in again:**
   ```bash
   op signin
   ```

2. **Set session token (if provided):**
   ```bash
   eval $(op signin)
   ```

3. **Use service account for automation:**
   ```bash
   export OP_SERVICE_ACCOUNT_TOKEN="<your-token>"
   ```

## Docker Issues

### Port Already in Use

**Symptoms:**
- "bind: address already in use"
- Services fail to start

**Solutions:**

1. **Check what's using the port:**
   ```bash
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   sudo netstat -tlnp | grep :8080
   ```

2. **Stop conflicting service:**
   ```bash
   # If Apache is running
   sudo systemctl stop apache2

   # If Nginx is running
   sudo systemctl stop nginx

   # If another Docker container
   docker stop <container-name>
   ```

3. **Change port in docker-compose-secure.yml:**
   ```yaml
   ports:
     - "8080:80"  # Map to different host port
   ```

### Docker Daemon Not Running

**Symptoms:**
- "Cannot connect to the Docker daemon"
- `docker ps` fails

**Solutions:**

1. **Start Docker service:**
   ```bash
   sudo systemctl start docker
   ```

2. **Enable Docker to start on boot:**
   ```bash
   sudo systemctl enable docker
   ```

3. **Check Docker status:**
   ```bash
   sudo systemctl status docker
   ```

4. **Verify user permissions:**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER

   # Logout and login again for changes to take effect
   ```

### Containers Keep Restarting

**Symptoms:**
- Container status shows "Restarting"
- Services unavailable

**Solutions:**

1. **Check logs for errors:**
   ```bash
   ./dev-logs.sh <service-name>
   ```

2. **Check container resource limits:**
   ```bash
   docker stats
   ```

3. **Increase memory limit (if needed):**
   ```yaml
   # In docker-compose-secure.yml
   services:
     service-name:
       deploy:
         resources:
           limits:
             memory: 512M
   ```

4. **Check for configuration errors:**
   ```bash
   # Validate compose file
   op run --env-file=.env.local -- docker compose -f docker-compose-secure.yml config
   ```

5. **Remove and recreate:**
   ```bash
   ./dev-stop.sh
   docker system prune -f
   ./dev-start.sh
   ```

### Out of Disk Space

**Symptoms:**
- "no space left on device"
- Services fail to start or write data

**Solutions:**

1. **Check disk usage:**
   ```bash
   df -h
   docker system df
   ```

2. **Clean up Docker resources:**
   ```bash
   # Remove unused containers
   docker container prune

   # Remove unused images
   docker image prune -a

   # Remove unused volumes
   docker volume prune

   # Full cleanup (WARNING: removes all unused Docker data)
   docker system prune -a --volumes
   ```

3. **Clean up log files:**
   ```bash
   # Truncate log files
   truncate -s 0 /var/lib/docker/containers/*/*-json.log
   ```

4. **Configure log rotation:**
   ```yaml
   # Add to each service in docker-compose-secure.yml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

## Service-Specific Issues

### Traefik Not Starting

**Symptoms:**
- Traefik container exits immediately
- "Error initializing: provider" errors

**Solutions:**

1. **Check Cloudflare token:**
   ```bash
   ./dev-secrets.sh --reveal | grep CLOUDFLARE_API_TOKEN
   ```

2. **Verify token permissions:**
   - Visit: https://dash.cloudflare.com/profile/api-tokens
   - Check token has `Zone.DNS.Edit` permission
   - Verify token is active

3. **Check ACME email:**
   ```bash
   op run --env-file=.env.local -- printenv ACME_EMAIL
   ```

4. **Check acme.json permissions:**
   ```bash
   ls -la letsencrypt/acme.json
   # Should be 600

   # Fix if needed
   chmod 600 letsencrypt/acme.json
   ```

5. **Check Docker Socket Proxy:**
   ```bash
   docker logs docker-socket-proxy
   docker exec traefik_reverse_proxy wget -q -O- http://docker-socket-proxy:2375/_ping
   ```

### Kasm Won't Start

**Symptoms:**
- Kasm container exits
- "Authentication failed" errors

**Solutions:**

1. **Check admin password:**
   ```bash
   ./dev-secrets.sh | grep KASM_ADMIN_PASSWORD
   ```

2. **Verify data directory:**
   ```bash
   ls -la kasm/data/
   # Should be owned by current user
   ```

3. **Check Docker Hub credentials (if used):**
   ```bash
   ./dev-secrets.sh --reveal | grep DOCKER_HUB
   ```

4. **Reset Kasm data:**
   ```bash
   ./dev-stop.sh
   rm -rf kasm/data/*
   ./dev-start.sh
   ```

### WUD Not Detecting Containers

**Symptoms:**
- WUD dashboard shows no containers
- "No containers found" message

**Solutions:**

1. **Check Docker Socket Proxy connection:**
   ```bash
   docker logs wud | grep -i docker
   ```

2. **Verify Docker Socket Proxy is running:**
   ```bash
   docker ps | grep docker-socket-proxy
   ```

3. **Check WUD configuration:**
   ```bash
   cat wud/config/config.yml
   ```

4. **Restart WUD:**
   ```bash
   ./dev-restart.sh wud
   ```

### Docker Socket Proxy Issues

**Symptoms:**
- Services can't connect to Docker
- "Connection refused" errors

**Solutions:**

1. **Check proxy logs:**
   ```bash
   docker logs docker-socket-proxy
   ```

2. **Verify it's running:**
   ```bash
   docker ps | grep docker-socket-proxy
   ```

3. **Test connectivity:**
   ```bash
   docker exec traefik_reverse_proxy wget -q -O- http://docker-socket-proxy:2375/_ping
   # Should return "OK"
   ```

4. **Restart proxy:**
   ```bash
   docker restart docker-socket-proxy
   ```

## Network Issues

### Containers Can't Communicate

**Symptoms:**
- Services can't reach each other
- DNS resolution failures

**Solutions:**

1. **Check networks exist:**
   ```bash
   docker network ls | grep -E '(traefik_net|socket_proxy_net)'
   ```

2. **Inspect network:**
   ```bash
   docker network inspect traefik_net
   ```

3. **Recreate networks:**
   ```bash
   ./dev-stop.sh
   docker network rm traefik_net socket_proxy_net
   ./dev-start.sh
   ```

4. **Test DNS resolution:**
   ```bash
   docker exec traefik_reverse_proxy ping -c 1 docker-socket-proxy
   ```

### Can't Access Services from Host

**Symptoms:**
- localhost:8080 not accessible
- "Connection refused" errors

**Solutions:**

1. **Verify containers are running:**
   ```bash
   ./dev-status.sh
   ```

2. **Check port bindings:**
   ```bash
   docker port traefik_reverse_proxy
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080/tcp
   sudo ufw allow 3000/tcp
   sudo ufw allow 6901/tcp
   ```

4. **Try 127.0.0.1 instead of localhost:**
   ```bash
   curl http://127.0.0.1:8080
   ```

## Certificate Issues

### Let's Encrypt Challenges Failing

**Symptoms:**
- "Error obtaining certificate" in Traefik logs
- HTTPS not working

**Solutions:**

1. **Check Cloudflare token:**
   ```bash
   ./dev-secrets.sh --reveal | grep CLOUDFLARE_API_TOKEN
   # Test token at Cloudflare dashboard
   ```

2. **Verify DNS records:**
   ```bash
   dig +short _acme-challenge.local.dev TXT
   ```

3. **Check ACME email:**
   ```bash
   op run --env-file=.env.local -- printenv ACME_EMAIL
   ```

4. **Delete and regenerate certificates:**
   ```bash
   ./dev-stop.sh
   rm letsencrypt/acme.json
   touch letsencrypt/acme.json
   chmod 600 letsencrypt/acme.json
   ./dev-start.sh
   ```

5. **Check rate limits:**
   - Let's Encrypt has rate limits
   - Wait 1 hour before retrying
   - Use staging server for testing:
     ```yaml
     # In docker-compose-secure.yml
     - "--certificatesresolvers.cloudflare.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
     ```

### Certificate Permissions Error

**Symptoms:**
- "Permission denied" for acme.json
- Traefik exits with error code

**Solutions:**

1. **Fix permissions:**
   ```bash
   chmod 600 letsencrypt/acme.json
   chown $USER:$USER letsencrypt/acme.json
   ```

2. **Restart Traefik:**
   ```bash
   ./dev-restart.sh traefik
   ```

## Performance Issues

### Containers Running Slowly

**Symptoms:**
- High CPU or memory usage
- Slow response times

**Solutions:**

1. **Check resource usage:**
   ```bash
   docker stats
   ```

2. **Check host resources:**
   ```bash
   htop
   free -h
   df -h
   ```

3. **Limit container resources:**
   ```yaml
   # In docker-compose-secure.yml
   services:
     service-name:
       deploy:
         resources:
           limits:
             cpus: '0.5'
             memory: 512M
   ```

4. **Clean up Docker:**
   ```bash
   docker system prune -a
   ```

5. **Restart Docker daemon:**
   ```bash
   sudo systemctl restart docker
   ./dev-start.sh
   ```

### High Disk I/O

**Symptoms:**
- Slow container startup
- High disk wait times

**Solutions:**

1. **Check disk usage:**
   ```bash
   iotop
   ```

2. **Reduce logging:**
   ```yaml
   # In docker-compose-secure.yml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

3. **Use volumes for persistent data:**
   - Volumes are more efficient than bind mounts
   - Consider migrating from ./data to named volumes

## Security Issues

### .env.local Exposed in Git

**Symptoms:**
- .env.local appears in `git status`
- Secrets at risk of being committed

**Solutions:**

1. **Immediately remove from staging:**
   ```bash
   git reset HEAD .env.local
   ```

2. **Add to .gitignore:**
   ```bash
   echo ".env.local" >> .gitignore
   git add .gitignore
   git commit -m "Add .env.local to gitignore"
   ```

3. **If already committed:**
   ```bash
   # Remove from history (CAREFUL!)
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch .env.local' \
     --prune-empty --tag-name-filter cat -- --all

   # Force push (coordinate with team first!)
   git push origin --force --all
   ```

4. **Rotate all secrets immediately:**
   ```bash
   ./dev-update-secrets.sh
   ```

### Incorrect File Permissions

**Symptoms:**
- Other users can read .env.local
- Security warnings

**Solutions:**

1. **Fix permissions:**
   ```bash
   chmod 600 .env.local
   ```

2. **Verify:**
   ```bash
   ls -la .env.local
   # Should show: -rw------- (600)
   ```

3. **Check ownership:**
   ```bash
   stat -c "%U %G" .env.local
   # Should show your username

   # Fix if needed
   chown $USER:$USER .env.local
   ```

## Getting Help

### Collect Diagnostic Information

```bash
#!/bin/bash
# Save as diagnose.sh

echo "=== System Information ==="
uname -a
echo ""

echo "=== Docker Version ==="
docker --version
docker compose version
echo ""

echo "=== 1Password CLI ==="
op --version
op account list
echo ""

echo "=== Container Status ==="
docker ps -a
echo ""

echo "=== Network Status ==="
docker network ls
echo ""

echo "=== Disk Usage ==="
df -h .
docker system df
echo ""

echo "=== Recent Logs ==="
docker compose -f docker-compose-secure.yml logs --tail=50
```

Run and save output:
```bash
chmod +x diagnose.sh
./diagnose.sh > diagnostic-report.txt 2>&1
```

### Enable Debug Logging

```bash
# Traefik debug logging
# Add to docker-compose-secure.yml:
command:
  - "--log.level=DEBUG"

# Restart to apply
./dev-restart.sh traefik
```

### Contact Support

When reporting issues, include:

1. **Environment details:**
   - OS version: `uname -a`
   - Docker version: `docker --version`
   - 1Password CLI version: `op --version`

2. **Error messages:**
   - Container logs: `./dev-logs.sh`
   - System logs: `journalctl -u docker`

3. **Configuration:**
   - Compose file structure (without secrets)
   - Network configuration

4. **Steps to reproduce:**
   - What you did
   - What you expected
   - What actually happened

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

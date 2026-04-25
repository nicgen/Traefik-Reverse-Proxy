# Traefik Configuration Notes

## Current Configuration: Command-Line Arguments with DNS-01 Challenge

This setup uses **Traefik v2.11** configured via command-line arguments with **DNS-01 challenge** for Let's Encrypt SSL/TLS certificate generation via Cloudflare.

### Configuration Method

Instead of using separate configuration files (`traefik.yml`, `dynamic.yml`), this setup uses command-line arguments in `docker-compose.yml`:

```yaml
command:
  - "--api.insecure=true"  # Dashboard enabled (local dev only)
  - "--providers.docker=true"  # Auto-discover containers
  - "--providers.docker.exposedbydefault=false"
  - "--entrypoints.web.address=:80"  # HTTP
  - "--entrypoints.websecure.address=:443"  # HTTPS
  - "--certificatesresolvers.cloudflare.acme.dnschallenge=true"
  - "--certificatesresolvers.cloudflare.acme.dnschallenge.provider=cloudflare"
  - "--certificatesresolvers.cloudflare.acme.email=${ACME_EMAIL}"
  - "--certificatesresolvers.cloudflare.acme.storage=/letsencrypt/acme.json"
```

### DNS-01 Challenge (Cloudflare)

The DNS-01 challenge verifies domain ownership by creating DNS TXT records via Cloudflare API.

**Advantages:**
- Works with wildcard certificates (`*.domain.com`)
- No need for port 80/443 to be publicly accessible during challenge
- Can validate internal/private domains

**Requirements:**
1. Cloudflare account with your domain
2. DNS API token with `Zone.DNS.Edit` permission
3. Set `CLOUDFLARE_API_TOKEN` in `.env`

**Setup:**
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Create token with permissions: `Zone.DNS.Edit`
3. Add to `.env`: `CLOUDFLARE_API_TOKEN=your-token`

### Certificate Storage

- Location: `./letsencrypt/acme.json`
- Persisted in Docker volume: `./letsencrypt:/letsencrypt`
- Auto-renewed 30 days before expiration
- Readable only by Traefik: `chmod 600 letsencrypt/acme.json`

### Network Configuration

All services communicate via `traefik_net` bridge network:

```yaml
networks:
  traefik_net:
    name: traefik_net
    driver: bridge
```

Services access each other by container name (e.g., `traefik`, `wud`, `kasm`).

### Service Discovery

Docker provider automatically discovers containers with Traefik labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.wud.rule=Host(`wud.${DOMAIN_NAME}`)"
  - "traefik.http.services.wud.loadbalancer.server.port=3000"
```

### Dashboard Access

**URL:** `http://localhost:8080`

**Note:** Dashboard is insecure (`api.insecure=true`) for local development. For production, use authentication or disable public access.

### Traefik Config Files (Legacy)

Files in `traefik/config/` are **NOT USED** in this setup:
- `traefik.yml` - Static config (command-line args used instead)
- `dynamic.yml` - Dynamic rules (could be enabled via `--providers.file` if needed)

These can be kept for reference or removed if not needed.

### Transition from File-Based Config

If switching from the previous file-based configuration:

**Before (File-based):**
```yaml
volumes:
  - ./traefik/config/traefik.yml:/etc/traefik/traefik.yml:ro
  - ./traefik/config/dynamic.yml:/etc/traefik/dynamic.yml:ro
```

**Now (Command-line):**
```yaml
command:
  - "--api.insecure=true"
  - "--providers.docker=true"
  - # ... more flags
```

### Troubleshooting

**Certificate generation not working:**
1. Check Cloudflare API token in `.env`
2. Verify domain is in Cloudflare
3. Check logs: `docker-compose logs traefik | grep -i acme`
4. Ensure `letsencrypt/acme.json` has correct permissions: `chmod 600 letsencrypt/acme.json`

**Services not accessible:**
1. Verify Traefik is running: `docker-compose ps`
2. Check Docker socket access: `docker exec traefik_reverse_proxy ls -la /var/run/docker.sock`
3. Review service labels in `docker-compose.yml`
4. Check logs: `docker-compose logs traefik`

**DNS resolution issues:**
1. Verify domain DNS points to your server
2. For local development, add to `/etc/hosts`:
   ```
   127.0.0.1 local.dev
   127.0.0.1 traefik.local.dev
   127.0.0.1 wud.local.dev
   127.0.0.1 kasm.local.dev
   ```

### Environment Variables Required

In `.env`:
```
DOMAIN_NAME=your-domain.com
ACME_EMAIL=your-email@example.com
CLOUDFLARE_API_TOKEN=your-dns-api-token
```

### Further Customization

To add middleware, security headers, or additional routing rules, you have options:

**Option 1: Add command-line flags**
```yaml
command:
  - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
  - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
```

**Option 2: Enable file provider and use dynamic.yml**
```yaml
command:
  - "--providers.file.filename=/etc/traefik/dynamic.yml"
  - "--providers.file.watch=true"
volumes:
  - ./traefik/config/dynamic.yml:/etc/traefik/dynamic.yml:ro
```

**Option 3: Use Traefik labels directly on services**
```yaml
labels:
  - "traefik.http.middlewares.myauth.basicauth.users=admin:hashed_password"
  - "traefik.http.routers.myservice.middlewares=myauth@docker"
```

### References

- [Traefik ACME Configuration](https://doc.traefik.io/traefik/https/acme/)
- [Traefik DNS Challenge](https://doc.traefik.io/traefik/https/acme/#dnschallenge)
- [Traefik Cloudflare Provider](https://doc.traefik.io/traefik/https/acme/#providers)
- [Traefik Command-Line Flags](https://doc.traefik.io/traefik/reference/static-configuration/cli/)

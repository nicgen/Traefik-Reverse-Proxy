# Get Started with 1Password Developer Environment

**Start here!** This is your entry point to the Docker + 1Password integration.

## What You Have

A complete Docker development environment with:
- **Traefik** - Reverse proxy with automatic HTTPS
- **What's Up Docker** - Container update monitoring
- **Kasm Workspaces** - Browser-based container streaming
- **1Password Integration** - Secure secret management

## Quick Start (5 Minutes)

### 1. Prerequisites Check

```bash
# Verify you have:
op --version        # 1Password CLI 2.0+
docker --version    # Docker 20.10+
docker compose version  # Docker Compose 2.0+
```

Not installed? See [Prerequisites](#prerequisites) below.

### 2. Authenticate with 1Password

```bash
op signin
```

### 3. Run Setup

```bash
cd /home/nic/docker
./setup-developer-environment.sh
```

You'll be prompted for:
- Domain name (e.g., local.dev)
- Email for Let's Encrypt
- Cloudflare API token
- Kasm admin password
- Docker Hub credentials (optional)

### 4. Start Services

```bash
./dev-start.sh
```

### 5. Access Your Services

- **Traefik Dashboard**: http://localhost:8080
- **What's Up Docker**: http://localhost:3000
- **Kasm Workspaces**: http://localhost:6901

## Daily Commands

```bash
./dev-start.sh      # Start all services
./dev-status.sh     # Check status
./dev-logs.sh       # View logs
./dev-stop.sh       # Stop services
```

## Where to Go Next

### Just Starting?
→ [QUICK_START_1PASSWORD.md](./QUICK_START_1PASSWORD.md) - Complete quick start guide

### Want Full Details?
→ [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md) - Comprehensive guide

### Need Daily Operations?
→ [DAILY_WORKFLOW.md](./DAILY_WORKFLOW.md) - Daily workflow reference

### Command Reference?
→ [COMMAND_CHEATSHEET.md](./COMMAND_CHEATSHEET.md) - All commands in one place

### Having Issues?
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common problems & solutions

### Integration Overview?
→ [README_1PASSWORD_INTEGRATION.md](./README_1PASSWORD_INTEGRATION.md) - Complete project overview

## Prerequisites

### 1Password CLI

**Linux:**
```bash
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  sudo tee /etc/apt/sources.list.d/1password.list

sudo apt update && sudo apt install 1password-cli
```

**Verify:**
```bash
op --version
```

### Docker & Docker Compose

**Ubuntu/Debian:**
```bash
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and back in for group changes

# Verify
docker --version
docker compose version
```

### Cloudflare API Token

1. Visit: https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Edit zone DNS" template
4. Select your domain
5. Create and copy the token

## File Structure Overview

```
/home/nic/docker/
├── .env.local                  # Your secrets (not committed)
├── docker-compose-secure.yml   # Docker configuration
├── dev-*.sh                    # Helper scripts
└── Documentation files (.md)
```

## Security Note

- `.env.local` contains all secrets
- File has 600 permissions (owner only)
- Not tracked in git
- Required for all operations

**Never commit `.env.local` to version control!**

## Common Issues

### "op: command not found"
→ Install 1Password CLI (see [Prerequisites](#prerequisites))

### "You are not currently signed in"
→ Run `op signin`

### ".env.local not found"
→ Run `./setup-developer-environment.sh`

### Port conflicts
→ Check: `sudo netstat -tlnp | grep -E ':(80|443|8080)'`

### Services won't start
→ Run: `./dev-stop.sh && docker system prune -f && ./dev-start.sh`

More help: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

## Key Features

### Simple Setup
One command to get started, prompts for all configuration

### Secure by Default
Multiple layers of security, no secrets in version control

### Easy Maintenance
Edit one file, restart services - that's it

### Team Friendly
Share setup script, each developer creates their own environment

### Well Documented
Comprehensive guides for every aspect

## Understanding the Integration

### How Secrets Work

1. **Storage**: All secrets in `.env.local` file
2. **Loading**: 1Password CLI reads file when running commands
3. **Injection**: `op run --env-file=.env.local --` injects variables
4. **Runtime**: Docker Compose receives variables, passes to containers

### Why This Approach?

**1Password Developer Environments** are purpose-built for local development:
- Single file for all secrets
- No vault management needed
- Simple rotation
- Native CLI integration
- Team collaboration ready

See [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md) for detailed explanation.

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `setup-developer-environment.sh` | Initial setup wizard |
| `dev-start.sh` | Start all services |
| `dev-stop.sh` | Stop all services |
| `dev-status.sh` | Check service status |
| `dev-logs.sh` | View service logs |
| `dev-restart.sh` | Restart services |
| `dev-secrets.sh` | View secrets (masked) |
| `dev-update-secrets.sh` | Update secrets |
| `verify-1password-setup.sh` | Verify setup is correct |

## Documentation Map

```
GET_STARTED.md (You are here!)
    ↓
QUICK_START_1PASSWORD.md (5-min setup)
    ↓
README_1PASSWORD_INTEGRATION.md (Project overview)
    ↓
DEVELOPER_ENVIRONMENT_GUIDE.md (Complete guide)
    ↓
DAILY_WORKFLOW.md (Daily operations)
    ↓
COMMAND_CHEATSHEET.md (Quick reference)
    ↓
TROUBLESHOOTING.md (Problem solving)
```

## Team Onboarding

New team member? Have them:

1. **Clone repository**
   ```bash
   git clone <repo-url>
   cd docker
   ```

2. **Install prerequisites**
   - 1Password CLI
   - Docker & Docker Compose

3. **Run setup**
   ```bash
   op signin
   ./setup-developer-environment.sh
   ```

4. **Start developing**
   ```bash
   ./dev-start.sh
   ```

See [Team Collaboration](./DEVELOPER_ENVIRONMENT_GUIDE.md#team-collaboration) section for details.

## Verification

After setup, verify everything is correct:

```bash
./verify-1password-setup.sh
```

This checks:
- Prerequisites installed
- Authentication valid
- Configuration correct
- Files properly secured
- Scripts executable
- Documentation present

## Support

### Self-Help
1. Run `./verify-1password-setup.sh`
2. Check `./dev-status.sh`
3. Read [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### Resources
- [1Password Developer Docs](https://developer.1password.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

## What's Different from Traditional Setup?

### Before (Vault Approach)
- Create vault items individually
- Manage complex references
- Update items one by one
- Complex team coordination

### After (Developer Environment)
- Run one setup script
- Edit one file
- Simple secret rotation
- Easy team onboarding

**Result**: 5-minute setup instead of 30+ minutes, ongoing maintenance is trivial.

## Next Actions

1. **Complete setup** (if not done)
   ```bash
   ./setup-developer-environment.sh
   ```

2. **Verify setup**
   ```bash
   ./verify-1password-setup.sh
   ```

3. **Start services**
   ```bash
   ./dev-start.sh
   ```

4. **Read detailed guide**
   - [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md)

5. **Bookmark daily workflow**
   - [DAILY_WORKFLOW.md](./DAILY_WORKFLOW.md)

## Summary

You now have a **production-ready Docker development environment** with:

- Secure secret management via 1Password
- Automated HTTPS certificates
- Container update monitoring
- Browser-based workspaces
- Complete documentation
- Team-ready workflows

**Time to first productive work**: ~5 minutes

Ready? Start here: `./setup-developer-environment.sh`

---

**Questions?** Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) or [DEVELOPER_ENVIRONMENT_GUIDE.md](./DEVELOPER_ENVIRONMENT_GUIDE.md)

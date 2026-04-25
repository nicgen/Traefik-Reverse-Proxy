# Traefik Reverse Proxy & Secure Infrastructure

This project provides a hardened Traefik-based reverse proxy infrastructure, designed for secure local or remote routing with automated SSL certificates.

## Core Features
- **Traefik v2.11**: Modern reverse proxy with automated TLS.
- **Cloudflare DNS-01**: Secure ACME challenge for automated SSL certificates (Let's Encrypt).
- **Docker Socket Proxy**: Security hardening that restricts Traefik's access to the Docker API.
- **Secure Dashboard**: Traefik dashboard protected by BasicAuth and HTTPS.
- **1Password Integration**: Seamless secret management (no plain-text secrets on disk).

## Getting Started

1. **Setup**: Initialize the directory structure.
   ```bash
   make setup
   ```

2. **Environment**: Ensure your secrets are available via 1Password.
   ```bash
   # Example using op run
   op run --env-file=.env -- make up
   ```

3. **Dashboard**: Access your secure dashboard at:
   `https://traefik.your-domain.com/dashboard/`

## Management Commands

- `make up`: Start the infrastructure.
- `make status`: Check container status.
- `make logs`: View live logs.
- `make down`: Stop services.
- `make clean`: Full cleanup (containers and volumes).

## Documentation
See the `docs/` folder for detailed guides, troubleshooting, and cheat sheets.


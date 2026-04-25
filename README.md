# Secure Docker Infrastructure

This project provides a secure, modular Docker infrastructure stack.

## Core Services
- **Traefik**: Reverse Proxy
- **What's Up Docker (WUD)**: Container update monitoring
- **Docker Socket Proxy**: Security hardening for Docker API

## Getting Started

1. **Setup**: Initialize the environment.
   ```bash
   make setup
   ```

2. **Run**: Start the services.
   ```bash
   make up
   ```

## Management

- `make status`: Check container status.
- `make logs`: View live logs.
- `make down`: Stop services.
- `make clean`: Stop services and remove volumes.

## Documentation
See the `docs/` folder for detailed guides and cheat sheets.

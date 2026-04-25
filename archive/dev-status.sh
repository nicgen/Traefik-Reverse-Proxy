#!/bin/bash
set -e

# ============================================================================
# Check Status of Docker Services
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Docker Development Environment Status${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

cd "$SCRIPT_DIR"

# Check if .env named pipe exists
if [ ! -p .env ]; then
    echo -e "${RED}Error: .env named pipe not found${NC}"
    echo "1Password environment not synced. Please:"
    echo "1. Ensure 1Password environment is synced to this directory"
    echo "2. Check 1Password app settings for Environment syncing"
    exit 1
fi

# ============================================================================
# Container Status
# ============================================================================
echo -e "${CYAN}Container Status:${NC}"
op run --env-file=.env -- docker compose -f docker-compose-secure.yml ps
echo ""

# ============================================================================
# Health Checks
# ============================================================================
echo -e "${CYAN}Service Health:${NC}"
echo ""

# Check if containers are running
CONTAINERS=("docker-socket-proxy" "traefik_reverse_proxy" "wud" "kasm")
for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
        if [ "$STATUS" = "running" ]; then
            echo -e "  ${GREEN}✓${NC} $container: running"
        else
            echo -e "  ${RED}⨯${NC} $container: $STATUS"
        fi
    else
        echo -e "  ${RED}⨯${NC} $container: not found"
    fi
done
echo ""

# ============================================================================
# Network Status
# ============================================================================
echo -e "${CYAN}Network Status:${NC}"
NETWORKS=("traefik_net" "socket_proxy_net")
for network in "${NETWORKS[@]}"; do
    if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
        echo -e "  ${GREEN}✓${NC} $network"
    else
        echo -e "  ${RED}⨯${NC} $network: not found"
    fi
done
echo ""

# ============================================================================
# Volume Status
# ============================================================================
echo -e "${CYAN}Data Directories:${NC}"
DIRS=("letsencrypt" "wud/config" "wud/data" "kasm/data")
for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "  ${GREEN}✓${NC} $dir ($SIZE)"
    else
        echo -e "  ${YELLOW}!${NC} $dir: not found"
    fi
done
echo ""

# ============================================================================
# Port Status
# ============================================================================
echo -e "${CYAN}Port Bindings:${NC}"
PORTS=("80" "443" "8080" "3000" "6901")
for port in "${PORTS[@]}"; do
    if netstat -tln 2>/dev/null | grep -q ":${port} " || ss -tln 2>/dev/null | grep -q ":${port} "; then
        CONTAINER=$(docker ps --format '{{.Names}}' --filter "publish=${port}" 2>/dev/null | head -n1)
        if [ -n "$CONTAINER" ]; then
            echo -e "  ${GREEN}✓${NC} Port $port: $CONTAINER"
        else
            echo -e "  ${YELLOW}!${NC} Port $port: in use (non-Docker)"
        fi
    else
        echo -e "  ${RED}⨯${NC} Port $port: not listening"
    fi
done
echo ""

# ============================================================================
# Service URLs
# ============================================================================
DOMAIN_NAME=$(op run --env-file=.env -- printenv DOMAIN_NAME 2>/dev/null || echo "local.dev")

echo -e "${CYAN}Service URLs:${NC}"
echo "  Traefik Dashboard:  http://localhost:8080"
echo "  What's Up Docker:   http://localhost:3000"
echo "  Kasm Workspaces:    http://localhost:6901"
echo ""
echo -e "${CYAN}Domain URLs (when DNS configured):${NC}"
echo "  What's Up Docker:   https://wud.$DOMAIN_NAME"
echo "  Kasm Workspaces:    https://kasm.$DOMAIN_NAME"
echo ""

# ============================================================================
# Quick Actions
# ============================================================================
echo -e "${CYAN}Quick Actions:${NC}"
echo "  View logs:          ./dev-logs.sh"
echo "  Restart services:   ./dev-restart.sh"
echo "  Stop services:      ./dev-stop.sh"
echo "  View secrets:       ./dev-secrets.sh"
echo ""

echo -e "${GREEN}=================================================================${NC}"

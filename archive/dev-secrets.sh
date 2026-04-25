#!/bin/bash
set -e

# ============================================================================
# View Secrets from 1Password Developer Environment
# ============================================================================
# This script displays secrets stored in the developer environment
# in a safe, masked format (unless --reveal is used)
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

# Check for reveal flag
REVEAL=false
if [ "$1" = "--reveal" ]; then
    REVEAL=true
fi

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  1Password Developer Environment Secrets${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

# Check for .env
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env not found${NC}"
    echo "Please run: ./setup-developer-environment.sh"
    exit 1
fi

# Function to mask a value
mask_value() {
    local value="$1"
    local length=${#value}

    if [ $length -le 8 ]; then
        echo "********"
    else
        local visible=$((length / 4))
        local masked=$((length - visible))
        echo "${value:0:$visible}$(printf '*%.0s' $(seq 1 $masked))"
    fi
}

# Load and display secrets
echo -e "${CYAN}Configuration Values:${NC}"
echo ""

# Export all variables
eval "$(op run --env-file=.env -- env | grep -E '^(DOMAIN_NAME|ACME_EMAIL|CLOUDFLARE_API_TOKEN|KASM_|DOCKER_HUB_|WUD_)=')"

# Display values
echo -e "${YELLOW}Global Configuration:${NC}"
echo "  DOMAIN_NAME: ${DOMAIN_NAME}"
echo ""

echo -e "${YELLOW}Traefik Configuration:${NC}"
echo "  ACME_EMAIL: ${ACME_EMAIL}"
if [ "$REVEAL" = true ]; then
    echo "  CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN}"
else
    echo "  CLOUDFLARE_API_TOKEN: $(mask_value "$CLOUDFLARE_API_TOKEN")"
fi
echo ""

echo -e "${YELLOW}Kasm Configuration:${NC}"
echo "  KASM_PORT: ${KASM_PORT}"
echo "  KASM_DATA_PATH: ${KASM_DATA_PATH}"
echo "  KASM_ADMIN_USER: ${KASM_ADMIN_USER}"
if [ "$REVEAL" = true ]; then
    echo "  KASM_ADMIN_PASSWORD: ${KASM_ADMIN_PASSWORD}"
else
    echo "  KASM_ADMIN_PASSWORD: $(mask_value "$KASM_ADMIN_PASSWORD")"
fi
echo ""

echo -e "${YELLOW}Docker Hub Configuration:${NC}"
if [ -n "$DOCKER_HUB_USERNAME" ]; then
    echo "  DOCKER_HUB_USERNAME: ${DOCKER_HUB_USERNAME}"
    if [ "$REVEAL" = true ]; then
        echo "  DOCKER_HUB_PASSWORD: ${DOCKER_HUB_PASSWORD}"
    else
        echo "  DOCKER_HUB_PASSWORD: $(mask_value "$DOCKER_HUB_PASSWORD")"
    fi
else
    echo "  (Not configured)"
fi
echo ""

echo -e "${YELLOW}What's Up Docker Configuration:${NC}"
echo "  WUD_CONFIG_PATH: ${WUD_CONFIG_PATH}"
echo "  WUD_DATA_PATH: ${WUD_DATA_PATH}"
echo "  WUD_API_PORT: ${WUD_API_PORT}"
echo "  WUD_REGISTRY_PROVIDER: ${WUD_REGISTRY_PROVIDER}"
echo ""

if [ "$REVEAL" = false ]; then
    echo -e "${CYAN}Note: Sensitive values are masked${NC}"
    echo "Use '--reveal' to show actual values: ./dev-secrets.sh --reveal"
    echo ""
fi

echo -e "${CYAN}Managing Secrets:${NC}"
echo "  Edit .env:    nano .env"
echo "  After editing:      Restart services with ./dev-restart.sh"
echo ""

echo -e "${CYAN}Security Recommendations:${NC}"
echo "  - Never commit .env to version control"
echo "  - Rotate sensitive credentials regularly"
echo "  - Use strong, unique passwords (16+ characters)"
echo "  - Limit access to .env file (chmod 600)"
echo ""

echo -e "${GREEN}=================================================================${NC}"

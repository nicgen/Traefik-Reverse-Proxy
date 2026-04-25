#!/bin/bash
set -e

# ============================================================================
# Update Secrets in 1Password Developer Environment
# ============================================================================
# This script helps update specific secrets in .env
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

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Update Developer Environment Secrets${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

# Check for .env
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env not found${NC}"
    echo "Please run: ./setup-developer-environment.sh"
    exit 1
fi

# Backup current .env
BACKUP_FILE=".env.backup.$(date +%Y%m%d_%H%M%S)"
cp .env "$BACKUP_FILE"
echo -e "${GREEN}✓ Created backup: $BACKUP_FILE${NC}"
echo ""

# Function to update a secret
update_secret() {
    local key="$1"
    local prompt="$2"
    local is_password="${3:-false}"

    echo -e "${CYAN}Update $prompt?${NC}"
    read -p "Update this value? [y/N]: " UPDATE

    if [[ "$UPDATE" =~ ^[Yy]$ ]]; then
        if [ "$is_password" = true ]; then
            read -sp "New value: " NEW_VALUE
            echo ""
        else
            read -p "New value: " NEW_VALUE
        fi

        if [ -n "$NEW_VALUE" ]; then
            # Update the value in .env
            sed -i "s|^${key}=.*|${key}=${NEW_VALUE}|" .env
            echo -e "${GREEN}✓ Updated $key${NC}"
        fi
    fi
    echo ""
}

echo -e "${YELLOW}Select which secrets to update:${NC}"
echo ""

# Offer to update each secret
update_secret "DOMAIN_NAME" "Domain Name" false
update_secret "ACME_EMAIL" "ACME Email" false
update_secret "CLOUDFLARE_API_TOKEN" "Cloudflare API Token" true
update_secret "KASM_ADMIN_PASSWORD" "Kasm Admin Password" true
update_secret "DOCKER_HUB_USERNAME" "Docker Hub Username" false
update_secret "DOCKER_HUB_PASSWORD" "Docker Hub Password" true

echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}  Secrets Updated${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Review changes: diff .env $BACKUP_FILE"
echo "  2. Restart services: ./dev-restart.sh"
echo "  3. Verify status: ./dev-status.sh"
echo ""

echo -e "${YELLOW}To revert changes:${NC}"
echo "  cp $BACKUP_FILE .env"
echo ""

#!/bin/bash
set -e

# ============================================================================
# 1Password Developer Environment Setup Script
# ============================================================================
# This script creates and configures a 1Password Developer Environment
# for the Docker development environment.
#
# Prerequisites:
#   - 1Password CLI (op) version 2.0 or later
#   - Authenticated 1Password account
#   - Docker and Docker Compose installed
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="docker-dev-env"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  1Password Developer Environment Setup${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

# ============================================================================
# Step 1: Verify Prerequisites
# ============================================================================
echo -e "${CYAN}Step 1: Verifying prerequisites...${NC}"
echo ""

# Check 1Password CLI
if ! command -v op &> /dev/null; then
    echo -e "${RED}Error: 1Password CLI (op) is not installed${NC}"
    echo "Install from: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi
echo -e "${GREEN}✓ 1Password CLI found: $(op --version)${NC}"

# Check authentication
if ! op account list &>/dev/null; then
    echo -e "${YELLOW}Authenticating with 1Password...${NC}"
    eval $(op signin)
fi
echo -e "${GREEN}✓ 1Password authenticated${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found: $(docker --version | cut -d' ' -f3 | tr -d ',')${NC}"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found: $(docker compose version --short)${NC}"
echo ""

# ============================================================================
# Step 2: Gather Configuration Values
# ============================================================================
echo -e "${CYAN}Step 2: Gathering configuration values...${NC}"
echo ""
echo "Please provide the following configuration values."
echo "Press Enter to use default values shown in [brackets]."
echo ""

# Domain name
read -p "Domain name [local.dev]: " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-local.dev}

# ACME email
read -p "Email for Let's Encrypt notifications: " ACME_EMAIL
while [[ -z "$ACME_EMAIL" ]]; do
    echo -e "${RED}Email is required${NC}"
    read -p "Email for Let's Encrypt notifications: " ACME_EMAIL
done

# Cloudflare API token
echo ""
echo -e "${YELLOW}Cloudflare API Token:${NC}"
echo "Generate at: https://dash.cloudflare.com/profile/api-tokens"
echo "Required permissions: Zone.DNS.Edit"
read -sp "Cloudflare API Token: " CLOUDFLARE_API_TOKEN
echo ""
while [[ -z "$CLOUDFLARE_API_TOKEN" ]]; do
    echo -e "${RED}Cloudflare API Token is required${NC}"
    read -sp "Cloudflare API Token: " CLOUDFLARE_API_TOKEN
    echo ""
done

# Kasm admin password
echo ""
echo -e "${YELLOW}Kasm Admin Password:${NC}"
echo "Use a strong password (16+ characters recommended)"
read -sp "Kasm Admin Password: " KASM_ADMIN_PASSWORD
echo ""
while [[ ${#KASM_ADMIN_PASSWORD} -lt 12 ]]; do
    echo -e "${RED}Password must be at least 12 characters${NC}"
    read -sp "Kasm Admin Password: " KASM_ADMIN_PASSWORD
    echo ""
done

# Docker Hub credentials (optional)
echo ""
echo -e "${YELLOW}Docker Hub Credentials (optional):${NC}"
echo "Leave empty to skip Docker Hub authentication"
read -p "Docker Hub Username []: " DOCKER_HUB_USERNAME
if [[ -n "$DOCKER_HUB_USERNAME" ]]; then
    read -sp "Docker Hub Password/Token: " DOCKER_HUB_PASSWORD
    echo ""
else
    DOCKER_HUB_PASSWORD=""
fi

echo ""
echo -e "${GREEN}✓ Configuration values gathered${NC}"
echo ""

# ============================================================================
# Step 3: Create 1Password Developer Environment
# ============================================================================
echo -e "${CYAN}Step 3: Creating 1Password Developer Environment...${NC}"
echo ""

# Create a temporary file for the .env.local
ENV_FILE=$(mktemp)
trap "rm -f $ENV_FILE" EXIT

# Write all configuration to the temporary .env.local file
cat > "$ENV_FILE" <<EOF
# Global Configuration
DOMAIN_NAME=$DOMAIN_NAME

# Traefik Configuration
ACME_EMAIL=$ACME_EMAIL
CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN

# Kasm Configuration
KASM_PORT=6901
KASM_DATA_PATH=./kasm/data
KASM_ADMIN_USER=admin
KASM_ADMIN_PASSWORD=$KASM_ADMIN_PASSWORD

# Docker Hub Credentials
DOCKER_HUB_USERNAME=$DOCKER_HUB_USERNAME
DOCKER_HUB_PASSWORD=$DOCKER_HUB_PASSWORD

# What's Up Docker Configuration
WUD_CONFIG_PATH=./wud/config
WUD_DATA_PATH=./wud/data
WUD_API_PORT=3000
WUD_REGISTRY_PROVIDER=docker
EOF

# Initialize the developer environment
echo -e "${YELLOW}Creating developer environment project...${NC}"
cd "$SCRIPT_DIR"

# Use op CLI to create the developer environment
# Note: The Developer Environment feature uses .env.local file
cp "$ENV_FILE" .env.local

echo -e "${GREEN}✓ Created .env.local with all configuration${NC}"
echo ""

# ============================================================================
# Step 4: Create Service Account (Optional)
# ============================================================================
echo -e "${CYAN}Step 4: Service Account Setup${NC}"
echo ""
echo "Service accounts enable non-interactive access for CI/CD pipelines."
read -p "Create a service account token? [y/N]: " CREATE_SA
echo ""

if [[ "$CREATE_SA" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}To create a service account:${NC}"
    echo "1. Visit: https://my.1password.com/developer-tools/infrastructure-secrets/service-accounts"
    echo "2. Create a new service account named: docker-dev-env-sa"
    echo "3. Grant access to this developer environment"
    echo "4. Save the token securely"
    echo ""
    echo "For automated access, set:"
    echo "  export OP_SERVICE_ACCOUNT_TOKEN=<your-token>"
    echo ""
    read -p "Press Enter to continue..."
fi

# ============================================================================
# Step 5: Create Helper Scripts
# ============================================================================
echo -e "${CYAN}Step 5: Creating helper scripts...${NC}"
echo ""

# Update .gitignore
if [ -f .gitignore ]; then
    if ! grep -q "^\.env\.local$" .gitignore; then
        echo ".env.local" >> .gitignore
        echo -e "${GREEN}✓ Added .env.local to .gitignore${NC}"
    fi
else
    echo ".env.local" > .gitignore
    echo -e "${GREEN}✓ Created .gitignore${NC}"
fi

echo -e "${GREEN}✓ Helper scripts ready${NC}"
echo ""

# ============================================================================
# Step 6: Verify Setup
# ============================================================================
echo -e "${CYAN}Step 6: Verifying setup...${NC}"
echo ""

# Create necessary directories
mkdir -p letsencrypt
mkdir -p wud/config wud/data
mkdir -p kasm/data kasm/data/profiles

echo -e "${GREEN}✓ Created necessary directories${NC}"

# Test loading environment
if op run --env-file=.env.local -- printenv DOMAIN_NAME &>/dev/null; then
    echo -e "${GREEN}✓ Environment variables load successfully${NC}"
else
    echo -e "${RED}⨯ Failed to load environment variables${NC}"
    exit 1
fi

# Set proper permissions
chmod 600 .env.local
echo -e "${GREEN}✓ Set secure permissions on .env.local${NC}"
echo ""

# ============================================================================
# Setup Complete
# ============================================================================
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo ""
echo -e "${CYAN}Developer Environment Created:${NC}"
echo "  Project: $PROJECT_NAME"
echo "  Environment file: .env.local"
echo "  Domain: $DOMAIN_NAME"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo -e "${YELLOW}1. Start your services:${NC}"
echo "   ./dev-start.sh"
echo ""
echo -e "${YELLOW}2. View running containers:${NC}"
echo "   ./dev-status.sh"
echo ""
echo -e "${YELLOW}3. View secrets (safely):${NC}"
echo "   ./dev-secrets.sh"
echo ""
echo -e "${YELLOW}4. Stop services:${NC}"
echo "   ./dev-stop.sh"
echo ""
echo -e "${CYAN}Access Your Services:${NC}"
echo "  Traefik Dashboard:  http://localhost:8080"
echo "  What's Up Docker:   http://localhost:3000"
echo "  Kasm Workspaces:    http://localhost:6901"
echo "    Username: admin"
echo "    Password: (stored in 1Password)"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  Setup Guide:      ./DEVELOPER_ENVIRONMENT_GUIDE.md"
echo "  Daily Workflow:   ./DAILY_WORKFLOW.md"
echo "  Troubleshooting:  ./TROUBLESHOOTING.md"
echo ""
echo -e "${GREEN}=================================================================${NC}"

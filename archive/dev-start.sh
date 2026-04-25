#!/bin/bash
set -e

# ============================================================================
# Start Docker Services with 1Password Developer Environment
# ============================================================================
# This script starts all Docker services with secrets loaded from
# 1Password Developer Environment (synced to .env named pipe)
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Starting Docker Development Environment${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

# Change to script directory
cd "$SCRIPT_DIR"

# ============================================================================
# Pre-flight Checks
# ============================================================================
echo -e "${CYAN}Pre-flight checks...${NC}"
echo ""

# Check 1Password CLI
if ! command -v op &> /dev/null; then
    echo -e "${RED}Error: 1Password CLI (op) is not installed${NC}"
    echo "Install from: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Check authentication
if ! op account list &>/dev/null; then
    echo -e "${YELLOW}Authenticating with 1Password...${NC}"
    eval $(op signin)
fi

# Check for .env pipe from 1Password
if [ ! -p .env ]; then
    echo -e "${RED}Error: .env named pipe not found${NC}"
    echo ""
    echo "1Password environment not synced. Please:"
    echo "1. Ensure 1Password environment is synced to this directory"
    echo "2. Check 1Password app settings for Environment syncing"
    echo ""
    exit 1
fi

# Check for docker-compose-secure.yml
if [ ! -f docker-compose-secure.yml ]; then
    echo -e "${RED}Error: docker-compose-secure.yml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# ============================================================================
# Create Necessary Directories
# ============================================================================
echo -e "${CYAN}Creating directories...${NC}"
mkdir -p letsencrypt
mkdir -p wud/config wud/data
mkdir -p kasm/data kasm/data/profiles
echo -e "${GREEN}✓ Directories ready${NC}"
echo ""

# ============================================================================
# Stop Existing Containers
# ============================================================================
echo -e "${CYAN}Stopping existing containers...${NC}"
op run --env-file=.env -- bash -c 'docker compose -f docker-compose-secure.yml down' 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# ============================================================================
# Start Services
# ============================================================================
echo -e "${CYAN}Starting services with secrets from 1Password...${NC}"
echo ""

# Run docker compose with 1Password environment injection via bash wrapper
# This ensures environment variables are properly substituted in docker-compose.yml
op run --env-file=.env -- bash -c 'docker compose -f docker-compose-secure.yml up -d'

echo ""
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}  Services Started Successfully!${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo ""

# Wait for containers to initialize
sleep 3

# ============================================================================
# Show Status
# ============================================================================
echo -e "${CYAN}Container Status:${NC}"
op run --env-file=.env -- bash -c 'docker compose -f docker-compose-secure.yml ps'
echo ""

# ============================================================================
# Display Service Information
# ============================================================================
echo -e "${CYAN}Service URLs:${NC}"
echo "  Traefik Dashboard:  http://localhost:8080"
echo "  What's Up Docker:   http://localhost:3000"
echo "  Kasm Workspaces:    http://localhost:6901"
echo ""

# Get domain from environment
DOMAIN_NAME=$(op run --env-file=.env -- printenv DOMAIN_NAME)
echo -e "${CYAN}Domain-based URLs (once DNS configured):${NC}"
echo "  What's Up Docker:   https://wud.$DOMAIN_NAME"
echo "  Kasm Workspaces:    https://kasm.$DOMAIN_NAME"
echo ""

echo -e "${CYAN}Useful Commands:${NC}"
echo "  View logs:          ./dev-logs.sh"
echo "  Stop services:      ./dev-stop.sh"
echo "  Check status:       ./dev-status.sh"
echo "  View secrets:       ./dev-secrets.sh"
echo "  Restart services:   ./dev-restart.sh"
echo ""

echo -e "${CYAN}Docker Commands with 1Password:${NC}"
echo "  Run any command:    op run --env-file=.env -- docker compose -f docker-compose-secure.yml <command>"
echo "  Examples:"
echo "    View logs:        op run --env-file=.env -- docker compose -f docker-compose-secure.yml logs -f"
echo "    Exec into traefik: op run --env-file=.env -- docker compose -f docker-compose-secure.yml exec traefik sh"
echo ""

echo -e "${GREEN}=================================================================${NC}"

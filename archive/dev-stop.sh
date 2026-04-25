#!/bin/bash
set -e

# ============================================================================
# Stop Docker Services
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Stopping Docker Development Environment${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

cd "$SCRIPT_DIR"

# Check for .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env not found, stopping without environment${NC}"
    docker compose -f docker-compose-secure.yml down'
else
    echo -e "${CYAN}Stopping services...${NC}"
    op run --env-file=.env -- bash -c 'docker compose -f docker-compose-secure.yml down'
fi

echo ""
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}  Services Stopped${NC}"
echo -e "${GREEN}=================================================================${NC}"

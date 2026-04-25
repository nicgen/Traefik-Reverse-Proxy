#!/bin/bash
set -e

# ============================================================================
# Restart Docker Services
# ============================================================================

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Restarting Docker Development Environment${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

cd "$SCRIPT_DIR"

SERVICE="${1:-}"

if [ -n "$SERVICE" ]; then
    echo -e "${CYAN}Restarting service: $SERVICE${NC}"
    op run --env-file=.env -- bash -c "docker compose -f docker-compose-secure.yml restart $SERVICE"
else
    echo -e "${CYAN}Restarting all services...${NC}"
    op run --env-file=.env -- bash -c 'docker compose -f docker-compose-secure.yml restart'
fi

echo ""
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}  Restart Complete${NC}"
echo -e "${GREEN}=================================================================${NC}"

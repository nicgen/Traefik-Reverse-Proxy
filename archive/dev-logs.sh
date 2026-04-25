#!/bin/bash

# ============================================================================
# View Docker Service Logs
# ============================================================================

# Colors for output
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

# Check for specific service
SERVICE="${1:-}"

if [ -n "$SERVICE" ]; then
    echo -e "${CYAN}Viewing logs for: $SERVICE${NC}"
    echo ""
    op run --env-file=.env -- bash -c "docker compose -f docker-compose-secure.yml logs -f $SERVICE"
else
    echo -e "${CYAN}Viewing logs for all services${NC}"
    echo "Tip: Use './dev-logs.sh <service-name>' to view specific service logs"
    echo "Services: docker-socket-proxy, traefik, wud, kasm"
    echo ""
    op run --env-file=.env -- bash -c 'docker compose -f docker-compose-secure.yml logs -f'
fi

#!/bin/bash
set -e

# ============================================================================
# Verify 1Password Developer Environment Setup
# ============================================================================
# This script verifies that the 1Password Developer Environment integration
# is correctly configured and ready to use.
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
echo -e "${BLUE}  1Password Developer Environment Verification${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

cd "$SCRIPT_DIR"

ERRORS=0
WARNINGS=0

# ============================================================================
# Check 1: Prerequisites
# ============================================================================
echo -e "${CYAN}[1/10] Checking prerequisites...${NC}"

# Check 1Password CLI
if command -v op &> /dev/null; then
    OP_VERSION=$(op --version)
    echo -e "${GREEN}  ✓ 1Password CLI installed: $OP_VERSION${NC}"
else
    echo -e "${RED}  ✗ 1Password CLI not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo -e "${GREEN}  ✓ Docker installed: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}  ✗ Docker not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "${GREEN}  ✓ Docker Compose installed: $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}  ✗ Docker Compose not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ============================================================================
# Check 2: Authentication
# ============================================================================
echo -e "${CYAN}[2/10] Checking 1Password authentication...${NC}"

if op account list &>/dev/null; then
    ACCOUNT=$(op account list | tail -n1 | awk '{print $3}')
    echo -e "${GREEN}  ✓ Authenticated as: $ACCOUNT${NC}"
else
    echo -e "${RED}  ✗ Not authenticated with 1Password${NC}"
    echo -e "${YELLOW}     Run: op signin${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ============================================================================
# Check 3: .env Named Pipe (1Password Environment)
# ============================================================================
echo -e "${CYAN}[3/10] Checking .env named pipe...${NC}"

if [ -p .env ]; then
    echo -e "${GREEN}  ✓ .env named pipe exists (1Password synced)${NC}"

    # Check permissions
    PERMS=$(stat -c "%a" .env)
    if [ "$PERMS" = "600" ]; then
        echo -e "${GREEN}  ✓ Permissions correct: $PERMS${NC}"
    else
        echo -e "${YELLOW}  ! Incorrect permissions: $PERMS (should be 600)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check ownership
    OWNER=$(stat -c "%U" .env)
    if [ "$OWNER" = "$USER" ]; then
        echo -e "${GREEN}  ✓ Owned by: $OWNER${NC}"
    else
        echo -e "${YELLOW}  ! Owned by: $OWNER (current user: $USER)${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}  ✗ .env named pipe not found${NC}"
    echo -e "${YELLOW}     1Password environment not synced to this directory${NC}"
    echo -e "${YELLOW}     Check 1Password app settings for Environment syncing${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ============================================================================
# Check 4: Required Environment Variables
# ============================================================================
echo -e "${CYAN}[4/10] Checking required environment variables...${NC}"

if [ -p .env ]; then
    REQUIRED_VARS=(
        "DOMAIN_NAME"
        "ACME_EMAIL"
        "CLOUDFLARE_API_TOKEN"
        "KASM_ADMIN_PASSWORD"
    )

    for var in "${REQUIRED_VARS[@]}"; do
        if VALUE=$(timeout 2 op run --env-file=.env -- printenv "$var" 2>/dev/null); then
            if [ -n "$VALUE" ]; then
                echo -e "${GREEN}  ✓ $var is set${NC}"
            else
                echo -e "${RED}  ✗ $var is empty${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        else
            echo -e "${RED}  ✗ $var not found${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done
else
    echo -e "${YELLOW}  ! Skipped (no .env pipe)${NC}"
fi

echo ""

# ============================================================================
# Check 5: Test Environment Loading
# ============================================================================
echo -e "${CYAN}[5/10] Testing environment variable loading...${NC}"

if [ -p .env ] && op account list &>/dev/null; then
    if TEST_VALUE=$(op run --env-file=.env -- printenv DOMAIN_NAME 2>/dev/null); then
        echo -e "${GREEN}  ✓ Can load DOMAIN_NAME: $TEST_VALUE${NC}"
    else
        echo -e "${RED}  ✗ Failed to load environment variables${NC}"
        ERRORS=$((ERRORS + 1))
    fi

    if TEST_EMAIL=$(op run --env-file=.env -- printenv ACME_EMAIL 2>/dev/null); then
        echo -e "${GREEN}  ✓ Can load ACME_EMAIL: $TEST_EMAIL${NC}"
    else
        echo -e "${RED}  ✗ Failed to load ACME_EMAIL${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}  ! Skipped (prerequisites not met)${NC}"
fi

echo ""

# ============================================================================
# Check 6: Docker Compose Configuration
# ============================================================================
echo -e "${CYAN}[6/10] Checking Docker Compose configuration...${NC}"

if [ -f docker-compose-secure.yml ]; then
    echo -e "${GREEN}  ✓ docker-compose-secure.yml exists${NC}"

    # Validate syntax
    if [ -p .env ]; then
        if op run --env-file=.env -- docker compose -f docker-compose-secure.yml config > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ Configuration is valid${NC}"
        else
            echo -e "${RED}  ✗ Configuration has errors${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}  ! Cannot validate (no .env)${NC}"
    fi
else
    echo -e "${RED}  ✗ docker-compose-secure.yml not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ============================================================================
# Check 7: Helper Scripts
# ============================================================================
echo -e "${CYAN}[7/10] Checking helper scripts...${NC}"

SCRIPTS=(
    "setup-developer-environment.sh"
    "dev-start.sh"
    "dev-stop.sh"
    "dev-status.sh"
    "dev-logs.sh"
    "dev-restart.sh"
    "dev-secrets.sh"
    "dev-update-secrets.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}  ✓ $script (executable)${NC}"
        else
            echo -e "${YELLOW}  ! $script (not executable)${NC}"
            echo -e "${YELLOW}     Fix with: chmod +x $script${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}  ✗ $script not found${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

# ============================================================================
# Check 8: Data Directories
# ============================================================================
echo -e "${CYAN}[8/10] Checking data directories...${NC}"

DIRS=(
    "letsencrypt"
    "wud/config"
    "wud/data"
    "kasm/data"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}  ✓ $dir exists${NC}"
    else
        echo -e "${YELLOW}  ! $dir not found${NC}"
        echo -e "${YELLOW}     Will be created on first start${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo ""

# ============================================================================
# Check 9: Git Configuration
# ============================================================================
echo -e "${CYAN}[9/10] Checking Git configuration...${NC}"

if [ -d .git ]; then
    # Check .gitignore
    if [ -f .gitignore ]; then
        if grep -q "^\.env\.local$" .gitignore; then
            echo -e "${GREEN}  ✓ .env in .gitignore${NC}"
        else
            echo -e "${RED}  ✗ .env not in .gitignore${NC}"
            echo -e "${YELLOW}     Add with: echo '.env' >> .gitignore${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}  ! .gitignore not found${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check if .env is staged
    if git ls-files --error-unmatch .env &>/dev/null; then
        echo -e "${RED}  ✗ .env is tracked by Git!${NC}"
        echo -e "${YELLOW}     Remove with: git rm --cached .env${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}  ✓ .env not tracked by Git${NC}"
    fi
else
    echo -e "${YELLOW}  ! Not a Git repository${NC}"
fi

echo ""

# ============================================================================
# Check 10: Documentation
# ============================================================================
echo -e "${CYAN}[10/10] Checking documentation...${NC}"

DOCS=(
    "QUICK_START_1PASSWORD.md"
    "DEVELOPER_ENVIRONMENT_GUIDE.md"
    "DAILY_WORKFLOW.md"
    "TROUBLESHOOTING.md"
    "README_1PASSWORD_INTEGRATION.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}  ✓ $doc${NC}"
    else
        echo -e "${YELLOW}  ! $doc not found${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}  Verification Summary${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo -e "${CYAN}You're ready to start developing:${NC}"
    echo "  ./dev-start.sh"
    echo ""
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}✓ Setup complete with $WARNINGS warning(s)${NC}"
    echo ""
    echo -e "${CYAN}You can start developing, but consider addressing warnings:${NC}"
    echo "  Review output above for suggested fixes"
    echo ""
    echo -e "${CYAN}Start services:${NC}"
    echo "  ./dev-start.sh"
    echo ""
    EXIT_CODE=0
else
    echo -e "${RED}✗ Setup incomplete: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo ""
    echo -e "${CYAN}Action required:${NC}"
    echo "  1. Review errors above"
    echo "  2. Run: ./setup-developer-environment.sh"
    echo "  3. Re-run this verification: ./verify-1password-setup.sh"
    echo ""
    EXIT_CODE=1
fi

echo -e "${CYAN}Quick Reference:${NC}"
echo "  Setup:          ./setup-developer-environment.sh"
echo "  Start:          ./dev-start.sh"
echo "  Status:         ./dev-status.sh"
echo "  Logs:           ./dev-logs.sh"
echo "  Secrets:        ./dev-secrets.sh"
echo "  Stop:           ./dev-stop.sh"
echo ""

echo -e "${CYAN}Documentation:${NC}"
echo "  Quick Start:    ./QUICK_START_1PASSWORD.md"
echo "  Full Guide:     ./DEVELOPER_ENVIRONMENT_GUIDE.md"
echo "  Daily Workflow: ./DAILY_WORKFLOW.md"
echo "  Troubleshooting:./TROUBLESHOOTING.md"
echo ""

echo -e "${BLUE}=================================================================${NC}"

exit $EXIT_CODE

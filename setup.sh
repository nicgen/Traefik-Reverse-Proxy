#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Initializing project structure..."

# Create necessary directories for volumes
mkdir -p letsencrypt
mkdir -p dynamic

echo -e "${GREEN}✓ Directories created${NC}"
echo "Setup complete. You can now run 'make up'."

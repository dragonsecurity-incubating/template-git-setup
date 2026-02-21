#!/bin/bash
#
# Setup script for Forgejo runner directories and permissions
# This script creates the required directories for Forgejo runners
# and sets the appropriate permissions.
#

set -e

echo "========================================="
echo "Forgejo Setup - Directory Configuration"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create runner directories
echo "Creating runner directories..."
mkdir -p runners/runner1
mkdir -p runners/runner2

echo -e "${GREEN}✓${NC} Created runners/runner1"
echo -e "${GREEN}✓${NC} Created runners/runner2"
echo ""

# Set ownership to UID/GID 1001 (used by forgejo-runner container)
echo "Setting directory ownership (UID:GID 1001:1001)..."

# Check if running with sufficient privileges
if [ "$EUID" -eq 0 ]; then
    # Running as root
    chown -R 1001:1001 runners/
    echo -e "${GREEN}✓${NC} Ownership set successfully"
else
    # Not running as root, try with sudo
    if command -v sudo &> /dev/null; then
        echo -e "${YELLOW}⚠${NC} Not running as root, using sudo..."
        sudo chown -R 1001:1001 runners/
        echo -e "${GREEN}✓${NC} Ownership set successfully (with sudo)"
    else
        echo -e "${YELLOW}⚠${NC} Warning: Could not set ownership (not root and sudo not available)"
        echo "   You may need to run: sudo chown -R 1001:1001 runners/"
    fi
fi
echo ""

# Set permissions
echo "Setting directory permissions (755)..."
chmod -R 755 runners/
echo -e "${GREEN}✓${NC} Permissions set successfully"
echo ""

# Verify setup
echo "Verifying directory structure..."
if [ -d "runners/runner1" ] && [ -d "runners/runner2" ]; then
    echo -e "${GREEN}✓${NC} All runner directories exist"
    echo ""
    echo "Directory structure:"
    ls -la runners/ | grep -E "^d.*runner[12]" || true
    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Configure your domain in docker-compose.yml and Caddyfile"
    echo "  2. Run: docker compose up -d"
    echo "  3. Access Forgejo web UI and complete initial setup"
    echo "  4. Register runners with: ./register-runner.sh runner1"
else
    echo -e "${YELLOW}⚠${NC} Warning: Some directories may not have been created properly"
    exit 1
fi

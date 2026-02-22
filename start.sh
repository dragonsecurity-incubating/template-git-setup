#!/bin/bash
#
# Convenience script to start Forgejo with all services
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "   Starting Forgejo Services"
echo "=========================================="
echo ""

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found"
    echo "Please run this script from the repository root directory"
    exit 1
fi

# Check if .env file exists (for Renovate)
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} .env file not found (required for Renovate bot)"
    echo ""
    echo "If you want to use Renovate for automated dependency updates:"
    echo "  1. Copy .env.example to .env"
    echo "  2. Edit .env and add your tokens"
    echo ""
    echo "Otherwise, you can continue without Renovate (it will be skipped)"
    echo ""
    read -p "Continue without Renovate? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Please create .env file before starting"
        exit 1
    fi
fi

# Check if directories exist
if [ ! -d "runners/runner1" ] || [ ! -d "runners/runner2" ]; then
    echo -e "${YELLOW}⚠${NC} Runner directories not found"
    echo ""
    read -p "Do you want to create them now? [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        ./setup-directories.sh
    else
        echo "Please run ./setup-directories.sh before starting"
        exit 1
    fi
fi

# Start services
echo "Starting Docker Compose services..."
docker compose up -d

echo ""
echo "Waiting for services to start..."
sleep 5

# Show status
echo ""
echo "Service Status:"
docker compose ps

echo ""
echo -e "${GREEN}✓${NC} Services started!"
echo ""
echo "Access Forgejo at the URL configured in your docker-compose.yml"
echo ""
echo "Next steps:"
echo "  - Complete initial Forgejo setup via web UI"
echo "  - Register runners: ./register-runner.sh runner1"
if [ ! -f ".env" ]; then
    echo "  - Optional: Set up Renovate by creating .env (see .env.example)"
fi
echo ""
echo "View logs: docker compose logs -f"

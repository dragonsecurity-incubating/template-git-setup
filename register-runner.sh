#!/bin/bash
#
# Register Forgejo Runner Script
# This script helps register a Forgejo runner with your Forgejo instance
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if runner name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error:${NC} Runner name is required"
    echo ""
    echo "Usage: $0 <runner_name>"
    echo ""
    echo "Available runners:"
    echo "  - runner1"
    echo "  - runner2"
    echo ""
    echo "Example: $0 runner1"
    exit 1
fi

RUNNER_NAME=$1

# Verify runner exists in docker-compose
if ! docker compose ps | grep -q "$RUNNER_NAME"; then
    echo -e "${RED}Error:${NC} Runner '$RUNNER_NAME' not found in docker-compose.yml"
    echo ""
    echo "Available runners:"
    docker compose ps --services | grep "^runner" || echo "  No runners found"
    exit 1
fi

# Check if runner is already registered
if [ -f "runners/$RUNNER_NAME/config.yml" ]; then
    echo -e "${YELLOW}⚠${NC} Warning: Runner '$RUNNER_NAME' appears to be already registered"
    echo "   Config file exists at: runners/$RUNNER_NAME/config.yml"
    echo ""
    read -p "Do you want to re-register (this will overwrite existing config)? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Registration cancelled."
        exit 0
    fi
fi

echo "=========================================="
echo "   Forgejo Runner Registration"
echo "=========================================="
echo ""
echo "Runner: $RUNNER_NAME"
echo ""

# Prompt for Forgejo instance URL
echo -e "${BLUE}Step 1:${NC} Enter your Forgejo instance URL"
echo "Example: https://git.example.com"
read -p "Forgejo URL: " FORGEJO_URL

if [ -z "$FORGEJO_URL" ]; then
    echo -e "${RED}Error:${NC} Forgejo URL cannot be empty"
    exit 1
fi

# Instructions for getting registration token
echo ""
echo -e "${BLUE}Step 2:${NC} Get a registration token from Forgejo"
echo ""
echo "To get a registration token:"
echo "  1. Login to Forgejo as an administrator"
echo "  2. Go to: ${FORGEJO_URL}/admin/actions/runners"
echo "  3. Click 'Create new Runner'"
echo "  4. Copy the registration token"
echo ""
read -p "Registration Token: " REG_TOKEN

if [ -z "$REG_TOKEN" ]; then
    echo -e "${RED}Error:${NC} Registration token cannot be empty"
    exit 1
fi

# Optional: Custom labels
echo ""
echo -e "${BLUE}Step 3:${NC} Configure runner labels (optional)"
echo ""
echo "Default labels:"
echo "  - docker:docker://node:20"
echo "  - ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
echo ""
read -p "Use default labels? [Y/n] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Enter custom labels (comma-separated):"
    echo "Format: label1:image1,label2:image2"
    read -p "Labels: " CUSTOM_LABELS
    LABELS_ARG="--labels $CUSTOM_LABELS"
else
    LABELS_ARG="--labels docker:docker://node:20,ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
fi

# Register the runner
echo ""
echo "Registering runner '$RUNNER_NAME'..."
echo ""

docker compose exec -T $RUNNER_NAME forgejo-runner register \
    --no-interactive \
    --instance "$FORGEJO_URL" \
    --token "$REG_TOKEN" \
    --name "$RUNNER_NAME" \
    $LABELS_ARG

# Check if registration was successful
if [ -f "runners/$RUNNER_NAME/config.yml" ]; then
    echo ""
    echo -e "${GREEN}✓${NC} Runner '$RUNNER_NAME' registered successfully!"
    echo ""
    echo "Configuration saved to: runners/$RUNNER_NAME/config.yml"
    echo ""
    echo "Restarting runner to apply configuration..."
    docker compose restart $RUNNER_NAME
    echo ""
    echo -e "${GREEN}✓${NC} Runner '$RUNNER_NAME' is now active!"
    echo ""
    echo "You can verify the runner status at:"
    echo "  ${FORGEJO_URL}/admin/actions/runners"
else
    echo ""
    echo -e "${RED}✗${NC} Registration may have failed - config file not found"
    echo "Check runner logs: docker compose logs $RUNNER_NAME"
    exit 1
fi

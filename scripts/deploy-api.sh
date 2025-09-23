#!/bin/bash
# Deploy Ludora API to Fly.io

set -e

echo "🚀 Deploying Ludora API to Fly.io..."

# Find the ludora-api directory
LUDORA_ROOT=""
if [ -f "../ludora-api/package.json" ]; then
    LUDORA_ROOT=".."
elif [ -f "../../ludora-api/package.json" ]; then
    LUDORA_ROOT="../.."
elif [ -f "ludora-api/package.json" ]; then
    LUDORA_ROOT="."
else
    echo "❌ Error: Cannot find ludora-api directory"
    echo "Expected to find ludora-api/package.json"
    echo "Run this script from ludora/ or ludora-utils/ directory"
    exit 1
fi

# Change to API directory
cd "$LUDORA_ROOT/ludora-api"

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ Error: flyctl is not installed"
    echo "Install it with: brew install flyctl"
    exit 1
fi

# Check if user is logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ Error: Not logged in to Fly.io"
    echo "Login with: flyctl auth login"
    exit 1
fi

# Parse command line arguments
DETACH=false
NO_CACHE=false
LOCAL_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --detach|-d)
            DETACH=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --local-only)
            LOCAL_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --detach, -d    Deploy in background"
            echo "  --no-cache      Force rebuild without cache"
            echo "  --local-only    Build locally instead of remote"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build deploy command
DEPLOY_CMD="flyctl deploy -a ludora-api"

if [ "$DETACH" = true ]; then
    DEPLOY_CMD="$DEPLOY_CMD --detach"
fi

if [ "$NO_CACHE" = true ]; then
    DEPLOY_CMD="$DEPLOY_CMD --no-cache"
fi

if [ "$LOCAL_ONLY" = true ]; then
    DEPLOY_CMD="$DEPLOY_CMD --local-only"
fi

echo "📦 Running: $DEPLOY_CMD"

# Run the deployment
eval $DEPLOY_CMD

if [ $? -eq 0 ]; then
    echo "✅ API deployment completed successfully!"
    echo "🌐 URL: https://ludora-api.fly.dev"
    echo ""
    echo "🔍 Check status with:"
    echo "  flyctl status -a ludora-api"
    echo ""
    echo "📋 View logs with:"
    echo "  flyctl logs -a ludora-api"
    echo ""
    echo "🏥 Health check:"
    echo "  curl https://ludora-api.fly.dev/health"
else
    echo "❌ Deployment failed!"
    echo "📋 Check logs with: flyctl logs -a ludora-api"
    exit 1
fi
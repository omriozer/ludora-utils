#!/bin/bash
# Deploy Ludora Frontend to Fly.io

set -e

echo "🚀 Deploying Ludora Frontend to Fly.io..."

# Find the ludora-front directory
LUDORA_ROOT=""
if [ -f "../ludora-front/package.json" ]; then
    LUDORA_ROOT=".."
elif [ -f "../../ludora-front/package.json" ]; then
    LUDORA_ROOT="../.."
elif [ -f "ludora-front/package.json" ]; then
    LUDORA_ROOT="."
else
    echo "❌ Error: Cannot find ludora-front directory"
    echo "Expected to find ludora-front/package.json"
    echo "Run this script from ludora/ or ludora-utils/ directory"
    exit 1
fi

# Change to frontend directory
cd "$LUDORA_ROOT/ludora-front"

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

# Check environment configuration
echo "🔧 Checking environment configuration..."
if [ -f ".env.production" ]; then
    echo "✅ Found .env.production"
    grep "VITE_API_BASE" .env.production || echo "⚠️  VITE_API_BASE not found in .env.production"
else
    echo "⚠️  No .env.production found"
fi

# Build deploy command
DEPLOY_CMD="flyctl deploy -a ludora-front"

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
    echo "✅ Frontend deployment completed successfully!"
    echo "🌐 URL: https://ludora-front.fly.dev"
    echo ""
    echo "🔍 Check status with:"
    echo "  flyctl status -a ludora-front"
    echo ""
    echo "📋 View logs with:"
    echo "  flyctl logs -a ludora-front"
    echo ""
    echo "🏥 Health check:"
    echo "  curl -I https://ludora-front.fly.dev"
else
    echo "❌ Deployment failed!"
    echo "📋 Check logs with: flyctl logs -a ludora-front"
    exit 1
fi
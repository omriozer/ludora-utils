#!/bin/bash
# Deploy Ludora API to Heroku

set -e

echo "🚀 Deploying Ludora API to Heroku..."

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

# Check if heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "❌ Error: Heroku CLI is not installed"
    echo "Install it from: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi

# Check if user is logged in
if ! heroku auth:whoami &> /dev/null; then
    echo "❌ Error: Not logged in to Heroku"
    echo "Login with: heroku login"
    exit 1
fi

# Parse command line arguments
APP="ludora-api-prod"
RUN_MIGRATIONS=true
FORCE_PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --app|-a)
            APP="$2"
            shift 2
            ;;
        --staging)
            APP="ludora-api-staging"
            shift
            ;;
        --no-migrate)
            RUN_MIGRATIONS=false
            shift
            ;;
        --force|-f)
            FORCE_PUSH=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --app, -a NAME  Deploy to specific Heroku app (default: ludora-api-prod)"
            echo "  --staging       Deploy to staging app (ludora-api-staging)"
            echo "  --no-migrate    Skip database migrations after deployment"
            echo "  --force, -f     Force push even if there are conflicts"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Deploy to production"
            echo "  $0 --staging          # Deploy to staging"
            echo "  $0 --app my-app       # Deploy to specific app"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if git is clean
if [ "$FORCE_PUSH" = false ]; then
    if ! git diff --quiet; then
        echo "❌ Error: You have uncommitted changes"
        echo "Commit your changes first, or use --force to deploy anyway"
        exit 1
    fi
fi

# Set up Heroku git remote if it doesn't exist
REMOTE_NAME="heroku-$APP"
if ! git remote | grep -q "^$REMOTE_NAME$"; then
    echo "🔗 Adding Heroku remote: $REMOTE_NAME"
    git remote add "$REMOTE_NAME" "https://git.heroku.com/$APP.git"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📦 Deploying branch '$CURRENT_BRANCH' to Heroku app '$APP'"

# Build deploy command
if [ "$FORCE_PUSH" = true ]; then
    DEPLOY_CMD="git push $REMOTE_NAME $CURRENT_BRANCH:main --force"
else
    DEPLOY_CMD="git push $REMOTE_NAME $CURRENT_BRANCH:main"
fi

echo "🚀 Running: $DEPLOY_CMD"

# Run the deployment
eval $DEPLOY_CMD

if [ $? -eq 0 ]; then
    echo "✅ Git push completed successfully!"
    echo "⏳ Waiting for Heroku build to complete..."
    sleep 30

    # Run database migrations if requested
    if [ "$RUN_MIGRATIONS" = true ]; then
        echo "🗃️ Running database migrations..."
        heroku run npm run migrate:prod --app "$APP"

        if [ $? -eq 0 ]; then
            echo "✅ Migrations completed successfully!"
        else
            echo "⚠️ Migrations failed, but deployment may still be successful"
        fi
    fi

    # Health check
    echo "🏥 Performing health check..."
    if [ "$APP" = "ludora-api-staging" ]; then
        HEALTH_URL="https://$APP.herokuapp.com/health"
    else
        HEALTH_URL="https://api.ludora.app/health"
    fi

    sleep 10
    if curl -f "$HEALTH_URL" &> /dev/null; then
        echo "✅ Health check passed!"
    else
        echo "⚠️ Health check failed - app may still be starting"
    fi

    echo ""
    echo "🎉 API deployment completed successfully!"
    echo "🌐 URL: $HEALTH_URL"
    echo ""
    echo "🔍 Check status with:"
    echo "  heroku ps --app $APP"
    echo ""
    echo "📋 View logs with:"
    echo "  heroku logs --tail --app $APP"
    echo ""
    echo "🏥 Manual health check:"
    echo "  curl $HEALTH_URL"
else
    echo "❌ Deployment failed!"
    echo "📋 Check logs with: heroku logs --tail --app $APP"
    exit 1
fi
#!/bin/bash
# Deploy Ludora Frontend to Firebase Hosting

set -e

echo "🚀 Deploying Ludora Frontend to Firebase Hosting..."

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

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Error: Not logged in to Firebase"
    echo "Login with: firebase login"
    exit 1
fi

# Check if Node.js and yarn are available for building
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    exit 1
fi

if ! command -v yarn &> /dev/null; then
    echo "❌ Error: Yarn is not installed"
    echo "Install it with: npm install -g yarn"
    exit 1
fi

# Parse command line arguments
PROJECT="ludora-af706"
SKIP_BUILD=false
STAGING=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project|-p)
            PROJECT="$2"
            shift 2
            ;;
        --staging)
            STAGING=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --project, -p ID  Deploy to specific Firebase project (default: ludora-af706)"
            echo "  --staging         Deploy to staging channel (preview)"
            echo "  --skip-build      Skip building and use existing dist/ folder"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Build and deploy to production"
            echo "  $0 --staging          # Deploy to staging channel"
            echo "  $0 --skip-build       # Deploy without rebuilding"
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
if [ "$STAGING" = true ]; then
    if [ -f ".env.staging" ]; then
        echo "✅ Found .env.staging"
        grep "VITE_API_BASE" .env.staging || echo "⚠️  VITE_API_BASE not found in .env.staging"
    else
        echo "⚠️  No .env.staging found"
        echo "Creating basic .env.staging file..."
        echo "VITE_API_BASE=https://api-staging.ludora.app/api" > .env.staging
        echo "✅ Created .env.staging with default values"
    fi
else
    if [ -f ".env.production" ]; then
        echo "✅ Found .env.production"
        grep "VITE_API_BASE" .env.production || echo "⚠️  VITE_API_BASE not found in .env.production"
    else
        echo "⚠️  No .env.production found"
        echo "Creating basic .env.production file..."
        echo "VITE_API_BASE=https://api.ludora.app/api" > .env.production
        echo "✅ Created .env.production with default values"
    fi
fi

# Check Firebase configuration
if [ ! -f "firebase.json" ]; then
    echo "❌ Error: firebase.json not found"
    echo "Initialize Firebase in this directory with: firebase init hosting"
    exit 1
fi

# Build the application if not skipped
if [ "$SKIP_BUILD" = false ]; then
    echo "📦 Installing dependencies..."
    yarn install

    echo "🏗️ Building application..."
    if [ "$STAGING" = true ]; then
        echo "Building for staging environment..."
        yarn build:staging
    else
        echo "Building for production environment..."
        yarn build
    fi

    if [ $? -ne 0 ]; then
        echo "❌ Build failed!"
        exit 1
    fi

    echo "✅ Build completed successfully"
else
    echo "⏭️ Skipping build (using existing dist/ folder)"
    if [ ! -d "dist" ]; then
        echo "❌ Error: dist/ folder not found and --skip-build was specified"
        echo "Run without --skip-build to build the application first"
        exit 1
    fi
fi

# Determine deployment target and command
if [ "$STAGING" = true ]; then
    echo "🚀 Deploying to Firebase staging channel..."
    DEPLOY_CMD="firebase hosting:channel:deploy staging --project $PROJECT"
    DEPLOY_TYPE="staging"
else
    echo "🚀 Deploying to Firebase production..."
    DEPLOY_CMD="firebase deploy --only hosting --project $PROJECT"
    DEPLOY_TYPE="production"
fi

echo "📦 Running: $DEPLOY_CMD"

# Run the deployment
eval $DEPLOY_CMD

if [ $? -eq 0 ]; then
    echo "✅ Frontend deployment completed successfully!"

    # Set URLs based on deployment type
    if [ "$STAGING" = true ]; then
        DEPLOYMENT_URL="https://$PROJECT--staging.web.app"
        echo "🌐 Staging URL: $DEPLOYMENT_URL"
    else
        DEPLOYMENT_URL="https://ludora.app"
        echo "🌐 Production URL: $DEPLOYMENT_URL"
        echo "🌐 Firebase URL: https://$PROJECT.web.app"
    fi

    echo ""
    echo "🔍 Check Firebase console:"
    echo "  https://console.firebase.google.com/project/$PROJECT/hosting"
    echo ""
    echo "📋 View Firebase logs:"
    echo "  firebase hosting:logs --project $PROJECT"
    echo ""
    echo "🏥 Health check:"
    echo "  curl -I $DEPLOYMENT_URL"

    # Perform automatic health check
    echo ""
    echo "🏥 Performing automatic health check..."
    sleep 5
    if curl -f -s "$DEPLOYMENT_URL" > /dev/null; then
        echo "✅ Health check passed!"
    else
        echo "⚠️ Health check failed - site may still be deploying"
    fi
else
    echo "❌ Deployment failed!"
    echo "📋 Check Firebase logs: firebase hosting:logs --project $PROJECT"
    exit 1
fi
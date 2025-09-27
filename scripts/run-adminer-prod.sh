#!/bin/bash

# Production Adminer Script
# This script starts Adminer for the production database

# Cleanup function to close connections on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down..."

    # Kill Adminer process
    if [ ! -z "$ADMINER_PID" ]; then
        echo "⏹️  Stopping Adminer..."
        kill $ADMINER_PID 2>/dev/null
    fi

    # Kill any Adminer processes on port 8082
    lsof -ti:8082 | xargs kill -9 2>/dev/null || true
    pkill -f "adminer" 2>/dev/null || true

    # Stop flyctl proxy if we started it
    if [ ! -z "$PROXY_PID" ]; then
        echo "📡 Stopping flyctl proxy..."
        kill $PROXY_PID 2>/dev/null
    fi

    echo "✅ Cleanup completed"
    exit 0
}

# Set up signal handlers for cleanup
trap cleanup SIGINT SIGTERM EXIT

echo "Starting Adminer for Production Environment..."

# Set environment for production
export ENVIRONMENT=production

# Load production environment variables
if [ -f "../ludora-api/.env.production" ]; then
    echo "Loading production environment variables from ../ludora-api/.env.production..."
    source ../ludora-api/.env.production
elif [ -f "ludora-api/.env.production" ]; then
    echo "Loading production environment variables from ludora-api/.env.production..."
    source ludora-api/.env.production
elif [ -f ".env" ]; then
    echo "Loading production environment variables from .env..."
    source .env
else
    echo "Warning: Production .env not found, using defaults for flyctl proxy"
fi

# Production database configuration (assumes flyctl proxy or direct connection)
# Override for local proxy access (when using flyctl proxy 5433:5432)
if [ "$DB_HOST" = "ludora-db.flycast" ]; then
    DB_HOST=localhost
    DB_PORT=5433
fi

# Ensure we have the correct defaults for production
DB_HOST=${DB_HOST:-localhost}  # localhost when using flyctl proxy
DB_PORT=${DB_PORT:-5433}       # proxy port 5433 -> remote 5432
DB_NAME=${DB_NAME:-postgres}   # production database name
DB_USER=${DB_USER:-postgres}   # production database user
DB_PASSWORD=${DB_PASSWORD:-2SpoAsK11AJAhhE}  # production database password

# Auto-start flyctl proxy if not running
echo "🔍 Checking if flyctl proxy is running on port 5433..."
if ! lsof -i :5433 > /dev/null 2>&1; then
    echo "📡 Starting flyctl proxy for production database..."
    flyctl proxy 5433:5432 -a ludora-db > /dev/null 2>&1 &
    PROXY_PID=$!
    echo "⏳ Waiting for proxy to be ready..."
    sleep 3

    # Verify proxy is working
    if lsof -i :5433 > /dev/null 2>&1; then
        echo "✅ Flyctl proxy started successfully on port 5433"
    else
        echo "❌ Failed to start flyctl proxy. Please check your Fly.io connection."
        exit 1
    fi
else
    echo "✅ Flyctl proxy already running on port 5433"
fi

# Check if Adminer is already running
echo "🔍 Checking if Adminer is running on port 8082..."
if lsof -i :8082 > /dev/null 2>&1; then
    echo "✅ Adminer already running on port 8082"
    ADMINER_RUNNING=true
else
    ADMINER_RUNNING=false
fi

echo "Database connection info:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Check if confirmations should be skipped (for automation)
if [ "$SKIP_PROD_CONFIRMATION" = "true" ]; then
    echo "⚡ Skipping confirmations (SKIP_PROD_CONFIRMATION=true)"
else
    # Strong warning for production access
    echo "🚨 DANGER: You are connecting to the PRODUCTION database!"
    echo "   Any changes will affect live data and users."
    echo "   Only proceed if you are absolutely sure."
    echo ""

    # Double confirmation for production
    read -p "Are you sure you want to connect to PRODUCTION? Type 'yes' to continue: " -r
    echo ""
    if [[ ! $REPLY == "yes" ]]; then
        echo "Cancelled for safety."
        exit 1
    fi

    read -p "This is PRODUCTION data. Type 'CONFIRM' to proceed: " -r
    echo ""
    if [[ ! $REPLY == "CONFIRM" ]]; then
        echo "Cancelled for safety."
        exit 1
    fi
fi

# Build auto-login URL with pre-filled credentials (including password)
AUTO_LOGIN_URL="http://localhost:8082/?pgsql=$DB_HOST:$DB_PORT&username=$DB_USER&db=$DB_NAME&password=$DB_PASSWORD"

# Handle Adminer startup
if [ "$ADMINER_RUNNING" = true ]; then
    echo "🎯 Adminer already running - opening browser with auto-login..."
    echo "Auto-login URL: $AUTO_LOGIN_URL"

    # Open browser immediately since Adminer is already running
    (open "$AUTO_LOGIN_URL" 2>/dev/null || echo "Open $AUTO_LOGIN_URL in your browser") &

    echo ""
    echo "✅ Production database GUI is ready!"
    echo "🚨 REMEMBER: This is PRODUCTION data!"
    echo ""
    echo "To stop Adminer later, run: pkill -f adminer"

else
    echo "🚀 Starting Adminer on http://localhost:8082"
    echo "Auto-login URL: $AUTO_LOGIN_URL"
    echo ""
    echo "Connection details (pre-filled):"
    echo "  System: PostgreSQL"
    echo "  Server: $DB_HOST:$DB_PORT"
    echo "  Username: $DB_USER"
    echo "  Database: $DB_NAME"
    echo ""
    echo "🚨 REMEMBER: This is PRODUCTION data!"
    echo "Press Ctrl+C to stop Adminer"
    echo ""

    # Get the script directory and navigate to tools
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOLS_DIR="$SCRIPT_DIR/../tools"

    if [ ! -f "$TOOLS_DIR/adminer.php" ]; then
        echo "Error: adminer.php not found at $TOOLS_DIR/adminer.php"
        echo "Please ensure adminer.php is in the tools directory"
        exit 1
    fi

    # Start server and open browser with auto-login (after confirmations for security)
    echo "Opening browser with auto-login URL..."
    (sleep 3 && (open "$AUTO_LOGIN_URL" 2>/dev/null || echo "Open $AUTO_LOGIN_URL in your browser")) &

    cd "$TOOLS_DIR"
    php -S localhost:8082 adminer.php &
    ADMINER_PID=$!

    echo "✅ Adminer started (PID: $ADMINER_PID)"
    echo "Press Ctrl+C to stop Adminer and close DB connections"

    # Wait for the PHP server to finish
    wait $ADMINER_PID
fi
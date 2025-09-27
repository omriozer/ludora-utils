#!/bin/bash

# Development Adminer Script
# This script starts Adminer for the development database

echo "Starting Adminer for Development Environment..."

# Set environment for development
export ENVIRONMENT=development

# Load development environment variables
if [ -f "ludora-api/.env" ]; then
    echo "Loading development environment variables..."
    source ludora-api/.env
else
    echo "Warning: ludora-api/.env not found, using defaults"
fi

# Database connection defaults for development
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-ludora_development}
DB_USER=${DB_USER:-ludora_user}

echo "Database connection info:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Start PHP built-in server with Adminer
echo "Starting Adminer on http://localhost:8080"
echo "Auto-login URL: http://localhost:8080/?pgsql=$DB_HOST:$DB_PORT&username=$DB_USER&db=$DB_NAME"
echo ""
echo "Connection details (pre-filled):"
echo "  System: PostgreSQL"
echo "  Server: $DB_HOST:$DB_PORT"
echo "  Username: $DB_USER"
echo "  Database: $DB_NAME"
echo ""
echo "Press Ctrl+C to stop Adminer"
echo ""

# Build auto-login URL with pre-filled credentials
AUTO_LOGIN_URL="http://localhost:8080/?pgsql=$DB_HOST:$DB_PORT&username=$DB_USER&db=$DB_NAME"

# Start server and open browser with auto-login
echo "Opening browser with auto-login URL..."
(sleep 3 && (open "$AUTO_LOGIN_URL" 2>/dev/null || echo "Open $AUTO_LOGIN_URL in your browser")) &

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/../tools"

if [ ! -f "$TOOLS_DIR/adminer.php" ]; then
    echo "Error: adminer.php not found at $TOOLS_DIR/adminer.php"
    echo "Please ensure adminer.php is in the tools directory"
    exit 1
fi

cd "$TOOLS_DIR" && php -S localhost:8080 adminer.php
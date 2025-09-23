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
echo "Use these connection details in Adminer:"
echo "  System: PostgreSQL"
echo "  Server: $DB_HOST:$DB_PORT"
echo "  Username: $DB_USER"
echo "  Database: $DB_NAME"
echo ""
echo "Press Ctrl+C to stop Adminer"
echo ""

# Start server and open browser
(sleep 2 && open "http://localhost:8080" 2>/dev/null || echo "Open http://localhost:8080 in your browser") &

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/../tools"
cd "$TOOLS_DIR" && php -S localhost:8080 adminer.php
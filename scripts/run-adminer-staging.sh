#!/bin/bash

# Staging Adminer Script
# This script starts Adminer for the staging database

echo "Starting Adminer for Staging Environment..."

# Set environment for staging
export ENVIRONMENT=staging

# Load staging environment variables
if [ -f "staging.env" ]; then
    echo "Loading staging environment variables..."
    source staging.env
else
    echo "Warning: staging.env not found, using defaults"
fi

# Database connection defaults for staging
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-ludora_staging}
DB_USER=${DB_USER:-ludora_user}

echo "Database connection info:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

# Warning for staging access
echo "⚠️  WARNING: You are connecting to the STAGING database!"
echo "   Be careful with data modifications."
echo ""

# Prompt for confirmation
read -p "Continue connecting to staging database? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Start PHP built-in server with Adminer
echo "Starting Adminer on http://localhost:8081"
echo "Use these connection details in Adminer:"
echo "  System: PostgreSQL"
echo "  Server: $DB_HOST:$DB_PORT"
echo "  Username: $DB_USER"
echo "  Database: $DB_NAME"
echo ""
echo "Press Ctrl+C to stop Adminer"
echo ""

# Start server and open browser
(sleep 2 && open "http://localhost:8081" 2>/dev/null || echo "Open http://localhost:8081 in your browser") &

cd tools && php -S localhost:8081 adminer.php
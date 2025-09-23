#!/bin/bash

# Production Adminer Script
# This script starts Adminer for the production database

echo "Starting Adminer for Production Environment..."

# Set environment for production
export ENVIRONMENT=production

# Load production environment variables
if [ -f ".env" ]; then
    echo "Loading production environment variables..."
    source .env
else
    echo "Error: .env not found! Production requires environment file."
    exit 1
fi

# Validate required environment variables
if [[ -z "$DB_HOST" || -z "$DB_USER" || -z "$DB_NAME" ]]; then
    echo "Error: Required database environment variables not set!"
    echo "Please ensure DB_HOST, DB_USER, DB_NAME are set in .env"
    exit 1
fi

# Database connection info for production
DB_PORT=${DB_PORT:-5432}

echo "Database connection info:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""

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

# Start PHP built-in server with Adminer
echo "Starting Adminer on http://localhost:8082"
echo "Use these connection details in Adminer:"
echo "  System: PostgreSQL"
echo "  Server: $DB_HOST:$DB_PORT"
echo "  Username: $DB_USER"
echo "  Database: $DB_NAME"
echo ""
echo "🚨 REMEMBER: This is PRODUCTION data!"
echo "Press Ctrl+C to stop Adminer"
echo ""

# Start server (no auto-open browser for prod security)
echo "Manually open http://localhost:8082 in your browser"

cd tools && php -S localhost:8082 adminer.php
#!/bin/bash
# Check status of all Ludora services

set -e

echo "📊 Ludora Platform Status Check"
echo "================================"

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
DETAILED=false
HEALTH_CHECK=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed|-d)
            DETAILED=true
            shift
            ;;
        --health|-H)
            HEALTH_CHECK=true
            shift
            ;;
        --json|-j)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Check status of all Ludora services"
            echo ""
            echo "Options:"
            echo "  --detailed, -d    Show detailed machine information"
            echo "  --health, -H      Run health checks on services"
            echo "  --json, -j        Output in JSON format"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                # Basic status check"
            echo "  $0 --detailed     # Detailed machine info"
            echo "  $0 --health       # Include health checks"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to check service status
check_service_status() {
    local app_name=$1
    local service_name=$2
    local url=$3

    echo ""
    echo "🔍 $service_name ($app_name)"
    echo "----------------------------"

    if [ "$JSON_OUTPUT" = true ]; then
        flyctl status -a $app_name --json
    else
        flyctl status -a $app_name
    fi

    if [ "$DETAILED" = true ]; then
        echo ""
        echo "📈 Machine Details:"
        flyctl vm status -a $app_name 2>/dev/null || echo "No VM status available"
    fi

    if [ "$HEALTH_CHECK" = true ] && [ -n "$url" ]; then
        echo ""
        echo "🏥 Health Check:"

        # Test URL connectivity
        if command -v curl &> /dev/null; then
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 10)
            if [ "$HTTP_CODE" = "200" ]; then
                echo "✅ $url - HTTP $HTTP_CODE (OK)"
            else
                echo "❌ $url - HTTP $HTTP_CODE (Failed)"
            fi
        else
            echo "⚠️  curl not available for health check"
        fi
    fi
}

# Function to run connectivity tests
run_connectivity_tests() {
    echo ""
    echo "🌐 Connectivity Tests"
    echo "--------------------"

    if command -v curl &> /dev/null; then
        # Test API health endpoint
        echo -n "API Health Check: "
        API_HEALTH=$(curl -s "https://ludora-api.fly.dev/health" --max-time 10)
        if echo "$API_HEALTH" | grep -q '"status":"healthy"'; then
            echo "✅ Healthy"
        else
            echo "❌ Unhealthy"
        fi

        # Test frontend
        echo -n "Frontend Check: "
        FRONTEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://ludora-front.fly.dev" --max-time 10)
        if [ "$FRONTEND_CODE" = "200" ]; then
            echo "✅ HTTP $FRONTEND_CODE"
        else
            echo "❌ HTTP $FRONTEND_CODE"
        fi

        # Test API auth endpoint
        echo -n "API Auth Check: "
        AUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://ludora-api.fly.dev/api/auth/me" --max-time 10)
        if [ "$AUTH_CODE" = "401" ]; then
            echo "✅ HTTP $AUTH_CODE (Expected - no auth)"
        elif [ "$AUTH_CODE" = "200" ]; then
            echo "✅ HTTP $AUTH_CODE"
        else
            echo "❌ HTTP $AUTH_CODE"
        fi
    else
        echo "⚠️  curl not available for connectivity tests"
    fi
}

# Function to show resource usage summary
show_resource_summary() {
    echo ""
    echo "💾 Resource Summary"
    echo "------------------"

    echo "📊 Application URLs:"
    echo "  Frontend: https://ludora-front.fly.dev"
    echo "  API:      https://ludora-api.fly.dev"
    echo "  Health:   https://ludora-api.fly.dev/health"
    echo ""

    # Get organization info
    echo "🏢 Organization:"
    flyctl auth whoami 2>/dev/null || echo "Unable to get user info"
}

# Main status checks
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting status check..."

# Check API service
check_service_status "ludora-api" "API Server" "https://ludora-api.fly.dev/health"

# Check Frontend service
check_service_status "ludora-front" "Frontend" "https://ludora-front.fly.dev"

# Check Database service
check_service_status "ludora-db" "Database" ""

# Run connectivity tests if requested
if [ "$HEALTH_CHECK" = true ]; then
    run_connectivity_tests
fi

# Show resource summary
show_resource_summary

echo ""
echo "✅ Status check completed at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "💡 Quick commands:"
echo "  View logs:    ./scripts/logs.sh [api|frontend|db]"
echo "  SSH access:   ./scripts/ssh-api.sh or ./scripts/ssh-frontend.sh"
echo "  Deploy:       ./scripts/deploy-api.sh or ./scripts/deploy-frontend.sh"
echo "  Database:     ./scripts/connect-db.sh"
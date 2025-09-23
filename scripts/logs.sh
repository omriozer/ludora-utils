#!/bin/bash
# View logs from Ludora services

set -e

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
SERVICE=""
FOLLOW=false
SINCE=""
INSTANCE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        api|backend)
            SERVICE="ludora-api"
            shift
            ;;
        frontend|front)
            SERVICE="ludora-front"
            shift
            ;;
        db|database)
            SERVICE="ludora-db"
            shift
            ;;
        --follow|-f)
            FOLLOW=true
            shift
            ;;
        --since|-s)
            SINCE="$2"
            shift 2
            ;;
        --instance|-i)
            INSTANCE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [SERVICE] [OPTIONS]"
            echo ""
            echo "View logs from Ludora services"
            echo ""
            echo "Services:"
            echo "  api, backend         View API server logs"
            echo "  frontend, front      View frontend server logs"
            echo "  db, database         View database logs"
            echo "  (no service)         Show all services menu"
            echo ""
            echo "Options:"
            echo "  --follow, -f         Follow logs in real-time"
            echo "  --since, -s TIME     Show logs since time (e.g., '2h', '30m', '2024-01-01')"
            echo "  --instance, -i ID    Show logs from specific instance"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 api                     # View API logs"
            echo "  $0 frontend -f             # Follow frontend logs"
            echo "  $0 api -s 1h               # API logs from last hour"
            echo "  $0 db -i abc123            # Database logs from specific instance"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to view logs for a service
view_logs() {
    local app_name=$1
    local service_name=$2

    echo "📋 Viewing logs for $service_name..."

    # Build logs command
    LOGS_CMD="flyctl logs -a $app_name"

    if [ "$FOLLOW" = true ]; then
        LOGS_CMD="$LOGS_CMD --follow"
    fi

    if [ -n "$SINCE" ]; then
        LOGS_CMD="$LOGS_CMD --since=\"$SINCE\""
    fi

    if [ -n "$INSTANCE" ]; then
        LOGS_CMD="$LOGS_CMD -i $INSTANCE"
    fi

    echo "🔗 Running: $LOGS_CMD"
    echo ""

    eval $LOGS_CMD
}

# If no service specified, show menu
if [ -z "$SERVICE" ]; then
    echo "📋 Ludora Services Logs"
    echo ""
    echo "Available services:"
    echo "  1) API Server (ludora-api)"
    echo "  2) Frontend (ludora-front)"
    echo "  3) Database (ludora-db)"
    echo "  4) All services status"
    echo ""
    read -p "Select service (1-4): " choice

    case $choice in
        1)
            SERVICE="ludora-api"
            ;;
        2)
            SERVICE="ludora-front"
            ;;
        3)
            SERVICE="ludora-db"
            ;;
        4)
            echo ""
            echo "📊 All Services Status:"
            echo ""
            echo "🔗 API Server:"
            flyctl status -a ludora-api
            echo ""
            echo "🎨 Frontend:"
            flyctl status -a ludora-front
            echo ""
            echo "🗄️ Database:"
            flyctl status -a ludora-db
            echo ""
            echo "💡 Use '$0 <service>' to view specific logs"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

# View logs for selected service
case $SERVICE in
    ludora-api)
        view_logs "ludora-api" "API Server"
        ;;
    ludora-front)
        view_logs "ludora-front" "Frontend"
        ;;
    ludora-db)
        view_logs "ludora-db" "Database"
        ;;
    *)
        echo "❌ Unknown service: $SERVICE"
        exit 1
        ;;
esac
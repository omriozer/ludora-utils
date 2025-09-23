#!/bin/bash
# Main Ludora management script

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎮 Ludora Platform Management"
echo "============================="

# Function to show available scripts
show_menu() {
    echo ""
    echo "Available commands:"
    echo ""
    echo "📦 Deployment:"
    echo "  deploy-api              Deploy API server"
    echo "  deploy-frontend         Deploy frontend"
    echo ""
    echo "🔌 Access:"
    echo "  ssh-api                 SSH into API server"
    echo "  ssh-frontend            SSH into frontend server"
    echo "  connect-db              Connect to database"
    echo ""
    echo "📋 Monitoring:"
    echo "  logs [service]          View service logs"
    echo "  status                  Check all services status"
    echo "  health-check            Run comprehensive health check"
    echo ""
    echo "🗄️  Database:"
    echo "  backup-db               Database backup operations"
    echo ""
    echo "🔐 Configuration:"
    echo "  manage-secrets          Manage environment variables"
    echo ""
    echo "Examples:"
    echo "  $0 deploy-api           # Deploy API"
    echo "  $0 logs api             # View API logs"
    echo "  $0 status --detailed    # Detailed status check"
    echo "  $0 health-check --quick # Quick health check"
    echo ""
}

# Parse command line arguments
COMMAND=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        deploy-api|deploy-frontend|ssh-api|ssh-frontend|connect-db|logs|status|health-check|backup-db|manage-secrets)
            COMMAND="$1"
            shift
            # Collect remaining arguments
            ARGS=("$@")
            break
            ;;
        --help|-h|help)
            show_menu
            exit 0
            ;;
        *)
            echo "❌ Unknown command: $1"
            show_menu
            exit 1
            ;;
    esac
done

# If no command specified, show menu
if [ -z "$COMMAND" ]; then
    show_menu
    exit 0
fi

# Execute the command
case $COMMAND in
    deploy-api)
        echo "🚀 Deploying API..."
        exec "$SCRIPT_DIR/deploy-api.sh" "${ARGS[@]}"
        ;;
    deploy-frontend)
        echo "🚀 Deploying Frontend..."
        exec "$SCRIPT_DIR/deploy-frontend.sh" "${ARGS[@]}"
        ;;
    ssh-api)
        echo "🔌 SSH to API server..."
        exec "$SCRIPT_DIR/ssh-api.sh" "${ARGS[@]}"
        ;;
    ssh-frontend)
        echo "🔌 SSH to Frontend server..."
        exec "$SCRIPT_DIR/ssh-frontend.sh" "${ARGS[@]}"
        ;;
    connect-db)
        echo "🗄️  Connecting to database..."
        exec "$SCRIPT_DIR/connect-db.sh" "${ARGS[@]}"
        ;;
    logs)
        echo "📋 Viewing logs..."
        exec "$SCRIPT_DIR/logs.sh" "${ARGS[@]}"
        ;;
    status)
        echo "📊 Checking status..."
        exec "$SCRIPT_DIR/status.sh" "${ARGS[@]}"
        ;;
    health-check)
        echo "🏥 Running health check..."
        exec "$SCRIPT_DIR/health-check.sh" "${ARGS[@]}"
        ;;
    backup-db)
        echo "💾 Database backup operations..."
        exec "$SCRIPT_DIR/backup-db.sh" "${ARGS[@]}"
        ;;
    manage-secrets)
        echo "🔐 Managing secrets..."
        exec "$SCRIPT_DIR/manage-secrets.sh" "${ARGS[@]}"
        ;;
    *)
        echo "❌ Unknown command: $COMMAND"
        show_menu
        exit 1
        ;;
esac
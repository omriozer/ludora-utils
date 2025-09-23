#!/bin/bash
# SSH into Ludora Frontend server

set -e

echo "🔌 Connecting to Ludora Frontend server via SSH..."

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
MACHINE_ID=""
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --machine|-m)
            MACHINE_ID="$2"
            shift 2
            ;;
        --command|-c)
            COMMAND="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Connect to Ludora Frontend server via SSH"
            echo ""
            echo "Options:"
            echo "  --machine, -m ID   Connect to specific machine ID"
            echo "  --command, -c CMD  Run command instead of interactive shell"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Interactive SSH session"
            echo "  $0 -c 'nginx -t'            # Test nginx configuration"
            echo "  $0 -m abc123 -c 'tail /var/log/nginx/error.log'  # Check logs"
            echo ""
            echo "Useful commands to run:"
            echo "  tail -f /var/log/nginx/access.log  # View access logs"
            echo "  tail -f /var/log/nginx/error.log   # View error logs"
            echo "  nginx -t                           # Test nginx config"
            echo "  cat /etc/nginx/conf.d/default.conf # View nginx config"
            echo "  ls -la /usr/share/nginx/html       # View static files"
            echo "  df -h                              # Check disk usage"
            echo "  free -m                            # Check memory usage"
            echo "  ps aux                             # Check running processes"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build SSH command
SSH_CMD="flyctl ssh console -a ludora-front"

if [ -n "$MACHINE_ID" ]; then
    SSH_CMD="$SSH_CMD -s $MACHINE_ID"
fi

if [ -n "$COMMAND" ]; then
    SSH_CMD="$SSH_CMD -C '$COMMAND'"
    echo "📋 Running command: $COMMAND"
else
    echo "🖥️  Starting interactive SSH session..."
    echo ""
    echo "💡 Useful commands once connected:"
    echo "   tail -f /var/log/nginx/access.log  # Access logs"
    echo "   tail -f /var/log/nginx/error.log   # Error logs"
    echo "   nginx -t                           # Test config"
    echo "   ls -la /usr/share/nginx/html       # Static files"
    echo "   df -h                              # Disk usage"
    echo "   exit                               # Close SSH session"
    echo ""
fi

echo "🔗 Connecting: $SSH_CMD"
echo ""

# Execute SSH command
eval $SSH_CMD
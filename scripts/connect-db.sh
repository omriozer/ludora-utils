#!/bin/bash
# Connect to Ludora PostgreSQL database

set -e

echo "🗄️  Connecting to Ludora Database..."

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ Error: flyctl is not installed"
    echo "Install it with: brew install flyctl"
    exit 1
fi

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql is not installed"
    echo "Install PostgreSQL client:"
    echo "  macOS: brew install postgresql"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    exit 1
fi

# Check if user is logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ Error: Not logged in to Fly.io"
    echo "Login with: flyctl auth login"
    exit 1
fi

# Parse command line arguments
PORT=5433
DATABASE="postgres"
USER="postgres"
COMMAND=""
NO_PROXY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --port|-p)
            PORT="$2"
            shift 2
            ;;
        --database|-d)
            DATABASE="$2"
            shift 2
            ;;
        --user|-U)
            USER="$2"
            shift 2
            ;;
        --command|-c)
            COMMAND="$2"
            shift 2
            ;;
        --no-proxy)
            NO_PROXY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Connect to Ludora PostgreSQL database"
            echo ""
            echo "Options:"
            echo "  --port, -p PORT      Local port for proxy (default: 5433)"
            echo "  --database, -d DB    Database name (default: postgres)"
            echo "  --user, -U USER      Username (default: postgres)"
            echo "  --command, -c CMD    Run SQL command instead of interactive"
            echo "  --no-proxy          Skip proxy setup (use existing connection)"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Interactive psql session"
            echo "  $0 -c 'SELECT COUNT(*) FROM \"user\";' # Run SQL query"
            echo "  $0 --port 5434                       # Use different local port"
            echo "  $0 --no-proxy                        # Connect to existing proxy"
            echo ""
            echo "Useful SQL commands:"
            echo "  \\dt                    # List tables"
            echo "  \\d+ table_name         # Describe table"
            echo "  SELECT COUNT(*) FROM \"user\";  # Count users"
            echo "  \\q                     # Quit psql"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set up database proxy if needed
if [ "$NO_PROXY" = false ]; then
    echo "🔗 Setting up database proxy on port $PORT..."
    echo "📝 Note: This will run in the background. Use Ctrl+C to stop when done."

    # Check if port is already in use
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $PORT is already in use. Using existing connection or try a different port."
    else
        echo "🚀 Starting proxy: flyctl proxy $PORT:5432 -a ludora-db"
        flyctl proxy $PORT:5432 -a ludora-db &
        PROXY_PID=$!

        # Wait a moment for proxy to start
        sleep 3

        # Trap to cleanup proxy on exit
        trap "echo '🛑 Stopping database proxy...'; kill $PROXY_PID 2>/dev/null; exit" EXIT
    fi
fi

# Get database password from environment or prompt
if [ -z "$PGPASSWORD" ]; then
    echo "🔐 Database password not set in PGPASSWORD environment variable"
    echo "📝 You'll be prompted for the password when connecting"
    echo ""
fi

# Build psql command
PSQL_CMD="psql -h localhost -p $PORT -U $USER -d $DATABASE"

if [ -n "$COMMAND" ]; then
    PSQL_CMD="$PSQL_CMD -c \"$COMMAND\""
    echo "📋 Running SQL: $COMMAND"
else
    echo "🖥️  Starting interactive database session..."
    echo ""
    echo "💡 Useful commands:"
    echo "   \\dt                    # List all tables"
    echo "   \\d+ table_name         # Describe table structure"
    echo "   SELECT COUNT(*) FROM \"user\";  # Count users"
    echo "   SELECT tablename FROM pg_tables WHERE schemaname = 'public'; # List tables"
    echo "   \\q                     # Quit psql"
    echo ""
fi

echo "🔗 Connecting: $PSQL_CMD"
echo ""

# Execute psql command
eval $PSQL_CMD
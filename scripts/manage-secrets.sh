#!/bin/bash
# Manage Ludora environment variables and secrets

set -e

echo "🔐 Ludora Secrets Management"
echo "============================"

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
ACTION=""
APP=""
SECRET_NAME=""
SECRET_VALUE=""
SECRET_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        list|ls)
            ACTION="list"
            shift
            ;;
        set|add)
            ACTION="set"
            SECRET_NAME="$2"
            SECRET_VALUE="$3"
            shift 3
            ;;
        unset|remove|rm)
            ACTION="unset"
            SECRET_NAME="$2"
            shift 2
            ;;
        import)
            ACTION="import"
            SECRET_FILE="$2"
            shift 2
            ;;
        export)
            ACTION="export"
            SECRET_FILE="$2"
            shift 2
            ;;
        --app|-a)
            APP="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [ACTION] [OPTIONS]"
            echo ""
            echo "Manage environment variables and secrets for Ludora services"
            echo ""
            echo "Actions:"
            echo "  list, ls                    List all secrets"
            echo "  set NAME VALUE              Set a secret"
            echo "  unset NAME                  Remove a secret"
            echo "  import FILE                 Import secrets from file"
            echo "  export FILE                 Export secrets to file"
            echo ""
            echo "Options:"
            echo "  --app, -a APP              Target specific app (api|frontend)"
            echo "  --help, -h                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 list -a api                           # List API secrets"
            echo "  $0 set DATABASE_URL 'postgres://...' -a api  # Set database URL"
            echo "  $0 unset OLD_SECRET -a api               # Remove a secret"
            echo "  $0 import secrets.env -a api             # Import from file"
            echo ""
            echo "Common secrets to set:"
            echo "  API (ludora-api):"
            echo "    DATABASE_URL, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
            echo "    AWS_REGION, AWS_S3_BUCKET, JWT_SECRET"
            echo ""
            echo "⚠️  CAUTION: Secrets are sensitive data. Handle carefully!"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to determine app name
determine_app() {
    if [ -z "$APP" ]; then
        echo "📱 Select target application:"
        echo "  1) API Server (ludora-api)"
        echo "  2) Frontend (ludora-front)"
        echo ""
        read -p "Select app (1-2): " choice

        case $choice in
            1)
                APP="ludora-api"
                ;;
            2)
                APP="ludora-front"
                ;;
            *)
                echo "❌ Invalid choice"
                exit 1
                ;;
        esac
    else
        # Normalize app names
        case $APP in
            api|backend)
                APP="ludora-api"
                ;;
            frontend|front)
                APP="ludora-front"
                ;;
            ludora-api|ludora-front)
                # Already correct
                ;;
            *)
                echo "❌ Unknown app: $APP"
                echo "Use 'api' or 'frontend'"
                exit 1
                ;;
        esac
    fi

    echo "🎯 Target app: $APP"
}

# Function to list secrets
list_secrets() {
    determine_app

    echo ""
    echo "🔍 Listing secrets for $APP..."
    echo ""

    flyctl secrets list -a "$APP"

    echo ""
    echo "💡 Set secret with: $0 set SECRET_NAME 'secret_value' -a $APP"
}

# Function to set secret
set_secret() {
    if [ -z "$SECRET_NAME" ] || [ -z "$SECRET_VALUE" ]; then
        echo "❌ Error: Both secret name and value are required"
        echo "Usage: $0 set SECRET_NAME 'secret_value'"
        exit 1
    fi

    determine_app

    echo ""
    echo "🔑 Setting secret '$SECRET_NAME' for $APP..."

    # Confirm if this is a sensitive operation
    if [[ "$SECRET_NAME" =~ (PASSWORD|SECRET|KEY|TOKEN) ]]; then
        echo "⚠️  This appears to be a sensitive secret"
        read -p "Continue? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "❌ Cancelled"
            exit 0
        fi
    fi

    flyctl secrets set "$SECRET_NAME=$SECRET_VALUE" -a "$APP"

    if [ $? -eq 0 ]; then
        echo "✅ Secret '$SECRET_NAME' set successfully!"
        echo ""
        echo "🔄 Note: Application will restart to pick up new secrets"
    else
        echo "❌ Failed to set secret"
        exit 1
    fi
}

# Function to unset secret
unset_secret() {
    if [ -z "$SECRET_NAME" ]; then
        echo "❌ Error: Secret name is required"
        echo "Usage: $0 unset SECRET_NAME"
        exit 1
    fi

    determine_app

    echo ""
    echo "🗑️  Removing secret '$SECRET_NAME' from $APP..."
    echo "⚠️  This cannot be undone!"
    read -p "Are you sure? (type 'yes' to confirm): " confirmation

    if [ "$confirmation" != "yes" ]; then
        echo "❌ Cancelled"
        exit 0
    fi

    flyctl secrets unset "$SECRET_NAME" -a "$APP"

    if [ $? -eq 0 ]; then
        echo "✅ Secret '$SECRET_NAME' removed successfully!"
        echo ""
        echo "🔄 Note: Application will restart to pick up changes"
    else
        echo "❌ Failed to remove secret"
        exit 1
    fi
}

# Function to import secrets from file
import_secrets() {
    if [ -z "$SECRET_FILE" ]; then
        echo "❌ Error: Secrets file is required"
        echo "Usage: $0 import secrets.env"
        exit 1
    fi

    if [ ! -f "$SECRET_FILE" ]; then
        echo "❌ Error: File not found: $SECRET_FILE"
        exit 1
    fi

    determine_app

    echo ""
    echo "📥 Importing secrets from '$SECRET_FILE' to $APP..."
    echo ""

    # Show preview of what will be imported
    echo "🔍 Preview of secrets to import:"
    grep -E '^[A-Z_]+=.+' "$SECRET_FILE" | sed 's/=.*/=***/' || true
    echo ""

    read -p "Continue with import? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ Import cancelled"
        exit 0
    fi

    flyctl secrets import -a "$APP" < "$SECRET_FILE"

    if [ $? -eq 0 ]; then
        echo "✅ Secrets imported successfully!"
        echo ""
        echo "🔄 Note: Application will restart to pick up new secrets"
    else
        echo "❌ Failed to import secrets"
        exit 1
    fi
}

# Function to export secrets to file
export_secrets() {
    determine_app

    if [ -z "$SECRET_FILE" ]; then
        SECRET_FILE="secrets-$APP-$(date +%Y%m%d-%H%M%S).env"
    fi

    echo ""
    echo "📤 Exporting secrets from $APP to '$SECRET_FILE'..."
    echo "⚠️  WARNING: This will create a file with sensitive data!"
    echo ""

    read -p "Continue with export? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ Export cancelled"
        exit 0
    fi

    # Get secrets list and create template file
    echo "# Exported secrets from $APP on $(date)" > "$SECRET_FILE"
    echo "# WARNING: This file contains sensitive data!" >> "$SECRET_FILE"
    echo "" >> "$SECRET_FILE"

    # Export secret names (values will need to be filled manually)
    flyctl secrets list -a "$APP" --json | grep -o '"name":"[^"]*"' | sed 's/"name":"\([^"]*\)"/\1=/' >> "$SECRET_FILE"

    echo "✅ Secret template exported to '$SECRET_FILE'"
    echo ""
    echo "📝 Note: Secret values are not exported for security."
    echo "   Edit the file manually to add values before importing."
    echo ""
    echo "🔒 Remember to:"
    echo "   1. Fill in the secret values"
    echo "   2. Keep the file secure"
    echo "   3. Delete it after use"
}

# Show current status
echo "🏢 User: $(flyctl auth whoami 2>/dev/null || echo 'Unknown')"
echo "📅 Date: $(date '+%Y-%m-%d %H:%M:%S')"

# If no action specified, show menu
if [ -z "$ACTION" ]; then
    echo ""
    echo "Available actions:"
    echo "  1) List secrets"
    echo "  2) Set secret"
    echo "  3) Remove secret"
    echo "  4) Import from file"
    echo "  5) Export template"
    echo ""
    read -p "Select action (1-5): " choice

    case $choice in
        1)
            ACTION="list"
            ;;
        2)
            ACTION="set"
            read -p "Secret name: " SECRET_NAME
            read -s -p "Secret value: " SECRET_VALUE
            echo ""
            ;;
        3)
            ACTION="unset"
            read -p "Secret name: " SECRET_NAME
            ;;
        4)
            ACTION="import"
            read -p "Secrets file path: " SECRET_FILE
            ;;
        5)
            ACTION="export"
            read -p "Output file (optional): " SECRET_FILE
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

# Execute the requested action
case $ACTION in
    list)
        list_secrets
        ;;
    set)
        set_secret
        ;;
    unset)
        unset_secret
        ;;
    import)
        import_secrets
        ;;
    export)
        export_secrets
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        exit 1
        ;;
esac
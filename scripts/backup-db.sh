#!/bin/bash
# Backup Ludora PostgreSQL database

set -e

echo "💾 Ludora Database Backup Utility"
echo "================================="

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
ACTION="create"
BACKUP_ID=""
LIST_ONLY=false
DOWNLOAD_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        create|backup)
            ACTION="create"
            shift
            ;;
        list|ls)
            ACTION="list"
            shift
            ;;
        download|get)
            ACTION="download"
            BACKUP_ID="$2"
            shift 2
            ;;
        restore)
            ACTION="restore"
            BACKUP_ID="$2"
            shift 2
            ;;
        --output|-o)
            DOWNLOAD_PATH="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [ACTION] [OPTIONS]"
            echo ""
            echo "Backup and restore Ludora PostgreSQL database"
            echo ""
            echo "Actions:"
            echo "  create, backup       Create a new backup"
            echo "  list, ls             List all backups"
            echo "  download ID          Download backup by ID"
            echo "  restore ID           Restore from backup ID"
            echo ""
            echo "Options:"
            echo "  --output, -o PATH    Download path for backup file"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 create                              # Create new backup"
            echo "  $0 list                                # List all backups"
            echo "  $0 download backup-123 -o ./backup/   # Download specific backup"
            echo "  $0 restore backup-123                 # Restore from backup"
            echo ""
            echo "⚠️  CAUTION: Restore operations will overwrite the current database!"
            exit 0
            ;;
        *)
            if [ "$ACTION" = "download" ] && [ -z "$BACKUP_ID" ]; then
                BACKUP_ID="$1"
                shift
            elif [ "$ACTION" = "restore" ] && [ -z "$BACKUP_ID" ]; then
                BACKUP_ID="$1"
                shift
            else
                echo "❌ Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
done

# Function to create backup
create_backup() {
    echo "📦 Creating new database backup..."
    echo ""

    BACKUP_RESULT=$(flyctl postgres backup create -a ludora-db)

    if [ $? -eq 0 ]; then
        echo "✅ Backup created successfully!"
        echo ""
        echo "📋 Backup Details:"
        echo "$BACKUP_RESULT"
        echo ""
        echo "💡 List all backups with: $0 list"
    else
        echo "❌ Backup creation failed!"
        exit 1
    fi
}

# Function to list backups
list_backups() {
    echo "📋 Listing all database backups..."
    echo ""

    flyctl postgres backup list -a ludora-db

    echo ""
    echo "💡 Download backup with: $0 download <backup-id>"
    echo "💡 Restore backup with: $0 restore <backup-id>"
}

# Function to download backup
download_backup() {
    if [ -z "$BACKUP_ID" ]; then
        echo "❌ Error: Backup ID is required for download"
        echo "Use: $0 list to see available backups"
        exit 1
    fi

    echo "⬇️  Downloading backup: $BACKUP_ID"

    # Set default download path if not specified
    if [ -z "$DOWNLOAD_PATH" ]; then
        DOWNLOAD_PATH="./backup-$(date +%Y%m%d-%H%M%S).sql"
    fi

    # Create directory if it doesn't exist
    DOWNLOAD_DIR=$(dirname "$DOWNLOAD_PATH")
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir -p "$DOWNLOAD_DIR"
        echo "📁 Created directory: $DOWNLOAD_DIR"
    fi

    echo "📁 Download path: $DOWNLOAD_PATH"
    echo ""

    flyctl postgres backup download "$BACKUP_ID" -a ludora-db -o "$DOWNLOAD_PATH"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Backup downloaded successfully!"
        echo "📄 File: $DOWNLOAD_PATH"

        # Show file size
        if [ -f "$DOWNLOAD_PATH" ]; then
            FILE_SIZE=$(ls -lh "$DOWNLOAD_PATH" | awk '{print $5}')
            echo "📏 Size: $FILE_SIZE"
        fi
    else
        echo "❌ Download failed!"
        exit 1
    fi
}

# Function to restore backup
restore_backup() {
    if [ -z "$BACKUP_ID" ]; then
        echo "❌ Error: Backup ID is required for restore"
        echo "Use: $0 list to see available backups"
        exit 1
    fi

    echo "⚠️  WARNING: This will restore the database from backup!"
    echo "🗄️  Backup ID: $BACKUP_ID"
    echo "🚨 This will OVERWRITE the current database!"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

    if [ "$confirmation" != "yes" ]; then
        echo "❌ Restore cancelled"
        exit 0
    fi

    echo ""
    echo "🔄 Restoring database from backup: $BACKUP_ID"
    echo "⏳ This may take several minutes..."
    echo ""

    flyctl postgres backup restore "$BACKUP_ID" -a ludora-db

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Database restored successfully!"
        echo ""
        echo "🔍 Verify the restore with:"
        echo "  $0 connect"
        echo "  SELECT COUNT(*) FROM \"user\";"
    else
        echo "❌ Restore failed!"
        exit 1
    fi
}

# Show current backup status
echo "📊 Database Backup Status"
echo "------------------------"
echo "🗄️  Database: ludora-db"
echo "📅 Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Execute the requested action
case $ACTION in
    create)
        create_backup
        ;;
    list)
        list_backups
        ;;
    download)
        download_backup
        ;;
    restore)
        restore_backup
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

echo ""
echo "💡 Additional backup commands:"
echo "  Create:   $0 create"
echo "  List:     $0 list"
echo "  Download: $0 download <backup-id>"
echo "  Restore:  $0 restore <backup-id>"
# Ludora Utils

Shared utilities, documentation, and management scripts for the Ludora educational gaming platform.

## Overview

This repository contains:
- **📋 Documentation**: Platform documentation, deployment guides, and operational procedures
- **🔧 Scripts**: Management scripts for deployment, monitoring, and maintenance
- **🛠️ Tools**: Utilities for development and operations

## Quick Start

### Using the Main Management Script

All operations can be performed through the main `ludora.sh` script:

```bash
# From ludora-utils directory
./scripts/ludora.sh

# From parent ludora directory
./ludora-utils/scripts/ludora.sh

# Common operations
./scripts/ludora.sh deploy-api
./scripts/ludora.sh deploy-frontend
./scripts/ludora.sh status
./scripts/ludora.sh logs api
```

### Direct Script Usage

You can also run scripts directly from any location:

```bash
# From ludora-utils/scripts
./deploy-api.sh
./deploy-frontend.sh

# From ludora-utils
./scripts/deploy-api.sh

# From parent ludora directory
./ludora-utils/scripts/deploy-api.sh
```

## Repository Structure

```
ludora-utils/
├── README.md                    # This file
├── docs/                        # Documentation
│   └── fly-io-deployment-guide.md  # Comprehensive deployment guide
└── scripts/                     # Management scripts
    ├── README.md                # Scripts documentation
    ├── ludora.sh               # Main management interface
    ├── deploy-api.sh           # Deploy API server
    ├── deploy-frontend.sh      # Deploy frontend
    ├── ssh-api.sh              # SSH to API server
    ├── ssh-frontend.sh         # SSH to frontend server
    ├── connect-db.sh           # Database connection
    ├── logs.sh                 # Log viewing
    ├── status.sh               # Status checking
    ├── health-check.sh         # Health monitoring
    ├── backup-db.sh            # Database backup
    ├── manage-secrets.sh       # Secrets management
    └── run-adminer-*.sh        # Database admin tools
```

## Platform Architecture

The Ludora platform consists of:

- **ludora-api**: Node.js backend API server
- **ludora-front**: React/Vite frontend application
- **ludora-db**: PostgreSQL database cluster
- **ludora-utils**: This repository (shared utilities)

All applications are deployed on Fly.io infrastructure.

## Prerequisites

### Required Tools

- **Fly.io CLI**: `brew install flyctl`
- **PostgreSQL Client**: `brew install postgresql`
- **curl**: Usually pre-installed

### Authentication

1. Login to Fly.io:
```bash
flyctl auth login
```

2. Verify access to Ludora apps:
```bash
flyctl apps list
```

## Available Scripts

### 📦 Deployment

- `deploy-api.sh` - Deploy API server
- `deploy-frontend.sh` - Deploy frontend application

### 🔌 Access & Monitoring

- `ssh-api.sh` - SSH into API server
- `ssh-frontend.sh` - SSH into frontend server
- `connect-db.sh` - Connect to PostgreSQL database
- `logs.sh` - View service logs
- `status.sh` - Check service status
- `health-check.sh` - Comprehensive health monitoring

### 🗄️ Database Operations

- `backup-db.sh` - Database backup and restore
- `run-adminer-*.sh` - Database administration tools

### 🔐 Configuration

- `manage-secrets.sh` - Environment variables and secrets management

See `scripts/README.md` for detailed documentation on each script.

## Usage Examples

### Deployment Workflow

```bash
# Check current status
./scripts/ludora.sh health-check

# Deploy API changes
./scripts/ludora.sh deploy-api

# Deploy frontend changes
./scripts/ludora.sh deploy-frontend

# Verify deployment
./scripts/ludora.sh status --health
```

### Troubleshooting

```bash
# Check service status
./scripts/ludora.sh status

# View real-time logs
./scripts/ludora.sh logs api --follow

# SSH for investigation
./scripts/ludora.sh ssh-api

# Run health diagnostics
./scripts/ludora.sh health-check --detailed
```

### Database Management

```bash
# Create backup
./scripts/ludora.sh backup-db create

# Connect to database
./scripts/ludora.sh connect-db

# Manage environment variables
./scripts/ludora.sh manage-secrets list --app api
```

## Path Resolution

The scripts automatically detect the correct paths to `ludora-api` and `ludora-front` directories:

- Works from `ludora-utils/scripts/` directory
- Works from `ludora-utils/` directory
- Works from parent `ludora/` directory
- Searches common relative paths automatically

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **fly-io-deployment-guide.md**: Complete deployment and operations guide
- **scripts/README.md**: Detailed script documentation

## Development

### Adding New Scripts

1. Create script in `scripts/` directory
2. Follow existing naming conventions
3. Add comprehensive help with `--help` flag
4. Include error handling and path resolution
5. Update documentation
6. Make executable: `chmod +x script-name.sh`

### Path Resolution Pattern

New scripts should use this pattern for finding project directories:

```bash
# Find the target directory
TARGET_ROOT=""
if [ -f "../target-dir/package.json" ]; then
    TARGET_ROOT=".."
elif [ -f "../../target-dir/package.json" ]; then
    TARGET_ROOT="../.."
elif [ -f "target-dir/package.json" ]; then
    TARGET_ROOT="."
else
    echo "❌ Error: Cannot find target-dir directory"
    exit 1
fi

cd "$TARGET_ROOT/target-dir"
```

## Contributing

1. Clone this repository alongside `ludora-api` and `ludora-front`
2. Make changes to scripts or documentation
3. Test thoroughly from different directory locations
4. Commit and push changes
5. Update both API and frontend repos to reference new versions if needed

## Support

For issues or questions:

1. Check the comprehensive deployment guide in `docs/`
2. Use script help: `./script-name.sh --help`
3. Run health checks: `./scripts/ludora.sh health-check`
4. View logs: `./scripts/ludora.sh logs [service]`

## License

Part of the Ludora educational gaming platform.
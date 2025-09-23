# Ludora Management Scripts

This directory contains management scripts for the Ludora platform deployed on Fly.io.

## Quick Start

Use the main management script for all operations:

```bash
# Show all available commands
./scripts/ludora.sh

# Deploy services
./scripts/ludora.sh deploy-api
./scripts/ludora.sh deploy-frontend

# Check status
./scripts/ludora.sh status
./scripts/ludora.sh health-check

# View logs
./scripts/ludora.sh logs api
./scripts/ludora.sh logs frontend

# SSH access
./scripts/ludora.sh ssh-api
./scripts/ludora.sh ssh-frontend

# Database operations
./scripts/ludora.sh connect-db
./scripts/ludora.sh backup-db

# Manage secrets
./scripts/ludora.sh manage-secrets
```

## Available Scripts

### 📦 Deployment Scripts

**`deploy-api.sh`** - Deploy the Ludora API server
```bash
./scripts/deploy-api.sh [OPTIONS]
  --detach, -d      Deploy in background
  --no-cache        Force rebuild without cache
  --local-only      Build locally instead of remote
```

**`deploy-frontend.sh`** - Deploy the Ludora frontend
```bash
./scripts/deploy-frontend.sh [OPTIONS]
  --detach, -d      Deploy in background
  --no-cache        Force rebuild without cache
  --local-only      Build locally instead of remote
```

### 🔌 Access Scripts

**`ssh-api.sh`** - SSH into the API server
```bash
./scripts/ssh-api.sh [OPTIONS]
  --machine, -m ID  Connect to specific machine
  --command, -c CMD Run command instead of interactive shell
```

**`ssh-frontend.sh`** - SSH into the frontend server
```bash
./scripts/ssh-frontend.sh [OPTIONS]
  --machine, -m ID  Connect to specific machine
  --command, -c CMD Run command instead of interactive shell
```

**`connect-db.sh`** - Connect to PostgreSQL database
```bash
./scripts/connect-db.sh [OPTIONS]
  --port, -p PORT   Local port for proxy (default: 5433)
  --database, -d DB Database name (default: postgres)
  --user, -U USER   Username (default: postgres)
  --command, -c CMD Run SQL command instead of interactive
  --no-proxy        Skip proxy setup (use existing connection)
```

### 📋 Monitoring Scripts

**`logs.sh`** - View service logs
```bash
./scripts/logs.sh [SERVICE] [OPTIONS]
  api, backend      View API server logs
  frontend, front   View frontend server logs
  db, database      View database logs
  --follow, -f      Follow logs in real-time
  --since, -s TIME  Show logs since time (e.g., '2h', '30m')
  --instance, -i ID Show logs from specific instance
```

**`status.sh`** - Check service status
```bash
./scripts/status.sh [OPTIONS]
  --detailed, -d    Show detailed machine information
  --health, -H      Run health checks on services
  --json, -j        Output in JSON format
```

**`health-check.sh`** - Comprehensive health check
```bash
./scripts/health-check.sh [OPTIONS]
  --quick, -q       Quick check (essential services only)
  --detailed, -d    Detailed check with additional tests
  --skip-external   Skip external service checks
```

### 🗄️ Database Scripts

**`backup-db.sh`** - Database backup operations
```bash
./scripts/backup-db.sh [ACTION] [OPTIONS]
  create, backup    Create a new backup
  list, ls          List all backups
  download ID       Download backup by ID
  restore ID        Restore from backup ID
  --output, -o PATH Download path for backup file
```

### 🔐 Configuration Scripts

**`manage-secrets.sh`** - Manage environment variables and secrets
```bash
./scripts/manage-secrets.sh [ACTION] [OPTIONS]
  list, ls          List all secrets
  set NAME VALUE    Set a secret
  unset NAME        Remove a secret
  import FILE       Import secrets from file
  export FILE       Export secrets to file
  --app, -a APP     Target specific app (api|frontend)
```

### 🎮 Main Script

**`ludora.sh`** - Main management interface
```bash
./scripts/ludora.sh [COMMAND] [OPTIONS]
```

This script provides a unified interface to all other scripts.

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

### Environment Variables

For database operations, set the password:
```bash
export PGPASSWORD="your-database-password"
```

## Common Workflows

### 🚀 Deployment Workflow

```bash
# Check current status
./scripts/ludora.sh health-check

# Deploy API
./scripts/ludora.sh deploy-api

# Deploy frontend
./scripts/ludora.sh deploy-frontend

# Verify deployment
./scripts/ludora.sh status --health
```

### 🔍 Troubleshooting Workflow

```bash
# Check overall status
./scripts/ludora.sh status

# View logs for problematic service
./scripts/ludora.sh logs api --follow

# SSH into service for investigation
./scripts/ludora.sh ssh-api

# Run comprehensive health check
./scripts/ludora.sh health-check --detailed
```

### 🗄️ Database Maintenance

```bash
# Create backup
./scripts/ludora.sh backup-db create

# List existing backups
./scripts/ludora.sh backup-db list

# Connect to database
./scripts/ludora.sh connect-db

# Run database migrations (from ludora-api directory)
cd ludora-api && npm run db:migrate
```

### 🔐 Secrets Management

```bash
# List current secrets
./scripts/ludora.sh manage-secrets list --app api

# Set a new secret
./scripts/ludora.sh manage-secrets set AWS_SECRET_KEY "value" --app api

# Import secrets from file
./scripts/ludora.sh manage-secrets import secrets.env --app api
```

## Application URLs

- **Frontend**: https://ludora-front.fly.dev
- **API**: https://ludora-api.fly.dev
- **API Health**: https://ludora-api.fly.dev/health

## File Structure

```
scripts/
├── README.md              # This file
├── ludora.sh              # Main management script
├── deploy-api.sh          # API deployment
├── deploy-frontend.sh     # Frontend deployment
├── ssh-api.sh             # SSH to API server
├── ssh-frontend.sh        # SSH to frontend server
├── connect-db.sh          # Database connection
├── logs.sh                # Log viewing
├── status.sh              # Status checking
├── health-check.sh        # Health monitoring
├── backup-db.sh           # Database backup
├── manage-secrets.sh      # Secrets management
├── run-adminer-dev.sh     # Database admin (dev)
├── run-adminer-prod.sh    # Database admin (prod)
└── run-adminer-staging.sh # Database admin (staging)
```

## Script Features

### Error Handling
- All scripts use `set -e` for early exit on errors
- Comprehensive error messages with troubleshooting hints
- Input validation and safety checks

### Help System
- Every script supports `--help` flag
- Detailed usage examples
- Common use cases documented

### Safety Features
- Confirmation prompts for destructive operations
- Backup verification before restores
- Environment validation

### User Experience
- Colored output for better readability
- Progress indicators for long operations
- Detailed logging and feedback

## Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
chmod +x scripts/*.sh
```

**2. Fly.io Not Authenticated**
```bash
flyctl auth login
```

**3. Database Connection Failed**
```bash
# Start database proxy first
flyctl proxy 5433:5432 -a ludora-db &
export PGPASSWORD="your-password"
./scripts/ludora.sh connect-db
```

**4. Script Not Found**
```bash
# Run from project root directory
cd /path/to/ludora
./scripts/ludora.sh
```

### Getting Help

1. Use `--help` flag on any script
2. Check the comprehensive deployment guide in `/docs/fly-io-deployment-guide.md`
3. View logs for specific services
4. Run health checks to identify issues

## Contributing

When adding new scripts:

1. Follow the existing naming convention
2. Add comprehensive help text with `--help`
3. Include error handling and validation
4. Update this README
5. Make the script executable: `chmod +x script-name.sh`
6. Test thoroughly before committing
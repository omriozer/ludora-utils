# Ludora Platform - Fly.io Deployment Guide

## Overview

The Ludora educational gaming platform is deployed on Fly.io with the following architecture:

- **Frontend**: React/Vite application served via Nginx
- **Backend**: Node.js API server
- **Database**: PostgreSQL cluster
- **File Storage**: AWS S3 integration

## Applications Overview

### 1. ludora-api (Backend API)
- **URL**: https://ludora-api.fly.dev
- **App ID**: `ludora-api`
- **Region**: ORD (Chicago)
- **Stack**: Node.js 20 + Alpine Linux
- **Database**: PostgreSQL (ludora-db)
- **Storage**: AWS S3 (ludora-files bucket)

### 2. ludora-front (Frontend)
- **URL**: https://ludora-front.fly.dev
- **App ID**: `ludora-front`
- **Region**: ORD (Chicago)
- **Stack**: Nginx Alpine serving static React build
- **API Connection**: Points to ludora-api.fly.dev

### 3. ludora-db (Database)
- **App ID**: `ludora-db`
- **Type**: PostgreSQL Cluster
- **Region**: ORD (Chicago)
- **Connection**: Internal Fly.io network + external proxy

## Installation & Setup

### Prerequisites

1. Install Fly.io CLI:
```bash
# macOS
brew install flyctl

# Other platforms: https://fly.io/docs/flyctl/install/
```

2. Login to Fly.io:
```bash
flyctl auth login
```

3. Verify access to Ludora organization:
```bash
flyctl orgs list
```

## Deployment Commands

### Backend API Deployment

```bash
# Navigate to API directory
cd ludora-api

# Deploy backend
flyctl deploy

# Deploy with specific options
flyctl deploy --detach              # Deploy in background
flyctl deploy --no-cache           # Force rebuild without cache
flyctl deploy --local-only         # Build locally instead of remote
```

### Frontend Deployment

```bash
# Navigate to frontend directory
cd ludora-front

# Deploy frontend
flyctl deploy

# The build process:
# 1. npm ci (install dependencies)
# 2. npm run build (create production build)
# 3. Copy dist/ to nginx html directory
# 4. Deploy to Fly.io
```

### Database Management

```bash
# Check database status
flyctl status -a ludora-db

# Connect to database via proxy (for local development)
flyctl proxy 5433:5432 -a ludora-db

# Then connect using psql:
PGPASSWORD=your_password psql -h localhost -p 5433 -U postgres -d postgres

# Run database migrations (from ludora-api directory)
npm run db:migrate

# Setup database from scratch
./scripts/setup-db.sh production setup
```

## SSH Access & Debugging

### SSH into Applications

```bash
# SSH into backend API server
flyctl ssh console -a ludora-api

# SSH into frontend server
flyctl ssh console -a ludora-front

# SSH with specific machine ID
flyctl ssh console -a ludora-api -s <machine-id>
```

### Useful SSH Commands

```bash
# Check application logs from inside container
tail -f /app/logs/app.log

# Check nginx logs (frontend only)
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log

# Check running processes
ps aux

# Check disk usage
df -h

# Check memory usage
free -m

# Check environment variables
env | grep -E "(DATABASE|AWS|NODE)"
```

## Monitoring & Logs

### View Application Logs

```bash
# Real-time logs for backend
flyctl logs -a ludora-api

# Real-time logs for frontend
flyctl logs -a ludora-front

# Historical logs
flyctl logs -a ludora-api --since="2h"

# Filter logs by instance
flyctl logs -a ludora-api -i <instance-id>
```

### Application Metrics

```bash
# Check application status
flyctl status -a ludora-api
flyctl status -a ludora-front
flyctl status -a ludora-db

# Check resource usage
flyctl vm status -a ludora-api

# Monitor deployment
flyctl monitor -a ludora-api
```

## Configuration Management

### Environment Variables

```bash
# List environment variables
flyctl secrets list -a ludora-api

# Set environment variables
flyctl secrets set DATABASE_URL="postgresql://..." -a ludora-api
flyctl secrets set AWS_ACCESS_KEY_ID="..." -a ludora-api
flyctl secrets set AWS_SECRET_ACCESS_KEY="..." -a ludora-api

# Remove environment variable
flyctl secrets unset VARIABLE_NAME -a ludora-api
```

### Configuration Files

Each application has a `fly.toml` configuration file:

```toml
# ludora-api/fly.toml
app = "ludora-api"
primary_region = "ord"

[build]

[env]
  NODE_ENV = "production"
  PORT = "3003"

[http_service]
  internal_port = 3003
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 1024
```

## Database Operations

### Connection Details

```bash
# Internal connection (from ludora-api)
DATABASE_URL=postgres://postgres:password@ludora-db.flycast:5432/postgres

# External connection (via proxy)
flyctl proxy 5433:5432 -a ludora-db
# Then: postgres://postgres:password@localhost:5433/postgres
```

### Common Database Tasks

```bash
# Run migrations
cd ludora-api
npm run db:migrate

# Check migration status
flyctl ssh console -a ludora-api
cd /app && npm run db:status

# Backup database
flyctl postgres backup create -a ludora-db

# List backups
flyctl postgres backup list -a ludora-db

# Restore from backup
flyctl postgres backup restore <backup-id> -a ludora-db
```

### Manual Database Setup

If you need to recreate the database from scratch:

```bash
# 1. Connect via proxy
flyctl proxy 5433:5432 -a ludora-db

# 2. Connect to database
PGPASSWORD=your_password psql -h localhost -p 5433 -U postgres -d postgres

# 3. Run setup script (from ludora-api directory)
./scripts/setup-db.sh production setup

# 4. Verify tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
```

## File Storage (AWS S3)

### S3 Configuration

The backend uses AWS S3 for file storage:

```bash
# Set S3 environment variables
flyctl secrets set AWS_REGION=eu-central-1 -a ludora-api
flyctl secrets set AWS_S3_BUCKET=ludora-files -a ludora-api
flyctl secrets set AWS_ACCESS_KEY_ID="your-key" -a ludora-api
flyctl secrets set AWS_SECRET_ACCESS_KEY="your-secret" -a ludora-api
```

### Test S3 Connection

```bash
# SSH into backend
flyctl ssh console -a ludora-api

# Test S3 upload
cd /app && node -e "
import('./services/FileService.js').then(async ({ default: fileService }) => {
  try {
    const testFile = {
      buffer: Buffer.from('Hello S3!'),
      originalname: 'test.txt',
      mimetype: 'text/plain'
    };
    const result = await fileService.uploadFile({
      file: testFile,
      folder: 'test',
      userId: 'test-user'
    });
    console.log('✅ S3 Upload Success:', result);
  } catch (error) {
    console.error('❌ S3 Upload Failed:', error.message);
  }
});
"
```

## Scaling & Performance

### Horizontal Scaling

```bash
# Scale backend API (add more instances)
flyctl scale count 2 -a ludora-api

# Scale to specific regions
flyctl scale count ord=1 sjc=1 -a ludora-api

# Scale frontend
flyctl scale count 2 -a ludora-front
```

### Vertical Scaling

```bash
# Scale backend resources
flyctl scale vm shared-cpu-2x --memory 2048 -a ludora-api

# Scale frontend resources
flyctl scale vm shared-cpu-1x --memory 512 -a ludora-front
```

### Auto-scaling Configuration

In `fly.toml`:

```toml
[http_service]
  auto_stop_machines = false    # Keep machines running
  auto_start_machines = true    # Auto-start stopped machines
  min_machines_running = 1      # Minimum instances
  max_machines_running = 5      # Maximum instances (if using auto-scaling)
```

## Troubleshooting

### Common Issues

**1. Database Connection Issues**
```bash
# Check database status
flyctl status -a ludora-db

# Check if database is accepting connections
flyctl ssh console -a ludora-api
cd /app && npm run db:test
```

**2. API Not Responding**
```bash
# Check API health
curl https://ludora-api.fly.dev/health

# Check API logs
flyctl logs -a ludora-api

# Check API status
flyctl status -a ludora-api
```

**3. Frontend Not Loading**
```bash
# Check frontend status
flyctl status -a ludora-front

# Check nginx configuration
flyctl ssh console -a ludora-front
cat /etc/nginx/conf.d/default.conf
```

**4. SSL Certificate Issues**
```bash
# Check certificate status
flyctl certs show ludora-api.fly.dev

# Force certificate renewal
flyctl certs refresh ludora-api.fly.dev
```

### Performance Monitoring

```bash
# Check resource usage
flyctl vm status -a ludora-api

# Monitor in real-time
flyctl monitor -a ludora-api

# Check metrics via Grafana
# Visit: https://fly.io/apps/ludora-api/monitoring
```

## Backup & Recovery

### Database Backups

```bash
# Create manual backup
flyctl postgres backup create -a ludora-db

# Automated backups are enabled by default
flyctl postgres backup list -a ludora-db

# Download backup
flyctl postgres backup download <backup-id> -a ludora-db
```

### Code Deployment Rollback

```bash
# List deployment history
flyctl releases -a ludora-api

# Rollback to previous version
flyctl releases rollback -a ludora-api

# Deploy specific version
flyctl deploy --image registry.fly.io/ludora-api:deployment-<id> -a ludora-api
```

### File Storage Backup

S3 files are automatically backed up by AWS. You can also:

```bash
# Sync S3 bucket locally (requires AWS CLI)
aws s3 sync s3://ludora-files ./local-backup/
```

## Cost Management

### Monitor Usage

```bash
# Check current usage
flyctl platform regions

# View billing information
flyctl dashboard billing
```

### Cost Optimization

1. **Auto-stop unused machines**: Set `auto_stop_machines = true`
2. **Right-size VMs**: Use smallest VM that meets performance needs
3. **Database optimization**: Regular cleanup and indexing
4. **CDN for static assets**: Consider using Fly.io's CDN for frontend assets

## Security Best Practices

### Secrets Management

```bash
# Use secrets for sensitive data
flyctl secrets set DATABASE_PASSWORD="..." -a ludora-api

# Avoid putting secrets in fly.toml
flyctl secrets import -a ludora-api < secrets.txt
```

### Network Security

- All traffic is HTTPS by default
- Database uses internal Fly.io network (flycast)
- API endpoints have proper authentication
- CORS is configured for frontend domain only

### Access Control

```bash
# Manage team access
flyctl orgs members -o <org-name>

# Add team member
flyctl orgs invite -o <org-name> user@example.com
```

## Development Workflow

### Local Development

1. **API**: Run `npm run start:dev` (connects to local DB)
2. **Frontend**: Run `npm run dev` (connects to local API)
3. **Database**: Use Docker PostgreSQL or connect to staging

### Staging Environment

You can create staging apps:

```bash
# Create staging API
flyctl app create ludora-api-staging

# Deploy to staging
flyctl deploy -a ludora-api-staging

# Set staging environment variables
flyctl secrets set NODE_ENV=staging -a ludora-api-staging
```

### Production Deployment Checklist

- [ ] Run tests locally: `npm test`
- [ ] Check environment variables are set
- [ ] Verify database migrations work: `npm run db:migrate`
- [ ] Deploy backend: `flyctl deploy -a ludora-api`
- [ ] Deploy frontend: `flyctl deploy -a ludora-front`
- [ ] Test health endpoints
- [ ] Verify critical functionality works

## Contact & Support

- **Fly.io Support**: https://fly.io/docs/
- **Project Repository**: Internal Ludora repository
- **Deployment Owner**: Omri (project maintainer)

For issues with this deployment, first check the logs, then try the troubleshooting steps above. If problems persist, contact the project maintainer with relevant log outputs and error messages.
# Ludora Platform - Vercel + Render Deployment Guide

## 🚀 Overview

This guide covers the complete deployment process for the Ludora educational gaming platform using the new Vercel + Render architecture. This replaces the previous Fly.io deployment.

**New Architecture**:
- **Frontend**: React/Vite application deployed on Vercel
- **Backend**: Node.js API deployed on Render Web Service
- **Database**: PostgreSQL managed database on Render
- **File Storage**: AWS S3 integration (unchanged)

**Production URLs**:
- **Frontend**: https://ludora.app
- **Backend API**: https://api.ludora.app/api
- **Database**: Render managed PostgreSQL

---

## 📋 Prerequisites

### Required Tools
1. **Vercel CLI**: Install with `npm install -g vercel`
2. **Render CLI**: Install with `npm install -g @render/cli` (optional)
3. **Git**: For repository management
4. **Node.js 20+**: For local development
5. **PostgreSQL Client**: For database operations

### Required Accounts
1. **Vercel Account**: Connected to GitHub repository
2. **Render Account**: For backend and database hosting
3. **AWS Account**: For S3 file storage
4. **Firebase Project**: For authentication

### Repository Access
- GitHub repository with appropriate permissions
- Environment-specific branches (main, staging, development)

---

## 🗄️ Database Setup (Render PostgreSQL)

### 1. Create PostgreSQL Instance

#### Production Database
1. Log in to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" → "PostgreSQL"
3. Configure:
   - **Name**: `ludora-production-db`
   - **Region**: Choose optimal region (US East recommended)
   - **PostgreSQL Version**: Latest stable (15+)
   - **Plan**: Choose based on requirements
4. Click "Create Database"
5. **Save Connection Details**:
   - Internal Database URL
   - External Database URL
   - Database Name, User, Password

#### Staging Database
Repeat the process with:
- **Name**: `ludora-staging-db`
- **Plan**: Can be smaller than production

### 2. Database Migration

#### Export from Current Database
```bash
# If migrating from existing database
pg_dump -h [current_host] -U [current_user] -d [current_db] > ludora_backup.sql

# Or if using DATABASE_URL
pg_dump $DATABASE_URL > ludora_backup.sql
```

#### Import to Render
```bash
# Use the external database URL from Render
psql [RENDER_EXTERNAL_DATABASE_URL] < ludora_backup.sql
```

#### Verify Migration
```bash
# Connect to new database
psql [RENDER_EXTERNAL_DATABASE_URL]

# Check tables
\dt

# Verify data
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM files;
SELECT COUNT(*) FROM games;
```

---

## 🖥️ Backend Deployment (Render Web Service)

### 1. Create Web Service

1. In Render Dashboard, click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure:
   - **Name**: `ludora-api`
   - **Region**: Same as database
   - **Branch**: `main` (for production)
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

### 2. Environment Variables Configuration

#### Core Configuration
```bash
ENVIRONMENT=production
PORT=10000
NODE_ENV=production
```

#### Database Configuration
```bash
# Use the INTERNAL Database URL from Render PostgreSQL
DATABASE_URL=postgresql://ludora_user:password@dpg-xxx-a.render.com:5432/ludora_production

# Fallback individual settings
DB_HOST=dpg-xxx-a.render.com
DB_PORT=5432
DB_NAME=ludora_production
DB_USER=ludora_user
DB_PASSWORD=[secure_password]
```

#### Authentication & Security
```bash
# Generate secure values:
# JWT_SECRET: openssl rand -base64 64
# API_KEY: openssl rand -hex 32
# ENCRYPTION_KEY: openssl rand -base64 32

JWT_SECRET=TSXwLpljYcmuzG6rI/8xoTQtmJlYsHTVZ+4knW+ymJO6qZJzibRNsqC6lRYjhKKYh5tTF/L/5Rr3+6CSR8QGgw==
JWT_EXPIRES_IN=24h
API_KEY=f7b714b5d664c7f631953ff910207ac4fe279f7a3a5dc3ae4374da4d06783ec2
ENCRYPTION_KEY=+UvfPsBgrObisurFcepl1k+GEd6buF/WccOokKorbCI=
```

#### Firebase Configuration
```bash
# Base64 encoded Firebase service account JSON
FIREBASE_SERVICE_ACCOUNT=ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAibHVkb3JhLWFmNzA2IiwKICAicHJpdmF0ZV9rZXlfaWQiOiAiNmI2YzM1MWM3NWUxN2ZmNGNjZWI1Nzk2Yjk2YWVmMzg2OTNlZmQ2ZCIsCi...
```

#### AWS S3 Configuration
```bash
USE_S3=true
AWS_S3_BUCKET=ludora-files
AWS_REGION=eu-central-1
AWS_ACCESS_KEY_ID=[YOUR_AWS_ACCESS_KEY]
AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_KEY]
LOCAL_STORAGE_PATH=./uploads
```

#### Payment Configuration (PayPlus)
```bash
# Production credentials
PAYPLUS_API_KEY=[YOUR_PAYPLUS_PROD_API_KEY]
PAYPLUS_SECRET_KEY=[YOUR_PAYPLUS_PROD_SECRET]
PAYPLUS_PAYMENT_PAGE_UID=[YOUR_PAYPLUS_PROD_PAGE_UID]

# Staging/Test credentials
PAYPLUS_STAGING_API_KEY=[YOUR_PAYPLUS_STAGING_API_KEY]
PAYPLUS_STAGING_SECRET_KEY=[YOUR_PAYPLUS_STAGING_SECRET]
PAYPLUS_STAGING_PAYMENT_PAGE_UID=[YOUR_PAYPLUS_STAGING_PAGE_UID]
```

#### External APIs
```bash
# Get from respective platforms
OPENAI_API_KEY=[your_openai_key]
ANTHROPIC_API_KEY=[your_anthropic_key]
DEFAULT_LLM_MODEL=gpt-3.5-turbo
```

#### Email Configuration
```bash
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=[your_email@ludora.app]
EMAIL_PASSWORD=[gmail_app_password]
DEFAULT_FROM_EMAIL=noreply@ludora.app
```

#### CORS & Frontend Configuration
```bash
# Update these to match your Vercel deployment
FRONTEND_URL=https://ludora.app
API_URL=https://api.ludora.app
ADDITIONAL_FRONTEND_URLS=https://ludora.app,https://ludora-preview.vercel.app

# Documentation
API_DOCS_URL=https://api.ludora.app/docs

# Security settings
CORS_DEV_OVERRIDE=false
DEBUG_USER=false
MAX_REQUEST_SIZE=52428800
```

### 3. Custom Domain Setup

1. In Render service settings, go to "Custom Domains"
2. Add domain: `api.ludora.app`
3. Update DNS records (see DNS section below)
4. Wait for SSL certificate provisioning

### 4. Deployment

1. Push code to main branch
2. Render will automatically build and deploy
3. Monitor deployment logs
4. Test health endpoint: `https://api.ludora.app/health`

---

## 🌐 Frontend Deployment (Vercel)

### 1. Connect Repository

1. Log in to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import from GitHub: `ludora-front` repository
4. Configure:
   - **Framework Preset**: Vite
   - **Root Directory**: `./` (or specific path if monorepo)
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`

### 2. Environment Variables

#### Production Environment
```bash
# API Configuration (pointing to new Render backend)
VITE_API_BASE=https://api.ludora.app/api

# Firebase Configuration (Production)
VITE_FIREBASE_API_KEY=AIzaSyCvc0KGxsYCu61pOwBSJ3tzdCs7lUT28JI
VITE_FIREBASE_AUTH_DOMAIN=ludora-af706.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=ludora-af706
VITE_FIREBASE_STORAGE_BUCKET=ludora-af706.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=985814078486
VITE_FIREBASE_APP_ID=1:985814078486:web:45bbbd97327171c94ad137
VITE_FIREBASE_MEASUREMENT_ID=G-THZ32X92VY
```

#### Staging Environment
Create a separate environment for staging with:
```bash
VITE_API_BASE=https://ludora-api-staging.render.com/api
# ... other staging-specific variables
```

### 3. Custom Domain Setup

1. In Vercel project settings, go to "Domains"
2. Add domain: `ludora.app`
3. Update DNS records (see DNS section below)
4. Vercel automatically provisions SSL certificate

### 4. Deployment Settings

#### Production Branch
- **Branch**: `main`
- **Automatic Deployments**: Enabled

#### Preview Deployments
- **Branch**: All branches except main
- **Automatic**: Enabled for Pull Requests

---

## 🌍 DNS Configuration

### Domain Records

#### For ludora.app (Frontend - Vercel)
```bash
# Add CNAME record
Type: CNAME
Name: @
Value: cname.vercel-dns.com
TTL: 300
```

#### For api.ludora.app (Backend - Render)
```bash
# Add CNAME record
Type: CNAME
Name: api
Value: [render-service-url].onrender.com
TTL: 300
```

### SSL Certificates
- **Vercel**: Automatic SSL via Let's Encrypt
- **Render**: Automatic SSL via Let's Encrypt
- **Verification**: Both platforms handle certificate renewal

---

## 🔐 CORS Configuration

### Backend CORS Settings

The backend must be configured to accept requests from all Vercel domains:

```javascript
// In your CORS configuration
const corsOptions = {
  origin: [
    'https://ludora.app',                    // Production
    'https://www.ludora.app',               // Production with www
    /^https:\/\/.*\.vercel\.app$/,          // All Vercel preview deployments
    'http://localhost:5173',                 // Local development
    'http://localhost:3000'                  // Alternative local port
  ],
  credentials: true,
  optionsSuccessStatus: 200
};
```

### Environment-Specific CORS

Use environment variables for dynamic CORS:
```bash
FRONTEND_URL=https://ludora.app
ADDITIONAL_FRONTEND_URLS=https://ludora-preview.vercel.app,https://ludora-staging.vercel.app
```

---

## 🧪 Testing & Validation

### Health Checks

#### Backend Health Check
```bash
curl https://api.ludora.app/health
# Expected: {"status":"healthy","timestamp":"2025-11-06T..."}
```

#### Frontend Health Check
```bash
curl https://ludora.app
# Expected: 200 OK with React app HTML
```

### Database Connectivity
```bash
# Test from backend service
npm run db:test

# Direct database connection test
psql $DATABASE_URL -c "SELECT NOW();"
```

### Authentication Flow
1. Test user registration
2. Test user login
3. Test JWT token validation
4. Test Firebase integration
5. Test session persistence

### File Upload Testing
1. Test S3 upload functionality
2. Test file download
3. Test file permissions
4. Verify CORS for file access

### Payment Integration
1. Test PayPlus staging environment
2. Verify webhook endpoints
3. Test payment flow end-to-end
4. Validate transaction recording

---

## 🏗️ Staging Environment

### Staging Deployment Strategy

#### Backend Staging (Render)
- **Service Name**: `ludora-api-staging`
- **Branch**: `staging` or `develop`
- **Database**: Separate staging database
- **Domain**: `api-staging.ludora.app`

#### Frontend Staging (Vercel)
- **Branch**: `staging` or `develop`
- **Environment**: Preview deployment
- **Domain**: Auto-generated Vercel URL

### Staging Testing Checklist
- [ ] Database migrations work correctly
- [ ] Environment variables are properly set
- [ ] Authentication works with staging Firebase
- [ ] API endpoints respond correctly
- [ ] File uploads work with S3
- [ ] Payment testing with staging PayPlus
- [ ] CORS allows staging frontend access

---

## 🔧 Monitoring & Maintenance

### Application Monitoring

#### Render Monitoring
- Service metrics in Render dashboard
- Resource usage monitoring
- Deployment history tracking
- Log aggregation and search

#### Vercel Monitoring
- Build and deployment metrics
- Frontend performance monitoring
- Core Web Vitals tracking
- Error boundary reporting

### Database Monitoring
- Connection pool monitoring
- Query performance analysis
- Storage usage tracking
- Backup verification

### Log Management

#### Backend Logs (Render)
```bash
# View live logs (if Render CLI installed)
render logs ludora-api

# Or view in dashboard
# https://dashboard.render.com/web/[service-id]/logs
```

#### Frontend Logs (Vercel)
```bash
# View deployment logs
vercel logs ludora-app

# Or view in dashboard
# https://vercel.com/[team]/ludora-app/logs
```

### Backup Strategy

#### Database Backups
- **Render Automatic**: Daily automated backups
- **Manual Backup**:
  ```bash
  pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
  ```

#### Code Backups
- **Git Repository**: Primary backup
- **Deployment History**: Available in both platforms

---

## 🚨 Troubleshooting

### Common Issues

#### 1. CORS Errors
**Symptoms**: Cross-origin request blocked errors
**Solutions**:
- Verify FRONTEND_URL environment variable
- Check ADDITIONAL_FRONTEND_URLS includes all Vercel domains
- Ensure credentials: true in CORS config

#### 2. Database Connection Issues
**Symptoms**: Database connection timeouts or authentication errors
**Solutions**:
- Verify DATABASE_URL is internal Render URL
- Check database service status
- Verify connection pooling settings
- Test direct connection with psql

#### 3. Environment Variable Issues
**Symptoms**: Configuration not loading, undefined values
**Solutions**:
- Verify all 72 backend variables are set
- Check for typos in variable names
- Ensure sensitive values are properly encoded
- Restart services after variable changes

#### 4. Build Failures
**Symptoms**: Deployment fails during build process
**Solutions**:
- Check build logs for specific errors
- Verify Node.js version compatibility
- Ensure all dependencies are in package.json
- Check for missing environment variables needed at build time

#### 5. SSL Certificate Issues
**Symptoms**: HTTPS not working, certificate warnings
**Solutions**:
- Wait for certificate propagation (up to 24 hours)
- Verify DNS records are correct
- Check domain ownership verification
- Contact platform support if issues persist

### Emergency Procedures

#### Rollback Plan
1. **DNS Revert**: Change DNS records back to previous hosting
2. **Service Restart**: Restart previous hosting services
3. **Database Sync**: Ensure data consistency
4. **Communication**: Notify users of temporary issue

#### Service Recovery
1. **Identify Issue**: Check monitoring dashboards
2. **Service Restart**: Restart affected services
3. **Health Check**: Verify all endpoints respond
4. **Monitor**: Watch for recurring issues

---

## 💰 Cost Optimization

### Render Optimization
- **Instance Sizing**: Start with smaller instances, scale as needed
- **Scaling**: Configure auto-scaling based on traffic
- **Database**: Choose appropriate plan for data size
- **Regions**: Use regions close to users

### Vercel Optimization
- **Plan Selection**: Choose plan based on usage
- **Build Optimization**: Optimize build times to reduce costs
- **Bandwidth**: Monitor and optimize for large assets
- **Preview Deployments**: Limit unnecessary preview builds

### AWS S3 Optimization
- **Storage Class**: Use appropriate storage classes
- **Lifecycle Policies**: Automatically transition old files
- **CloudFront**: Consider CDN for frequently accessed files
- **Monitoring**: Track usage and costs

---

## 📞 Support & Resources

### Platform Documentation
- **Render**: https://render.com/docs
- **Vercel**: https://vercel.com/docs
- **AWS S3**: https://docs.aws.amazon.com/s3/

### Monitoring Tools
- **Render Dashboard**: https://dashboard.render.com
- **Vercel Dashboard**: https://vercel.com/dashboard
- **AWS Console**: https://console.aws.amazon.com

### Emergency Contacts
- **Technical Lead**: Omri
- **Repository**: Internal Ludora repository
- **This Guide**: `/ludora-utils/docs/vercel-render-deployment-guide.md`
- **Migration Plan**: `/ludora-utils/docs/migration-plan.md`

---

**Last Updated**: November 6, 2025
**Version**: 1.0.0
**Migration Status**: Ready for execution
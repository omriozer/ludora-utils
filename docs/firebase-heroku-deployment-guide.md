# Ludora Platform - Firebase + Heroku Deployment Guide

## 🚀 Overview

This guide covers the complete deployment process for the Ludora educational gaming platform using the Firebase + Heroku architecture. This replaces the previous Fly.io deployment.

**Current Architecture**:
- **Frontend**: React/Vite application deployed on Firebase Hosting
- **Backend**: Node.js API deployed on Heroku
- **Database**: PostgreSQL on Heroku Postgres
- **File Storage**: AWS S3 integration (unchanged)

**Production URLs**:
- **Frontend**: https://ludora.app
- **Backend API**: https://api.ludora.app/api
- **Database**: Heroku Postgres (managed)

---

## 📋 Prerequisites

### Required Tools
1. **Firebase CLI**: Install with `npm install -g firebase-tools`
2. **Heroku CLI**: Install from [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
3. **Git**: For repository management
4. **Node.js 20+**: For local development
5. **PostgreSQL Client**: For database operations

### Required Accounts
1. **Firebase Account**: Connected to Google account with project access
2. **Heroku Account**: For backend and database hosting
3. **AWS Account**: For S3 file storage
4. **Cloudflare Account**: For DNS and CDN management

### Repository Access
- GitHub repository with appropriate permissions
- Environment-specific branches (main, staging, development)

---

## 🗄️ Database Setup (Heroku Postgres)

### 1. Create PostgreSQL Instance

#### Production Database
1. Log in to [Heroku Dashboard](https://dashboard.heroku.com)
2. Navigate to your Heroku app or click "New" → "Create new app"
3. Go to "Resources" tab
4. Search for "Heroku Postgres" and select a plan
5. Click "Submit Order Form"
6. **Save Connection Details**:
   - DATABASE_URL (automatically set as config var)
   - Connection details available in database settings

#### Staging Database
Create a separate Heroku app for staging:
- **App Name**: `ludora-api-staging`
- **Add-on**: Heroku Postgres (can be smaller plan than production)

### 2. Database Migration

#### Export from Current Database
```bash
# If migrating from existing database
pg_dump -h [current_host] -U [current_user] -d [current_db] > ludora_backup.sql

# Or if using DATABASE_URL
pg_dump $DATABASE_URL > ludora_backup.sql
```

#### Import to Heroku
```bash
# Get Heroku database URL
heroku config:get DATABASE_URL -a ludora-api-prod

# Import data to Heroku
heroku pg:psql -a ludora-api-prod < ludora_backup.sql

# Or use pg_restore for custom format
heroku pg:restore ludora_backup.sql DATABASE_URL -a ludora-api-prod
```

#### Verify Migration
```bash
# Connect to Heroku database
heroku pg:psql -a ludora-api-prod

# Check tables
\dt

# Verify data
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM files;
SELECT COUNT(*) FROM games;
```

---

## 🖥️ Backend Deployment (Heroku)

### 1. Create Heroku App

```bash
# Create production app
heroku create ludora-api-prod --region us

# Create staging app
heroku create ludora-api-staging --region us

# Add git remotes
git remote add heroku-prod https://git.heroku.com/ludora-api-prod.git
git remote add heroku-staging https://git.heroku.com/ludora-api-staging.git
```

### 2. Add Heroku Postgres

```bash
# Add Postgres to production
heroku addons:create heroku-postgresql:essential-0 -a ludora-api-prod

# Add Postgres to staging
heroku addons:create heroku-postgresql:mini -a ludora-api-staging
```

### 3. Environment Variables Configuration

#### Core Configuration
```bash
# Production settings
heroku config:set ENVIRONMENT=production -a ludora-api-prod
heroku config:set NODE_ENV=production -a ludora-api-prod
heroku config:set PORT=3003 -a ludora-api-prod
```

#### Authentication & Security
```bash
# Generate secure values (use same from previous deployment):
heroku config:set JWT_SECRET=TSXwLpljYcmuzG6rI/8xoTQtmJlYsHTVZ+4knW+ymJO6qZJzibRNsqC6lRYjhKKYh5tTF/L/5Rr3+6CSR8QGgw== -a ludora-api-prod
heroku config:set JWT_EXPIRES_IN=24h -a ludora-api-prod
heroku config:set API_KEY=f7b714b5d664c7f631953ff910207ac4fe279f7a3a5dc3ae4374da4d06783ec2 -a ludora-api-prod
heroku config:set ENCRYPTION_KEY=+UvfPsBgrObisurFcepl1k+GEd6buF/WccOokKorbCI= -a ludora-api-prod
```

#### Firebase Configuration
```bash
# Base64 encoded Firebase service account JSON
heroku config:set FIREBASE_SERVICE_ACCOUNT=ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAibHVkb3JhLWFmNzA2IiwKICAicHJpdmF0ZV9rZXlfaWQiOiAiNmI2YzM1MWM3NWUxN2ZmNGNjZWI1Nzk2Yjk2YWVmMzg2OTNlZmQ2ZCIsCi... -a ludora-api-prod
```

#### AWS S3 Configuration
```bash
heroku config:set USE_S3=true -a ludora-api-prod
heroku config:set AWS_S3_BUCKET=ludora-files -a ludora-api-prod
heroku config:set AWS_REGION=eu-central-1 -a ludora-api-prod
heroku config:set AWS_ACCESS_KEY_ID=[YOUR_AWS_ACCESS_KEY] -a ludora-api-prod
heroku config:set AWS_SECRET_ACCESS_KEY=[YOUR_AWS_SECRET_KEY] -a ludora-api-prod
heroku config:set LOCAL_STORAGE_PATH=./uploads -a ludora-api-prod
```

#### Payment Configuration (PayPlus)
```bash
# Production credentials
heroku config:set PAYPLUS_API_KEY=[YOUR_PAYPLUS_PROD_API_KEY] -a ludora-api-prod
heroku config:set PAYPLUS_SECRET_KEY=[YOUR_PAYPLUS_PROD_SECRET] -a ludora-api-prod
heroku config:set PAYPLUS_PAYMENT_PAGE_UID=[YOUR_PAYPLUS_PROD_PAGE_UID] -a ludora-api-prod

# Staging/Test credentials
heroku config:set PAYPLUS_STAGING_API_KEY=[YOUR_PAYPLUS_STAGING_API_KEY] -a ludora-api-prod
heroku config:set PAYPLUS_STAGING_SECRET_KEY=[YOUR_PAYPLUS_STAGING_SECRET] -a ludora-api-prod
heroku config:set PAYPLUS_STAGING_PAYMENT_PAGE_UID=[YOUR_PAYPLUS_STAGING_PAGE_UID] -a ludora-api-prod
```

#### External APIs
```bash
# Get from respective platforms
heroku config:set OPENAI_API_KEY=[your_openai_key] -a ludora-api-prod
heroku config:set ANTHROPIC_API_KEY=[your_anthropic_key] -a ludora-api-prod
heroku config:set DEFAULT_LLM_MODEL=gpt-3.5-turbo -a ludora-api-prod
```

#### Email Configuration
```bash
heroku config:set EMAIL_HOST=smtp.gmail.com -a ludora-api-prod
heroku config:set EMAIL_PORT=587 -a ludora-api-prod
heroku config:set EMAIL_USER=[your_email@ludora.app] -a ludora-api-prod
heroku config:set EMAIL_PASSWORD=[gmail_app_password] -a ludora-api-prod
heroku config:set DEFAULT_FROM_EMAIL=noreply@ludora.app -a ludora-api-prod
```

#### CORS & Frontend Configuration
```bash
# Update these to match your Firebase deployment
heroku config:set FRONTEND_URL=https://ludora.app -a ludora-api-prod
heroku config:set API_URL=https://api.ludora.app -a ludora-api-prod
heroku config:set ADDITIONAL_FRONTEND_URLS=https://ludora.app,https://ludora-af706.web.app -a ludora-api-prod
heroku config:set API_DOCS_URL=https://api.ludora.app/docs -a ludora-api-prod

# Security settings
heroku config:set CORS_DEV_OVERRIDE=false -a ludora-api-prod
heroku config:set DEBUG_USER=false -a ludora-api-prod
heroku config:set MAX_REQUEST_SIZE=52428800 -a ludora-api-prod
```

### 4. Custom Domain Setup

```bash
# Add custom domain to Heroku app
heroku domains:add api.ludora.app -a ludora-api-prod

# Get DNS target from Heroku
heroku domains -a ludora-api-prod
```

### 5. Deployment

```bash
# Deploy to production
git push heroku-prod main

# Deploy to staging
git push heroku-staging staging

# Run database migrations
heroku run npm run migrate:prod -a ludora-api-prod

# Check deployment
heroku ps -a ludora-api-prod
heroku logs --tail -a ludora-api-prod
```

---

## 🌐 Frontend Deployment (Firebase Hosting)

### 1. Initialize Firebase Project

```bash
# Login to Firebase
firebase login

# Initialize Firebase in project
cd ludora-front
firebase init hosting

# Configuration:
# - Use existing project: ludora-af706
# - Public directory: dist
# - Single-page app: Yes
# - Set up automatic builds with GitHub: No (we'll use GitHub Actions)
```

### 2. Environment Variables

Firebase doesn't use traditional environment variables for static sites. Instead, we'll use build-time environment variables.

#### Production Environment Variables
Create `.env.production` in ludora-front:
```bash
# API Configuration (pointing to Heroku backend)
VITE_API_BASE=https://api.ludora.app/api

# Firebase Configuration (Production)
VITE_FIREBASE_API_KEY=AIzaSyCvc0KGxsYCu61pOwBSJ3tzdCs7lUT28JI
VITE_FIREBASE_AUTH_DOMAIN=ludora.app
VITE_FIREBASE_PROJECT_ID=ludora-af706
VITE_FIREBASE_STORAGE_BUCKET=ludora-af706.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=985814078486
VITE_FIREBASE_APP_ID=1:985814078486:web:45bbbd97327171c94ad137
VITE_FIREBASE_MEASUREMENT_ID=G-THZ32X92VY
```

### 3. Custom Domain Setup

```bash
# Add custom domain in Firebase Console
# Or via CLI:
firebase hosting:sites:create ludora-main

# Connect domain
# Go to Firebase Console > Hosting > Add custom domain
# Domain: ludora.app
# Follow verification steps
```

### 4. Deployment

```bash
# Build and deploy
npm run build
firebase deploy --only hosting

# Or deploy with specific site
firebase deploy --only hosting:ludora-main

# Check deployment
firebase hosting:sites:list
```

---

## 🌍 DNS Configuration (Cloudflare)

### Domain Records

#### For ludora.app (Frontend - Firebase)
```bash
# Add CNAME record in Cloudflare
Type: CNAME
Name: @
Value: ludora-af706.web.app
TTL: Auto
Proxy status: Proxied (orange cloud)
```

#### For api.ludora.app (Backend - Heroku)
```bash
# Add CNAME record in Cloudflare
Type: CNAME
Name: api
Value: [heroku-app-name]-xxxx.herokuapp.com
TTL: Auto
Proxy status: Proxied (orange cloud)
```

### SSL Certificates
- **Firebase**: Automatic SSL via Firebase Hosting
- **Heroku**: Automatic SSL via ACM (Automated Certificate Management)
- **Cloudflare**: Additional SSL/TLS encryption and security

### Cloudflare Configuration
```bash
# SSL/TLS Settings
SSL/TLS encryption mode: Full (strict)
Always Use HTTPS: On
HTTP Strict Transport Security: Enabled

# Security Settings
Security Level: Medium
Browser Integrity Check: On
Challenge Passage: 30 minutes

# Performance Settings
Auto Minify: CSS, JS, HTML
Brotli: On
Rocket Loader: Off (can interfere with React)
```

---

## 🔐 CORS Configuration

### Backend CORS Settings

The backend must be configured to accept requests from Firebase domains and development:

```javascript
// In your CORS configuration
const corsOptions = {
  origin: [
    'https://ludora.app',                    // Production (custom domain)
    'https://ludora-af706.web.app',         // Firebase default domain
    'https://ludora-af706.firebaseapp.com', // Firebase app domain
    'http://localhost:5173',                // Local development (Vite)
    'http://localhost:3000'                 // Alternative local port
  ],
  credentials: true,
  optionsSuccessStatus: 200
};
```

### Environment-Specific CORS

Use environment variables for dynamic CORS:
```bash
FRONTEND_URL=https://ludora.app
ADDITIONAL_FRONTEND_URLS=https://ludora-af706.web.app,https://ludora-af706.firebaseapp.com
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
# Test from Heroku app
heroku run npm run db:test -a ludora-api-prod

# Direct database connection test
heroku pg:psql -a ludora-api-prod -c "SELECT NOW();"
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

#### Backend Staging (Heroku)
- **App Name**: `ludora-api-staging`
- **Branch**: `staging` or `develop`
- **Database**: Separate staging Heroku Postgres
- **Domain**: `api-staging.ludora.app` (optional)

#### Frontend Staging (Firebase)
- **Site**: Create separate Firebase hosting site
- **Branch**: `staging` or `develop`
- **Domain**: Use Firebase preview URL or custom staging domain

### Staging Testing Checklist
- [ ] Database migrations work correctly
- [ ] Environment variables are properly set
- [ ] Authentication works with Firebase
- [ ] API endpoints respond correctly
- [ ] File uploads work with S3
- [ ] Payment testing with staging PayPlus
- [ ] CORS allows frontend access

---

## 🔧 Monitoring & Maintenance

### Application Monitoring

#### Heroku Monitoring
```bash
# View app metrics
heroku logs --tail -a ludora-api-prod
heroku ps -a ludora-api-prod
heroku config -a ludora-api-prod

# Monitor dyno usage
heroku logs --source app -a ludora-api-prod

# Database monitoring
heroku pg:info -a ludora-api-prod
heroku pg:diagnose -a ludora-api-prod
```

#### Firebase Monitoring
```bash
# View hosting logs
firebase hosting:logs

# Performance monitoring (in Firebase Console)
# - Page load times
# - Core Web Vitals
# - Real user monitoring
```

### Database Monitoring
```bash
# Connection monitoring
heroku pg:info -a ludora-api-prod

# Query performance
heroku pg:diagnose -a ludora-api-prod

# Storage usage
heroku pg:info -a ludora-api-prod
```

### Backup Strategy

#### Database Backups
```bash
# Manual backup
heroku pg:backups:capture -a ludora-api-prod

# Schedule automatic backups
heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Los_Angeles' -a ludora-api-prod

# Download backup
heroku pg:backups:download -a ludora-api-prod
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
- Verify FRONTEND_URL environment variable in Heroku
- Check ADDITIONAL_FRONTEND_URLS includes Firebase domains
- Ensure credentials: true in CORS config

#### 2. Database Connection Issues
**Symptoms**: Database connection timeouts or authentication errors
**Solutions**:
- Verify DATABASE_URL is properly set in Heroku config
- Check database service status: `heroku pg:info -a ludora-api-prod`
- Test direct connection: `heroku pg:psql -a ludora-api-prod`

#### 3. Environment Variable Issues
**Symptoms**: Configuration not loading, undefined values
**Solutions**:
- Check Heroku config: `heroku config -a ludora-api-prod`
- Verify all required variables are set
- Restart dynos after config changes: `heroku ps:restart -a ludora-api-prod`

#### 4. Build Failures
**Symptoms**: Deployment fails during build process
**Solutions**:
- Check build logs: `heroku logs -a ludora-api-prod`
- Verify Node.js version in package.json engines
- Ensure all dependencies are in package.json
- Check for missing environment variables needed at build time

#### 5. SSL Certificate Issues
**Symptoms**: HTTPS not working, certificate warnings
**Solutions**:
- Verify DNS records in Cloudflare
- Check domain ownership verification
- Wait for certificate propagation (up to 24 hours)
- Contact platform support if issues persist

### Emergency Procedures

#### Rollback Plan
1. **Heroku Rollback**: `heroku releases:rollback -a ludora-api-prod`
2. **Firebase Rollback**: `firebase hosting:rollback`
3. **DNS Revert**: Change Cloudflare DNS records if needed
4. **Database Sync**: Restore from backup if needed

#### Service Recovery
```bash
# Check service status
heroku ps -a ludora-api-prod
firebase hosting:sites:list

# Restart services
heroku ps:restart -a ludora-api-prod
firebase deploy --only hosting

# Monitor recovery
heroku logs --tail -a ludora-api-prod
```

---

## 💰 Cost Optimization

### Heroku Optimization
- **Dyno Sizing**: Start with Basic or Standard-1X dynos
- **Database**: Use appropriate Postgres plan (Essential-0 for small apps)
- **Add-ons**: Monitor usage and adjust plans accordingly
- **Sleeping Dynos**: Consider for staging environments

### Firebase Optimization
- **Hosting Plan**: Firebase Hosting has generous free tier
- **Bandwidth**: Monitor usage for large assets
- **Performance**: Optimize build sizes to reduce bandwidth

### AWS S3 Optimization
- **Storage Class**: Use appropriate storage classes (Standard vs IA)
- **Lifecycle Policies**: Automatically transition old files
- **CloudFront**: Consider CDN integration for frequently accessed files

### Cloudflare Optimization
- **Free Plan**: Provides good value for basic needs
- **Caching**: Configure appropriate cache rules
- **Image Optimization**: Use Cloudflare's image optimization features

---

## 📞 Support & Resources

### Platform Documentation
- **Firebase**: https://firebase.google.com/docs/hosting
- **Heroku**: https://devcenter.heroku.com
- **Cloudflare**: https://developers.cloudflare.com

### Monitoring Tools
- **Heroku Dashboard**: https://dashboard.heroku.com
- **Firebase Console**: https://console.firebase.google.com
- **Cloudflare Dashboard**: https://dash.cloudflare.com

### CLI References
```bash
# Heroku commands
heroku --help
heroku apps
heroku logs --tail -a [app-name]
heroku config -a [app-name]

# Firebase commands
firebase --help
firebase projects:list
firebase hosting:sites:list
firebase serve

# Cloudflare commands (if using wrangler)
wrangler --help
```

### Emergency Contacts
- **Technical Lead**: Omri
- **Repository**: Internal Ludora repository
- **This Guide**: `/ludora-utils/docs/firebase-heroku-deployment-guide.md`
- **Migration Plan**: `/ludora-utils/docs/migration-plan.md`

---

**Last Updated**: November 7, 2025
**Version**: 1.0.0
**Migration Status**: Firebase + Heroku Active Deployment
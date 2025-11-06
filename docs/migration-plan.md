# Ludora Platform Migration: Fly.io → Firebase + Heroku

## 🎯 Migration Overview

**Migration Date**: November 2025
**🚨 CRITICAL UPDATE**: Fly.io deployment deleted - expedited migration in progress
**Objective**: Migrate from Fly.io to cost-effective Firebase + Heroku architecture
**Target Architecture**:
- **Frontend**: React/Vite → Firebase Hosting (with global CDN)
- **Backend**: Node.js API → Heroku Web Service
- **Database**: PostgreSQL → Heroku Postgres

**Expected Benefits**:
- 60-80% cost reduction
- Improved frontend performance via Firebase Hosting CDN
- Simplified deployment and management
- Better auto-scaling capabilities
- Cloudflare integration for enhanced security and performance

---

## 📊 Current Architecture Analysis

### Frontend (ludora-front)
- **Platform**: Fly.io with Nginx
- **Framework**: React + Vite
- **Environment Variables**: 7 total
  - `VITE_API_BASE`: https://api.ludora.app/api
  - `VITE_FIREBASE_API_KEY`: AIzaSyCvc0KGxsYCu61pOwBSJ3tzdCs7lUT28JI
  - `VITE_FIREBASE_AUTH_DOMAIN`: ludora.app
  - `VITE_FIREBASE_PROJECT_ID`: ludora-af706
  - `VITE_FIREBASE_STORAGE_BUCKET`: ludora-af706.firebasestorage.app
  - `VITE_FIREBASE_MESSAGING_SENDER_ID`: 985814078486
  - `VITE_FIREBASE_APP_ID`: 1:985814078486:web:45bbbd97327171c94ad137
  - `VITE_FIREBASE_MEASUREMENT_ID`: G-THZ32X92VY

### Backend (ludora-api)
- **Platform**: Fly.io (1GB RAM, port 3003)
- **Framework**: Node.js + Express
- **Environment Variables**: 72 total
- **Integrations**:
  - PostgreSQL database
  - AWS S3 (ludora-files bucket)
  - Firebase Admin
  - PayPlus payment gateway
  - OpenAI/Anthropic APIs
  - SMTP email

### Database (ludora-db)
- **Platform**: Fly.io PostgreSQL Cluster
- **Connection**: Internal flycast network
- **Current URL**: postgres://postgres:2SpoAsK11AJAhhE@ludora-db.flycast:5432/postgres

---

## 🚀 Migration Execution Plan

### Phase 1: Planning & Documentation

#### 1.1 Create Migration Plan Document ✅
- [x] **Status**: COMPLETED
- **File**: `/ludora-utils/docs/migration-plan.md`
- **Details**: Comprehensive 72-step migration tracking document created with:
  - Complete environment variable inventory (72 backend + 7 frontend)
  - Phase-by-phase execution plan with detailed checkboxes
  - Critical information recording spaces
  - Rollback procedures and security considerations
  - Success metrics and contact information
- **Completed**: November 6, 2025

#### 1.2 Create New Deployment Guide ✅
- [x] **Status**: COMPLETED
- **File**: `/ludora-utils/docs/firebase-heroku-deployment-guide.md`
- **Contents**:
  - Complete environment variable reference (72 backend + 7 frontend)
  - Comprehensive step-by-step deployment instructions for Firebase + Heroku
  - Database setup and migration procedures
  - CORS configuration with Firebase domain patterns
  - DNS configuration and custom domain setup via Cloudflare
  - Testing, monitoring, and troubleshooting guides
  - Cost optimization strategies
  - Emergency rollback procedures
- **Completed**: November 7, 2025
- **Size**: ~600 lines of comprehensive documentation

#### 1.3 Deprecate Old Deployment Guide ✅
- [x] **Status**: COMPLETED
- **File**: `/ludora-utils/docs/fly-io-deployment-guide.md`
- **Action**: Added prominent deprecation notice at top with links to new guide
- **Changes Made**:
  - Added clear deprecation warning with emojis for visibility
  - Linked to new Firebase + Heroku deployment guide
  - Linked to migration plan document
  - Added "DO NOT USE" warnings throughout
  - Marked all content sections as outdated
- **Completed**: November 6, 2025

---

### Phase 2: Database Migration (Heroku Postgres)

#### 2.1 Create Heroku Postgres Instances
- [ ] **Status**: PENDING
- **Production Instance**:
  - Heroku App: ludora-api-prod
  - Database URL: _[To be recorded]_
  - Plan: essential-0 or higher
- **Staging Instance**:
  - Heroku App: ludora-api-staging
  - Database URL: _[To be recorded]_
  - Plan: mini or essential-0

#### 2.2 Export Database from Local Development ✅
- [x] **Status**: COMPLETED
- **Source**: Local PostgreSQL database (ludora_development)
- **Backup Files Created**:
  - Full backup (custom): ludora_development_20251106_165200.sql.backup
  - Full backup (SQL): ludora_development_20251106_165200.sql
  - Schema only: ludora_development_20251106_165200_schema.sql
  - Data only: ludora_development_20251106_165200_data.sql
  - Info file: ludora_development_20251106_165200_info.txt
  - Checksums: ludora_development_20251106_165200_checksums.txt
- **Database Statistics**:
  - 33+ tables with complete schema
  - 221 curriculum entries
  - 88 migration records
  - All production-ready table structure
- **Completed**: November 6, 2025

#### 2.3 Import Database to Heroku
- [ ] **Status**: PENDING
- **Import Method**: heroku pg:restore or heroku pg:psql
- **Import Duration**: _[To be recorded]_
- **Verification Results**: _[To be recorded]_

#### 2.4 Database Connection Testing
- [ ] **Status**: PENDING
- **Connection Tests**:
  - [ ] Local connection test
  - [ ] API connection test
  - [ ] Migration script test
- **Notes**: _[Test results to be recorded]_

---

### Phase 3: Backend Migration (Heroku Web Service)

#### 3.1 Create Heroku Apps
- [ ] **Status**: PENDING
- **Production App Details**:
  - App Name: ludora-api-prod
  - App URL: _[To be recorded]_
  - Region: us (United States)
  - Dyno Type: Basic or Standard-1X
- **Staging App Details**:
  - App Name: ludora-api-staging
  - App URL: _[To be recorded]_
  - Region: us (United States)
  - Dyno Type: Basic

#### 3.2 Configure Environment Variables (72 total)
- [ ] **Status**: PENDING
- **Core Configuration**:
  - [ ] `ENVIRONMENT=production`
  - [ ] `PORT=3003` (or Heroku assigned)
  - [ ] `DATABASE_URL`: _[New Heroku PostgreSQL URL]_
  - [ ] `JWT_SECRET`: _[Migrated from Fly.io]_
  - [ ] `API_KEY`: _[Migrated from Fly.io]_
  - [ ] `ENCRYPTION_KEY`: _[Migrated from Fly.io]_

- **Firebase Configuration**:
  - [ ] `FIREBASE_SERVICE_ACCOUNT`: _[Base64 encoded JSON]_

- **AWS S3 Configuration**:
  - [ ] `USE_S3=true`
  - [ ] `AWS_S3_BUCKET=ludora-files`
  - [ ] `AWS_ACCESS_KEY_ID`: _[Migrated from Fly.io]_
  - [ ] `AWS_SECRET_ACCESS_KEY`: _[Migrated from Fly.io]_
  - [ ] `AWS_REGION=eu-central-1`

- **Payment Configuration (PayPlus)**:
  - [ ] `PAYPLUS_API_KEY`: _[Production key]_
  - [ ] `PAYPLUS_SECRET_KEY`: _[Production secret]_
  - [ ] `PAYPLUS_PAYMENT_PAGE_UID`: _[Production UID]_
  - [ ] `PAYPLUS_STAGING_API_KEY`: _[Test key]_
  - [ ] `PAYPLUS_STAGING_SECRET_KEY`: _[Test secret]_
  - [ ] `PAYPLUS_STAGING_PAYMENT_PAGE_UID`: _[Test UID]_

- **API Configuration**:
  - [ ] `OPENAI_API_KEY`: _[Migrated from Fly.io]_
  - [ ] `ANTHROPIC_API_KEY`: _[Migrated from Fly.io]_
  - [ ] `DEFAULT_LLM_MODEL=gpt-3.5-turbo`

- **Email Configuration**:
  - [ ] `EMAIL_HOST=smtp.gmail.com`
  - [ ] `EMAIL_PORT=587`
  - [ ] `EMAIL_USER`: _[Production email]_
  - [ ] `EMAIL_PASSWORD`: _[App password]_
  - [ ] `DEFAULT_FROM_EMAIL=noreply@ludora.app`

- **CORS Configuration**:
  - [ ] `FRONTEND_URL`: _[New Firebase URL]_
  - [ ] `API_URL`: _[New Heroku URL]_
  - [ ] `ADDITIONAL_FRONTEND_URLS`: _[Include Firebase default URLs]_

#### 3.3 Deploy Backend to Heroku
- [ ] **Status**: PENDING
- **Build Configuration**: Heroku buildpacks (Node.js)
- **Deploy Command**: git push heroku main
- **First Deployment URL**: _[To be recorded]_
- **Health Check**: _[/health endpoint test results]_

#### 3.4 Configure Custom Domain (api.ludora.app)
- [ ] **Status**: PENDING
- **Domain Configuration**: _[Steps taken to be recorded]_
- **SSL Certificate**: _[Status to be recorded]_
- **DNS Changes**: _[Details to be recorded]_

---

### Phase 4: Frontend Migration (Firebase Hosting)

#### 4.1 Initialize Firebase Project
- [ ] **Status**: PENDING
- **Project Name**: ludora-af706
- **Firebase Site**: _[Created site name]_
- **Build Settings**: _[Configuration details]_

#### 4.2 Configure Environment Variables
- [ ] **Status**: PENDING
- **Production Environment**:
  - [ ] `VITE_API_BASE`: _[New Heroku backend URL]_
  - [ ] `VITE_FIREBASE_API_KEY`: AIzaSyCvc0KGxsYCu61pOwBSJ3tzdCs7lUT28JI
  - [ ] `VITE_FIREBASE_AUTH_DOMAIN`: ludora-af706.firebaseapp.com
  - [ ] `VITE_FIREBASE_PROJECT_ID`: ludora-af706
  - [ ] `VITE_FIREBASE_STORAGE_BUCKET`: ludora-af706.firebasestorage.app
  - [ ] `VITE_FIREBASE_MESSAGING_SENDER_ID`: 985814078486
  - [ ] `VITE_FIREBASE_APP_ID`: 1:985814078486:web:45bbbd97327171c94ad137
  - [ ] `VITE_FIREBASE_MEASUREMENT_ID`: G-THZ32X92VY

#### 4.3 Deploy Frontend to Firebase
- [ ] **Status**: PENDING
- **Build Command**: npm run build
- **Deploy Command**: firebase deploy --only hosting
- **First Deployment URL**: _[To be recorded]_
- **Firebase Default URL**: _[To be recorded]_

#### 4.4 Configure Custom Domain (ludora.app)
- [ ] **Status**: PENDING
- **Domain Configuration**: _[Steps taken]_
- **DNS Changes**: _[Details recorded]_
- **SSL Certificate**: _[Auto-configured by Firebase]_

---

### Phase 5: Integration & Testing

#### 5.1 CORS Configuration Update
- [ ] **Status**: PENDING
- **Backend CORS Update**: _[Include all Firebase URLs]_
- **Testing**: _[Cross-origin request tests]_

#### 5.2 End-to-End Testing
- [ ] **Status**: PENDING
- **Authentication Flow**:
  - [ ] User login/logout
  - [ ] Firebase authentication
  - [ ] JWT token validation
- **API Endpoints**:
  - [ ] Health check
  - [ ] User management
  - [ ] File upload/download
  - [ ] Payment processing
- **Database Operations**:
  - [ ] Read operations
  - [ ] Write operations
  - [ ] Migration compatibility

#### 5.3 Performance Testing
- [ ] **Status**: PENDING
- **Frontend Performance**: _[Load times, metrics]_
- **Backend Response Times**: _[API latency tests]_
- **Database Performance**: _[Query performance tests]_

---

### Phase 6: DNS Cutover & Go-Live

#### 6.1 Staging Environment Validation
- [ ] **Status**: PENDING
- **Staging URLs**:
  - Frontend: _[Firebase preview URL]_
  - Backend: _[Heroku staging app URL]_
- **Full Testing**: _[Results to be recorded]_

#### 6.2 Production DNS Cutover
- [ ] **Status**: PENDING
- **DNS Changes**:
  - [ ] ludora.app → Firebase Hosting
  - [ ] api.ludora.app → Heroku
- **Propagation Time**: _[To be recorded]_
- **Rollback Plan**: _[Documented steps]_

#### 6.3 Post-Cutover Monitoring
- [ ] **Status**: PENDING
- **Monitoring Period**: 48 hours minimum
- **Health Checks**: _[Results to be recorded]_
- **User Feedback**: _[Issues to be recorded]_

---

### Phase 7: Cleanup & Documentation

#### 7.1 Fly.io Cleanup
- [ ] **Status**: PENDING
- **Final Backup**: _[Before decommission]_
- **Service Shutdown**:
  - [ ] ludora-front.fly.dev
  - [ ] ludora-api.fly.dev
  - [ ] ludora-db.fly.dev
- **Subscription Cancellation**: _[Date recorded]_

#### 7.2 Documentation Updates
- [ ] **Status**: PENDING
- **Updated Documentation**:
  - [ ] Deployment guide
  - [ ] Environment setup
  - [ ] Troubleshooting guide
  - [ ] Team handover document

---

## 🚨 Critical Information

### Security Considerations
- **Environment Variable Migration**: Secure transfer of 72+ sensitive variables
- **Database Credentials**: New connection strings with secure passwords
- **API Keys**: Firebase, PayPlus, OpenAI/Anthropic keys remain unchanged
- **JWT Secrets**: Maintain same secrets to avoid user re-authentication

### Rollback Plan
1. **Immediate DNS Revert**: Change DNS back to Fly.io URLs
2. **Database Sync**: Ensure Fly.io database has latest data
3. **Application Restart**: Restart Fly.io services if needed
4. **Communication**: Notify users of temporary service restoration

### Contact Information
- **Technical Lead**: Omri
- **Repository**: Internal Ludora repository
- **Migration Document**: This file (`/ludora-utils/docs/migration-plan.md`)

---

## 📈 Success Metrics

### Cost Reduction
- **Target**: 60-80% reduction in hosting costs
- **Current**: _[Fly.io monthly cost to be recorded]_
- **New**: _[Firebase + Heroku monthly cost to be recorded]_

### Performance Improvements
- **Frontend Load Time**: _[Before/after measurements]_
- **API Response Time**: _[Before/after measurements]_
- **Database Query Performance**: _[Before/after measurements]_

### Reliability Metrics
- **Uptime**: Target 99.9%
- **Error Rates**: Monitor for first 30 days
- **User Satisfaction**: Track support tickets and feedback

---

**Last Updated**: November 6, 2025
**Next Review**: After each phase completion
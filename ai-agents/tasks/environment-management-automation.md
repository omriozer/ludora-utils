# Environment Management Automation - Complete Implementation Plan

## 📋 Task Overview

**Priority**: High
**Estimated Time**: 3-4 weeks
**Owner Agent**: ludora-deployment
**Status**: Planning Phase

### **Objective**
Create a comprehensive automated environment management system that eliminates manual environment variable drift, provides secure secret rotation, and ensures deployment consistency across all environments.

---

## 🎯 Core Requirements

Based on discussion with developer:

1. **Secret Rotation Automation**: Terminal-based interactive system with checkboxes
2. **Auto-fetch External Keys**: AWS, Firebase, Heroku API integration
3. **Auto-generate Internal Keys**: JWT secrets, encryption keys, API keys
4. **Manual Admin Control**: Admin password, bucket names require manual input
5. **Periodic Reminders**: Scheduled notifications for rotation maintenance
6. **All-at-once Migration**: No gradual rollout - full implementation
7. **Custom Scripts**: No external tools (Vault, Doppler, etc.)
8. **AWS IAM Separation**: Individual users per environment
9. **No Monitoring**: Simple validation, no complex audit trails
10. **Auto-rollback**: Automatic revert on sync failures
11. **Single Developer**: No team coordination needed currently

---

## 📁 Implementation Structure

### **Phase 1: Secret Rotation System (Week 1)**

#### **Files to Create:**

```
ludora-utils/
├── scripts/
│   ├── secret-rotator.js              # Main interactive rotation script
│   ├── environment-sync.js            # Master sync and rollback system
│   └── rotation-scheduler.js          # Reminder notification system
├── key-managers/
│   ├── aws-key-manager.js             # AWS credential automation
│   ├── firebase-manager.js            # Firebase key management
│   ├── heroku-manager.js              # Heroku config automation
│   ├── internal-generator.js          # JWT/encryption key generation
│   └── payplus-manager.js             # PayPlus credential management
└── templates/
    ├── rotation-config.json           # Configuration for rotation rules
    └── reminder-schedule.json         # Reminder timing configuration
```

#### **Key Features:**

**1. Interactive Terminal UI** (`secret-rotator.js`):
```javascript
// Terminal checkbox interface for key selection
✅ AWS Production Credentials
✅ Firebase Production Config
⬜ JWT Secret (last rotated: 45 days ago)
⬜ Encryption Key (last rotated: 90 days ago)
✅ PayPlus API Keys
⬜ Admin Password (manual input required)
⬜ S3 Bucket Names (manual input required)

[Rotate Selected] [Cancel] [Show Last Rotation]
```

**2. Auto-fetch External Services**:
- **AWS**: Create new IAM user, generate keys, update Heroku config
- **Firebase**: Generate new service account, update project credentials
- **Heroku**: Rotate database URL, update config vars via API
- **PayPlus**: API key regeneration (if supported by PayPlus API)

**3. Auto-generate Internal Keys**:
- **JWT_SECRET**: Cryptographically secure random 256-bit key
- **ENCRYPTION_KEY**: AES-256 compatible base64 key
- **API_KEY**: Custom format with timestamp + random data

**4. Manual Admin Controls**:
- **ADMIN_PASSWORD**: Secure prompt with confirmation
- **S3 Bucket Names**: Validation against existing buckets
- **Email Credentials**: Manual input with SMTP testing

#### **Rotation Rules Configuration:**

```json
// rotation-config.json
{
  "rotationSchedule": {
    "critical": 90,      // days - production secrets
    "standard": 180,     // days - staging/dev secrets
    "internal": 365      // days - internal generated keys
  },
  "autoRotatable": [
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "JWT_SECRET",
    "ENCRYPTION_KEY",
    "API_KEY"
  ],
  "manualRequired": [
    "ADMIN_PASSWORD",
    "EMAIL_USER",
    "EMAIL_PASSWORD",
    "AWS_S3_BUCKET",
    "DATABASE_URL"
  ],
  "externalServices": {
    "aws": {
      "endpoint": "iam.amazonaws.com",
      "permissions": ["s3:*", "s3:GetBucketLocation"]
    },
    "firebase": {
      "endpoint": "firebase.googleapis.com",
      "projectIds": ["ludora-af706", "ludora-staging"]
    },
    "heroku": {
      "apps": ["ludora-api-prod", "ludora-api-staging"]
    }
  }
}
```

### **Phase 2: AWS IAM User Separation (Week 2)**

#### **Implementation Steps:**

**1. Create Environment-Specific IAM Users:**
```bash
# Production IAM User
aws iam create-user --user-name ludora-prod-user
aws iam attach-user-policy --user-name ludora-prod-user --policy-arn arn:aws:iam::aws:policy/custom-ludora-prod-s3-policy

# Staging IAM User
aws iam create-user --user-name ludora-staging-user
aws iam attach-user-policy --user-name ludora-staging-user --policy-arn arn:aws:iam::aws:policy/custom-ludora-staging-s3-policy

# Development IAM User
aws iam create-user --user-name ludora-dev-user
aws iam attach-user-policy --user-name ludora-dev-user --policy-arn arn:aws:iam::aws:policy/custom-ludora-dev-s3-policy
```

**2. Bucket Access Policies:**
```json
// ludora-prod-s3-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::ludora-files-prod",
        "arn:aws:s3:::ludora-files-prod/*"
      ]
    }
  ]
}
```

**3. Credential Migration Script:**
```javascript
// aws-migration.js
async function migrateAWSCredentials() {
  // 1. Create new IAM users via AWS API
  // 2. Generate access keys for each user
  // 3. Update Heroku config vars
  // 4. Test bucket access from each environment
  // 5. Deactivate shared credentials
  // 6. Rollback on any failure
}
```

### **Phase 3: Template System Overhaul (Week 3)**

#### **Master Template Implementation:**

**1. Enhanced .env.example** (Git-tracked master template):
```bash
# ============================================
# LUDORA ENVIRONMENT TEMPLATE v2.0
# ============================================
# Generated by: environment-sync.js
# Last Updated: {{TIMESTAMP}}
# Environment: {{ENVIRONMENT_TYPE}}

# CORE CONFIGURATION
ENVIRONMENT={{ENVIRONMENT}}                    # Auto: development|staging|production
PORT={{PORT}}                                 # Auto: 3003|3004|3005
NODE_ENV={{NODE_ENV}}                        # Auto: development|staging|production

# DATABASE CONFIGURATION
DATABASE_URL={{DATABASE_URL}}                # External: Heroku managed
DATABASE_SSL_REQUIRE={{DATABASE_SSL_REQUIRE}} # Auto: false|true|true

# AUTHENTICATION & SECURITY
JWT_SECRET={{JWT_SECRET}}                     # Internal: Auto-generated 256-bit
ENCRYPTION_KEY={{ENCRYPTION_KEY}}            # Internal: Auto-generated AES-256
API_KEY={{API_KEY}}                          # Internal: Auto-generated with timestamp
ADMIN_PASSWORD={{ADMIN_PASSWORD}}            # Manual: Admin input required

# AWS S3 STORAGE
AWS_ACCESS_KEY_ID={{AWS_ACCESS_KEY_ID}}       # External: Environment-specific IAM user
AWS_SECRET_ACCESS_KEY={{AWS_SECRET_ACCESS_KEY}} # External: Environment-specific IAM user
AWS_S3_BUCKET={{AWS_S3_BUCKET}}              # Manual: ludora-files-{env}
AWS_REGION={{AWS_REGION}}                    # Auto: eu-central-1

# FIREBASE AUTHENTICATION
FIREBASE_SERVICE_ACCOUNT={{FIREBASE_SERVICE_ACCOUNT}} # External: Environment-specific
FIREBASE_ADMIN_PROJECT_ID={{FIREBASE_ADMIN_PROJECT_ID}} # Manual: ludora-{env}

# PAYMENT PROCESSING (PAYPLUS)
PAYPLUS_API_KEY={{PAYPLUS_API_KEY}}          # External: Environment-specific
PAYPLUS_SECRET_KEY={{PAYPLUS_SECRET_KEY}}    # External: Environment-specific
PAYPLUS_PAYMENT_PAGE_UID={{PAYPLUS_PAYMENT_PAGE_UID}} # Manual: Environment-specific

# FRONTEND URLS
FRONTEND_URL={{FRONTEND_URL}}                # Manual: Environment-specific domain
API_URL={{API_URL}}                          # Manual: Environment-specific domain
ADDITIONAL_FRONTEND_URLS={{ADDITIONAL_FRONTEND_URLS}} # Manual: Comma-separated domains

# EMAIL CONFIGURATION
EMAIL_HOST={{EMAIL_HOST}}                    # Auto: smtp.gmail.com
EMAIL_PORT={{EMAIL_PORT}}                    # Auto: 587
EMAIL_USER={{EMAIL_USER}}                    # Manual: Admin input required
EMAIL_PASSWORD={{EMAIL_PASSWORD}}            # Manual: Admin input required
DEFAULT_FROM_EMAIL={{DEFAULT_FROM_EMAIL}}    # Manual: Environment-specific

# MONITORING & ALERTS
TELEGRAM_BOT_TOKEN={{TELEGRAM_BOT_TOKEN}}    # Manual: Admin input required
TELEGRAM_CHAT_ID={{TELEGRAM_CHAT_ID}}        # Manual: Admin input required

# Last Rotation Information:
# JWT_SECRET: {{JWT_SECRET_LAST_ROTATED}}
# AWS_CREDENTIALS: {{AWS_CREDENTIALS_LAST_ROTATED}}
# ENCRYPTION_KEY: {{ENCRYPTION_KEY_LAST_ROTATED}}
```

**2. Environment Population Script:**
```javascript
// environment-sync.js
class EnvironmentSync {
  async populateFromTemplate(environment) {
    // 1. Load .env.example template
    // 2. Replace {{PLACEHOLDERS}} with actual values
    // 3. Source values from:
    //    - Auto: calculated/derived values
    //    - Internal: generated secrets
    //    - External: fetched from APIs
    //    - Manual: prompt user input
    // 4. Validate completeness
    // 5. Create backup of existing
    // 6. Write new environment file
    // 7. Test environment functionality
    // 8. Rollback on failure
  }

  async syncToRemote(environment) {
    // 1. Compare local with remote (Heroku/Firebase)
    // 2. Show diff with confirmation prompt
    // 3. Update remote environment
    // 4. Verify remote functionality
    // 5. Rollback on failure
  }
}
```

### **Phase 4: Advanced Automation (Week 4)**

#### **Reminder and Scheduling System:**

**1. Rotation Scheduler** (`rotation-scheduler.js`):
```javascript
// Periodic reminder system
const REMINDER_SCHEDULE = {
  monthly: ['AWS_CREDENTIALS', 'FIREBASE_KEYS'],
  quarterly: ['JWT_SECRET', 'ENCRYPTION_KEY', 'ADMIN_PASSWORD'],
  biannual: ['EMAIL_CREDENTIALS', 'PAYPLUS_KEYS'],
  annual: ['S3_BUCKET_REVIEW', 'TELEGRAM_TOKENS']
};

// Notification methods
async function sendReminder(keys, daysOverdue) {
  // 1. Terminal notification when running any git command
  // 2. Slack/email notification (if configured)
  // 3. Block certain operations if critical keys expired
  // 4. Show rotation command to run
}
```

**2. Git Hook Integration:**
```bash
# Enhanced pre-push hook
#!/bin/bash

# Check for overdue secret rotations
node scripts/rotation-scheduler.js --check-overdue

if [ $? -eq 1 ]; then
  echo "⚠️  OVERDUE SECRET ROTATIONS DETECTED"
  echo "   Run 'npm run secrets:rotate' before pushing to production"
  echo "   Or use 'git push --no-verify' to bypass (NOT RECOMMENDED)"
  exit 1
fi

# Continue with existing environment validation
node scripts/env-validator.js --pre-push
```

#### **Rollback and Recovery System:**

**1. Backup Strategy:**
```javascript
// Before any rotation or sync operation
async function createBackup(environment) {
  const backup = {
    timestamp: Date.now(),
    environment: environment,
    herokuConfig: await heroku.getConfig(),
    localFiles: {
      '.env.production': fs.readFileSync('.env.production'),
      '.env.staging': fs.readFileSync('.env.staging')
    },
    awsCredentials: await aws.getCurrentCredentials(),
    firebaseConfig: await firebase.getCurrentConfig()
  };

  fs.writeFileSync(`backups/env-backup-${backup.timestamp}.json`,
                   JSON.stringify(backup, null, 2));
}

async function rollback(backupTimestamp) {
  // 1. Load backup file
  // 2. Restore Heroku config vars
  // 3. Restore local environment files
  // 4. Revert AWS/Firebase changes
  // 5. Verify functionality
  // 6. Log rollback operation
}
```

---

## 🔧 Developer Workflow

### **Daily Operations:**
```bash
# Check environment status
npm run env:status

# Rotate overdue secrets
npm run secrets:rotate

# Sync local to production (with confirmation)
npm run env:sync-prod

# Show rotation schedule
npm run secrets:schedule
```

### **Periodic Maintenance:**
```bash
# Monthly AWS credential rotation
npm run rotate:aws-monthly

# Quarterly internal key rotation
npm run rotate:internal-quarterly

# Emergency rollback
npm run env:rollback 1638360000000
```

### **Emergency Procedures:**
```bash
# Force sync bypassing validations
npm run env:sync-prod --force

# Emergency key generation
npm run secrets:emergency-generate

# Health check all environments
npm run env:health-check-all
```

---

## ⚠️ Security Considerations

### **Secret Storage:**
1. **Never commit actual secrets** - only templates with placeholders
2. **Encrypted backups** - All backup files use encryption at rest
3. **Secure deletion** - Old secrets securely wiped after rotation
4. **Access logging** - All secret access logged with timestamps

### **Rotation Safety:**
1. **Validation before rotation** - Test connectivity before changing keys
2. **Gradual rollout** - Rotate staging before production
3. **Automatic testing** - Post-rotation functionality tests
4. **Manual confirmation** - Production changes require explicit approval

### **Emergency Recovery:**
1. **Multiple backup sources** - Local, encrypted cloud storage
2. **Out-of-band access** - Admin access doesn't depend on rotated keys
3. **Manual override** - Bypass rotation system for emergencies
4. **Documentation** - Step-by-step manual recovery procedures

---

## 📊 Success Metrics

### **Automation Goals:**
- [ ] **Zero manual environment drift** - All changes via automation
- [ ] **<5 minute rotation time** - Complete environment rotation under 5 minutes
- [ ] **100% rollback success** - All failed rotations successfully reverted
- [ ] **Zero secret exposure** - No secrets committed to Git
- [ ] **Quarterly rotation compliance** - All critical keys rotated on schedule

### **Developer Experience:**
- [ ] **One-command setup** - New developers can set up environment in one command
- [ ] **Clear error messages** - All failures provide actionable fix instructions
- [ ] **Zero surprise failures** - Proactive validation prevents deployment issues
- [ ] **Emergency access** - Can override system for critical fixes

---

## 🚀 Implementation Timeline

### **Week 1: Secret Rotation Core**
- [ ] Interactive terminal UI for key selection
- [ ] AWS credential auto-rotation
- [ ] Internal key generation (JWT, encryption)
- [ ] Basic rollback functionality
- [ ] Testing with staging environment

### **Week 2: External Service Integration**
- [ ] Firebase key management
- [ ] Heroku config synchronization
- [ ] PayPlus credential handling
- [ ] AWS IAM user separation
- [ ] Production environment testing

### **Week 3: Template System**
- [ ] Master .env.example enhancement
- [ ] Environment population automation
- [ ] Local to remote sync system
- [ ] Comprehensive validation
- [ ] Migration from current system

### **Week 4: Advanced Features**
- [ ] Reminder and scheduling system
- [ ] Enhanced git hook integration
- [ ] Encrypted backup system
- [ ] Emergency recovery procedures
- [ ] Documentation and training

---

## 📚 Dependencies

### **External APIs Required:**
- **AWS IAM API** - For credential management
- **Heroku Platform API** - For config var management
- **Firebase Admin API** - For service account management
- **PayPlus API** - For credential rotation (if available)

### **Node.js Packages:**
```json
{
  "aws-sdk": "^2.1400.0",
  "heroku-client": "^3.1.0",
  "firebase-admin": "^11.8.0",
  "inquirer": "^9.2.0",
  "cli-table3": "^0.6.3",
  "chalk": "^5.3.0",
  "ora": "^6.3.1"
}
```

### **System Requirements:**
- **Heroku CLI** - For direct config management
- **AWS CLI** - For IAM user management
- **Firebase CLI** - For project configuration
- **Git hooks** - For automated validation

---

## 🔄 Future Enhancements

### **Phase 5: Advanced Monitoring** (Future)
- Real-time environment drift detection
- Slack/email notifications for anomalies
- Usage analytics for secret access patterns
- Compliance reporting for audit requirements

### **Phase 6: Team Scaling** (Future)
- Multi-developer secret sharing
- Role-based access controls
- Approval workflows for production changes
- Audit trails for compliance

### **Phase 7: Multi-Cloud Support** (Future)
- Google Cloud Platform integration
- Azure KeyVault support
- Multi-region secret replication
- Disaster recovery automation

---

## 📞 Implementation Notes

### **Agent Assignment:**
- **Primary**: ludora-deployment agent (infrastructure expertise)
- **Secondary**: ludora-security-expert agent (secret management review)
- **Validation**: ludora-backend agent (API integration testing)

### **Risk Mitigation:**
1. **Staged rollout** - Test extensively in development/staging
2. **Backup everything** - Multiple restore points before changes
3. **Manual override** - Always maintain emergency access
4. **Documentation** - Clear procedures for all scenarios

### **Success Criteria:**
- Zero environment-related deployment failures
- Sub-5-minute secret rotation time
- 100% automation coverage for routine tasks
- Clear audit trail for all changes
- Emergency recovery capability under 15 minutes

---

*This task represents a comprehensive solution to environment management automation that addresses current security vulnerabilities while providing a foundation for future scaling and compliance requirements.*
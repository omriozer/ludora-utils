# File Management Operations Manual

> **Status**: Production Ready ✅
> **Target Audience**: DevOps, System Administrators, Operations Team
> **Environment**: All environments (Development, Staging, Production)

## Executive Summary

This manual provides comprehensive operational procedures for the Ludora file management system. The system has been fully standardized and validated as of October 2025, with production-ready tools for monitoring, cleanup, and maintenance.

## System Overview

### Architecture
- **3-Layer System**: Marketing (public), Content (private), System (mixed)
- **Storage**: AWS S3 with CloudFront CDN
- **Database**: PostgreSQL with JSONB for complex file structures
- **Environments**: Development, Staging, Production with identical structure

### Key Metrics (Target Values)
- **Upload Success Rate**: >99%
- **API Response Time**: <2 seconds
- **Storage Growth**: <20% monthly
- **Orphan Files**: <100 in production
- **System Availability**: 99.9%

## Daily Operations

### Health Monitoring

**Daily Health Check Script**:
```bash
#!/bin/bash
# daily-file-health-check.sh

echo "🔍 Daily File Management Health Check - $(date)"

# Check S3 connectivity
echo "📡 Testing S3 connectivity..."
aws s3 ls s3://ludora-s3-bucket/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ S3 connectivity OK"
else
    echo "❌ S3 connectivity FAILED"
    # Alert mechanism
    curl -X POST -H 'Content-type: application/json' \
         --data '{"text":"🚨 S3 connectivity check failed"}' \
         $SLACK_WEBHOOK_URL
fi

# Check database connectivity
echo "📊 Testing database connectivity..."
cd /app/ludora-api
node -e "
require('./models').sequelize.authenticate()
  .then(() => console.log('✅ Database connectivity OK'))
  .catch(err => {
    console.log('❌ Database connectivity FAILED:', err.message);
    process.exit(1);
  });
"

# Check upload API endpoints
echo "🔗 Testing upload endpoints..."
curl -f -s "https://api.ludora.app/api/health" > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ API endpoints responding"
else
    echo "❌ API endpoints FAILED"
fi

# Check recent error rates
echo "📈 Checking recent error rates..."
# Query logs for last 24 hours error rate
ERROR_COUNT=$(grep -c "ERROR" /var/log/ludora/api.log | tail -1000)
if [ $ERROR_COUNT -lt 50 ]; then
    echo "✅ Error rate acceptable ($ERROR_COUNT errors in last 1000 log entries)"
else
    echo "⚠️ High error rate detected ($ERROR_COUNT errors in last 1000 log entries)"
fi

echo "✅ Daily health check completed"
```

### Storage Monitoring

**Storage Usage Check**:
```bash
# Check S3 storage usage by environment
aws s3api list-objects-v2 --bucket ludora-s3-bucket --prefix "production/" \
  --query "sum(Contents[].Size)" --output text | \
  awk '{print "Production storage: " $1/1024/1024/1024 " GB"}'

aws s3api list-objects-v2 --bucket ludora-s3-bucket --prefix "staging/" \
  --query "sum(Contents[].Size)" --output text | \
  awk '{print "Staging storage: " $1/1024/1024/1024 " GB"}'

aws s3api list-objects-v2 --bucket ludora-s3-bucket --prefix "development/" \
  --query "sum(Contents[].Size)" --output text | \
  awk '{print "Development storage: " $1/1024/1024/1024 " GB"}'
```

## Weekly Operations

### Orphan File Cleanup

**Production-Ready Cleanup Scripts** (Located in `/ludora-api/scripts/`):

```bash
# Weekly orphan file cleanup - Development
cd /app/ludora-api
node scripts/cleanup-orphaned-files.js --env=development --batch-size=200

# Weekly orphan file cleanup - Staging
node scripts/cleanup-orphaned-files.js --env=staging --batch-size=100

# Monthly orphan file cleanup - Production (with extra safety)
node scripts/cleanup-orphaned-files.js --env=production --batch-size=50
```

**Cleanup Script Features**:
- ✅ **Safe Operation**: Files moved to quarantine, not deleted immediately
- ✅ **Interactive Mode**: Asks for confirmation before operations
- ✅ **Resumable**: Can continue interrupted cleanup sessions
- ✅ **Progress Tracking**: Shows detailed progress and statistics
- ✅ **Batch Processing**: Handles large numbers of files efficiently
- ✅ **Validation**: Works correctly with refactor changes

**Cleanup Options**:
```bash
# Automated cleanup (no prompts) for CI/CD
node scripts/cleanup-orphaned-files.js --env=development --force

# Custom batch size for performance tuning
node scripts/cleanup-orphaned-files.js --env=production --batch-size=25

# Resume interrupted cleanup session
node scripts/cleanup-orphaned-files.js --env=staging --resume

# Skip recently checked files (performance optimization)
node scripts/cleanup-orphaned-files.js --env=development --check-threshold=48h
```

### System Validation

**Comprehensive System Validation**:
```bash
# Run complete system validation
cd /app/ludora-utils
node scripts/validate-file-system.js

# Expected output for healthy system:
# ✅ Tests Passed: 24
# ❌ Tests Failed: 0
# 📈 Success Rate: 100%
# 🎉 EXCELLENT: File system validation passed with excellent results!
```

**Validation Coverage**:
- Frontend file structure validation
- Backend service routing verification
- Documentation completeness check
- File type matrix implementation
- S3 path structure validation

## Monthly Operations

### Deep Storage Analysis

**Comprehensive Storage Report**:
```bash
#!/bin/bash
# monthly-storage-analysis.sh

echo "📊 Monthly Storage Analysis - $(date)"

# Detailed breakdown by file type and entity
cd /app/ludora-api
node -e "
const { collectAllFileReferences } = require('./scripts/utils/databaseReferenceCollector.js');

async function analyze() {
  console.log('🔍 Analyzing file references by environment...');

  for (const env of ['development', 'staging', 'production']) {
    console.log(\`\\n📁 Environment: \${env}\`);
    const refs = await collectAllFileReferences(env);
    console.log(\`   Total references: \${refs.length}\`);

    // Group by file type
    const types = {};
    refs.forEach(ref => {
      const type = ref.split('/').includes('image') ? 'image' :
                   ref.split('/').includes('video') ? 'video' :
                   ref.split('/').includes('document') ? 'document' :
                   ref.split('/').includes('audio') ? 'audio' : 'other';
      types[type] = (types[type] || 0) + 1;
    });

    Object.entries(types).forEach(([type, count]) => {
      console.log(\`   \${type}: \${count} files\`);
    });
  }
}

analyze().catch(console.error);
"
```

### Performance Review

**Monthly Performance Analysis**:
```bash
# API response time analysis
echo "📈 API Performance Analysis"
echo "Recent upload endpoint response times:"
grep "POST /api/assets/upload" /var/log/ludora/api.log | \
  grep "$(date +%Y-%m)" | \
  awk '{print $NF}' | \
  sort -n | \
  awk '{
    sum += $1;
    if ($1 > max) max = $1;
    if (min == 0 || $1 < min) min = $1
  }
  END {
    print "Average: " sum/NR "ms";
    print "Min: " min "ms";
    print "Max: " max "ms"
  }'

# Storage growth analysis
echo "📊 Storage Growth Analysis"
# Compare current month vs previous month storage usage
CURRENT_MONTH_SIZE=$(aws s3api list-objects-v2 --bucket ludora-s3-bucket \
  --query "sum(Contents[?LastModified>=\`$(date -d 'first day of this month' '+%Y-%m-%d')\`].Size)" \
  --output text)

echo "Storage added this month: $(echo $CURRENT_MONTH_SIZE | awk '{print $1/1024/1024/1024}') GB"
```

## Quarterly Operations

### Complete System Audit

**Quarterly Security and Compliance Audit**:
```bash
#!/bin/bash
# quarterly-audit.sh

echo "🔐 Quarterly File Management Audit - $(date)"

# 1. Check S3 bucket policies
echo "🔍 Auditing S3 bucket policies..."
aws s3api get-bucket-policy --bucket ludora-s3-bucket | jq '.Policy | fromjson'

# 2. Verify CORS configuration
echo "🌐 Checking CORS configuration..."
aws s3api get-bucket-cors --bucket ludora-s3-bucket

# 3. Check encryption settings
echo "🔒 Verifying encryption settings..."
aws s3api get-bucket-encryption --bucket ludora-s3-bucket

# 4. Audit public vs private file separation
echo "📊 Auditing public/private file separation..."
cd /app/ludora-api
node scripts/cleanup-orphaned-files.js --env=production --batch-size=1 2>&1 | \
  grep "Found.*references"

# 5. Check backup configuration
echo "💾 Verifying backup configuration..."
aws s3api get-bucket-versioning --bucket ludora-s3-bucket
aws s3api get-bucket-replication --bucket ludora-s3-bucket 2>/dev/null || \
  echo "⚠️ Cross-region replication not configured"

# 6. Access control audit
echo "👥 Auditing access controls..."
aws s3api get-bucket-acl --bucket ludora-s3-bucket
```

### Documentation Review

**Quarterly Documentation Update**:
```bash
# Check documentation freshness
echo "📚 Documentation freshness check"
find /app/ludora-utils/docs/architecture -name "*.md" -exec echo "File: {}" \; \
  -exec grep -l "Last Updated" {} \; \
  -exec grep "Last Updated" {} \;

# Validate code examples in documentation
echo "🧪 Validating code examples"
# Extract and test JavaScript code blocks from documentation
grep -A 10 "```javascript" /app/ludora-utils/docs/architecture/FILE_*GUIDE.md | \
  # Process code examples for syntax validation
```

## Emergency Procedures

### File Operation Failure Response

**When File Uploads Fail System-Wide**:
1. **Immediate Response (0-5 minutes)**:
   ```bash
   # Check S3 connectivity
   aws s3 ls s3://ludora-s3-bucket/

   # Check database connectivity
   cd /app/ludora-api && npm run db:test

   # Check API health
   curl -f "https://api.ludora.app/api/health"
   ```

2. **Investigation (5-15 minutes)**:
   ```bash
   # Check recent error logs
   tail -100 /var/log/ludora/api.log | grep -i error

   # Check system resources
   df -h  # Disk space
   free -m  # Memory usage

   # Check recent deployments
   git log --oneline -10
   ```

3. **Mitigation (15-30 minutes)**:
   ```bash
   # Restart API service if needed
   pm2 restart ludora-api

   # Clear any stuck file operations
   # (Check for stuck multipart uploads)
   aws s3api list-multipart-uploads --bucket ludora-s3-bucket
   ```

### Data Corruption Response

**When S3/Database Inconsistency Detected**:
1. **Assessment**:
   ```bash
   # Run comprehensive validation
   cd /app/ludora-utils
   node scripts/validate-file-system.js > /tmp/validation-report.txt

   # Generate database reference report
   cd /app/ludora-api
   node -e "
   const { collectAllFileReferences } = require('./scripts/utils/databaseReferenceCollector.js');
   collectAllFileReferences('production').then(refs => {
     console.log('Total DB references:', refs.length);
     console.log('Sample references:', refs.slice(0, 10));
   });
   " > /tmp/db-references.txt
   ```

2. **Isolation**:
   ```bash
   # Temporarily disable file uploads (if severe)
   # Add maintenance mode flag
   echo "MAINTENANCE_MODE=true" >> /app/ludora-api/.env
   pm2 restart ludora-api
   ```

3. **Recovery**:
   ```bash
   # Use orphan detection to identify issues
   cd /app/ludora-api
   node scripts/cleanup-orphaned-files.js --env=production --batch-size=10

   # Review and fix specific inconsistencies
   # (Manual process based on validation results)
   ```

### Security Incident Response

**When Unauthorized File Access Detected**:
1. **Immediate Containment**:
   ```bash
   # Review recent S3 access logs
   aws logs filter-log-events --log-group-name cloudtrail-log-group \
     --start-time $(date -d '1 hour ago' +%s)000 \
     --filter-pattern "{ $.eventSource = s3.amazonaws.com }"

   # Check for unusual API access patterns
   grep "GET /api/assets" /var/log/ludora/api.log | \
     tail -1000 | awk '{print $1}' | sort | uniq -c | sort -nr
   ```

2. **Investigation**:
   ```bash
   # Review authentication logs
   grep "auth" /var/log/ludora/api.log | tail -100

   # Check for privilege escalation
   grep "admin" /var/log/ludora/api.log | tail -50
   ```

3. **Hardening**:
   ```bash
   # Rotate API keys if needed
   # Update S3 bucket policies
   # Review and update access controls
   ```

## Monitoring and Alerting Setup

### CloudWatch Metrics

**Key Metrics to Monitor**:
```bash
# S3 Storage Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=ludora-s3-bucket \
  --start-time $(date -d '1 day ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average

# API Endpoint Response Times
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

### Alert Thresholds

**Production Alert Configuration**:
```yaml
# cloudwatch-alerts.yml
alerts:
  upload_failure_rate:
    threshold: 5%  # Alert if >5% of uploads fail
    evaluation_period: 5 minutes

  storage_growth:
    threshold: 20%  # Alert if >20% growth per month
    evaluation_period: 1 day

  orphan_files:
    threshold: 100  # Alert if >100 orphan files
    evaluation_period: 1 hour

  api_response_time:
    threshold: 5000ms  # Alert if >5s response time
    evaluation_period: 2 minutes

  error_rate:
    threshold: 1%  # Alert if >1% error rate
    evaluation_period: 5 minutes
```

### Dashboard Configuration

**Grafana Dashboard Metrics**:
```json
{
  "dashboard": {
    "title": "File Management System",
    "panels": [
      {
        "title": "Upload Success Rate",
        "targets": ["upload_success_count", "upload_failure_count"]
      },
      {
        "title": "Storage Usage by Environment",
        "targets": ["s3_storage_development", "s3_storage_staging", "s3_storage_production"]
      },
      {
        "title": "API Response Times",
        "targets": ["api_response_time_avg", "api_response_time_p95"]
      },
      {
        "title": "Orphan File Count",
        "targets": ["orphan_files_development", "orphan_files_production"]
      }
    ]
  }
}
```

## Backup and Recovery

### S3 Backup Strategy

**Cross-Region Replication**:
```bash
# Verify cross-region replication status
aws s3api get-bucket-replication --bucket ludora-s3-bucket

# Enable versioning (required for replication)
aws s3api put-bucket-versioning --bucket ludora-s3-bucket \
  --versioning-configuration Status=Enabled

# Configure lifecycle policy for old versions
aws s3api put-bucket-lifecycle-configuration --bucket ludora-s3-bucket \
  --lifecycle-configuration file://lifecycle-policy.json
```

**Lifecycle Policy Example**:
```json
{
  "Rules": [
    {
      "ID": "OrphanFileCleanup",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "trash/"
      },
      "Expiration": {
        "Days": 30
      }
    },
    {
      "ID": "OldVersionCleanup",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
```

### Database Backup

**File Reference Metadata Backup**:
```bash
#!/bin/bash
# backup-file-metadata.sh

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/file-metadata"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup file reference data
pg_dump -h localhost -U ludora_user -d ludora_production \
  --table=product \
  --table=file \
  --table=lesson_plan \
  --table=workshop \
  --table=course \
  --table=school \
  --table=settings \
  --table=audiofile \
  --data-only \
  --file="$BACKUP_DIR/file_references_$BACKUP_DATE.sql"

# Compress backup
gzip "$BACKUP_DIR/file_references_$BACKUP_DATE.sql"

echo "✅ File metadata backup completed: file_references_$BACKUP_DATE.sql.gz"
```

### Recovery Procedures

**File Reference Recovery**:
```bash
# Restore file reference metadata
gunzip /backups/file-metadata/file_references_YYYYMMDD_HHMMSS.sql.gz
psql -h localhost -U ludora_user -d ludora_production \
  -f /backups/file-metadata/file_references_YYYYMMDD_HHMMSS.sql

# Verify restoration
cd /app/ludora-utils
node scripts/validate-file-system.js
```

**S3 Point-in-Time Recovery**:
```bash
# List file versions
aws s3api list-object-versions --bucket ludora-s3-bucket \
  --prefix "production/private/document/file/123/"

# Restore specific version
aws s3api copy-object \
  --copy-source "ludora-s3-bucket/production/private/document/file/123/document.pdf?versionId=VERSION_ID" \
  --bucket ludora-s3-bucket \
  --key "production/private/document/file/123/document.pdf"
```

## Performance Tuning

### S3 Performance Optimization

**Transfer Acceleration**:
```bash
# Enable S3 Transfer Acceleration
aws s3api put-bucket-accelerate-configuration \
  --bucket ludora-s3-bucket \
  --accelerate-configuration Status=Enabled

# Test acceleration performance
aws s3 cp test-file.txt s3://ludora-s3-bucket/test/ --endpoint-url https://s3-accelerate.amazonaws.com
```

**Multipart Upload Optimization**:
```javascript
// Optimized multipart upload configuration
const uploadParams = {
  Bucket: 'ludora-s3-bucket',
  Key: s3Key,
  Body: fileStream,
  ContentType: contentType,
  Metadata: {
    'entity-type': entityType,
    'entity-id': entityId,
    'upload-date': new Date().toISOString()
  }
};

// For files > 100MB, use multipart upload
const uploadOptions = {
  partSize: 10 * 1024 * 1024, // 10MB parts
  queueSize: 4 // 4 parallel uploads
};

const upload = s3.upload(uploadParams, uploadOptions);
```

### Database Performance

**Index Optimization**:
```sql
-- Indexes for file reference queries
CREATE INDEX CONCURRENTLY idx_product_has_image ON product(has_image) WHERE has_image = true;
CREATE INDEX CONCURRENTLY idx_file_name ON file(file_name) WHERE file_name IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_lesson_plan_file_configs ON lesson_plan USING GIN(file_configs);
CREATE INDEX CONCURRENTLY idx_workshop_has_video ON workshop(has_video) WHERE has_video = true;
CREATE INDEX CONCURRENTLY idx_course_has_video ON course(has_video) WHERE has_video = true;
CREATE INDEX CONCURRENTLY idx_school_has_logo ON school(has_logo) WHERE has_logo = true;
CREATE INDEX CONCURRENTLY idx_settings_has_logo ON settings(has_logo) WHERE has_logo = true;
CREATE INDEX CONCURRENTLY idx_audiofile_has_file ON audiofile(has_file) WHERE has_file = true;
```

## Troubleshooting Reference

### Common Issues

**Issue**: High orphan file count
```bash
# Immediate investigation
cd /app/ludora-api
node scripts/cleanup-orphaned-files.js --env=production --batch-size=10

# Check recent upload failures
grep "upload.*failed" /var/log/ludora/api.log | tail -20

# Review transaction rollback logs
grep "rollback" /var/log/ludora/api.log | tail -10
```

**Issue**: Slow upload performance
```bash
# Check S3 transfer acceleration
aws s3api get-bucket-accelerate-configuration --bucket ludora-s3-bucket

# Test network performance
curl -o /dev/null -s -w "Total time: %{time_total}s\n" \
  "https://s3.amazonaws.com/ludora-s3-bucket/test-file"

# Check multipart upload settings
grep "multipart" /app/ludora-api/config/s3.js
```

**Issue**: Database consistency errors
```bash
# Run validation script
cd /app/ludora-utils
node scripts/validate-file-system.js | tee /tmp/validation-results.txt

# Check specific entity routing
cd /app/ludora-api
node -e "
const { collectUnifiedFileReferences } = require('./scripts/utils/databaseReferenceCollector.js');
collectUnifiedFileReferences('production').then(refs => {
  console.log('Unified references found:', refs.length);
});
"
```

### Escalation Procedures

**Level 1: Automated Response**
- Health check failures trigger automatic restarts
- Minor orphan file accumulation triggers cleanup scripts
- Performance degradation triggers scaling

**Level 2: Operations Team**
- Upload failure rate >5%
- Storage growth >20% monthly
- Consistency check failures

**Level 3: Development Team**
- Security incidents
- Data corruption
- System architecture changes needed

**Level 4: Management**
- Extended outages (>1 hour)
- Data loss incidents
- Compliance violations

---

**Document Version**: 1.0
**Last Updated**: October 31, 2025
**Next Review**: January 2026
**Emergency Contact**: DevOps Team (emergency-alerts channel)

**Related Documents**:
- [FILE_ARCHITECTURE_OVERVIEW.md](./FILE_ARCHITECTURE_OVERVIEW.md)
- [FILE_MANAGEMENT_DEVELOPER_GUIDE.md](./FILE_MANAGEMENT_DEVELOPER_GUIDE.md)
- [FILES_MANAGMENT_REFACTOR.md](./FILES_MANAGMENT_REFACTOR.md)

**Operational Scripts**:
- Main cleanup: `/ludora-api/scripts/cleanup-orphaned-files.js`
- System validation: `/ludora-utils/scripts/validate-file-system.js`
- Database references: `/ludora-api/scripts/utils/databaseReferenceCollector.js`
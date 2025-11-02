# Step 3: Comprehensive Testing

> **Parent Document**: `FILES_MANAGMENT_REFACTOR.md`
> **Status**: NOT_STARTED
> **Priority**: HIGH - Critical validation step

## Overview

Conduct comprehensive testing of ALL file upload scenarios across ALL entity types to ensure complete system functionality and S3/database consistency after Steps 1 and 2 fixes.

## Problem Statement

### Testing Scope Required
The file management system spans multiple layers and entity types:
- **3 File Layers**: Marketing, Content, System
- **7 Entity Types**: Product, File, LessonPlan, Workshop, Course, School, Settings, AudioFile
- **Multiple Asset Types**: Images, videos, documents, audio files
- **Various Upload Scenarios**: New uploads, replacements, deletions

### Critical Validation Points
1. **S3/Database Consistency** - Files must match database records exactly
2. **Cross-Entity Functionality** - No regressions in any entity type
3. **Error Handling** - Graceful failures and rollback capabilities
4. **Performance** - No degradation in upload times or responsiveness

## Testing Strategy

### Phase 1: Marketing Layer Testing (Product Entity)
Test marketing assets for ALL Product types:

#### File Products
- [ ] Marketing image upload to File product
- [ ] Marketing image deletion from File product
- [ ] Marketing video upload (YouTube) to File product
- [ ] Marketing video upload (uploaded) to File product
- [ ] Marketing video deletion from File product

#### LessonPlan Products
- [ ] Marketing image upload to LessonPlan product
- [ ] Marketing image deletion from LessonPlan product
- [ ] Marketing video upload (YouTube) to LessonPlan product
- [ ] Marketing video upload (uploaded) to LessonPlan product
- [ ] Marketing video deletion from LessonPlan product

#### Workshop Products
- [ ] Marketing image upload to Workshop product
- [ ] Marketing image deletion from Workshop product
- [ ] Marketing video upload (YouTube) to Workshop product
- [ ] Marketing video upload (uploaded) to Workshop product
- [ ] Marketing video deletion from Workshop product

#### Course Products
- [ ] Marketing image upload to Course product
- [ ] Marketing image deletion from Course product
- [ ] Marketing video upload (YouTube) to Course product
- [ ] Marketing video upload (uploaded) to Course product
- [ ] Marketing video deletion from Course product

#### Game Products
- [ ] Marketing image upload to Game product
- [ ] Marketing image deletion from Game product
- [ ] Marketing video upload (YouTube) to Game product
- [ ] Marketing video upload (uploaded) to Game product
- [ ] Marketing video deletion from Game product

#### Tool Products
- [ ] Marketing image upload to Tool product
- [ ] Marketing image deletion from Tool product
- [ ] Marketing video upload (YouTube) to Tool product
- [ ] Marketing video upload (uploaded) to Tool product
- [ ] Marketing video deletion from Tool product

### Phase 2: Content Layer Testing (Entity-Specific)

#### File Entity Content
- [ ] Document upload (PDF) to File entity
- [ ] Document upload (PPTX) to File entity
- [ ] Document upload (DOCX) to File entity
- [ ] Document upload (ZIP) to File entity
- [ ] Document replacement in File entity
- [ ] Document deletion from File entity
- [ ] Preview settings functionality
- [ ] Footer settings functionality

#### LessonPlan Entity Content
- [ ] Opening file upload (PPT) to LessonPlan entity
- [ ] Body file upload (PPT) to LessonPlan entity
- [ ] Audio file upload (MP3) to LessonPlan entity
- [ ] Asset file upload (any type) to LessonPlan entity
- [ ] Multiple audio files to LessonPlan entity
- [ ] Multiple asset files to LessonPlan entity
- [ ] File product linking to LessonPlan entity
- [ ] File removal from LessonPlan entity
- [ ] Slide configuration functionality

#### Workshop Entity Content
- [ ] Content video upload to Workshop entity
- [ ] Content video replacement in Workshop entity
- [ ] Content video deletion from Workshop entity
- [ ] Legacy video field compatibility

#### Course Entity Content
- [ ] Content video upload to Course entity
- [ ] Content video replacement in Course entity
- [ ] Content video deletion from Course entity
- [ ] Course module video handling

### Phase 3: System Layer Testing (Direct Entity Assets)

#### School Entity
- [ ] Logo upload to School entity
- [ ] Logo replacement in School entity
- [ ] Logo deletion from School entity
- [ ] Legacy logo_url compatibility

#### Settings Entity
- [ ] System logo upload to Settings entity
- [ ] System logo replacement in Settings entity
- [ ] System logo deletion from Settings entity
- [ ] Footer settings configuration
- [ ] Legacy logo_url compatibility

#### AudioFile Entity
- [ ] Audio file upload to AudioFile entity
- [ ] Audio file replacement in AudioFile entity
- [ ] Audio file deletion from AudioFile entity
- [ ] Audio metadata handling (duration, size, type)

### Phase 4: Edge Case Testing

#### Invalid Scenarios
- [ ] Corrupted entity IDs
- [ ] Non-existent entity references
- [ ] Unsupported file types
- [ ] File size limits
- [ ] Network interruptions during upload
- [ ] S3 service unavailability
- [ ] Database connection failures

#### Security Testing
- [ ] Unauthorized file access attempts
- [ ] File type validation bypass attempts
- [ ] Path traversal attempts
- [ ] Large file upload attacks

#### Performance Testing
- [ ] Multiple simultaneous uploads
- [ ] Large file uploads (>100MB)
- [ ] Rapid consecutive uploads
- [ ] Memory usage during uploads
- [ ] Browser tab closure during upload

## Testing Implementation

### Automated Testing Scripts
Create comprehensive test scripts for:

#### Unit Tests
```javascript
// Test entity mapping logic
describe('Entity Mapping', () => {
  test('Marketing assets use Product entity', () => {
    // Test all Product types with marketing assets
  });

  test('Content assets use specific entity', () => {
    // Test all entity types with content assets
  });
});
```

#### Integration Tests
```javascript
// Test complete upload flows
describe('Upload Flows', () => {
  test('File product marketing image upload', async () => {
    // Full upload + database check + S3 verification
  });

  test('LessonPlan categorized file upload', async () => {
    // Full upload + file_configs check + S3 verification
  });
});
```

#### E2E Tests
```javascript
// Test complete user workflows
describe('User Workflows', () => {
  test('Create File product with document and marketing image', async () => {
    // Complete product creation workflow
  });

  test('Create LessonPlan with all file types', async () => {
    // Complete lesson plan creation workflow
  });
});
```

### Manual Testing Checklist

#### For Each Upload Scenario
1. **Before Upload**
   - [ ] Document initial database state
   - [ ] Check S3 bucket contents
   - [ ] Verify entity exists and is valid

2. **During Upload**
   - [ ] Monitor upload progress
   - [ ] Check browser network tab for API calls
   - [ ] Watch server logs for errors
   - [ ] Note any UI feedback issues

3. **After Upload**
   - [ ] Verify file appears in UI immediately
   - [ ] Check database fields are updated correctly
   - [ ] Confirm S3 file exists at expected path
   - [ ] Test file access/download functionality
   - [ ] Refresh page and verify persistence

4. **After Deletion**
   - [ ] Verify file removed from UI immediately
   - [ ] Check database fields are cleared correctly
   - [ ] Confirm S3 file is deleted
   - [ ] Test that download links are broken

### S3/Database Consistency Validation

#### Automated Consistency Checks
```javascript
// Create utility to verify S3/DB consistency
const validateConsistency = async (entityType, entityId) => {
  const dbRecord = await getEntityRecord(entityType, entityId);
  const s3Files = await listS3Files(entityType, entityId);

  // Check for orphaned S3 files
  const orphanedFiles = s3Files.filter(s3File =>
    !dbRecord.hasFileReference(s3File)
  );

  // Check for missing S3 files
  const missingFiles = dbRecord.getFileReferences().filter(dbFile =>
    !s3Files.includes(dbFile.s3Path)
  );

  return { orphanedFiles, missingFiles };
};
```

#### Manual Consistency Verification
For each entity type:
- [ ] List all database records with file references
- [ ] List all S3 files in corresponding paths
- [ ] Identify orphaned S3 files (no DB reference)
- [ ] Identify missing S3 files (DB reference but no file)
- [ ] Document any inconsistencies found

## Performance Benchmarks

### Baseline Measurements
Record baseline performance for:
- [ ] Single file upload time by size (1MB, 10MB, 50MB, 100MB)
- [ ] Simultaneous upload handling (2, 5, 10 concurrent uploads)
- [ ] Database query performance for file operations
- [ ] S3 upload/download speeds
- [ ] UI responsiveness during uploads

### Performance Validation
After fixes, ensure:
- [ ] No degradation in upload speeds
- [ ] No increase in database query times
- [ ] No memory leaks during uploads
- [ ] UI remains responsive under load

## Error Handling Validation

### Error Scenarios
Test graceful handling of:
- [ ] Network timeouts during upload
- [ ] S3 service errors
- [ ] Database connection issues
- [ ] Invalid file types
- [ ] File size limit exceeded
- [ ] Insufficient permissions
- [ ] Duplicate file uploads

### Error Response Validation
For each error scenario:
- [ ] User receives clear, helpful error message
- [ ] Partial uploads are cleaned up properly
- [ ] System state remains consistent
- [ ] User can retry the operation
- [ ] Error is logged for debugging

## Regression Testing

### Existing Functionality Validation
Ensure no regressions in:
- [ ] User authentication and authorization
- [ ] Product creation and editing workflows
- [ ] File preview and download functionality
- [ ] Footer settings and PDF generation
- [ ] Admin-only features and restrictions
- [ ] Payment and purchase workflows
- [ ] Search and catalog functionality

### Legacy Compatibility
Verify continued support for:
- [ ] Existing products with legacy field values
- [ ] Old S3 paths and file references
- [ ] Deprecated but still-used API endpoints
- [ ] Browser compatibility across supported versions

## Success Criteria

### Technical Validation
- [ ] 100% of test scenarios pass
- [ ] Zero S3/database inconsistencies
- [ ] No performance degradation
- [ ] All error scenarios handled gracefully
- [ ] No regressions in existing functionality

### User Experience Validation
- [ ] File uploads are intuitive and responsive
- [ ] Error messages are clear and actionable
- [ ] Upload progress is accurately displayed
- [ ] File management operations work reliably

### System Health Validation
- [ ] No memory leaks or resource issues
- [ ] Server logs show no unexpected errors
- [ ] S3 storage usage is reasonable
- [ ] Database performance remains optimal

## Documentation Requirements

### Test Results Documentation
For each test scenario:
- [ ] Expected behavior description
- [ ] Actual behavior observed
- [ ] Any issues or deviations found
- [ ] Screenshots or logs where relevant
- [ ] Resolution steps for any failures

### Performance Results Documentation
- [ ] Benchmark measurements before and after
- [ ] Performance impact analysis
- [ ] Recommendations for optimization
- [ ] Monitoring setup for ongoing validation

## Problems Found
*To be filled during implementation*

## Solutions Applied
*To be filled during implementation*

## Testing Results
*To be filled during implementation*

## Next Steps
*To be filled during implementation*

---

**Created**: October 31, 2025
**Last Updated**: October 31, 2025
**Status**: NOT_STARTED
**Assigned**: Pending
**Estimated Time**: 1-2 days
**Dependencies**: Step 1 and Step 2 completion
**Blocks**: Step 4 (Orphan File Cleanup)
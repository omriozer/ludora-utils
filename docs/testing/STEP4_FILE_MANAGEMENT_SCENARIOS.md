# Step 4: File Management Scenarios

> **Parent Document**: `UI_TESTING_IMPLEMENTATION.md`
> **Status**: NOT_STARTED
> **Priority**: CRITICAL - Validates Recently Refactored File System

## Overview

Implement comprehensive file management test scenarios to validate the recently refactored 3-layer file architecture. These tests ensure the upload workflows, S3/database consistency, race condition handling, and file serving functionality work correctly across all entity types and asset categories.

## Objectives

1. **Validate 3-Layer Architecture** - Marketing, Content, and System asset separation
2. **Test Upload Workflows** - All file types across all entity types
3. **Verify S3/Database Consistency** - Ensure no orphan files or database mismatches
4. **Race Condition Testing** - Validate upload-to-serve timing fixes
5. **Entity ID Validation** - Test the enhanced validation and error handling

## File Management Architecture Review

### 3-Layer File Architecture (Recently Refactored)
```
📈 Marketing Layer (Product Entity)
├── Marketing images (has_image, image_filename)
├── Marketing videos (marketing_video_type, marketing_video_id)
└── Applied to ALL product types (file, lesson_plan, workshop, course, etc.)

📚 Content Layer (Entity-Specific)
├── File Entity: Documents (file_name)
├── LessonPlan Entity: Categorized files (file_configs JSONB)
├── Workshop/Course Entity: Content videos (has_video, video_filename)
└── Content specific to each entity type

⚙️ System Layer (Direct Entity Assets)
├── School Entity: Institution logos (has_logo, logo_filename)
├── Settings Entity: System logos (has_logo, logo_filename)
└── AudioFile Entity: Audio content (has_file, file_filename)
```

### Recent Fixes Validated
- ✅ Backend EntityService routing logic fixed
- ✅ Frontend entity ID validation enhanced
- ✅ Race condition handling implemented
- ✅ Upload-to-serve flow validated

## Test Scenarios Implementation

### Marketing Layer Tests (Priority 1 - Recently Fixed)

#### FILE-001: Product Marketing Image Upload
```javascript
// cypress/e2e/file-management/marketing-image-upload.cy.js
import { ProductCreationPage } from '../../support/page-objects/ProductCreationPage'
import { FileHelpers } from '../../support/helpers/file-helpers'

describe('File Management - Marketing Image Upload', () => {
  const productPage = new ProductCreationPage()

  beforeEach(() => {
    cy.loginAsUser()
    cy.task('cleanupTestProducts')
  })

  afterEach(() => {
    cy.task('cleanupTestFiles')
  })

  it('FILE-001 should upload marketing image for File product', () => {
    cy.fixture('products').then((products) => {
      const fileProduct = products.fileProduct

      // Arrange: Create File product
      productPage
        .visit()
        .selectProductType('file')
        .fillProductDetails(fileProduct)

      // Act: Upload marketing image
      cy.uploadMarketingImage('test-image.jpg')
      cy.submitProduct()

      // Assert: Verify upload success
      cy.verifyToast('המוצר נוצר בהצלחה') // Hebrew: Product created successfully
      cy.verifyRedirectTo('/products')

      // Verify S3 upload
      cy.verifyS3FileExists('development/public/image/file', '@productId', 'image.jpg')

      // Verify database consistency
      cy.verifyDatabaseRecord('product', '@productId', {
        has_image: true,
        image_filename: 'image.jpg'
      })

      // Verify image serving
      cy.verifyImageServing('file', '@productId', 'image.jpg')
    })
  })

  it('FILE-002 should upload marketing image for LessonPlan product', () => {
    cy.fixture('products').then((products) => {
      const lessonPlan = products.lessonPlan

      productPage
        .visit()
        .selectProductType('lesson_plan')
        .fillProductDetails(lessonPlan)

      cy.uploadMarketingImage('test-image.jpg')
      cy.submitProduct()

      // Verify S3 path for lesson_plan type
      cy.verifyS3FileExists('development/public/image/lesson_plan', '@productId', 'image.jpg')

      // Verify database on Product entity (not LessonPlan entity)
      cy.verifyDatabaseRecord('product', '@productId', {
        has_image: true,
        image_filename: 'image.jpg'
      })
    })
  })

  it('FILE-003 should handle race condition gracefully', () => {
    cy.fixture('products').then((products) => {
      productPage
        .visit()
        .selectProductType('file')
        .fillProductDetails(products.fileProduct)

      cy.uploadMarketingImage('test-image.jpg')
      cy.submitProduct()

      // Immediately try to view the image (test race condition fix)
      cy.get('@productId').then((productId) => {
        cy.visit(`/product-details?id=${productId}`)

        // The race condition fix should handle the timing
        cy.get('[data-testid="product-image"]', { timeout: 10000 })
          .should('be.visible')
          .and('have.attr', 'src')
          .and('include', '/api/assets/image/')
      })
    })
  })

  it('FILE-004 should validate file type restrictions', () => {
    productPage
      .visit()
      .selectProductType('file')

    // Try to upload invalid file type
    cy.uploadMarketingImage('test-document.pdf') // PDF instead of image

    cy.verifyError('רק קבצי תמונה מותרים') // Hebrew: Only image files allowed
    cy.verifyUploadRejected()
  })

  it('FILE-005 should handle large file uploads', () => {
    productPage
      .visit()
      .selectProductType('file')

    // Try to upload large image
    cy.uploadMarketingImage('test-image-large.jpg') // > 5MB file

    cy.verifyError('גודל הקובץ חורג מהמותר') // Hebrew: File size exceeds limit
    cy.verifyUploadRejected()
  })
})
```

#### FILE-006: Marketing Video Upload
```javascript
// cypress/e2e/file-management/marketing-video-upload.cy.js
describe('File Management - Marketing Video Upload', () => {
  beforeEach(() => {
    cy.loginAsUser()
  })

  it('FILE-006 should upload marketing video file', () => {
    cy.fixture('products').then((products) => {
      const productPage = new ProductCreationPage()

      productPage
        .visit()
        .selectProductType('workshop')
        .fillProductDetails(products.workshop)

      // Upload video file
      cy.uploadMarketingVideo('test-video.mp4')
      cy.submitProduct()

      // Verify S3 upload to marketing-video path
      cy.verifyS3FileExists('development/public/marketing-video/workshop', '@productId', 'video.mp4')

      // Verify database fields
      cy.verifyDatabaseRecord('product', '@productId', {
        marketing_video_type: 'uploaded',
        marketing_video_id: 'video.mp4'
      })
    })
  })

  it('FILE-007 should handle YouTube video embed', () => {
    const productPage = new ProductCreationPage()

    productPage
      .visit()
      .selectProductType('course')

    // Add YouTube video
    cy.addYouTubeVideo('https://www.youtube.com/watch?v=dQw4w9WgXcQ')
    cy.submitProduct()

    // Verify database fields for YouTube
    cy.verifyDatabaseRecord('product', '@productId', {
      marketing_video_type: 'youtube',
      marketing_video_id: 'dQw4w9WgXcQ'
    })

    // Verify no S3 upload for YouTube
    cy.verifyS3FileNotExists('development/public/marketing-video/course', '@productId')
  })
})
```

### Content Layer Tests

#### FILE-008: Document Upload (File Entity)
```javascript
// cypress/e2e/file-management/document-upload.cy.js
describe('File Management - Document Upload', () => {
  beforeEach(() => {
    cy.loginAsUser()
  })

  it('FILE-008 should upload document to File entity', () => {
    const productPage = new ProductCreationPage()

    productPage
      .visit()
      .selectProductType('file')
      .fillProductDetails({
        name: 'Test Document Product',
        description: 'Test document for automation'
      })

    // Upload document file
    cy.uploadDocument('test-document.pdf')
    cy.submitProduct()

    // Verify S3 upload to private document path
    cy.verifyS3FileExists('development/private/document/file', '@fileId', 'test-document.pdf')

    // Verify database on File entity
    cy.verifyDatabaseRecord('file', '@fileId', {
      file_name: 'test-document.pdf'
    })

    // Verify document serving with authentication
    cy.verifyDocumentServing('file', '@fileId', 'test-document.pdf')
  })

  it('FILE-009 should support multiple document formats', () => {
    const supportedFormats = [
      { file: 'test-document.pdf', type: 'PDF' },
      { file: 'test-presentation.pptx', type: 'PowerPoint' },
      { file: 'test-spreadsheet.xlsx', type: 'Excel' },
      { file: 'test-document.docx', type: 'Word' }
    ]

    supportedFormats.forEach((format) => {
      cy.createFileProduct(`Test ${format.type} Product`)
      cy.uploadDocument(format.file)
      cy.submitProduct()

      cy.verifyS3FileExists('development/private/document/file', '@fileId', format.file)
      cy.verifyDatabaseRecord('file', '@fileId', {
        file_name: format.file
      })
    })
  })
})
```

#### FILE-010: LessonPlan File Management
```javascript
// cypress/e2e/file-management/lesson-plan-files.cy.js
describe('File Management - LessonPlan Files', () => {
  beforeEach(() => {
    cy.loginAsUser()
  })

  it('FILE-010 should upload opening presentation', () => {
    const productPage = new ProductCreationPage()

    productPage
      .visit()
      .selectProductType('lesson_plan')
      .fillBasicDetails({
        name: 'Test Lesson Plan',
        subject: 'Mathematics'
      })

    // Upload opening presentation (PPT only)
    cy.uploadLessonPlanFile('opening', 'test-presentation.pptx')
    cy.submitProduct()

    // Verify S3 upload to lesson-plan categorized path
    cy.verifyS3FileExists('development/private/lesson-plan', '@lessonPlanId', 'test-presentation.pptx')

    // Verify database JSONB field
    cy.verifyDatabaseRecord('lessonplan', '@lessonPlanId', {
      'file_configs.opening': [
        {
          filename: 'test-presentation.pptx',
          upload_method: 'upload_new'
        }
      ]
    })
  })

  it('FILE-011 should upload multiple audio files', () => {
    const audioFiles = ['test-audio1.mp3', 'test-audio2.wav', 'test-audio3.m4a']

    const productPage = new ProductCreationPage()

    productPage
      .visit()
      .selectProductType('lesson_plan')
      .fillBasicDetails({
        name: 'Audio Test Lesson Plan'
      })

    // Upload multiple audio files
    audioFiles.forEach((audioFile) => {
      cy.uploadLessonPlanFile('audio', audioFile)
    })

    cy.submitProduct()

    // Verify all audio files uploaded
    audioFiles.forEach((audioFile) => {
      cy.verifyS3FileExists('development/private/lesson-plan', '@lessonPlanId', audioFile)
    })

    // Verify database JSONB structure
    cy.verifyDatabaseRecord('lessonplan', '@lessonPlanId', {
      'file_configs.audio': audioFiles.map(file => ({
        filename: file,
        upload_method: 'upload_new'
      }))
    })
  })

  it('FILE-012 should enforce PPT-only restriction for opening/body', () => {
    const productPage = new ProductCreationPage()

    productPage
      .visit()
      .selectProductType('lesson_plan')

    // Try to upload non-PPT file to opening
    cy.uploadLessonPlanFile('opening', 'test-document.pdf')

    cy.verifyError('רק קבצי PowerPoint מותרים עבור פתיחה וגוף השיעור') // Hebrew: Only PowerPoint files allowed for opening and body
    cy.verifyUploadRejected()
  })
})
```

### System Layer Tests

#### FILE-013: School Logo Upload
```javascript
// cypress/e2e/file-management/school-logo-upload.cy.js
describe('File Management - School Logo Upload', () => {
  beforeEach(() => {
    cy.loginAsAdmin() // Admin required for school management
  })

  it('FILE-013 should upload school logo', () => {
    cy.visit('/schools')
    cy.createSchool('Test School')

    cy.uploadSchoolLogo('test-logo.png')
    cy.saveSchool()

    // Verify S3 upload to public school path
    cy.verifyS3FileExists('development/public/image/school', '@schoolId', 'logo.png')

    // Verify database on School entity
    cy.verifyDatabaseRecord('school', '@schoolId', {
      has_logo: true,
      logo_filename: 'logo.png'
    })

    // Verify logo serving (public access)
    cy.verifyLogoServing('school', '@schoolId', 'logo.png')
  })
})
```

#### FILE-014: AudioFile Management
```javascript
// cypress/e2e/file-management/audio-file-management.cy.js
describe('File Management - AudioFile Management', () => {
  beforeEach(() => {
    cy.loginAsAdmin()
  })

  it('FILE-014 should upload and manage audio files', () => {
    cy.visit('/audio')
    cy.createAudioFile('Test Background Music')

    cy.uploadAudioFile('test-background-music.mp3')
    cy.saveAudioFile()

    // Verify S3 upload to private audio path
    cy.verifyS3FileExists('development/private/audio/audiofile', '@audioFileId', 'test-background-music.mp3')

    // Verify database with metadata
    cy.verifyDatabaseRecord('audiofile', '@audioFileId', {
      has_file: true,
      file_filename: 'test-background-music.mp3',
      file_size: cy.getFileSize('test-background-music.mp3'),
      file_type: 'audio/mpeg'
    })

    // Verify audio serving with authentication
    cy.verifyAudioServing('audiofile', '@audioFileId', 'test-background-music.mp3')
  })
})
```

### Integration and Consistency Tests

#### FILE-015: S3/Database Consistency Validation
```javascript
// cypress/e2e/file-management/s3-database-consistency.cy.js
describe('File Management - S3/Database Consistency', () => {
  beforeEach(() => {
    cy.loginAsUser()
    cy.task('cleanupTestData')
  })

  it('FILE-015 should maintain S3/database consistency across all layers', () => {
    // Create files across all layers
    const testData = [
      { type: 'file', layer: 'marketing', asset: 'image' },
      { type: 'lesson_plan', layer: 'marketing', asset: 'image' },
      { type: 'workshop', layer: 'content', asset: 'video' },
      { type: 'file', layer: 'content', asset: 'document' }
    ]

    testData.forEach((test) => {
      cy.createProductWithAsset(test.type, test.asset)

      // Verify consistency
      cy.verifyS3DatabaseConsistency(test.type, '@entityId', test.asset)
    })

    // Run consistency validation script
    cy.task('validateFileSystemConsistency').then((result) => {
      expect(result.orphanFiles).to.equal(0)
      expect(result.missingFiles).to.equal(0)
      expect(result.inconsistencies).to.equal(0)
    })
  })

  it('FILE-016 should detect and handle orphan files', () => {
    // Create orphan file scenario
    cy.createProductWithImage('file')
    cy.deleteProductKeepingS3File('@productId')

    // Verify orphan detection
    cy.task('detectOrphanFiles').then((orphans) => {
      expect(orphans.length).to.be.greaterThan(0)
    })

    // Run cleanup
    cy.task('cleanupOrphanFiles')

    // Verify cleanup
    cy.task('detectOrphanFiles').then((orphans) => {
      expect(orphans.length).to.equal(0)
    })
  })
})
```

#### FILE-017: Entity ID Validation
```javascript
// cypress/e2e/file-management/entity-id-validation.cy.js
describe('File Management - Entity ID Validation', () => {
  beforeEach(() => {
    cy.loginAsUser()
  })

  it('FILE-017 should validate entity IDs before upload', () => {
    // Test corrupted entity ID pattern (previously caused issues)
    const corruptedId = '1760716453729iku75fgz2'

    cy.intercept('POST', '/api/assets/upload*').as('uploadRequest')

    // Try to upload with corrupted ID
    cy.uploadImageToProduct(corruptedId, 'test-image.jpg')

    cy.wait('@uploadRequest').then((interception) => {
      // Should be rejected by enhanced validation
      expect(interception.response.statusCode).to.equal(400)
      expect(interception.response.body.error).to.include('Invalid entity ID')
    })
  })

  it('FILE-018 should accept valid entity IDs', () => {
    const validIds = [
      'prod123',
      'file-abc-123',
      'lesson_plan_456',
      'workshop789'
    ]

    validIds.forEach((validId) => {
      cy.createMockProduct(validId)
      cy.uploadImageToProduct(validId, 'test-image.jpg')
      cy.verifyUploadSuccess()
    })
  })
})
```

### Custom File Management Commands

#### File Upload Commands
```javascript
// cypress/support/commands.js - File management commands

// Marketing image upload
Cypress.Commands.add('uploadMarketingImage', (fileName) => {
  cy.get('[data-testid="marketing-image-upload"]')
    .selectFile(`cypress/fixtures/test-files/images/${fileName}`, { force: true })

  cy.get('[data-testid="upload-progress"]').should('be.visible')
  cy.get('[data-testid="upload-success"]', { timeout: 30000 }).should('be.visible')
})

// Document upload
Cypress.Commands.add('uploadDocument', (fileName) => {
  cy.get('[data-testid="document-upload"]')
    .selectFile(`cypress/fixtures/test-files/documents/${fileName}`, { force: true })

  cy.verifyUploadProgress()
  cy.verifyUploadComplete()
})

// LessonPlan categorized file upload
Cypress.Commands.add('uploadLessonPlanFile', (category, fileName) => {
  cy.get(`[data-testid="lesson-plan-${category}-upload"]`)
    .selectFile(`cypress/fixtures/test-files/${fileName}`, { force: true })

  cy.verifyUploadProgress()
  cy.verifyUploadComplete()
})

// S3 verification commands
Cypress.Commands.add('verifyS3FileExists', (bucketPath, entityId, fileName) => {
  cy.task('s3:fileExists', {
    path: `${bucketPath}/${entityId}/${fileName}`
  }).should('equal', true)
})

Cypress.Commands.add('verifyS3FileNotExists', (bucketPath, entityId) => {
  cy.task('s3:listFiles', {
    path: `${bucketPath}/${entityId}/`
  }).should('have.length', 0)
})

// File serving verification
Cypress.Commands.add('verifyImageServing', (entityType, entityId, fileName) => {
  cy.request({
    url: `/api/assets/image/${entityType}/${entityId}/${fileName}`,
    headers: {
      'Authorization': `Bearer ${Cypress.env('authToken')}`
    }
  }).then((response) => {
    expect(response.status).to.equal(200)
    expect(response.headers['content-type']).to.include('image')
  })
})

// Database verification
Cypress.Commands.add('verifyDatabaseRecord', (table, id, expectedFields) => {
  cy.task('db:findRecord', { table, id }).then((record) => {
    Object.keys(expectedFields).forEach((field) => {
      if (field.includes('.')) {
        // Handle JSONB fields like 'file_configs.opening'
        const [parentField, childField] = field.split('.')
        expect(record[parentField][childField]).to.deep.equal(expectedFields[field])
      } else {
        expect(record[field]).to.equal(expectedFields[field])
      }
    })
  })
})
```

## Implementation Priority

### Phase 4.1: Marketing Layer (P0 - Critical)
- [ ] Product marketing image uploads for all product types
- [ ] Marketing video uploads (file + YouTube)
- [ ] Race condition handling validation
- [ ] Entity ID validation testing

### Phase 4.2: Content Layer (P0 - Critical)
- [ ] File entity document uploads
- [ ] LessonPlan categorized file uploads
- [ ] Workshop/Course content video uploads
- [ ] File type and size validation

### Phase 4.3: System Layer (P1 - High)
- [ ] School logo uploads
- [ ] Settings logo management
- [ ] AudioFile content management
- [ ] Metadata tracking validation

### Phase 4.4: Integration Testing (P1 - High)
- [ ] S3/Database consistency validation
- [ ] Orphan file detection and cleanup
- [ ] Cross-layer consistency checks
- [ ] Performance and reliability testing

## Validation Criteria

### Upload Functionality
- [ ] All file types upload successfully to correct S3 paths
- [ ] Database records updated with correct standardized fields
- [ ] File serving works immediately after upload
- [ ] Error handling graceful for invalid uploads

### Architecture Validation
- [ ] 3-layer separation maintained correctly
- [ ] Marketing assets always on Product entity
- [ ] Content assets on appropriate entity types
- [ ] System assets on direct entities

### Consistency and Reliability
- [ ] No orphan files created during testing
- [ ] S3 and database always synchronized
- [ ] Race conditions handled gracefully
- [ ] Entity ID validation prevents corrupted calls

## Implementation Status

### ⏳ NOT STARTED - Ready for Implementation

#### Test Cases to Implement
- [ ] FILE-001 to FILE-018: Comprehensive file management scenarios
- [ ] Custom commands for file operations
- [ ] S3 and database verification utilities
- [ ] Consistency validation tools

#### Dependencies
- **Step 3**: Authentication scenarios (file uploads require login)
- **Prerequisites**: Test files in fixtures directory
- **Environment**: S3 development bucket accessible

### Next Steps After Completion
1. **Validate Refactored System**: Ensure all file management fixes work correctly
2. **Performance Testing**: Test large file uploads and concurrent operations
3. **Begin Business Flows**: Proceed to Step 5 with validated file uploads
4. **Document Findings**: Update architecture documentation with test insights

## Problems Found
*To be filled during implementation*

## Solutions Applied
*To be filled during implementation*

## Testing Results
*To be filled during implementation*

## Implementation Notes
*To be filled during implementation*

---

**Created**: October 31, 2025
**Last Updated**: October 31, 2025
**Status**: NOT_STARTED
**Assigned**: Pending
**Estimated Time**: 3-4 days
**Dependencies**: Steps 1, 2, 3 completed
**Blocks**: Step 5 (business flows require file uploads)

**Related Documents**:
- [UI_TESTING_IMPLEMENTATION.md](./UI_TESTING_IMPLEMENTATION.md) - Master plan
- [STEP3_AUTHENTICATION_SCENARIOS.md](./STEP3_AUTHENTICATION_SCENARIOS.md) - Previous step
- [STEP5_BUSINESS_FLOW_SCENARIOS.md](./STEP5_BUSINESS_FLOW_SCENARIOS.md) - Next step
- [FILES_MANAGMENT_REFACTOR.md](../architecture/FILES_MANAGMENT_REFACTOR.md) - Related refactor
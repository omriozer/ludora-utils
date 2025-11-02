# File Management Developer Guide

> **Status**: Production Ready ✅
> **Target Audience**: Developers implementing file upload functionality
> **Prerequisites**: Basic knowledge of React, Node.js, and SQL

## Quick Start

### Adding File Upload to Existing Entity

**1. Database Migration**
```sql
-- Add standardized file fields to your entity
ALTER TABLE your_entity ADD COLUMN has_image BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE your_entity ADD COLUMN image_filename VARCHAR(255) NULL;
```

**2. Backend Model (Sequelize)**
```javascript
// models/YourEntity.js
YourEntity.prototype.hasImageAsset = function() {
  return this.has_image === true;
};

YourEntity.prototype.getImageFilename = function() {
  return this.image_filename;
};
```

**3. Frontend Implementation**
```javascript
// components/YourEntityForm.jsx
import { useUnifiedAssetUploads } from '@/hooks/useUnifiedAssetUploads';

const YourEntityForm = ({ entity }) => {
  const { handleAssetUpload, hasAsset, getAssetUrl } = useUnifiedAssetUploads(entity);

  const handleImageUpload = async (event) => {
    await handleAssetUpload(event, 'image', { isPublic: true });
  };

  return (
    <div>
      {hasAsset('image') && (
        <img src={getAssetUrl('image')} alt="Entity image" />
      )}
      <input type="file" onChange={handleImageUpload} accept="image/*" />
    </div>
  );
};
```

## Entity-Specific Implementation Patterns

### Product Entity (Marketing Assets)

Marketing assets are **always stored on the Product entity**, regardless of product type.

```javascript
// ✅ CORRECT: Marketing image for any product type
const product = await models.Product.create({
  name: 'My File Product',
  type: 'file',  // or 'lesson_plan', 'workshop', etc.
  has_image: false,  // Will be updated when image is uploaded
  image_filename: null
});

// Frontend: Marketing image upload
const { handleAssetUpload } = useUnifiedAssetUploads(product);
await handleAssetUpload(event, 'image', { isPublic: true });  // Public for marketing
```

**Key Principles**:
- Marketing assets belong to **Product entity only**
- All product types (`file`, `lesson_plan`, `workshop`, `course`, `game`, `tool`) use same pattern
- Marketing images are **public** (accessible without authentication)
- Marketing videos can be YouTube embeds or uploaded MP4 files

### File Entity (Document Content)

Files contain documents for download with preview and footer features.

```javascript
// Backend: File entity with document
const file = await models.File.create({
  name: 'Important Document',
  file_name: null,  // Will be set on upload
  allow_preview: true,
  add_copyrights_footer: true,
  footer_settings: {
    text: { content: 'Company Confidential', visible: true },
    logo: { visible: true }
  }
});

// Frontend: Document upload
const { handleAssetUpload } = useUnifiedAssetUploads(file);
await handleAssetUpload(event, 'document', {
  isPublic: false,  // Private for content
  allowedTypes: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'zip', 'txt']
});
```

**Key Principles**:
- Documents are **private** (require authentication)
- Support preview functionality with footer customization
- Specific file type restrictions for security
- S3 path: `private/document/file/{file_id}/{filename}`

### LessonPlan Entity (Complex File Structure)

LessonPlans have the most complex file structure with categorized uploads.

```javascript
// Backend: LessonPlan with file categories
const lessonPlan = await models.LessonPlan.create({
  title: 'Math Lesson',
  file_configs: {
    opening: null,    // PPT files only, 1 max
    body: null,       // PPT files only, 1 max
    audio: [],        // MP3/WAV/M4A, multiple allowed
    assets: []        // Any file type, multiple allowed
  }
});

// Frontend: Category-specific uploads
const { handleAssetUpload } = useUnifiedAssetUploads(lessonPlan);

// Opening slide upload (PPT only, 1 max)
await handleAssetUpload(event, 'lesson-plan-opening', {
  isPublic: false,
  allowedTypes: ['ppt', 'pptx'],
  maxFiles: 1
});

// Audio files (multiple allowed)
await handleAssetUpload(event, 'lesson-plan-audio', {
  isPublic: false,
  allowedTypes: ['mp3', 'wav', 'm4a'],
  maxFiles: 10
});

// Asset files (any type, multiple allowed)
await handleAssetUpload(event, 'lesson-plan-assets', {
  isPublic: false,
  allowedTypes: '*',
  maxFiles: 20
});
```

**LessonPlan Upload Methods**:
1. **Upload New (Asset Only)**: Creates File with `is_asset_only: true`
2. **Create Product**: Creates standalone File product, then links
3. **Link Existing**: Links existing File product (PPT only for opening/body)

### Workshop/Course Entities (Content Videos)

Workshop and Course entities focus on video content delivery.

```javascript
// Backend: Workshop with content video
const workshop = await models.Workshop.create({
  title: 'Advanced JavaScript',
  has_video: false,
  video_filename: null,
  // Legacy field (deprecated but still supported)
  video_file_url: null
});

// Frontend: Video upload
const { handleAssetUpload } = useUnifiedAssetUploads(workshop);
await handleAssetUpload(event, 'content-video', {
  isPublic: false,  // Private content
  allowedTypes: ['mp4', 'mov', 'avi', 'webm'],
  maxFileSize: 500 * 1024 * 1024  // 500MB limit
});
```

### System Entities (Logos and Audio)

System entities handle institutional branding and standalone audio.

```javascript
// School logo (public)
const school = await models.School.create({
  name: 'Springfield Elementary',
  has_logo: false,
  logo_filename: null
});

await handleAssetUpload(event, 'logo', { isPublic: true });

// AudioFile (private with metadata)
const audioFile = await models.AudioFile.create({
  title: 'Background Music',
  has_file: false,
  file_filename: null,
  duration: null,  // Automatically set on upload
  file_size: null,
  file_type: null
});

await handleAssetUpload(event, 'audio', { isPublic: false });
```

## Advanced Patterns

### Entity ID Validation

**Always validate entity IDs before API calls to prevent corruption**:

```javascript
// Built into useUnifiedAssetUploads hook
const isValidEntityId = (entityId) => {
  if (!entityId) return false;
  if (typeof entityId !== 'string') return false;
  if (entityId.length > 50) return false;
  if (entityId.includes('undefined')) return false;
  if (entityId.includes('null')) return false;
  if (!/^[a-zA-Z0-9_-]+$/.test(entityId)) return false;
  if (/^\d{10,}\w+$/.test(entityId)) return false; // Detects corrupted IDs
  return true;
};

// Usage in custom implementations
if (!isValidEntityId(entity.id)) {
  throw new Error('Invalid entity ID detected');
}
```

### Asset Type Classification

```javascript
const ASSET_TYPES = {
  MARKETING: ['image', 'marketing_video'],
  CONTENT: ['document', 'content_video', 'lesson-plan-opening', 'lesson-plan-body', 'lesson-plan-audio', 'lesson-plan-assets'],
  SYSTEM: ['logo', 'audio']
};

const getAssetLayer = (assetType) => {
  if (ASSET_TYPES.MARKETING.includes(assetType)) return 'marketing';
  if (ASSET_TYPES.CONTENT.includes(assetType)) return 'content';
  if (ASSET_TYPES.SYSTEM.includes(assetType)) return 'system';
  return 'unknown';
};

// Use in entity mapping
const getEntityMapping = (entity, assetType) => {
  const layer = getAssetLayer(assetType);

  switch (layer) {
    case 'marketing':
      // Marketing assets always go to Product entity
      return {
        entityType: entity.product_type || 'product',
        entityId: entity.id,
        isPublic: true
      };
    case 'content':
      // Content assets go to specific entity
      return {
        entityType: entity.constructor.name.toLowerCase(),
        entityId: entity.id,
        isPublic: false
      };
    case 'system':
      // System assets go to entity directly
      return {
        entityType: entity.constructor.name.toLowerCase(),
        entityId: entity.id,
        isPublic: entity.constructor.name === 'School' || entity.constructor.name === 'Settings'
      };
    default:
      throw new Error(`Unknown asset type: ${assetType}`);
  }
};
```

### Error Handling Patterns

```javascript
// Comprehensive error handling in upload operations
const handleUploadWithErrorHandling = async (event, assetType, options = {}) => {
  try {
    // Validate entity ID first
    if (!isValidEntityId(entity.id)) {
      throw new Error('Invalid entity ID - cannot proceed with upload');
    }

    // Validate file
    const file = event.target.files[0];
    if (!file) {
      throw new Error('No file selected');
    }

    // Validate file type
    if (options.allowedTypes && options.allowedTypes !== '*') {
      const fileExtension = file.name.split('.').pop().toLowerCase();
      if (!options.allowedTypes.includes(fileExtension)) {
        throw new Error(`File type ${fileExtension} not allowed. Allowed types: ${options.allowedTypes.join(', ')}`);
      }
    }

    // Validate file size
    if (options.maxFileSize && file.size > options.maxFileSize) {
      throw new Error(`File size ${formatBytes(file.size)} exceeds limit of ${formatBytes(options.maxFileSize)}`);
    }

    // Perform upload
    const result = await handleAssetUpload(event, assetType, options);

    // Success feedback
    toast({
      title: "קובץ הועלה בהצלחה",
      description: "הקובץ נשמר במערכת",
      variant: "default"
    });

    return result;

  } catch (error) {
    console.error('Upload failed:', error);

    // User-friendly error messages
    toast({
      title: "שגיאה בהעלאת קובץ",
      description: error.message || "אירעה שגיאה לא צפויה",
      variant: "destructive"
    });

    throw error;
  }
};
```

### Transaction Management

```javascript
// Backend: Atomic file operations with transactions
const uploadFileWithTransaction = async (entityType, entityId, file, assetType) => {
  const transaction = await models.sequelize.transaction();

  try {
    // Upload to S3 first
    const s3Result = await uploadToS3(file, {
      entityType,
      entityId,
      assetType,
      environment: process.env.NODE_ENV
    });

    // Update database within transaction
    const updateData = {};
    if (assetType === 'image') {
      updateData.has_image = true;
      updateData.image_filename = s3Result.filename;
    }

    await models[capitalizeEntityType(entityType)].update(
      updateData,
      {
        where: { id: entityId },
        transaction
      }
    );

    // Commit transaction
    await transaction.commit();

    return s3Result;

  } catch (error) {
    // Rollback transaction
    await transaction.rollback();

    // Clean up S3 file if it was uploaded
    if (s3Result && s3Result.s3Key) {
      await deleteFromS3(s3Result.s3Key);
    }

    throw error;
  }
};
```

## Testing Patterns

### Unit Tests for File Operations

```javascript
// tests/fileOperations.test.js
describe('File Operations', () => {
  test('should upload marketing image to Product entity', async () => {
    const product = await models.Product.create({
      name: 'Test Product',
      type: 'file',
      has_image: false
    });

    const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' });

    const result = await uploadEntityFile('product', product.id, mockFile, 'image');

    expect(result.success).toBe(true);

    // Verify database update
    const updatedProduct = await models.Product.findByPk(product.id);
    expect(updatedProduct.has_image).toBe(true);
    expect(updatedProduct.image_filename).toBeTruthy();

    // Verify S3 file exists
    const s3Exists = await checkS3FileExists(result.s3Key);
    expect(s3Exists).toBe(true);
  });

  test('should validate entity ID before upload', async () => {
    const corruptedId = '1760716453729iku75fgz2';

    expect(() => {
      isValidEntityId(corruptedId);
    }).toThrow('Invalid entity ID');
  });
});
```

### Integration Tests

```javascript
// tests/integration/fileUpload.test.js
describe('File Upload Integration', () => {
  test('should handle complete upload flow', async () => {
    // Create test entity
    const file = await models.File.create({
      name: 'Test Document',
      file_name: null
    });

    // Mock file upload
    const uploadResponse = await request(app)
      .post(`/api/entities/file/${file.id}/upload`)
      .attach('file', Buffer.from('test content'), 'test.pdf')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    // Verify response
    expect(uploadResponse.body.success).toBe(true);
    expect(uploadResponse.body.filename).toBe('test.pdf');

    // Verify database update
    const updatedFile = await models.File.findByPk(file.id);
    expect(updatedFile.file_name).toBe('test.pdf');

    // Verify S3 file
    const s3Key = `development/private/document/file/${file.id}/test.pdf`;
    const s3Object = await s3Client.headObject({
      Bucket: process.env.S3_BUCKET,
      Key: s3Key
    }).promise();
    expect(s3Object).toBeTruthy();
  });
});
```

## Performance Optimization

### Frontend Optimization

```javascript
// Optimized file upload with progress tracking
const useOptimizedFileUpload = (entity) => {
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  const uploadWithProgress = async (file, assetType, options = {}) => {
    setIsUploading(true);
    setUploadProgress(0);

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('assetType', assetType);

      const response = await fetch(`/api/entities/${entity.type}/${entity.id}/upload`, {
        method: 'POST',
        body: formData,
        headers: {
          'Authorization': `Bearer ${getAuthToken()}`
        },
        // Track upload progress
        onUploadProgress: (progressEvent) => {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          setUploadProgress(progress);
        }
      });

      if (!response.ok) {
        throw new Error(`Upload failed: ${response.statusText}`);
      }

      return await response.json();

    } finally {
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  return { uploadWithProgress, uploadProgress, isUploading };
};
```

### Backend Optimization

```javascript
// Optimized S3 upload with multipart for large files
const uploadLargeFile = async (file, s3Params) => {
  const fileSize = file.size;
  const MULTIPART_THRESHOLD = 100 * 1024 * 1024; // 100MB

  if (fileSize > MULTIPART_THRESHOLD) {
    // Use multipart upload for large files
    return await s3Client.upload({
      ...s3Params,
      Body: file,
      PartSize: 10 * 1024 * 1024, // 10MB parts
      QueueSize: 4 // Parallel uploads
    }).promise();
  } else {
    // Standard upload for smaller files
    return await s3Client.putObject({
      ...s3Params,
      Body: file
    }).promise();
  }
};
```

## Security Best Practices

### File Validation

```javascript
// Comprehensive file validation
const validateUploadFile = (file, options = {}) => {
  const errors = [];

  // File size validation
  if (options.maxSize && file.size > options.maxSize) {
    errors.push(`File size exceeds limit of ${formatBytes(options.maxSize)}`);
  }

  // File type validation
  if (options.allowedTypes && options.allowedTypes !== '*') {
    const fileExtension = file.name.split('.').pop().toLowerCase();
    if (!options.allowedTypes.includes(fileExtension)) {
      errors.push(`File type ${fileExtension} not allowed`);
    }
  }

  // File name validation
  if (!/^[a-zA-Z0-9._-]+$/.test(file.name)) {
    errors.push('File name contains invalid characters');
  }

  // Virus scanning (integration point)
  if (options.virusScan) {
    // Integrate with virus scanning service
    const scanResult = scanFileForViruses(file);
    if (!scanResult.clean) {
      errors.push('File failed security scan');
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
};
```

### Access Control

```javascript
// Role-based file access control
const checkFileAccess = (user, entity, assetType) => {
  // Public assets - always accessible
  if (getAssetLayer(assetType) === 'marketing') {
    return true;
  }

  // Private assets - require authentication
  if (!user) {
    throw new Error('Authentication required for private assets');
  }

  // Admin users - full access
  if (user.role === 'admin') {
    return true;
  }

  // Entity ownership checks
  switch (entity.constructor.name) {
    case 'File':
      return user.id === entity.created_by || user.school_id === entity.school_id;
    case 'LessonPlan':
      return user.id === entity.teacher_id || user.school_id === entity.school_id;
    case 'Workshop':
      return user.id === entity.instructor_id;
    default:
      return false;
  }
};
```

## Troubleshooting Guide

### Common Issues and Solutions

**Issue**: Upload succeeds but file doesn't appear in UI
```javascript
// Check entity ID validity
if (!isValidEntityId(entity.id)) {
  console.error('Corrupted entity ID detected:', entity.id);
  // Reload entity from database
  entity = await refetchEntity(entity.id);
}

// Check asset type classification
const layer = getAssetLayer(assetType);
if (layer === 'unknown') {
  console.error('Unknown asset type:', assetType);
}

// Verify hook state updates
const { hasAsset, getAssetUrl } = useUnifiedAssetUploads(entity);
console.log('Has asset:', hasAsset(assetType));
console.log('Asset URL:', getAssetUrl(assetType));
```

**Issue**: "Image exists in S3 but database indicates it shouldn't"
```javascript
// This typically indicates EntityService routing issues
// Check that marketing assets are routed to Product entity

// For Product entities, verify:
if (entity.product_type) {
  // Marketing assets should update Product entity
  const productEntity = await models.Product.findByPk(entity.id);
  console.log('Product has_image:', productEntity.has_image);
  console.log('Product image_filename:', productEntity.image_filename);
}
```

**Issue**: Orphan files accumulating
```bash
# Run the existing cleanup script
cd ludora-api
node scripts/cleanup-orphaned-files.js --env=development

# For automated cleanup
node scripts/cleanup-orphaned-files.js --env=development --force
```

### Debugging Tools

```javascript
// Debug entity mapping
const debugEntityMapping = (entity, assetType) => {
  console.log('Entity:', entity);
  console.log('Asset Type:', assetType);
  console.log('Asset Layer:', getAssetLayer(assetType));

  try {
    const mapping = getEntityMapping(entity, assetType);
    console.log('Entity Mapping:', mapping);
    return mapping;
  } catch (error) {
    console.error('Entity Mapping Error:', error);
    return null;
  }
};

// Debug S3 path construction
const debugS3Path = (entityType, entityId, assetType, filename) => {
  try {
    const s3Path = constructS3Path({
      env: process.env.NODE_ENV,
      privacy: getAssetLayer(assetType) === 'marketing' ? 'public' : 'private',
      assetType,
      entityType,
      entityId,
      filename
    });
    console.log('S3 Path:', s3Path);
    return s3Path;
  } catch (error) {
    console.error('S3 Path Construction Error:', error);
    return null;
  }
};
```

## Migration Examples

### Upgrading from Legacy Patterns

```javascript
// OLD (Deprecated)
if (product.image_url === 'HAS_IMAGE') {
  const imageUrl = `/api/assets/image/product/${product.id}`;
  // Manual URL construction
}

// NEW (Standardized)
if (product.has_image === true) {
  const filename = product.image_filename;
  const url = FileReferenceService.getAssetUrl(product, 'product', 'image');
  // Service-managed URL construction
}

// Migration script example
const migrateProductImages = async () => {
  const products = await models.Product.findAll({
    where: {
      image_url: 'HAS_IMAGE'
    }
  });

  for (const product of products) {
    // Check if S3 file exists
    const s3Key = `${process.env.NODE_ENV}/public/image/${product.type}/${product.id}/`;
    const s3Objects = await listS3ObjectsWithPrefix(s3Key);

    if (s3Objects.length > 0) {
      // Update to standardized fields
      await product.update({
        has_image: true,
        image_filename: s3Objects[0].Key.split('/').pop(),
        image_url: null // Clear legacy field
      });
    }
  }
};
```

---

**Document Version**: 1.0
**Last Updated**: October 31, 2025
**Next Review**: January 2026

**Related Documents**:
- [FILE_ARCHITECTURE_OVERVIEW.md](./FILE_ARCHITECTURE_OVERVIEW.md)
- [FILE_MANAGEMENT_OPERATIONS.md](./FILE_MANAGEMENT_OPERATIONS.md)
- [FILES_MANAGMENT_REFACTOR.md](./FILES_MANAGMENT_REFACTOR.md)
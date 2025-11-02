# Step 2: Frontend Upload Logic Fix

> **Parent Document**: `FILES_MANAGMENT_REFACTOR.md`
> **Status**: NOT_STARTED
> **Priority**: HIGH - Dependent on Step 1 completion

## Overview

Fix the frontend upload logic in `useUnifiedAssetUploads.js` to correctly handle entity mapping for all asset types and ensure robust validation prevents API calls with invalid entity IDs.

## Problem Statement

### Current Issues
1. **Entity ID Mapping Confusion**: Marketing vs content asset ID mapping unclear
2. **Invalid Entity ID Calls**: API calls with corrupted IDs like '176167854500406ugxpl18'
3. **Asset Type Classification**: Confusion between marketing images and content files
4. **Backend Compatibility**: lesson_plan products need special entity type mapping

### Evidence from Previous Work
- Frontend was calling non-existent v2 endpoints
- Entity ID validation was missing
- Marketing asset ID mapping was inconsistent
- Backend entity type support was incomplete

## Technical Analysis

### Current useUnifiedAssetUploads.js Structure
The hook handles:
- Asset upload operations
- Entity ID mapping for different asset types
- API endpoint construction
- Database field updates

### Key Functions to Review
1. **getEntityMapping()** - Maps product info to backend entity info
2. **handleAssetUpload()** - Main upload logic
3. **checkAssetExists()** - Asset existence validation
4. **Entity ID validation** - Prevents invalid API calls

### Known Issues to Address
```javascript
// Current problematic mapping
const getEntityMapping = useCallback((product, assetType) => {
  const isMarketingAsset = ['image', 'marketing_video'].includes(assetType);

  if (isMarketingAsset) {
    // Marketing assets: Use product layer (product.id + product_type)
    entityType = getBackendSupportedEntityType(product.product_type);
    entityId = product.id; // Should this always be product.id?
  } else {
    // Content assets: Use entity layer (entity_id + entity_type)
    // Need to handle lesson_plan -> file mapping
  }
}, []);
```

## Implementation Plan

### 1. Entity Mapping Review
- [ ] Audit current getEntityMapping() logic
- [ ] Verify marketing vs content asset classification
- [ ] Test lesson_plan -> file entity type mapping
- [ ] Ensure all Product types supported

### 2. Entity ID Validation Enhancement
- [ ] Implement robust entity ID format validation
- [ ] Prevent API calls with obviously corrupted IDs
- [ ] Add logging for invalid ID attempts
- [ ] Graceful error handling for edge cases

### 3. Asset Type Classification Cleanup
- [ ] Clear distinction between marketing and content assets
- [ ] Proper handling of all asset types:
  - Marketing: image, marketing_video
  - Content: document, content_video
  - System: logo, audio

### 4. Backend Integration Fixes
- [ ] Use correct /api/assets/* endpoints (not v2)
- [ ] Proper entity type mapping for all Product types
- [ ] Correct field updates after upload
- [ ] Error handling for backend responses

## Implementation Details

### Files to Modify
- `/ludora-front/src/components/product/hooks/useUnifiedAssetUploads.js`
- Possibly `/ludora-front/src/components/product/hooks/useProductUploadsCompat.js`

### Key Areas to Fix

#### 1. Entity ID Validation
```javascript
// Add robust validation
const isValidEntityId = (entityId) => {
  if (!entityId) return false;
  if (typeof entityId !== 'string') return false;
  if (entityId.length > 50) return false; // Reasonable length limit
  if (!/^[a-zA-Z0-9_-]+$/.test(entityId)) return false; // Basic format check
  return true;
};
```

#### 2. Clear Asset Type Classification
```javascript
const ASSET_TYPES = {
  MARKETING: ['image', 'marketing_video'],
  CONTENT: ['document', 'content_video'],
  SYSTEM: ['logo', 'audio']
};

const getAssetLayer = (assetType) => {
  if (ASSET_TYPES.MARKETING.includes(assetType)) return 'marketing';
  if (ASSET_TYPES.CONTENT.includes(assetType)) return 'content';
  if (ASSET_TYPES.SYSTEM.includes(assetType)) return 'system';
  throw new Error(`Unknown asset type: ${assetType}`);
};
```

#### 3. Proper Entity Mapping
```javascript
const getEntityMapping = useCallback((product, assetType) => {
  const assetLayer = getAssetLayer(assetType);

  switch (assetLayer) {
    case 'marketing':
      // Marketing assets always use Product entity
      return {
        entityType: getBackendSupportedEntityType(product.product_type),
        entityId: product.id,
        updateTarget: 'product'
      };

    case 'content':
      // Content assets use specific entity
      return {
        entityType: getBackendSupportedEntityType(product.product_type),
        entityId: product.entity_id,
        updateTarget: 'entity'
      };

    case 'system':
      // System assets handled separately
      return {
        entityType: assetType, // 'logo', 'audio', etc.
        entityId: product.entity_id,
        updateTarget: 'entity'
      };
  }
}, []);
```

### Backend Entity Type Mapping
```javascript
const getBackendSupportedEntityType = (productType) => {
  const mapping = {
    'lesson_plan': 'file', // Special mapping for backend compatibility
    'file': 'file',
    'workshop': 'workshop',
    'course': 'course',
    'game': 'game',
    'tool': 'tool'
  };

  if (!mapping[productType]) {
    throw new Error(`Unsupported product type: ${productType}`);
  }

  return mapping[productType];
};
```

## Testing Strategy

### Unit Testing
- [ ] Test entity mapping for all Product types
- [ ] Test entity ID validation with various inputs
- [ ] Test asset type classification
- [ ] Test error handling for edge cases

### Integration Testing
- [ ] Test marketing image upload to File product
- [ ] Test marketing image upload to LessonPlan product
- [ ] Test document upload to File product
- [ ] Test categorized file upload to LessonPlan product
- [ ] Test content video upload to Workshop product

### Edge Case Testing
- [ ] Corrupted entity IDs
- [ ] Missing entity_id field
- [ ] Unsupported product types
- [ ] Network failures during upload
- [ ] Backend validation errors

## Expected Outcomes

### Success Criteria
1. **All asset uploads work correctly**
2. **No API calls with invalid entity IDs**
3. **Clear separation between marketing and content assets**
4. **Proper error handling and user feedback**
5. **Database fields updated correctly after upload**

### Performance Improvements
- Fewer failed API calls due to validation
- Clear error messages for users
- Reduced debugging time for developers

## Dependencies

### Requires Step 1 Completion
- Backend entity routing must be fixed first
- Cannot test frontend properly until backend works

### Existing Code to Preserve
- Compatibility wrapper (useProductUploadsCompat.js)
- Existing /api/assets/* endpoints
- Current S3 path construction logic

## Risk Assessment

### Low Risk
- Entity ID validation improvements
- Asset type classification cleanup
- Error handling enhancements

### Medium Risk
- Entity mapping logic changes
- Backend endpoint usage changes
- Field update logic modifications

### High Risk
- Breaking existing upload functionality
- Compatibility issues with existing components

### Mitigation
- Comprehensive testing before deployment
- Preserve compatibility wrapper
- Gradual rollout with monitoring

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
**Estimated Time**: 3-4 hours
**Dependencies**: Step 1 (Backend Entity Routing Fix)
**Blocks**: Step 3 (Comprehensive Testing)
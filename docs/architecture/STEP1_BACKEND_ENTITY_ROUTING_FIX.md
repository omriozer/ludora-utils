# Step 1: Backend Entity Routing Fix

> **Parent Document**: `FILES_MANAGMENT_REFACTOR.md`
> **Status**: NOT_STARTED
> **Priority**: CRITICAL - Blocking all marketing image uploads

## Overview

Fix the EntityService.js field routing logic that incorrectly sends marketing asset fields (`has_image`, `image_filename`) to content entities (File, LessonPlan) instead of keeping them on the Product entity where they belong.

## Problem Statement

### Current Broken Behavior
When uploading marketing images to Products with `product_type: 'file'` or `product_type: 'lesson_plan'`:

1. **S3 Upload Succeeds**: Image uploads to S3 correctly
2. **Database Update Fails**: Marketing fields sent to File/LessonPlan entities that don't have those fields
3. **Inconsistency Created**: S3 has image, database indicates no image exists

### Root Cause
In `/ludora-api/services/EntityService.js`, the `updateProductTypeEntity()` method splits Product updates:
- Some fields go to Product entity
- Other fields go to content entity (File, LessonPlan, etc.)

**Marketing fields are incorrectly classified as content fields.**

### Evidence from Server Logs
```
🔄 Routing Product update to updateProductTypeEntity for file entity
📝 Updating file entity: { has_image: true, image_filename: 'image.jpg', ... }
🚨 INCONSISTENCY: Image exists in S3 but database indicates it shouldn't
```

## Technical Analysis

### EntityService.js Structure
The service has a `productOnlyFields` array that determines which fields stay on Product:
```javascript
const productOnlyFields = [
  'title', 'short_description', 'description', 'category', 'product_type',
  'price', 'is_published', 'image_url', // OLD: has legacy image_url
  'marketing_video_type', 'marketing_video_id', 'marketing_video_title', 'marketing_video_duration',
  'tags', 'target_audience', 'type_attributes', 'access_days', 'creator_user_id'
];
```

**MISSING**: `'has_image'`, `'image_filename'` are not in productOnlyFields!

### Expected Fix
Add missing marketing image fields to productOnlyFields:
```javascript
const productOnlyFields = [
  // ... existing fields ...
  'image_url', 'has_image', 'image_filename',  // All marketing image fields
  // ... rest of fields ...
];
```

## Implementation Plan

### 1. Code Analysis
- [ ] Read current EntityService.js implementation
- [ ] Identify all field classification arrays
- [ ] Map current field routing logic
- [ ] Document all marketing vs content fields

### 2. Fix Field Classification
- [ ] Add `has_image` to productOnlyFields
- [ ] Add `image_filename` to productOnlyFields
- [ ] Verify no other marketing fields are missing
- [ ] Review Workshop/Course image fields (should they be content or marketing?)

### 3. Testing Strategy
- [ ] Test marketing image upload to File product
- [ ] Test marketing image upload to LessonPlan product
- [ ] Verify content files still work (File documents, LessonPlan categorized files)
- [ ] Check database field routing logs

### 4. Validation
- [ ] Confirm S3/database consistency
- [ ] Verify images persist after page reload
- [ ] Test image deletion functionality
- [ ] Check all Product types (file, lesson_plan, workshop, course, etc.)

## Implementation Details

### Files to Modify
- `/ludora-api/services/EntityService.js` - Update productOnlyFields array

### Expected Changes
```javascript
// BEFORE (BROKEN)
const productOnlyFields = [
  'title', 'short_description', 'description', 'category', 'product_type',
  'price', 'is_published', 'image_url',
  'marketing_video_type', 'marketing_video_id', 'marketing_video_title', 'marketing_video_duration',
  'tags', 'target_audience', 'type_attributes', 'access_days', 'creator_user_id'
];

// AFTER (FIXED)
const productOnlyFields = [
  'title', 'short_description', 'description', 'category', 'product_type',
  'price', 'is_published', 'image_url', 'has_image', 'image_filename',  // ADDED
  'marketing_video_type', 'marketing_video_id', 'marketing_video_title', 'marketing_video_duration',
  'tags', 'target_audience', 'type_attributes', 'access_days', 'creator_user_id'
];
```

### Line Numbers
- Current productOnlyFields location: approximately line 986-991
- Need to verify exact location during implementation

## Testing Checklist

### Before Fix (Document Current Broken State)
- [ ] Test File product marketing image upload - should fail with S3 inconsistency
- [ ] Test LessonPlan product marketing image upload - should fail with S3 inconsistency
- [ ] Document exact error messages and logs

### After Fix (Verify Correct Behavior)
- [ ] File product marketing image upload - should work correctly
- [ ] LessonPlan product marketing image upload - should work correctly
- [ ] Workshop product marketing image upload - should work correctly
- [ ] Course product marketing image upload - should work correctly
- [ ] Images persist after page reload
- [ ] Database shows correct has_image=true, image_filename set
- [ ] S3 files exist and are accessible

### Regression Testing
- [ ] File entity document uploads still work
- [ ] LessonPlan categorized file uploads still work
- [ ] Workshop content video uploads still work
- [ ] Course content video uploads still work
- [ ] School logo uploads still work
- [ ] Settings logo uploads still work
- [ ] AudioFile uploads still work

## Expected Outcomes

### Success Criteria
1. **Marketing images work for ALL Product types**
2. **S3/database consistency maintained**
3. **No regression in content file uploads**
4. **Server logs show correct field routing**

### Performance Impact
- **Minimal**: Only changes field classification logic
- **No new queries**: Same database operations, just routed correctly
- **No S3 changes**: S3 path construction unchanged

## Risk Assessment

### Low Risk Changes
- Adding fields to existing array
- No new code paths
- Existing validation remains

### Potential Issues
- Other marketing fields might be missing from productOnlyFields
- Workshop/Course image fields might need similar treatment
- Legacy image_url field conflicts

### Mitigation
- Comprehensive testing before production
- Ability to quickly rollback changes
- Monitor server logs for new errors

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
**Estimated Time**: 2-3 hours
**Dependencies**: None
**Blocks**: Step 2, Step 3
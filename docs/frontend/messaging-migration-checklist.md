# Messaging System Migration Checklist

## Overview

This document tracks the migration from fragmented messaging systems to the unified messaging API. Use this checklist to identify and migrate remaining legacy patterns.

## ✅ Completed Migrations

### Core Infrastructure
- [x] Created unified messaging service (`/utils/messaging.js`)
- [x] Created ConfirmationProvider for promise-based dialogs
- [x] Added ConfirmationProvider to App.jsx root
- [x] Removed unused Sonner component

### Files Updated
- [x] `/pages/GameLauncher.jsx` - Replaced 2 alert() calls
- [x] `/components/FloatingAdminMenu.jsx` - Replaced 2 alert() calls
- [x] `/components/test/RuleBuilderTest.jsx` - Replaced 1 alert() call
- [x] `/pages/BrandSettings.jsx` - Replaced 1 confirm() call
- [x] `/pages/Games.jsx` - Replaced 1 window.confirm() call
- [x] `/utils/purchaseHelpers.js` - Migrated from direct toast to unified API
- [x] `/services/apiClient.js` - Migrated from direct toast to unified API (partial)

## 🔄 Remaining Native Alert Migrations

Search for remaining instances with:
```bash
grep -r "alert\|confirm\|window\.alert\|window\.confirm" src/ --include="*.jsx" --include="*.js"
```

### High Priority Files (Contains Native Alerts)
- [ ] `/pages/SubscriptionSettings.jsx` - window.confirm()
- [ ] `/components/admin/games/editors/MissionEditorModal.jsx` - window.confirm()
- [ ] `/components/GameContentTemplates.jsx` - confirm()
- [ ] `/components/admin/games/editors/MissionTaskListEditor.jsx` - window.confirm()
- [ ] `/components/modals/WorkshopModal.jsx` - window.confirm()
- [ ] `/pages/Participants.jsx` - window.confirm()
- [ ] `/pages/CourseViewer.jsx` - window.confirm()
- [ ] `/components/gameBuilder/steps/ContentRulesStep.jsx` - alert() + confirm()
- [ ] `/components/audio/AudioLibrary.jsx` - confirm()
- [ ] `/pages/GameContentManagement.jsx` - confirm()

## 🔄 Remaining Direct Toast Migrations

Search for remaining instances with:
```bash
grep -r "from.*use-toast" src/ --include="*.jsx" --include="*.js"
```

### Files Using Direct Toast Imports
- [ ] `/pages/Checkout.jsx`
- [ ] `/components/ui/GetAccessButton.jsx`
- [ ] `/components/modals/ProductModal.jsx`
- [ ] `/components/SecureVideoPlayer.jsx`
- [ ] `/contexts/UserContext.jsx`

## 🔄 Local Message System Migrations

### Files with Custom Message Systems
- [ ] `/pages/BrandSettings.jsx` - Has local showMessage() function
- [ ] `/pages/SiteTexts.jsx` - Check for local message patterns
- [ ] `/pages/Products.jsx` - Check for local message patterns
- [ ] `/pages/MyAccount.jsx` - Check for local message patterns

## Migration Patterns

### Alert/Confirm Replacement
```javascript
// Before
alert('message');
const result = confirm('question?');

// After
import { showError, showConfirm } from '@/utils/messaging';

showError('message');
const result = await showConfirm('title', 'question?');
```

### Toast Import Replacement
```javascript
// Before
import { toast } from '@/components/ui/use-toast';
toast({ title: 'Success', variant: 'default' });

// After
import { showSuccess } from '@/utils/messaging';
showSuccess('Success');
```

### Local Message System Replacement
```javascript
// Before
const [message, setMessage] = useState(null);
const showMessage = (type, text) => {
  setMessage({ type, text });
  setTimeout(() => setMessage(null), 5000);
};

// After
import { showSuccess, showError } from '@/utils/messaging';
// Remove local state and function, use unified API directly
```

## Testing Checklist

After migrating each file:
- [ ] Verify messages display correctly
- [ ] Check Hebrew/RTL layout
- [ ] Test confirmation dialogs return correct values
- [ ] Ensure async/await is used properly for confirmations
- [ ] Verify error handling still works
- [ ] Test edge cases (network errors, validation failures)

## Validation Commands

```bash
# Find remaining native alerts
grep -r "alert\(" src/ --include="*.js" --include="*.jsx" | grep -v "AlertDialog" | grep -v "AlertDescription"

# Find remaining native confirms
grep -r "confirm\(" src/ --include="*.js" --include="*.jsx" | grep -v "ConfirmationDialog"

# Find remaining direct toast imports
grep -r "from.*use-toast" src/ --include="*.js" --include="*.jsx"

# Find remaining toast() calls
grep -r "toast\(" src/ --include="*.js" --include="*.jsx" | grep -v "showToast"
```

## Performance Considerations

- Unified messaging reduces bundle size by removing duplicate libraries
- Promise-based confirmations improve user experience
- Centralized error handling reduces code duplication
- RTL support eliminates layout inconsistencies

## Known Issues & Workarounds

### Issue: Async Confirmation in Event Handlers
Some event handlers may need restructuring to support async confirmations.

**Problem:**
```javascript
const handleClick = (e) => {
  if (!confirm('Sure?')) return;
  doAction();
};
```

**Solution:**
```javascript
const handleClick = async (e) => {
  const confirmed = await showConfirm('Confirm', 'Sure?');
  if (!confirmed) return;
  doAction();
};
```

### Issue: Multiple Confirmations in Sequence
For multiple confirmations, ensure proper async handling.

**Solution:**
```javascript
const handleMultipleActions = async () => {
  const step1 = await showConfirm('Step 1', 'Continue with step 1?');
  if (!step1) return;

  const step2 = await showConfirm('Step 2', 'Continue with step 2?');
  if (!step2) return;

  // Proceed with actions
};
```

## Next Steps

1. **High Priority**: Migrate remaining native alerts (security concern for UX consistency)
2. **Medium Priority**: Convert direct toast imports to unified API
3. **Low Priority**: Replace local message systems
4. **Documentation**: Update component documentation to reference unified system
5. **Testing**: Create comprehensive test suite for messaging system

## Completion Metrics

- **Native Alerts**: ~10 remaining instances
- **Direct Toast Imports**: ~5 remaining files
- **Local Message Systems**: ~3 files identified
- **Estimated Effort**: 2-3 hours to complete migration

---

**Tip**: Use VS Code's search and replace with regex to batch-update simple patterns:
- Search: `alert\('([^']*)')\;`
- Replace: `showError('$1');`
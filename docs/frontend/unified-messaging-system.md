# Unified Messaging System

## Overview

The Ludora frontend now uses a unified messaging system that provides consistent user notifications across the entire application. This system replaces the previous fragmented approach with multiple toast libraries and native browser alerts.

## Quick Start

```javascript
import { showSuccess, showError, showWarning, showInfo, showConfirm } from '@/utils/messaging';

// Simple success message
showSuccess('פעולה בוצעה בהצלחה');

// Error with details
showError('שגיאה בעדכון', 'לא הצלחנו לשמור את השינויים');

// Confirmation dialog
const confirmed = await showConfirm('מחיקת קובץ', 'האם אתה בטוח שברצונך למחוק קובץ זה?');
if (confirmed) {
  deleteFile();
}
```

## API Reference

### Toast Notifications (Temporary)

#### `showSuccess(title, description?, options?)`
Display a success toast notification.

**Parameters:**
- `title` (string) - Main message text
- `description` (string, optional) - Additional details
- `options` (object, optional) - Additional options
  - `duration` (number) - Auto-dismiss time in ms (default: 5000)
  - `persistent` (boolean) - Disable auto-dismiss

**Example:**
```javascript
showSuccess('קובץ נשמר בהצלחה');
showSuccess('העלאה הושלמה', 'הקובץ זמין עכשיו למשתמשים', { duration: 8000 });
```

#### `showError(title, description?, options?)`
Display an error toast notification.

**Example:**
```javascript
showError('שגיאה בטעינה');
showError('שגיאת רשת', 'בדוק את החיבור לאינטרנט');
```

#### `showWarning(title, description?, options?)`
Display a warning toast notification.

#### `showInfo(title, description?, options?)`
Display an informational toast notification.

### Confirmation Dialogs (Modal)

#### `showConfirm(title, message, options?)`
Display a confirmation dialog and return a Promise that resolves to the user's choice.

**Parameters:**
- `title` (string) - Dialog title
- `message` (string) - Dialog message
- `options` (object, optional)
  - `variant` ('warning' | 'danger' | 'info' | 'success') - Dialog style
  - `confirmText` (string) - Confirm button text (default: "אישור")
  - `cancelText` (string) - Cancel button text (default: "ביטול")

**Returns:** `Promise<boolean>` - `true` if confirmed, `false` if cancelled

**Example:**
```javascript
const deleteConfirmed = await showConfirm(
  'מחיקת משתמש',
  'פעולה זו תמחק את המשתמש לצמיתות. האם להמשיך?',
  {
    variant: 'danger',
    confirmText: 'מחק',
    cancelText: 'בטל'
  }
);

if (deleteConfirmed) {
  await deleteUser(userId);
  showSuccess('המשתמש נמחק בהצלחה');
}
```

### Global Messages (Fixed Position)

#### `showGlobalMessage(type, message)`
Display a global message that stays fixed at the top of the screen.

**Parameters:**
- `type` ('error' | 'info') - Message type
- `message` (string) - Message text

**Example:**
```javascript
// For system-wide announcements
showGlobalMessage('info', 'המערכת תהיה בתחזוקה בין 02:00-04:00');
```

#### `hideGlobalMessage()`
Hide the current global message.

## Migration Guide

### From Native Browser Alerts

**Before:**
```javascript
alert('משהו קרה');
const confirmed = confirm('האם אתה בטוח?');
```

**After:**
```javascript
showError('משהו קרה');
const confirmed = await showConfirm('אישור', 'האם אתה בטוח?');
```

### From Direct Toast Imports

**Before:**
```javascript
import { toast } from '@/components/ui/use-toast';

toast({
  title: 'הצלחה',
  description: 'הפעולה בוצעה',
  variant: 'default'
});
```

**After:**
```javascript
import { showSuccess } from '@/utils/messaging';

showSuccess('הצלחה', 'הפעולה בוצעה');
```

### From Local Message Systems

**Before:**
```javascript
// Local state-based message system
const [message, setMessage] = useState(null);
const showMessage = (type, text) => {
  setMessage({ type, text });
  setTimeout(() => setMessage(null), 5000);
};
```

**After:**
```javascript
import { showSuccess, showError } from '@/utils/messaging';

// Just use the unified API directly
showSuccess('פעולה בוצעה');
showError('שגיאה');
```

## Hebrew/RTL Support

All components in the unified messaging system fully support Hebrew text and RTL layout:

- Dialog text is automatically right-aligned
- Buttons are positioned correctly for RTL
- Default button texts are in Hebrew
- Icons and layout respect RTL direction

## Best Practices

### Message Types

| Type | When to Use | Example |
|------|-------------|---------|
| **Success** | Successful operations | "קובץ נשמר", "משתמש נוסף" |
| **Error** | Failed operations | "שגיאה בשמירה", "חיבור נכשל" |
| **Warning** | Important notices | "קובץ גדול מדי", "מקום אחסון נמוך" |
| **Info** | General information | "עדכון זמין", "טיפ שימושי" |

### Confirmation Dialogs

Use confirmation dialogs for:
- Destructive actions (delete, remove)
- Actions that can't be undone
- Actions with significant consequences
- Navigation away from unsaved changes

**Variants:**
- `danger` - For destructive actions (red theme)
- `warning` - For important decisions (yellow theme)
- `info` - For informational confirmations (blue theme)
- `success` - For positive confirmations (green theme)

### Message Length

- **Titles**: Keep short and clear (1-3 words)
- **Descriptions**: Provide helpful details but stay concise
- **Error messages**: Include actionable guidance when possible

### Examples of Good Messages

```javascript
// Good: Clear, specific, actionable
showError('שגיאה בהעלאה', 'הקובץ גדול מ-10MB. נסה קובץ קטן יותר.');

// Good: Positive feedback
showSuccess('נשמר בהצלחה');

// Good: Clear confirmation
const confirmed = await showConfirm(
  'מחיקת תמונה',
  'תמונה זו תמחק לצמיתות מהגלריה. האם להמשיך?',
  { variant: 'danger' }
);
```

### Examples of Poor Messages

```javascript
// Bad: Too vague
showError('שגיאה');

// Bad: Technical jargon
showError('HTTP 500 Internal Server Error');

// Bad: No context
showSuccess('בוצע');
```

## Implementation Details

### Architecture

The unified messaging system consists of:

1. **`/utils/messaging.js`** - Main API and utilities
2. **`/components/ui/ConfirmationProvider.jsx`** - Global confirmation dialog provider
3. **Existing toast system** - Enhanced but preserved for compatibility
4. **Enhanced ConfirmationDialog** - Promise-based wrapper around existing component

### Provider Setup

The `ConfirmationProvider` is automatically included in `App.jsx` and doesn't require additional setup.

### Error Handling

The system includes fallbacks:
- If `ConfirmationProvider` is not available, `showConfirm()` falls back to native `confirm()`
- Console warnings are shown when fallbacks are used
- Network errors automatically show user-friendly messages

## Common Hebrew Messages

The system includes pre-defined Hebrew messages for common scenarios:

```javascript
import { HEBREW_MESSAGES } from '@/utils/messaging';

// Use predefined messages for consistency
showError(HEBREW_MESSAGES.NETWORK_ERROR);
showSuccess(HEBREW_MESSAGES.SUCCESS);

const confirmed = await showConfirm('מחיקה', HEBREW_MESSAGES.DELETE_CONFIRM);
```

## Troubleshooting

### Confirmation Dialogs Not Working
- Ensure `ConfirmationProvider` is wrapped around your app root
- Check browser console for warning messages

### Messages Not Appearing
- Verify toast container (`<Toaster />`) is included in your app
- Check if messages are being blocked by other UI elements

### Styling Issues
- RTL support requires proper CSS configuration
- Ensure Hebrew fonts are loaded correctly
- Check z-index conflicts with other components

## Duplicate Prevention

The toast system automatically prevents duplicate messages from being displayed simultaneously. This prevents spam when users rapidly click buttons.

**How it works:**
- Compares `title`, `description`, and `variant` of new toasts
- If an identical toast is already displayed, prevents creating a new one
- Returns the existing toast's control methods instead
- Console logs when duplicates are prevented for debugging

**Example:**
```javascript
// User rapidly clicks "Save" button
showSuccess('נשמר בהצלחה!'); // Shows toast
showSuccess('נשמר בהצלחה!'); // Prevented - returns existing toast
showSuccess('נשמר בהצלחה!'); // Prevented - returns existing toast

// Console output: "Duplicate toast prevented: נשמר בהצלחה!"
```

**Note:** Different positions or options are treated as different toasts.

## Future Enhancements

Planned improvements:
- Action buttons in toast notifications
- Toast queuing and management
- Custom toast positions
- Integration with notification system
- Bulk operations with progress indicators

---

**Note:** This unified system is designed to eventually replace all existing messaging approaches in the codebase. When encountering old patterns, please migrate them to use this unified API.
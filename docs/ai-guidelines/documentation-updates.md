# Documentation Update Requirements

This document establishes the requirement that AI assistants must update documentation incrementally with every code change, not just at the end of major features.

## Core Principle

**Every code change must be accompanied by corresponding documentation updates.** Documentation is not a post-development task—it's an integral part of the development process.

## When to Update Documentation

### Immediate Updates Required

**Code Changes That Require Documentation Updates:**
1. **New API Endpoints** → Update API reference documentation
2. **Database Schema Changes** → Update database schema documentation
3. **New Components** → Update component documentation
4. **Changed Patterns** → Update code patterns documentation
5. **Configuration Changes** → Update setup and configuration docs
6. **New Dependencies** → Update setup requirements
7. **Security Changes** → Update security documentation
8. **Deployment Changes** → Update deployment documentation

### The "Before and After" Rule

**Before making any significant change:**
1. Read the relevant documentation sections
2. Understand the current documented approach
3. Plan how the documentation will need to change

**After making any change:**
1. Update the documentation immediately
2. Ensure examples still work
3. Update cross-references if needed
4. Verify links still work

## Documentation Update Workflow

### 1. Small Changes (Single Function/Component)

**Example: Adding a new utility function**

```javascript
// Add function to utils/dateHelpers.js
export const formatDateForHebrewLocale = (date) => {
  return new Intl.DateTimeFormat('he-IL').format(date);
};
```

**Required Documentation Update:**
```markdown
// docs/frontend/utility-functions.md

### Date Utilities

#### formatDateForHebrewLocale(date)
Formats a date according to Hebrew locale conventions.

**Parameters:**
- `date` (Date) - The date to format

**Returns:**
- `string` - Formatted date string in Hebrew locale

**Example:**
```javascript
import { formatDateForHebrewLocale } from '@/utils/dateHelpers';

const formattedDate = formatDateForHebrewLocale(new Date());
// Returns: "22.9.2025"
```

**Usage in Components:**
Commonly used in date display components for Hebrew-speaking users.
```

### 2. Medium Changes (New Feature/Component)

**Example: Adding a new ProgressBar component**

**Code Changes:**
- Create `src/components/ui/ProgressBar.jsx`
- Add to component exports
- Use in upload components

**Documentation Updates Required:**

**1. Component Documentation:**
```markdown
// docs/frontend/components.md - Add section

### ProgressBar

A customizable progress indicator component.

**Props:**
- `value` (number, 0-100) - Current progress value
- `label` (string, optional) - Accessibility label
- `variant` ('default' | 'success' | 'warning' | 'error') - Visual style
- `size` ('sm' | 'md' | 'lg') - Component size

**Example:**
```jsx
<ProgressBar
  value={75}
  label="Upload progress"
  variant="default"
  size="md"
/>
```

**Styling:**
Uses Tailwind classes with CSS variables for theming. Supports RTL layouts.
```

**2. Update Component Index:**
```markdown
// docs/frontend/component-index.md - Add entry

| Component | Purpose | Location | Props |
|-----------|---------|----------|-------|
| ProgressBar | Progress indication | `/ui/ProgressBar.jsx` | value, label, variant, size |
```

### 3. Large Changes (API Endpoints/Database Changes)

**Example: Adding new Workshop entity**

**Code Changes:**
- Create Workshop model
- Add API endpoints
- Update database schema
- Add frontend service

**Documentation Updates Required:**

**1. API Documentation:**
```markdown
// docs/backend/api-reference.md - Add section

### Workshop Endpoints

#### GET /api/entities/workshop
List workshops with filtering and pagination.

**Query Parameters:**
- `filters[creator_id]` (string) - Filter by creator
- `filters[is_live]` (boolean) - Filter live workshops
- `sort` (string) - Sort field (default: created_at)
- `order` (asc|desc) - Sort order (default: desc)

**Response:**
```json
{
  "success": true,
  "data": {
    "workshops": [...],
    "pagination": {...}
  }
}
```
```

**2. Database Documentation:**
```markdown
// docs/architecture/database-schema.md - Add table

### workshop
Workshop entity for educational sessions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Unique workshop ID |
| title | VARCHAR(255) | NOT NULL | Workshop title |
| description | TEXT | - | Workshop description |
| is_live | BOOLEAN | DEFAULT false | Live vs recorded |
| video_file_url | VARCHAR(255) | - | Video content URL |
| creator_user_id | VARCHAR(255) | FK to user(id) | Workshop creator |

**Relationships:**
- workshop.creator_user_id → user.id (Many-to-One)
- purchase.purchasable_id → workshop.id (One-to-Many, polymorphic)
```

**3. Frontend Service Documentation:**
```markdown
// docs/frontend/api-integration.md - Add service

### Workshop Service

```javascript
import { workshopService } from '@/services/workshopService';

// Get all workshops
const workshops = await workshopService.getAll({
  filters: { is_live: true },
  sort: 'created_at'
});

// Create workshop
const newWorkshop = await workshopService.create({
  title: 'New Workshop',
  description: 'Workshop description',
  is_live: false
});
```
```

## Documentation Types and Their Update Triggers

### API Reference Documentation
**Update When:**
- Adding new endpoints
- Changing request/response formats
- Modifying authentication requirements
- Adding new query parameters
- Changing error responses

**Files to Update:**
- `docs/backend/api-reference.md`
- Postman collections (if exists)
- OpenAPI specs (if exists)

### Database Documentation
**Update When:**
- Adding new tables
- Modifying table schemas
- Adding/removing indexes
- Changing relationships
- Adding JSONB fields

**Files to Update:**
- `docs/architecture/database-schema.md`
- `docs/architecture/database-patterns.md` (if patterns change)
- Migration documentation

### Component Documentation
**Update When:**
- Creating new components
- Changing component APIs (props)
- Modifying styling patterns
- Adding new component variants

**Files to Update:**
- `docs/frontend/components.md`
- `docs/frontend/styling-guide.md`
- Component story files (if using Storybook)

### Architecture Documentation
**Update When:**
- Changing system architecture
- Adding new services or integrations
- Modifying authentication flow
- Changing deployment patterns

**Files to Update:**
- `docs/architecture/overview.md`
- `docs/architecture/authentication.md`
- `docs/deployment/` files

## Quality Standards for Documentation Updates

### Accuracy Requirements
1. **Code Examples Must Work**: All code examples must be tested and functional
2. **Parameter Accuracy**: All parameters, types, and constraints must be correct
3. **Link Validity**: All internal links must resolve correctly
4. **Version Consistency**: Documentation must match the current code version

### Completeness Requirements
1. **Purpose**: Every addition must explain WHY it exists
2. **Usage**: How to use the new functionality
3. **Examples**: Practical examples for common use cases
4. **Constraints**: Limitations or considerations
5. **Related Changes**: How it affects other parts of the system

### Style Requirements
1. **Consistent Format**: Follow established documentation patterns
2. **Clear Language**: Use simple, direct language
3. **Logical Organization**: Information in logical order
4. **Searchable**: Use clear headings and keywords

## Documentation Review Process

### Self-Review Checklist
Before considering a change complete, verify:

- [ ] **Accuracy**: All documented information is correct
- [ ] **Completeness**: All aspects of the change are documented
- [ ] **Examples**: Code examples work and are relevant
- [ ] **Links**: All internal references are updated
- [ ] **Context**: Documentation explains why the change was made
- [ ] **Impact**: Related systems/components are updated

### Cross-Reference Updates
When updating documentation, check these related areas:

**For API Changes:**
- Update frontend service documentation
- Update authentication documentation (if auth changes)
- Update error handling documentation
- Update rate limiting info (if applicable)

**For Database Changes:**
- Update API documentation (if endpoints affected)
- Update migration documentation
- Update backup/restore procedures
- Update performance considerations

**For Component Changes:**
- Update page documentation (if used in pages)
- Update styling guide (if patterns change)
- Update accessibility documentation
- Update testing documentation

## AI Todo Integration

### Document Updates in Todos
When working with AI todos, document all documentation updates:

```markdown
## Documentation Updates Made This Session:
- ✅ Updated API reference for new Workshop endpoints
- ✅ Added Workshop entity to database schema docs
- ✅ Updated frontend service documentation
- 🔄 Still need to update deployment docs for new entity
- ⏳ Planning to add Workshop component documentation
```

### Track Documentation Debt
If documentation cannot be updated immediately, track it:

```markdown
## Documentation Debt:
- [ ] Workshop component patterns need documenting
- [ ] API rate limiting info needs updating
- [ ] New authentication flow needs architecture doc update

## Reason for Delay:
Components still being refactored, will document once patterns stabilize.

## Deadline:
Complete by end of current development cycle.
```

## Common Documentation Anti-Patterns

### Don't Do These Things

**1. Batch Documentation Updates**
```markdown
❌ Wrong Approach:
- Build entire feature
- Update all documentation at the end
- Risk forgetting details or context

✅ Correct Approach:
- Add new API endpoint
- Immediately document the endpoint
- Add new component
- Immediately document the component
```

**2. Incomplete Updates**
```markdown
❌ Wrong:
"Added new Workshop API endpoints"

✅ Correct:
- Updated API reference with Workshop CRUD endpoints
- Added Workshop entity to database schema documentation
- Updated frontend service documentation with Workshop methods
- Added Workshop to entity relationship diagram
```

**3. Outdated Examples**
```markdown
❌ Wrong:
// Example from old API version
const response = await fetch('/api/product/123');

✅ Correct:
// Current API version
const workshop = await workshopService.getById('123');
```

**4. Missing Context**
```markdown
❌ Wrong:
"Workshop entity for educational content"

✅ Correct:
"Workshop entity represents educational sessions that can be live or recorded.
Used in the content creator economy where educators can create and monetize
educational workshops. Integrates with the purchase system for access control."
```

## Tools and Automation

### Documentation Validation
Consider implementing tools to validate documentation:

```javascript
// Example: Validate API documentation matches actual endpoints
const validateApiDocs = () => {
  // Check that all documented endpoints exist
  // Verify parameter types match implementation
  // Ensure examples use current API format
};
```

### Link Checking
Regularly verify internal links work:

```bash
# Example script to check markdown links
find docs/ -name "*.md" -exec markdown-link-check {} \;
```

### Documentation Metrics
Track documentation quality:
- Documentation coverage (% of code with docs)
- Outdated documentation detection
- Link health monitoring
- Example validation

## Success Metrics

### How to Measure Good Documentation Practice

**Quality Indicators:**
1. **Zero Outdated Examples**: All code examples work with current codebase
2. **Complete Cross-References**: All related documentation is updated together
3. **Immediate Updates**: Documentation changes committed with code changes
4. **No Documentation Debt**: No backlog of undocumented features

**Developer Experience Indicators:**
1. **Self-Service**: Developers can implement features using only documentation
2. **Quick Onboarding**: New developers can be productive quickly
3. **Reduced Questions**: Fewer clarification questions about implementation
4. **Consistent Patterns**: Clear patterns lead to consistent implementations

By following these documentation update requirements, we ensure that the Ludora project maintains high-quality, accurate, and useful documentation that evolves with the codebase.
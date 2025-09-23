# AI Todo Workflow System

This document explains how AI assistants should use the todo system to track progress, maintain context between sessions, and ensure comprehensive task completion.

## Todo Directory Structure

### Location of Todo Files
```
ludora/
├── docs/ai-todos/                    # Cross-project todos
├── ludora-api/docs/ai-todos/         # Backend-specific todos
└── ludora-front/docs/ai-todos/       # Frontend-specific todos
```

### When to Use Each Directory

**Cross-Project Todos (`/docs/ai-todos/`)**:
- Architecture changes affecting both frontend and backend
- Documentation updates spanning multiple components
- Feature implementations requiring full-stack changes
- Migration tasks affecting the entire system

**Backend Todos (`/ludora-api/docs/ai-todos/`)**:
- Database schema changes
- API endpoint modifications
- Backend service implementations
- Database migration tasks

**Frontend Todos (`/ludora-front/docs/ai-todos/`)**:
- Component development
- UI/UX improvements
- Frontend service integrations
- Page implementations

## Todo File Format

### File Naming Convention
```
{feature-name}-{date}.md           # For new features
{system-component}-refactoring.md  # For refactoring tasks
{bug-description}-fix.md           # For bug fixes
{migration-name}-migration.md      # For data migrations
```

### Required Sections

#### Header Information
```markdown
# [Task Title] - [Status]

## Context
Brief description of what needs to be done and why.

## Current Status: [Status Description]
Summary of current progress.
```

#### Task Tracking
```markdown
### ✅ Completed Tasks:
- [x] Task that has been finished
- [x] Another completed task

### 🔄 In Progress Tasks:
- [ ] Task currently being worked on
- [ ] Another active task

### ⏳ Pending Tasks:
- [ ] Task waiting to be started
- [ ] Future task dependency
```

#### Technical Details
```markdown
## Technical Notes
Key implementation details, constraints, or patterns to follow.

## Code Changes Made
List of files modified and what was changed.

## Testing Requirements
What needs to be tested to verify completion.
```

#### Session Continuity
```markdown
## Session Continuity Notes
If session is interrupted, next AI should:
1. Check this file for current progress
2. Continue with [specific next task]
3. Update this file with progress

## Next Priority
Specific next action to take.
```

## Workflow Process

### 1. Starting a New Task

**Before Beginning Work:**
1. Read existing todo files to understand current state
2. Check if similar work has been started
3. Create new todo file if none exists
4. Update existing todo file if continuing work

**Example Workflow:**
```markdown
# New Feature: Video Upload Enhancement

## Context
Users need better progress tracking during video uploads.

## Current Status: Planning Phase ✅

### ✅ Research Complete:
- [x] Analyzed current upload implementation
- [x] Identified performance bottlenecks
- [x] Reviewed user feedback

### 🔄 Development Phase:
- [ ] Implement progress tracking component
- [ ] Add upload cancellation feature
- [ ] Update API to support chunked uploads

### ⏳ Testing Phase:
- [ ] Write unit tests for new components
- [ ] Perform manual testing with large files
- [ ] Update documentation
```

### 2. Working on Tasks

**During Implementation:**
1. Update todo file with each completed subtask
2. Add technical notes about decisions made
3. Document any issues or blockers encountered
4. Update current status section

**Progress Tracking:**
```markdown
## Session Progress - [Date/Time]
### Completed This Session:
- ✅ Created ProgressBar component
- ✅ Integrated with upload service
- ✅ Added error handling

### Issues Encountered:
- File size calculation inconsistency
- Browser compatibility issue with progress events

### Next Steps:
- Resolve browser compatibility
- Add upload cancellation
```

### 3. Documentation Updates

**Required Documentation Updates:**
- Update relevant documentation sections as you make changes
- Don't wait until the end to update docs
- Document new patterns or architectural decisions
- Update API documentation for endpoint changes

**Documentation Workflow:**
```markdown
## Documentation Updates Made:
- ✅ Updated API reference for new upload endpoints
- ✅ Added component documentation for ProgressBar
- 🔄 Updating user guide with new upload flow
- ⏳ Need to update architecture docs with new patterns
```

### 4. Completing Tasks

**Before Marking Complete:**
1. Verify all subtasks are finished
2. Run tests to ensure no regressions
3. Update documentation
4. Archive or clean up todo file

**Completion Checklist:**
```markdown
## Completion Checklist:
- [x] All implementation tasks completed
- [x] Tests written and passing
- [x] Documentation updated
- [x] Code reviewed for patterns compliance
- [x] No breaking changes introduced
- [ ] Performance impact assessed
- [ ] Accessibility considerations addressed
```

## Best Practices

### Task Granularity
- **Good**: "Implement user authentication middleware"
- **Better**: "Add JWT validation to auth middleware"
- **Best**: "Add JWT token expiration check to requireAuth middleware"

### Status Tracking
- Use clear status indicators (✅ 🔄 ⏳ ❌)
- Update status in real-time, not batched
- Include timestamps for significant updates
- Note any blockers or dependencies

### Technical Documentation
- Record architectural decisions made
- Document new patterns established
- Note any deviations from established patterns
- Include code examples for complex implementations

### Session Handoff
- Always assume another AI will continue the work
- Provide clear next steps
- Document current state comprehensively
- Include any context that might not be obvious

## Common Scenarios

### Scenario 1: Multi-Session Feature Development

**Day 1 - AI Session 1:**
```markdown
# User Profile Enhancement - In Progress

## Current Status: Backend API Complete ✅

### ✅ Backend Complete:
- [x] Added profile picture upload endpoint
- [x] Implemented image resizing service
- [x] Updated user model with avatar_url field

### 🔄 Frontend In Progress:
- [x] Created ProfilePicture component
- [ ] Integrate with upload API
- [ ] Add loading states

## Session Handoff:
Next AI should focus on completing frontend integration.
Upload component is in src/components/ProfilePicture.jsx
```

**Day 2 - AI Session 2:**
```markdown
# User Profile Enhancement - Completed ✅

## Updates from Previous Session:
- ✅ Completed frontend integration
- ✅ Added loading and error states
- ✅ Implemented image preview

### Final Tasks Completed:
- [x] Added form validation
- [x] Updated profile page UI
- [x] Added success notifications
- [x] Updated documentation

## Testing Completed:
- ✅ Upload various image formats
- ✅ Test error scenarios
- ✅ Verify responsive design
```

### Scenario 2: Bug Fix Tracking

```markdown
# Video Streaming Access Control Bug - Resolved

## Problem:
Users with valid subscriptions couldn't access workshop videos.

## Root Cause Found:
Subscription validation logic wasn't checking plan benefits correctly.

## Fix Applied:
- ✅ Updated access control middleware
- ✅ Fixed subscription plan benefit checking
- ✅ Added logging for debug purposes

## Testing:
- ✅ Verified fix with test subscription
- ✅ Confirmed no regression in purchase-based access
- ✅ Updated unit tests

## Files Modified:
- middleware/access.js - Fixed subscription logic
- services/subscriptionService.js - Added benefit validation
- tests/access.test.js - Updated test cases
```

### Scenario 3: Refactoring Task

```markdown
# Product Entity Refactoring - Phase 2 Complete

## Context:
Migrating from single Product table to dedicated entity tables.

## Phase 2 Status: Backend Implementation Complete ✅

### ✅ Database Schema:
- [x] Created Workshop table
- [x] Created Course table
- [x] Created File table
- [x] Created Tool table
- [x] Added polymorphic Purchase fields

### ✅ API Implementation:
- [x] Workshop CRUD endpoints
- [x] Course CRUD endpoints
- [x] File CRUD endpoints
- [x] Tool CRUD endpoints
- [x] Updated access control

### 🔄 Next Phase: Data Migration
- [ ] Create migration scripts
- [ ] Migrate existing Product data
- [ ] Update Purchase records
- [ ] Verify data integrity

## Critical Notes:
- Maintain backward compatibility during migration
- Test migration on staging first
- Have rollback plan ready
```

## Error Recovery

### When Things Go Wrong

**If Implementation Fails:**
1. Document what went wrong
2. Record exact error messages
3. Note what was tried
4. Identify potential solutions
5. Mark task as blocked with reason

**Example Error Documentation:**
```markdown
## Issue Encountered - [Timestamp]

### Problem:
Database migration failed with constraint violation.

### Error Details:
```
ERROR: insert or update on table "purchase" violates foreign key constraint
DETAIL: Key (purchasable_id)=(workshop_123) is not present in table "workshop"
```

### Analysis:
Migration script is trying to create Purchase records before Workshop records exist.

### Solution Attempted:
- Reordered migration steps
- Added dependency checks

### Status: Blocked ❌
Need to restructure migration to create entities before updating purchases.

### Next Steps:
1. Create workshop records first
2. Then update purchase records
3. Add data validation step
```

## Integration with Development

### Before Making Code Changes
1. **Read Current Todos**: Check what's already in progress
2. **Update Status**: Mark relevant tasks as in-progress
3. **Document Plan**: Add implementation approach to todo

### During Development
1. **Incremental Updates**: Update todos with each significant step
2. **Document Decisions**: Note architectural or design decisions
3. **Track Issues**: Log any problems or unexpected discoveries

### After Completing Work
1. **Final Updates**: Mark all relevant tasks complete
2. **Documentation**: Ensure all docs are updated
3. **Clean Up**: Archive completed todos or remove if no longer relevant
4. **Handoff Notes**: Prepare clear context for future work

This todo workflow ensures continuity between AI sessions, maintains project context, and provides clear tracking of development progress.
# Student Authentication System - Requirements

## Task Overview
**Date**: 2024-11-22
**Team Leader**: ludora-team-leader
**Objective**: Implement proper login screens for student portal protected pages with admin override capabilities

## Problem Statement
Currently students are auto-created when joining game rooms without proper authentication flow. Need to implement:
1. Proper login screens for protected pages
2. Admin override functionality for maintenance mode and testing

## Clarified Requirements

### 1. Authentication Flow Scope
**Protected Pages** (require authentication):
- TeacherCatalog
- Lobby page
- Gameplay

**Non-Protected Pages**:
- Homepage (may allow optional login)

### 2. Admin Override Capabilities
- Admins use **same student authentication methods** on student portal
- Admins can override maintenance mode
- When admin logs in via Firebase on student portal → get Player record connected to User record
- Admin-as-player gets normal player experience + admin privileges

### 3. Students_Access Settings Integration
Settings control login screen options:
- `invite_only`: Show only privacy code input
- `authed_only`: Show only Firebase login
- `all`: Show both privacy code AND Firebase options

**Privacy Code Behavior**:
- **New player**: Enter display name → creates new player with privacy code
- **Existing player**: Enter privacy code → takes over existing player session

### 4. Portal Isolation (Cookie/Session)
- Teacher portal login ≠ Student portal login
- Each portal maintains separate authentication sessions
- Same user can be logged into both portals separately
- Portal-aware cookies ensure no cross-contamination

## Technical Requirements

### Components Needed
1. **StudentLogin component** - Universal login screen
2. **usePlayerAuth hook** - Enhanced authentication state management
3. **ProtectedStudentRoute wrapper** - Route protection logic
4. **Portal-aware cookie system** - Separate sessions per portal

### Authentication Flow
1. User visits protected page → Show StudentLogin if not authenticated
2. StudentLogin adapts to `students_access` setting
3. Privacy code → Player session OR Firebase → User + connected Player
4. Admin users get Player + admin privileges
5. Portal-specific cookies maintain session isolation

## Success Criteria
- [ ] TeacherCatalog shows login screen when required
- [ ] Lobby and gameplay require authentication
- [ ] Admin can override maintenance mode via student portal auth
- [ ] students_access setting controls available login options
- [ ] Portal session isolation working
- [ ] Privacy code can create new or take over existing players
- [ ] Zero breaking changes to existing teacher portal
# Explore Agent Workspace: Student Portal Authentication System

**Agent**: Explore Specialist  
**Task**: Investigate current student portal authentication architecture  
**Status**: Complete  
**Date**: 2025-11-23

---

## Executive Summary

The student portal authentication system has a **comprehensive but partially broken architecture**. The system implements dual authentication tokens (access + refresh), cookie-based persistence, and multi-layer validation, but has critical gaps in cookie persistence and session handling that cause players to lose authentication on page reload.

**Critical Issues Found**:
1. **Cookie Persistence Failing** - Cookies set correctly but not persisting/being sent back
2. **Missing Player Session Refresh on Reload** - `/players/me` called but returns 401
3. **Dual Token System Not Properly Coordinated** - Tokens generated but not reaching frontend
4. **Legacy Code Conflicts** - Multiple authentication attempts competing
5. **Missing OAuth Cookie Bridge** - Student portal needs cross-subdomain cookie sharing

---

## Authentication System Architecture

### Overview: Dual-Entity Authentication

```
STUDENT PORTAL (my.ludora.app)
├── Anonymous Players (privacy code)
│   ├── Database: Player model
│   ├── Tokens: access + refresh (JWTs)
│   ├── Cookies: student_access_token, student_refresh_token
│   └── Sessions: UserSession records
│
├── Authenticated Users (teachers accessing student portal)
│   ├── Database: User model
│   ├── Tokens: access + refresh (JWTs)
│   ├── Cookies: student_access_token, student_refresh_token
│   └── Sessions: UserSession records
│
└── Anonymous Access (no auth, depends on students_access setting)
    ├── No cookies
    ├── No sessions
    └── Only allowed if students_access = 'all'
```

### Authentication Flow Layers

#### Layer 1: Backend Authentication Middleware (ludora-api/middleware/auth.js)

**Unified Authentication Middleware** (`authenticateUserOrPlayer`)
- Tries user authentication first (user tokens)
- Falls back to player authentication (player tokens)
- Sets `req.entity` and `req.entityType` for unified handling

**Specific Middleware**:
- `authenticateToken` - User only (teacher portal)
- `authenticatePlayer` - Player only (student portal)
- `authenticateUserOrPlayer` - Either (dual-auth endpoints)
- `optionalUserOrPlayer` - Optional (continues if auth missing)

#### Layer 2: Player Authentication Specific (ludora-api/routes/players.js)

**Login Flow** (POST /players/login):
```
Client sends: { privacy_code: "ABCD1234" }
   ↓
Server authenticates via PlayerService.authenticatePlayer()
   ├── Finds player by privacy code (case-insensitive)
   ├── Verifies teacher is active (if assigned)
   ├── Creates UserSession record with 24-hour expiry
   └── Sets player online: true
   ↓
Server generates tokens:
   ├── Access Token (JWT): 15-minute expiry, contains player ID
   ├── Refresh Token (JWT): 7-day expiry, contains player ID
   └── Legacy Session Cookie: 24 hours (for compatibility)
   ↓
Sets httpOnly cookies:
   ├── student_access_token (access token)
   ├── student_refresh_token (refresh token)
   └── student_session (legacy, will be deprecated)
   ↓
Returns player data to frontend (WITHOUT privacy_code for security)
```

**Refresh Flow** (POST /players/refresh):
```
Client sends: (automatic via apiClient retry on 401)
   ↓
Server receives refresh token from student_refresh_token cookie
   ↓
Validates JWT signature
   ├── Verifies payload.type === 'player'
   └── Gets fresh player data from database
   ↓
Generates new access token
   ↓
Sets student_access_token cookie with new token
   ↓
Returns player data
```

**Get Current Player** (GET /players/me):
```
Client sends: (with cookies)
   ↓
Server calls authenticateUserOrPlayer middleware
   ├── Tries to verify student_access_token
   ├── If valid → sets req.player and req.entityType = 'player'
   ├── If invalid → tries to refresh with student_refresh_token
   └── If no valid auth → returns 401
   ↓
Returns player data or error
```

#### Layer 3: Cookie Configuration (ludora-api/utils/cookieConfig.js)

**Cookie Domain Settings**:
```javascript
Development:   '.localhost'          // Enables cross-subdomain testing
Staging:       '.ludora.app'         // Allows staging subdomains
Production:    '.ludora.app'         // Allows ludora.app and my.ludora.app
```

**Cookie Properties**:
```javascript
httpOnly: true              // Prevents JavaScript access
secure: (env !== 'dev')     // HTTPS only in production/staging
sameSite: 'lax'             // Allows subdomain access
maxAge: {
  access: 15 * 60 * 1000,   // 15 minutes
  refresh: 7 * 24 * 60 * 1000  // 7 days
}
```

---

## Frontend Authentication System

### AuthManager (ludora-front/src/services/AuthManager.js)

**Singleton Architecture**:
- Single instance manages all authentication state
- Listeners notify components of state changes
- Centralized init on app startup

**Authentication Strategy**:
```javascript
Teacher Portal (ludora.app):
  ├── Methods: ['firebase']
  ├── Allow Anonymous: false
  └── Result: User or error

Student Portal (my.ludora.app):
  ├── Methods: ['player', 'firebase']  // Player first (priority)
  ├── Allow Anonymous: depends on students_access setting
  └── Results:
      ├── invite_only: player auth OR admin firebase auth
      ├── authed_only: firebase auth (no anonymous)
      └── all: player auth → firebase auth → anonymous access
```

**State Management**:
```javascript
currentAuth = {
  type: 'user' | 'player' | null,
  entity: { full user/player object }
}

authState = {
  isLoading: boolean,
  isInitialized: boolean,
  authType: 'user' | 'player' | null,
  user: { user data if type='user' } | null,
  player: { player data if type='player' } | null,
  isAuthenticated: boolean,
  settings: { Settings object }
}
```

### API Client (ludora-front/src/services/apiClient.js)

**Player API Methods**:
```javascript
Player.login(privacyCode)
  → POST /players/login
  → Returns: { success, player data (no privacy_code) }
  → Sets: student_access_token, student_refresh_token cookies

Player.getCurrentPlayer(suppressUserErrors)
  → GET /players/me
  → Returns: player data or null (if 401)
  → Automatically retries with refresh on 401

Player.createAnonymous(displayName)
  → POST /players/create-anonymous
  → Returns: { success, player (includes privacy_code) }
  → Does NOT automatically login

Player.logout()
  → POST /players/logout
  → Clears: all player cookies
```

**Cookie-Based Request Handling**:
```javascript
Every request from apiRequest():
  ├── credentials: 'include'  // Auto-includes cookies
  ├── Automatic 401 retry:
  │   ├── Detect 401 response
  │   ├── Determine if player or user request
  │   ├── Call appropriate refresh endpoint
  │   └── Retry original request
  └── Only retries 401 once (prevents loops)
```

### Student Login Component (ludora-front/src/components/auth/StudentLogin.jsx)

**Login Modes**:
```javascript
Existing Player:
  ├── Input: privacy_code (8 characters)
  ├── Action: Player.login(privacyCode)
  ├── Then: handleExistingPlayerLoginComplete()
  └── Delay: 100ms before navigation (let state updates process)

New Player (Anonymous):
  ├── Input: display_name
  ├── Action 1: Player.createAnonymous(displayName)
  ├── Action 2: Player.login(newPlayer.privacy_code)
  ├── Then: Show welcome modal
  ├── On Modal Close: Navigate home
  └── Note: Does NOT call refreshUser() (avoids redundant API calls)
```

**Mode Switching by students_access Setting**:
```javascript
invite_only:
  ├── Show: Privacy code login only
  ├── Show: "Create new player" option
  └── Hide: Google login

authed_only:
  ├── Hide: Privacy code login
  ├── Show: Google/Firebase login only
  └── Hide: New player creation

all:
  ├── Show: Both options
  ├── Show: Both "existing" and "new player" modes
  └── Show: Divider between options
```

---

## Data Models

### Player Model (ludora-api/models/Player.js)

```javascript
{
  id: UUID,                       // Primary key
  privacy_code: STRING(8),        // Unique, auto-generated
  display_name: STRING(100),      // Public name shown to others
  user_id: STRING | null,         // For future user account linking
  teacher_id: STRING | null,      // Teacher who owns this player
  achievements: JSONB[],          // Array of achievement objects
  preferences: JSONB {},          // Player settings
  is_online: BOOLEAN,             // True if currently in session
  last_seen: DATE,                // Last activity timestamp
  is_active: BOOLEAN,             // Soft delete flag
  created_at: DATE,
  updated_at: DATE
}

Key Relationships:
├── belongsTo User (user_id) - Optional user account
├── belongsTo User as teacher (teacher_id) - Teacher owner
└── hasMany UserSession (player_id) - Active sessions
```

### UserSession Model (ludora-api/models/UserSession.js)

```javascript
{
  id: STRING,                     // Generated session ID
  user_id: STRING | null,         // For user sessions
  player_id: UUID | null,         // For player sessions
  expires_at: DATE,               // Session expiry (24 hours)
  last_accessed_at: DATE,         // For activity tracking
  is_active: BOOLEAN,             // Soft delete flag
  invalidated_at: DATE | null,    // When manually invalidated
  portal: STRING('teacher'|'student'), // Portal context
  metadata: JSONB {               // User agent, IP, login method
    userAgent: string,
    ipAddress: string,
    loginMethod: 'privacy_code' | 'firebase' | ...
  },
  created_at: DATE,
  updated_at: DATE
}

Key Methods:
├── isActive() - Checks not expired, not invalidated
├── updateLastAccessed() - Marks activity, auto-extends if < 2 hours
├── invalidate() - Soft delete
├── isPlayerSession() - Type check
└── isUserSession() - Type check
```

---

## Critical Authentication Gaps - Root Causes

### Issue 1: Cookie Persistence Failing on Page Reload

**Symptoms**:
- Players log in successfully
- Cookies set correctly (verified in dev tools)
- Page refreshes → cookies disappear
- `/players/me` returns 401

**Root Causes**:
1. **Cross-Subdomain Cookie Issues (Development)**
   - Dev uses localhost:5173 (student) and localhost:3003 (API)
   - cookieConfig.js sets `.localhost` domain (correct)
   - BUT: May not work with mixed localhost/127.0.0.1
   - May fail with non-standard dev proxy setup

2. **Missing HttpOnly Cookie Bridge**
   - Frontend cannot see/manage httpOnly cookies
   - Relies on browser to send them automatically
   - If browser doesn't recognize domain → cookies not sent
   - Student portal may have different origin than API

3. **Vite Dev Proxy Not Forwarding Cookies Properly**
   - Modern Vite may strip/block Set-Cookie headers
   - Check if Vite config has `proxy` settings for /api
   - May need explicit `credentials` handling

### Issue 2: Auth Requests Not Appearing in API Logs on Reload

**Symptoms**:
- Page reloads
- No `/players/me` request in API logs
- Suggests frontend not even attempting auth check

**Root Causes**:
1. **AuthManager Not Re-Initializing**
   - `initialize()` checks `if (this.isInitialized)` early exit
   - If initialized to failed state, won't retry
   - Especially if set to `isInitialized = true` after error (line 119)

2. **Player Auth Check Not Being Called**
   - `checkPlayerAuth()` calls `Player.getCurrentPlayer(true)`
   - Parameter `true` suppresses error messages
   - But if API call never happens, frontend won't know

3. **No Session Storage Fallback**
   - If cookies lost, no localStorage backup
   - Can't reconstruct auth state from stored data
   - AuthManager completely resets on reload

### Issue 3: "Not Logged In" Errors Despite Being Logged In

**Symptoms**:
- Player authenticated
- Later: "Not logged in" error
- Cookies still exist but not working

**Root Causes**:
1. **Token Expiry Not Extended**
   - Access token expires after 15 minutes
   - No automatic extension mechanism on activity
   - Access token expires before refresh is called
   - Subsequent requests all fail with 401

2. **Refresh Token Validation Failing**
   - Refresh token JWT verification fails
   - Possible clock skew between frontend/backend
   - JWT secret mismatch (unlikely)
   - Refresh endpoint not being called

3. **Player Validation on Refresh Failing**
   - Player found in database but `is_active: false`
   - Player deleted (soft delete)
   - Teacher deactivated (PlayerService checks this)
   - Session expired from database

### Issue 4: Legacy Code Conflicts

**Legacy Components Identified**:
1. **student_session Cookie** (deprecated)
   - Set by `/players/login` for compatibility
   - Used nowhere in modern auth flow
   - Creates confusion about which cookie to use

2. **Dual Token System Partially Implemented**
   - Access token properly implemented
   - Refresh token generated but manual JWT verification in player refresh
   - Not using AuthService refresh logic like user auth
   - Inconsistency between player and user refresh handling

3. **Multiple Auth Attempts**
   - `authenticateUserOrPlayer` tries user THEN player
   - On student portal, tries player in wrong order
   - AuthManager also tries both in wrong order
   - Leads to race conditions

4. **Debug Logging Left in Code**
   - Multiple `// TODO remove debug` comments
   - Especially in StudentLogin.jsx handleExistingPlayerLoginComplete
   - In Player.getCurrentPlayer in apiClient
   - In /players/me endpoint

### Issue 5: Missing Player Auth Session Refresh Integration

**What Works**:
- User auth has full refresh token system with AuthService
- AuthService.refreshAccessToken() handles user refresh
- Database-backed session persistence

**What's Missing for Players**:
- No PlayerAuthService equivalent
- Player refresh done manually in players.js route
- No database-backed refresh token storage
- Refresh tokens are pure JWTs (not stored/revokable)
- No coordination between PlayerService and refresh logic

---

## Authentication Flow Comparison: Users vs Players

### User Authentication (Works)

```
1. Login (POST /auth/login via Firebase)
   ├── Firebase authenticates user
   ├── Backend verifies idToken
   ├── Creates UserSession record
   ├── Generates access + refresh tokens
   └── Sets teacher_access_token, teacher_refresh_token cookies

2. Access Resource
   ├── Browser sends cookies automatically
   ├── Middleware verifies access token
   ├── Success → access granted
   └── Continue

3. Access Token Expires (15 min)
   ├── Frontend gets 401
   ├── API client calls POST /auth/refresh
   ├── Backend calls AuthService.refreshAccessToken()
   ├── AuthService looks up refresh token in database
   ├── Generates new access token
   ├── Sets new teacher_access_token cookie
   └── Frontend retries request → success

4. Logout
   ├── Frontend calls POST /auth/logout
   ├── Backend revokes refresh token
   ├── Clears both cookies
   └── UserSession marked inactive
```

### Player Authentication (Broken)

```
1. Login (POST /players/login)
   ├── PlayerService finds player by privacy_code
   ├── Sets player online: true
   ├── Creates UserSession record
   ├── Generates access + refresh tokens (both JWTs)
   ├── Sets student_access_token, student_refresh_token cookies
   └── Returns player data

2. Access Resource
   ├── Browser sends cookies (ISSUE: may not work due to domain)
   ├── Middleware verifies access token
   ├── Success → access granted
   └── Continue

3. Access Token Expires (15 min)
   ├── Frontend gets 401
   ├── API client calls POST /players/refresh
   ├── Backend extracts payload from student_refresh_token JWT
   ├── Gets fresh player data from database
   ├── Generates new access token (JWT)
   ├── Sets new student_access_token cookie
   └── Frontend retries request (ISSUE: may still fail)

4. Page Reload (CRITICAL ISSUE)
   ├── AuthManager.initialize() called
   ├── checkPlayerAuth() → Player.getCurrentPlayer(true)
   ├── Sends GET /players/me with cookies
   ├── Middleware tries to verify student_access_token (may fail)
   ├── Tries to refresh with student_refresh_token
   ├── Returns player data IF successful
   └── ISSUE: If refresh fails → returns 401 → auth lost

5. Logout
   ├── Frontend calls POST /players/logout
   ├── Backend sets player offline: false
   ├── Invalidates UserSession
   ├── Clears cookies
   └── Returns success
```

---

## Cross-Cutting Concerns

### Cookie Domain Strategy

**Current Implementation**:
```
Development: '.localhost'
  ├── Enables: localhost:5173 ← localhost:3003
  ├── Requires: Vite proxy configured for /api
  └── Issue: May not work with all dev setups

Staging/Production: '.ludora.app'
  ├── Enables: my.ludora.app ← ludora.app
  ├── Shared: student_* cookies available to both subdomains
  └── Secure: Explicit domain prevents oversharing
```

### Session Lifecycle

**Player Session Lifecycle**:
```
Creation (via POST /players/login):
  ├── UserSession created with 24-hour expiry
  ├── Portal: 'student'
  └── is_active: true

Activity Update (via GET /players/me):
  ├── UserSession.updateLastAccessed()
  ├── If expires within 2 hours → extend to 24 hours
  ├── Access token also refreshed (15 min renewal)
  └── Keeps session alive during active use

Expiry (cleanup):
  ├── After 24 hours with no activity
  ├── PlayerService.cleanupExpiredSessions() runs hourly
  ├── Deleted from database
  └── Player automatically logged out

Manual Logout:
  ├── PlayerService.logoutPlayer() called
  ├── Player.is_online = false
  ├── UserSession.invalidate() called
  ├── Browser cookies cleared
  └── Session marked as invalidated in database
```

---

## Identified Legacy Code for Cleanup

### Code to Remove/Fix:

1. **student_session Cookie** (ludora-api/routes/players.js line 123-125)
   - Deprecated dual-token tracking
   - Only for compatibility during migration
   - Can be removed once player refresh proven stable

2. **Debug Logging** (Multiple files)
   - ludora-front/src/components/auth/StudentLogin.jsx (lines 211-249)
   - ludora-front/src/services/apiClient.js (lines 823-848, 82-104)
   - ludora-api/routes/players.js (lines 251-307)
   - Should be removed before production

3. **Firebase Logout on Student Portal** (ludora-front/src/services/AuthManager.js)
   - Lines 129-187: clearFirebaseAuthenticationState()
   - Aggressive clearing of Firebase keys
   - May not be needed with proper auth strategy
   - Verify works without before cleanup

4. **Redundant Auth Attempts**
   - AuthManager.determineAuthStrategy() tries player first
   - But executeAuthStrategy() also tries both
   - Potential race condition between firebase and player auth
   - Should be single consolidated flow

5. **Missing Error Handling**
   - PlayerService methods have minimal error context
   - API errors don't distinguish between "not found" and "inactive"
   - Should provide specific error types for debugging

---

## Key Findings Summary

### What's Working:
- Backend authentication middleware correctly implemented
- Cookie configuration properly set up for cross-subdomain sharing
- Token generation and validation working correctly
- Player model and database persistence solid
- UserSession tracking comprehensive

### What's Broken:
- Cookie persistence from API to frontend failing
- Page reload losing authentication state
- Frontend not re-checking auth on load
- Legacy code creating confusion and conflicts
- Refresh token flow not robust enough for page reloads

### What Needs Redesign:
- AuthManager initialization to handle failed initial auth
- Frontend cookie handling for development environment
- Player session refresh to be more resilient
- Removal of legacy cookies and code
- Better error distinction in player authentication

---

## Recommendations for Fix

### Priority 1 (Critical - Session Persistence):
1. Debug cookie domain settings in development
2. Verify Vite proxy correctly handling Set-Cookie headers
3. Ensure `/players/me` called on app initialization with proper retry
4. Add cookie fallback or session storage for development

### Priority 2 (High - Auth Recovery):
1. Implement robust refresh token handling for players
2. Add specific error types for auth failures
3. Handle clock skew and token validation issues
4. Add session state recovery on page reload

### Priority 3 (Medium - Code Quality):
1. Remove legacy student_session cookie code
2. Remove all debug logging
3. Consolidate duplicate auth attempts
4. Standardize player and user auth refresh handling

### Priority 4 (Low - Architecture):
1. Consider moving player refresh to PlayerAuthService
2. Store refresh tokens in database (for revocation)
3. Implement cross-domain session restoration
4. Add analytics for auth flow debugging

---

## Files Affected & Their Purposes

### Backend (ludora-api/)
- **middleware/auth.js** - Authentication validation, token verification, refresh handling
- **middleware/validation.js** - `studentsAccessMiddleware` for access control
- **routes/auth.js** - User authentication, Firebase integration, token management
- **routes/players.js** - Player authentication, privacy code login, session management
- **services/PlayerService.js** - Player CRUD, session management, status updates
- **services/AuthService.js** - Token generation/validation, user refresh handling
- **models/Player.js** - Player data model, privacy code generation
- **models/UserSession.js** - Session data model, persistence, lifecycle management
- **utils/cookieConfig.js** - Cookie domain/security settings, cross-subdomain handling

### Frontend (ludora-front/)
- **src/services/AuthManager.js** - Singleton auth state manager, strategy determination
- **src/services/apiClient.js** - HTTP client, cookie-based requests, auto-refresh
- **src/components/auth/StudentLogin.jsx** - Login UI, privacy code entry, new player creation
- **src/pages/students/StudentHome.jsx** - Portal home, uses authentication context
- **src/contexts/UserContext.jsx** - (Presumed) Auth state provider, login/logout handlers
- **src/hooks/useUser.js** - (Presumed) Custom hook for accessing auth state

---


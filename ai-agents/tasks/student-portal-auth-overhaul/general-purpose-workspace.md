# General-Purpose Agent Workspace: Authentication Flow Design (Phase 2)

**Agent**: General-Purpose Development Specialist
**Task**: Design authentication flow fixes for student portal
**Status**: IN PROGRESS
**Date**: 2025-11-23

---

## Executive Summary

This document provides detailed technical designs for fixing the 3 critical (P0) issues and 1 major (P1) issue identified in the student portal authentication system. Each design includes implementation steps, risk assessment, rollback strategy, and test cases.

---

## Table of Contents

1. [Cookie Persistence Fix Design](#1-cookie-persistence-fix-design-p0-critical)
2. [AuthManager Initialization Redesign](#2-authmanager-initialization-redesign-p0-critical)
3. [Player Refresh Token Strategy Decision](#3-player-refresh-token-strategy-decision-p2-medium)
4. [Legacy Code Removal Plan](#4-legacy-code-removal-plan-p1-major)
5. [Implementation Timeline](#5-implementation-timeline)
6. [Risk Assessment Matrix](#6-risk-assessment-matrix)

---

## 1. Cookie Persistence Fix Design (P0 Critical)

### Problem Statement

Players log in successfully, cookies are set (verified in browser dev tools), but after page reload:
1. Cookies appear to disappear or are not sent to API
2. `/players/me` returns 401
3. No auth requests appear in API logs on reload

### Root Cause Analysis

After analyzing the code, the root cause is a **combination of issues**:

#### Issue 1A: Cookie Domain Configuration Inconsistency

**Current Configuration** (`cookieConfig.js` line 19-23):
```javascript
case 'development':
default:
  // CRITICAL FIX: Use .localhost domain for cross-subdomain cookie sharing
  return '.localhost';
```

**Problem**: The `.localhost` domain is set, but:
- Frontend runs on `my.localhost:5173` (student portal) or `localhost:5173` (teacher portal)
- API runs on `localhost:3003`
- Browser may not recognize `.localhost` as a valid domain for cross-subdomain sharing
- Some browsers treat `localhost` specially and don't apply domain rules

#### Issue 1B: Vite Proxy Not Forwarding Set-Cookie Headers

**Current Vite Config** (`vite.config.js` lines 61-129):
```javascript
proxy: {
  '/api': {
    target: `http://${VITE_CONFIG.api.domain}:${VITE_CONFIG.api.port}`,
    changeOrigin: true,
    secure: false,
    // Missing: cookieDomainRewrite configuration
  }
}
```

**Problem**: The Vite proxy may be:
- Stripping `Set-Cookie` headers
- Not rewriting cookie domains properly
- Not preserving cookie path settings

#### Issue 1C: Frontend Not Calling `/players/me` on Reload

**Current AuthManager** (`AuthManager.js` line 84-88):
```javascript
async initialize() {
  if (this.isInitialized) {
    clog('[AuthManager] Already initialized, returning current state');
    return this.getAuthState();
  }
```

**Problem**: After page reload:
- AuthManager instance is recreated (new instance)
- BUT `isInitialized` might be set too early (line 119)
- Or API call fails silently without proper retry

### Proposed Solution

#### Solution 1A: Remove Cookie Domain in Development

**Change** (`cookieConfig.js`):
```javascript
// BEFORE
case 'development':
default:
  return '.localhost';

// AFTER
case 'development':
default:
  // In development, don't set domain - let browser use default (current host)
  // This ensures cookies work with Vite proxy which rewrites requests
  return undefined;  // Browser will default to current origin
```

**Rationale**:
- When domain is `undefined`, browser stores cookie for the exact origin
- Vite proxy forwards requests to API, so cookies for `localhost:5173` include API calls
- Simpler and more reliable than cross-subdomain sharing in dev

#### Solution 1B: Configure Vite Proxy for Cookie Handling

**Change** (`vite.config.js`):
```javascript
proxy: {
  '/api': {
    target: `http://${VITE_CONFIG.api.domain}:${VITE_CONFIG.api.port}`,
    changeOrigin: true,
    secure: false,
    ws: true,
    // ADD THESE CONFIGURATIONS:
    cookieDomainRewrite: {
      '.localhost': 'localhost',  // Rewrite any .localhost domain
      'localhost': 'localhost'    // Keep localhost as-is
    },
    cookiePathRewrite: {
      '*': '/'  // Ensure cookies are available for all paths
    },
    headers: {
      'X-Forwarded-Host': `localhost:${VITE_CONFIG.frontend.port}`,
      'X-Forwarded-Proto': 'http'
    },
    configure: (proxy, options) => {
      // Existing SSE handling...

      // ADD: Log cookie handling for debugging
      proxy.on('proxyRes', (proxyRes, req, res) => {
        const setCookie = proxyRes.headers['set-cookie'];
        if (setCookie) {
          console.log('🍪 Vite proxy: Set-Cookie header received:', setCookie);
        }
      });
    }
  }
}
```

#### Solution 1C: Add Session Storage Fallback for Development

**New utility** (`ludora-front/src/utils/authPersistence.js`):
```javascript
/**
 * Session storage fallback for development when cookies fail
 * Production uses httpOnly cookies only
 */

const AUTH_STATE_KEY = 'ludora_auth_state_dev';

export function persistAuthState(authState) {
  if (process.env.NODE_ENV !== 'development') return;

  try {
    // Only persist minimal state needed for recovery
    const minimalState = {
      authType: authState.authType,
      entityId: authState.player?.id || authState.user?.id,
      timestamp: Date.now()
    };
    sessionStorage.setItem(AUTH_STATE_KEY, JSON.stringify(minimalState));
  } catch (e) {
    console.warn('[authPersistence] Failed to persist auth state:', e);
  }
}

export function getPersistedAuthState() {
  if (process.env.NODE_ENV !== 'development') return null;

  try {
    const stored = sessionStorage.getItem(AUTH_STATE_KEY);
    if (!stored) return null;

    const state = JSON.parse(stored);

    // Check if state is still valid (within 24 hours)
    if (Date.now() - state.timestamp > 24 * 60 * 60 * 1000) {
      sessionStorage.removeItem(AUTH_STATE_KEY);
      return null;
    }

    return state;
  } catch (e) {
    return null;
  }
}

export function clearPersistedAuthState() {
  sessionStorage.removeItem(AUTH_STATE_KEY);
}
```

### Test Cases for Cookie Persistence

```javascript
// Test Suite: Cookie Persistence Validation

describe('Cookie Persistence', () => {
  describe('Development Environment', () => {
    test('1. Login sets cookies that persist after reload', async () => {
      // 1. Navigate to student portal
      // 2. Login with privacy code
      // 3. Verify cookies exist in browser
      // 4. Reload page
      // 5. Verify /players/me is called
      // 6. Verify player data returned
    });

    test('2. Cookies survive tab close and reopen', async () => {
      // 1. Login
      // 2. Close tab
      // 3. Reopen tab
      // 4. Verify auth state recovered
    });

    test('3. Logout properly clears cookies', async () => {
      // 1. Login
      // 2. Logout
      // 3. Verify cookies cleared
      // 4. Verify /players/me returns 401
    });
  });

  describe('Production Environment', () => {
    test('4. Cross-subdomain cookies work', async () => {
      // 1. Login on my.ludora.app
      // 2. Verify cookies have domain .ludora.app
      // 3. Verify API calls to api.ludora.app include cookies
    });
  });
});
```

### Implementation Steps

1. **Step 1**: Modify `cookieConfig.js` to return `undefined` in development
2. **Step 2**: Update `vite.config.js` with `cookieDomainRewrite` configuration
3. **Step 3**: Add debug logging to verify cookies are being set
4. **Step 4**: Create session storage fallback utility
5. **Step 5**: Test end-to-end cookie flow

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaks production cookies | Low | High | Keep `.ludora.app` for prod/staging |
| Session storage security | Low | Medium | Only use in development |
| Vite proxy incompatibility | Low | Medium | Test with multiple browsers |

### Rollback Strategy

1. Revert `cookieConfig.js` to return `.localhost`
2. Remove Vite proxy cookie configuration
3. Remove session storage fallback
4. All changes are config-level, no database changes

---

## 2. AuthManager Initialization Redesign (P0 Critical)

### Problem Statement

1. `/players/me` is not being called on page reload
2. AuthManager exits early if `isInitialized` is true
3. No retry mechanism for failed auth attempts
4. Auth state lost after page reload

### Root Cause Analysis

**Current Initialization Flow** (`AuthManager.js`):
```javascript
async initialize() {
  if (this.isInitialized) {
    clog('[AuthManager] Already initialized, returning current state');
    return this.getAuthState();  // <-- PROBLEM: Returns stale state
  }
  // ...
  this.isInitialized = true;  // <-- PROBLEM: Set even on failure (line 119)
}
```

**Problems Identified**:
1. `isInitialized` blocks re-initialization but doesn't guarantee auth succeeded
2. On page reload, AuthManager is new instance but cookies exist
3. If first auth attempt fails, no retry occurs
4. Error at line 117 sets `isInitialized = true` even on failure

### Proposed Solution

#### Solution 2A: Force Re-Check on Every Page Load

**Redesigned `initialize()` method**:
```javascript
async initialize(forceRefresh = false) {
  // Allow re-initialization if forced or never successfully authenticated
  if (this.isInitialized && !forceRefresh && this.currentAuth) {
    clog('[AuthManager] Already initialized with valid auth, returning current state');
    return this.getAuthState();
  }

  try {
    clog('[AuthManager] 🚀 Starting authentication initialization...');
    this.isLoading = true;
    this.notifyAuthListeners();

    // Step 1: Load settings
    await this.loadSettings();

    // Step 2: Determine strategy
    const authStrategy = this.determineAuthStrategy();
    clog('[AuthManager] 📋 Authentication strategy:', authStrategy);

    // Step 3: Execute with retry logic
    await this.executeAuthStrategyWithRetry(authStrategy);

    // Only mark as initialized if we have a definitive result
    this.isInitialized = true;
    this.isLoading = false;

    clog('[AuthManager] ✅ Initialization complete:', this.getAuthState());
    this.notifyAuthListeners();

    return this.getAuthState();
  } catch (error) {
    cerror('[AuthManager] ❌ Initialization failed:', error);
    this.isLoading = false;
    // DON'T set isInitialized = true on failure!
    this.notifyAuthListeners();
    throw error;
  }
}
```

#### Solution 2B: Add Retry Logic with Exponential Backoff

**New method** `executeAuthStrategyWithRetry()`:
```javascript
async executeAuthStrategyWithRetry(strategy, maxRetries = 3) {
  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      clog(`[AuthManager] 🔄 Auth attempt ${attempt}/${maxRetries}`);
      await this.executeAuthStrategy(strategy);

      // If we got here without error, auth completed (success or allowed anonymous)
      return;
    } catch (error) {
      lastError = error;

      // Don't retry on certain errors
      if (error.message.includes('network') || error.message.includes('fetch')) {
        // Network error - worth retrying
        const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000); // 1s, 2s, 4s, max 5s
        clog(`[AuthManager] ⏳ Network error, retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        // Other errors (auth failed) - don't retry
        throw error;
      }
    }
  }

  // All retries exhausted
  throw lastError || new Error('Auth failed after all retries');
}
```

#### Solution 2C: Handle Offline Scenarios Gracefully

**Add offline detection**:
```javascript
async executeAuthStrategy(strategy) {
  // Check if offline
  if (!navigator.onLine) {
    clog('[AuthManager] 📴 Offline detected, using cached state');

    // Try to recover from session storage (development only)
    const cached = getPersistedAuthState();
    if (cached) {
      this.currentAuth = { type: cached.authType, entity: null };
      return;
    }

    // No cached state - allow anonymous if strategy permits
    if (strategy.allowAnonymous) {
      this.currentAuth = null;
      return;
    }

    throw new Error('Offline and no cached authentication');
  }

  // Continue with normal auth flow...
}
```

#### Solution 2D: Add App-Level Re-Initialization Hook

**Update App.jsx or main entry point**:
```javascript
// In App.jsx or UserContext
useEffect(() => {
  const initAuth = async () => {
    try {
      // Always force refresh on mount (page load/reload)
      await authManager.initialize(true);
    } catch (error) {
      console.error('Auth initialization failed:', error);
    }
  };

  initAuth();

  // Listen for online/offline events
  const handleOnline = () => {
    if (!authManager.currentAuth) {
      authManager.initialize(true);
    }
  };

  window.addEventListener('online', handleOnline);
  return () => window.removeEventListener('online', handleOnline);
}, []);
```

### Test Cases for AuthManager Initialization

```javascript
describe('AuthManager Initialization', () => {
  test('1. /players/me called on every page load', async () => {
    // Mock logged-in state
    // Call authManager.initialize(true)
    // Verify /players/me was called
    // Verify player data returned
  });

  test('2. Retry on network failure', async () => {
    // Mock first 2 API calls to fail
    // Mock 3rd call to succeed
    // Verify 3 attempts were made
    // Verify auth eventually succeeds
  });

  test('3. Graceful offline handling', async () => {
    // Mock navigator.onLine = false
    // Call initialize
    // Verify no API calls made
    // Verify appropriate state set
  });

  test('4. Re-initialization after failure', async () => {
    // First initialize fails
    // Verify isInitialized is false
    // Second initialize succeeds
    // Verify auth state correct
  });
});
```

### Implementation Steps

1. **Step 1**: Refactor `initialize()` to accept `forceRefresh` parameter
2. **Step 2**: Add `executeAuthStrategyWithRetry()` method
3. **Step 3**: Add offline detection and handling
4. **Step 4**: Update App.jsx to force refresh on mount
5. **Step 5**: Add debug logging throughout

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing auth flow | Medium | High | Extensive testing |
| Infinite retry loop | Low | Medium | Max retry limit |
| Race conditions | Medium | Medium | Single initialization lock |

### Rollback Strategy

1. Revert AuthManager.js changes
2. All changes are code-level, no database impact
3. Can be feature-flagged if needed

---

## 3. Player Refresh Token Strategy Decision (P2 Medium)

### Current State Analysis

**User Tokens**: Database-stored with revocation
```javascript
// AuthService.refreshAccessToken uses RefreshToken table
RefreshToken {
  id: STRING,
  user_id: STRING,
  token_hash: STRING,
  expires_at: DATE,
  is_revoked: BOOLEAN
}
```

**Player Tokens**: Pure JWT (no database storage)
```javascript
// players.js line 98-110
const refreshPayload = {
  id: result.player.id,
  type: 'player',
  tokenId: refreshTokenId,
  entityType: 'player'
};
const refreshToken = jwt.sign(refreshPayload, process.env.JWT_SECRET, {
  expiresIn: '7d',
  issuer: 'ludora-api',
  audience: 'ludora-student-portal'
});
```

### Decision: Keep Pure JWT for Players

**Recommendation**: Keep player refresh tokens as pure JWTs (no database storage)

**Rationale**:
1. **Simplicity**: Players are anonymous, less security risk than authenticated users
2. **Scalability**: No database queries for player token validation
3. **Consistency**: Already working, just need better error handling
4. **Player Lifecycle**: Players can be soft-deleted, JWT validation can check `is_active`

### Enhancements for JWT-Based Player Tokens

#### Enhancement 3A: Add Token Version for Rotation

**Modified token payload**:
```javascript
const refreshPayload = {
  id: result.player.id,
  type: 'player',
  tokenId: generateId(),
  tokenVersion: player.token_version || 1,  // NEW
  entityType: 'player',
  iat: Math.floor(Date.now() / 1000)
};
```

**Player model addition**:
```javascript
// Add to Player model
token_version: {
  type: DataTypes.INTEGER,
  defaultValue: 1
}
```

**Revocation mechanism**: Increment `token_version` to invalidate all existing tokens

#### Enhancement 3B: Add Specific Error Types

**New error types** (`ludora-api/utils/playerAuthErrors.js`):
```javascript
export class PlayerAuthError extends Error {
  constructor(message, code, statusCode = 401) {
    super(message);
    this.name = 'PlayerAuthError';
    this.code = code;
    this.statusCode = statusCode;
  }
}

export const PLAYER_AUTH_ERRORS = {
  TOKEN_EXPIRED: new PlayerAuthError('Player token expired', 'PLAYER_TOKEN_EXPIRED'),
  TOKEN_INVALID: new PlayerAuthError('Invalid player token', 'PLAYER_TOKEN_INVALID'),
  TOKEN_REVOKED: new PlayerAuthError('Player token revoked', 'PLAYER_TOKEN_REVOKED'),
  PLAYER_NOT_FOUND: new PlayerAuthError('Player not found', 'PLAYER_NOT_FOUND', 404),
  PLAYER_INACTIVE: new PlayerAuthError('Player account inactive', 'PLAYER_INACTIVE', 403),
  TEACHER_INACTIVE: new PlayerAuthError('Teacher account inactive', 'TEACHER_INACTIVE', 403),
  SESSION_EXPIRED: new PlayerAuthError('Player session expired', 'SESSION_EXPIRED'),
};
```

**Usage in middleware**:
```javascript
// In authenticatePlayer middleware
if (!player) {
  throw PLAYER_AUTH_ERRORS.PLAYER_NOT_FOUND;
}
if (!player.is_active) {
  throw PLAYER_AUTH_ERRORS.PLAYER_INACTIVE;
}
```

#### Enhancement 3C: Frontend Error Handling

**Update apiClient.js refresh logic**:
```javascript
// In apiRequestWithRetry, add specific error handling
if (response.status === 401) {
  const errorData = await response.json().catch(() => ({}));

  switch (errorData.code) {
    case 'PLAYER_TOKEN_EXPIRED':
    case 'PLAYER_TOKEN_REVOKED':
      // Attempt refresh
      return attemptTokenRefresh(endpoint, options);

    case 'PLAYER_NOT_FOUND':
    case 'PLAYER_INACTIVE':
      // Player no longer valid - force logout
      await Player.logout();
      authManager.reset();
      throw new Error('Your session has ended. Please log in again.');

    default:
      throw new ApiError(errorData.error || 'Authentication failed', 401);
  }
}
```

### Alternative: Database-Stored Player Tokens (NOT RECOMMENDED)

If database storage is needed in future, here's the schema:

```javascript
// PlayerRefreshToken model (hypothetical)
PlayerRefreshToken {
  id: UUID,
  player_id: UUID,
  token_hash: STRING(64),
  expires_at: DATE,
  is_revoked: BOOLEAN,
  device_info: JSONB,
  created_at: DATE
}
```

**Migration effort**: 3-4 hours
**Reasons to consider later**:
- Multi-device session management
- Security audit requirements
- Token usage analytics

### Implementation Steps

1. **Step 1**: Add `token_version` field to Player model (migration)
2. **Step 2**: Create `playerAuthErrors.js` utility
3. **Step 3**: Update `authenticatePlayer` middleware with specific errors
4. **Step 4**: Update `apiClient.js` with error-specific handling
5. **Step 5**: Add revocation method to PlayerService

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Token version migration | Low | Low | Default to 1 |
| Error handling changes | Low | Medium | Test thoroughly |
| Breaking existing tokens | Low | Medium | Backward compatible |

---

## 4. Legacy Code Removal Plan (P1 Major)

### Items to Remove/Deprecate

#### 4A: student_session Cookie

**Location**: `ludora-api/routes/players.js` lines 122-125
```javascript
// Keep existing session for compatibility but will be phased out
const playerSessionConfig = createAccessTokenConfig();
playerSessionConfig.maxAge = 24 * 60 * 60 * 1000;
res.cookie('student_session', result.sessionId, playerSessionConfig);
```

**Removal Timeline**:
- **Week 1**: Add deprecation warning in logs
- **Week 2**: Stop setting cookie for new logins
- **Week 3**: Remove cookie-setting code entirely
- **Week 4**: Remove from logout/clear code

**Risk**: Low - Cookie is not used anywhere in current code

#### 4B: Debug Logging Removal

**Files with `// TODO remove debug` comments**:

1. **`StudentLogin.jsx`** (lines 211-249)
   - Multiple debug logs in login flow
   - Safe to remove after auth fixes verified

2. **`apiClient.js`** (lines 823-848, 82-104)
   - Debug logs in Player.getCurrentPlayer
   - Debug logs in apiRequestWithRetry
   - Safe to remove after auth fixes verified

3. **`players.js`** (lines 251-307)
   - Debug logs in `/players/me` endpoint
   - Safe to remove after auth fixes verified

4. **`AuthManager.js`** (multiple locations)
   - Debug logs in executeAuthStrategy
   - Debug logs in checkPlayerAuth
   - Safe to remove after auth fixes verified

**Removal Process**:
```bash
# Find all debug logs
grep -rn "TODO remove debug" ludora-front/src/ ludora-api/

# Remove systematically by task tag
# All tagged: "fix player authentication persistence"
```

**Timeline**: After Phase 3 implementation verified working

#### 4C: Unified Auth Middleware Consolidation

**Current State**: Multiple overlapping auth checks
- `authenticateToken` - Users only
- `authenticatePlayer` - Players only
- `authenticateUserOrPlayer` - Both (unified)
- `optionalUserOrPlayer` - Both (optional)

**Consolidation Plan**:
1. Keep `authenticateUserOrPlayer` as primary for endpoints needing both
2. Keep `authenticateToken` for teacher-only endpoints
3. Deprecate `authenticatePlayer` (use unified instead)
4. Review and document when to use each

**Timeline**: After Phase 3, low priority

### Removal Schedule

| Item | Priority | Week 1 | Week 2 | Week 3 | Week 4 |
|------|----------|--------|--------|--------|--------|
| student_session cookie | P1 | Log warning | Stop setting | Remove code | Cleanup |
| Debug logs | P1 | - | - | Verify fixes | Remove all |
| Middleware consolidation | P2 | - | Document | - | Implement |

### Risk Assessment for Removals

| Removal | Risk Level | Rollback Difficulty | Recommendation |
|---------|------------|---------------------|----------------|
| student_session | Very Low | Easy | Proceed |
| Debug logs | Very Low | Easy | Proceed after fixes |
| Middleware | Medium | Medium | Defer to Phase 4 |

---

## 5. Implementation Timeline

### Phase 2: Design (Current) - 2-3 hours
- [x] Cookie persistence fix design
- [x] AuthManager initialization redesign
- [x] Player refresh token strategy decision
- [x] Legacy code removal plan
- [ ] Review and approval

### Phase 3: Implementation - 4-5 hours

**Day 1** (2-3 hours):
1. Cookie configuration fixes
2. Vite proxy updates
3. Initial testing

**Day 2** (2-3 hours):
1. AuthManager initialization refactor
2. Retry logic implementation
3. Integration testing

### Phase 4: Cleanup - 2-3 hours

**Week 1-2**:
1. Remove student_session cookie
2. Remove debug logs after verification

### Phase 5: Testing - 3-4 hours

1. Manual testing of all auth flows
2. Cross-browser testing
3. Production verification

---

## 6. Risk Assessment Matrix

| Issue | Severity | Fix Complexity | Risk Level | Rollback Time |
|-------|----------|----------------|------------|---------------|
| Cookie persistence | Critical | Medium | Medium | 5 minutes |
| AuthManager init | Critical | Medium | Medium | 5 minutes |
| Token strategy | Medium | Low | Low | N/A (enhancement) |
| Legacy removal | Low | Low | Very Low | 2 minutes |

### Overall Risk Mitigation Strategy

1. **Feature flags**: Not needed (changes are incremental and reversible)
2. **Staged rollout**: Deploy to staging first, verify, then production
3. **Monitoring**: Add specific logging to track auth success rates
4. **Rollback plan**: Git revert with clear commit messages

---

## 7. Files to Modify

### Backend (ludora-api/)

| File | Changes | Priority |
|------|---------|----------|
| `utils/cookieConfig.js` | Return undefined in dev | P0 |
| `routes/players.js` | Remove student_session, add error codes | P1 |
| `middleware/auth.js` | Add specific error types | P1 |
| `utils/playerAuthErrors.js` | New file - error types | P1 |
| `models/Player.js` | Add token_version field | P2 |

### Frontend (ludora-front/)

| File | Changes | Priority |
|------|---------|----------|
| `vite.config.js` | Add cookieDomainRewrite | P0 |
| `src/services/AuthManager.js` | Redesign initialize() | P0 |
| `src/services/apiClient.js` | Add error-specific handling | P1 |
| `src/utils/authPersistence.js` | New file - session storage | P2 |

---

## 8. Next Steps

1. **Review this design document** with team lead
2. **Get approval** before proceeding to Phase 3
3. **Begin implementation** of P0 fixes first
4. **Test thoroughly** before removing debug logs
5. **Deploy to staging** and verify
6. **Deploy to production** after staging verification

---

## Appendix A: Current Code References

### Cookie Configuration
- `/ludora-api/utils/cookieConfig.js` - 221 lines
- Key functions: `getCookieDomain()`, `createAuthCookieConfig()`

### Authentication Flow
- `/ludora-api/middleware/auth.js` - 489 lines
- Key middlewares: `authenticateUserOrPlayer`, `authenticatePlayer`

### Frontend Auth
- `/ludora-front/src/services/AuthManager.js` - 529 lines
- Key methods: `initialize()`, `checkPlayerAuth()`

### Player API
- `/ludora-api/routes/players.js` - 674 lines
- Key endpoints: `POST /login`, `POST /refresh`, `GET /me`

---

*Document created: 2025-11-23*
*Status: Ready for Review*

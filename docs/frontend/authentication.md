# Authentication

This document covers the authentication system, protected routes, and user management patterns used in the Ludora frontend application.

## Authentication Architecture

Ludora uses a hybrid authentication system combining:

- **Firebase Authentication** for user identity and Google OAuth
- **Custom JWT tokens** for API authorization
- **React Context** for client-side state management
- **Protected routes** for access control

## Firebase Integration

### Firebase Configuration

```javascript
// Firebase config from environment variables
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
```

### Google OAuth Login

```javascript
// /src/services/apiClient.js
async function loginWithFirebaseAuth() {
  try {
    const { initializeApp } = await import('firebase/app');
    const { getAuth, signInWithRedirect, GoogleAuthProvider, getRedirectResult } = await import('firebase/auth');

    const app = initializeApp(firebaseConfig);
    const auth = getAuth(app);
    const provider = new GoogleAuthProvider();

    // Check for redirect result first
    const result = await getRedirectResult(auth);
    if (result && result.user) {
      const idToken = await result.user.getIdToken();
      return await loginWithFirebase({ idToken });
    }

    // If no redirect result, trigger redirect
    await signInWithRedirect(auth, provider);

  } catch (error) {
    console.error('Firebase login error:', error);
    throw new Error('Error logging in with Google');
  }
}

// Exchange Firebase token for app token
export async function loginWithFirebase({ idToken }) {
  const response = await apiRequest('/auth/verify', {
    method: 'POST',
    body: JSON.stringify({ idToken })
  });

  if (response.valid && response.token) {
    authToken = response.token;
    localStorage.setItem('authToken', response.token);
  }

  return response;
}
```

## User Context Provider

### UserContext Implementation

```jsx
// /src/contexts/UserContext.jsx
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { User, SubscriptionPlan, Settings } from '@/services/apiClient';

const UserContext = createContext(null);

export function useUser() {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
}

export function UserProvider({ children }) {
  const [currentUser, setCurrentUser] = useState(null);
  const [settings, setSettings] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  // Check for persisted auth state on mount
  useEffect(() => {
    const init = async () => {
      await loadSettings();
      await checkPersistedAuth();
    };
    init();
  }, []);

  const checkPersistedAuth = useCallback(async () => {
    try {
      const token = localStorage.getItem('authToken');
      const rememberMe = localStorage.getItem('rememberMe') === 'true';
      const tokenExpiry = localStorage.getItem('tokenExpiry');

      if (!token) {
        setIsLoading(false);
        return;
      }

      // Check if token is expired
      if (tokenExpiry && new Date().getTime() > parseInt(tokenExpiry)) {
        clearAuth();
        setIsLoading(false);
        return;
      }

      // Try to get current user with existing token
      const user = await User.getCurrentUser();
      if (user) {
        await loadUserData(user);
        updateLastActivity();
        setIsAuthenticated(true);
      } else {
        clearAuth();
      }
    } catch (error) {
      console.error('Error checking persisted auth:', error);
      clearAuth();
    } finally {
      setIsLoading(false);
    }
  }, []);

  const loadUserData = useCallback(async (user) => {
    try {
      // Load user subscription if subscription system is enabled
      if (settings?.subscription_system_enabled) {
        try {
          const updatedUser = await checkUserSubscription(user);
          setCurrentUser(updatedUser);
        } catch (subscriptionError) {
          console.warn('Subscription check failed, proceeding without subscription:', subscriptionError);
          setCurrentUser(user);
        }
      } else {
        setCurrentUser(user);
      }
      setIsAuthenticated(true);
    } catch (error) {
      console.error('Error loading user data:', error);
      throw error;
    }
  }, [settings]);

  const login = useCallback(async (userData, rememberMe = false) => {
    try {
      await loadUserData(userData);

      // Set remember me preference
      if (rememberMe) {
        const oneWeekFromNow = new Date().getTime() + (7 * 24 * 60 * 60 * 1000);
        localStorage.setItem('tokenExpiry', oneWeekFromNow.toString());
        localStorage.setItem('rememberMe', 'true');
      } else {
        localStorage.removeItem('tokenExpiry');
        localStorage.setItem('rememberMe', 'false');
      }

      updateLastActivity();
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }, [loadUserData]);

  const logout = useCallback(async () => {
    try {
      const { logout: apiLogout } = await import('@/services/apiClient');
      await apiLogout();
    } catch (error) {
      console.error('API logout error:', error);
    } finally {
      clearAuth();
    }
  }, []);

  const clearAuth = useCallback(() => {
    setCurrentUser(null);
    setIsAuthenticated(false);
    localStorage.removeItem('authToken');
    localStorage.removeItem('tokenExpiry');
    localStorage.removeItem('rememberMe');
    localStorage.removeItem('lastActivity');
  }, []);

  const updateLastActivity = useCallback(() => {
    localStorage.setItem('lastActivity', new Date().getTime().toString());
  }, []);

  // Update last activity on user interactions
  useEffect(() => {
    if (isAuthenticated) {
      const handleActivity = () => updateLastActivity();

      document.addEventListener('click', handleActivity);
      document.addEventListener('keypress', handleActivity);

      return () => {
        document.removeEventListener('click', handleActivity);
        document.removeEventListener('keypress', handleActivity);
      };
    }
  }, [isAuthenticated, updateLastActivity]);

  const value = {
    currentUser,
    settings,
    isLoading,
    isAuthenticated,
    login,
    logout,
    updateUser: (updatedUserData) => {
      setCurrentUser(prev => ({ ...prev, ...updatedUserData }));
    },
    clearAuth
  };

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
}
```

## Protected Routes

### ProtectedRoute Component

```jsx
// /src/components/auth/ProtectedRoute.jsx
import { useUser } from '@/contexts/UserContext';
import { Navigate, useLocation } from 'react-router-dom';

export default function ProtectedRoute({ children }) {
  const { currentUser, isLoading } = useUser();
  const location = useLocation();

  // Show loading while checking authentication
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-indigo-50/50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Redirect to home if not authenticated
  if (!currentUser) {
    return <Navigate to="/" state={{ from: location }} replace />;
  }

  return children;
}
```

### AdminRoute Component

```jsx
// /src/components/auth/AdminRoute.jsx
import { useUser } from '@/contexts/UserContext';
import { Navigate } from 'react-router-dom';

export default function AdminRoute({ children }) {
  const { currentUser, isLoading } = useUser();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Check if user is authenticated and has admin role
  if (!currentUser || currentUser.role !== 'admin') {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}
```

### Route Configuration

```jsx
// /src/App.jsx
import { Routes, Route, Navigate } from 'react-router-dom';
import { useUser } from '@/contexts/UserContext';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import AdminRoute from '@/components/auth/AdminRoute';

function App() {
  const { currentUser, isLoading } = useUser();

  return (
    <Layout>
      <Routes>
        {/* Public routes */}
        <Route
          path='/'
          element={
            !isLoading && currentUser ? (
              <Navigate to='/dashboard' replace />
            ) : (
              <Pages.Home />
            )
          }
        />
        <Route path='/registration' element={<Pages.Registration />} />

        {/* Protected routes - require authentication */}
        <Route
          path='/dashboard'
          element={
            <ProtectedRoute>
              <Pages.Dashboard />
            </ProtectedRoute>
          }
        />

        <Route
          path='/account'
          element={
            <ProtectedRoute>
              <Pages.MyAccount />
            </ProtectedRoute>
          }
        />

        {/* Admin-only routes */}
        <Route
          path='/admin'
          element={
            <AdminRoute>
              <Pages.AdminPanel />
            </AdminRoute>
          }
        />

        <Route
          path='/users'
          element={
            <AdminRoute>
              <Pages.Users />
            </AdminRoute>
          }
        />
      </Routes>
    </Layout>
  );
}
```

## Login Modal

### LoginModal Component

```jsx
// /src/components/LoginModal.jsx
import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { User } from '@/services/apiClient';
import { useUser } from '@/contexts/UserContext';

export default function LoginModal({ isOpen, onClose }) {
  const [isLoading, setIsLoading] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState(null);
  const { login } = useUser();

  const handleGoogleLogin = async () => {
    try {
      setIsLoading(true);
      setError(null);

      // Trigger Firebase login
      const result = await User.login();

      if (result && result.user) {
        await login(result.user, rememberMe);
        onClose();
      }
    } catch (error) {
      console.error('Login error:', error);
      setError(error.message || 'Failed to log in');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-center text-2xl font-bold">
            התחברות
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6 py-4">
          {error && (
            <div className="p-3 text-sm text-red-600 bg-red-50 border border-red-200 rounded-md">
              {error}
            </div>
          )}

          <Button
            onClick={handleGoogleLogin}
            disabled={isLoading}
            className="w-full h-12 text-base"
          >
            {isLoading ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                מתחבר...
              </>
            ) : (
              <>
                <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
                  {/* Google icon SVG */}
                </svg>
                התחבר עם Google
              </>
            )}
          </Button>

          <div className="flex items-center space-x-2">
            <Checkbox
              id="remember"
              checked={rememberMe}
              onCheckedChange={setRememberMe}
            />
            <label
              htmlFor="remember"
              className="text-sm text-gray-700 cursor-pointer"
            >
              זכור אותי למשך שבוע
            </label>
          </div>

          <div className="text-xs text-gray-500 text-center">
            על ידי התחברות, אתה מסכים לתנאי השימוש ולמדיניות הפרטיות שלנו
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
```

## Session Management

### Token Management

```javascript
// /src/services/apiClient.js
// Store authentication token in memory
let authToken = null;

// Initialize auth token from localStorage on app start
if (typeof localStorage !== 'undefined') {
  authToken = localStorage.getItem('authToken');
}

// Add auth token to requests
export async function apiRequest(endpoint, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  };

  // Add auth token if available
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }

  const response = await fetch(url, {
    credentials: 'include',
    headers,
    ...options
  });

  // Handle token expiration
  if (response.status === 401) {
    authToken = null;
    localStorage.removeItem('authToken');
    // Redirect to login or trigger re-authentication
    throw new Error('Authentication expired');
  }

  return response.json();
}
```

### Session Timeout Handling

```jsx
// /src/hooks/useSessionTimeout.js
import { useEffect, useCallback } from 'react';
import { useUser } from '@/contexts/UserContext';

export function useSessionTimeout(timeoutMinutes = 30) {
  const { logout, isAuthenticated } = useUser();

  const checkSessionTimeout = useCallback(() => {
    if (!isAuthenticated) return;

    const lastActivity = localStorage.getItem('lastActivity');
    if (lastActivity) {
      const timeDiff = new Date().getTime() - parseInt(lastActivity);
      const timeoutMs = timeoutMinutes * 60 * 1000;

      if (timeDiff > timeoutMs) {
        logout();
        toast.error('Session expired due to inactivity');
      }
    }
  }, [isAuthenticated, logout, timeoutMinutes]);

  useEffect(() => {
    if (!isAuthenticated) return;

    // Check session timeout every minute
    const interval = setInterval(checkSessionTimeout, 60000);

    return () => clearInterval(interval);
  }, [isAuthenticated, checkSessionTimeout]);
}
```

## Role-Based Access Control

### Permission Hook

```jsx
// /src/hooks/usePermissions.js
import { useUser } from '@/contexts/UserContext';

export function usePermissions() {
  const { currentUser } = useUser();

  const hasRole = (role) => {
    return currentUser?.role === role;
  };

  const hasPermission = (permission) => {
    if (!currentUser) return false;

    const userPermissions = currentUser.permissions || [];
    return userPermissions.includes(permission);
  };

  const canAccess = (resource) => {
    // Define resource permissions
    const resourcePermissions = {
      'admin-panel': ['admin'],
      'user-management': ['admin', 'moderator'],
      'content-creation': ['admin', 'content-creator'],
      'game-builder': ['admin', 'game-creator'],
    };

    const requiredRoles = resourcePermissions[resource] || [];
    return requiredRoles.includes(currentUser?.role);
  };

  return {
    hasRole,
    hasPermission,
    canAccess,
    isAdmin: hasRole('admin'),
    isModerator: hasRole('moderator') || hasRole('admin'),
    isContentCreator: hasRole('content-creator') || hasRole('admin'),
  };
}

// Usage in components
export default function UserManagement() {
  const { canAccess } = usePermissions();

  if (!canAccess('user-management')) {
    return <div>Access denied</div>;
  }

  return (
    <div>
      {/* User management interface */}
    </div>
  );
}
```

### Conditional Rendering

```jsx
// /src/components/ConditionalRender.jsx
import { usePermissions } from '@/hooks/usePermissions';

export function RoleGuard({ role, children, fallback = null }) {
  const { hasRole } = usePermissions();

  return hasRole(role) ? children : fallback;
}

export function PermissionGuard({ permission, children, fallback = null }) {
  const { hasPermission } = usePermissions();

  return hasPermission(permission) ? children : fallback;
}

// Usage
<RoleGuard role="admin">
  <AdminButton />
</RoleGuard>

<PermissionGuard permission="delete-users">
  <DeleteButton />
</PermissionGuard>
```

## User Profile Management

### Profile Update

```jsx
export default function UserProfile() {
  const { currentUser, updateUser } = useUser();
  const [isEditing, setIsEditing] = useState(false);

  const form = useForm({
    defaultValues: {
      display_name: currentUser?.display_name || '',
      bio: currentUser?.bio || '',
    }
  });

  const handleUpdateProfile = async (data) => {
    try {
      const updatedUser = await User.updateMyUserData(data);
      updateUser(updatedUser);
      setIsEditing(false);
      toast.success('Profile updated successfully');
    } catch (error) {
      toast.error('Failed to update profile');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">Profile</h2>
        <Button
          variant="outline"
          onClick={() => setIsEditing(!isEditing)}
        >
          {isEditing ? 'Cancel' : 'Edit'}
        </Button>
      </div>

      {isEditing ? (
        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleUpdateProfile)}>
            {/* Form fields */}
          </form>
        </Form>
      ) : (
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium text-gray-500">Display Name</label>
            <p className="text-lg">{currentUser?.display_name}</p>
          </div>
          <div>
            <label className="text-sm font-medium text-gray-500">Email</label>
            <p className="text-lg">{currentUser?.email}</p>
          </div>
        </div>
      )}
    </div>
  );
}
```

## Best Practices

### 1. Security
- Never store sensitive data in localStorage
- Use secure, HTTP-only cookies for sensitive tokens when possible
- Implement proper CSRF protection
- Validate permissions on both client and server

### 2. User Experience
- Provide clear loading states during authentication
- Handle authentication errors gracefully
- Implement "remember me" functionality
- Show appropriate feedback for all auth actions

### 3. Performance
- Lazy load authentication-related components
- Cache user data appropriately
- Minimize authentication checks
- Optimize context re-renders

### 4. Error Handling
- Handle network failures gracefully
- Provide retry mechanisms for failed auth requests
- Clear sensitive data on authentication errors
- Log authentication events for debugging

### 5. Testing
- Mock authentication in tests
- Test protected route access
- Validate permission logic
- Test session timeout scenarios

This authentication architecture provides a secure, user-friendly authentication system for the Ludora application while maintaining flexibility for future enhancements.
# State Management

This document covers state management patterns and practices used in the Ludora frontend application.

## Architecture Overview

Ludora uses React Context API for global state management, with local component state for UI-specific concerns. The state management follows these principles:

- **Context for Global State**: User authentication, app settings, tutorial state
- **Local State for UI**: Form inputs, modal visibility, loading states
- **Server State**: API data managed through custom hooks

## Context Providers

### UserContext

The primary context for managing user authentication and app settings.

```jsx
// /src/contexts/UserContext.jsx
import { createContext, useContext, useState, useEffect, useCallback } from 'react';
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

  // Context methods
  const login = useCallback(async (userData, rememberMe = false) => {
    // Login implementation
  }, []);

  const logout = useCallback(async () => {
    // Logout implementation
  }, []);

  const updateUser = useCallback((updatedUserData) => {
    setCurrentUser(prev => ({ ...prev, ...updatedUserData }));
  }, []);

  const value = {
    currentUser,
    settings,
    isLoading,
    isAuthenticated,
    login,
    logout,
    updateUser,
    clearAuth
  };

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
}
```

**Usage Pattern:**
```jsx
import { useUser } from '@/contexts/UserContext';

export default function Dashboard() {
  const { currentUser, isLoading, isAuthenticated } = useUser();

  if (isLoading) return <div>Loading...</div>;
  if (!isAuthenticated) return <Navigate to="/login" />;

  return (
    <div>
      <h1>Welcome, {currentUser.display_name}!</h1>
    </div>
  );
}
```

### TutorialContext

Manages interactive tutorial state and progression.

```jsx
// /src/contexts/TutorialContext.jsx
export function TutorialProvider({ children }) {
  const [tutorialState, setTutorialState] = useState({
    isActive: false,
    currentStep: 0,
    tutorialType: null,
    completedTutorials: []
  });

  const startTutorial = useCallback((tutorialType) => {
    setTutorialState({
      isActive: true,
      currentStep: 0,
      tutorialType,
      completedTutorials: tutorialState.completedTutorials
    });
  }, [tutorialState.completedTutorials]);

  const nextStep = useCallback(() => {
    setTutorialState(prev => ({
      ...prev,
      currentStep: prev.currentStep + 1
    }));
  }, []);

  return (
    <TutorialContext.Provider value={{
      tutorialState,
      startTutorial,
      nextStep,
      completeTutorial,
      skipTutorial
    }}>
      {children}
    </TutorialContext.Provider>
  );
}
```

## Local State Patterns

### Form State Management

Using React Hook Form for complex forms:

```jsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

export default function UserProfileForm() {
  const form = useForm({
    resolver: zodResolver(userProfileSchema),
    defaultValues: {
      name: '',
      email: '',
      bio: ''
    }
  });

  const onSubmit = async (data) => {
    try {
      await updateUser(data);
      toast.success('Profile updated successfully');
    } catch (error) {
      toast.error('Failed to update profile');
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        {/* Form fields */}
      </form>
    </Form>
  );
}
```

### Modal State Management

```jsx
export default function UserManagement() {
  const [selectedUser, setSelectedUser] = useState(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

  const handleEditUser = (user) => {
    setSelectedUser(user);
    setIsEditModalOpen(true);
  };

  const handleDeleteUser = (user) => {
    setSelectedUser(user);
    setIsDeleteModalOpen(true);
  };

  const closeModals = () => {
    setIsEditModalOpen(false);
    setIsDeleteModalOpen(false);
    setSelectedUser(null);
  };

  return (
    <div>
      <UserList onEdit={handleEditUser} onDelete={handleDeleteUser} />

      <EditUserModal
        user={selectedUser}
        isOpen={isEditModalOpen}
        onClose={closeModals}
      />

      <DeleteUserModal
        user={selectedUser}
        isOpen={isDeleteModalOpen}
        onClose={closeModals}
      />
    </div>
  );
}
```

## Server State Management

### Custom Data Fetching Hooks

```jsx
// /src/hooks/useUsers.js
import { useState, useEffect } from 'react';
import { User } from '@/services/entities';

export function useUsers(filters = {}) {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        setLoading(true);
        const userData = await User.filter(filters);
        setUsers(userData);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
  }, [JSON.stringify(filters)]);

  const refetch = () => {
    setError(null);
    fetchUsers();
  };

  return { users, loading, error, refetch };
}
```

### Optimistic Updates Pattern

```jsx
export function useUserActions() {
  const { updateUser } = useUser();
  const [users, setUsers] = useState([]);

  const updateUserOptimistic = async (userId, updates) => {
    // Optimistic update
    setUsers(prev => prev.map(user =>
      user.id === userId ? { ...user, ...updates } : user
    ));

    try {
      const updatedUser = await User.update(userId, updates);
      // Update with server response
      setUsers(prev => prev.map(user =>
        user.id === userId ? updatedUser : user
      ));
      return updatedUser;
    } catch (error) {
      // Revert optimistic update
      setUsers(prev => prev.map(user =>
        user.id === userId ? { ...user, ...originalData } : user
      ));
      throw error;
    }
  };

  return { updateUserOptimistic };
}
```

## State Persistence

### LocalStorage Integration

```jsx
// Custom hook for persisted state
function usePersistedState(key, defaultValue) {
  const [state, setState] = useState(() => {
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : defaultValue;
    } catch (error) {
      console.error(`Error reading localStorage key "${key}":`, error);
      return defaultValue;
    }
  });

  const setValue = (value) => {
    try {
      setState(value);
      localStorage.setItem(key, JSON.stringify(value));
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  };

  return [state, setValue];
}

// Usage
export default function UserPreferences() {
  const [preferences, setPreferences] = usePersistedState('userPreferences', {
    theme: 'light',
    language: 'he',
    notifications: true
  });

  return (
    <div>
      <label>
        <input
          type="checkbox"
          checked={preferences.notifications}
          onChange={(e) => setPreferences(prev => ({
            ...prev,
            notifications: e.target.checked
          }))}
        />
        Enable notifications
      </label>
    </div>
  );
}
```

## Error State Management

### Error Boundary Pattern

```jsx
import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="p-4 text-center">
          <h2 className="text-lg font-semibold text-red-600">Something went wrong</h2>
          <p className="text-gray-600 mt-2">Please refresh the page and try again.</p>
          <button
            onClick={() => this.setState({ hasError: false, error: null })}
            className="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Global Error Toast

```jsx
// /src/hooks/useErrorHandler.js
import { toast } from 'sonner';

export function useErrorHandler() {
  const handleError = (error, customMessage) => {
    const message = customMessage || error.message || 'An unexpected error occurred';
    toast.error(message);
    console.error('Application error:', error);
  };

  return { handleError };
}
```

## Performance Optimization

### State Update Optimization

```jsx
// Batch state updates
const handleBulkUpdate = (updates) => {
  React.unstable_batchedUpdates(() => {
    setLoading(true);
    setError(null);
    setData(updates);
    setLoading(false);
  });
};

// Avoid unnecessary re-renders with useMemo
const expensiveValue = useMemo(() => {
  return data.filter(item => item.isActive).length;
}, [data]);

// Memoize callbacks to prevent child re-renders
const handleItemClick = useCallback((id) => {
  setSelectedItem(id);
}, []);
```

### Context Optimization

```jsx
// Split contexts to avoid unnecessary re-renders
const UserDataContext = createContext();
const UserActionsContext = createContext();

export function UserProvider({ children }) {
  const [userData, setUserData] = useState(null);

  const actions = useMemo(() => ({
    updateUser: (data) => setUserData(prev => ({ ...prev, ...data })),
    clearUser: () => setUserData(null)
  }), []);

  return (
    <UserDataContext.Provider value={userData}>
      <UserActionsContext.Provider value={actions}>
        {children}
      </UserActionsContext.Provider>
    </UserDataContext.Provider>
  );
}

// Separate hooks for data and actions
export const useUserData = () => useContext(UserDataContext);
export const useUserActions = () => useContext(UserActionsContext);
```

## Best Practices

### 1. State Structure
- Keep state flat when possible
- Normalize complex data structures
- Separate UI state from business data

### 2. Context Usage
- Create specific contexts for different concerns
- Avoid putting everything in one large context
- Use context for truly global state only

### 3. Performance
- Use `useMemo` and `useCallback` judiciously
- Split contexts to minimize re-renders
- Implement proper dependency arrays

### 4. Error Handling
- Always handle loading and error states
- Provide meaningful error messages
- Implement retry mechanisms for failed requests

### 5. Testing
- Test context providers in isolation
- Mock API calls in state tests
- Test error scenarios and edge cases

This state management approach provides a scalable, maintainable solution for the Ludora application while maintaining good performance and developer experience.
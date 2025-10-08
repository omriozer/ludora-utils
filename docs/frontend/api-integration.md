# API Integration

This document covers the API integration patterns, service layer architecture, and data fetching strategies used in the Ludora frontend.

## Service Layer Architecture

The application uses a centralized service layer built around a REST API client with entity-based abstractions.

### API Client Structure

```javascript
// /src/services/apiClient.js
const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:3003/api';

// Generic API request helper with authentication
export async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;

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

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: response.statusText }));
    throw new Error(error.message || `API request failed: ${response.status}`);
  }

  return response.json();
}
```

### Entity API Pattern

The application uses a consistent entity API pattern for CRUD operations:

```javascript
// Entity CRUD operations class
class EntityAPI {
  constructor(entityName) {
    this.entityName = entityName;
    this.basePath = `/entities/${entityName}`;
  }

  async find(query = {}) {
    const searchParams = new URLSearchParams(query);
    const queryString = searchParams.toString();
    const endpoint = queryString ? `${this.basePath}?${queryString}` : this.basePath;
    return apiRequest(endpoint);
  }

  async findById(id) {
    return apiRequest(`${this.basePath}/${id}`);
  }

  async create(data) {
    return apiRequest(this.basePath, {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  async update(id, data) {
    return apiRequest(`${this.basePath}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data)
    });
  }

  async delete(id) {
    return apiRequest(`${this.basePath}/${id}`, {
      method: 'DELETE'
    });
  }

  async filter(query = {}, options = null) {
    // Advanced filtering with sorting and pagination
    const searchParams = new URLSearchParams(query);

    if (options) {
      if (options.order) {
        searchParams.set('sort', JSON.stringify(options.order));
      }
      if (options.limit) {
        searchParams.set('limit', options.limit.toString());
      }
      if (options.offset) {
        searchParams.set('offset', options.offset.toString());
      }
    }

    const queryString = searchParams.toString();
    const endpoint = queryString ? `${this.basePath}?${queryString}` : this.basePath;
    return apiRequest(endpoint);
  }
}
```

### Available Entities

```javascript
// Entity instances
export const User = new EntityAPI('user');
export const Game = new EntityAPI('game');
export const Course = new EntityAPI('course');
export const Workshop = new EntityAPI('workshop');
export const Settings = new EntityAPI('settings');
export const Category = new EntityAPI('category');
export const File = new EntityAPI('file');
export const Purchase = new EntityAPI('purchase');
export const SubscriptionPlan = new EntityAPI('subscriptionplan');
export const Classroom = new EntityAPI('classroom');
export const School = new EntityAPI('school');
export const Coupon = new EntityAPI('coupon');
export const Transaction = new EntityAPI('transaction');
// ... and more
```

## Authentication Integration

### Firebase Authentication

The application integrates with Firebase Auth for user authentication:

```javascript
// Firebase auth integration
async function loginWithFirebaseAuth() {
  try {
    const { initializeApp } = await import('firebase/app');
    const { getAuth, signInWithRedirect, GoogleAuthProvider, getRedirectResult } = await import('firebase/auth');

    const firebaseConfig = {
      apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
      authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
      // ... other config
    };

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
```

### Token Management

```javascript
// Store authentication token in memory
let authToken = null;

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

// Initialize auth token from localStorage on app start
if (typeof localStorage !== 'undefined') {
  authToken = localStorage.getItem('authToken');
}
```

## Admin-Only API Integration

### Coupon Management API Pattern

The coupon management system uses a simplified API integration pattern that bypasses the EntityAPI for direct fetch calls with proper authentication:

```javascript
// Direct API integration pattern used in coupon components
import { getApiBase } from '@/utils/api';

// Get all coupons (admin only)
const loadCoupons = async () => {
  try {
    const response = await fetch(`${getApiBase()}/entities/coupon`, {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error('Failed to fetch coupons');
    }

    const coupons = await response.json();
    return coupons;
  } catch (error) {
    cerror('Error loading coupons:', error);
    throw error;
  }
};

// Create new coupon
const createCoupon = async (couponData) => {
  const response = await fetch(`${getApiBase()}/entities/coupon`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(couponData)
  });

  if (!response.ok) {
    throw new Error('Failed to create coupon');
  }

  return response.json();
};

// Update existing coupon
const updateCoupon = async (id, updates) => {
  const response = await fetch(`${getApiBase()}/entities/coupon/${id}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(updates)
  });

  return response.json();
};
```

### Admin Authentication Pattern

```javascript
// Admin route protection using UserContext
import { useUser } from '@/contexts/UserContext';
import { isStaff } from '@/lib/userUtils';

// Component-level admin check (handled by AdminRoute wrapper)
export default function CouponComponent() {
  const { currentUser, isLoading } = useUser();

  // No manual admin checking - AdminRoute handles this
  // Components focus on functionality only

  if (isLoading) {
    return <LoadingSpinner />;
  }

  // Component logic...
}

// Route-level protection in App.jsx
<Route path='/coupons/*' element={
  <AdminRoute>
    <CouponComponent />
  </AdminRoute>
} />
```

### Error Handling with Hebrew Messages

```javascript
import { toast } from '@/components/ui/use-toast';
import { clog, cerror } from '@/lib/utils';

// Bilingual error handling pattern
const handleCouponOperation = async (operation) => {
  try {
    const result = await operation();

    // Success message in Hebrew for users
    toast({
      title: "פעולה הושלמה בהצלחה",
      description: "הקופון עודכן במערכת",
      variant: "default"
    });

    return result;
  } catch (error) {
    // Technical details for developers (English)
    cerror('Coupon operation failed:', error);

    // User-friendly message in Hebrew
    toast({
      title: "שגיאה בפעולה",
      description: "לא ניתן לבצע את הפעולה. אנא נסה שוב.",
      variant: "destructive"
    });

    throw error;
  }
};
```

### Analytics Data Integration

```javascript
// Combine multiple data sources for analytics
const loadAnalyticsData = async () => {
  try {
    const [couponsResponse, transactionsResponse, purchasesResponse] = await Promise.all([
      // Get all coupons for basic metrics
      fetch(`${getApiBase()}/entities/coupon`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      }),

      // Get transaction data for usage analytics
      fetch(`${getApiBase()}/entities/transaction`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      }).catch(() => null), // Optional - may not exist in all setups

      // Get purchase data with coupon metadata
      fetch(`${getApiBase()}/entities/purchase`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      })
    ]);

    const coupons = await couponsResponse.json();
    const transactions = transactionsResponse ? await transactionsResponse.json() : [];
    const purchases = await purchasesResponse.json();

    // Calculate analytics from combined data
    return calculateCouponAnalytics(coupons, transactions, purchases);
  } catch (error) {
    cerror('Error loading analytics data:', error);
    throw error;
  }
};
```

## Data Fetching Patterns

### Custom Hooks for Data Fetching

```javascript
// /src/hooks/useEntityData.js
import { useState, useEffect, useCallback } from 'react';

export function useEntityData(EntityAPI, filters = {}, options = {}) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const result = await EntityAPI.filter(filters, options);
      setData(result);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching data:', err);
    } finally {
      setLoading(false);
    }
  }, [EntityAPI, JSON.stringify(filters), JSON.stringify(options)]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const refetch = () => {
    fetchData();
  };

  return { data, loading, error, refetch };
}

// Usage example
export default function UserList() {
  const { data: users, loading, error, refetch } = useEntityData(User,
    { active: true },
    { order: [['created_at', 'DESC']], limit: 50 }
  );

  if (loading) return <div>Loading users...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      <button onClick={refetch}>Refresh</button>
      {users.map(user => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  );
}
```

### Pagination Hook

```javascript
// /src/hooks/usePagination.js
export function usePagination(EntityAPI, filters = {}, pageSize = 20) {
  const [currentPage, setCurrentPage] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchPage = useCallback(async (page) => {
    setLoading(true);
    try {
      const offset = (page - 1) * pageSize;
      const result = await EntityAPI.filter(filters, {
        limit: pageSize,
        offset
      });

      setData(result.data || result);
      setTotalCount(result.total || result.length);
      setCurrentPage(page);
    } catch (error) {
      console.error('Pagination error:', error);
    } finally {
      setLoading(false);
    }
  }, [EntityAPI, filters, pageSize]);

  useEffect(() => {
    fetchPage(1);
  }, [fetchPage]);

  const totalPages = Math.ceil(totalCount / pageSize);
  const hasNextPage = currentPage < totalPages;
  const hasPrevPage = currentPage > 1;

  return {
    data,
    loading,
    currentPage,
    totalPages,
    totalCount,
    hasNextPage,
    hasPrevPage,
    nextPage: () => hasNextPage && fetchPage(currentPage + 1),
    prevPage: () => hasPrevPage && fetchPage(currentPage - 1),
    goToPage: fetchPage
  };
}
```

### Retry Logic Implementation

```javascript
// /src/hooks/useRetryableRequest.js
export function useRetryableRequest(requestFn, maxRetries = 3, delay = 1000) {
  const [isRetrying, setIsRetrying] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  const executeWithRetry = useCallback(async (...args) => {
    let lastError;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          setIsRetrying(true);
          setRetryCount(attempt);
          await new Promise(resolve => setTimeout(resolve, delay * attempt));
        }

        const result = await requestFn(...args);
        setIsRetrying(false);
        setRetryCount(0);
        return result;
      } catch (error) {
        lastError = error;

        // Don't retry on 4xx errors (client errors)
        if (error.response?.status >= 400 && error.response?.status < 500) {
          break;
        }
      }
    }

    setIsRetrying(false);
    setRetryCount(0);
    throw lastError;
  }, [requestFn, maxRetries, delay]);

  return { executeWithRetry, isRetrying, retryCount };
}

// Example usage in Dashboard component
const loadSubscriptionPlanWithRetry = useCallback(async (planId, retries = 2, delay = 1000) => {
  for (let i = 0; i < retries; i++) {
    try {
      return await SubscriptionPlan.filter({ id: planId });
    } catch (error) {
      if (error.response?.status === 429 && i < retries - 1) {
        console.log(`Rate limit hit, retrying in ${delay}ms... (${i + 1}/${retries})`);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay *= 2;
      } else {
        throw error;
      }
    }
  }
}, []);
```

## File Upload Integration

### File Upload Service

```javascript
// File upload with progress tracking
export const Core = {
  UploadFile: async (data) => {
    const formData = new FormData();

    if (data.file) {
      formData.append('file', data.file);
    }

    Object.keys(data).forEach(key => {
      if (key !== 'file') {
        formData.append(key, data[key]);
      }
    });

    return apiRequest('/integrations/uploadFile', {
      method: 'POST',
      body: formData,
      headers: {} // Remove Content-Type to let browser set multipart boundary
    });
  },

  UploadPrivateFile: async (data) => {
    const formData = new FormData();

    if (data.file) {
      formData.append('file', data.file);
    }

    Object.keys(data).forEach(key => {
      if (key !== 'file') {
        formData.append(key, data[key]);
      }
    });

    return apiRequest('/integrations/uploadPrivateFile', {
      method: 'POST',
      body: formData,
      headers: {}
    });
  }
};
```

### File Upload Hook

```javascript
// /src/hooks/useFileUpload.js
export function useFileUpload() {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState(null);

  const uploadFile = useCallback(async (file, options = {}) => {
    setUploading(true);
    setError(null);
    setProgress(0);

    try {
      const uploadData = {
        file,
        ...options
      };

      const result = await Core.UploadFile(uploadData);
      setProgress(100);
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setUploading(false);
    }
  }, []);

  return {
    uploadFile,
    uploading,
    progress,
    error
  };
}
```

## Real-time Features

### WebSocket Integration Pattern

```javascript
// /src/hooks/useWebSocket.js
export function useWebSocket(url, options = {}) {
  const [socket, setSocket] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('Disconnected');
  const [lastMessage, setLastMessage] = useState(null);

  useEffect(() => {
    const ws = new WebSocket(url);

    ws.onopen = () => {
      setConnectionStatus('Connected');
      setSocket(ws);
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      setLastMessage(data);
      options.onMessage?.(data);
    };

    ws.onclose = () => {
      setConnectionStatus('Disconnected');
      setSocket(null);
    };

    ws.onerror = (error) => {
      setConnectionStatus('Error');
      options.onError?.(error);
    };

    return () => {
      ws.close();
    };
  }, [url]);

  const sendMessage = useCallback((message) => {
    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify(message));
    }
  }, [socket]);

  return {
    socket,
    connectionStatus,
    lastMessage,
    sendMessage
  };
}
```

## Error Handling

### API Error Handling

```javascript
// Enhanced error handling in apiRequest
export async function apiRequest(endpoint, options = {}) {
  try {
    const response = await fetch(url, { ...defaultOptions, ...options });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));

      // Log validation details if available
      if (error.details && Array.isArray(error.details)) {
        console.error('Validation Details:', error.details);
      }

      const errorMessage = typeof error.error === 'string' ? error.error :
                        error.message ||
                        JSON.stringify(error) ||
                        `API request failed: ${response.status}`;

      const apiError = new Error(errorMessage);
      apiError.status = response.status;
      apiError.response = error;
      throw apiError;
    }

    return await response.json();
  } catch (error) {
    console.error('API Request Failed:', error);
    throw error;
  }
}
```

### Error Recovery Patterns

```javascript
// /src/hooks/useErrorRecovery.js
export function useErrorRecovery() {
  const [error, setError] = useState(null);
  const [isRecovering, setIsRecovering] = useState(false);

  const handleError = useCallback((error, recoveryFn) => {
    setError({
      message: error.message,
      canRecover: typeof recoveryFn === 'function',
      recoveryFn
    });
  }, []);

  const recover = useCallback(async () => {
    if (error?.recoveryFn) {
      setIsRecovering(true);
      try {
        await error.recoveryFn();
        setError(null);
      } catch (recoveryError) {
        console.error('Recovery failed:', recoveryError);
      } finally {
        setIsRecovering(false);
      }
    }
  }, [error]);

  const clearError = () => setError(null);

  return {
    error,
    isRecovering,
    handleError,
    recover,
    clearError
  };
}
```

## Best Practices

### 1. API Request Optimization
- Use appropriate HTTP methods (GET, POST, PUT, DELETE)
- Implement request/response interceptors for common logic
- Add request timeouts for better UX
- Cache responses when appropriate

### 2. Error Handling
- Provide meaningful error messages to users
- Implement retry logic for transient failures
- Log errors appropriately for debugging
- Handle network connectivity issues

### 3. Security
- Always validate data on both client and server
- Use HTTPS for all API requests
- Implement proper authentication token handling
- Sanitize user inputs

### 4. Performance
- Implement pagination for large datasets
- Use debouncing for search/filter inputs
- Cache frequently accessed data
- Minimize API calls with proper state management

### 5. Testing
- Mock API calls in tests
- Test error scenarios and edge cases
- Validate request/response formats
- Test authentication flows

This API integration architecture provides a robust, scalable foundation for the Ludora application's data layer while maintaining good separation of concerns and developer experience.
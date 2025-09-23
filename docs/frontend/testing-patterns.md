# Testing Patterns

This document covers testing strategies, patterns, and best practices used in the Ludora frontend application.

## Testing Stack

Ludora uses a modern testing setup built on:

- **Vitest** - Fast unit test runner
- **Testing Library** - User-focused testing utilities
- **jsdom** - DOM simulation for Node.js
- **MSW** - API mocking
- **@testing-library/jest-dom** - Custom DOM matchers

## Test Configuration

### Vitest Setup

```javascript
// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.js'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test-setup.js',
      ],
    },
  },
});
```

### Test Setup File

```javascript
// /src/test-setup.js
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

// Cleanup after each test case
afterEach(() => {
  cleanup();
});

// Mock environment variables
vi.mock('import.meta', () => ({
  env: {
    VITE_API_BASE: 'http://localhost:3003/api',
    VITE_FIREBASE_API_KEY: 'mock-api-key',
    VITE_FIREBASE_AUTH_DOMAIN: 'mock-domain.firebaseapp.com',
    VITE_FIREBASE_PROJECT_ID: 'mock-project',
  }
}));

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn(() => ({
  disconnect: vi.fn(),
  observe: vi.fn(),
  unobserve: vi.fn(),
}));

// Mock ResizeObserver
global.ResizeObserver = vi.fn(() => ({
  disconnect: vi.fn(),
  observe: vi.fn(),
  unobserve: vi.fn(),
}));
```

## Component Testing Patterns

### Basic Component Test

```jsx
// /src/components/ui/__tests__/Button.test.jsx
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { Button } from '../Button';

describe('Button', () => {
  it('renders button with text', () => {
    render(<Button>Click me</Button>);

    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('applies variant classes correctly', () => {
    render(<Button variant="destructive">Delete</Button>);

    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-destructive');
  });

  it('disables button when disabled prop is true', () => {
    render(<Button disabled>Disabled</Button>);

    const button = screen.getByRole('button');
    expect(button).toBeDisabled();
    expect(button).toHaveClass('disabled:opacity-50');
  });

  it('renders as different element when asChild is true', () => {
    render(
      <Button asChild>
        <a href="/test">Link Button</a>
      </Button>
    );

    const link = screen.getByRole('link');
    expect(link).toHaveAttribute('href', '/test');
    expect(link).toHaveClass('inline-flex'); // Button classes applied to link
  });
});
```

### Testing Custom Hooks

```jsx
// /src/hooks/__tests__/useIsMobile.test.js
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { useIsMobile } from '../use-mobile';

describe('useIsMobile', () => {
  let mockMatchMedia;

  beforeEach(() => {
    mockMatchMedia = vi.fn();
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: mockMatchMedia,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns false for desktop width', () => {
    const mockMQL = {
      matches: false,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    };
    mockMatchMedia.mockReturnValue(mockMQL);
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 1024,
    });

    const { result } = renderHook(() => useIsMobile());

    expect(result.current).toBe(false);
  });

  it('returns true for mobile width', () => {
    const mockMQL = {
      matches: true,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    };
    mockMatchMedia.mockReturnValue(mockMQL);
    Object.defineProperty(window, 'innerWidth', {
      writable: true,
      value: 375,
    });

    const { result } = renderHook(() => useIsMobile());

    expect(result.current).toBe(true);
  });

  it('updates when screen size changes', () => {
    const mockMQL = {
      matches: false,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    };
    mockMatchMedia.mockReturnValue(mockMQL);

    const { result } = renderHook(() => useIsMobile());

    // Simulate screen size change
    act(() => {
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        value: 375,
      });
      // Trigger the change event
      const changeHandler = mockMQL.addEventListener.mock.calls[0][1];
      changeHandler();
    });

    expect(result.current).toBe(true);
  });
});
```

## Context Testing

### UserContext Testing

```jsx
// /src/contexts/__tests__/UserContext.test.jsx
import { render, screen, waitFor, act } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { UserProvider, useUser } from '../UserContext';
import * as apiClient from '@/services/apiClient';

// Mock API client
vi.mock('@/services/apiClient', () => ({
  User: {
    getCurrentUser: vi.fn(),
    update: vi.fn(),
  },
  Settings: {
    find: vi.fn(),
  },
}));

// Test component that uses UserContext
function TestComponent() {
  const { currentUser, isLoading, isAuthenticated, login, logout } = useUser();

  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <div data-testid="auth-status">
        {isAuthenticated ? 'Authenticated' : 'Not authenticated'}
      </div>
      {currentUser && (
        <div data-testid="user-email">{currentUser.email}</div>
      )}
      <button onClick={() => login({ email: 'test@example.com' })}>
        Login
      </button>
      <button onClick={logout}>Logout</button>
    </div>
  );
}

describe('UserContext', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  it('provides initial loading state', async () => {
    apiClient.Settings.find.mockResolvedValue([]);
    apiClient.User.getCurrentUser.mockRejectedValue(new Error('No token'));

    render(
      <UserProvider>
        <TestComponent />
      </UserProvider>
    );

    expect(screen.getByText('Loading...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByTestId('auth-status')).toHaveTextContent('Not authenticated');
    });
  });

  it('loads user when valid token exists', async () => {
    const mockUser = { id: '1', email: 'test@example.com' };

    localStorage.setItem('authToken', 'valid-token');
    apiClient.Settings.find.mockResolvedValue([]);
    apiClient.User.getCurrentUser.mockResolvedValue(mockUser);

    render(
      <UserProvider>
        <TestComponent />
      </UserProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('auth-status')).toHaveTextContent('Authenticated');
      expect(screen.getByTestId('user-email')).toHaveTextContent('test@example.com');
    });
  });

  it('handles login correctly', async () => {
    apiClient.Settings.find.mockResolvedValue([]);
    apiClient.User.getCurrentUser.mockRejectedValue(new Error('No token'));

    render(
      <UserProvider>
        <TestComponent />
      </UserProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('auth-status')).toHaveTextContent('Not authenticated');
    });

    // Simulate login
    act(() => {
      screen.getByText('Login').click();
    });

    await waitFor(() => {
      expect(screen.getByTestId('auth-status')).toHaveTextContent('Authenticated');
    });
  });

  it('handles logout correctly', async () => {
    const mockUser = { id: '1', email: 'test@example.com' };

    localStorage.setItem('authToken', 'valid-token');
    apiClient.Settings.find.mockResolvedValue([]);
    apiClient.User.getCurrentUser.mockResolvedValue(mockUser);

    render(
      <UserProvider>
        <TestComponent />
      </UserProvider>
    );

    await waitFor(() => {
      expect(screen.getByTestId('auth-status')).toHaveTextContent('Authenticated');
    });

    // Simulate logout
    act(() => {
      screen.getByText('Logout').click();
    });

    await waitFor(() => {
      expect(screen.getByTestId('auth-status')).toHaveTextContent('Not authenticated');
      expect(localStorage.getItem('authToken')).toBeNull();
    });
  });
});
```

## Form Testing

### React Hook Form Testing

```jsx
// /src/components/__tests__/ContactForm.test.jsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import ContactForm from '../ContactForm';

describe('ContactForm', () => {
  it('renders form fields', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
  });

  it('shows validation errors for invalid input', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    // Try to submit without filling required fields
    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(screen.getByText(/name must be at least 2 characters/i)).toBeInTheDocument();
      expect(screen.getByText(/please enter a valid email address/i)).toBeInTheDocument();
    });
  });

  it('submits form with valid data', async () => {
    const user = userEvent.setup();
    const mockSubmit = vi.fn().mockResolvedValue({});

    render(<ContactForm onSubmit={mockSubmit} />);

    // Fill in form
    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');

    // Submit form
    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        name: 'John Doe',
        email: 'john@example.com',
      });
    });
  });

  it('handles submission errors', async () => {
    const user = userEvent.setup();
    const mockSubmit = vi.fn().mockRejectedValue(new Error('Server error'));

    render(<ContactForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalled();
      // Should show error message or handle error state
    });
  });

  it('disables submit button during submission', async () => {
    const user = userEvent.setup();
    const mockSubmit = vi.fn(() => new Promise(resolve => setTimeout(resolve, 100)));

    render(<ContactForm onSubmit={mockSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');

    const submitButton = screen.getByRole('button', { name: /submit/i });
    await user.click(submitButton);

    expect(submitButton).toBeDisabled();
    expect(screen.getByText(/submitting/i)).toBeInTheDocument();
  });
});
```

## API Integration Testing

### MSW Setup for API Mocking

```javascript
// /src/__tests__/mocks/handlers.js
import { rest } from 'msw';

export const handlers = [
  // Auth endpoints
  rest.post('/api/auth/login', (req, res, ctx) => {
    return res(
      ctx.json({
        token: 'mock-jwt-token',
        user: {
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
        }
      })
    );
  }),

  rest.get('/api/auth/me', (req, res, ctx) => {
    const authHeader = req.headers.get('authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res(ctx.status(401), ctx.json({ error: 'Unauthorized' }));
    }

    return res(
      ctx.json({
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
      })
    );
  }),

  // Users endpoints
  rest.get('/api/entities/user', (req, res, ctx) => {
    return res(
      ctx.json([
        { id: '1', email: 'user1@example.com', name: 'User 1' },
        { id: '2', email: 'user2@example.com', name: 'User 2' },
      ])
    );
  }),

  rest.post('/api/entities/user', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        id: '3',
        ...req.body,
      })
    );
  }),

  // Error handling
  rest.get('/api/entities/error-test', (req, res, ctx) => {
    return res(
      ctx.status(500),
      ctx.json({ error: 'Internal server error' })
    );
  }),
];
```

```javascript
// /src/__tests__/mocks/server.js
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

### API Hook Testing

```jsx
// /src/hooks/__tests__/useUsers.test.js
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, beforeAll, afterEach, afterAll } from 'vitest';
import { server } from '../__tests__/mocks/server';
import { useUsers } from '../useUsers';

describe('useUsers', () => {
  beforeAll(() => server.listen());
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());

  it('fetches users successfully', async () => {
    const { result } = renderHook(() => useUsers());

    expect(result.current.loading).toBe(true);
    expect(result.current.users).toEqual([]);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.users).toEqual([
      { id: '1', email: 'user1@example.com', name: 'User 1' },
      { id: '2', email: 'user2@example.com', name: 'User 2' },
    ]);
    expect(result.current.error).toBeNull();
  });

  it('handles API errors', async () => {
    // Override the handler to return an error
    server.use(
      rest.get('/api/entities/user', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server error' }));
      })
    );

    const { result } = renderHook(() => useUsers());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.users).toEqual([]);
    expect(result.current.error).toBeTruthy();
  });

  it('refetches data when refetch is called', async () => {
    const { result } = renderHook(() => useUsers());

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.users).toHaveLength(2);

    // Mock additional user for refetch
    server.use(
      rest.get('/api/entities/user', (req, res, ctx) => {
        return res(
          ctx.json([
            { id: '1', email: 'user1@example.com', name: 'User 1' },
            { id: '2', email: 'user2@example.com', name: 'User 2' },
            { id: '3', email: 'user3@example.com', name: 'User 3' },
          ])
        );
      })
    );

    act(() => {
      result.current.refetch();
    });

    await waitFor(() => {
      expect(result.current.users).toHaveLength(3);
    });
  });
});
```

## Integration Testing

### Page Component Testing

```jsx
// /src/pages/__tests__/Dashboard.test.jsx
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect, vi, beforeAll, afterEach, afterAll } from 'vitest';
import { server } from '../../__tests__/mocks/server';
import { UserProvider } from '@/contexts/UserContext';
import Dashboard from '../Dashboard';

// Mock components that might have complex dependencies
vi.mock('@/components/TutorialOverlay', () => ({
  default: () => <div data-testid="tutorial-overlay" />,
}));

function renderDashboard(initialUser = null) {
  return render(
    <MemoryRouter>
      <UserProvider>
        <Dashboard />
      </UserProvider>
    </MemoryRouter>
  );
}

describe('Dashboard', () => {
  beforeAll(() => server.listen());
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());

  it('shows loading state initially', () => {
    renderDashboard();

    expect(screen.getByText(/loading dashboard/i)).toBeInTheDocument();
  });

  it('displays user information when loaded', async () => {
    // Set up authenticated state
    localStorage.setItem('authToken', 'valid-token');

    renderDashboard();

    await waitFor(() => {
      expect(screen.getByText(/hello, test user/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/dashboard under development/i)).toBeInTheDocument();
  });

  it('shows development message', async () => {
    localStorage.setItem('authToken', 'valid-token');

    renderDashboard();

    await waitFor(() => {
      expect(screen.getByText(/dashboard under development/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/we're working hard/i)).toBeInTheDocument();
  });
});
```

## Accessibility Testing

### Testing ARIA attributes and keyboard navigation

```jsx
// /src/components/__tests__/Modal.test.jsx
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import Modal from '../Modal';

describe('Modal Accessibility', () => {
  it('has proper ARIA attributes', () => {
    render(
      <Modal isOpen={true} onClose={vi.fn()}>
        <h2>Modal Title</h2>
        <p>Modal content</p>
      </Modal>
    );

    const modal = screen.getByRole('dialog');
    expect(modal).toHaveAttribute('aria-modal', 'true');
    expect(modal).toHaveAttribute('aria-labelledby');
  });

  it('traps focus within modal', async () => {
    const user = userEvent.setup();

    render(
      <div>
        <button>Outside button</button>
        <Modal isOpen={true} onClose={vi.fn()}>
          <h2>Modal Title</h2>
          <button>Modal button 1</button>
          <button>Modal button 2</button>
        </Modal>
      </div>
    );

    const modalButton1 = screen.getByText('Modal button 1');
    const modalButton2 = screen.getByText('Modal button 2');
    const closeButton = screen.getByLabelText(/close/i);

    // Focus should be trapped within modal
    modalButton1.focus();
    expect(modalButton1).toHaveFocus();

    await user.tab();
    expect(modalButton2).toHaveFocus();

    await user.tab();
    expect(closeButton).toHaveFocus();

    // Should wrap back to first focusable element
    await user.tab();
    expect(modalButton1).toHaveFocus();
  });

  it('closes on Escape key press', async () => {
    const user = userEvent.setup();
    const onClose = vi.fn();

    render(
      <Modal isOpen={true} onClose={onClose}>
        <h2>Modal Title</h2>
      </Modal>
    );

    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalled();
  });

  it('returns focus to trigger element when closed', async () => {
    const user = userEvent.setup();
    let isOpen = true;
    const toggleModal = () => { isOpen = !isOpen; };

    const { rerender } = render(
      <div>
        <button onClick={toggleModal}>Open Modal</button>
        {isOpen && (
          <Modal isOpen={isOpen} onClose={toggleModal}>
            <h2>Modal Title</h2>
            <button onClick={toggleModal}>Close</button>
          </Modal>
        )}
      </div>
    );

    const openButton = screen.getByText('Open Modal');
    openButton.focus();

    await user.click(openButton);

    // Modal is now open, close it
    const closeButton = screen.getByText('Close');
    await user.click(closeButton);

    // Re-render without modal
    rerender(
      <div>
        <button onClick={toggleModal}>Open Modal</button>
      </div>
    );

    // Focus should return to the open button
    expect(openButton).toHaveFocus();
  });
});
```

## Performance Testing

### Testing component performance

```jsx
// /src/components/__tests__/ExpensiveComponent.test.jsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import ExpensiveComponent from '../ExpensiveComponent';

describe('ExpensiveComponent Performance', () => {
  it('does not re-render unnecessarily', () => {
    const expensiveCalculation = vi.fn(() => 'result');

    const { rerender } = render(
      <ExpensiveComponent
        data={[1, 2, 3]}
        onCalculate={expensiveCalculation}
      />
    );

    expect(expensiveCalculation).toHaveBeenCalledTimes(1);

    // Re-render with same props
    rerender(
      <ExpensiveComponent
        data={[1, 2, 3]}
        onCalculate={expensiveCalculation}
      />
    );

    // Should not call expensive calculation again
    expect(expensiveCalculation).toHaveBeenCalledTimes(1);

    // Re-render with different props
    rerender(
      <ExpensiveComponent
        data={[1, 2, 3, 4]}
        onCalculate={expensiveCalculation}
      />
    );

    // Should call expensive calculation again
    expect(expensiveCalculation).toHaveBeenCalledTimes(2);
  });
});
```

## Test Utilities

### Custom Test Utilities

```jsx
// /src/__tests__/test-utils.jsx
import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { UserProvider } from '@/contexts/UserContext';

// Custom render function that includes providers
export function renderWithProviders(ui, options = {}) {
  const {
    initialEntries = ['/'],
    user = null,
    ...renderOptions
  } = options;

  function Wrapper({ children }) {
    return (
      <MemoryRouter initialEntries={initialEntries}>
        <UserProvider initialUser={user}>
          {children}
        </UserProvider>
      </MemoryRouter>
    );
  }

  return render(ui, { wrapper: Wrapper, ...renderOptions });
}

// Custom matchers
export const customMatchers = {
  toHaveLoadingState: (received) => {
    const hasSpinner = received.querySelector('.animate-spin');
    const hasLoadingText = received.textContent.includes('Loading') ||
                          received.textContent.includes('טוען');

    return {
      message: () => `Expected element to have loading state`,
      pass: hasSpinner || hasLoadingText,
    };
  },
};

// Re-export everything from testing-library
export * from '@testing-library/react';
export { renderWithProviders as render };
```

## Best Practices

### 1. Test Structure
- Follow AAA pattern (Arrange, Act, Assert)
- Use descriptive test names
- Group related tests with `describe` blocks
- Keep tests focused and atomic

### 2. Mocking Strategy
- Mock external dependencies
- Use MSW for API mocking
- Mock complex components in integration tests
- Avoid mocking implementation details

### 3. User-Centric Testing
- Test user interactions, not implementation
- Use `screen.getByRole()` and semantic queries
- Test accessibility features
- Focus on user workflows

### 4. Performance
- Keep tests fast and isolated
- Use `beforeEach` and `afterEach` for cleanup
- Mock heavy operations
- Run tests in parallel when possible

### 5. Coverage Goals
- Aim for high test coverage (80%+)
- Focus on critical user paths
- Test error scenarios
- Include edge cases

This testing approach ensures robust, maintainable tests that provide confidence in the Ludora application's functionality and user experience.
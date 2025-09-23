# Established Code Patterns

This document outlines the established code patterns, conventions, and architectural decisions that AI assistants must follow when working on the Ludora platform.

## Backend Patterns

### API Endpoint Patterns

#### Generic Entity CRUD
All entities follow a consistent CRUD pattern:

```javascript
// Generic entity routes (/api/entities/:type)
router.get('/:type', async (req, res) => {
  // List entities with filtering, pagination, sorting
});

router.post('/:type', async (req, res) => {
  // Create new entity with validation
});

router.get('/:type/:id', async (req, res) => {
  // Get single entity with access control
});

router.put('/:type/:id', async (req, res) => {
  // Update entity with ownership/permission checks
});

router.delete('/:type/:id', async (req, res) => {
  // Delete entity with cascade handling
});
```

**Key Principles:**
- Always validate entity type against allowed types
- Implement consistent access control patterns
- Use structured error responses
- Support filtering, sorting, and pagination
- Handle cascade deletions properly

#### Authentication Middleware Pattern
```javascript
// Standard authentication chain
const authMiddleware = [
  requireAuth,           // JWT validation
  validateUserExists,    // User record exists
  checkUserPermissions   // Role-based access
];

// Usage in routes
router.post('/admin-endpoint',
  ...authMiddleware,
  requireRole('admin'),
  handler
);
```

#### Error Response Pattern
```javascript
// Consistent error structure
const sendError = (res, statusCode, message, details = null) => {
  res.status(statusCode).json({
    success: false,
    error: {
      message,
      details,
      timestamp: new Date().toISOString(),
      statusCode
    }
  });
};

// Usage
if (!user) {
  return sendError(res, 404, 'User not found', { userId });
}
```

### Database Patterns

#### Sequelize Model Pattern
```javascript
// Standard model definition
const Model = sequelize.define('ModelName', {
  id: {
    type: DataTypes.STRING,
    primaryKey: true,
    defaultValue: () => generateId()
  },
  // ... other fields
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'model_name',
  timestamps: true,
  underscored: true
});
```

#### JSONB Usage Pattern
```javascript
// Game settings with JSONB
const game = await Game.findOne({
  where: {
    id: gameId,
    game_type: 'memory_game',
    // Query JSONB fields
    [Op.and]: [
      sequelize.where(
        sequelize.cast(sequelize.json('game_settings.pairs_count'), 'integer'),
        '>=', minPairs
      )
    ]
  }
});

// Update JSONB fields
await game.update({
  game_settings: {
    ...game.game_settings,
    pairs_count: newPairCount
  }
});
```

#### Migration Pattern
```javascript
// Standard migration structure
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('table_name', {
      id: {
        type: Sequelize.STRING,
        primaryKey: true
      },
      // ... fields
      created_at: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW
      },
      updated_at: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW
      }
    });

    // Add indexes
    await queryInterface.addIndex('table_name', ['frequently_queried_field']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('table_name');
  }
};
```

### Service Layer Pattern
```javascript
// Business logic in services
class GameService {
  static async createGame(gameData, creatorId) {
    // Validation
    const validation = await this.validateGameData(gameData);
    if (!validation.isValid) {
      throw new ValidationError(validation.errors);
    }

    // Business logic
    const game = await Game.create({
      ...gameData,
      creator_user_id: creatorId,
      id: generateId()
    });

    // Side effects
    await this.initializeGameSettings(game);

    return game;
  }

  static async validateGameData(data) {
    // Use Joi for validation
    const schema = Joi.object({
      title: Joi.string().required(),
      game_type: Joi.string().valid(...GAME_TYPES).required()
    });

    try {
      await schema.validateAsync(data);
      return { isValid: true };
    } catch (error) {
      return { isValid: false, errors: error.details };
    }
  }
}
```

## Frontend Patterns

### Component Structure Pattern
```jsx
// Standard functional component pattern
import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { useUser } from '@/contexts/UserContext';

export const ComponentName = ({
  prop1,
  prop2,
  onAction,
  className = ''
}) => {
  // Hooks first
  const { user } = useUser();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Effects
  useEffect(() => {
    // Side effects
  }, [dependencies]);

  // Event handlers
  const handleAction = async () => {
    setLoading(true);
    setError(null);

    try {
      await onAction();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Early returns for loading/error states
  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error} />;

  // Main render
  return (
    <div className={`component-base-styles ${className}`}>
      {/* Component content */}
    </div>
  );
};
```

### Service Integration Pattern
```jsx
// API service usage
import { gameService } from '@/services/gameService';

const GameComponent = () => {
  const [games, setGames] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchGames = async () => {
      try {
        const gamesData = await gameService.getAll({
          filters: { published: true },
          sort: 'created_at',
          order: 'desc'
        });
        setGames(gamesData);
      } catch (error) {
        console.error('Failed to fetch games:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchGames();
  }, []);

  // ... rest of component
};
```

### Form Handling Pattern
```jsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// Validation schema
const gameSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  game_type: z.enum(['memory_game', 'scatter_game'])
});

const GameForm = ({ onSubmit, initialData = {} }) => {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset
  } = useForm({
    resolver: zodResolver(gameSchema),
    defaultValues: initialData
  });

  const onFormSubmit = async (data) => {
    try {
      await onSubmit(data);
      reset();
    } catch (error) {
      // Handle submission error
    }
  };

  return (
    <form onSubmit={handleSubmit(onFormSubmit)} className="space-y-4">
      <div>
        <label htmlFor="title">Title</label>
        <input
          {...register('title')}
          className="form-input"
        />
        {errors.title && (
          <p className="text-red-500 text-sm">{errors.title.message}</p>
        )}
      </div>

      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Saving...' : 'Save'}
      </Button>
    </form>
  );
};
```

### Context Usage Pattern
```jsx
// Context provider pattern
import React, { createContext, useContext, useState, useEffect } from 'react';

const UserContext = createContext();

export const UserProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Initialize user data
    const initUser = async () => {
      try {
        const userData = await authService.getCurrentUser();
        setUser(userData);
      } catch (error) {
        console.error('Failed to load user:', error);
      } finally {
        setLoading(false);
      }
    };

    initUser();
  }, []);

  const login = async (credentials) => {
    const userData = await authService.login(credentials);
    setUser(userData);
    return userData;
  };

  const logout = async () => {
    await authService.logout();
    setUser(null);
  };

  const value = {
    user,
    loading,
    login,
    logout,
    isAuthenticated: !!user
  };

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
};

// Hook for consuming context
export const useUser = () => {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within UserProvider');
  }
  return context;
};
```

## Styling Patterns

### Tailwind CSS Usage
```jsx
// Consistent class patterns
const Button = ({ variant = 'primary', size = 'md', children, ...props }) => {
  const baseClasses = 'font-medium rounded-lg transition-colors focus:outline-none focus:ring-2';

  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
    destructive: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500'
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg'
  };

  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]}`}
      {...props}
    >
      {children}
    </button>
  );
};
```

### RTL (Hebrew) Support Pattern
```jsx
// RTL-aware layouts
const Card = ({ children }) => (
  <div className="bg-white rounded-lg shadow p-4 rtl:text-right ltr:text-left">
    {children}
  </div>
);

// Direction-aware spacing
const Navigation = () => (
  <nav className="flex items-center space-x-4 rtl:space-x-reverse">
    {/* Navigation items */}
  </nav>
);
```

## Testing Patterns

### Backend Testing Pattern
```javascript
// API endpoint testing
const request = require('supertest');
const app = require('../index');

describe('Game API', () => {
  let authToken;
  let testUser;

  beforeEach(async () => {
    // Setup test data
    testUser = await createTestUser();
    authToken = generateTestToken(testUser);
  });

  afterEach(async () => {
    // Cleanup
    await cleanupTestData();
  });

  describe('POST /api/entities/game', () => {
    it('should create a new game with valid data', async () => {
      const gameData = {
        title: 'Test Game',
        game_type: 'memory_game'
      };

      const response = await request(app)
        .post('/api/entities/game')
        .set('Authorization', `Bearer ${authToken}`)
        .send(gameData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe(gameData.title);
    });

    it('should return 400 for invalid game type', async () => {
      const invalidData = {
        title: 'Test Game',
        game_type: 'invalid_type'
      };

      await request(app)
        .post('/api/entities/game')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidData)
        .expect(400);
    });
  });
});
```

### Frontend Testing Pattern
```jsx
// Component testing
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import { GameForm } from './GameForm';

// Mock services
vi.mock('@/services/gameService', () => ({
  gameService: {
    create: vi.fn()
  }
}));

describe('GameForm', () => {
  const mockOnSubmit = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should submit form with valid data', async () => {
    render(<GameForm onSubmit={mockOnSubmit} />);

    // Fill form
    fireEvent.change(screen.getByLabelText(/title/i), {
      target: { value: 'Test Game' }
    });

    fireEvent.change(screen.getByLabelText(/game type/i), {
      target: { value: 'memory_game' }
    });

    // Submit
    fireEvent.click(screen.getByRole('button', { name: /save/i }));

    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith({
        title: 'Test Game',
        game_type: 'memory_game'
      });
    });
  });

  it('should show validation errors for empty title', async () => {
    render(<GameForm onSubmit={mockOnSubmit} />);

    fireEvent.click(screen.getByRole('button', { name: /save/i }));

    await waitFor(() => {
      expect(screen.getByText(/title is required/i)).toBeInTheDocument();
    });

    expect(mockOnSubmit).not.toHaveBeenCalled();
  });
});
```

## Security Patterns

### Input Validation Pattern
```javascript
// Server-side validation with Joi
const validateGameInput = (data) => {
  const schema = Joi.object({
    title: Joi.string().trim().min(1).max(255).required(),
    description: Joi.string().trim().max(1000).optional(),
    game_type: Joi.string().valid(...ALLOWED_GAME_TYPES).required(),
    game_settings: Joi.object().optional()
  });

  return schema.validate(data, { abortEarly: false });
};
```

### Access Control Pattern
```javascript
// Permission checking middleware
const requireOwnership = (entityType) => {
  return async (req, res, next) => {
    try {
      const entity = await getEntityById(entityType, req.params.id);

      if (!entity) {
        return sendError(res, 404, 'Entity not found');
      }

      // Check ownership or admin permission
      if (entity.creator_user_id !== req.user.id && req.user.role !== 'admin') {
        return sendError(res, 403, 'Insufficient permissions');
      }

      req.entity = entity;
      next();
    } catch (error) {
      next(error);
    }
  };
};
```

### File Upload Security Pattern
```javascript
// Secure file upload with validation
const multerConfig = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: process.env.AWS_S3_BUCKET,
    key: (req, file, cb) => {
      const uniqueName = `${Date.now()}-${crypto.randomUUID()}-${file.originalname}`;
      cb(null, `uploads/${req.user.id}/${uniqueName}`);
    }
  }),
  fileFilter: (req, file, cb) => {
    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/png', 'video/mp4'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  },
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB
  }
});
```

## Performance Patterns

### Database Query Optimization
```javascript
// Efficient queries with proper joins
const getGameWithContent = async (gameId) => {
  return await Game.findOne({
    where: { id: gameId },
    include: [
      {
        model: GameContentUsage,
        include: [
          {
            model: ContentList,
            attributes: ['id', 'name', 'content_type']
          }
        ]
      }
    ],
    attributes: { exclude: ['sensitive_field'] }
  });
};

// Use database indexes for common queries
const findGamesByType = async (gameType, options = {}) => {
  const { limit = 20, offset = 0, sort = 'created_at' } = options;

  return await Game.findAndCountAll({
    where: {
      game_type: gameType,
      is_published: true
    },
    order: [[sort, 'DESC']],
    limit,
    offset,
    attributes: ['id', 'title', 'description', 'created_at'] // Only needed fields
  });
};
```

### Frontend Performance Pattern
```jsx
// Lazy loading and code splitting
import { lazy, Suspense } from 'react';

const GameBuilder = lazy(() => import('./GameBuilder'));

const App = () => (
  <Suspense fallback={<LoadingSpinner />}>
    <GameBuilder />
  </Suspense>
);

// Memoization for expensive computations
import { useMemo, useCallback } from 'react';

const GameList = ({ games, filters }) => {
  const filteredGames = useMemo(() => {
    return games.filter(game =>
      game.title.toLowerCase().includes(filters.search.toLowerCase()) &&
      (filters.type === 'all' || game.game_type === filters.type)
    );
  }, [games, filters]);

  const handleGameClick = useCallback((gameId) => {
    // Handle click
  }, []);

  return (
    <div>
      {filteredGames.map(game => (
        <GameCard
          key={game.id}
          game={game}
          onClick={handleGameClick}
        />
      ))}
    </div>
  );
};
```

## Error Handling Patterns

### Global Error Boundary
```jsx
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
    // Send to error reporting service
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-fallback">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => window.location.reload()}>
            Reload Page
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### API Error Handling
```javascript
// Consistent error handling
const handleApiError = (error, req, res, next) => {
  console.error('API Error:', {
    method: req.method,
    url: req.url,
    user: req.user?.id,
    error: error.message,
    stack: error.stack
  });

  if (error.name === 'ValidationError') {
    return sendError(res, 400, 'Validation failed', error.details);
  }

  if (error.name === 'SequelizeUniqueConstraintError') {
    return sendError(res, 409, 'Resource already exists');
  }

  if (error.name === 'UnauthorizedError') {
    return sendError(res, 401, 'Authentication required');
  }

  // Default error
  sendError(res, 500, 'Internal server error');
};
```

## Anti-Patterns to Avoid

### Don't Break These Rules

1. **Never hardcode configuration values**
   ```javascript
   // ❌ Wrong
   const apiUrl = 'http://localhost:3001';

   // ✅ Correct
   const apiUrl = process.env.VITE_API_URL;
   ```

2. **Don't bypass authentication middleware**
   ```javascript
   // ❌ Wrong - no auth check
   router.delete('/api/admin/users/:id', deleteUser);

   // ✅ Correct - proper auth chain
   router.delete('/api/admin/users/:id',
     requireAuth,
     requireRole('admin'),
     deleteUser
   );
   ```

3. **Don't ignore error handling**
   ```jsx
   // ❌ Wrong - no error handling
   const fetchData = async () => {
     const data = await api.getData();
     setData(data);
   };

   // ✅ Correct - proper error handling
   const fetchData = async () => {
     try {
       setLoading(true);
       const data = await api.getData();
       setData(data);
     } catch (error) {
       setError(error.message);
     } finally {
       setLoading(false);
     }
   };
   ```

4. **Don't create inconsistent API patterns**
   ```javascript
   // ❌ Wrong - inconsistent response format
   res.json({ game: gameData });

   // ✅ Correct - consistent response format
   res.json({
     success: true,
     data: gameData
   });
   ```

Following these established patterns ensures consistency, maintainability, and reliability across the Ludora platform.
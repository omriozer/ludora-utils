# Coding Standards

This document establishes the coding standards, conventions, and best practices for the Ludora platform.

## General Principles

### Code Quality Standards
1. **Readability First**: Code should be self-documenting and easy to understand
2. **Consistency**: Follow established patterns throughout the codebase
3. **Security**: Always consider security implications of code changes
4. **Performance**: Write efficient code that scales well
5. **Maintainability**: Code should be easy to modify and extend

### Documentation Requirements
- Document complex business logic with inline comments
- Update API documentation with endpoint changes
- Maintain architectural documentation for system changes
- Include examples in function documentation

## Backend Standards (Node.js)

### File and Directory Structure
```
ludora-api/
├── routes/              # API endpoint definitions
├── models/              # Database models (Sequelize)
├── services/            # Business logic services
├── middleware/          # Express middleware
├── config/              # Configuration files
├── utils/               # Utility functions
├── tests/               # Test files
└── migrations/          # Database migrations
```

### Naming Conventions

**Files and Directories:**
- Use kebab-case: `user-service.js`, `auth-middleware.js`
- Model files: PascalCase matching model name: `User.js`, `Game.js`
- Test files: `{name}.test.js` or `{name}.spec.js`

**Variables and Functions:**
```javascript
// camelCase for variables and functions
const userName = 'john_doe';
const fetchUserData = async () => {};

// PascalCase for classes and constructors
class UserService {
  constructor() {}
}

// UPPER_SNAKE_CASE for constants
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024;
const ALLOWED_FILE_TYPES = ['jpg', 'png', 'mp4'];
```

**Database:**
```sql
-- snake_case for table and column names
CREATE TABLE user_profile (
  user_id VARCHAR(255),
  profile_data JSONB
);
```

### Code Organization Patterns

#### Service Layer Pattern
```javascript
// services/gameService.js
class GameService {
  static async createGame(gameData, creatorId) {
    // Input validation
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

module.exports = GameService;
```

#### Controller Pattern
```javascript
// routes/games.js
const express = require('express');
const GameService = require('../services/GameService');
const { requireAuth, validateInput } = require('../middleware');

const router = express.Router();

router.post('/',
  requireAuth,
  validateInput(gameCreationSchema),
  async (req, res, next) => {
    try {
      const game = await GameService.createGame(req.body, req.user.id);

      res.status(201).json({
        success: true,
        data: game
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
```

#### Error Handling Pattern
```javascript
// middleware/errorHandler.js
const handleApiError = (error, req, res, next) => {
  // Log error with context
  console.error('API Error:', {
    method: req.method,
    url: req.url,
    user: req.user?.id,
    error: error.message,
    stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
  });

  // Handle specific error types
  if (error.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      error: {
        message: 'Validation failed',
        details: error.details,
        statusCode: 400
      }
    });
  }

  if (error.name === 'UnauthorizedError') {
    return res.status(401).json({
      success: false,
      error: {
        message: 'Authentication required',
        statusCode: 401
      }
    });
  }

  // Default error response
  res.status(500).json({
    success: false,
    error: {
      message: 'Internal server error',
      statusCode: 500
    }
  });
};
```

### Database Patterns

#### Model Definition
```javascript
// models/Game.js
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Game = sequelize.define('Game', {
    id: {
      type: DataTypes.STRING,
      primaryKey: true,
      defaultValue: () => generateId()
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        len: [1, 255]
      }
    },
    game_type: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        isIn: [['memory_game', 'scatter_game', 'wisdom_maze']]
      }
    },
    game_settings: {
      type: DataTypes.JSONB,
      defaultValue: {}
    },
    is_published: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    creator_user_id: {
      type: DataTypes.STRING,
      allowNull: false,
      references: {
        model: 'user',
        key: 'id'
      }
    }
  }, {
    tableName: 'game',
    timestamps: true,
    underscored: true,
    indexes: [
      { fields: ['game_type'] },
      { fields: ['is_published'] },
      { fields: ['creator_user_id'] }
    ]
  });

  // Associations
  Game.associate = (models) => {
    Game.belongsTo(models.User, {
      foreignKey: 'creator_user_id',
      as: 'creator'
    });
  };

  return Game;
};
```

#### Query Patterns
```javascript
// Efficient queries with proper includes
const getPublishedGames = async (options = {}) => {
  const { limit = 20, offset = 0, gameType } = options;

  const whereClause = {
    is_published: true
  };

  if (gameType) {
    whereClause.game_type = gameType;
  }

  return await Game.findAndCountAll({
    where: whereClause,
    include: [
      {
        model: User,
        as: 'creator',
        attributes: ['id', 'full_name'] // Only needed fields
      }
    ],
    order: [['created_at', 'DESC']],
    limit,
    offset
  });
};
```

### Security Standards

#### Input Validation
```javascript
const Joi = require('joi');

const userRegistrationSchema = Joi.object({
  email: Joi.string().email().required(),
  full_name: Joi.string().min(1).max(255).required(),
  password: Joi.string().min(8).required(),
  birth_date: Joi.date().iso().optional()
});

// Use in middleware
const validateUserRegistration = (req, res, next) => {
  const { error } = userRegistrationSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      error: {
        message: 'Validation failed',
        details: error.details
      }
    });
  }
  next();
};
```

#### Authentication Middleware
```javascript
const requireAuth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        error: { message: 'Authentication token required' }
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findByPk(decoded.userId);

    if (!user || !user.is_active) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid or inactive user' }
      });
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      error: { message: 'Invalid authentication token' }
    });
  }
};
```

## Frontend Standards (React)

### File and Directory Structure
```
src/
├── components/          # Reusable components
│   ├── ui/             # Base UI components
│   ├── auth/           # Authentication components
│   └── shared/         # Business logic components
├── pages/              # Route-level components
├── contexts/           # React Context providers
├── hooks/              # Custom React hooks
├── services/           # API communication
├── utils/              # Utility functions
└── lib/                # Library configurations
```

### Naming Conventions

**Components:**
```jsx
// PascalCase for component files and names
// GameBuilder.jsx
export const GameBuilder = ({ gameId, onSave }) => {
  // Component implementation
};

// kebab-case for non-component files
// api-client.js, date-utils.js
```

**Props and Variables:**
```jsx
// camelCase for props, variables, functions
const GameCard = ({
  gameTitle,           // camelCase
  isPublished,         // boolean with 'is' prefix
  onGameClick,         // event handlers with 'on' prefix
  gameData = {}        // default values when appropriate
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleClick = () => {
    onGameClick(gameData.id);
  };

  return (
    <div className="game-card">
      {/* Component content */}
    </div>
  );
};
```

### Component Patterns

#### Functional Component Structure
```jsx
import React, { useState, useEffect, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { useUser } from '@/contexts/UserContext';
import { gameService } from '@/services/gameService';

export const GameList = ({
  initialFilters = {},
  onGameSelect,
  className = ''
}) => {
  // 1. Hooks (state, context, custom hooks)
  const { user } = useUser();
  const [games, setGames] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState(initialFilters);

  // 2. Effects
  useEffect(() => {
    fetchGames();
  }, [filters]);

  // 3. Event handlers and functions
  const fetchGames = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await gameService.getAll({
        filters,
        sort: 'created_at',
        order: 'desc'
      });

      setGames(response.data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [filters]);

  const handleGameClick = useCallback((gameId) => {
    onGameSelect?.(gameId);
  }, [onGameSelect]);

  // 4. Early returns for loading/error states
  if (loading) {
    return <div className="animate-pulse">Loading games...</div>;
  }

  if (error) {
    return (
      <div className="text-red-600">
        Error loading games: {error}
        <Button onClick={fetchGames} variant="outline" size="sm">
          Retry
        </Button>
      </div>
    );
  }

  // 5. Main render
  return (
    <div className={`game-list ${className}`}>
      {games.length === 0 ? (
        <div className="text-gray-500">No games found</div>
      ) : (
        games.map(game => (
          <GameCard
            key={game.id}
            game={game}
            onClick={handleGameClick}
          />
        ))
      )}
    </div>
  );
};
```

#### Form Component Pattern
```jsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// Validation schema
const gameSchema = z.object({
  title: z.string().min(1, 'Title is required').max(255),
  description: z.string().optional(),
  game_type: z.enum(['memory_game', 'scatter_game', 'wisdom_maze'])
});

export const GameForm = ({
  initialData = {},
  onSubmit,
  onCancel,
  isSubmitting = false
}) => {
  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
    reset,
    watch
  } = useForm({
    resolver: zodResolver(gameSchema),
    defaultValues: initialData
  });

  const watchedGameType = watch('game_type');

  const onFormSubmit = async (data) => {
    try {
      await onSubmit(data);
      reset();
    } catch (error) {
      // Error handling is done by parent component
      console.error('Form submission error:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit(onFormSubmit)} className="space-y-6">
      <div>
        <label htmlFor="title" className="block text-sm font-medium">
          Game Title *
        </label>
        <input
          {...register('title')}
          type="text"
          className="mt-1 block w-full rounded-md border-gray-300"
          placeholder="Enter game title"
        />
        {errors.title && (
          <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="game_type" className="block text-sm font-medium">
          Game Type *
        </label>
        <select {...register('game_type')} className="mt-1 block w-full">
          <option value="">Select game type</option>
          <option value="memory_game">Memory Game</option>
          <option value="scatter_game">Scatter Game</option>
          <option value="wisdom_maze">Wisdom Maze</option>
        </select>
        {errors.game_type && (
          <p className="mt-1 text-sm text-red-600">{errors.game_type.message}</p>
        )}
      </div>

      <div className="flex justify-end space-x-3">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          disabled={isSubmitting}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          disabled={isSubmitting || !isDirty}
        >
          {isSubmitting ? 'Saving...' : 'Save Game'}
        </Button>
      </div>
    </form>
  );
};
```

#### Custom Hook Pattern
```jsx
// hooks/useApi.js
import { useState, useEffect, useCallback } from 'react';

export const useApi = (apiCall, dependencies = []) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const result = await apiCall();
      setData(result);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, dependencies);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const refetch = useCallback(() => {
    fetchData();
  }, [fetchData]);

  return {
    data,
    loading,
    error,
    refetch
  };
};

// Usage
const GameList = () => {
  const { data: games, loading, error, refetch } = useApi(
    () => gameService.getAll({ published: true }),
    []
  );

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {games?.map(game => (
        <GameCard key={game.id} game={game} />
      ))}
    </div>
  );
};
```

### Service Layer Pattern
```javascript
// services/gameService.js
import { apiClient } from './apiClient';

class GameService {
  static async getAll(options = {}) {
    const { filters = {}, sort = 'created_at', order = 'desc', limit = 20, offset = 0 } = options;

    const params = new URLSearchParams({
      sort,
      order,
      limit: limit.toString(),
      offset: offset.toString()
    });

    // Add filters to params
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        params.append(`filters[${key}]`, value.toString());
      }
    });

    const response = await apiClient.get(`/entities/game?${params}`);
    return response.data;
  }

  static async getById(id) {
    const response = await apiClient.get(`/entities/game/${id}`);
    return response.data;
  }

  static async create(gameData) {
    const response = await apiClient.post('/entities/game', gameData);
    return response.data;
  }

  static async update(id, gameData) {
    const response = await apiClient.put(`/entities/game/${id}`, gameData);
    return response.data;
  }

  static async delete(id) {
    const response = await apiClient.delete(`/entities/game/${id}`);
    return response.data;
  }
}

export { GameService as gameService };
```

### Styling Standards

#### Tailwind CSS Patterns
```jsx
// Component with consistent styling patterns
const Button = ({
  variant = 'primary',
  size = 'md',
  children,
  className = '',
  ...props
}) => {
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
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};
```

#### RTL Support Pattern
```jsx
// RTL-aware component design
const Card = ({ title, children, actions }) => (
  <div className="bg-white rounded-lg shadow-md p-6">
    <div className="flex items-center justify-between mb-4">
      <h3 className="text-lg font-medium rtl:text-right ltr:text-left">
        {title}
      </h3>
      <div className="flex items-center space-x-2 rtl:space-x-reverse">
        {actions}
      </div>
    </div>
    <div className="rtl:text-right ltr:text-left">
      {children}
    </div>
  </div>
);
```

## Testing Standards

### Backend Testing
```javascript
// tests/services/gameService.test.js
const { GameService } = require('../../services/GameService');
const { Game, User } = require('../../models');

describe('GameService', () => {
  let testUser;

  beforeEach(async () => {
    // Setup test data
    testUser = await User.create({
      id: 'test-user-1',
      email: 'test@example.com',
      full_name: 'Test User',
      role: 'teacher'
    });
  });

  afterEach(async () => {
    // Cleanup
    await Game.destroy({ where: {}, force: true });
    await User.destroy({ where: {}, force: true });
  });

  describe('createGame', () => {
    it('should create a game with valid data', async () => {
      const gameData = {
        title: 'Test Game',
        game_type: 'memory_game',
        description: 'A test game'
      };

      const game = await GameService.createGame(gameData, testUser.id);

      expect(game.title).toBe(gameData.title);
      expect(game.game_type).toBe(gameData.game_type);
      expect(game.creator_user_id).toBe(testUser.id);
    });

    it('should throw validation error for invalid game type', async () => {
      const invalidData = {
        title: 'Test Game',
        game_type: 'invalid_type'
      };

      await expect(
        GameService.createGame(invalidData, testUser.id)
      ).rejects.toThrow('Validation failed');
    });
  });
});
```

### Frontend Testing
```jsx
// components/__tests__/GameCard.test.jsx
import { render, screen, fireEvent } from '@testing-library/react';
import { vi } from 'vitest';
import { GameCard } from '../GameCard';

const mockGame = {
  id: 'game-1',
  title: 'Test Game',
  description: 'A test game',
  game_type: 'memory_game',
  is_published: true
};

describe('GameCard', () => {
  const mockOnClick = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders game information correctly', () => {
    render(<GameCard game={mockGame} onClick={mockOnClick} />);

    expect(screen.getByText('Test Game')).toBeInTheDocument();
    expect(screen.getByText('A test game')).toBeInTheDocument();
  });

  it('calls onClick when card is clicked', () => {
    render(<GameCard game={mockGame} onClick={mockOnClick} />);

    fireEvent.click(screen.getByRole('button'));

    expect(mockOnClick).toHaveBeenCalledWith('game-1');
  });

  it('shows published status correctly', () => {
    render(<GameCard game={mockGame} onClick={mockOnClick} />);

    expect(screen.getByText(/published/i)).toBeInTheDocument();
  });
});
```

## Performance Standards

### Backend Performance
- API responses < 500ms for typical requests
- Database queries optimized with proper indexes
- Use connection pooling for database connections
- Implement pagination for large datasets
- Use JSONB indexes for frequent JSONB queries

### Frontend Performance
- Initial page load < 3 seconds
- Component renders < 100ms
- Use React.memo for expensive components
- Implement lazy loading for routes
- Optimize bundle size with code splitting

### Code Examples
```jsx
// Memoization for expensive components
const ExpensiveComponent = React.memo(({ data, onUpdate }) => {
  const processedData = useMemo(() => {
    return data.map(item => ({
      ...item,
      calculated: expensiveCalculation(item)
    }));
  }, [data]);

  return (
    <div>
      {processedData.map(item => (
        <ItemCard key={item.id} item={item} onUpdate={onUpdate} />
      ))}
    </div>
  );
});

// Callback optimization
const GameList = ({ games, onGameUpdate }) => {
  const handleUpdate = useCallback((gameId, updates) => {
    onGameUpdate(gameId, updates);
  }, [onGameUpdate]);

  return (
    <div>
      {games.map(game => (
        <GameCard
          key={game.id}
          game={game}
          onUpdate={handleUpdate}
        />
      ))}
    </div>
  );
};
```

## Security Guidelines

### General Security
- Never commit secrets or API keys
- Validate all inputs on both client and server
- Use parameterized queries to prevent SQL injection
- Implement proper error handling without exposing internals
- Use HTTPS for all communications

### Authentication Security
```javascript
// Secure token handling
const generateToken = (user) => {
  return jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );
};

// Secure password hashing (handled by Firebase Auth)
// Never implement custom password hashing
```

### Data Protection
```javascript
// Sanitize user inputs
const sanitizeUserInput = (input) => {
  return input.trim().replace(/[<>]/g, '');
};

// Limit data exposure in responses
const safeUserObject = (user) => ({
  id: user.id,
  email: user.email,
  full_name: user.full_name,
  role: user.role
  // Never include sensitive fields like passwords
});
```

## Git and Version Control

### Commit Messages
Use conventional commit format:
```
type(scope): description

feat(auth): add password reset functionality
fix(games): resolve memory game scoring bug
docs(api): update authentication documentation
refactor(database): optimize game query performance
```

### Branch Naming
```
feature/add-video-streaming
bugfix/fix-authentication-issue
hotfix/security-patch
refactor/optimize-database-queries
```

### Code Review Standards
- All changes require pull request review
- Include tests for new functionality
- Update documentation for API changes
- Verify no console.log statements in production code
- Check for security implications

Following these coding standards ensures consistency, maintainability, and quality across the Ludora platform.
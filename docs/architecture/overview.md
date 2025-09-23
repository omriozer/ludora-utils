# System Architecture Overview

Ludora is a full-stack educational gaming platform built with a modern web architecture designed for scalability, maintainability, and educational effectiveness.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     LUDORA PLATFORM                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   React Client   │    │   Express API   │    │ PostgreSQL  │ │
│  │                 │◄──►│                │◄──►│  Database   │ │
│  │  • Vite Build    │    │ • RESTful API   │    │             │ │
│  │  • Tailwind CSS  │    │ • JWT Auth      │    │ • Sequelize │ │
│  │  • Radix UI      │    │ • File Upload   │    │ • JSONB     │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
│           │                       │                      │      │
│           │                       │                      │      │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │ Firebase Auth   │    │   File Storage  │    │   External  │ │
│  │                 │    │                 │    │  Services   │ │
│  │ • User Auth     │    │ • AWS S3        │    │ • PayPlus   │ │
│  │ • Email Verify  │    │ • Local Files   │    │ • Email     │ │
│  │ • Password      │    │ • Video Stream  │    │ • Analytics │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend Stack
- **Framework**: React 18 with hooks and context
- **Build Tool**: Vite for fast development and optimized builds
- **Styling**: Tailwind CSS with custom design system
- **UI Components**: Radix UI for accessible, unstyled primitives
- **Routing**: React Router DOM v7 for client-side navigation
- **State Management**: React Context API with custom hooks
- **Forms**: React Hook Form with Zod validation
- **Testing**: Vitest + React Testing Library

### Backend Stack
- **Runtime**: Node.js 18+ with ES modules
- **Framework**: Express.js with comprehensive middleware
- **Database**: PostgreSQL 14+ with Sequelize ORM
- **Authentication**: Firebase Admin SDK + JWT tokens
- **File Storage**: AWS S3 with multer for uploads
- **Email**: Nodemailer with configurable providers
- **Process Management**: PM2 for production deployment
- **Testing**: Jest with Supertest for API testing

### Database Architecture
- **Primary Database**: PostgreSQL with hybrid patterns
- **ORM**: Sequelize for structured data
- **Flexible Data**: JSONB columns for game settings
- **Migrations**: Sequelize CLI for schema management
- **Indexing**: Strategic JSONB and composite indexes

## Core Domain Model

### Entity Relationships

```
User ←→ Purchase ←→ [Workshop|Course|File|Tool]
  │         │
  ├─ Role   └─ SubscriptionHistory ←→ SubscriptionPlan
  │
  └─ School ←→ Classroom ←→ Student

Game ←→ GameContentUsage ←→ Content[Word|Image|QA|etc.]
  │
  └─ GameSettings (JSONB) ←→ GameContentRule
```

### Key Entities

**User Management:**
- `User` - Multi-role user system (student, teacher, parent, admin)
- `School` - Educational institution management
- `Classroom` - Teacher-student organization
- `StudentInvitation` - Student enrollment workflow

**Educational Content:**
- `Game` - Educational games with flexible JSONB settings
- `Content Types` - Word, WordEN, Image, QA, Grammar, AudioFile
- `ContentList` - Organized content collections
- `GameContentRule` - Smart content selection rules

**Business Operations:**
- `Workshop`, `Course`, `File`, `Tool` - Dedicated product entities
- `Purchase` - Polymorphic purchase tracking with access control
- `SubscriptionPlan/History` - Subscription management
- `ParentConsent` - COPPA compliance for minors

## Authentication & Authorization Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Login    │───►│ Firebase Auth   │───►│   JWT Token     │
│   (Email/Pass)  │    │                 │    │   Generation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Frontend Store  │    │  Token Storage  │    │ API Middleware  │
│   User Data     │    │   (HttpOnly)    │    │ Token Validate  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                             │
         │                                             │
         └─────────────► API Requests ─────────────────┘
```

### Authentication Process
1. **User Login**: Email/password submitted to Firebase
2. **Firebase Verification**: Firebase validates credentials
3. **JWT Generation**: API generates signed JWT with user data from database
4. **Token Storage**: Frontend stores token securely
5. **Request Authorization**: All API requests include JWT in Authorization header
6. **Token Validation**: API middleware validates JWT on each request

### Role-Based Access Control
```
Admin (3) ─ Full system access, user management, platform settings
   │
Staff (2) ─ Content moderation, support, limited admin features
   │
Teacher (1) ─ Classroom management, student progress, content creation
   │
User (0) ─ Basic access, purchases, game playing
```

## Data Architecture Patterns

### Hybrid JSONB Approach
Ludora uses a hybrid data pattern combining structured tables with flexible JSONB:

**Structured Data:**
- Entity relationships (User ↔ Purchase)
- Frequently queried fields (user.email, game.title)
- Referential integrity constraints

**JSONB Data:**
- Game settings and configurations
- Content rules and filters
- User preferences and metadata

### Example: Game Settings
```sql
-- Structured fields for queries
CREATE TABLE game (
  id VARCHAR(255) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  game_type VARCHAR(50) NOT NULL,
  is_published BOOLEAN DEFAULT false,

  -- Flexible settings in JSONB
  game_settings JSONB DEFAULT '{}',

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexed JSONB queries
CREATE INDEX idx_game_pairs_count ON game
USING BTREE (((game_settings->>'pairs_count')::int))
WHERE game_type = 'memory_game';
```

## API Architecture

### RESTful Design Patterns

**Generic Entity Endpoints:**
```
GET    /api/entities/:type           # List entities
POST   /api/entities/:type           # Create entity
GET    /api/entities/:type/:id       # Get entity
PUT    /api/entities/:type/:id       # Update entity
DELETE /api/entities/:type/:id       # Delete entity
```

**Specialized Endpoints:**
```
POST   /api/auth/login               # Authentication
GET    /api/videos/:id/stream        # Video streaming
POST   /api/games/content-usage      # Game content management
GET    /api/access/check             # Permission checking
```

### Middleware Stack
```
Request → CORS → Helmet → Rate Limit → Auth → Validation → Route Handler
```

1. **CORS**: Cross-origin resource sharing
2. **Helmet**: Security headers
3. **Rate Limiting**: Prevent abuse
4. **Authentication**: JWT validation
5. **Validation**: Input sanitization and validation
6. **Route Handler**: Business logic execution

## File Storage Architecture

### Multi-Storage Strategy
```
Upload Request
     │
     ▼
┌─────────────┐    YES    ┌─────────────┐
│AWS S3 Config│ ────────► │   AWS S3    │
│  Available? │           │   Storage   │
└─────────────┘           └─────────────┘
     │ NO
     ▼
┌─────────────┐
│Local Storage│
│ (uploads/)  │
└─────────────┘
```

### Video Streaming System
- **HTTP Range Support**: Efficient streaming with 206 responses
- **Access Control**: Purchase/subscription verification before serving
- **Creator Access**: Content creators can access their own videos
- **Security**: No direct file system access, all requests through API

## Frontend Architecture

### Component Hierarchy
```
App
├── Routes (React Router)
├── AuthProvider (Context)
├── Pages
│   ├── Public (Home, Auth, Legal)
│   ├── Dashboard (User-specific)
│   ├── Educational (Games, Courses)
│   ├── Admin (Management)
│   └── School (Classroom management)
└── Components
    ├── UI (Reusable components)
    ├── Forms (Form components)
    ├── Layout (Headers, navigation)
    └── Game (Game-specific)
```

### State Management Pattern
```javascript
// Global state with Context
const AuthContext = createContext();
const UserContext = createContext();

// Local state with hooks
const [games, setGames] = useState([]);
const [loading, setLoading] = useState(false);

// Service layer for API calls
const gameService = {
  async fetchGames() { /* API call */ },
  async createGame(data) { /* API call */ }
};
```

## Security Architecture

### Defense in Depth
1. **Input Validation**: Joi schemas for all API inputs
2. **Authentication**: Firebase + JWT token validation
3. **Authorization**: Role-based access control
4. **HTTPS**: TLS encryption for all communications
5. **CORS**: Restricted cross-origin requests
6. **Rate Limiting**: Prevent abuse and DoS attacks
7. **SQL Injection Prevention**: Sequelize ORM parameterized queries
8. **XSS Prevention**: Input sanitization and CSP headers

### Data Protection
- **COPPA Compliance**: Parent consent for users under 13
- **Password Security**: Firebase handles password hashing
- **Session Management**: JWT tokens with expiration
- **File Access Control**: Signed URLs for protected content

## Deployment Architecture

### Environment Separation
```
Development ← Git → Staging ← Git → Production
     │                │             │
     ▼                ▼             ▼
Local Database   Test Database  Prod Database
Firebase Dev     Firebase Test  Firebase Prod
```

### Production Infrastructure
- **Process Management**: PM2 for Node.js processes
- **Database**: PostgreSQL with connection pooling
- **File Storage**: AWS S3 with CDN
- **Monitoring**: PM2 monitoring + custom health checks
- **Logging**: Structured logging with rotation

## Performance Considerations

### Database Optimization
- **Indexing Strategy**: Composite indexes for common queries
- **JSONB Performance**: Strategic indexing on JSONB fields
- **Connection Pooling**: Sequelize connection management
- **Query Optimization**: N+1 prevention with eager loading

### Frontend Performance
- **Code Splitting**: Route-based lazy loading
- **Asset Optimization**: Vite build optimization
- **Caching Strategy**: Browser caching for static assets
- **Bundle Size**: Tree-shaking and dependency optimization

## Scalability Design

### Horizontal Scaling Opportunities
- **API Servers**: Stateless design allows multiple instances
- **Database**: Read replicas for heavy read workloads
- **File Storage**: S3 handles scaling automatically
- **Caching**: Redis can be added for session/data caching

### Vertical Scaling
- **Database**: PostgreSQL scales well with hardware
- **API Server**: Node.js cluster mode for multi-core
- **Memory Usage**: Efficient data structures and garbage collection

## Development Workflow

### Code Organization
```
ludora/
├── ludora-api/              # Backend application
│   ├── routes/              # API endpoints
│   ├── models/              # Database models
│   ├── services/            # Business logic
│   ├── middleware/          # Request processing
│   └── config/              # Configuration
├── ludora-front/            # Frontend application
│   ├── src/pages/           # Route components
│   ├── src/components/      # Reusable components
│   ├── src/services/        # API communication
│   └── src/contexts/        # State management
└── docs/                    # Documentation
```

### Migration Strategy
The platform was migrated from Base44 to custom architecture:
- **Phase 1**: API independence from Base44
- **Phase 2**: Database schema optimization
- **Phase 3**: Enhanced authentication system
- **Phase 4**: Performance optimization

## Next Steps

To understand specific aspects of the architecture:

- **Database Design**: [Database Schema](./database-schema.md)
- **Database Patterns**: [JSONB Patterns](./database-patterns.md)
- **Authentication**: [Auth System](./authentication.md)
- **File Storage**: [Storage System](./file-storage.md)

For implementation details:
- **API Reference**: [Backend API](../backend/api-reference.md)
- **Component Guide**: [Frontend Components](../frontend/components.md)
- **Development Guide**: [Development Setup](../getting-started/setup.md)
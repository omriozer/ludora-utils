# Development Environment Setup

This guide will help you set up a complete Ludora development environment from scratch.

## Prerequisites

### Required Software
- **Node.js 18+** - [Download from nodejs.org](https://nodejs.org/)
- **npm 8+** - Comes with Node.js
- **PostgreSQL 14+** - [Download from postgresql.org](https://www.postgresql.org/download/)
- **Git** - [Download from git-scm.com](https://git-scm.com/)

### Optional Tools
- **Docker** - For containerized database setup
- **VS Code** - Recommended IDE with extensions
- **Postman** - For API testing

## Quick Setup (5 Minutes)

### 1. Clone Repository
```bash
git clone <repository-url>
cd ludora
```

### 2. Install Dependencies
```bash
# Install API dependencies
cd ludora-api
npm install

# Install frontend dependencies
cd ../ludora-front
npm install

# Return to root
cd ..
```

### 3. Database Setup
```bash
cd ludora-api

# Create database and run migrations
npm run db:setup

# Verify database connection
npm run db:test
```

### 4. Environment Configuration
```bash
# Copy environment templates
cp development.env.example development.env
cp ../ludora-front/.env.example ../ludora-front/.env

# Edit development.env with your settings:
# - Database connection details
# - Firebase credentials
# - AWS S3 credentials (optional)
```

### 5. Start Development Servers
```bash
# Terminal 1: Start API server (port 3001)
cd ludora-api
npm run dev

# Terminal 2: Start frontend (port 5173)
cd ludora-front
npm run dev
```

Visit `http://localhost:5173` to access the application.

## Detailed Setup Instructions

### Database Setup Options

#### Option 1: Local PostgreSQL Installation
1. Install PostgreSQL 14+ on your system
2. Create a development database:
   ```sql
   createdb ludora_development
   createuser ludora_user --password
   ```
3. Update `development.env` with your database credentials

#### Option 2: Docker PostgreSQL
```bash
# Start PostgreSQL container
docker run --name ludora-postgres \
  -e POSTGRES_DB=ludora_development \
  -e POSTGRES_USER=ludora_user \
  -e POSTGRES_PASSWORD=ludora_dev_pass \
  -p 5432:5432 \
  -d postgres:14

# Wait a few seconds, then run migrations
cd ludora-api
npm run db:setup
```

### Firebase Configuration

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication with Email/Password

2. **Get Firebase Config**:
   - Project Settings > General > Your apps
   - Copy the config object values

3. **Create Service Account**:
   - Project Settings > Service Accounts
   - Generate new private key
   - Download the JSON file

4. **Update Environment Files**:
   ```bash
   # ludora-api/development.env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xyz@your-project.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

   # ludora-front/.env
   VITE_FIREBASE_API_KEY=your-api-key
   VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=your-project-id
   ```

### AWS S3 Configuration (Optional)

If you want to use AWS S3 for file storage:

1. **Create S3 Bucket**:
   - Create bucket in AWS Console
   - Configure CORS policy for uploads

2. **Create IAM User**:
   - Create user with S3 read/write permissions
   - Generate access keys

3. **Update Environment**:
   ```bash
   # ludora-api/development.env
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_REGION=us-west-2
   AWS_S3_BUCKET=your-bucket-name
   ```

Without S3, files will be stored locally in `ludora-api/uploads/`.

## Development Scripts

### API Scripts
```bash
cd ludora-api

# Development server with auto-reload
npm run dev

# Run tests
npm test
npm run test:watch
npm run test:coverage

# Database management
npm run migrate           # Run pending migrations
npm run migrate:undo      # Undo last migration
npm run migrate:status    # Check migration status
npm run db:gui           # Open Adminer (localhost:8080)

# Production commands
npm run start:prod
npm run pm2:start
```

### Frontend Scripts
```bash
cd ludora-front

# Development server
npm run dev

# Build for production
npm run build
npm run preview

# Testing
npm test
npm run test:ui
npm run test:coverage

# Linting
npm run lint
```

## Verification Steps

### 1. Test API Connection
```bash
curl http://localhost:3001/health
# Should return: {"status":"ok","environment":"development"}
```

### 2. Test Database Connection
```bash
cd ludora-api
npm run db:test
# Should show successful database connection
```

### 3. Test Frontend Build
```bash
cd ludora-front
npm run build
# Should build without errors
```

### 4. Test Authentication
1. Open `http://localhost:5173`
2. Try to register a new account
3. Check Firebase Console for the new user

## Troubleshooting

### Database Issues
- **Connection refused**: Check PostgreSQL is running
- **Authentication failed**: Verify username/password in `.env`
- **Database doesn't exist**: Run `npm run db:setup`

### Firebase Issues
- **Auth domain error**: Check VITE_FIREBASE_AUTH_DOMAIN
- **Project not found**: Verify FIREBASE_PROJECT_ID
- **Permission denied**: Check service account permissions

### Port Conflicts
- **API port 3001 in use**: Change PORT in development.env
- **Frontend port 5173 in use**: Change in vite.config.js

### Common Solutions
```bash
# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Reset database
npm run db:drop
npm run db:setup
```

## IDE Setup (VS Code)

### Recommended Extensions
```json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-json",
    "ms-vscode.vscode-eslint",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.vscode-postgres"
  ]
}
```

### Workspace Settings
```json
{
  "typescript.preferences.includePackageJsonAutoImports": "on",
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "ms-vscode.vscode-typescript-next",
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"]
  ]
}
```

## Next Steps

Once your environment is set up:

1. **Explore the Codebase**: Start with [Architecture Overview](../architecture/overview.md)
2. **Run Tests**: Ensure everything works with `npm test`
3. **Read API Docs**: Check [API Reference](../backend/api-reference.md)
4. **Understand Components**: Review [Frontend Guide](../frontend/components.md)
5. **Make Changes**: Follow [Development Guidelines](../development/coding-standards.md)

## Need Help?

- **Setup Issues**: Check [Troubleshooting Guide](./troubleshooting.md)
- **API Questions**: See [API Reference](../backend/api-reference.md)
- **Database Problems**: Review [Database Patterns](../architecture/database-patterns.md)
# Quick Start Guide

Get Ludora running in 5 minutes for immediate development.

## Prerequisites Check
```bash
# Verify you have the required tools
node --version    # Should be 18+
npm --version     # Should be 8+
psql --version    # Should be 14+
```

## 5-Minute Setup

### 1. Clone & Install (1 minute)
```bash
# Clone repository
git clone <repository-url> ludora
cd ludora

# Install all dependencies
cd ludora-api && npm install
cd ../ludora-front && npm install
cd ..
```

### 2. Database Setup (1 minute)
```bash
cd ludora-api

# Create database and run migrations
npm run db:setup

# Verify connection
npm run db:test
```

### 3. Environment Setup (1 minute)
```bash
# Copy environment files
cp ludora-api/development.env.example ludora-api/development.env
cp ludora-front/.env.example ludora-front/.env

# Quick Firebase setup (use demo credentials)
# Edit ludora-api/development.env and ludora-front/.env
# with your Firebase project details
```

### 4. Start Servers (30 seconds)
```bash
# Terminal 1: API Server
cd ludora-api && npm run dev

# Terminal 2: Frontend
cd ludora-front && npm run dev
```

### 5. Verify Setup (30 seconds)
- Open `http://localhost:5173` - Frontend should load
- Check `http://localhost:3001/health` - API should respond
- Try registering a test account

## What You Get

### Running Services
- **Frontend**: `http://localhost:5173` - React application
- **API**: `http://localhost:3001` - Express.js server
- **Database GUI**: `npm run db:gui` - Adminer at `http://localhost:8080`

### Default Admin Account
```
Email: admin@ludora.app
Password: admin123
```

### Test Data
The setup includes sample data:
- Demo educational games
- Test content (words, images, Q&A)
- Sample workshops and courses
- Basic user roles and permissions

## Essential Development Commands

### Daily Development
```bash
# Start development (in separate terminals)
cd ludora-api && npm run dev      # API with auto-reload
cd ludora-front && npm run dev    # Frontend with hot reload

# Run tests
npm test                          # All tests
npm run test:watch               # Watch mode
npm run test:coverage            # With coverage
```

### Database Operations
```bash
cd ludora-api

# Database management
npm run migrate                   # Run new migrations
npm run migrate:undo             # Undo last migration
npm run db:gui                   # Open database GUI

# Reset database (if needed)
npm run db:drop && npm run db:setup
```

### Quick Testing
```bash
# Test API endpoints
curl http://localhost:3001/health
curl http://localhost:3001/api/auth/validate -H "Authorization: Bearer <token>"

# Test frontend build
cd ludora-front && npm run build
```

## Common Issues & Quick Fixes

### Database Connection Failed
```bash
# Check PostgreSQL is running
brew services list | grep postgres    # macOS
sudo service postgresql status        # Linux

# Restart if needed
brew services restart postgresql      # macOS
sudo service postgresql restart       # Linux
```

### Port Already in Use
```bash
# Kill processes on ports
npx kill-port 3001    # API port
npx kill-port 5173    # Frontend port

# Or change ports in config files
```

### Firebase Authentication Issues
```bash
# Verify environment variables are set
grep FIREBASE ludora-api/development.env
grep VITE_FIREBASE ludora-front/.env

# Test Firebase connection
cd ludora-api && node -e "require('./config/firebase.js'); console.log('Firebase connected')"
```

### Missing Dependencies
```bash
# Reinstall all dependencies
rm -rf ludora-api/node_modules ludora-front/node_modules
rm ludora-api/package-lock.json ludora-front/package-lock.json
cd ludora-api && npm install
cd ../ludora-front && npm install
```

## Next Steps

Once you have everything running:

1. **Explore the App**:
   - Register a test user
   - Browse educational games
   - Try the admin panel

2. **Understand the Code**:
   - Start with [Architecture Overview](../architecture/overview.md)
   - Review [API Reference](../backend/api-reference.md)
   - Check [Component Guide](../frontend/components.md)

3. **Make Your First Change**:
   - Edit a React component
   - Add a new API endpoint
   - Modify database schema

4. **Run Tests**:
   - Ensure changes don't break existing functionality
   - Add tests for new features

## Development Workflow

```bash
# Daily routine
git pull origin main                    # Get latest changes
npm run migrate                         # Apply database changes
npm test                                # Verify tests pass
npm run dev                            # Start development

# Before committing
npm test                               # Run all tests
npm run lint                           # Check code style
npm run build                          # Verify builds work
git add . && git commit -m "Your change"
```

## Performance Tips

- **Use npm scripts**: They're optimized for the project
- **Keep terminals open**: Avoid restarting dev servers
- **Use database GUI**: Faster than CLI for data inspection
- **Hot reload**: Both frontend and API support automatic reloading

## Need More Detail?

- **Complete Setup**: [Full Setup Guide](./setup.md)
- **Troubleshooting**: [Troubleshooting Guide](./troubleshooting.md)
- **Architecture**: [System Architecture](../architecture/overview.md)
- **API Documentation**: [API Reference](../backend/api-reference.md)
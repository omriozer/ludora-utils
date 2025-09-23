# Troubleshooting Guide

Common issues and their solutions when developing with Ludora.

## Database Issues

### Connection Refused / Database Unreachable

**Symptoms:**
- `ECONNREFUSED` errors
- API fails to start with database connection error
- Tests fail immediately

**Solutions:**
```bash
# Check if PostgreSQL is running
brew services list | grep postgres    # macOS
sudo service postgresql status        # Linux
systemctl status postgresql           # systemd

# Start PostgreSQL if not running
brew services start postgresql        # macOS
sudo service postgresql start         # Linux
systemctl start postgresql           # systemd

# Check connection manually
psql -h localhost -U ludora_user -d ludora_development
```

### Authentication Failed for User

**Symptoms:**
- `password authentication failed` error
- Can connect to postgres but not with app credentials

**Solutions:**
```bash
# Reset user password
sudo -u postgres psql
ALTER USER ludora_user PASSWORD 'ludora_dev_pass';
\q

# Update environment file
# Verify ludora-api/development.env has correct credentials:
DATABASE_URL=postgresql://ludora_user:ludora_dev_pass@localhost:5432/ludora_development
```

### Database Does Not Exist

**Symptoms:**
- `database "ludora_development" does not exist`
- Fresh setup fails

**Solutions:**
```bash
# Create database manually
createdb ludora_development

# Or reset database completely
cd ludora-api
npm run db:drop    # If exists
npm run db:setup   # Create and migrate
```

### Migration Errors

**Symptoms:**
- Migration fails with constraint errors
- Schema out of sync

**Solutions:**
```bash
cd ludora-api

# Check migration status
npm run migrate:status

# Reset database (CAUTION: loses data)
npm run db:drop
npm run db:setup

# Or undo last migration and retry
npm run migrate:undo
npm run migrate
```

## Firebase Authentication Issues

### Project Not Found / Invalid Configuration

**Symptoms:**
- `Firebase project not found` error
- Authentication doesn't work on frontend

**Solutions:**
```bash
# Verify environment variables
grep FIREBASE ludora-api/development.env
grep VITE_FIREBASE ludora-front/.env

# Check Firebase project exists and is active
# Visit https://console.firebase.google.com/

# Test Firebase connection
cd ludora-api
node -e "require('./config/firebase.js'); console.log('Firebase OK')"
```

### Service Account Issues

**Symptoms:**
- `Error: insufficient permissions` from Firebase
- Admin operations fail

**Solutions:**
```bash
# Verify service account key format
# Private key should have \n for line breaks:
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQ...\n-----END PRIVATE KEY-----\n"

# Check service account permissions in Firebase Console:
# Project Settings > Service Accounts
# Ensure it has "Firebase Admin SDK Admin Service Agent" role
```

### CORS Errors with Firebase

**Symptoms:**
- `CORS policy` errors in browser console
- Authentication fails only in browser

**Solutions:**
```bash
# Update Firebase Auth domain in frontend env
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com

# Ensure domain matches exactly what's in Firebase Console
# Project Settings > General > Your apps
```

## Node.js / npm Issues

### Port Already in Use

**Symptoms:**
- `EADDRINUSE: address already in use :::3001`
- Server fails to start

**Solutions:**
```bash
# Find and kill process using port
lsof -ti:3001 | xargs kill -9
lsof -ti:5173 | xargs kill -9

# Or use npm package
npx kill-port 3001 5173

# Change ports if needed
# In ludora-api/development.env:
PORT=3002

# In ludora-front/vite.config.js:
server: { port: 5174 }
```

### npm Install Failures

**Symptoms:**
- `npm ERR!` during installation
- Missing dependencies

**Solutions:**
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node.js version
node --version  # Should be 18+

# Try with legacy peer deps
npm install --legacy-peer-deps
```

### Module Resolution Errors

**Symptoms:**
- `Cannot find module` errors
- Import/require failures

**Solutions:**
```bash
# Verify file exists
ls -la ludora-api/config/firebase.js

# Check file extensions and case sensitivity
# Ensure imports match exact filenames

# Clear module cache (for Node.js)
rm -rf node_modules/.cache

# Restart development server
```

## Frontend Issues

### Build Failures

**Symptoms:**
- `npm run build` fails
- TypeScript compilation errors

**Solutions:**
```bash
cd ludora-front

# Check for linting errors
npm run lint

# Clear Vite cache
rm -rf node_modules/.vite

# Verify all imports are correct
npm run build -- --debug
```

### Hot Reload Not Working

**Symptoms:**
- Changes don't reflect automatically
- Page requires manual refresh

**Solutions:**
```bash
# Restart Vite dev server
# Ctrl+C to stop, then npm run dev

# Check file watching limits (Linux)
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Clear browser cache and hard refresh
# Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)
```

### API Connection Issues

**Symptoms:**
- `fetch failed` errors
- CORS errors in browser

**Solutions:**
```bash
# Verify API URL in frontend environment
grep VITE_API_URL ludora-front/.env
# Should be: VITE_API_URL=http://localhost:3001

# Check API is running
curl http://localhost:3001/health

# Enable CORS in API (already configured)
# Check ludora-api/index.js for CORS setup
```

## File Upload Issues

### Upload Fails / File Not Found

**Symptoms:**
- File uploads return 500 errors
- Uploaded files can't be accessed

**Solutions:**
```bash
# Check uploads directory exists and is writable
mkdir -p ludora-api/uploads/{images,videos,documents}
chmod 755 ludora-api/uploads

# Verify multer configuration
# Check ludora-api/middleware/fileUpload.js

# For S3 issues, verify AWS credentials:
grep AWS ludora-api/development.env
```

## Testing Issues

### Tests Fail to Start

**Symptoms:**
- Jest/Vitest won't start
- `Cannot find module` in test files

**Solutions:**
```bash
# Backend tests (Jest)
cd ludora-api
rm -rf node_modules/.cache
npm test -- --clearCache

# Frontend tests (Vitest)
cd ludora-front
rm -rf node_modules/.vite
npm test -- --run
```

### Database Tests Failing

**Symptoms:**
- Tests pass individually but fail in suite
- Database connection errors in tests

**Solutions:**
```bash
# Use test database
# Update ludora-api/test.env:
DATABASE_URL=postgresql://ludora_user:ludora_dev_pass@localhost:5432/ludora_test

# Create test database
createdb ludora_test

# Run tests with proper environment
cd ludora-api
ENVIRONMENT=test npm test
```

## Performance Issues

### Slow API Responses

**Solutions:**
```bash
# Check database performance
# Run EXPLAIN ANALYZE on slow queries

# Monitor database connections
cd ludora-api
npm run db:gui
# Check active connections in Adminer

# Add database indexes if needed
# See docs/architecture/database-patterns.md
```

### High Memory Usage

**Solutions:**
```bash
# Monitor Node.js memory
node --inspect ludora-api/index.js

# Use production build for frontend
cd ludora-front
npm run build
npm run preview  # Instead of npm run dev
```

## Environment-Specific Issues

### Development vs Production

**Symptoms:**
- Works in development but fails in staging/production
- Environment variable issues

**Solutions:**
```bash
# Verify environment files exist for each stage
ls ludora-api/*.env

# Check environment loading
cd ludora-api
ENVIRONMENT=staging node -e "console.log(process.env.DATABASE_URL)"

# Use correct start commands
npm run start:dev      # Development
npm run start:staging  # Staging
npm run start:prod     # Production
```

## Getting Help

### Debug Information to Gather

```bash
# System information
node --version
npm --version
psql --version
uname -a  # System info

# Check service status
brew services list | grep postgres  # macOS
systemctl status postgresql         # Linux

# Check logs
tail -f ludora-api/logs/pm2-combined-0.log
```

### Log Locations

```bash
# API logs
ludora-api/logs/pm2-combined-0.log
ludora-api/logs/pm2-error-0.log

# Database logs (varies by system)
/usr/local/var/log/postgres.log     # macOS Homebrew
/var/log/postgresql/              # Linux
```

### Common Log Commands

```bash
cd ludora-api

# View recent logs
npm run logs:view:recent

# View errors only
npm run logs:view:errors

# Follow live logs
npm run logs:tail

# Check log sizes
npm run logs:size
```

### When to Reset Everything

If multiple issues persist, try a complete reset:

```bash
# Stop all services
npm run pm2:stop 2>/dev/null || true
pkill -f "node.*ludora" 2>/dev/null || true

# Clear all caches
rm -rf ludora-api/node_modules ludora-front/node_modules
rm -rf ludora-api/logs/* 2>/dev/null || true
npm cache clean --force

# Reset database
cd ludora-api
npm run db:drop 2>/dev/null || true

# Fresh install
cd ludora-api && npm install
cd ../ludora-front && npm install

# Fresh setup
cd ludora-api
npm run db:setup
npm run dev
```

## Need More Help?

- **Setup Guide**: [Complete Setup Instructions](./setup.md)
- **Architecture**: [System Architecture](../architecture/overview.md)
- **API Reference**: [API Documentation](../backend/api-reference.md)
- **Database**: [Database Patterns](../architecture/database-patterns.md)
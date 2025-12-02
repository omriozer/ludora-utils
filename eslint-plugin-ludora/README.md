# ESLint Plugin Ludora

Custom ESLint rules for enforcing Ludora's architectural patterns, particularly around data-driven caching and code quality.

## Installation

The plugin is automatically installed when you run `npm install` in either the backend or frontend projects.

```bash
# Backend
cd ludora-api && npm install

# Frontend
cd ludora-front && npm install
```

## Rules

### 🚨 `ludora/no-time-based-caching` (Error - BLOCKS PR APPROVAL)

**This is a HARD ARCHITECTURAL RULE that will block PR approval if violated.**

Detects and prevents time-based cache expiration patterns. Ludora requires all caching to be data-driven using `updated_at` timestamps or version fields.

#### ❌ Violations

```javascript
// setTimeout for cache expiration
setTimeout(() => cache.delete('key'), 60000);  // BLOCKS PR

// setInterval for cache clearing
setInterval(() => cache.clear(), 15 * 60 * 1000);  // BLOCKS PR

// TTL-only cache configuration
const CACHE_TTL = 60000;  // BLOCKS PR if used alone

// Time-based cache keys
const cacheKey = `data:${Math.floor(Date.now() / 60000)}`;  // BLOCKS PR

// Time-based expiration in stored objects
localStorage.setItem('data', JSON.stringify({
  value: data,
  expires: Date.now() + 60000  // BLOCKS PR
}));

// React Query with only time-based staling
useQuery('key', fetchData, {
  staleTime: 5 * 60 * 1000,  // BLOCKS PR without refetchOnWindowFocus
  cacheTime: 10 * 60 * 1000
});
```

#### ✅ Correct Patterns

```javascript
// Data-driven cache key with version
const maxUpdated = await models.Setting.max('updated_at');
const cacheKey = `settings:${maxUpdated}`;

// Event-driven cache invalidation
models.Setting.addHook('afterUpdate', () => {
  cache.delete('settings');
});

// React Query with proper validation
useQuery(['settings', settingsVersion], fetchSettings, {
  staleTime: Infinity,  // Never stale by time
  refetchOnWindowFocus: true,  // Check on focus
  refetchOnReconnect: true  // Check on reconnect
});
```

### 📋 `ludora/require-data-driven-cache` (Warning)

Suggests using data-driven cache patterns with `updated_at` fields for proper invalidation.

#### Warnings

- Cache keys without version information
- Missing MAX(updated_at) queries for collections
- Cache operations without corresponding invalidation logic
- Mutations without cache invalidation

### 🔍 `ludora/no-unused-cache-keys` (Warning)

Detects unused cache key variables and orphaned cache operations.

#### Detects

- Cache keys defined but never used
- Cache entries set but never retrieved
- Cache entries retrieved but never set
- Cache constants that are never referenced

### 🚫 `ludora/no-console-log` (Error)

Enforces using `clog`/`cerror` instead of `console.log`/`console.error` for consistent logging.

#### Configuration

```javascript
// .eslintrc.js
rules: {
  'ludora/no-console-log': ['error', {
    allowInTests: true,      // Allow console.log in test files
    allowInMigrations: true  // Allow console.log in migrations
  }]
}
```

#### Auto-fix Available

```bash
# Automatically convert console.log to clog
npm run lint:fix
```

## Running Linting

```bash
# Backend
cd ludora-api
npm run lint        # Check for violations
npm run lint:fix    # Auto-fix where possible

# Frontend
cd ludora-front
npm run lint        # Check for violations
npm run lint:fix    # Auto-fix where possible
```

## Integration with CI/CD

These rules are enforced in the CI/CD pipeline. Any violations of error-level rules will:

1. Fail the build
2. Block PR approval
3. Prevent deployment

## Disabling Rules

In rare cases where you need to disable a rule:

```javascript
// Disable for next line
// eslint-disable-next-line ludora/no-time-based-caching
setTimeout(() => specialCase(), 1000);

// Disable for entire file (NOT RECOMMENDED)
/* eslint-disable ludora/no-time-based-caching */
```

**Note:** Disabling `no-time-based-caching` requires architectural review and approval.

## Why These Rules Exist

### Time-Based Caching Problems

1. **Stale Data:** Users see outdated information even when data has changed
2. **Wasted Resources:** Fresh data refetched even when nothing changed
3. **Race Conditions:** Timer expiration vs data updates
4. **Memory Leaks:** Forgotten timers
5. **Unpredictable Behavior:** Across server restarts

### Benefits of Data-Driven Caching

1. **Always Fresh:** Cache invalidates immediately when data changes
2. **Efficient:** Cache persists indefinitely if data doesn't change
3. **Predictable:** Cache state directly tied to data state
4. **No Cleanup:** No timers to manage or clear
5. **Scalable:** Works across multiple server instances

## Contributing

To add new rules or modify existing ones:

1. Edit files in `/ludora-utils/eslint-plugin-ludora/rules/`
2. Test thoroughly on both backend and frontend
3. Update this documentation
4. Get architectural review for changes to caching rules

## Support

For questions about these rules or help fixing violations, contact the architecture team or refer to the main CLAUDE.md documentation.
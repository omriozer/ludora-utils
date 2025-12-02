/**
 * Ludora Custom ESLint Plugin
 * Enforces data-driven caching patterns and detects unused code
 */

const noTimeBasedCaching = require('./rules/no-time-based-caching');
const requireDataDrivenCache = require('./rules/require-data-driven-cache');
const noUnusedCacheKeys = require('./rules/no-unused-cache-keys');
const noConsoleLog = require('./rules/no-console-log');

module.exports = {
  rules: {
    'no-time-based-caching': noTimeBasedCaching,
    'require-data-driven-cache': requireDataDrivenCache,
    'no-unused-cache-keys': noUnusedCacheKeys,
    'no-console-log': noConsoleLog
  },
  configs: {
    recommended: {
      plugins: ['ludora'],
      rules: {
        'ludora/no-time-based-caching': 'error',
        'ludora/require-data-driven-cache': 'warn',
        'ludora/no-unused-cache-keys': 'warn',
        'ludora/no-console-log': 'error'
      }
    }
  }
};
/**
 * Ludora Custom ESLint Plugin
 * Enforces data-driven caching patterns and detects unused code
 */

// Existing rules
const noTimeBasedCaching = require('./rules/no-time-based-caching');
const requireDataDrivenCache = require('./rules/require-data-driven-cache');
const noUnusedCacheKeys = require('./rules/no-unused-cache-keys');
const noConsoleLog = require('./rules/no-console-log');
const enforceCentralizedErrors = require('./rules/enforce-centralized-errors');

// New async-handler rules (split for incremental cleanup)
const requireAsyncHandler = require('./rules/require-async-handler');
const requireAsyncHandlerGet = require('./rules/require-async-handler-get');
const requireAsyncHandlerPost = require('./rules/require-async-handler-post');
const requireAsyncHandlerPutPatch = require('./rules/require-async-handler-put-patch');
const requireAsyncHandlerDelete = require('./rules/require-async-handler-delete');
const requireAsyncHandlerByFile = require('./rules/require-async-handler-by-file');

// Backend architecture rules
const requireEntityService = require('./rules/require-entity-service');
const noDirectErrorResponse = require('./rules/no-direct-error-response');
const noDirectErrorResponse4xx = require('./rules/no-direct-error-response-4xx');
const noDirectErrorResponse5xx = require('./rules/no-direct-error-response-5xx');

// Frontend rules
const noDirectFetch = require('./rules/no-direct-fetch');

module.exports = {
  rules: {
    // Existing rules
    'no-time-based-caching': noTimeBasedCaching,
    'require-data-driven-cache': requireDataDrivenCache,
    'no-unused-cache-keys': noUnusedCacheKeys,
    'no-console-log': noConsoleLog,
    'enforce-centralized-errors': enforceCentralizedErrors,

    // Async handler rules (split for <50 violations each)
    'require-async-handler': requireAsyncHandler,
    'require-async-handler-get': requireAsyncHandlerGet,
    'require-async-handler-post': requireAsyncHandlerPost,
    'require-async-handler-put-patch': requireAsyncHandlerPutPatch,
    'require-async-handler-delete': requireAsyncHandlerDelete,
    'require-async-handler-by-file': requireAsyncHandlerByFile,

    // Backend architecture enforcement
    'require-entity-service': requireEntityService,
    'no-direct-error-response': noDirectErrorResponse,
    'no-direct-error-response-4xx': noDirectErrorResponse4xx,
    'no-direct-error-response-5xx': noDirectErrorResponse5xx,

    // Frontend architecture enforcement
    'no-direct-fetch': noDirectFetch
  },
  configs: {
    recommended: {
      plugins: ['ludora'],
      rules: {
        // Existing rules (always enabled)
        'ludora/no-time-based-caching': 'error',
        'ludora/require-data-driven-cache': 'warn',
        'ludora/no-unused-cache-keys': 'warn',
        'ludora/no-console-log': 'error',
        'ludora/enforce-centralized-errors': ['warn', {
          allowInTests: true,
          allowInMigrations: true,
          mode: 'migration'
        }],

        // New rules (disabled by default - enable manually for incremental cleanup)
        'ludora/require-async-handler': 'off',
        'ludora/require-async-handler-get': 'off',
        'ludora/require-async-handler-post': 'off',
        'ludora/require-async-handler-put-patch': 'off',
        'ludora/require-async-handler-delete': 'off',
        'ludora/require-async-handler-by-file': 'off',
        'ludora/require-entity-service': 'off',
        'ludora/no-direct-error-response': 'off',
        'ludora/no-direct-error-response-4xx': 'off',
        'ludora/no-direct-error-response-5xx': 'off',
        'ludora/no-direct-fetch': 'off'
      }
    }
  }
};
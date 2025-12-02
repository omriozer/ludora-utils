/**
 * ESLint Rule: no-time-based-caching
 * Detects and prevents time-based cache expiration patterns
 * This is a HARD ARCHITECTURAL RULE that blocks PR approval
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Disallow time-based cache expiration patterns (blocks PR approval)',
      category: 'Architecture',
      recommended: true
    },
    messages: {
      setTimeoutCache: 'BLOCKING: setTimeout for cache expiration is prohibited. Use data-driven invalidation with updated_at fields instead.',
      setIntervalCache: 'BLOCKING: setInterval for cache clearing is prohibited. Use event-driven or data-driven invalidation instead.',
      ttlOnlyCache: 'BLOCKING: TTL-only cache configuration is prohibited. Include data version checking or event-driven invalidation.',
      timeCacheKey: 'BLOCKING: Time-based cache keys are prohibited. Use data version (updated_at) in cache keys instead.',
      expiresCachePattern: 'BLOCKING: Time-based expiration in cache objects is prohibited. Use data versioning instead.',
      reactQueryTimeOnly: 'BLOCKING: React Query staleTime without data validation is prohibited. Add refetchOnWindowFocus or version checking.',
      localStorageExpires: 'BLOCKING: localStorage with time-based expiration is prohibited. Use version fields instead.'
    },
    fixable: null,
    schema: []
  },

  create(context) {
    // Track cache-related variables
    const cacheVariables = new Set();
    const cacheMapInstances = new Set();

    return {
      // Track cache variable declarations
      VariableDeclarator(node) {
        const varName = node.id.name;

        // Track variables that are cache-related
        if (varName && (
          varName.toLowerCase().includes('cache') ||
          varName.toLowerCase().includes('store')
        )) {
          cacheVariables.add(varName);
        }

        // Track Map instances used for caching
        if (node.init &&
            node.init.type === 'NewExpression' &&
            node.init.callee.name === 'Map') {
          cacheMapInstances.add(varName);
        }
      },

      // Detect setTimeout with cache operations
      CallExpression(node) {
        const callee = node.callee;

        // Check setTimeout patterns
        if (callee.name === 'setTimeout' && node.arguments[0]) {
          const callback = node.arguments[0];
          const callbackCode = context.getSourceCode().getText(callback);

          // Check if setTimeout involves cache operations
          if (callbackCode.match(/cache\.(delete|clear|remove|set|invalidate)/i) ||
              callbackCode.match(/delete.*cache/i) ||
              callbackCode.match(/clear.*cache/i) ||
              callbackCode.match(/invalidate.*cache/i) ||
              callbackCode.match(/localStorage\.(removeItem|clear)/i)) {
            context.report({
              node,
              messageId: 'setTimeoutCache'
            });
          }
        }

        // Check setInterval patterns
        if (callee.name === 'setInterval' && node.arguments[0]) {
          const callback = node.arguments[0];
          const callbackCode = context.getSourceCode().getText(callback);

          if (callbackCode.match(/cache\.(clear|delete|invalidate)/i) ||
              callbackCode.match(/clear.*cache/i) ||
              callbackCode.match(/invalidate.*cache/i)) {
            context.report({
              node,
              messageId: 'setIntervalCache'
            });
          }
        }

        // Check for time-based cache key patterns
        if (callee.type === 'MemberExpression' &&
            (callee.object.name && cacheVariables.has(callee.object.name))) {
          const args = node.arguments;
          if (args.length > 0) {
            const keyArg = context.getSourceCode().getText(args[0]);

            // Check for Date.now() or timestamp in cache keys
            if (keyArg.includes('Date.now()') ||
                keyArg.includes('getTime()') ||
                keyArg.match(/Math\.floor\s*\(\s*Date\.now/)) {
              context.report({
                node,
                messageId: 'timeCacheKey'
              });
            }
          }
        }

        // Check React Query patterns
        if ((callee.name === 'useQuery' || callee.name === 'useInfiniteQuery') &&
            node.arguments.length >= 3) {
          const options = node.arguments[2];
          if (options && options.type === 'ObjectExpression') {
            const hasStaleTime = options.properties.some(p =>
              p.key && p.key.name === 'staleTime'
            );
            const hasRefetch = options.properties.some(p =>
              p.key && (p.key.name === 'refetchOnWindowFocus' ||
                       p.key.name === 'refetchOnReconnect' ||
                       p.key.name === 'refetchInterval')
            );

            if (hasStaleTime && !hasRefetch) {
              context.report({
                node: options,
                messageId: 'reactQueryTimeOnly'
              });
            }
          }
        }
      },

      // Check object properties for TTL/expires patterns
      Property(node) {
        const key = node.key;

        // Check for TTL-only configurations
        if (key && (key.name === 'ttl' ||
                   key.name === 'TTL' ||
                   key.name === 'timeToLive' ||
                   key.name === 'cacheTime')) {
          const parent = node.parent;

          // Check if this is a cache configuration without data validation
          const hasDataValidation = parent.properties.some(p =>
            p.key && (p.key.name === 'version' ||
                     p.key.name === 'dataVersion' ||
                     p.key.name === 'updated_at' ||
                     p.key.name === 'validateCache')
          );

          if (!hasDataValidation) {
            context.report({
              node,
              messageId: 'ttlOnlyCache'
            });
          }
        }

        // Check for expires patterns
        if (key && (key.name === 'expires' ||
                   key.name === 'expiresAt' ||
                   key.name === 'expiry')) {
          const value = node.value;
          const valueCode = context.getSourceCode().getText(value);

          // Check if expires is calculated with Date.now() + time
          if (valueCode.includes('Date.now()') ||
              valueCode.includes('+ ') ||
              valueCode.includes('getTime()')) {
            context.report({
              node,
              messageId: 'expiresCachePattern'
            });
          }
        }
      },

      // Check localStorage patterns
      MemberExpression(node) {
        if (node.object.name === 'localStorage' &&
            node.property.name === 'setItem') {
          const parent = node.parent;
          if (parent && parent.type === 'CallExpression') {
            const args = parent.arguments;
            if (args.length >= 2) {
              const valueArg = context.getSourceCode().getText(args[1]);

              // Check for expires field in stored data
              if (valueArg.includes('expires:') ||
                  valueArg.includes('expiresAt') ||
                  (valueArg.includes('Date.now()') && valueArg.includes('+'))) {
                context.report({
                  node: parent,
                  messageId: 'localStorageExpires'
                });
              }
            }
          }
        }
      },

      // Check for CACHE_TTL or similar constants
      Identifier(node) {
        if (node.parent.type === 'VariableDeclarator' &&
            node.parent.id === node) {
          const varName = node.name;

          if (varName === 'CACHE_TTL' ||
              varName === 'CACHE_TIMEOUT' ||
              varName === 'CACHE_EXPIRY' ||
              varName === 'CACHE_DURATION') {
            const init = node.parent.init;

            // Check if it's just a time value without data validation
            if (init && init.type === 'Literal' && typeof init.value === 'number') {
              context.report({
                node: node.parent,
                messageId: 'ttlOnlyCache'
              });
            }
          }
        }
      }
    };
  }
};
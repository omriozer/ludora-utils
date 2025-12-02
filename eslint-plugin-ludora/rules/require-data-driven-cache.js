/**
 * ESLint Rule: require-data-driven-cache
 * Suggests using data-driven cache patterns with updated_at fields
 */

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'Suggest using data-driven cache patterns with updated_at fields',
      category: 'Best Practices',
      recommended: true
    },
    messages: {
      missingDataVersion: 'Cache key should include data version (e.g., updated_at timestamp) for proper invalidation.',
      missingCacheInvalidation: 'Cache set operations should have corresponding invalidation on data changes.',
      suggestEventDriven: 'Consider using event-driven cache invalidation (afterUpdate hooks, SSE events).',
      useMaxUpdatedAt: 'Use MAX(updated_at) from database for collection cache keys.',
      includeVersionInKey: 'Cache key "{{key}}" should include a data version for proper invalidation.'
    },
    fixable: 'code',
    schema: []
  },

  create(context) {
    const cacheOperations = [];
    const cacheKeys = new Set();

    return {
      // Track cache.set() or cache.get() operations
      CallExpression(node) {
        const callee = node.callee;

        // Detect cache operations
        if (callee.type === 'MemberExpression' &&
            callee.object.name &&
            (callee.object.name.toLowerCase().includes('cache') ||
             callee.object.name === 'queryClient')) {

          const method = callee.property.name;

          // Track cache.set operations
          if (method === 'set' || method === 'put') {
            const keyArg = node.arguments[0];
            if (keyArg) {
              const keyText = context.getSourceCode().getText(keyArg);
              cacheOperations.push({ type: 'set', node, key: keyText });

              // Check if key includes version
              if (!keyText.includes('updated_at') &&
                  !keyText.includes('version') &&
                  !keyText.includes('dataVersion') &&
                  !keyText.includes('maxUpdated') &&
                  !keyText.includes('etag')) {
                context.report({
                  node: keyArg,
                  messageId: 'includeVersionInKey',
                  data: { key: keyText.replace(/[`'"]/g, '') }
                });
              }
            }
          }

          // Track cache.get operations
          if (method === 'get' || method === 'has') {
            const keyArg = node.arguments[0];
            if (keyArg) {
              const keyText = context.getSourceCode().getText(keyArg);
              cacheKeys.add(keyText);

              // Suggest version checking for gets
              if (keyArg.type === 'Literal' &&
                  !keyText.includes(':')) {
                context.report({
                  node: keyArg,
                  messageId: 'missingDataVersion'
                });
              }
            }
          }
        }

        // Check for models.*.findAll or similar without version tracking
        if (callee.type === 'MemberExpression' &&
            callee.object.type === 'MemberExpression' &&
            callee.object.object.name === 'models') {

          const method = callee.property.name;

          if (method === 'findAll' || method === 'findOne') {
            // Check if this is inside a function that uses caching
            const functionScope = findEnclosingFunction(node);
            if (functionScope) {
              const functionBody = context.getSourceCode().getText(functionScope);

              if (functionBody.includes('cache.set') ||
                  functionBody.includes('cache.get')) {

                // Check if there's a MAX(updated_at) query nearby
                if (!functionBody.includes('max(\'updated_at\')') &&
                    !functionBody.includes('MAX(updated_at)') &&
                    !functionBody.includes('.max(')) {
                  context.report({
                    node,
                    messageId: 'useMaxUpdatedAt'
                  });
                }
              }
            }
          }
        }

        // Check React Query patterns
        if (callee.name === 'useQuery' || callee.name === 'useMutation') {
          const keyArg = node.arguments[0];
          const options = node.arguments[2];

          if (keyArg && keyArg.type === 'ArrayExpression') {
            const hasVersion = keyArg.elements.some(el => {
              const text = context.getSourceCode().getText(el);
              return text.includes('version') ||
                     text.includes('updated_at') ||
                     text.includes('updatedAt');
            });

            if (!hasVersion) {
              context.report({
                node: keyArg,
                messageId: 'missingDataVersion',
                fix(fixer) {
                  // Suggest adding version to cache key
                  const lastElement = keyArg.elements[keyArg.elements.length - 1];
                  return fixer.insertTextAfter(lastElement, ', dataVersion');
                }
              });
            }
          }

          // Check mutations have invalidation
          if (callee.name === 'useMutation' && options) {
            const hasInvalidation = options.properties &&
              options.properties.some(p =>
                p.key && (p.key.name === 'onSuccess' ||
                         p.key.name === 'onSettled')
              );

            if (!hasInvalidation) {
              context.report({
                node: options || node,
                messageId: 'missingCacheInvalidation'
              });
            }
          }
        }
      },

      // Check for Sequelize hooks
      MemberExpression(node) {
        if (node.property.name === 'addHook') {
          const parent = node.parent;

          if (parent && parent.type === 'CallExpression') {
            const hookType = parent.arguments[0];

            if (hookType && hookType.value &&
                (hookType.value === 'afterUpdate' ||
                 hookType.value === 'afterCreate' ||
                 hookType.value === 'afterDestroy')) {

              // This is good - they're using hooks for cache invalidation
              // We could add a positive comment here if ESLint supported it
            }
          }
        }
      },

      // Check class methods that might need cache invalidation
      MethodDefinition(node) {
        const methodName = node.key.name;

        // Methods that likely modify data
        if (methodName === 'create' ||
            methodName === 'update' ||
            methodName === 'delete' ||
            methodName === 'save' ||
            methodName === 'destroy') {

          const methodBody = context.getSourceCode().getText(node.value.body);

          // Check if method invalidates cache
          if (!methodBody.includes('cache.clear') &&
              !methodBody.includes('cache.delete') &&
              !methodBody.includes('invalidate') &&
              !methodBody.includes('clearCache')) {

            context.report({
              node: node.key,
              messageId: 'suggestEventDriven'
            });
          }
        }
      }
    };

    function findEnclosingFunction(node) {
      let current = node.parent;
      while (current) {
        if (current.type === 'FunctionDeclaration' ||
            current.type === 'FunctionExpression' ||
            current.type === 'ArrowFunctionExpression') {
          return current;
        }
        current = current.parent;
      }
      return null;
    }
  }
};
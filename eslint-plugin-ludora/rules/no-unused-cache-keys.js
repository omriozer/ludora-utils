/**
 * ESLint Rule: no-unused-cache-keys
 * Detects unused cache key variables and patterns
 */

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'Detect unused cache key variables and patterns',
      category: 'Best Practices',
      recommended: true
    },
    messages: {
      unusedCacheKey: 'Cache key "{{key}}" is defined but never used.',
      unusedCacheConstant: 'Cache constant "{{name}}" is defined but never referenced.',
      orphanedCacheSet: 'Cache entry "{{key}}" is set but never retrieved.',
      orphanedCacheGet: 'Cache entry "{{key}}" is retrieved but never set.'
    },
    // Auto-fix disabled: removing cache keys requires verification that they're truly unused
    // fixable: 'code',
    schema: []
  },

  create(context) {
    const cacheKeyDefinitions = new Map(); // key -> node
    const cacheKeyUsages = new Map(); // key -> usage count
    const cacheSetOperations = new Set();
    const cacheGetOperations = new Set();

    return {
      // Track cache key constant definitions
      VariableDeclarator(node) {
        const varName = node.id.name;

        // Track CACHE_KEY constants
        if (varName && (
          varName.includes('CACHE_KEY') ||
          varName.includes('_KEY') ||
          varName === 'cacheKey' ||
          varName === 'key'
        )) {
          if (node.init && node.init.type === 'Literal') {
            const keyValue = node.init.value;
            cacheKeyDefinitions.set(varName, {
              node,
              value: keyValue,
              used: false
            });
          }
        }
      },

      // Track cache operations
      CallExpression(node) {
        const callee = node.callee;

        if (callee.type === 'MemberExpression' &&
            callee.object.name &&
            (callee.object.name.toLowerCase().includes('cache') ||
             callee.object.name === 'localStorage')) {

          const method = callee.property.name;
          const keyArg = node.arguments[0];

          if (keyArg) {
            let keyValue;

            // Extract key value
            if (keyArg.type === 'Literal') {
              keyValue = keyArg.value;
            } else if (keyArg.type === 'Identifier') {
              // Mark the identifier as used
              const keyDef = cacheKeyDefinitions.get(keyArg.name);
              if (keyDef) {
                keyDef.used = true;
                keyValue = keyDef.value;
              }
            } else if (keyArg.type === 'TemplateLiteral') {
              // Extract template literal base
              if (keyArg.quasis.length > 0) {
                keyValue = keyArg.quasis[0].value.cooked;
              }
            }

            // Track set/get operations
            if (keyValue) {
              if (method === 'set' || method === 'setItem' || method === 'put') {
                cacheSetOperations.add(keyValue);
              } else if (method === 'get' || method === 'getItem' || method === 'has') {
                cacheGetOperations.add(keyValue);
              }

              // Track usage
              const currentCount = cacheKeyUsages.get(keyValue) || 0;
              cacheKeyUsages.set(keyValue, currentCount + 1);
            }
          }
        }

        // Track React Query cache keys
        if (callee.name === 'useQuery' ||
            callee.name === 'useMutation' ||
            callee.name === 'invalidateQueries') {

          const keyArg = node.arguments[0];
          if (keyArg) {
            if (keyArg.type === 'ArrayExpression') {
              keyArg.elements.forEach(el => {
                if (el.type === 'Identifier') {
                  const keyDef = cacheKeyDefinitions.get(el.name);
                  if (keyDef) {
                    keyDef.used = true;
                  }
                }
              });
            } else if (keyArg.type === 'Identifier') {
              const keyDef = cacheKeyDefinitions.get(keyArg.name);
              if (keyDef) {
                keyDef.used = true;
              }
            }
          }
        }
      },

      // Track references to cache key variables
      Identifier(node) {
        // Skip if this is the declaration itself
        if (node.parent.type === 'VariableDeclarator' && node.parent.id === node) {
          return;
        }

        const keyDef = cacheKeyDefinitions.get(node.name);
        if (keyDef) {
          keyDef.used = true;
        }
      },

      // Report issues at the end
      'Program:exit'() {
        // Report unused cache key constants
        for (const [name, def] of cacheKeyDefinitions) {
          if (!def.used) {
            context.report({
              node: def.node,
              messageId: 'unusedCacheConstant',
              data: { name },
              fix(fixer) {
                // Remove the entire variable declaration
                const parent = def.node.parent;
                if (parent.type === 'VariableDeclaration' &&
                    parent.declarations.length === 1) {
                  return fixer.remove(parent);
                }
                return fixer.remove(def.node);
              }
            });
          }
        }

        // Report orphaned cache operations
        for (const key of cacheSetOperations) {
          if (!cacheGetOperations.has(key)) {
            // Find the node that sets this key
            const setNode = findCacheOperation(context, key, 'set');
            if (setNode) {
              context.report({
                node: setNode,
                messageId: 'orphanedCacheSet',
                data: { key }
              });
            }
          }
        }

        for (const key of cacheGetOperations) {
          if (!cacheSetOperations.has(key)) {
            // Find the node that gets this key
            const getNode = findCacheOperation(context, key, 'get');
            if (getNode) {
              context.report({
                node: getNode,
                messageId: 'orphanedCacheGet',
                data: { key }
              });
            }
          }
        }

        // Report cache keys that are only used once
        for (const [key, count] of cacheKeyUsages) {
          if (count === 1 && typeof key === 'string') {
            // This might be a one-time cache that's never invalidated
            const node = findCacheOperation(context, key);
            if (node) {
              context.report({
                node,
                messageId: 'unusedCacheKey',
                data: { key }
              });
            }
          }
        }
      }
    };

    function findCacheOperation(context, key, operation) {
      // This is a simplified implementation
      // In a real implementation, we'd track nodes during the traversal
      const sourceCode = context.getSourceCode();
      const ast = sourceCode.ast;

      // Use a visitor pattern to find the node
      let foundNode = null;
      const visited = new WeakSet(); // Prevent infinite recursion

      function visit(node) {
        if (!node || visited.has(node)) return;
        visited.add(node);

        if (node.type === 'CallExpression' &&
            node.callee && node.callee.type === 'MemberExpression') {

          const method = node.callee.property && node.callee.property.name;
          const keyArg = node.arguments && node.arguments[0];

          if (keyArg && keyArg.type === 'Literal' && keyArg.value === key) {
            if (!operation ||
                (operation === 'set' && (method === 'set' || method === 'setItem')) ||
                (operation === 'get' && (method === 'get' || method === 'getItem'))) {
              foundNode = node;
              return; // Stop searching once found
            }
          }
        }

        // Recursively visit child nodes
        for (const prop in node) {
          if (foundNode) break; // Stop if already found
          if (node[prop] && typeof node[prop] === 'object' && prop !== 'parent') {
            if (Array.isArray(node[prop])) {
              for (const child of node[prop]) {
                if (foundNode) break;
                if (child && typeof child === 'object') {
                  visit(child);
                }
              }
            } else if (node[prop].type) {
              visit(node[prop]);
            }
          }
        }
      }

      visit(ast);
      return foundNode;
    }
  }
};
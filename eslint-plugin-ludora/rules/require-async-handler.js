/**
 * @fileoverview Require async route handlers to be wrapped with asyncHandler
 * @author Ludora Team
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Require async route handlers to be wrapped with asyncHandler middleware',
      category: 'Best Practices',
      recommended: true
    },
    messages: {
      missingAsyncHandler: 'Async route handler must be wrapped with asyncHandler() to prevent unhandled promise rejections',
      noDirectAsyncHandler: 'asyncHandler() can only wrap async functions. Remove asyncHandler or make the function async'
    },
    schema: [{
      type: 'object',
      properties: {
        routeMethods: {
          type: 'array',
          items: { type: 'string' },
          default: ['get', 'post', 'put', 'patch', 'delete', 'all', 'use']
        },
        allowInMiddleware: {
          type: 'boolean',
          default: false
        }
      },
      additionalProperties: false
    }],
    fixable: null
  },

  create(context) {
    const options = context.options[0] || {};
    const routeMethods = options.routeMethods || ['get', 'post', 'put', 'patch', 'delete', 'all', 'use'];
    const allowInMiddleware = options.allowInMiddleware || false;

    // Track if we're in a route file (routes/ directory)
    const filename = context.getFilename();
    const isRouteFile = filename.includes('/routes/');
    const isMiddlewareFile = filename.includes('/middleware/');

    // Skip if not a route file or if in middleware and allowed
    if (!isRouteFile && (isMiddlewareFile && allowInMiddleware)) {
      return {};
    }

    /**
     * Check if a function is async
     */
    function isAsyncFunction(node) {
      if (!node) return false;

      // Check for async keyword
      if (node.async === true) {
        return true;
      }

      // Check for ArrowFunctionExpression with async
      if (node.type === 'ArrowFunctionExpression' && node.async) {
        return true;
      }

      // Check for FunctionExpression with async
      if (node.type === 'FunctionExpression' && node.async) {
        return true;
      }

      return false;
    }

    /**
     * Check if a function is wrapped with asyncHandler
     */
    function isWrappedWithAsyncHandler(node) {
      if (!node) return false;

      // Check if parent is a CallExpression
      if (node.parent && node.parent.type === 'CallExpression') {
        const callee = node.parent.callee;

        // Direct call: asyncHandler(async ...)
        if (callee.type === 'Identifier' && callee.name === 'asyncHandler') {
          return true;
        }
      }

      return false;
    }

    /**
     * Check if this is a route handler call
     */
    function isRouteHandler(node) {
      if (node.type !== 'CallExpression') return false;

      const callee = node.callee;

      // Check for router.get(), router.post(), etc.
      if (callee.type === 'MemberExpression') {
        const object = callee.object;
        const property = callee.property;

        // Check if it's router.METHOD or app.METHOD
        if (property.type === 'Identifier' && routeMethods.includes(property.name)) {
          if (object.type === 'Identifier' && (object.name === 'router' || object.name === 'app')) {
            return true;
          }
        }
      }

      return false;
    }

    /**
     * Get the handler function from route call arguments
     */
    function getRouteHandler(routeCall) {
      // Route handlers are typically the last argument
      // e.g., router.get('/path', middleware, handler)
      const args = routeCall.arguments;
      if (args.length < 2) return null;

      // The handler is the last argument
      const lastArg = args[args.length - 1];

      // Skip if it's not a function
      if (lastArg.type !== 'FunctionExpression' &&
          lastArg.type !== 'ArrowFunctionExpression' &&
          lastArg.type !== 'CallExpression') {
        return null;
      }

      return lastArg;
    }

    return {
      CallExpression(node) {
        // Check if this is a route handler call
        if (!isRouteHandler(node)) {
          return;
        }

        const handler = getRouteHandler(node);
        if (!handler) return;

        // If handler is a CallExpression, check if it's asyncHandler(...)
        if (handler.type === 'CallExpression') {
          const callee = handler.callee;

          // If it's asyncHandler, check that the wrapped function is actually async
          if (callee.type === 'Identifier' && callee.name === 'asyncHandler') {
            const wrappedFunc = handler.arguments[0];
            if (wrappedFunc && !isAsyncFunction(wrappedFunc)) {
              context.report({
                node: handler,
                messageId: 'noDirectAsyncHandler'
              });
            }
          }

          // It's a CallExpression but not asyncHandler, skip (might be a closure or factory)
          return;
        }

        // Check if it's an async function
        if (isAsyncFunction(handler)) {
          // Check if it's wrapped with asyncHandler
          if (!isWrappedWithAsyncHandler(handler)) {
            context.report({
              node: handler,
              messageId: 'missingAsyncHandler'
            });
          }
        }
      }
    };
  }
};

/**
 * @fileoverview Require async route handlers to be wrapped with asyncHandler - file-specific version
 * @author Ludora Team
 *
 * This rule allows splitting violations by specific files for incremental cleanup.
 * Each file can be enabled separately to fix violations in batches.
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Require async route handlers to be wrapped with asyncHandler (file-specific)',
      category: 'Best Practices',
      recommended: false // Enable manually per file
    },
    messages: {
      missingAsyncHandler: 'Async route handler must be wrapped with asyncHandler() [{{file}}]'
    },
    schema: [{
      type: 'object',
      properties: {
        filePattern: {
          type: 'string',
          description: 'Glob pattern or filename to check (e.g., "**/auth.js", "payments.js")'
        },
        routeMethods: {
          type: 'array',
          items: { type: 'string' },
          default: ['get', 'post', 'put', 'patch', 'delete', 'all', 'use']
        }
      },
      additionalProperties: false,
      required: ['filePattern']
    }],
    fixable: null
  },

  create(context) {
    const options = context.options[0] || {};
    const filePattern = options.filePattern;
    const routeMethods = options.routeMethods || ['get', 'post', 'put', 'patch', 'delete', 'all', 'use'];

    if (!filePattern) {
      return {}; // No pattern specified, skip
    }

    // Get filename and check if it matches the pattern
    const filename = context.getFilename();
    const isRouteFile = filename.includes('/routes/');

    // Simple pattern matching
    let matchesPattern = false;
    if (filePattern.includes('*')) {
      // Glob pattern - simple implementation
      const regex = new RegExp(filePattern.replace(/\*/g, '.*'));
      matchesPattern = regex.test(filename);
    } else {
      // Exact filename match
      matchesPattern = filename.endsWith(filePattern) || filename.includes(`/${filePattern}`);
    }

    if (!isRouteFile || !matchesPattern) {
      return {}; // Skip if not matching
    }

    // Extract just the filename for error messages
    const fileShortName = filename.split('/').pop();

    function isAsyncFunction(node) {
      return node && (node.async === true ||
        (node.type === 'ArrowFunctionExpression' && node.async) ||
        (node.type === 'FunctionExpression' && node.async));
    }

    function isWrappedWithAsyncHandler(node) {
      if (!node || !node.parent) return false;
      if (node.parent.type === 'CallExpression') {
        const callee = node.parent.callee;
        return callee.type === 'Identifier' && callee.name === 'asyncHandler';
      }
      return false;
    }

    function isRouteHandler(node) {
      if (node.type !== 'CallExpression') return false;
      const callee = node.callee;
      if (callee.type === 'MemberExpression') {
        const object = callee.object;
        const property = callee.property;
        if (property.type === 'Identifier' && routeMethods.includes(property.name)) {
          return object.type === 'Identifier' && (object.name === 'router' || object.name === 'app');
        }
      }
      return false;
    }

    function getRouteHandler(routeCall) {
      const args = routeCall.arguments;
      if (args.length < 2) return null;
      const lastArg = args[args.length - 1];
      if (lastArg.type !== 'FunctionExpression' &&
          lastArg.type !== 'ArrowFunctionExpression' &&
          lastArg.type !== 'CallExpression') {
        return null;
      }
      return lastArg;
    }

    return {
      CallExpression(node) {
        if (!isRouteHandler(node)) return;

        const handler = getRouteHandler(node);
        if (!handler || handler.type === 'CallExpression') return;

        if (isAsyncFunction(handler) && !isWrappedWithAsyncHandler(handler)) {
          context.report({
            node: handler,
            messageId: 'missingAsyncHandler',
            data: {
              file: fileShortName
            }
          });
        }
      }
    };
  }
};

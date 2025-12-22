/**
 * @fileoverview Require async GET route handlers to be wrapped with asyncHandler
 * @author Ludora Team
 *
 * Split from main rule to allow incremental cleanup (GET handlers only)
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Require async GET route handlers to be wrapped with asyncHandler',
      category: 'Best Practices',
      recommended: true
    },
    messages: {
      missingAsyncHandler: 'Async GET route handler must be wrapped with asyncHandler()'
    },
    schema: []
  },

  create(context) {
    const filename = context.getFilename();
    const isRouteFile = filename.includes('/routes/');

    if (!isRouteFile) {
      return {};
    }

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

    function isGetRouteHandler(node) {
      if (node.type !== 'CallExpression') return false;
      const callee = node.callee;
      if (callee.type === 'MemberExpression') {
        const object = callee.object;
        const property = callee.property;
        if (property.type === 'Identifier' && property.name === 'get') {
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
        if (!isGetRouteHandler(node)) return;

        const handler = getRouteHandler(node);
        if (!handler || handler.type === 'CallExpression') return;

        if (isAsyncFunction(handler) && !isWrappedWithAsyncHandler(handler)) {
          context.report({
            node: handler,
            messageId: 'missingAsyncHandler'
          });
        }
      }
    };
  }
};

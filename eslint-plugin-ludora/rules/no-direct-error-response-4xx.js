/**
 * @fileoverview Detect direct 4xx error responses (client errors)
 * @author Ludora Team
 *
 * Split from no-direct-error-response for incremental cleanup of client errors (400-499)
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce throw generateError() for 4xx (client) errors',
      category: 'Error Handling',
      recommended: true
    },
    messages: {
      useGenerateError: 'Use throw generateError() for 4xx client error instead of res.status({{status}}).json()'
    },
    schema: []
  },

  create(context) {
    const filename = context.getFilename();

    if (filename.includes('errorHandler') ||
        filename.includes('.test.') ||
        filename.includes('/migrations/')) {
      return {};
    }

    return {
      CallExpression(node) {
        // Check for .json() call
        if (node.callee.type === 'MemberExpression' &&
            node.callee.property.name === 'json') {

          // Check if it's chained after .status()
          const jsonObject = node.callee.object;
          if (jsonObject.type === 'CallExpression' &&
              jsonObject.callee.type === 'MemberExpression' &&
              jsonObject.callee.property.name === 'status') {

            // Get status code argument
            const statusArg = jsonObject.arguments[0];
            let statusCode = null;

            if (statusArg && statusArg.type === 'Literal') {
              statusCode = statusArg.value;
            }

            // Check if it's a 4xx status code
            if (statusCode && statusCode >= 400 && statusCode < 500) {
              // Check if the json argument is an object with 'error' property
              const jsonArg = node.arguments[0];
              if (jsonArg && jsonArg.type === 'ObjectExpression') {
                const hasErrorProp = jsonArg.properties.some(prop =>
                  prop.key && (prop.key.name === 'error' || prop.key.value === 'error')
                );

                if (hasErrorProp) {
                  context.report({
                    node,
                    messageId: 'useGenerateError',
                    data: {
                      status: statusCode
                    }
                  });
                }
              }
            }
          }
        }
      }
    };
  }
};

/**
 * @fileoverview Detect direct 5xx error responses (server errors)
 * @author Ludora Team
 *
 * Split from no-direct-error-response for incremental cleanup of server errors (500-599)
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce throw generateError() for 5xx (server) errors',
      category: 'Error Handling',
      recommended: true
    },
    messages: {
      useGenerateError: 'Use throw generateError() for 5xx server error instead of res.status({{status}}).json()'
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

            // Check if it's a 5xx status code
            if (statusCode && statusCode >= 500 && statusCode < 600) {
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

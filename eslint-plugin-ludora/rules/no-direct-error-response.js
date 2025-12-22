/**
 * @fileoverview Detect direct error responses instead of throw generateError()
 * @author Ludora Team
 *
 * Detects: res.status(XXX).json({ error: ... })
 * Should be: throw generateError('ERROR_KEY', errorNumber, { lang })
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce throw generateError() over res.status().json()',
      category: 'Error Handling',
      recommended: true
    },
    messages: {
      useGenerateError: 'Use throw generateError() instead of res.status({{status}}).json(). Direct error responses bypass centralized error handling.'
    },
    schema: [{
      type: 'object',
      properties: {
        statusCodeRange: {
          type: 'string',
          enum: ['4xx', '5xx', 'all'],
          default: 'all'
        }
      },
      additionalProperties: false
    }]
  },

  create(context) {
    const options = context.options[0] || {};
    const statusCodeRange = options.statusCodeRange || 'all';

    const filename = context.getFilename();

    // Allow in error handler middleware and tests
    if (filename.includes('errorHandler') ||
        filename.includes('.test.') ||
        filename.includes('/migrations/')) {
      return {};
    }

    function shouldCheckStatus(statusCode) {
      if (statusCodeRange === 'all') return true;
      if (statusCodeRange === '4xx') return statusCode >= 400 && statusCode < 500;
      if (statusCodeRange === '5xx') return statusCode >= 500 && statusCode < 600;
      return false;
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

            // Check if we should flag this status code range
            if (statusCode && shouldCheckStatus(statusCode)) {
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

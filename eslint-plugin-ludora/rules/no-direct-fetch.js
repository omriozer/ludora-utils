/**
 * @fileoverview Require apiRequest/apiClient instead of direct fetch()
 * @author Ludora Team
 *
 * CRITICAL: Direct fetch() bypasses authentication, error handling, and interceptors
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Require apiRequest() instead of fetch() for API calls',
      category: 'Best Practices',
      recommended: true
    },
    messages: {
      useApiRequest: 'Use apiRequest() instead of fetch(). Direct fetch bypasses authentication headers and error handling.'
    },
    schema: []
  },

  create(context) {
    const filename = context.getFilename();

    // Allow in specific files
    if (filename.includes('publicApis.js') || // External API calls
        filename.includes('apiClient.js') || // API client implementation itself
        filename.includes('.test.') ||
        filename.includes('cypress/')) {
      return {};
    }

    return {
      CallExpression(node) {
        // Check for fetch() calls
        if (node.callee.type === 'Identifier' && node.callee.name === 'fetch') {
          const firstArg = node.arguments[0];

          // Allow external URLs (non-Ludora APIs)
          if (firstArg && firstArg.type === 'Literal') {
            const url = firstArg.value;
            // Allow external domains
            if (typeof url === 'string' && url.startsWith('http') && !url.includes('ludora')) {
              // Check if it's truly external
              const externalDomains = ['data.gov.il', 'api.external.com'];
              if (externalDomains.some(domain => url.includes(domain))) {
                return;
              }
            }
          }

          // Flag all other fetch() calls
          context.report({
            node,
            messageId: 'useApiRequest'
          });
        }
      }
    };
  }
};

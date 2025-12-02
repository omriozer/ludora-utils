/**
 * ESLint Rule: no-console-log
 * Enforces using clog/cerror instead of console.log/console.error
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce using clog/cerror instead of console.log/console.error',
      category: 'Best Practices',
      recommended: true
    },
    messages: {
      useClLog: 'Use clog() instead of console.log() for consistent logging.',
      useCerror: 'Use cerror() instead of console.error() for consistent error logging.',
      useClWarn: 'Use clog() instead of console.warn() for consistent warning logging.',
      useClInfo: 'Use clog() instead of console.info() for consistent info logging.',
      useClDebug: 'Use clog() instead of console.debug() for consistent debug logging.',
      avoidConsoleTable: 'Avoid console.table(). Use clog() with formatted output instead.',
      avoidConsoleDir: 'Avoid console.dir(). Use clog() with JSON.stringify() instead.',
      debugTagRequired: 'Debug logs should include task tag comment: // TODO remove debug - [task title]'
    },
    fixable: 'code',
    schema: [
      {
        type: 'object',
        properties: {
          allowInTests: {
            type: 'boolean',
            default: true
          },
          allowInMigrations: {
            type: 'boolean',
            default: true
          }
        },
        additionalProperties: false
      }
    ]
  },

  create(context) {
    const options = context.options[0] || {};
    const allowInTests = options.allowInTests !== false;
    const allowInMigrations = options.allowInMigrations !== false;

    // Check if we're in a test or migration file
    const filename = context.getFilename ? context.getFilename() :
                    context.filename || '';
    const isTestFile = filename.includes('.test.') ||
                      filename.includes('.spec.') ||
                      filename.includes('__tests__');
    const isMigrationFile = filename.includes('/migrations/') ||
                           filename.includes('-migration.js');

    // Skip if allowed in current file type
    if ((isTestFile && allowInTests) ||
        (isMigrationFile && allowInMigrations)) {
      return {};
    }

    return {
      // Check console.* method calls
      CallExpression(node) {
        if (node.callee.type !== 'MemberExpression') return;
        if (node.callee.object.name !== 'console') return;

        const method = node.callee.property.name;
        const args = node.arguments;

        // Get source code for fix
        const sourceCode = context.getSourceCode();
        const argsText = args.map(arg => sourceCode.getText(arg)).join(', ');

        switch (method) {
          case 'log':
            context.report({
              node,
              messageId: 'useClLog',
              fix(fixer) {
                return fixer.replaceText(node, `clog(${argsText})`);
              }
            });
            break;

          case 'error':
            context.report({
              node,
              messageId: 'useCerror',
              fix(fixer) {
                return fixer.replaceText(node, `cerror(${argsText})`);
              }
            });
            break;

          case 'warn':
            context.report({
              node,
              messageId: 'useClWarn',
              fix(fixer) {
                return fixer.replaceText(node, `clog('[WARN]', ${argsText})`);
              }
            });
            break;

          case 'info':
            context.report({
              node,
              messageId: 'useClInfo',
              fix(fixer) {
                return fixer.replaceText(node, `clog('[INFO]', ${argsText})`);
              }
            });
            break;

          case 'debug':
            context.report({
              node,
              messageId: 'useClDebug',
              fix(fixer) {
                return fixer.replaceText(node, `clog('[DEBUG]', ${argsText})`);
              }
            });
            break;

          case 'table':
            context.report({
              node,
              messageId: 'avoidConsoleTable',
              fix(fixer) {
                return fixer.replaceText(node, `clog('Table data:', ${argsText})`);
              }
            });
            break;

          case 'dir':
            context.report({
              node,
              messageId: 'avoidConsoleDir',
              fix(fixer) {
                const objArg = args[0] ? sourceCode.getText(args[0]) : 'undefined';
                return fixer.replaceText(node,
                  `clog('Object:', JSON.stringify(${objArg}, null, 2))`);
              }
            });
            break;
        }
      },

      // Check clog/cerror calls for debug tagging
      CallExpression(node) {
        if (node.callee.type !== 'Identifier') return;

        const functionName = node.callee.name;
        if (functionName !== 'clog' && functionName !== 'cerror') return;

        // Check if there's a TODO comment on the same line or line above
        const sourceCode = context.getSourceCode();
        const comments = sourceCode.getCommentsBefore(node);

        // Also check inline comments
        const lineOfNode = node.loc.start.line;
        const tokensOnLine = sourceCode.getTokens(node, {
          filter: token => token.loc.start.line === lineOfNode
        });

        let hasDebugTag = false;

        // Check comments before the statement
        for (const comment of comments) {
          if (comment.loc.end.line >= lineOfNode - 1) {
            const commentText = comment.value.toLowerCase();
            if (commentText.includes('todo remove debug')) {
              hasDebugTag = true;
              break;
            }
          }
        }

        // Check if this might be a debug log (heuristic)
        if (!hasDebugTag && node.arguments.length > 0) {
          const firstArg = node.arguments[0];
          const argText = sourceCode.getText(firstArg);

          // Common debug log patterns
          const debugPatterns = [
            'debug:',
            'test:',
            'checking',
            'entering',
            'exiting',
            'value:',
            'data:',
            'result:',
            'response:',
            'request:',
            'state:',
            'props:',
            'params:'
          ];

          const looksLikeDebug = debugPatterns.some(pattern =>
            argText.toLowerCase().includes(pattern)
          );

          // Skip system logs (logs that are meant to stay)
          const systemPatterns = [
            'error',
            'successfully',
            'completed',
            'failed',
            'started',
            'listening',
            'connected',
            'disconnected'
          ];

          const looksLikeSystemLog = systemPatterns.some(pattern =>
            argText.toLowerCase().includes(pattern)
          );

          if (looksLikeDebug && !looksLikeSystemLog) {
            context.report({
              node,
              messageId: 'debugTagRequired',
              fix(fixer) {
                // Add TODO comment before the log
                const lineStart = sourceCode.lines[lineOfNode - 1];
                const indent = lineStart.match(/^\s*/)[0];
                return fixer.insertTextBefore(node,
                  `// TODO remove debug - [task title]\n${indent}`);
              }
            });
          }
        }
      }
    };
  }
};
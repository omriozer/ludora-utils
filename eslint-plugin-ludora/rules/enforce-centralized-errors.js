/**
 * @fileoverview Rule to enforce centralized error handling patterns
 * @author Ludora Team
 *
 * This rule detects old error handling patterns and enforces the new centralized system:
 * - Detects direct res.status().json() instead of throw generateError()
 * - Detects throw new Error() instead of generateError()
 * - Detects routes not wrapped with asyncHandler
 * - Shows warnings for existing code, errors for new code (based on git diff)
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce centralized error handling patterns',
      category: 'Best Practices',
      recommended: true,
    },
    // Auto-fix disabled: error handling migration is too complex for automated fixes
    // fixable: 'code',
    schema: [
      {
        type: 'object',
        properties: {
          allowInTests: {
            type: 'boolean',
            default: true,
          },
          allowInMigrations: {
            type: 'boolean',
            default: true,
          },
          mode: {
            type: 'string',
            enum: ['strict', 'migration'],
            default: 'migration',
          },
        },
        additionalProperties: false,
      },
    ],
    messages: {
      useGenerateError: 'Use generateError() instead of {{method}}. Import from "../lib/errors/apiError.js"',
      useAsyncHandler: 'Wrap route handler with asyncHandler() for centralized error handling',
      noDirectResponse: 'Never use res.status().json() for errors. Use "throw generateError()" instead',
      noThrowError: 'Use generateError() instead of throwing plain Error',
      importRequired: 'Import {{import}} from "{{path}}"',
      migrationWarning: '[MIGRATION] Old error pattern detected. This should be updated to use centralized error handling',
    },
  },

  create(context) {
    const options = context.options[0] || {};
    const mode = options.mode || 'migration';
    const allowInTests = options.allowInTests !== false;
    const allowInMigrations = options.allowInMigrations !== false;
    const sourceCode = context.getSourceCode();
    const filename = context.getFilename();

    // Check if file should be ignored
    if (
      (allowInTests && /\.(test|spec)\.js$/.test(filename)) ||
      (allowInTests && filename.includes('/tests/')) ||
      (allowInMigrations && filename.includes('/migrations/'))
    ) {
      return {};
    }

    // Check if this is a new/modified file (for strict mode on new code)
    let isNewOrModified = false;
    try {
      const gitStatus = execSync('git status --porcelain', { encoding: 'utf-8' });
      const relativePath = path.relative(process.cwd(), filename);
      isNewOrModified = gitStatus.includes(relativePath);
    } catch (e) {
      // If git check fails, treat as existing file
      isNewOrModified = false;
    }

    // Determine severity based on mode and file status
    const getSeverity = () => {
      if (mode === 'strict') return 'error';
      if (mode === 'migration') {
        return isNewOrModified ? 'error' : 'warn';
      }
      return 'warn';
    };

    // Track imports in the file
    let hasGenerateErrorImport = false;
    let hasAsyncHandlerImport = false;

    // Check for existing imports
    const checkImports = (node) => {
      const source = node.source?.value || '';
      if (source.includes('apiError')) {
        const specifiers = node.specifiers || [];
        hasGenerateErrorImport = specifiers.some(
          spec => spec.imported?.name === 'generateError' || spec.local?.name === 'generateError'
        );
      }
      if (source.includes('errorHandler')) {
        const specifiers = node.specifiers || [];
        hasAsyncHandlerImport = specifiers.some(
          spec => spec.imported?.name === 'asyncHandler' || spec.local?.name === 'asyncHandler'
        );
      }
    };

    return {
      ImportDeclaration: checkImports,

      // Detect res.status().json() pattern
      CallExpression(node) {
        // Check for res.status().json() or res.status().send()
        if (
          node.callee.type === 'MemberExpression' &&
          (node.callee.property.name === 'json' ||
           node.callee.property.name === 'send')
        ) {
          const object = node.callee.object;
          if (
            object &&
            object.type === 'CallExpression' &&
            object.callee.type === 'MemberExpression' &&
            object.callee.property.name === 'status' &&
            object.callee.object.name === 'res'
          ) {
            // Check if this is an error response (status >= 400)
            const statusArg = object.arguments[0];
            if (statusArg && statusArg.type === 'Literal' && statusArg.value >= 400) {
              const messageId = getSeverity() === 'warn' ? 'migrationWarning' : 'noDirectResponse';

              context.report({
                node,
                messageId
              });
            }
          }
        }

        // Detect throw new Error() pattern
        if (
          node.type === 'NewExpression' &&
          node.callee.name === 'Error' &&
          node.parent &&
          node.parent.type === 'ThrowStatement'
        ) {
          const messageId = getSeverity() === 'warn' ? 'migrationWarning' : 'noThrowError';

          context.report({
            node: node.parent,
            messageId
          });
        }

        // Detect Express route handlers without asyncHandler
        if (
          (node.callee.type === 'MemberExpression' &&
           node.callee.object.name === 'router' &&
           ['get', 'post', 'put', 'patch', 'delete', 'all', 'use'].includes(node.callee.property.name)) ||
          (node.callee.type === 'MemberExpression' &&
           node.callee.object.name === 'app' &&
           ['get', 'post', 'put', 'patch', 'delete', 'all', 'use'].includes(node.callee.property.name))
        ) {
          const args = node.arguments;

          // Find the handler function(s) - could be after middleware
          for (let i = 0; i < args.length; i++) {
            const arg = args[i];

            // Check if it's an async function that's not wrapped in asyncHandler
            if (
              arg &&
              (arg.type === 'ArrowFunctionExpression' || arg.type === 'FunctionExpression') &&
              arg.async &&
              !(arg.parent && arg.parent.type === 'CallExpression' && arg.parent.callee.name === 'asyncHandler')
            ) {
              // Check if this handler has a try-catch block
              let hasTryCatch = false;
              if (arg.body && arg.body.type === 'BlockStatement') {
                hasTryCatch = arg.body.body.some(statement => statement.type === 'TryStatement');
              }

              // Only report if there's a try-catch (indicating error handling)
              if (hasTryCatch) {
                const messageId = getSeverity() === 'warn' ? 'migrationWarning' : 'useAsyncHandler';

                context.report({
                  node: arg,
                  messageId
                });
              }
            }
          }
        }
      },

      // Add import suggestions at the end of the program
      'Program:exit'() {
        // Check if we need to suggest imports
        const firstNode = sourceCode.ast.body[0];
        if (!firstNode) return;

        if (!hasGenerateErrorImport && sourceCode.getText().includes('generateError')) {
          context.report({
            node: firstNode,
            messageId: 'importRequired',
            data: {
              import: 'generateError',
              path: '../lib/errors/apiError.js',
            }
          });
        }

        if (!hasAsyncHandlerImport && sourceCode.getText().includes('asyncHandler')) {
          context.report({
            node: firstNode,
            messageId: 'importRequired',
            data: {
              import: 'asyncHandler',
              path: '../middleware/errorHandler.js',
            }
          });
        }
      },
    };
  },
};
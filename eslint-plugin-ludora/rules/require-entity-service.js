/**
 * @fileoverview Require EntityService usage for product entity operations
 * @author Ludora Team
 *
 * CRITICAL: Bypassing EntityService breaks Product/Entity relationship integrity
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Require EntityService for Game/Level/Presentation operations',
      category: 'Architecture',
      recommended: true
    },
    messages: {
      useEntityService: 'Use EntityService.{{method}}() instead of direct model.{{entity}}.{{operation}}(). Direct operations bypass Product table and break ownership tracking.'
    },
    schema: []
  },

  create(context) {
    const filename = context.getFilename();

    // Allow in EntityService itself and migrations
    if (filename.includes('EntityService') || filename.includes('/migrations/')) {
      return {};
    }

    const PRODUCT_ENTITIES = ['Game', 'Level', 'Presentation'];
    // Only restrict WRITE operations - reads are OK for validation purposes
    const RESTRICTED_OPERATIONS = ['create', 'destroy', 'update', 'bulkCreate'];

    return {
      CallExpression(node) {
        // Check for models.{Entity}.{operation}() pattern
        if (node.callee.type === 'MemberExpression') {
          const method = node.callee.property.name;

          // Check if it's a restricted operation
          if (RESTRICTED_OPERATIONS.includes(method)) {
            const object = node.callee.object;

            // Check if it's models.Game/Level/Presentation
            if (object.type === 'MemberExpression' &&
                object.object.type === 'Identifier' &&
                object.object.name === 'models' &&
                PRODUCT_ENTITIES.includes(object.property.name)) {

              const entityName = object.property.name;

              // Map operation to EntityService method
              let entityServiceMethod;
              switch (method) {
                case 'create':
                  entityServiceMethod = 'create';
                  break;
                case 'destroy':
                  entityServiceMethod = 'delete';
                  break;
                case 'update':
                  entityServiceMethod = 'update';
                  break;
                case 'findAll':
                case 'findOne':
                case 'findByPk':
                  entityServiceMethod = 'get/query';
                  break;
                default:
                  entityServiceMethod = method;
              }

              context.report({
                node,
                messageId: 'useEntityService',
                data: {
                  entity: entityName,
                  operation: method,
                  method: entityServiceMethod
                }
              });
            }
          }
        }
      }
    };
  }
};

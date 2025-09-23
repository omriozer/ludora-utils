# AI Todo System Instructions

## Overview
This document contains instructions for using the AI todo workflow system for the Ludora project. This system helps track progress on complex tasks and ensures all requirements are completed systematically.

## Todo System Structure

### Directory Organization
- `/docs/ai-todos/` - General project-wide tasks
- `/ludora-api/docs/ai-todos/` - Backend-specific tasks
- `/ludora-front/docs/ai-todos/` - Frontend-specific tasks

### File Naming Convention
- Use descriptive kebab-case names: `feature-name-implementation.md`
- Include status in filename for easy identification: `admin-documentation-button.md`
- Use present tense for active tasks: `implementing-user-auth.md`
- Use past tense for completed tasks: `admin-documentation-button-completed.md`

## Todo File Template

```markdown
# Task Title - Status

## Context
Brief description of what needs to be done and why

## Current Status: [Implementation Complete/In Progress/Pending]

### ✅ Completed Tasks:
- [x] Specific completed item
- [x] Another completed item

### 🔄 In Progress:
- [ ] Current task being worked on

### ⏳ Pending:
- [ ] Future task to be done
- [ ] Another future task

## Technical Implementation Details

### Files Modified/Created:
1. **`/path/to/file.jsx`**:
   - Description of changes made
   - Key features added

2. **`/path/to/another/file.js`**:
   - More changes described

### Code Examples:
```javascript
// Key code snippets for reference
```

## User Flow
Step-by-step description of how the feature works from user perspective

## Features
List of specific features implemented

## Access Control
Security considerations and access restrictions

## Next Steps (Optional)
- [ ] Future enhancements
- [ ] Optional improvements
```

## When to Use Todo System

### Use TodoWrite Tool When:
1. **Complex multi-step tasks** - When a task requires 3 or more distinct steps
2. **Non-trivial and complex tasks** - Tasks requiring careful planning or multiple operations
3. **User explicitly requests todo list** - When user directly asks for todo tracking
4. **User provides multiple tasks** - When users provide numbered or comma-separated lists
5. **After receiving new instructions** - Immediately capture user requirements as todos
6. **Starting work on a task** - Mark as in_progress BEFORE beginning work
7. **After completing a task** - Mark as completed and add follow-up tasks

### Do NOT Use TodoWrite Tool When:
1. **Single straightforward task** - Simple one-step operations
2. **Trivial tasks** - Tasks that can be completed in less than 3 simple steps
3. **Purely conversational** - Informational requests or discussions
4. **Quick file reads** - Simple file viewing or searching

## Task States and Management

### Task States:
- **pending**: Task not yet started
- **in_progress**: Currently working on (limit to ONE task at a time)
- **completed**: Task finished successfully

### Task Description Format:
- **content**: Imperative form describing what needs to be done
  - Example: "Run tests", "Build the project"
- **activeForm**: Present continuous form shown during execution
  - Example: "Running tests", "Building the project"

### Management Rules:
1. **Update task status in real-time** as work progresses
2. **Mark tasks complete IMMEDIATELY** after finishing (don't batch completions)
3. **Exactly ONE task in_progress** at any time (not less, not more)
4. **Complete current tasks before starting new ones**
5. **Remove irrelevant tasks** from the list entirely

### Task Completion Requirements:
- **ONLY mark completed when FULLY accomplished**
- **If encountering errors or blockers**, keep as in_progress
- **When blocked, create new task** describing what needs resolution
- **Never mark completed if:**
  - Tests are failing
  - Implementation is partial
  - Unresolved errors encountered
  - Missing necessary files or dependencies

## Best Practices

### Task Breakdown:
- **Create specific, actionable items**
- **Break complex tasks into smaller, manageable steps**
- **Use clear, descriptive task names**
- **Always provide both content and activeForm**

### Documentation Integration:
- **Keep todo files updated** throughout development process
- **Document technical decisions** and implementation details
- **Include code examples** for future reference
- **Maintain user flow descriptions** for feature understanding

### Progress Tracking:
- **Use checkboxes** for subtasks within markdown files
- **Update status sections** as work progresses
- **Add timestamp information** when relevant
- **Include troubleshooting notes** for future reference

## Examples

### Good Todo Usage:
```markdown
User: "Add dark mode toggle to the application settings. Make sure you run the tests and build when you're done!"

Assistant creates todos:
1. Creating dark mode toggle component in Settings page
2. Adding dark mode state management (context/store)
3. Implementing CSS-in-JS styles for dark theme
4. Updating existing components to support theme switching
5. Running tests and build process, addressing any failures
```

### Poor Todo Usage:
```markdown
User: "How do I print 'Hello World' in Python?"
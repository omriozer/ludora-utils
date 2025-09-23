# Git Workflow and Version Control

This document outlines the Git workflow, branching strategy, and version control practices for the Ludora platform.

## Branching Strategy

### Main Branches

**`main`** - Production Branch
- Always deployable to production
- Protected branch requiring pull request reviews
- All commits must pass CI/CD checks
- Direct commits prohibited

**`develop`** - Integration Branch (if used)
- Integration branch for feature development
- Used for staging deployments
- Features merge here before going to main

### Feature Branches

**Naming Convention:**
```
feature/[issue-number]-brief-description
feature/123-add-video-streaming
feature/456-implement-user-roles
feature/789-game-builder-ui
```

**Branch Creation:**
```bash
# Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/123-add-video-streaming
```

### Bug Fix Branches

**Naming Convention:**
```
bugfix/[issue-number]-brief-description
bugfix/321-fix-authentication-loop
bugfix/654-resolve-memory-leak
bugfix/987-correct-hebrew-display
```

### Hotfix Branches

**For urgent production fixes:**
```
hotfix/[issue-number]-brief-description
hotfix/111-security-patch
hotfix/222-payment-gateway-fix
```

**Hotfix Process:**
```bash
# Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/111-security-patch

# Make fixes and commit
git add .
git commit -m "fix(security): patch authentication vulnerability"

# Merge to main immediately
git checkout main
git merge hotfix/111-security-patch
git push origin main

# Also merge to develop if it exists
git checkout develop
git merge hotfix/111-security-patch
git push origin develop

# Delete hotfix branch
git branch -d hotfix/111-security-patch
git push origin --delete hotfix/111-security-patch
```

## Commit Message Standards

### Conventional Commits Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types
- `feat` - New feature implementation
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, missing semicolons, etc.)
- `refactor` - Code refactoring without feature changes
- `perf` - Performance improvements
- `test` - Adding or modifying tests
- `chore` - Maintenance tasks, dependency updates
- `ci` - CI/CD configuration changes
- `build` - Build system changes

### Scope Examples
- `auth` - Authentication related changes
- `api` - Backend API changes
- `ui` - Frontend UI components
- `database` - Database schema or query changes
- `games` - Game-related functionality
- `payments` - Payment processing
- `security` - Security-related changes

### Good Commit Examples
```bash
# Feature commits
git commit -m "feat(games): add memory game difficulty settings"
git commit -m "feat(auth): implement password reset flow"
git commit -m "feat(api): add video streaming endpoints"

# Bug fix commits
git commit -m "fix(ui): resolve Hebrew text alignment issues"
git commit -m "fix(auth): prevent duplicate user registration"
git commit -m "fix(games): correct scoring calculation"

# Documentation commits
git commit -m "docs(api): update authentication endpoint documentation"
git commit -m "docs(readme): add development setup instructions"

# Refactoring commits
git commit -m "refactor(database): optimize game content queries"
git commit -m "refactor(ui): extract reusable button component"
```

### Commit Body Guidelines
```bash
# Example with body
git commit -m "feat(payments): integrate PayPlus payment gateway

- Add PayPlus SDK integration
- Implement webhook handler for payment status
- Add payment status tracking in database
- Support both one-time and subscription payments

Closes #123"
```

## Pull Request Process

### Creating Pull Requests

**Before Creating PR:**
1. Ensure your branch is up to date with main
2. Run tests locally and ensure they pass
3. Update documentation if needed
4. Test your changes thoroughly

**Branch Update Process:**
```bash
# Update your feature branch with latest main
git checkout main
git pull origin main
git checkout feature/123-add-video-streaming
git merge main

# Resolve any conflicts
# Run tests
npm test

# Push updated branch
git push origin feature/123-add-video-streaming
```

### Pull Request Template

**Title Format:**
```
[TYPE] Brief description of changes

feat: Add video streaming functionality
fix: Resolve authentication timeout issue
docs: Update API documentation for games
```

**Description Template:**
```markdown
## Description
Brief description of what this PR does and why.

## Changes Made
- [ ] Added new video streaming API endpoints
- [ ] Implemented access control for video content
- [ ] Updated frontend video player component
- [ ] Added tests for video streaming functionality

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Tested on multiple browsers/devices

## Documentation
- [ ] Updated API documentation
- [ ] Updated user documentation
- [ ] Updated architecture documentation
- [ ] No documentation changes needed

## Screenshots (if applicable)
[Include screenshots for UI changes]

## Related Issues
Closes #123
Related to #456

## Checklist
- [ ] Code follows project coding standards
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No console.log statements left in code
- [ ] Security implications considered
```

### Code Review Guidelines

**For Reviewers:**
1. **Functionality**: Does the code work as intended?
2. **Code Quality**: Is the code readable, maintainable, and following standards?
3. **Security**: Are there any security implications?
4. **Performance**: Are there any performance concerns?
5. **Tests**: Are there adequate tests for the changes?
6. **Documentation**: Is documentation updated appropriately?

**Review Comments Format:**
```markdown
# Suggestion
Consider using a more descriptive variable name here:
```javascript
// Instead of 'data'
const gameData = response.data;
```

# Required Change
This could cause a security vulnerability. Please validate the input:
```javascript
const sanitizedTitle = validator.escape(req.body.title);
```

# Question
Why did you choose this approach over using the existing service method?

# Praise
Great error handling implementation here!
```

### Merging Pull Requests

**Merge Requirements:**
- [ ] At least one approval from code owner
- [ ] All CI/CD checks passing
- [ ] No merge conflicts
- [ ] Branch is up to date with target branch

**Merge Options:**
1. **Squash and Merge** (Preferred for feature branches)
   - Combines all commits into one clean commit
   - Use for feature development

2. **Merge Commit**
   - Preserves commit history
   - Use for hotfixes or when commit history is important

3. **Rebase and Merge**
   - Replays commits without merge commit
   - Use when you want linear history

**After Merging:**
```bash
# Delete the feature branch
git branch -d feature/123-add-video-streaming
git push origin --delete feature/123-add-video-streaming

# Update local main
git checkout main
git pull origin main
```

## Release Management

### Version Numbers
Follow Semantic Versioning (SemVer):
```
MAJOR.MINOR.PATCH

1.0.0 - Initial release
1.1.0 - New features, backward compatible
1.1.1 - Bug fixes, backward compatible
2.0.0 - Breaking changes
```

### Release Process

**Preparing for Release:**
```bash
# Create release branch
git checkout main
git pull origin main
git checkout -b release/v1.2.0

# Update version numbers
# Update CHANGELOG.md
# Final testing

# Merge to main
git checkout main
git merge release/v1.2.0

# Tag the release
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin main
git push origin v1.2.0

# Clean up
git branch -d release/v1.2.0
```

### Changelog Management

**Changelog Format:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-01-15

### Added
- Video streaming functionality with access control
- Hebrew language support in games
- Payment integration with PayPlus

### Changed
- Improved game builder UI/UX
- Optimized database queries for better performance

### Fixed
- Authentication timeout issues
- Hebrew text display in RTL mode
- Memory game scoring calculation

### Security
- Fixed authentication vulnerability
- Updated dependencies with security patches

## [1.1.0] - 2024-12-01
...
```

## Best Practices

### Commit Best Practices

**Do:**
- Make atomic commits (one logical change per commit)
- Write clear, descriptive commit messages
- Include issue numbers in commits
- Test changes before committing
- Keep commits focused and small

**Don't:**
- Commit broken code
- Mix unrelated changes in one commit
- Use vague commit messages like "fix stuff"
- Commit secrets or API keys
- Force push to shared branches

### Branch Management

**Keeping Branches Clean:**
```bash
# Regular cleanup of merged branches
git branch --merged main | grep -v main | xargs git branch -d

# List remote branches that have been deleted
git remote prune origin

# Interactive rebase to clean up commits before PR
git rebase -i HEAD~3
```

**Long-Running Feature Branches:**
```bash
# Regularly sync with main to avoid large conflicts
git checkout feature/long-running-feature
git fetch origin
git merge origin/main

# Or use rebase for cleaner history
git rebase origin/main
```

### Conflict Resolution

**Merge Conflict Resolution:**
```bash
# When conflicts occur during merge
git merge main
# Auto-merging file.js
# CONFLICT (content): Merge conflict in file.js

# Edit conflicted files
# Remove conflict markers (<<<<<<<, =======, >>>>>>>)
# Keep the correct code

# Stage resolved files
git add file.js

# Complete the merge
git commit -m "resolve merge conflicts with main"
```

**Preventing Conflicts:**
- Keep feature branches short-lived
- Regularly sync with main branch
- Communicate with team about overlapping work
- Use clear, descriptive variable names

### Git Configuration

**Recommended Git Configuration:**
```bash
# Set up user information
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch name
git config --global init.defaultBranch main

# Enable helpful colors
git config --global color.ui auto

# Set up better diff algorithm
git config --global diff.algorithm patience

# Set up pull strategy
git config --global pull.rebase false

# Set up default push behavior
git config --global push.default simple

# Set up helpful aliases
git config --global alias.st status
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# Set up editor (example with VS Code)
git config --global core.editor "code --wait"
```

## Troubleshooting Common Issues

### Undoing Changes

**Undo Last Commit (not pushed):**
```bash
# Keep changes in working directory
git reset --soft HEAD~1

# Remove changes completely
git reset --hard HEAD~1
```

**Undo Pushed Commit:**
```bash
# Create revert commit
git revert HEAD

# For merge commits
git revert -m 1 HEAD
```

**Recover Deleted Branch:**
```bash
# Find the commit hash
git reflog

# Recreate branch
git checkout -b recovered-branch <commit-hash>
```

### Large Files and Repository Cleanup

**Remove Large Files from History:**
```bash
# Use git filter-branch (be very careful)
git filter-branch --tree-filter 'rm -f large-file.zip' HEAD

# Or use BFG Repo-Cleaner (recommended)
bfg --delete-files large-file.zip
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

**Repository Size Management:**
- Use `.gitignore` for build artifacts, dependencies
- Use Git LFS for large binary files
- Regular cleanup of old branches
- Avoid committing large files

This Git workflow ensures clean, traceable development process while maintaining code quality and collaboration efficiency.
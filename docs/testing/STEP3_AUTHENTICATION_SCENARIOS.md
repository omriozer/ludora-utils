# Step 3: Authentication Scenarios

> **Parent Document**: `UI_TESTING_IMPLEMENTATION.md`
> **Status**: NOT_STARTED
> **Priority**: CRITICAL - Foundation for all user interactions

## Overview

Implement comprehensive authentication test scenarios for the Ludora platform using Firebase authentication. These tests validate user registration, login, logout, session management, and role-based permissions - critical functionality that enables all other user interactions.

## Objectives

1. **Firebase Authentication Integration** with Cypress test environment
2. **User Registration Flows** including email verification
3. **Login/Logout Workflows** with session management
4. **Permission Testing** for user roles and admin access
5. **Error Handling** for authentication failures

## Authentication Architecture Analysis

### Current Implementation Review
- **Firebase Project**: `ludora-af706` (development)
- **Authentication Methods**: Email/password with email verification
- **User Roles**: `user`, `admin`, `content_creator`
- **Session Management**: JWT tokens with Firebase ID tokens
- **Route Protection**: `ProtectedRoute`, `AdminRoute`, `ConditionalRoute` components

### Test Environment Considerations
- **Firebase Test Config**: Use development Firebase project
- **Test Users**: Pre-created accounts for consistent testing
- **Email Verification**: Handle verification in test environment
- **Token Management**: Store and reuse authentication tokens

## Test Scenarios Implementation

### Authentication Test Cases

#### AUTH-001: User Registration Flow
```javascript
// cypress/e2e/auth/registration.cy.js
import { RegistrationPage } from '../../support/page-objects/RegistrationPage'

describe('Authentication - User Registration', () => {
  const registrationPage = new RegistrationPage()

  beforeEach(() => {
    cy.task('cleanupTestUsers')
    registrationPage.visit()
  })

  it('AUTH-001 should successfully register new user with valid data', () => {
    cy.fixture('users').then((users) => {
      const newUser = {
        ...users.validUser,
        email: `test-${Date.now()}@ludora.app` // Unique email
      }

      // Arrange: Prepare registration form
      registrationPage.verifyFormVisible()

      // Act: Fill and submit registration
      registrationPage
        .fillForm(newUser)
        .acceptTerms()
        .submit()

      // Assert: Verify registration success
      cy.verifyToast('הרשמה הושלמה בהצלחה') // Hebrew: Registration completed successfully
      cy.verifyEmailVerificationSent(newUser.email)

      // Verify user created in database
      cy.verifyUserCreated({
        email: newUser.email,
        role: 'user',
        emailVerified: false
      })
    })
  })

  it('AUTH-002 should reject registration with invalid email format', () => {
    const invalidUser = {
      email: 'invalid-email-format',
      password: 'ValidPassword123!',
      fullName: 'Test User'
    }

    registrationPage
      .fillForm(invalidUser)
      .submit()

    registrationPage.verifyError('כתובת אימייל לא תקינה') // Hebrew: Invalid email address
    cy.url().should('include', '/registration') // Should stay on registration page
  })

  it('AUTH-003 should require strong password', () => {
    const weakPasswordUser = {
      email: 'test@ludora.app',
      password: '123', // Weak password
      fullName: 'Test User'
    }

    registrationPage
      .fillForm(weakPasswordUser)
      .submit()

    registrationPage.verifyError('סיסמה חייבת להכיל לפחות 8 תווים') // Hebrew: Password must contain at least 8 characters
  })

  it('AUTH-004 should prevent duplicate email registration', () => {
    cy.fixture('users').then((users) => {
      const existingUser = users.testUser

      registrationPage
        .fillForm(existingUser)
        .submit()

      registrationPage.verifyError('כתובת אימייל זו כבר רשומה במערכת') // Hebrew: This email is already registered
    })
  })
})
```

#### AUTH-005: User Login Flow
```javascript
// cypress/e2e/auth/login.cy.js
import { LoginPage } from '../../support/page-objects/LoginPage'
import { DashboardPage } from '../../support/page-objects/DashboardPage'

describe('Authentication - User Login', () => {
  const loginPage = new LoginPage()
  const dashboardPage = new DashboardPage()

  beforeEach(() => {
    cy.clearLocalStorage()
    cy.clearCookies()
  })

  it('AUTH-005 should successfully login with valid credentials', () => {
    cy.fixture('users').then((users) => {
      const validUser = users.testUser

      // Arrange: Navigate to login
      loginPage.visit()

      // Act: Perform login
      loginPage
        .fillCredentials(validUser.email, validUser.password)
        .submit()

      // Assert: Verify successful login
      cy.verifyToast('התחברות בוצעה בהצלחה') // Hebrew: Login successful
      cy.verifyRedirectTo('/dashboard')

      // Verify user session established
      cy.verifyUserLoggedIn(validUser.email)
      cy.verifyAuthToken()

      // Verify dashboard loads correctly
      dashboardPage.verifyWelcomeMessage(validUser.fullName)
    })
  })

  it('AUTH-006 should reject invalid credentials', () => {
    const invalidCredentials = {
      email: 'nonexistent@ludora.app',
      password: 'WrongPassword123!'
    }

    loginPage
      .visit()
      .fillCredentials(invalidCredentials.email, invalidCredentials.password)
      .submit()

    loginPage.verifyError('שם משתמש או סיסמה שגויים') // Hebrew: Wrong username or password
    cy.url().should('include', '/') // Should stay on home/login page
    cy.verifyUserNotLoggedIn()
  })

  it('AUTH-007 should handle Firebase authentication errors', () => {
    // Mock Firebase error
    cy.intercept('POST', '**/identitytoolkit.googleapis.com/**', {
      statusCode: 400,
      body: { error: { message: 'INVALID_PASSWORD' } }
    }).as('firebaseError')

    cy.fixture('users').then((users) => {
      loginPage
        .visit()
        .fillCredentials(users.testUser.email, 'wrongpassword')
        .submit()

      cy.wait('@firebaseError')
      loginPage.verifyError('סיסמה שגויה') // Hebrew: Wrong password
    })
  })
})
```

#### AUTH-008: Session Management
```javascript
// cypress/e2e/auth/session-management.cy.js
describe('Authentication - Session Management', () => {
  beforeEach(() => {
    cy.loginAsUser() // Custom command to log in
  })

  it('AUTH-008 should maintain session across page reloads', () => {
    // Verify logged in state
    cy.verifyUserLoggedIn()

    // Reload page
    cy.reload()

    // Verify session persisted
    cy.verifyUserLoggedIn()
    cy.url().should('include', '/dashboard')
  })

  it('AUTH-009 should refresh token automatically', () => {
    // Mock token expiration
    cy.mockTokenExpiration()

    // Navigate to protected route
    cy.visit('/products')

    // Verify token refresh occurred
    cy.verifyTokenRefreshed()
    cy.verifyPageLoaded()
  })

  it('AUTH-010 should logout successfully', () => {
    // Perform logout
    cy.logout()

    // Verify logout effects
    cy.verifyUserLoggedOut()
    cy.verifyRedirectTo('/')
    cy.verifyAuthTokenCleared()

    // Verify protected routes inaccessible
    cy.visit('/dashboard')
    cy.verifyRedirectTo('/') // Should redirect to home
  })
})
```

#### AUTH-011: Admin Permissions
```javascript
// cypress/e2e/auth/admin-permissions.cy.js
describe('Authentication - Admin Permissions', () => {
  it('AUTH-011 should grant admin access to admin user', () => {
    cy.loginAsAdmin()

    // Verify admin dashboard access
    cy.visit('/admin')
    cy.verifyPageLoaded()
    cy.verifyAdminNavigation()

    // Test admin-only features
    cy.visit('/users')
    cy.verifyUserManagementAccess()

    cy.visit('/system-settings')
    cy.verifySystemSettingsAccess()
  })

  it('AUTH-012 should deny admin access to regular user', () => {
    cy.loginAsUser()

    // Attempt to access admin routes
    cy.visit('/admin')
    cy.verifyAccessDenied()
    cy.verifyRedirectTo('/dashboard')

    cy.visit('/users')
    cy.verifyAccessDenied()

    // Verify error message
    cy.verifyToast('אין לך הרשאה לגשת לעמוד זה') // Hebrew: You don't have permission to access this page
  })

  it('AUTH-013 should validate role-based route access', () => {
    const protectedRoutes = [
      { path: '/admin', requiredRole: 'admin' },
      { path: '/users', requiredRole: 'admin' },
      { path: '/coupons', requiredRole: 'admin' },
      { path: '/system-settings', requiredRole: 'admin' }
    ]

    cy.loginAsUser()

    protectedRoutes.forEach(route => {
      cy.visit(route.path)
      cy.verifyAccessDenied()
      cy.verifyRedirectTo('/dashboard')
    })
  })
})
```

### Custom Authentication Commands

#### Authentication Helper Commands
```javascript
// cypress/support/commands.js - Authentication commands

// Login as different user types
Cypress.Commands.add('loginAsUser', () => {
  cy.fixture('users').then((users) => {
    cy.login(users.testUser.email, users.testUser.password)
  })
})

Cypress.Commands.add('loginAsAdmin', () => {
  cy.fixture('users').then((users) => {
    cy.login(users.adminUser.email, users.adminUser.password)
  })
})

// Core login command
Cypress.Commands.add('login', (email, password) => {
  cy.session([email, password], () => {
    cy.visit('/')
    cy.get('[data-testid="email-input"]').type(email)
    cy.get('[data-testid="password-input"]').type(password)
    cy.get('[data-testid="login-button"]').click()
    cy.url().should('include', '/dashboard')
    cy.getCookie('authToken').should('exist')
  })
})

// Logout command
Cypress.Commands.add('logout', () => {
  cy.get('[data-testid="user-menu"]').click()
  cy.get('[data-testid="logout-button"]').click()
  cy.url().should('not.include', '/dashboard')
})

// Verification commands
Cypress.Commands.add('verifyUserLoggedIn', (email) => {
  cy.window().its('localStorage').invoke('getItem', 'authToken').should('exist')
  if (email) {
    cy.window().its('localStorage').invoke('getItem', 'userEmail').should('equal', email)
  }
})

Cypress.Commands.add('verifyUserLoggedOut', () => {
  cy.window().its('localStorage').invoke('getItem', 'authToken').should('not.exist')
  cy.window().its('localStorage').invoke('getItem', 'userEmail').should('not.exist')
})

Cypress.Commands.add('verifyAuthToken', () => {
  cy.window().its('localStorage').invoke('getItem', 'authToken')
    .should('exist')
    .and('not.be.empty')
    .then((token) => {
      // Verify token format (JWT)
      expect(token).to.match(/^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$/)
    })
})

// Test data management
Cypress.Commands.add('verifyUserCreated', (userData) => {
  cy.task('db:findUser', { email: userData.email }).then((user) => {
    expect(user).to.exist
    expect(user.email).to.equal(userData.email)
    expect(user.role).to.equal(userData.role)
  })
})

Cypress.Commands.add('verifyEmailVerificationSent', (email) => {
  // In test environment, we might mock email service
  cy.task('mockEmail:verify', { email }).should('equal', true)
})
```

### Page Objects for Authentication

#### Login Page Object
```javascript
// cypress/support/page-objects/LoginPage.js
export class LoginPage {
  constructor() {
    this.url = '/'
    this.selectors = {
      emailInput: '[data-testid="email-input"]',
      passwordInput: '[data-testid="password-input"]',
      loginButton: '[data-testid="login-button"]',
      errorMessage: '[data-testid="error-message"]',
      forgotPasswordLink: '[data-testid="forgot-password-link"]'
    }
  }

  visit() {
    cy.visit(this.url)
    return this
  }

  fillCredentials(email, password) {
    cy.get(this.selectors.emailInput).clear().type(email)
    cy.get(this.selectors.passwordInput).clear().type(password)
    return this
  }

  submit() {
    cy.get(this.selectors.loginButton).click()
    return this
  }

  verifyError(expectedMessage) {
    cy.get(this.selectors.errorMessage).should('contain', expectedMessage)
    return this
  }

  clickForgotPassword() {
    cy.get(this.selectors.forgotPasswordLink).click()
    return this
  }
}
```

#### Registration Page Object
```javascript
// cypress/support/page-objects/RegistrationPage.js
export class RegistrationPage {
  constructor() {
    this.url = '/registration'
    this.selectors = {
      emailInput: '[data-testid="email-input"]',
      passwordInput: '[data-testid="password-input"]',
      fullNameInput: '[data-testid="fullname-input"]',
      termsCheckbox: '[data-testid="terms-checkbox"]',
      submitButton: '[data-testid="submit-registration"]',
      errorMessage: '[data-testid="error-message"]',
      successMessage: '[data-testid="success-message"]'
    }
  }

  visit() {
    cy.visit(this.url)
    return this
  }

  verifyFormVisible() {
    cy.get(this.selectors.emailInput).should('be.visible')
    cy.get(this.selectors.passwordInput).should('be.visible')
    cy.get(this.selectors.fullNameInput).should('be.visible')
    return this
  }

  fillForm(userData) {
    cy.get(this.selectors.emailInput).clear().type(userData.email)
    cy.get(this.selectors.passwordInput).clear().type(userData.password)
    cy.get(this.selectors.fullNameInput).clear().type(userData.fullName)
    return this
  }

  acceptTerms() {
    cy.get(this.selectors.termsCheckbox).check()
    return this
  }

  submit() {
    cy.get(this.selectors.submitButton).click()
    return this
  }

  verifyError(expectedMessage) {
    cy.get(this.selectors.errorMessage).should('contain', expectedMessage)
    return this
  }

  verifySuccess() {
    cy.get(this.selectors.successMessage).should('be.visible')
    return this
  }
}
```

### Test Data for Authentication

#### User Fixtures
```json
// cypress/fixtures/users.json
{
  "testUser": {
    "email": "test@ludora.app",
    "password": "TestPassword123!",
    "fullName": "Test User",
    "role": "user",
    "active": true,
    "emailVerified": true
  },
  "adminUser": {
    "email": "admin@ludora.app",
    "password": "AdminPassword123!",
    "fullName": "Admin User",
    "role": "admin",
    "active": true,
    "emailVerified": true
  },
  "contentCreator": {
    "email": "creator@ludora.app",
    "password": "CreatorPassword123!",
    "fullName": "Content Creator",
    "role": "content_creator",
    "active": true,
    "emailVerified": true
  },
  "inactiveUser": {
    "email": "inactive@ludora.app",
    "password": "InactivePassword123!",
    "fullName": "Inactive User",
    "role": "user",
    "active": false,
    "emailVerified": true
  }
}
```

## Implementation Priority

### Phase 3.1: Core Authentication (P0 - Critical)
- [ ] User login/logout functionality
- [ ] Session management and persistence
- [ ] Basic error handling

### Phase 3.2: Registration Flows (P1 - High)
- [ ] User registration with validation
- [ ] Email verification process
- [ ] Password strength requirements

### Phase 3.3: Permission Testing (P1 - High)
- [ ] Admin role validation
- [ ] Route protection testing
- [ ] Access control verification

### Phase 3.4: Edge Cases (P2 - Medium)
- [ ] Token expiration handling
- [ ] Network error scenarios
- [ ] Invalid authentication states

## Validation Criteria

### Functional Completeness
- [ ] All authentication flows tested (login, logout, registration)
- [ ] Role-based access control validated
- [ ] Error scenarios handled gracefully
- [ ] Session management working correctly

### Integration Validation
- [ ] Firebase authentication integration working
- [ ] Database user records synchronized
- [ ] Frontend state management accurate
- [ ] API authentication headers correct

### Test Quality
- [ ] Tests are reliable and not flaky
- [ ] Clear error messages and assertions
- [ ] Proper test data cleanup
- [ ] Consistent execution across environments

## Implementation Status

### ⏳ NOT STARTED - Ready for Implementation

#### Test Cases to Implement
- [ ] AUTH-001: User Registration Flow
- [ ] AUTH-005: User Login Flow
- [ ] AUTH-008: Session Management
- [ ] AUTH-011: Admin Permissions
- [ ] AUTH-006: Invalid Credentials
- [ ] AUTH-010: Logout Process

#### Support Code Required
- [ ] Authentication custom commands
- [ ] Page objects for login/registration
- [ ] Test data fixtures and helpers
- [ ] Database verification utilities

### Dependencies
- **Step 1**: Cypress setup completed
- **Step 2**: Test case design patterns established
- **Prerequisites**: Test user accounts created in development database

### Next Steps After Completion
1. **Validate Authentication Tests**: Ensure all auth scenarios pass consistently
2. **Document Test Users**: Create guide for maintaining test accounts
3. **Begin File Management Testing**: Proceed to Step 4 with authenticated users
4. **Integration Testing**: Validate auth works with other features

## Problems Found
*To be filled during implementation*

## Solutions Applied
*To be filled during implementation*

## Testing Results
*To be filled during implementation*

## Implementation Notes
*To be filled during implementation*

---

**Created**: October 31, 2025
**Last Updated**: October 31, 2025
**Status**: NOT_STARTED
**Assigned**: Pending
**Estimated Time**: 2-3 days
**Dependencies**: Steps 1, 2 completed
**Blocks**: Steps 4, 5 (require authenticated users)

**Related Documents**:
- [UI_TESTING_IMPLEMENTATION.md](./UI_TESTING_IMPLEMENTATION.md) - Master plan
- [STEP2_TEST_CASE_SCENARIOS_DESIGN.md](./STEP2_TEST_CASE_SCENARIOS_DESIGN.md) - Previous step
- [STEP4_FILE_MANAGEMENT_SCENARIOS.md](./STEP4_FILE_MANAGEMENT_SCENARIOS.md) - Next step
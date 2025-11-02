# Step 5: Business Flow Scenarios

> **Parent Document**: `UI_TESTING_IMPLEMENTATION.md`
> **Status**: NOT_STARTED
> **Priority**: HIGH - Revenue-Critical User Journeys

## Overview

Implement comprehensive business flow test scenarios that validate end-to-end user journeys critical for Ludora's educational platform revenue. These tests cover product discovery, cart management, checkout processes, payment integration, and post-purchase access - ensuring the complete customer experience functions correctly.

## Objectives

1. **Product Discovery & Management** - Search, browse, create, and edit products
2. **Cart & Checkout Workflows** - Add to cart, manage items, complete checkout
3. **Payment Integration** - PayPlus payment processing and error handling
4. **Purchase & Access Management** - Post-purchase content access and downloads
5. **Admin Business Operations** - User management, analytics, and system administration

## Business Architecture Review

### Revenue-Critical Workflows
- **Product Catalog** → **Cart Management** → **Checkout** → **Payment** → **Access**
- **Content Creation** → **Publishing** → **Marketing** → **Sales**
- **User Management** → **Permissions** → **Content Access** → **Analytics**

### Payment Integration (PayPlus)
- **Development Environment**: PayPlus test credentials
- **Supported Methods**: Credit cards, digital wallets
- **Currency**: Israeli Shekels (₪)
- **Features**: Coupons, subscriptions, one-time payments

## Test Scenarios Implementation

### Product Management Workflows

#### BUSI-001: Product Discovery and Browsing
```javascript
// cypress/e2e/business-flows/product-discovery.cy.js
import { ProductCatalogPage } from '../../support/page-objects/ProductCatalogPage'
import { ProductDetailsPage } from '../../support/page-objects/ProductDetailsPage'

describe('Business Flows - Product Discovery', () => {
  const catalogPage = new ProductCatalogPage()
  const detailsPage = new ProductDetailsPage()

  beforeEach(() => {
    cy.task('seedProductCatalog')
  })

  it('BUSI-001 should browse products by category', () => {
    catalogPage.visit()

    // Browse different product categories
    const categories = ['Education', 'Mathematics', 'Science', 'Language']

    categories.forEach((category) => {
      catalogPage
        .selectCategory(category)
        .verifyProductsFiltered(category)
        .verifyProductCount()
    })
  })

  it('BUSI-002 should search products by keyword', () => {
    catalogPage.visit()

    const searchTerms = ['math', 'lesson plan', 'worksheet']

    searchTerms.forEach((term) => {
      catalogPage
        .searchProducts(term)
        .verifySearchResults(term)
        .verifyResultsRelevance(term)
    })
  })

  it('BUSI-003 should view product details', () => {
    catalogPage
      .visit()
      .selectFirstProduct()

    detailsPage
      .verifyProductInformation()
      .verifyPricing()
      .verifyMediaContent()
      .verifyAddToCartButton()
  })

  it('BUSI-004 should filter by product type', () => {
    const productTypes = ['file', 'lesson_plan', 'workshop', 'course']

    productTypes.forEach((type) => {
      catalogPage
        .visit()
        .filterByType(type)
        .verifyOnlyTypeShown(type)
    })
  })
})
```

#### BUSI-005: Product Creation Workflow
```javascript
// cypress/e2e/business-flows/product-creation-workflow.cy.js
describe('Business Flows - Product Creation', () => {
  beforeEach(() => {
    cy.loginAsUser()
  })

  it('BUSI-005 should create complete file product with all assets', () => {
    cy.fixture('products').then((products) => {
      const fileProduct = products.fileProduct

      // Navigate to product creation
      cy.visit('/products/create')

      // Fill product details
      cy.selectProductType('file')
      cy.fillProductDetails({
        name: fileProduct.name,
        description: fileProduct.description,
        price: fileProduct.price,
        category: fileProduct.category
      })

      // Upload marketing image
      cy.uploadMarketingImage('test-marketing-image.jpg')

      // Upload document
      cy.uploadDocument('test-document.pdf')

      // Set pricing and access
      cy.setPricing(fileProduct.price)
      cy.setAccessDays(30)

      // Publish product
      cy.publishProduct()

      // Verify creation success
      cy.verifyToast('המוצר נוצר בהצלחה') // Hebrew: Product created successfully
      cy.verifyRedirectTo('/products')

      // Verify product appears in catalog
      cy.visit('/files')
      cy.verifyProductInCatalog(fileProduct.name)
    })
  })

  it('BUSI-006 should create lesson plan with multiple files', () => {
    cy.visit('/products/create')

    cy.selectProductType('lesson_plan')
    cy.fillBasicDetails({
      name: 'Complete Math Lesson',
      subject: 'Mathematics',
      gradeLevel: '5-6'
    })

    // Upload categorized files
    cy.uploadLessonPlanFile('opening', 'lesson-opening.pptx')
    cy.uploadLessonPlanFile('body', 'lesson-body.pptx')
    cy.uploadLessonPlanFile('audio', 'background-music.mp3')
    cy.uploadLessonPlanFile('assets', 'worksheet.pdf')

    // Upload marketing image
    cy.uploadMarketingImage('lesson-preview.jpg')

    cy.publishProduct()

    // Verify all files uploaded correctly
    cy.verifyLessonPlanFiles('@lessonPlanId', {
      opening: ['lesson-opening.pptx'],
      body: ['lesson-body.pptx'],
      audio: ['background-music.mp3'],
      assets: ['worksheet.pdf']
    })
  })
})
```

### Cart and Checkout Workflows

#### BUSI-007: Cart Management
```javascript
// cypress/e2e/business-flows/cart-management.cy.js
import { CartPage } from '../../support/page-objects/CartPage'
import { ProductCatalogPage } from '../../support/page-objects/ProductCatalogPage'

describe('Business Flows - Cart Management', () => {
  const cartPage = new CartPage()
  const catalogPage = new ProductCatalogPage()

  beforeEach(() => {
    cy.loginAsUser()
    cy.task('clearUserCart')
    cy.task('seedTestProducts')
  })

  it('BUSI-007 should add products to cart', () => {
    catalogPage.visit()

    // Add multiple products to cart
    cy.addProductToCart('Test File Product')
    cy.verifyCartCount(1)

    cy.addProductToCart('Test Lesson Plan')
    cy.verifyCartCount(2)

    cy.addProductToCart('Test Workshop')
    cy.verifyCartCount(3)

    // Verify cart contents
    cartPage
      .visit()
      .verifyProductInCart('Test File Product')
      .verifyProductInCart('Test Lesson Plan')
      .verifyProductInCart('Test Workshop')
      .verifyTotalPrice()
  })

  it('BUSI-008 should update cart quantities', () => {
    // Add product to cart
    cy.addProductToCart('Test File Product')

    cartPage
      .visit()
      .updateQuantity('Test File Product', 3)
      .verifyQuantity('Test File Product', 3)
      .verifyUpdatedTotal()
  })

  it('BUSI-009 should remove items from cart', () => {
    // Add multiple products
    cy.addProductToCart('Test File Product')
    cy.addProductToCart('Test Lesson Plan')

    cartPage
      .visit()
      .removeProduct('Test File Product')
      .verifyProductNotInCart('Test File Product')
      .verifyProductInCart('Test Lesson Plan')
      .verifyCartCount(1)
  })

  it('BUSI-010 should persist cart across sessions', () => {
    // Add items to cart
    cy.addProductToCart('Test File Product')
    cy.addProductToCart('Test Lesson Plan')

    // Logout and login
    cy.logout()
    cy.loginAsUser()

    // Verify cart persisted
    cartPage
      .visit()
      .verifyProductInCart('Test File Product')
      .verifyProductInCart('Test Lesson Plan')
      .verifyCartCount(2)
  })
})
```

#### BUSI-011: Checkout Process
```javascript
// cypress/e2e/business-flows/checkout-process.cy.js
import { CheckoutPage } from '../../support/page-objects/CheckoutPage'

describe('Business Flows - Checkout Process', () => {
  const checkoutPage = new CheckoutPage()

  beforeEach(() => {
    cy.loginAsUser()
    cy.task('prepareCartWithProducts')
  })

  it('BUSI-011 should complete checkout with valid payment', () => {
    checkoutPage.visit()

    // Review order details
    checkoutPage
      .verifyOrderSummary()
      .verifyTotalAmount()

    // Fill billing information
    checkoutPage.fillBillingDetails({
      fullName: 'Test User',
      email: 'test@ludora.app',
      phone: '050-1234567',
      address: 'Test Address 123',
      city: 'Tel Aviv',
      zipCode: '12345'
    })

    // Fill payment information
    checkoutPage.fillPaymentDetails({
      cardNumber: '4111111111111111', // Test card
      expiryMonth: '12',
      expiryYear: '25',
      cvv: '123',
      cardHolder: 'Test User'
    })

    // Submit payment
    checkoutPage.submitPayment()

    // Verify payment success
    cy.verifyPaymentSuccess()
    cy.verifyRedirectTo('/payment-success')
    cy.verifyOrderConfirmation()

    // Verify purchase record created
    cy.verifyPurchaseCreated('@orderId')
  })

  it('BUSI-012 should handle payment failures gracefully', () => {
    checkoutPage.visit()

    // Use invalid card number
    checkoutPage
      .fillBillingDetails({
        fullName: 'Test User',
        email: 'test@ludora.app'
      })
      .fillPaymentDetails({
        cardNumber: '4000000000000002', // Declined test card
        expiryMonth: '12',
        expiryYear: '25',
        cvv: '123'
      })
      .submitPayment()

    // Verify error handling
    cy.verifyPaymentError('התשלום נדחה') // Hebrew: Payment declined
    cy.verifyStaysOnCheckout()
    cy.verifyNoPurchaseCreated()
  })

  it('BUSI-013 should apply coupons correctly', () => {
    cy.fixture('coupons').then((coupons) => {
      const validCoupon = coupons.tenPercentOff

      checkoutPage
        .visit()
        .applyCoupon(validCoupon.code)
        .verifyCouponApplied(validCoupon)
        .verifyDiscountCalculated(validCoupon.discount)
        .verifyUpdatedTotal()
    })
  })
})
```

### Payment Integration Workflows

#### BUSI-014: PayPlus Payment Integration
```javascript
// cypress/e2e/business-flows/payment-integration.cy.js
describe('Business Flows - PayPlus Payment Integration', () => {
  beforeEach(() => {
    cy.loginAsUser()
    cy.task('prepareCheckoutOrder')
  })

  it('BUSI-014 should process credit card payment through PayPlus', () => {
    cy.visit('/checkout')

    // Complete checkout form
    cy.fillCheckoutForm()

    // Process payment through PayPlus
    cy.processPayPlusPayment({
      cardNumber: '4111111111111111',
      expiryDate: '12/25',
      cvv: '123'
    })

    // Verify PayPlus response handling
    cy.verifyPayPlusSuccess()
    cy.verifyTransactionRecorded()
    cy.verifyContentAccessGranted()
  })

  it('BUSI-015 should handle PayPlus webhook callbacks', () => {
    // Mock PayPlus webhook
    cy.intercept('POST', '/api/webhooks/payplus', {
      statusCode: 200,
      body: { status: 'success' }
    }).as('payPlusWebhook')

    cy.processPayPlusPayment({
      cardNumber: '4111111111111111',
      expiryDate: '12/25',
      cvv: '123'
    })

    // Wait for webhook processing
    cy.wait('@payPlusWebhook')

    // Verify webhook handling
    cy.verifyWebhookProcessed()
    cy.verifyPurchaseStatusUpdated('completed')
  })

  it('BUSI-016 should handle payment timeouts', () => {
    // Mock payment timeout
    cy.intercept('POST', '**/payplus/**', {
      statusCode: 408,
      delay: 30000
    }).as('paymentTimeout')

    cy.fillCheckoutForm()
    cy.processPayPlusPayment({
      cardNumber: '4111111111111111',
      expiryDate: '12/25',
      cvv: '123'
    })

    cy.wait('@paymentTimeout')
    cy.verifyTimeoutHandling()
    cy.verifyOrderStatusUpdated('timeout')
  })
})
```

### Post-Purchase Workflows

#### BUSI-017: Content Access and Downloads
```javascript
// cypress/e2e/business-flows/content-access.cy.js
import { PurchasePage } from '../../support/page-objects/PurchasePage'

describe('Business Flows - Content Access', () => {
  const purchasePage = new PurchasePage()

  beforeEach(() => {
    cy.loginAsUser()
    cy.task('createCompletedPurchase')
  })

  it('BUSI-017 should grant access to purchased content', () => {
    purchasePage.visit()

    // Verify purchased products listed
    purchasePage
      .verifyPurchasedProduct('Test File Product')
      .verifyPurchaseDate()
      .verifyAccessStatus('active')

    // Access purchased content
    purchasePage
      .accessContent('Test File Product')
      .verifyContentAccess()
      .verifyDownloadAvailable()
  })

  it('BUSI-018 should download purchased files', () => {
    purchasePage
      .visit()
      .downloadFile('Test File Product', 'test-document.pdf')

    // Verify download
    cy.verifyFileDownloaded('test-document.pdf')
    cy.verifyDownloadTracked('@purchaseId', 'test-document.pdf')
  })

  it('BUSI-019 should enforce access permissions', () => {
    // Try to access content without purchase
    cy.logout()
    cy.loginAsDifferentUser()

    cy.visit('/content/test-file-product')
    cy.verifyAccessDenied()
    cy.verifyRedirectTo('/product-details?id=test-file-product')
  })

  it('BUSI-020 should handle expired access', () => {
    cy.task('expirePurchaseAccess', '@purchaseId')

    purchasePage
      .visit()
      .verifyPurchasedProduct('Test File Product')
      .verifyAccessStatus('expired')

    purchasePage
      .attemptContentAccess('Test File Product')
      .verifyAccessExpiredMessage()
      .verifyRenewOption()
  })
})
```

### Admin Business Operations

#### BUSI-021: User Management Workflows
```javascript
// cypress/e2e/business-flows/admin-user-management.cy.js
import { AdminPanelPage } from '../../support/page-objects/AdminPanelPage'
import { UserManagementPage } from '../../support/page-objects/UserManagementPage'

describe('Business Flows - Admin User Management', () => {
  const adminPanel = new AdminPanelPage()
  const userMgmt = new UserManagementPage()

  beforeEach(() => {
    cy.loginAsAdmin()
  })

  it('BUSI-021 should manage user accounts', () => {
    adminPanel
      .visit()
      .navigateToUserManagement()

    userMgmt
      .verifyUserList()
      .searchUser('test@ludora.app')
      .verifyUserFound('test@ludora.app')

    // Edit user details
    userMgmt
      .editUser('test@ludora.app')
      .updateRole('content_creator')
      .saveUser()

    // Verify role updated
    userMgmt
      .verifyUserRole('test@ludora.app', 'content_creator')
  })

  it('BUSI-022 should manage user subscriptions', () => {
    userMgmt
      .visit()
      .selectUser('test@ludora.app')
      .viewSubscriptions()

    // Update subscription
    userMgmt
      .addSubscription('premium', '1-month')
      .verifySubscriptionActive()
      .verifyAccessUpdated()
  })

  it('BUSI-023 should generate user reports', () => {
    adminPanel
      .visit()
      .navigateToAnalytics()

    // Generate user activity report
    cy.generateUserReport({
      dateRange: 'last-30-days',
      userType: 'all'
    })

    cy.verifyReportGenerated()
    cy.downloadReport('user-activity.xlsx')
    cy.verifyReportDownloaded()
  })
})
```

#### BUSI-024: System Analytics and Monitoring
```javascript
// cypress/e2e/business-flows/analytics-monitoring.cy.js
describe('Business Flows - Analytics and Monitoring', () => {
  beforeEach(() => {
    cy.loginAsAdmin()
    cy.task('seedAnalyticsData')
  })

  it('BUSI-024 should display revenue analytics', () => {
    cy.visit('/admin/analytics')

    // Verify revenue metrics
    cy.verifyRevenueMetrics({
      totalRevenue: true,
      monthlyGrowth: true,
      topProducts: true,
      conversionRate: true
    })

    // Filter by date range
    cy.filterAnalytics('last-3-months')
    cy.verifyMetricsUpdated()
  })

  it('BUSI-025 should monitor system health', () => {
    cy.visit('/admin/system-health')

    // Check system metrics
    cy.verifySystemMetrics({
      apiResponseTime: '<2000ms',
      databaseConnections: 'healthy',
      fileUploadSuccess: '>95%',
      errorRate: '<1%'
    })

    // View error logs
    cy.viewErrorLogs()
    cy.verifyErrorLogsFiltered()
  })
})
```

### Integration Test Workflows

#### BUSI-026: Complete User Journey
```javascript
// cypress/e2e/business-flows/complete-user-journey.cy.js
describe('Business Flows - Complete User Journey', () => {
  it('BUSI-026 should complete full customer journey', () => {
    // Registration
    cy.registerNewUser({
      email: 'journey-test@ludora.app',
      password: 'TestPassword123!',
      fullName: 'Journey Test User'
    })

    // Email verification (mocked)
    cy.verifyEmailAndActivate()

    // Browse products
    cy.visit('/files')
    cy.browseProducts()

    // Add to cart
    cy.addProductToCart('Premium File Package')
    cy.addProductToCart('Math Lesson Plan')

    // Apply coupon
    cy.applyCoupon('WELCOME10')

    // Checkout
    cy.proceedToCheckout()
    cy.fillCheckoutForm()
    cy.processPayment({
      cardNumber: '4111111111111111',
      expiryDate: '12/25',
      cvv: '123'
    })

    // Verify purchase
    cy.verifyPaymentSuccess()
    cy.verifyContentAccess()

    // Download content
    cy.downloadPurchasedContent()

    // Verify complete journey
    cy.verifyUserJourneyComplete()
  })
})
```

### Custom Business Flow Commands

#### Business Flow Helper Commands
```javascript
// cypress/support/commands.js - Business flow commands

// Product management
Cypress.Commands.add('addProductToCart', (productName) => {
  cy.contains('[data-testid="product-card"]', productName)
    .find('[data-testid="add-to-cart"]')
    .click()

  cy.verifyToast('המוצר נוסף לעגלה') // Hebrew: Product added to cart
})

Cypress.Commands.add('proceedToCheckout', () => {
  cy.visit('/cart')
  cy.get('[data-testid="checkout-button"]').click()
  cy.url().should('include', '/checkout')
})

// Payment processing
Cypress.Commands.add('processPayPlusPayment', (paymentDetails) => {
  cy.fillPaymentForm(paymentDetails)
  cy.get('[data-testid="submit-payment"]').click()

  // Handle PayPlus redirect/iframe
  cy.handlePayPlusFlow()
})

Cypress.Commands.add('verifyPaymentSuccess', () => {
  cy.url().should('include', '/payment-success')
  cy.get('[data-testid="success-message"]').should('be.visible')
  cy.verifyToast('התשלום הושלם בהצלחה') // Hebrew: Payment completed successfully
})

// Content access
Cypress.Commands.add('verifyContentAccess', () => {
  cy.visit('/purchases')
  cy.get('[data-testid="purchased-products"]').should('be.visible')
  cy.get('[data-testid="access-content"]').should('be.enabled')
})

Cypress.Commands.add('downloadPurchasedContent', () => {
  cy.get('[data-testid="download-button"]').first().click()
  cy.verifyDownloadStarted()
})

// Admin operations
Cypress.Commands.add('generateUserReport', (options) => {
  cy.get('[data-testid="report-type"]').select('user-activity')
  cy.get('[data-testid="date-range"]').select(options.dateRange)
  cy.get('[data-testid="generate-report"]').click()

  cy.get('[data-testid="report-generated"]').should('be.visible')
})

// Verification commands
Cypress.Commands.add('verifyCartCount', (expectedCount) => {
  cy.get('[data-testid="cart-count"]').should('contain', expectedCount)
})

Cypress.Commands.add('verifyPurchaseCreated', (orderId) => {
  cy.task('db:findPurchase', { orderId }).then((purchase) => {
    expect(purchase).to.exist
    expect(purchase.status).to.equal('completed')
  })
})

Cypress.Commands.add('verifyDownloadTracked', (purchaseId, fileName) => {
  cy.task('db:findDownloadLog', { purchaseId, fileName }).then((log) => {
    expect(log).to.exist
    expect(log.downloadedAt).to.exist
  })
})
```

## Implementation Priority

### Phase 5.1: Core Business Flows (P0 - Critical)
- [ ] Product discovery and browsing
- [ ] Cart management and checkout
- [ ] Payment processing integration
- [ ] Content access and downloads

### Phase 5.2: Product Management (P1 - High)
- [ ] Complete product creation workflows
- [ ] Product editing and updates
- [ ] Publishing and unpublishing
- [ ] Category and metadata management

### Phase 5.3: Admin Operations (P1 - High)
- [ ] User management workflows
- [ ] Analytics and reporting
- [ ] System monitoring
- [ ] Content moderation

### Phase 5.4: Integration Testing (P2 - Medium)
- [ ] Complete user journey testing
- [ ] Cross-feature integration
- [ ] Performance and reliability
- [ ] Error handling and recovery

## Validation Criteria

### Business Functionality
- [ ] All revenue-critical workflows function correctly
- [ ] Payment processing handles success and failure scenarios
- [ ] Content access control works as designed
- [ ] Admin operations complete successfully

### User Experience
- [ ] Workflows are intuitive and efficient
- [ ] Error messages are clear and helpful
- [ ] Performance meets user expectations
- [ ] Mobile and desktop experiences consistent

### Integration Quality
- [ ] PayPlus payment integration reliable
- [ ] Database transactions maintain consistency
- [ ] File uploads work with purchases
- [ ] Analytics data accurate and timely

## Implementation Status

### ⏳ NOT STARTED - Ready for Implementation

#### Test Cases to Implement
- [ ] BUSI-001 to BUSI-026: Complete business flow scenarios
- [ ] Page objects for all business workflows
- [ ] Payment integration testing utilities
- [ ] Analytics and reporting validation

#### Dependencies
- **Steps 1-4**: Foundation, design, auth, and file management completed
- **PayPlus Setup**: Test credentials and webhook configuration
- **Test Data**: Product catalog and user accounts

### Next Steps After Completion
1. **Full System Validation**: Complete end-to-end testing
2. **Performance Optimization**: Identify and resolve bottlenecks
3. **CI/CD Integration**: Automate test execution in deployment pipeline
4. **Documentation Updates**: Reflect testing insights in system docs

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
**Estimated Time**: 3-4 days
**Dependencies**: Steps 1, 2, 3, 4 completed
**Blocks**: None (final step)

**Related Documents**:
- [UI_TESTING_IMPLEMENTATION.md](./UI_TESTING_IMPLEMENTATION.md) - Master plan
- [STEP4_FILE_MANAGEMENT_SCENARIOS.md](./STEP4_FILE_MANAGEMENT_SCENARIOS.md) - Previous step
- All previous steps required for complete business flow testing
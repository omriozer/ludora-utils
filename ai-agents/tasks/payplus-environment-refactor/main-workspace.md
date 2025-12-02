# Task: PayPlus Environment Refactoring
**Task ID**: payplus-env-refactor-001
**Started**: 2025-11-25
**Status**: investigation-complete
**Last Updated**: 2025-11-25
**Estimated Completion**: 2025-11-25 (investigation phase complete, analysis in progress)

## 🎯 Task Overview
- **Objective**: Investigate current PayPlus payment system implementation that allows admin environment selection, prepare for refactoring to automatic environment detection
- **Complexity**: complex
- **Success Criteria**: Complete understanding of all components involved in PayPlus environment switching

## 📊 Overall Progress
- [x] Phase 1: Planning & Architecture
- [x] Phase 2: Investigation & Discovery
- [x] Phase 3: Analysis & Documentation
- [ ] Phase 4: Refactoring Plan
- [ ] Phase 5: Implementation Plan

## 🔍 Investigation Areas Completed

### 1. Frontend/Checkout UI - Admin interfaces for environment selection ✅
**Findings:**
- `PayPlusEnvironmentSelector.jsx` component - UI selector for admin/sysadmin users only
- Used in 2 places: `/pages/Checkout.jsx` and `/components/SubscriptionModal.jsx`
- Selector allows choosing between "production" and "test" environments
- Environment value is passed to backend with payment requests

### 2. Backend API Logic - Payment processing and environment switching ✅
**Findings:**
- Environment parameter accepted in payment endpoints: `/createPayplusPaymentPage` and `/createSubscriptionPayment`
- `PaymentService.getPayPlusCredentials()` - switches between production/staging credentials based on environment
- `PayplusService.openPayplusPage()` - uses environment to select PayPlus API URL and credentials
- Environment normalized: "test" → "staging" for database storage

### 3. Database Schema - Environment information storage ✅
**Findings:**
- `Transaction` table has `environment` column (ENUM: 'production', 'staging')
- All transactions record which environment was used for payment
- No user preferences or settings stored for environment selection
- Environment is transaction-specific, not user-specific

### 4. Configuration Management - Credentials and settings ✅
**Findings:**
- Production credentials: `PAYPLUS_API_KEY`, `PAYPLUS_SECRET_KEY`, `PAYPLUS_PAYMENT_PAGE_UID`
- Staging credentials: `PAYPLUS_STAGING_API_KEY`, `PAYPLUS_STAGING_SECRET_KEY`, `PAYPLUS_STAGING_PAYMENT_PAGE_UID`
- PayPlus URLs:
  - Production: `https://restapi.payplus.co.il/api/v1.0/`
  - Staging: `https://restapidev.payplus.co.il/api/v1.0/`

### 5. Webhook Systems - Environment-specific handling ✅
**Findings:**
- Webhooks don't differentiate by environment in processing
- Transaction environment is stored but not used for webhook validation
- Same webhook endpoint handles both production and staging callbacks

## 📝 Current Implementation Analysis

### How Environment Selection Works:
1. **Admin UI Display**: `PayPlusEnvironmentSelector` component shows only to admin/sysadmin users
2. **User Selection**: Admin chooses "production" or "test" in checkout/subscription modals
3. **Frontend → Backend**: Environment passed in API requests (`environment` parameter)
4. **Credential Selection**: Backend selects appropriate PayPlus credentials based on environment
5. **Transaction Recording**: Environment stored in database transaction record
6. **Payment Processing**: PayPlus API called with selected environment credentials

### Key Files Involved:
- **Frontend Components:**
  - `/src/components/PayPlusEnvironmentSelector.jsx` - The selector component
  - `/src/pages/Checkout.jsx` - Uses selector at line 636-641
  - `/src/components/SubscriptionModal.jsx` - Uses selector at line 695-703

- **Backend Services:**
  - `/services/PaymentService.js` - `getPayPlusCredentials()` method (lines 359-405)
  - `/services/PayplusService.js` - Uses credentials in `openPayplusPage()` (line 31)
  - `/services/SubscriptionPaymentService.js` - Handles subscription payments with environment

- **API Routes:**
  - `/routes/payments.js` - Accepts environment parameter (line 219, 249)

- **Database:**
  - `/models/Transaction.js` - Stores environment (line 36-39)

## 🚨 Issues & Warnings

### Current Problems:
1. **Manual Selection Risk**: Admins might accidentally select wrong environment
2. **Inconsistent UX**: Regular users don't see selector, but admins do
3. **Production Risk**: Test payments could accidentally go to production
4. **Confusing for Admins**: Why should they need to choose?
5. **No Validation**: No checks to ensure correct environment for deployment

### Refactoring Considerations:
1. **Automatic Detection**: Use `process.env.NODE_ENV` or custom env variable
2. **Remove UI Element**: Completely remove `PayPlusEnvironmentSelector` component
3. **Backend-Only Logic**: Environment determination should be server-side only
4. **Clear Mapping**: Development/Staging → Test, Production → Production
5. **Backward Compatibility**: Existing transactions have environment stored

## 📋 Components Requiring Modification

### Frontend Changes Required:
1. **Remove Component**: Delete `/src/components/PayPlusEnvironmentSelector.jsx`
2. **Update Checkout.jsx**: Remove lines 636-641 (PayPlusEnvironmentSelector usage)
3. **Update SubscriptionModal.jsx**: Remove lines 695-703 (PayPlusEnvironmentSelector usage)
4. **Remove State Management**: Remove `paymentEnvironment` state and setters
5. **Update API Calls**: Remove environment parameter from payment requests

### Backend Changes Required:
1. **Auto-detect Environment**: Modify `getPayPlusCredentials()` to use NODE_ENV
2. **Remove Parameter**: Remove environment parameter from payment endpoints
3. **Update Services**: Modify PayplusService and SubscriptionPaymentService
4. **Migration**: Consider updating existing transaction records if needed

### Testing Requirements:
1. Verify correct credentials used in each environment
2. Test payment flow without environment selector
3. Ensure webhooks still work correctly
4. Validate existing transactions aren't affected
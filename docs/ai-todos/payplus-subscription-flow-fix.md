# PayPlus Subscription Flow Fix - Comprehensive Implementation Plan

## **Status: 🔴 IN PROGRESS**
**Last Updated:** 2025-01-20 22:00
**Session:** PayPlus subscription flow analysis and fix

---

## **🎯 Executive Summary**

The PayPlus subscription system is currently broken because:
1. **Customer tokens are never saved** after successful payments
2. **Wrong PayPlus API endpoints** are being used for token-based subscriptions
3. **Database schema issues** prevent proper webhook processing
4. **User model pollution** instead of clean subscription data architecture

## **🔍 Root Cause Analysis**

### **Issue #1: Token Storage Never Happens**
- `PaymentService.saveCustomerToken()` method exists but is **never called**
- Payment webhooks don't extract or save customer tokens
- Result: Every customer treated as "new" requiring payment pages

**Files Affected:**
- `/Users/omri/omri-dev/base44/ludora/ludora-api/services/PaymentService.js:596-633`
- `/Users/omri/omri-dev/base44/ludora/ludora-api/routes/webhooks.js` (missing token extraction)

### **Issue #2: CustomerToken Schema Mismatch**
- `PaymentService.saveCustomerToken()` expects fields that don't match `CustomerToken` model
- Model has `token_value` but service uses `token_uid`
- Model has `card_mask` but service uses `last_four_digits`

**Files Affected:**
- `/Users/omri/omri-dev/base44/ludora/ludora-api/models/CustomerToken.js:23-27`
- `/Users/omri/omri-dev/base44/ludora/ludora-api/services/PaymentService.js:596-633`

### **Issue #3: Wrong PayPlus API Usage**
Current implementation uses wrong endpoints:
- ❌ **Currently**: `/PaymentPages/generateLink` for ALL subscriptions
- ✅ **Should be**: `/RecurringPayments/Add` for customers with tokens

**PayPlus API Documentation References:**
- New customers: https://docs.payplus.co.il/reference/post_paymentpages-generatelink
- Token customers: https://docs.payplus.co.il/reference/post_recurringpayments-add
- Cancellation: https://docs.payplus.co.il/reference/post_recurringpayments-deleterecurring-uid
- Updates: https://docs.payplus.co.il/reference/post_recurringpayments-update-uid

### **Issue #4: SubscriptionHistory Schema Issues**
Service tries to save fields that don't exist in database:

**Missing Fields:**
- `payplus_subscription_uid`
- `purchased_price`
- `metadata`
- `cancellation_reason`
- `notes`
- `next_billing_date`
- `cancelled_at`

**Files Affected:**
- `/Users/omri/omri-dev/base44/ludora/ludora-api/models/SubscriptionHistory.js:1-27`
- `/Users/omri/omri-dev/base44/ludora/ludora-api/services/SubscriptionService.js:365-378`

### **Issue #5: User Model Pollution**
SubscriptionService tries to add subscription fields to User model:
```javascript
// This fails because fields don't exist:
await this.models.User.update({
  current_subscription_plan_id: planId,
  subscription_status: 'active',
  subscription_start_date: subscriptionStartDate,
  // ...
})
```

**Better Architecture:** Query latest SubscriptionHistory record instead of duplicating data

---

## **📋 Implementation Plan**

### **Phase 1: Fix Token Storage Infrastructure** ✅ **PRIORITY 1**

#### **✅ Task 1.1: Create AI Documentation**
- [x] Document complete analysis and plan
- File: `/Users/omri/omri-dev/base44/ludora/ludora-utils/docs/ai-todos/payplus-subscription-flow-fix.md`

#### **✅ Task 1.2: Fix CustomerToken Schema Mismatch**
**Problem:** PaymentService.saveCustomerToken() doesn't match CustomerToken model fields

**COMPLETED:** Fixed both `saveCustomerToken()` and `getCustomerTokens()` methods to match CustomerToken model:
- ✅ Fixed `token_uid` → `token_value` mapping
- ✅ Fixed `last_four_digits` → `card_mask` mapping
- ✅ Added missing `payplus_customer_uid`, `environment` fields
- ✅ Fixed `metadata` → `payplus_response` field
- ✅ Updated getCustomerTokens() field mappings

**Files Updated:**
- ✅ `/Users/omri/omri-dev/base44/ludora/ludora-api/services/PaymentService.js:596-666`

#### **⏳ Task 1.3: Add Token Extraction to Webhooks**
**Problem:** Webhooks don't extract/save customer tokens from PayPlus responses

**Files to Update:**
- [ ] `/Users/omri/omri-dev/base44/ludora/ludora-api/routes/webhooks.js:126-488` (payment webhook)
- [ ] `/Users/omri/omri-dev/base44/ludora/ludora-api/routes/webhooks.js:490-656` (subscription webhook)

**Implementation:** Extract token data from PayPlus callback and call `saveCustomerToken()`

### **Phase 2: Fix Database Schema** ✅ **PRIORITY 2**

#### **⏳ Task 2.1: Create SubscriptionHistory Migration**
**Problem:** Missing required fields for webhook processing

**Migration Required:**
```sql
ALTER TABLE subscriptionhistory
ADD COLUMN payplus_subscription_uid VARCHAR(255),
ADD COLUMN purchased_price DECIMAL(10,2),
ADD COLUMN metadata JSONB DEFAULT '{}',
ADD COLUMN cancellation_reason VARCHAR(255),
ADD COLUMN notes TEXT,
ADD COLUMN next_billing_date TIMESTAMP,
ADD COLUMN cancelled_at TIMESTAMP;
```

**Files to Create:**
- [ ] New migration file in `/Users/omri/omri-dev/base44/ludora/ludora-api/migrations/`

#### **⏳ Task 2.2: Update SubscriptionHistory Model**
**Problem:** Model definition missing fields used by SubscriptionService

**Files to Update:**
- [ ] `/Users/omri/omri-dev/base44/ludora/ludora-api/models/SubscriptionHistory.js:1-27`

### **Phase 3: Fix PayPlus API Implementation** ✅ **PRIORITY 3**

#### **⏳ Task 3.1: Update SubscriptionService API Logic**
**Problem:** Using wrong PayPlus endpoints for token-based subscriptions

**Current Flow (SubscriptionService.js:48-102):**
```javascript
if (customerTokens.length > 0) {
  // Uses PaymentService.createRecurringSubscription() ❌ WRONG API
}
// Falls back to /PaymentPages/generateLink
```

**Correct Flow Should Be:**
```javascript
if (customerTokens.length > 0) {
  // Use /RecurringPayments/Add endpoint directly ✅
}
// Fallback to /PaymentPages/generateLink for new customers ✅
```

**PayPlus API Endpoints:**
- **Token-based subscriptions**: `/RecurringPayments/Add`
- **New customers**: `/PaymentPages/generateLink` with `charge_method: 3`
- **Cancellation**: `/RecurringPayments/DeleteRecurring/{uid}` (stays active until next cycle)
- **Downgrade**: `/RecurringPayments/Update/{uid}` (takes effect next cycle)
- **Upgrade**: `/RecurringPayments/Update/{uid}` + immediate prorated charge

**Files to Update:**
- [ ] `/Users/omri/omri-dev/base44/ludora/ludora-api/services/SubscriptionService.js:12-216`

#### **⏳ Task 3.2: Implement Subscription Management Methods**
**Add new methods:**
- [ ] `cancelSubscription()` → `/RecurringPayments/DeleteRecurring/{uid}`
- [ ] `updateSubscription()` → `/RecurringPayments/Update/{uid}`
- [ ] `upgradeSubscription()` → Update + calculate prorated charge

### **Phase 4: Clean Architecture** ✅ **PRIORITY 4**

#### **⏳ Task 4.1: Remove User Model Pollution**
**Problem:** SubscriptionService tries to update non-existent User fields

**Files to Update:**
- [ ] `/Users/omri/omri-dev/base44/ludora/ludora-api/services/SubscriptionService.js:348-361` (remove User.update calls)

#### **⏳ Task 4.2: Add User Helper Methods**
**Solution:** Add methods to query SubscriptionHistory instead of storing in User

**Implementation:**
```javascript
User.prototype.getCurrentSubscription = async function() {
  return await SubscriptionHistory.findOne({
    where: { user_id: this.id, action_type: 'subscribe', status: 'active' },
    order: [['created_at', 'DESC']],
    include: [{ model: SubscriptionPlan }]
  });
}

User.prototype.hasActiveSubscription = async function() {
  const subscription = await this.getCurrentSubscription();
  return subscription && new Date(subscription.end_date) > new Date();
}
```

**Files to Update:**
- [ ] `/Users/omri/omri-dev/base44/ludora/ludora-api/models/User.js` (add helper methods)

### **Phase 5: Advanced Features** ✅ **PRIORITY 5**

#### **⏳ Task 5.1: Implement Prorated Billing for Upgrades**
**Requirement:** When upgrading, charge prorated difference immediately

**Implementation:**
- [ ] Calculate remaining time in current billing cycle
- [ ] Calculate price difference between plans
- [ ] Charge prorated amount immediately
- [ ] Update subscription to new plan via `/RecurringPayments/Update/{uid}`

#### **⏳ Task 5.2: Add Status Monitoring**
**Enhancement:** Add backup status checking (not just webhook dependency)

**Implementation:**
- [ ] Use existing `PaymentService.checkSubscriptionStatus()` method
- [ ] Add scheduled task for periodic status verification
- [ ] Handle webhook failures gracefully

---

## **🧪 Testing Strategy**

### **Test Scenarios:**
1. **New Customer Subscription**
   - Should use `/PaymentPages/generateLink` with `charge_method: 3`
   - Webhook should save customer token
   - Subscription should be created in SubscriptionHistory

2. **Returning Customer Subscription**
   - Should use `/RecurringPayments/Add` with saved token
   - No payment page redirect
   - Immediate subscription activation

3. **Subscription Management**
   - Cancel: Should use `/RecurringPayments/DeleteRecurring/{uid}`
   - Downgrade: Should use `/RecurringPayments/Update/{uid}` (next cycle)
   - Upgrade: Should use `/RecurringPayments/Update/{uid}` + prorated charge

### **Verification Points:**
- [ ] Tokens are saved after successful payments
- [ ] Token-based subscriptions work without payment pages
- [ ] SubscriptionHistory records are created properly
- [ ] User helper methods return correct subscription status
- [ ] Webhook processing completes without errors

---

## **📚 Reference Documentation**

### **PayPlus API Endpoints:**
- **Payment Pages**: https://docs.payplus.co.il/reference/post_paymentpages-generatelink
- **Recurring Payments Add**: https://docs.payplus.co.il/reference/post_recurringpayments-add
- **Recurring Payments Delete**: https://docs.payplus.co.il/reference/post_recurringpayments-deleterecurring-uid
- **Recurring Payments Update**: https://docs.payplus.co.il/reference/post_recurringpayments-update-uid
- **Transaction Charge**: https://docs.payplus.co.il/reference/post_transactions-charge

### **Key Files:**
- **SubscriptionService**: `/Users/omri/omri-dev/base44/ludora/ludora-api/services/SubscriptionService.js`
- **PaymentService**: `/Users/omri/omri-dev/base44/ludora/ludora-api/services/PaymentService.js`
- **Webhooks**: `/Users/omri/omri-dev/base44/ludora/ludora-api/routes/webhooks.js`
- **CustomerToken Model**: `/Users/omri/omri-dev/base44/ludora/ludora-api/models/CustomerToken.js`
- **SubscriptionHistory Model**: `/Users/omri/omri-dev/base44/ludora/ludora-api/models/SubscriptionHistory.js`

### **Project Context:**
- **API Base**: `https://api.ludora.app/api`
- **Environment**: Fly.io deployment
- **Database**: PostgreSQL with Sequelize ORM
- **Payment Gateway**: PayPlus (Israeli payment processor)

---

## **🔄 Update Log**

### **2025-01-20 22:00**
- ✅ Created comprehensive analysis and implementation plan
- ✅ Identified root causes and priority order
- ✅ Documented all file locations and API endpoints
- ⏳ Ready to begin Phase 1 implementation

---

**Next Action:** Start with Task 1.2 - Fix CustomerToken schema mismatch in PaymentService
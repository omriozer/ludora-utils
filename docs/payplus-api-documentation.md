# PayPlus Payment Link Generation API Documentation

## Overview
The PayPlus Payment Link Generation API allows you to generate payment links for processing transactions. You can configure options like charge methods, amount, and success/failure callbacks.

**Endpoint:** `POST https://restapi.payplus.co.il/api/v1.0/PaymentPages/generateLink`

## Headers
- `api-key` (string, required) - API Key
- `secret-key` (string, required) - Secret Key

## Core Parameters

### Required Parameters
- `payment_page_uid` (string, required) - UID of the Payment Page (defaults to configured page ID)
- `amount` (number, required) - Amount of the payment
- `currency_code` (string, required) - Currency of the page (defaults to "ILS")
- `sendEmailApproval` (boolean, required) - Send email for successful transaction (defaults to true)
- `sendEmailFailure` (boolean, required) - Send email for failed transaction (defaults to false)

### Charge Methods
- `charge_method` (integer enum, defaults to 1)
  - `0` - Check (J2) - validates card without charging
  - `1` - Charge (J4) - immediate payment (transactional purchases)
  - `2` - Approval (J5) - funds verification
  - `3` - Recurring Payments - subscription billing
  - `4` - Refund (J4) - immediate refund
  - `5` - Token (J2) - tokenization

### Payment Method Configuration
- `charge_default` (string enum, defaults to nullable)
  - Options: `credit-card`, `bit`, `multipass`, `paypal`, `praxell`, `valuecard`, `verifone`
  - If payment page includes multiple options, you can select which tab will be opened by default
- `hide_other_charge_methods` (boolean, defaults to false)
  - Hide other payment methods and manage selection in your website
- `allowed_charge_methods` (array of strings, defaults to credit-card,google-pay)
  - Specific payment methods options in the payment page
- `allowed_cards` (array of strings, defaults to mastercard,visa)
  - Specific card brands to proceed with
- `allowed_bins` (array of integers)
  - Specific BINs to proceed with (6 or 8 digits)

## URL Configuration
- `refURL_success` (string) - Success callback URL (defaults to payment page settings)
- `refURL_failure` (string) - Failure callback URL (defaults to payment page settings)
- `refURL_cancel` (string) - Cancel callback URL (defaults to payment page settings)
- `refURL_callback` (string) - General callback URL (defaults to payment page settings)
- `send_failure_callback` (boolean, defaults to false) - Receive callback also in failure transactions

## Customer Information
- `customer` (object)
  - `uid` (string) - Allocate payment to specific customer
  - `customer_name` (string, required) - Important for invoicing company integration
  - `email` (string, required) - Used to search and allocate payment under client
  - `customer_external_number` (string) - External customer ID from ERP or other system
  - `vat_number` (string) - Used for customer search if email not sent
  - `phone` (string)
  - `address` (string)
  - `postal_code` (string)
  - `city` (string)
  - `country_iso` (string)

## Items Configuration
- `items` (array of objects) - Product/service details
  - `name` (string) - Product name
  - `product_invoice_extra_details` (string) - Additional invoice content
  - `product_uid` (string) - Unique identifier for product
  - `image_url` (string) - Product image URL
  - `category_uid` (string) - Category identifier
  - `quantity` (integer)
  - `barcode` (string)
  - `value` (integer)
  - `price` (number)
  - `discount_type` (string enum) - "percentage" OR "amount"
  - `discount_value` (number) - Required if discount type has value
  - `shipping` (boolean) - Show shipping line instead of product in order summary
  - `vat_type` (integer enum) - VAT settings
    - `0` - VAT included
    - `1` - VAT not included
    - `2` - Exempt VAT
  - `guide_document_url` (string) - Manual documentation URL for product

## Payment Configuration
- `language_code` (string, defaults to "he") - Display language
- `non_voucher_minimum_amount` (integer, defaults to 0) - Minimum payment for Credit Card transactions
- `expiry_datetime` (string, defaults to 30) - Minutes until page expires
- `payments` (integer, defaults to 5) - Number of installments for payment
- `payments_credit` (boolean, defaults to false) - Enable credit transaction (3-8 payments based on value)
- `payments_selected` (integer, defaults to 1) - Pre-selected number of payments
- `payments_first_amount` (integer, defaults to 5) - First installment amount (works with payments_selected)

## Advanced Options
- `custom_invoice_name` (string, defaults to "Customer Name") - Custom invoice customer name
- `create_token` (boolean, defaults to false) - Return customer token for future charges
- `initial_invoice` (boolean, defaults to true) - Create initial invoice for transaction
- `invoice_language` (boolean, defaults to false) - Invoice language override
- `paying_vat` (boolean, defaults to true) - Include VAT in tax document
- `hide_payments_field` (boolean, defaults to false) - Hide payments field for foreign transactions
- `hide_identification_id` (boolean, defaults to false) - Hide identification field for foreign transactions
- `send_customer_success_sms` (boolean, defaults to false) - Send SMS notification on success
- `customer_failure_sms` (boolean, defaults to false) - Send SMS notification on failure
- `add_user_information` (boolean, defaults to false) - Control customer details form
- `more_info` (string) - Additional information field
- `more_info_2` through `more_info_5` (string) - Additional information fields
- `create_hash` (string, defaults to false) - Encrypt customer details in callback
- `show_more_info` (string, defaults to false) - Show general information of more_info fields
- `support_track2` (boolean, defaults to false) - Support track2 in payment pages
- `close_doc` (string) - Close document in invoice+ by payment confirmation

## Recurring Payments
For subscription/recurring payments, use `charge_method: 3` and include:
- `recurring_settings` (object)
  - `instant_first_payment` (boolean, required) - Initial first payment immediately
  - `recurring_type` (integer enum, required) - Frequency type
    - `0` - Daily
    - `1` - Weekly
    - `2` - Monthly
  - `recurring_range` (integer, required) - Payment frequency (e.g., 1 = every month, 2 = every 2 months)
  - `number_of_charges` (integer, required) - Total number of charges (0 = unlimited)
  - `start_date_on_payment_date` (boolean, required) - Start recurring on payment date
  - `start_date` (integer, required) - Start date if not using payment date
  - `jump_payments` (integer, required) - Free trial days (e.g., 30 = 30 days free)
  - `successful_invoice` (boolean, required) - Create invoice for each successful payment
  - `customer_failure_email` (boolean, required) - Email customer on payment failure
  - `send_customer_success_email` (boolean, required) - Email customer on payment success
  - `end_date` (string) - When recurring will stop (for unlimited)

## Security Options
- `secure3d` (object) - 3D Secure settings
  - `allowed_issuers` (array of strings) - Allowed card issuers
- `invoice_integration_uid` (string) - Invoice integration identifier
- `cashier_uid` (string) - Cashier identifier

## Response Codes
- `200` - Success - Returns payment link URL
- `422` - Validation Error - Invalid parameters

## Example Usage

### One-time Payment
```json
{
  "payment_page_uid": "7a0bcd4d-f35f-4301-a945-926378a2416d",
  "charge_method": 1,
  "amount": 100,
  "currency_code": "ILS",
  "sendEmailApproval": true,
  "sendEmailFailure": false,
  "customer": {
    "customer_name": "John Doe",
    "email": "john@example.com"
  },
  "items": [{
    "name": "Course Access",
    "price": 100,
    "quantity": 1
  }]
}
```

### Recurring/Subscription Payment
```json
{
  "payment_page_uid": "7a0bcd4d-f35f-4301-a945-926378a2416d",
  "charge_method": 3,
  "amount": 50,
  "currency_code": "ILS",
  "sendEmailApproval": true,
  "sendEmailFailure": false,
  "recurring_settings": {
    "instant_first_payment": true,
    "recurring_type": 2,
    "recurring_range": 1,
    "number_of_charges": 0,
    "start_date_on_payment_date": true,
    "start_date": 15,
    "jump_payments": 30,
    "successful_invoice": true,
    "customer_failure_email": true,
    "send_customer_success_email": true
  },
  "customer": {
    "customer_name": "Jane Smith",
    "email": "jane@example.com"
  }
}
```

## Integration Notes

### For Ludora Platform
- Use `charge_method: 1` for one-time course/workshop/tool purchases
- Use `charge_method: 3` for subscription plans
- Always include customer email and name for proper tracking
- Set appropriate success/failure callback URLs
- Include product information in items array for proper invoicing
- Configure Hebrew language with `language_code: "he"`
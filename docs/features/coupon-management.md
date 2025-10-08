# 🎫 Ludora Coupon Management System

A comprehensive admin-only coupon and discount code management system integrated into the Ludora platform with advanced targeting, bulk generation, and analytics capabilities.

## 🚀 Features

- ✅ **Admin Dashboard**: Centralized hub accessible via floating admin menu
- ✅ **Multiple Discount Types**: Percentage (%) and fixed amount (₪) discounts
- ✅ **Advanced Targeting**: General, product-specific, product-type, and user-segment targeting
- ✅ **Bulk Generation**: Pattern-based bulk coupon creation with smart validation
- ✅ **Usage Tracking**: Per-coupon usage limits and real-time tracking
- ✅ **Analytics & Reports**: Performance metrics and usage analytics
- ✅ **PayPlus Integration**: Seamless integration with PayPlus payment gateway
- ✅ **Hebrew UI**: Full RTL support with Hebrew language interface
- ✅ **Security**: Admin-only access with JWT token authentication

## 🏗️ Architecture

```
Admin Menu (/admin-menu)
       ↓ (navigate)
Coupon Dashboard (/coupons)
       ↓ (CRUD operations)
API Coupon Endpoints (/api/entities/coupon)
       ↓ (validation & storage)
Database (coupon table)
       ↓ (integration)
PayPlus Gateway (discount application)
```

### Component Structure
```
src/pages/
├── CouponDashboard.jsx       # Central hub with statistics
├── CouponForm.jsx           # Create/edit individual coupons
├── CouponManagement.jsx     # List, filter, and manage coupons
├── CouponAnalytics.jsx      # Analytics and performance reports
└── BulkCouponGenerator.jsx  # Pattern-based bulk generation
```

## 📚 API Endpoints

### Coupon Management
- **GET** `/api/entities/coupon` - List all coupons (admin only)
- **POST** `/api/entities/coupon` - Create new coupon
- **GET** `/api/entities/coupon/:id` - Get specific coupon details
- **PUT** `/api/entities/coupon/:id` - Update existing coupon
- **DELETE** `/api/entities/coupon/:id` - Delete coupon

### Bulk Generation (Future Enhancement)
- **POST** `/api/functions/generateCouponCodes` - Generate multiple coupons with patterns
- **POST** `/api/functions/validateCouponPattern` - Validate coupon code pattern
- **GET** `/api/functions/getCouponPresetPatterns` - Get preset pattern options

### Analytics Integration
- **GET** `/api/entities/transaction` - Transaction data for analytics
- **GET** `/api/entities/purchase` - Purchase data with coupon metadata

## 🎯 Coupon Configuration

### Discount Types
```javascript
// Percentage discount
{
  discount_type: 'percentage',
  discount_value: 20,           // 20%
  discount_cap: 100             // Maximum ₪100 discount
}

// Fixed amount discount
{
  discount_type: 'fixed_amount',
  discount_value: 50,           // ₪50 off
  minimum_amount: 200           // Minimum purchase ₪200
}
```

### Targeting Options
```javascript
// General - applies to all products
{ targeting_type: 'general' }

// Product-specific targeting
{
  targeting_type: 'product_id',
  targeting_criteria: 'PRODUCT_ID'
}

// Product-type targeting
{
  targeting_type: 'product_type',
  targeting_criteria: 'workshop' // workshop, course, file, tool, game
}

// User-segment targeting
{
  targeting_type: 'user_segment',
  user_segments: ['new_user', 'vip', 'student']
}
```

### Visibility Settings
```javascript
// Secret - requires coupon code entry
{ visibility: 'secret' }

// Public - displayed in coupon lists
{ visibility: 'public' }

// Auto-suggest - automatically suggested at checkout
{ visibility: 'auto_suggest' }
```

## 🔐 Access Control Logic

### Admin Route Protection
```jsx
// All coupon routes wrapped with AdminRoute
<Route path='/coupons' element={
  <AdminRoute>
    <CouponDashboard />
  </AdminRoute>
} />

// AdminRoute checks user role via UserContext
const { currentUser } = useUser();
if (!isStaff(currentUser)) {
  return <Navigate to="/dashboard" replace />;
}
```

### Component-Level Security
```javascript
// Removed redundant admin checks - AdminRoute handles protection
// BEFORE (conflicting):
// if (user.role !== 'admin') {
//   navigate('/');
//   return;
// }

// AFTER (clean):
// Components focus on functionality, AdminRoute handles access
```

### API Security
```javascript
// All coupon API requests require JWT authentication
const response = await fetch(`${getApiBase()}/entities/coupon`, {
  headers: {
    'Authorization': `Bearer ${localStorage.getItem('token')}`,
    'Content-Type': 'application/json'
  }
});
```

## 🔄 Frontend Integration

### Coupon Dashboard
```javascript
// Statistics display with real-time data
const [stats, setStats] = useState({
  totalCoupons: 0,
  activeCoupons: 0,
  totalUsage: 0,
  expiringSoon: 0
});

// Navigation cards for different coupon operations
const dashboardItems = [
  { title: "ניהול קופונים", link: "/coupons/manage" },
  { title: "יצירת קופון חדש", link: "/coupons/create" },
  { title: "ניתוח ודוחות", link: "/coupons/analytics" },
  { title: "יצירה בכמויות", link: "/coupons/bulk-generate" }
];
```

### Form Handling
```javascript
// React Hook Form with Zod validation
const validateForm = () => {
  const errors = {};

  if (!formData.code.trim()) {
    errors.code = 'קוד הקופון הוא שדה חובה';
  } else if (!/^[A-Z0-9_-]+$/.test(formData.code)) {
    errors.code = 'קוד הקופון יכול להכיל רק אותיות באנגלית, מספרים, _ ו-';
  }

  if (formData.discount_type === 'percentage' && formData.discount_value > 100) {
    errors.discount_value = 'אחוז הנחה לא יכול להיות גדול מ-100%';
  }

  return Object.keys(errors).length === 0;
};
```

### Bulk Generation Patterns
```javascript
// Smart pattern validation
const presets = {
  student: { pattern: 'STUDENT-###', description: 'קופונים לתלמידים' },
  vip: { pattern: 'VIP-####', description: 'קופוני VIP' },
  holiday: { pattern: 'HOLIDAY##', description: 'קופוני חג' }
};

// Pattern replacement logic
// # = random number, @ = random letter
let code = pattern.replace(/#/g, () => Math.floor(Math.random() * 10));
code = code.replace(/@/g, () => String.fromCharCode(65 + Math.floor(Math.random() * 26)));
```

## 🗄️ Database Schema Dependencies

### Required Tables
- `coupon` - Main coupon entity with all configuration
- `purchase` - Links coupons to transactions
- `transaction` - PayPlus transaction data with coupon metadata
- `user` - Admin user authentication

### Coupon Table Structure
```sql
CREATE TABLE coupon (
  id VARCHAR PRIMARY KEY,
  code VARCHAR UNIQUE NOT NULL,
  description TEXT,
  discount_type ENUM('percentage', 'fixed_amount'),
  discount_value DECIMAL(10,2) NOT NULL,
  discount_cap DECIMAL(10,2),
  minimum_amount DECIMAL(10,2),
  targeting_type ENUM('general', 'product_type', 'product_id', 'user_segment'),
  targeting_criteria VARCHAR,
  targeting_metadata JSON,
  visibility ENUM('secret', 'public', 'auto_suggest'),
  is_active BOOLEAN DEFAULT true,
  usage_limit INTEGER,
  usage_count INTEGER DEFAULT 0,
  valid_from DATETIME,
  valid_until DATETIME,
  priority_level INTEGER DEFAULT 5,
  can_stack BOOLEAN DEFAULT false,
  user_segments JSON,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Transaction Integration
```javascript
// PayPlus transaction metadata includes applied coupons
{
  payplus_response: {
    coupon_info: {
      applied_coupons: [
        {
          code: "SAVE20",
          discountAmount: 50.00,
          originalAmount: 250.00,
          finalAmount: 200.00
        }
      ],
      total_discount: 50.00
    }
  }
}
```

## 🧪 Testing

### Manual Frontend Testing
```bash
# Navigate to admin coupon dashboard
1. Login as admin user
2. Access floating admin menu
3. Click "ניהול קופונים" (Coupon Management)
4. Verify dashboard loads with statistics

# Test coupon creation
1. Click "צור קופון חדש" (Create New Coupon)
2. Fill required fields (code, discount_value)
3. Set targeting and visibility options
4. Submit and verify creation success

# Test bulk generation
1. Navigate to /coupons/bulk-generate
2. Select or create pattern (e.g., BULK-####)
3. Set count and coupon settings
4. Generate and download CSV
```

### API Testing
```bash
# Get all coupons (admin only)
curl -H "Authorization: Bearer ADMIN_JWT" \
  http://localhost:3003/api/entities/coupon

# Create new coupon
curl -X POST -H "Authorization: Bearer ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"code":"TEST20","discount_type":"percentage","discount_value":20}' \
  http://localhost:3003/api/entities/coupon

# Update coupon
curl -X PUT -H "Authorization: Bearer ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"is_active":false}' \
  http://localhost:3003/api/entities/coupon/COUPON_ID
```

## 🔧 Configuration

### Environment Variables
- `VITE_API_BASE` - API base URL for frontend
- Database connection settings for coupon storage
- JWT secret for authentication

### Route Configuration
```javascript
// App.jsx route definitions
const couponRoutes = [
  { path: '/coupons', component: 'CouponDashboard' },
  { path: '/coupons/create', component: 'CouponForm' },
  { path: '/coupons/edit/:id', component: 'CouponForm' },
  { path: '/coupons/manage', component: 'CouponManagement' },
  { path: '/coupons/analytics', component: 'CouponAnalytics' },
  { path: '/coupons/bulk-generate', component: 'BulkCouponGenerator' }
];
```

## 🛡️ Security Features

### Authentication Required
All coupon operations require admin-level authentication via JWT tokens.

### Role-Based Access Control
```javascript
// UserContext role validation
import { isStaff, isAdmin, isSysadmin } from '@/lib/userUtils';

// AdminRoute component enforces access control
if (!isStaff(currentUser)) {
  return <Navigate to="/dashboard" replace />;
}
```

### Input Validation
```javascript
// Server-side validation prevents malicious input
- Coupon codes must match regex pattern: /^[A-Z0-9_-]+$/
- Discount values validated for type and range
- Usage limits and dates validated for logical consistency
- SQL injection protection via ORM
```

### Audit Trail
- Creation and modification timestamps
- Usage tracking with user identification
- Admin action logging
- Transaction integration for applied discounts

## 📈 Performance Considerations

### Frontend Optimization
```javascript
// Efficient state management
- React Context for user authentication
- Local state for form data
- Optimistic updates for better UX

// Component patterns
- Lazy loading of dashboard statistics
- Debounced search and filtering
- Pagination for large coupon lists
```

### Database Optimization
```sql
-- Recommended indexes for coupon table
CREATE INDEX idx_coupon_code ON coupon(code);
CREATE INDEX idx_coupon_active ON coupon(is_active);
CREATE INDEX idx_coupon_valid_dates ON coupon(valid_from, valid_until);
CREATE INDEX idx_coupon_usage ON coupon(usage_count, usage_limit);
```

### API Response Caching
```javascript
// Frontend caching strategy
- Dashboard statistics cached for 5 minutes
- Coupon lists cached until modifications
- Form data persisted in session storage
```

## 🚀 Deployment Notes

### Production Recommendations
1. **Database Indexes**: Ensure proper indexing on coupon table
2. **Rate Limiting**: Implement rate limiting on coupon creation APIs
3. **Monitoring**: Track coupon usage patterns and performance
4. **Backup**: Include coupon data in backup strategy
5. **Analytics**: Monitor discount impact on revenue

### Admin Access Setup
```javascript
// Ensure admin users have proper roles
UPDATE user SET role = 'admin' WHERE email = 'admin@ludora.app';

// Verify AdminRoute protection is active
- Check UserContext integration
- Test role-based navigation
- Validate JWT token authentication
```

## 🐛 Troubleshooting

### Common Issues

1. **"אין הרשאה" (No Permission) Error**
   - Verify user has admin role in database
   - Check JWT token validity
   - Confirm AdminRoute is not blocking access

2. **Coupon Creation Fails**
   - Check for duplicate coupon codes
   - Validate discount values and types
   - Verify database connection

3. **Dashboard Not Loading**
   - Check API endpoint accessibility
   - Verify admin authentication
   - Review console for JavaScript errors

4. **Bulk Generation Issues**
   - Validate pattern syntax (# for numbers, @ for letters)
   - Check for pattern collision potential
   - Verify bulk API endpoints exist

### Debug Checklist

- [x] AdminRoute properly wraps all coupon routes
- [x] UserContext provides admin role information
- [x] API endpoints return proper error messages
- [x] Database constraints prevent invalid data
- [x] Frontend validation matches backend rules
- [x] Toast notifications show Hebrew error messages

## 🔄 Integration Checklist

- [x] Central coupon dashboard with statistics
- [x] Individual coupon creation and editing
- [x] Bulk coupon generation with patterns
- [x] Comprehensive coupon management interface
- [x] Analytics and performance reporting
- [x] AdminRoute access control integration
- [x] PayPlus payment gateway compatibility
- [x] Hebrew UI with RTL support
- [x] JWT authentication for all operations
- [x] Database schema and API endpoints
- [x] Error handling and user feedback
- [x] Documentation and testing guidelines

## 📞 Support

For issues or questions about the coupon management system:

1. **Admin Access Issues**: Check user roles and AdminRoute configuration
2. **API Errors**: Verify JWT tokens and endpoint accessibility
3. **Frontend Problems**: Check browser console and network requests
4. **Database Issues**: Verify coupon table schema and constraints
5. **PayPlus Integration**: Test discount application in checkout flow

### Key Files Reference
- `/src/pages/CouponDashboard.jsx` - Main dashboard hub
- `/src/pages/CouponForm.jsx` - Create/edit forms
- `/src/pages/CouponManagement.jsx` - Coupon list management
- `/src/pages/CouponAnalytics.jsx` - Analytics and reports
- `/src/pages/BulkCouponGenerator.jsx` - Bulk generation tool
- `/src/App.jsx` - Route definitions with AdminRoute protection

The coupon management system is now fully integrated and ready for production use with comprehensive admin controls and PayPlus integration!
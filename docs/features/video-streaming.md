# 🎥 Ludora Video Streaming System

A complete HTTP Range-compatible video streaming system integrated into the Ludora API with comprehensive access control based on user purchases and subscriptions.

## 🚀 Features

- ✅ **HTTP Range Support**: Efficient video streaming with partial content delivery (206 responses)
- ✅ **Access Control**: Purchase and subscription-based access verification
- ✅ **Real Progress Tracking**: Live upload progress with XMLHttpRequest
- ✅ **Large File Support**: No arbitrary file size limits for video uploads
- ✅ **Security**: Protected endpoints requiring authentication
- ✅ **Creator Access**: Content creators can access their own videos
- ✅ **Subscription Integration**: Automatic access based on active subscriptions

## 🏗️ Architecture

```
Frontend (ProductModal)
       ↓ (upload)
API Video Upload (/api/videos/upload)
       ↓ (stores file)
File System (uploads/videos/)
       ↓ (streaming request)
API Video Stream (/api/videos/:id/stream)
       ↓ (access check)
Access Control Service
       ↓ (queries)
Database (Products, Purchases, Subscriptions)
```

## 📚 API Endpoints

### Video Streaming
- **GET** `/api/videos/:videoId/stream` - Stream video with HTTP Range support and access control
- **GET** `/api/videos/:videoId/access` - Check if user has access to video (debugging)
- **GET** `/api/videos/:videoId/info` - Get video metadata and access info

### Video Management
- **POST** `/api/videos/upload` - Upload a new video file
- **GET** `/api/videos/my-videos` - List user's accessible videos (TODO)

## 🔐 Access Control Logic

### 1. Purchase-Based Access
```javascript
// User has purchased the specific product containing the video
const purchase = await Purchase.findOne({
  where: {
    buyer_email: userEmail,
    product_id: productId,
    payment_status: 'completed'
  }
});

// Check for lifetime access or time-limited access
if (purchase.purchased_lifetime_access || withinAccessPeriod) {
  return { hasAccess: true, reason: 'purchase' };
}
```

### 2. Subscription-Based Access
```javascript
// User has active subscription with video access benefits
const subscription = await SubscriptionHistory.findOne({
  where: {
    user_id: userId,
    status: 'active',
    start_date: { [Op.lte]: new Date() },
    end_date: { [Op.gte]: new Date() }
  },
  include: [{ model: SubscriptionPlan }]
});

// Check if subscription plan includes video access
const benefits = subscription.SubscriptionPlan.benefits;
if (benefits.video_access || benefits.all_content) {
  return { hasAccess: true, reason: 'subscription' };
}
```

### 3. Creator Access
```javascript
// User is the creator of the content
const product = await Product.findOne({
  where: {
    id: productId,
    creator_user_id: userId
  }
});

if (product) {
  return { hasAccess: true, reason: 'creator' };
}
```

## 🔄 Frontend Integration

### Updated ProductModal
```javascript
// Real progress tracking for video uploads
xhr.upload.onprogress = (event) => {
  if (event.lengthComputable) {
    const percentComplete = Math.round((event.loaded / event.total) * 100);
    setUploadProgress(prev => ({ ...prev, [uploadKey]: percentComplete }));
  }
};

// Upload to integrated endpoint
xhr.open('POST', '/api/videos/upload', true);
xhr.send(formData);
```

### Video Player Integration
```html
<!-- Simple HTML5 video player with automatic range request handling -->
<video controls preload="metadata">
    <source src="/api/videos/VIDEO_ID/stream" type="video/mp4">
    Your browser does not support the video tag.
</video>
```

## 🗄️ Database Schema Dependencies

### Required Tables
- `product` - Contains video references and metadata
- `purchase` - Tracks user purchases with access periods
- `subscriptionplan` - Defines subscription benefits
- `subscriptionhistory` - Tracks active user subscriptions
- `user` - User authentication and identification

### Key Fields

#### Products
- `video_file_url` - Workshop video URL
- `course_modules` - JSON array containing module video URLs
- `creator_user_id` - Content creator reference

#### Purchases
- `buyer_email` - Links to user
- `product_id` - Links to product
- `access_until` - Expiration date
- `purchased_lifetime_access` - Boolean flag
- `purchased_access_days` - Access duration

#### Subscription Plans
- `benefits` - JSON object with access permissions:
  ```json
  {
    "video_access": true,
    "workshop_videos": true,
    "course_videos": true,
    "all_content": true
  }
  ```

## 🧪 Testing

### 1. Run the Test Suite
```bash
cd ludora-api
node test-video-access.js
```

### 2. Manual API Testing
```bash
# Upload a video
curl -X POST -F "file=@test.mp4" \
  -H "Authorization: Bearer YOUR_JWT" \
  http://localhost:3001/api/videos/upload

# Check access
curl -H "Authorization: Bearer YOUR_JWT" \
  http://localhost:3001/api/videos/VIDEO_ID/access

# Stream with range request
curl -H "Authorization: Bearer YOUR_JWT" \
  -H "Range: bytes=0-1023" \
  http://localhost:3001/api/videos/VIDEO_ID/stream
```

### 3. Browser Testing
Create an HTML file with a video element pointing to `/api/videos/VIDEO_ID/stream`

## 🔧 Configuration

### Environment Variables
- `ENVIRONMENT` - development/staging/production
- Database connection settings in `config/database.js`

### File Storage
- Videos stored in: `ludora-api/uploads/videos/`
- Filename format: `{uuid}.mp4`
- No size limits for video files

## 🛡️ Security Features

### Authentication Required
All video endpoints require valid JWT authentication via `requireAuth` middleware.

### Access Control Middleware
The `videoAccessMiddleware` checks permissions before serving content:
- Verifies user is authenticated
- Checks purchase history
- Validates subscription benefits
- Confirms creator ownership

### Private File Handling
- Videos are served through controlled endpoints
- No direct file system access
- Request logging for analytics
- Custom headers for debugging (`X-Access-Type`, `X-Video-ID`)

## 📈 Performance Considerations

### HTTP Range Requests
- Efficient streaming with partial content delivery
- Supports video seeking without full download
- Proper Content-Range and Accept-Ranges headers

### Caching Strategy
- `Cache-Control: private, max-age=3600` for authenticated content
- Browser-side caching for video chunks
- No public caching due to access control

### File Storage Optimization
- Videos stored with UUID filenames
- Direct file system streaming (no memory buffering)
- Configurable storage directory

## 🚀 Deployment Notes

### Production Recommendations
1. **Reverse Proxy**: Use nginx for static file serving performance
2. **CDN Integration**: Consider CDN for video delivery with signed URLs
3. **Database Indexing**: Ensure indexes on `buyer_email`, `product_id`, `user_id`
4. **Monitoring**: Log video access patterns for analytics
5. **Backup**: Include video files in backup strategy

### Example nginx Configuration
```nginx
# Serve videos through Node.js for access control
location /api/videos/ {
    proxy_pass http://localhost:3001;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    client_max_body_size 10G;  # Allow large video uploads
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Video not found**: Check file exists in `uploads/videos/`
2. **Access denied**: Verify user has valid purchase or subscription
3. **Upload fails**: Check file permissions on uploads directory
4. **Stream interruptions**: Verify Range header handling

### Debug Endpoints

- `GET /api/videos/:id/access` - Shows detailed access information
- Custom headers in responses show access type and video ID
- Console logging shows access attempts with reasons

## 🔄 Integration Checklist

- [x] Video streaming server with HTTP Range support
- [x] Access control based on purchases and subscriptions  
- [x] Real upload progress tracking
- [x] Integration with existing ludora-api
- [x] Updated ProductModal frontend
- [x] Database model integration
- [x] Authentication middleware
- [x] Error handling and logging
- [x] Test suite and documentation

## 📞 Support

For issues or questions about the video streaming system:

1. Check the test suite results: `node test-video-access.js`
2. Verify database connections and model associations
3. Test API endpoints with curl commands
4. Check server logs for detailed error information

The system is now fully integrated and ready for production use with proper access control and streaming capabilities!
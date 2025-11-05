# Ludora API Reference

> **Version**: 1.0.0
> **Base URL**: `http://localhost:3003` (development)
> **Environment**: Custom API migrated from base44

## Table of Contents

1. [Authentication & Authorization](#authentication--authorization)
2. [Generic Entity API Pattern](#generic-entity-api-pattern)
3. [Authentication Endpoints](#authentication-endpoints)
4. [Entity Management](#entity-management)
5. [Functions & Business Logic](#functions--business-logic)
6. [Video Management](#video-management)
7. [Access Control](#access-control)
8. [Media & File Management](#media--file-management)
9. [Game Content Templates](#game-content-templates)
10. [Game Content Usage](#game-content-usage)
11. [Integrations](#integrations)
12. [Logging](#logging)
13. [Error Handling](#error-handling)
14. [Rate Limiting](#rate-limiting)
15. [Middleware](#middleware)

---

## Authentication & Authorization

The Ludora API uses multiple authentication methods:

### Authentication Methods

1. **JWT Tokens** - Primary authentication method
2. **Firebase ID Tokens** - Legacy support
3. **API Keys** - For external integrations
4. **Query Parameter Tokens** - For media access

### Authentication Headers

```http
Authorization: Bearer <jwt_token>
# OR
Authorization: Bearer <firebase_id_token>
# OR
X-API-Key: <api_key>
```

### User Roles

- **`user`** - Standard user with basic permissions
- **`admin`** - Administrative access to system management
- **`sysadmin`** - Full system access

### User Types

- **`teacher`** - Educational content creator
- **`student`** - Content consumer
- **`parent`** - Guardian access
- **`headmaster`** - School administrator

### Authentication Middleware

- **`authenticateToken`** - Requires valid authentication
- **`optionalAuth`** - Authentication optional, continues without auth if no token
- **`requireRole(role)`** - Requires specific role
- **`requireUserType(userType)`** - Requires specific user type
- **`requireOwnership(getResourceOwnerId)`** - Requires resource ownership
- **`validateApiKey`** - Validates API key for external integrations

---

## Generic Entity API Pattern

The Ludora API provides a generic CRUD pattern for all entity types. This pattern is consistent across all entity operations.

### Supported Entity Types

```javascript
[
  'user', 'settings', 'registration', 'emailtemplate', 'category',
  'coupon', 'supportmessage', 'notification', 'sitetext', 'product',
  'purchase', 'workshop', 'course', 'file', 'tool', 'emaillog',
  'game', 'audiofile', 'gameaudiosettings', 'word', 'worden', 'image',
  'qa', 'grammar', 'contentlist', 'contentrelationship', 'subscriptionplan',
  'webhooklog', 'pendingsubscription', 'subscriptionhistory', 'gamesession',
  'attribute', 'gamecontenttag', 'contenttag', 'school', 'classroom',
  'studentinvitation', 'parentconsent', 'classroommembership'
]
```

### Generic Entity Endpoints

All entity types follow this pattern:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/entities/{type}` | List entities with filtering |
| `GET` | `/api/entities/{type}/{id}` | Get specific entity |
| `POST` | `/api/entities/{type}` | Create new entity |
| `PUT` | `/api/entities/{type}/{id}` | Update entity |
| `DELETE` | `/api/entities/{type}/{id}` | Delete entity |
| `POST` | `/api/entities/{type}/bulk` | Bulk operations |
| `GET` | `/api/entities/{type}/count` | Count entities |

---

## Authentication Endpoints

### Login

```http
POST /api/auth/login
```

**Authentication**: None
**Rate Limit**: 10 requests per 15 minutes

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response**:
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "role": "user",
    "user_type": "teacher"
  }
}
```

**Error Responses**:
- `400` - Validation failed
- `401` - Invalid credentials

### Register

```http
POST /api/auth/register
```

**Authentication**: None
**Rate Limit**: 10 requests per 15 minutes

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "fullName": "John Doe",
  "role": "user",
  "user_type": "teacher"
}
```

**Response**:
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "full_name": "John Doe"
  }
}
```

### Get Current User

```http
GET /api/auth/me
```

**Authentication**: Required
**Response**:
```json
{
  "id": "user_id",
  "uid": "user_id",
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "user",
  "user_type": "teacher",
  "is_verified": true,
  "is_active": true,
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

### Update Profile

```http
PUT /api/auth/update-profile
```

**Authentication**: Required
**Request Body**:
```json
{
  "full_name": "John Updated",
  "phone": "+1234567890",
  "education_level": "bachelor"
}
```

### Logout

```http
POST /api/auth/logout
```

**Authentication**: Optional
**Response**:
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### Password Reset

```http
POST /api/auth/forgot-password
```

**Authentication**: None
**Rate Limit**: 10 requests per 15 minutes

**Request Body**:
```json
{
  "email": "user@example.com"
}
```

```http
POST /api/auth/reset-password
```

**Request Body**:
```json
{
  "token": "reset_token",
  "newPassword": "NewPassword123!"
}
```

### Token Operations

```http
POST /api/auth/verify
```

**Request Body**:
```json
{
  "idToken": "firebase_id_token"
}
```

```http
POST /api/auth/custom-token
```

**Request Body**:
```json
{
  "uid": "user_id",
  "claims": {}
}
```

```http
POST /api/auth/set-claims
```

**Authentication**: Required
**Request Body**:
```json
{
  "uid": "user_id",
  "claims": {
    "role": "admin"
  }
}
```

---

## Entity Management

### List Entities

```http
GET /api/entities/{type}?limit=50&offset=0&order=desc
```

**Authentication**: Optional
**Query Parameters**:
- `limit` (number, 1-1000, default: 50) - Number of results
- `offset` (number, default: 0) - Pagination offset
- `order` (string, 'asc'|'desc', default: 'desc') - Sort order
- Additional filters based on entity type

**Example**:
```http
GET /api/entities/workshop?limit=10&is_published=true
```

**Response**:
```json
{
  "count": 10,
  "rows": [
    {
      "id": "workshop_id",
      "title": "Workshop Title",
      "price": 99.99,
      "is_published": true
    }
  ]
}
```

### Get Entity by ID

```http
GET /api/entities/{type}/{id}
```

**Authentication**: Optional
**Response**:
```json
{
  "id": "entity_id",
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

**Error Responses**:
- `404` - Entity not found

### Create Entity

```http
POST /api/entities/{type}
```

**Authentication**: Required
**Content Creator Permissions**: Required for product types (workshop, course, file, tool, game)

**Request Body**: Varies by entity type

**Workshop Example**:
```json
{
  "title": "New Workshop",
  "description": "Workshop description",
  "price": 99.99,
  "workshop_type": "recorded",
  "is_published": false
}
```

**Game Example**:
```json
{
  "title": "Math Game",
  "short_description": "Educational math game",
  "game_type": "memory_game",
  "price": 0,
  "device_compatibility": "both",
  "language": "hebrew",
  "game_settings": {
    "difficulty": "easy",
    "time_limit": 60
  }
}
```

**Response**:
```json
{
  "id": "new_entity_id",
  "title": "New Workshop",
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

**Error Responses**:
- `400` - Validation failed
- `403` - Content creator permissions required

### Update Entity

```http
PUT /api/entities/{type}/{id}
```

**Authentication**: Required
**Request Body**: Partial entity data

**Response**: Updated entity data

**Error Responses**:
- `404` - Entity not found
- `403` - Insufficient permissions

### Delete Entity

```http
DELETE /api/entities/{type}/{id}
```

**Authentication**: Required
**Response**:
```json
{
  "message": "Entity deleted successfully",
  "id": "deleted_entity_id"
}
```

### Bulk Operations

```http
POST /api/entities/{type}/bulk
```

**Authentication**: Required
**Request Body**:
```json
{
  "operation": "create",
  "data": [
    {"title": "Item 1"},
    {"title": "Item 2"}
  ]
}
```

**Operations**:
- `create` - Bulk create entities
- `delete` - Bulk delete by IDs

**Response**:
```json
{
  "results": [
    {"id": "new_id_1", "status": "created"},
    {"id": "new_id_2", "status": "created"}
  ],
  "count": 2
}
```

### Count Entities

```http
GET /api/entities/{type}/count
```

**Authentication**: Optional
**Response**:
```json
{
  "count": 156
}
```

### List Available Entity Types

```http
GET /api/entities
```

**Authentication**: Optional
**Response**:
```json
{
  "entityTypes": ["user", "workshop", "game", "..."],
  "count": 25
}
```

---

## Functions & Business Logic

The Functions API provides business logic operations and integrations.

### Payment Functions

#### Send Payment Confirmation

```http
POST /api/functions/sendPaymentConfirmation
```

**Authentication**: Required
**Request Body**:
```json
{
  "paymentId": "payment_id",
  "userId": "user_id",
  "amount": 99.99,
  "email": "user@example.com"
}
```

#### Test PayPlus Connection

```http
POST /api/functions/testPayplusConnection
```

**Authentication**: Required
**Response**:
```json
{
  "connected": true,
  "status": "healthy"
}
```

#### Apply Coupon

```http
POST /api/functions/applyCoupon
```

**Authentication**: Required
**Request Body**:
```json
{
  "couponCode": "SAVE20",
  "userId": "user_id",
  "purchaseAmount": 100.00
}
```

#### Create Payment Page

```http
POST /api/functions/createPayplusPaymentPage
```

**Authentication**: Required
**Request Body**:
```json
{
  "purchaseId": "purchase_id",
  "amount": 99.99,
  "returnUrl": "https://example.com/success",
  "callbackUrl": "https://example.com/callback"
}
```

### Registration Functions

#### Update Existing Registrations

```http
POST /api/functions/updateExistingRegistrations
```

**Authentication**: Required
**Request Body**:
```json
{
  "registrationData": [
    {
      "id": "reg_id",
      "status": "completed"
    }
  ]
}
```

#### Send Registration Email

```http
POST /api/functions/sendRegistrationEmail
```

**Authentication**: Required
**Request Body**:
```json
{
  "email": "user@example.com",
  "registrationData": {
    "user_name": "John Doe",
    "site_name": "Ludora"
  }
}
```

### Email Functions

#### Process Email Triggers

```http
POST /api/functions/processEmailTriggers
```

**Authentication**: Required
**Request Body**:
```json
{
  "triggers": [
    {
      "type": "registration_confirmation",
      "recipient": "user@example.com",
      "data": {}
    }
  ]
}
```

#### Trigger Email Automation

```http
POST /api/functions/triggerEmailAutomation
```

**Authentication**: Required
**Request Body**:
```json
{
  "automationId": "automation_id",
  "userId": "user_id",
  "recipientEmail": "user@example.com",
  "data": {}
}
```

### Game Functions

#### Update Existing Games

```http
POST /api/functions/updateExistingGames
```

**Authentication**: Required
**Request Body**:
```json
{
  "gameUpdates": [
    {
      "id": "game_id",
      "title": "Updated Game Title"
    }
  ]
}
```

#### Upload Verbs Bulk

```http
POST /api/functions/uploadVerbsBulk
```

**Authentication**: Required
**Request Body**:
```json
{
  "verbs": [
    {
      "hebrew": "לרוץ",
      "english": "to run",
      "category": "verb",
      "language": "he"
    }
  ]
}
```

### File Functions

#### Delete File

```http
POST /api/functions/deleteFile
```

**Authentication**: Required
**Request Body**:
```json
{
  "fileId": "file_id",
  "entityType": "file"
}
```

#### Create Signed URL

```http
POST /api/functions/createSignedUrl
```

**Authentication**: Required
**Request Body**:
```json
{
  "fileName": "document.pdf",
  "fileType": "application/pdf",
  "operation": "upload"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "signedUrl": "https://storage.ludora.com/files/upload/document.pdf?token=...", // this is wrong!
    "expiresAt": "2024-01-01T01:00:00.000Z"
  }
}
```

### Subscription Functions

#### Create Subscription Page

```http
POST /api/functions/createPayplusSubscriptionPage
```

**Authentication**: Required
**Request Body**:
```json
{
  "planId": "plan_id",
  "userId": "user_id",
  "userEmail": "user@example.com"
}
```

#### Handle Subscription Callback

```http
POST /api/functions/handlePayplusSubscriptionCallback
```

**Authentication**: Required
**Request Body**: PayPlus callback data

---

## Video Management

### Stream Video

```http
GET /api/videos/{videoId}/stream
```

**Authentication**: Required
**Video Access Control**: Applied

**Features**:
- HTTP Range support for streaming
- Access control verification
- Secure streaming with headers

**Headers**:
- `Range: bytes=0-1023` (optional)
- `Authorization: Bearer <token>`

**Response Headers**:
- `Content-Type: video/mp4`
- `Accept-Ranges: bytes`
- `Content-Range: bytes 0-1023/1048576` (for partial content)
- `Cache-Control: private, max-age=3600`
- `X-Access-Type: purchase|subscription|free`

**Status Codes**:
- `200` - Full content
- `206` - Partial content (range request)
- `401` - Authentication required
- `403` - Access denied
- `404` - Video not found
- `416` - Range not satisfiable

### Check Video Access

```http
GET /api/videos/{videoId}/access
```

**Authentication**: Required
**Response**:
```json
{
  "videoId": "video_id",
  "userId": "user_id",
  "userEmail": "user@example.com",
  "access": {
    "hasAccess": true,
    "reason": "purchase",
    "expiresAt": "2024-12-31T23:59:59.000Z"
  }
}
```

### Upload Video

```http
POST /api/videos/upload
```

**Authentication**: Required
**Content-Type**: `multipart/form-data`
**File Limits**: 10GB maximum

**Form Fields**:
- `file` - Video file (MP4, WebM, OGG)

**Response**:
```json
{
  "success": true,
  "videoId": "unique_video_id",
  "filename": "unique_filename.mp4",
  "size": 1048576,
  "streamUrl": "/api/videos/unique_video_id/stream",
  "uploadedAt": "2024-01-01T00:00:00.000Z"
}
```

**Error Responses**:
- `400` - No file uploaded / Invalid file type
- `413` - File too large

### Get Video Info

```http
GET /api/videos/{videoId}/info
```

**Authentication**: Required
**Access Control**: Applied

**Response**:
```json
{
  "videoId": "video_id",
  "size": 1048576,
  "created": "2024-01-01T00:00:00.000Z",
  "streamUrl": "/api/videos/video_id/stream",
  "accessType": "purchase",
  "hasAccess": true
}
```

### List User Videos

```http
GET /api/videos/my-videos
```

**Authentication**: Required
**Response**: User's accessible videos list

---

## Access Control

### Check Entity Access

```http
GET /api/access/check/{entityType}/{entityId}
```

**Authentication**: Required
**Response**:
```json
{
  "hasAccess": true,
  "accessType": "purchase",
  "expiresAt": "2024-12-31T23:59:59.000Z",
  "purchaseDate": "2024-01-01T00:00:00.000Z"
}
```

### Get User Purchases

```http
GET /api/access/my-purchases?entityType=workshop&activeOnly=true
```

**Authentication**: Required
**Query Parameters**:
- `entityType` (optional) - Filter by entity type
- `activeOnly` (boolean) - Show only active purchases

**Response**:
```json
{
  "purchases": [
    {
      "id": "purchase_id",
      "entityType": "workshop",
      "entityId": "workshop_id",
      "purchaseDate": "2024-01-01T00:00:00.000Z",
      "expiresAt": "2024-12-31T23:59:59.000Z",
      "isLifetime": false
    }
  ]
}
```

### Grant Access (Admin)

```http
POST /api/access/grant
```

**Authentication**: Required (Admin)
**Request Body**:
```json
{
  "userEmail": "user@example.com",
  "entityType": "workshop",
  "entityId": "workshop_id",
  "accessDays": 365,
  "isLifetimeAccess": false,
  "price": 0
}
```

### Revoke Access (Admin)

```http
DELETE /api/access/revoke
```

**Authentication**: Required (Admin)
**Request Body**:
```json
{
  "userEmail": "user@example.com",
  "entityType": "workshop",
  "entityId": "workshop_id"
}
```

### Get Entity Users (Admin)

```http
GET /api/access/entity/{entityType}/{entityId}/users
```

**Authentication**: Required (Admin)
**Response**: List of users with access to entity

### Get Entity Stats (Admin)

```http
GET /api/access/entity/{entityType}/{entityId}/stats
```

**Authentication**: Required (Admin)
**Response**: Access statistics for entity

---

## Media & File Management

### Secure Video Streaming

```http
GET /api/media/video/{entityType}/{entityId}
```

**Authentication**: Required (Header or Query)
**Entity Types**: `workshop`, `course`, `file`, `tool`

**Authentication Methods**:
- Header: `Authorization: Bearer <token>`
- Query: `?authToken=<token>`

**Features**:
- Access control verification
- HTTP Range support
- Auto-grant for free content
- Secure headers to prevent downloads

**Response Headers**:
- `Content-Type: video/mp4`
- `Accept-Ranges: bytes`
- `Cache-Control: no-cache, no-store, must-revalidate`
- `Content-Security-Policy: default-src 'self'`
- `Access-Control-Allow-Origin: *`

### Get Video URL

```http
GET /api/media/video-url/{entityType}/{entityId}
```

**Authentication**: Required
**Response**:
```json
{
  "success": true,
  "data": {
    "videoUrl": "/api/media/video/workshop/123?token=...",
    "expires": "2024-01-01T01:00:00.000Z"
  }
}
```

### Upload File

```http
POST /api/media/file/upload
```

**Authentication**: Required
**Content-Type**: `multipart/form-data`
**File Limits**: 500MB maximum

**Form Fields**:
- `file` - File to upload
- `fileEntityId` - Associated File entity ID

**Supported File Types**:
- PDF: `application/pdf`
- Word: `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- Excel: `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- PowerPoint: `application/vnd.ms-powerpoint`, `application/vnd.openxmlformats-officedocument.presentationml.presentation`
- Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- Archives: `application/zip`

**Response**:
```json
{
  "success": true,
  "fileEntityId": "file_entity_id",
  "filename": "file_123456.pdf",
  "size": 1048576,
  "fileType": "pdf",
  "downloadUrl": "/api/media/file/download/file_entity_id",
  "uploadedAt": "2024-01-01T00:00:00.000Z"
}
```

### Download File

```http
GET /api/media/file/download/{fileEntityId}
```

**Authentication**: Required (Header or Query)
**Access Control**: Applied

**Features**:
- Access verification
- Auto-grant for free content
- Creator access
- Secure download headers

**Response Headers**:
- `Content-Type: application/pdf` (or appropriate type)
- `Content-Disposition: attachment; filename="File Title.pdf"`
- `Cache-Control: no-cache, no-store, must-revalidate`

**Error Responses**:
- `403` - Access denied
- `404` - File not found

---

## Game Content Templates

### List Templates

```http
GET /api/game-content-templates?game_type=memory_game&include_rules=true
```

**Authentication**: Required
**Query Parameters**:
- `game_type` (optional) - Filter by game type
- `is_global` (boolean) - Filter global templates
- `include_rules` (boolean) - Include associated rules

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "template_id",
      "name": "Math Content Template",
      "game_type": "memory_game",
      "content_types": ["word", "image"],
      "is_global": true,
      "rules": []
    }
  ],
  "meta": {
    "total": 1,
    "filters": {
      "game_type": "memory_game",
      "include_rules": true
    }
  }
}
```

### Get Templates for Game Type

```http
GET /api/game-content-templates/game-type/{gameType}?include_global=true
```

**Authentication**: Required
**Response**: Templates available for specific game type

### Get Global Templates

```http
GET /api/game-content-templates/global
```

**Authentication**: Required
**Response**: Global templates available for all game types

### Get Template by ID

```http
GET /api/game-content-templates/{id}
```

**Authentication**: Required
**Response**:
```json
{
  "success": true,
  "data": {
    "id": "template_id",
    "name": "Template Name",
    "description": "Template description",
    "game_type": "memory_game",
    "content_types": ["word", "image"],
    "is_global": false,
    "creator": {
      "id": "user_id",
      "full_name": "Creator Name"
    },
    "rules": []
  }
}
```

### Create Template (Admin)

```http
POST /api/game-content-templates
```

**Authentication**: Required (Admin)
**Request Body**:
```json
{
  "name": "New Template",
  "description": "Template description",
  "game_type": "memory_game",
  "content_types": ["word", "image"],
  "is_global": false,
  "rules": [
    {
      "rule_type": "attribute_based",
      "rule_config": {
        "attribute": "difficulty",
        "value": "easy"
      },
      "priority": 1
    }
  ]
}
```

### Update Template (Admin)

```http
PUT /api/game-content-templates/{id}
```

**Authentication**: Required (Admin)
**Request Body**: Partial template data

### Delete Template (Admin)

```http
DELETE /api/game-content-templates/{id}
```

**Authentication**: Required (Admin)

### Template Rules Management

#### Add Rule to Template

```http
POST /api/game-content-templates/{id}/rules
```

**Authentication**: Required (Admin)
**Request Body**:
```json
{
  "rule_type": "attribute_based",
  "rule_config": {
    "attribute": "subject",
    "value": "math"
  },
  "priority": 1
}
```

#### Update Template Rule

```http
PUT /api/game-content-templates/{id}/rules/{ruleId}
```

**Authentication**: Required (Admin)

#### Delete Template Rule

```http
DELETE /api/game-content-templates/{id}/rules/{ruleId}
```

**Authentication**: Required (Admin)

### Preview Rule Content

```http
POST /api/game-content-templates/preview-rule
```

**Authentication**: Required (Admin)
**Request Body**:
```json
{
  "rule_type": "attribute_based",
  "rule_config": {
    "attribute": "subject",
    "value": "math"
  },
  "content_types": ["word", "image"],
  "limit": 10
}
```

**Response**: Preview of content matching the rule

---

## Game Content Usage

### List Game Content Usage

```http
GET /api/games/{gameId}/content-usage
```

**Authentication**: Required
**Access Control**: Game ownership verification

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "usage_id",
      "name": "Math Words",
      "content_types": ["word"],
      "template_id": "template_id"
    }
  ],
  "meta": {
    "game_id": "game_id",
    "game_title": "Math Game",
    "total": 1
  }
}
```

### Get Content Usage

```http
GET /api/games/{gameId}/content-usage/{usageId}
```

**Authentication**: Required
**Access Control**: Game ownership verification

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "usage_id",
    "name": "Math Words",
    "description": "Math vocabulary",
    "content_types": ["word"],
    "template": {
      "id": "template_id",
      "name": "Template Name"
    },
    "rules": []
  }
}
```

### Create Content Usage

```http
POST /api/games/{gameId}/content-usage
```

**Authentication**: Required
**Access Control**: Game ownership verification

**Request Body**:
```json
{
  "name": "Math Words",
  "description": "Math vocabulary for level 1",
  "content_types": ["word"],
  "template_id": "template_id",
  "rules": []
}
```

### Copy Template to Usage

```http
POST /api/games/{gameId}/content-usage/copy-template
```

**Authentication**: Required
**Access Control**: Game ownership verification

**Request Body**:
```json
{
  "template_id": "template_id",
  "name": "Custom Name",
  "description": "Custom description"
}
```

### Update Content Usage

```http
PUT /api/games/{gameId}/content-usage/{usageId}
```

**Authentication**: Required
**Access Control**: Game ownership verification

### Delete Content Usage

```http
DELETE /api/games/{gameId}/content-usage/{usageId}
```

**Authentication**: Required
**Access Control**: Game ownership verification

### Content Usage Rules Management

#### Add Rule to Usage

```http
POST /api/games/{gameId}/content-usage/{usageId}/rules
```

**Authentication**: Required
**Request Body**:
```json
{
  "rule_type": "attribute_based",
  "rule_config": {
    "attribute": "difficulty",
    "value": "easy"
  },
  "priority": 1
}
```

#### Update Usage Rule

```http
PUT /api/games/{gameId}/content-usage/{usageId}/rules/{ruleId}
```

#### Delete Usage Rule

```http
DELETE /api/games/{gameId}/content-usage/{usageId}/rules/{ruleId}
```

### Resolve Content for Usage

```http
GET /api/games/{gameId}/content-usage/{usageId}/resolve
```

**Authentication**: Required
**Response**: Resolved content based on usage rules

### Preview Rule Content

```http
POST /api/games/{gameId}/content-usage/preview-rule
```

**Authentication**: Required
**Request Body**:
```json
{
  "rule_type": "attribute_based",
  "rule_config": {
    "attribute": "subject",
    "value": "math"
  },
  "content_types": ["word"],
  "limit": 10
}
```

---

## Integrations

### LLM Integration

#### Invoke LLM

```http
POST /api/integrations/invokeLLM
```

**Authentication**: Required
**Rate Limit**: 100 requests per hour

**Request Body**:
```json
{
  "prompt": "Translate this to Hebrew: Hello",
  "model": "gpt-3.5-turbo",
  "maxTokens": 1000,
  "temperature": 0.7,
  "systemPrompt": "You are a helpful translator"
}
```

**Supported Models**:
- OpenAI: `gpt-3.5-turbo`, `gpt-4`, `gpt-4-turbo-preview`
- Anthropic: `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`, `claude-3-opus-20240229`

**Response**:
```json
{
  "success": true,
  "data": {
    "response": "שלום",
    "model": "gpt-3.5-turbo",
    "usage": {
      "prompt_tokens": 15,
      "completion_tokens": 5,
      "total_tokens": 20
    }
  }
}
```

### Email Integration

#### Send Email

```http
POST /api/integrations/sendEmail
```

**Authentication**: Required
**Rate Limit**: 200 emails per hour

**Request Body**:
```json
{
  "to": "user@example.com",
  "subject": "Welcome to Ludora",
  "html": "<h1>Welcome!</h1>",
  "text": "Welcome!",
  "from": "noreply@ludora.app"
}
```

**Multiple Recipients**:
```json
{
  "to": ["user1@example.com", "user2@example.com"],
  "subject": "Newsletter",
  "html": "<h1>Newsletter</h1>"
}
```

### File Integration

#### Upload File

```http
POST /api/integrations/uploadFile
```

**Authentication**: Required
**Rate Limit**: 50 uploads per 15 minutes
**Content-Type**: `multipart/form-data`
**File Limits**: 50MB maximum

**Form Fields**:
- `file` - File to upload

**Response**:
```json
{
  "success": true,
  "data": {
    "fileId": "file_id",
    "url": "https://storage.ludora.com/files/file_id", // this is wrong!
    "fileName": "document.pdf",
    "size": 1048576,
    "mimeType": "application/pdf"
  }
}
```

#### Upload Private File

```http
POST /api/integrations/uploadPrivateFile
```

**Authentication**: Required
**Form Fields**:
- `file` - File to upload
- `folder` - Storage folder
- `tags` - File tags

#### Extract Data from File

```http
POST /api/integrations/extractDataFromUploadedFile
```

**Authentication**: Required
**Form Fields**:
- `file` - File to analyze
- `extractionType` - Type of extraction

**Authentication**: Required
**Rate Limit**: 100 requests per hour

**Request Body**:
```json
{
  "prompt": "A cute cartoon cat",
  "size": "1024x1024",
  "style": "natural",
  "quality": "standard"
}
```

**Sizes**: `256x256`, `512x512`, `1024x1024`
**Styles**: `natural`, `vivid`, `artistic`
**Quality**: `standard`, `hd`

**Response**:
```json
{
  "success": true,
  "data": {
    "imageId": "img_123456",
    "url": "https://images.ludora.com/generated/123456.png", // this is wrong!
    "prompt": "A cute cartoon cat",
    "size": "1024x1024",
    "generatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Integration Health & Capabilities

#### Health Check

```http
GET /api/integrations/health
```

**Authentication**: None
**Response**:
```json
{
  "status": "healthy",
  "integrations": {
    "llm": "available",
    "email": "available",
    "fileUpload": "available",
    "imageGeneration": "available",
    "dataExtraction": "available",
    "signedUrls": "available"
  },
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

#### Get Capabilities

```http
GET /api/integrations/capabilities
```

**Authentication**: Optional
**Response**:
```json
{
  "llm": {
    "models": ["gpt-3.5-turbo", "claude-3-sonnet-20240229"],
    "maxTokens": 8192,
    "supportedLanguages": ["en", "he", "es", "fr", "ar"]
  },
  "email": {
    "providers": ["smtp", "sendgrid"],
    "features": ["html", "text", "templates"],
    "templateTypes": ["registration_confirmation", "payment_confirmation"]
  },
  "fileUpload": {
    "maxSize": "50MB",
    "supportedTypes": ["image/jpeg", "application/pdf"],
    "storage": ["local", "s3"],
    "features": ["public-upload", "private-upload", "signed-urls"]
  },
  "environment": {
    "llmProviders": {
      "openai": true,
      "anthropic": true
    },
    "email": true
  }
}
```

#### Get LLM Models

```http
GET /api/integrations/llm/models
```

**Authentication**: Optional
**Response**:
```json
{
  "success": true,
  "data": {
    "openai": ["gpt-3.5-turbo", "gpt-4"],
    "anthropic": ["claude-3-sonnet-20240229"],
    "capabilities": {
      "chat": true,
      "completion": true,
      "embedding": true
    }
  }
}
```

---

## Logging

### Create Log Entry

```http
POST /api/logs
```

**Authentication**: Optional
**Request Body**:
```json
{
  "source_type": "app",
  "log_type": "error",
  "message": "User login failed"
}
```

**Source Types**: `app`, `api`
**Log Types**: `log`, `error`, `debug`, `warn`, `info`

**Response**:
```json
{
  "success": true,
  "id": "log_id"
}
```

### Get Logs (Admin)

```http
GET /api/logs?source_type=app&log_type=error&limit=100&offset=0
```

**Authentication**: Required
**Query Parameters**:
- `source_type` (optional) - Filter by source
- `log_type` (optional) - Filter by log type
- `user_id` (optional) - Filter by user
- `limit` (number, default: 100) - Number of results
- `offset` (number, default: 0) - Pagination offset
- `start_date` (ISO string) - Start date filter
- `end_date` (ISO string) - End date filter

**Response**:
```json
{
  "success": true,
  "logs": [
    {
      "id": "log_id",
      "source_type": "app",
      "log_type": "error",
      "message": "User login failed",
      "user_id": "user_id",
      "created_at": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "limit": 100,
    "offset": 0
  }
}
```

---

## Error Handling

### Standard Error Response Format

```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE",
    "statusCode": 400,
    "details": {},
    "requestId": "req_123456789"
  }
}
```

### HTTP Status Codes

- `200` - OK
- `201` - Created
- `206` - Partial Content (video streaming)
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `413` - Payload Too Large
- `416` - Range Not Satisfiable
- `429` - Too Many Requests
- `500` - Internal Server Error
- `503` - Service Unavailable

### Error Codes

#### Authentication Errors
- `UNAUTHORIZED` - Missing or invalid authentication
- `FORBIDDEN` - Insufficient permissions
- `INVALID_TOKEN` - Token format is invalid
- `TOKEN_EXPIRED` - Token has expired

#### Validation Errors
- `VALIDATION_ERROR` - Request validation failed
- `BAD_REQUEST` - Invalid request format
- `UNIQUE_CONSTRAINT_ERROR` - Duplicate resource
- `FOREIGN_KEY_CONSTRAINT_ERROR` - Invalid reference

#### Resource Errors
- `NOT_FOUND` - Resource not found
- `CONFLICT` - Resource conflict

#### Rate Limiting
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `TOO_MANY_REQUESTS` - Rate limit exceeded

#### File Upload Errors
- `FILE_UPLOAD_ERROR` - General upload error
- `FILE_TOO_LARGE` - File exceeds size limit
- `INVALID_FILE_TYPE` - Unsupported file type

#### System Errors
- `INTERNAL_ERROR` - Internal server error
- `DATABASE_ERROR` - Database operation failed
- `SERVICE_UNAVAILABLE` - External service unavailable

### Error Details

Error responses may include additional details in the `details` field:

```json
{
  "error": {
    "message": "Validation failed",
    "code": "VALIDATION_ERROR",
    "statusCode": 400,
    "details": [
      {
        "field": "email",
        "message": "Please provide a valid email address",
        "value": "invalid-email"
      }
    ]
  }
}
```

---

## Rate Limiting

### Rate Limit Headers

All responses include rate limiting headers:

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

### Rate Limit Policies

| Endpoint Category | Limit | Window |
|------------------|-------|---------|
| Authentication | 10 requests | 15 minutes |
| General API | 10,000 requests | 15 minutes |
| LLM Integration | 100 requests | 1 hour |
| File Upload | 50 requests | 15 minutes |
| Email | 200 requests | 1 hour |

### Rate Limit Bypass

- Development environment: Rate limits are disabled
- API key authentication: May have different limits

---

## Middleware

### Security Middleware

- **Helmet**: Security headers protection
- **CORS**: Cross-origin resource sharing
- **Request ID**: Unique request tracking
- **Request Logging**: Request/response logging

### Authentication Middleware

- **`authenticateToken`**: Validates JWT/Firebase tokens
- **`optionalAuth`**: Optional authentication
- **`requireRole`**: Role-based access control
- **`requireUserType`**: User type verification
- **`requireOwnership`**: Resource ownership verification

### Validation Middleware

- **`validateBody`**: Request body validation with Joi
- **`validateQuery`**: Query parameter validation
- **`validateEntityType`**: Entity type validation
- **`validateFileUpload`**: File upload validation

### Custom Middleware

- **`requestIdMiddleware`**: Adds unique request ID
- **`requestLogger`**: Logs requests and responses
- **`globalErrorHandler`**: Global error handling
- **`notFoundHandler`**: 404 error handling

---

## Health Check & System Info

### Health Check

```http
GET /health
```

**Authentication**: None
**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 86400,
  "environment": "development",
  "version": "1.0.0",
  "services": {
    "database": "connected",
    "email": "configured",
    "storage": "local",
    "llm": {
      "openai": "configured",
      "anthropic": "configured"
    }
  }
}
```

### API Info

```http
GET /api
```

**Authentication**: None
**Response**:
```json
{
  "name": "Ludora API",
  "version": "1.0.0",
  "environment": "development",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "endpoints": {
    "auth": "/api/auth",
    "entities": "/api/entities",
    "functions": "/api/functions",
    "integrations": "/api/integrations",
    "videos": "/api/videos",
    "access": "/api/access",
    "game-content-templates": "/api/game-content-templates",
    "game-content-usage": "/api/games"
  }
}
```

### Root Endpoint

```http
GET /
```

**Authentication**: None
**Response**:
```json
{
  "message": "Ludora API is running",
  "environment": "development",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "1.0.0",
  "status": "healthy"
}
```

---

## Notes

- All endpoints return JSON responses
- Timestamps are in ISO 8601 format (UTC)
- File uploads use multipart/form-data
- Rate limits are enforced per IP address
- Authentication tokens should be included in the Authorization header
- The API supports CORS for frontend integration
- All file operations include security headers
- Video streaming supports HTTP Range requests for efficient playback
- Content creator permissions are required for certain entity types
- Access control is automatically applied to media endpoints

---

*This documentation covers the complete Ludora API as migrated from the base44 platform. For specific implementation details or troubleshooting, refer to the source code or contact the development team.*
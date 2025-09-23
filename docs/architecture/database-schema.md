# Database Schema Documentation

Complete documentation of the Ludora PostgreSQL database schema, including all tables, relationships, and data patterns.

## Overview

The Ludora database uses a hybrid approach combining structured relational tables with flexible JSONB columns for dynamic data. This provides both queryability and flexibility for educational content management.

## Core Entity Tables

### user
Primary user entity supporting multi-role authentication.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Unique user identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User email address |
| full_name | VARCHAR(255) | NOT NULL | User's full name |
| role | VARCHAR(50) | NOT NULL, DEFAULT 'user' | User role (user, teacher, staff, admin) |
| user_type | VARCHAR(50) | DEFAULT 'regular' | User type classification |
| is_verified | BOOLEAN | DEFAULT false | Email verification status |
| is_active | BOOLEAN | DEFAULT true | Account active status |
| phone | VARCHAR(50) | | Phone number |
| address | TEXT | | Physical address |
| birth_date | DATE | | Date of birth |
| avatar_url | VARCHAR(255) | | Profile picture URL |
| settings | JSONB | DEFAULT '{}' | User preferences and settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| last_login | TIMESTAMP | | Last login timestamp |

**Indexes:**
- `idx_user_email` - Unique index on email
- `idx_user_role` - Index on role for permission queries
- `idx_user_created_at` - Index for user listing

**Role Hierarchy:**
- `user` (0) - Basic user permissions
- `teacher` (1) - Classroom management permissions
- `staff` (2) - Content moderation permissions
- `admin` (3) - Full system access

### school
Educational institution management.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | School identifier |
| name | VARCHAR(255) | NOT NULL | School name |
| address | TEXT | | School address |
| phone | VARCHAR(50) | | Contact phone |
| email | VARCHAR(255) | | Contact email |
| principal_name | VARCHAR(255) | | Principal's name |
| settings | JSONB | DEFAULT '{}' | School-specific settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### classroom
Teacher-managed classroom organization.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Classroom identifier |
| name | VARCHAR(255) | NOT NULL | Classroom name |
| teacher_user_id | VARCHAR(255) | FK to user(id), NOT NULL | Teacher who manages this classroom |
| school_id | VARCHAR(255) | FK to school(id) | Associated school |
| grade_level | VARCHAR(50) | | Grade level (1-12) |
| subject | VARCHAR(100) | | Primary subject |
| description | TEXT | | Classroom description |
| settings | JSONB | DEFAULT '{}' | Classroom-specific settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

**Relationships:**
- classroom.teacher_user_id → user.id (Many-to-One)
- classroom.school_id → school.id (Many-to-One)

### classroom_membership
Student-classroom relationships.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Membership identifier |
| classroom_id | VARCHAR(255) | FK to classroom(id), NOT NULL | Classroom reference |
| student_user_id | VARCHAR(255) | FK to user(id), NOT NULL | Student reference |
| joined_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | When student joined |
| status | VARCHAR(50) | DEFAULT 'active' | Membership status |

**Unique Constraints:**
- `unique_classroom_student` - (classroom_id, student_user_id)

### student_invitation
Student invitation workflow for classroom enrollment.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Invitation identifier |
| classroom_id | VARCHAR(255) | FK to classroom(id), NOT NULL | Target classroom |
| student_email | VARCHAR(255) | NOT NULL | Invited student email |
| invitation_code | VARCHAR(255) | UNIQUE, NOT NULL | Unique invitation code |
| status | VARCHAR(50) | DEFAULT 'pending' | Invitation status |
| invited_by_user_id | VARCHAR(255) | FK to user(id) | Teacher who sent invitation |
| expires_at | TIMESTAMP | | Invitation expiration |
| accepted_at | TIMESTAMP | | When invitation was accepted |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

## Product Entity Tables

### workshop
Educational workshop entity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Workshop identifier |
| title | VARCHAR(255) | NOT NULL | Workshop title |
| description | TEXT | | Workshop description |
| video_file_url | VARCHAR(255) | | Workshop video URL |
| is_live | BOOLEAN | DEFAULT false | Live vs recorded workshop |
| schedule_date | TIMESTAMP | | Scheduled date for live workshops |
| duration_minutes | INTEGER | | Workshop duration |
| creator_user_id | VARCHAR(255) | FK to user(id) | Workshop creator |
| price | DECIMAL(10,2) | DEFAULT 0 | Workshop price |
| is_published | BOOLEAN | DEFAULT false | Published status |
| category | VARCHAR(100) | | Workshop category |
| tags | JSONB | DEFAULT '[]' | Workshop tags |
| settings | JSONB | DEFAULT '{}' | Workshop-specific settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### course
Multi-module educational course entity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Course identifier |
| title | VARCHAR(255) | NOT NULL | Course title |
| description | TEXT | | Course description |
| course_modules | JSONB | DEFAULT '[]' | Array of course modules |
| total_duration_minutes | INTEGER | | Total course duration |
| difficulty_level | VARCHAR(50) | | Course difficulty |
| creator_user_id | VARCHAR(255) | FK to user(id) | Course creator |
| price | DECIMAL(10,2) | DEFAULT 0 | Course price |
| is_published | BOOLEAN | DEFAULT false | Published status |
| category | VARCHAR(100) | | Course category |
| tags | JSONB | DEFAULT '[]' | Course tags |
| settings | JSONB | DEFAULT '{}' | Course-specific settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### file
Digital file/download entity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | File identifier |
| title | VARCHAR(255) | NOT NULL | File title |
| description | TEXT | | File description |
| file_url | VARCHAR(255) | NOT NULL | File storage URL |
| file_type | VARCHAR(100) | | File MIME type |
| file_size | BIGINT | | File size in bytes |
| download_count | INTEGER | DEFAULT 0 | Number of downloads |
| creator_user_id | VARCHAR(255) | FK to user(id) | File creator |
| price | DECIMAL(10,2) | DEFAULT 0 | File price |
| is_published | BOOLEAN | DEFAULT false | Published status |
| category | VARCHAR(100) | | File category |
| tags | JSONB | DEFAULT '[]' | File tags |
| settings | JSONB | DEFAULT '{}' | File-specific settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### tool
Educational tool/application entity.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Tool identifier |
| title | VARCHAR(255) | NOT NULL | Tool title |
| description | TEXT | | Tool description |
| tool_url | VARCHAR(255) | | External tool URL |
| file_url | VARCHAR(255) | | Downloadable tool file |
| tool_type | VARCHAR(100) | | Tool category type |
| creator_user_id | VARCHAR(255) | FK to user(id) | Tool creator |
| price | DECIMAL(10,2) | DEFAULT 0 | Tool price |
| is_published | BOOLEAN | DEFAULT false | Published status |
| category | VARCHAR(100) | | Tool category |
| tags | JSONB | DEFAULT '[]' | Tool tags |
| settings | JSONB | DEFAULT '{}' | Tool-specific settings |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

## Business Operation Tables

### purchase
Polymorphic purchase tracking with access control.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Purchase identifier |
| buyer_email | VARCHAR(255) | NOT NULL | Purchaser email |
| buyer_user_id | VARCHAR(255) | FK to user(id) | Purchaser user ID |
| purchasable_type | VARCHAR(50) | | Entity type (workshop, course, file, tool) |
| purchasable_id | VARCHAR(255) | | Entity ID (polymorphic) |
| product_id | VARCHAR(255) | | Legacy product ID |
| price_paid | DECIMAL(10,2) | NOT NULL | Amount paid |
| payment_method | VARCHAR(50) | | Payment method used |
| payment_status | VARCHAR(50) | DEFAULT 'pending' | Payment status |
| transaction_id | VARCHAR(255) | | External transaction ID |
| access_expires_at | TIMESTAMP | | Access expiration (NULL = lifetime) |
| purchased_lifetime_access | BOOLEAN | DEFAULT false | Lifetime access flag |
| purchased_access_days | INTEGER | | Access duration in days |
| metadata | JSONB | DEFAULT '{}' | Purchase metadata |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

**Indexes:**
- `idx_purchase_buyer_email` - Fast lookup by buyer
- `idx_purchase_polymorphic` - (purchasable_type, purchasable_id)
- `idx_purchase_status` - Payment status queries

### subscription_plan
Available subscription plans.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Plan identifier |
| name | VARCHAR(255) | NOT NULL | Plan name |
| description | TEXT | | Plan description |
| price_monthly | DECIMAL(10,2) | | Monthly price |
| price_yearly | DECIMAL(10,2) | | Yearly price |
| benefits | JSONB | NOT NULL | Plan benefits and features |
| is_active | BOOLEAN | DEFAULT true | Plan availability |
| display_order | INTEGER | DEFAULT 0 | Display ordering |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

**Benefits Structure:**
```json
{
  "video_access": true,
  "workshop_videos": true,
  "course_videos": true,
  "all_content": true,
  "priority_support": true,
  "max_classrooms": 10
}
```

### subscription_history
User subscription tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Subscription identifier |
| user_id | VARCHAR(255) | FK to user(id), NOT NULL | Subscriber |
| subscription_plan_id | VARCHAR(255) | FK to subscription_plan(id) | Plan reference |
| status | VARCHAR(50) | NOT NULL | Subscription status |
| start_date | TIMESTAMP | NOT NULL | Subscription start |
| end_date | TIMESTAMP | | Subscription end |
| auto_renew | BOOLEAN | DEFAULT true | Auto-renewal setting |
| payment_method | VARCHAR(50) | | Payment method |
| external_subscription_id | VARCHAR(255) | | External payment processor ID |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

## Game System Tables

### game
Educational game entity with flexible JSONB settings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Game identifier |
| title | VARCHAR(255) | NOT NULL | Game title |
| description | TEXT | | Game description |
| game_type | VARCHAR(50) | NOT NULL | Game type (memory_game, scatter_game, etc.) |
| creator_user_id | VARCHAR(255) | FK to user(id) | Game creator |
| is_published | BOOLEAN | DEFAULT false | Published status |
| game_settings | JSONB | DEFAULT '{}' | Game configuration |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

**Game Types:**
- `memory_game` - Memory matching game
- `scatter_game` - Spatial word/image placement
- `wisdom_maze` - Quiz-based navigation
- `sharp_and_smooth` - Audio discrimination
- `ar_up_there` - AR vocabulary game

**Game Settings Structure (varies by type):**
```json
{
  "pairs_count": 8,
  "match_time_limit": 30,
  "difficulty_progression": {
    "enabled": true,
    "stages": [...]
  },
  "content_stages": [
    {
      "stage_number": 1,
      "contentConnection": {
        "type": "rule",
        "content": [...],
        "rules": [...]
      }
    }
  ]
}
```

### game_content_rule
Rules for smart content selection in games.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Rule identifier |
| rule_id | VARCHAR(255) | NOT NULL | Rule reference ID |
| content_type | VARCHAR(255) | NOT NULL | Target content type |
| content_id | VARCHAR(255) | NOT NULL | Target content ID |
| connection_type | VARCHAR(20) | DEFAULT 'manual' | Connection method |
| connection_config | JSONB | DEFAULT '{}' | Connection configuration |
| is_excluded | BOOLEAN | DEFAULT false | Exclusion flag |
| order_index | INTEGER | | Content ordering |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### game_content_usage
Game instances with content assignments.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Usage identifier |
| game_id | VARCHAR(255) | FK to game(id), NOT NULL | Game reference |
| content_resolved | JSONB | DEFAULT '{}' | Resolved content for game |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

## Content System Tables

### content_list
Organized collections of educational content.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | List identifier |
| name | VARCHAR(255) | NOT NULL | List name |
| description | TEXT | | List description |
| content_type | VARCHAR(100) | NOT NULL | Type of content in list |
| items | JSONB | DEFAULT '[]' | Array of content items |
| tags | JSONB | DEFAULT '[]' | Content tags |
| creator_user_id | VARCHAR(255) | FK to user(id) | List creator |
| is_public | BOOLEAN | DEFAULT false | Public visibility |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### word
Hebrew vocabulary content.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Word identifier |
| hebrew_word | VARCHAR(255) | NOT NULL | Hebrew word |
| english_translation | VARCHAR(255) | | English translation |
| pronunciation | VARCHAR(255) | | Pronunciation guide |
| definition | TEXT | | Word definition |
| example_sentence | TEXT | | Usage example |
| category | VARCHAR(100) | | Word category |
| difficulty_level | INTEGER | DEFAULT 1 | Difficulty (1-5) |
| audio_url | VARCHAR(255) | | Pronunciation audio |
| image_url | VARCHAR(255) | | Associated image |
| tags | JSONB | DEFAULT '[]' | Word tags |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### word_en
English vocabulary content.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Word identifier |
| english_word | VARCHAR(255) | NOT NULL | English word |
| hebrew_translation | VARCHAR(255) | | Hebrew translation |
| pronunciation | VARCHAR(255) | | Pronunciation guide |
| definition | TEXT | | Word definition |
| example_sentence | TEXT | | Usage example |
| category | VARCHAR(100) | | Word category |
| difficulty_level | INTEGER | DEFAULT 1 | Difficulty (1-5) |
| audio_url | VARCHAR(255) | | Pronunciation audio |
| image_url | VARCHAR(255) | | Associated image |
| tags | JSONB | DEFAULT '[]' | Word tags |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### image
Educational image content.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Image identifier |
| title | VARCHAR(255) | NOT NULL | Image title |
| description | TEXT | | Image description |
| image_url | VARCHAR(255) | NOT NULL | Image file URL |
| alt_text | VARCHAR(255) | | Accessibility alt text |
| category | VARCHAR(100) | | Image category |
| tags | JSONB | DEFAULT '[]' | Image tags |
| creator_user_id | VARCHAR(255) | FK to user(id) | Image uploader |
| is_public | BOOLEAN | DEFAULT false | Public visibility |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### qa
Question and answer content.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Q&A identifier |
| question | TEXT | NOT NULL | Question text |
| answer | TEXT | NOT NULL | Answer text |
| category | VARCHAR(100) | | Q&A category |
| difficulty_level | INTEGER | DEFAULT 1 | Difficulty (1-5) |
| multiple_choice_options | JSONB | | Multiple choice options |
| explanation | TEXT | | Answer explanation |
| tags | JSONB | DEFAULT '[]' | Q&A tags |
| creator_user_id | VARCHAR(255) | FK to user(id) | Q&A creator |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

## Compliance Tables

### parent_consent
COPPA compliance for users under 13.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | VARCHAR(255) | PRIMARY KEY | Consent identifier |
| child_user_id | VARCHAR(255) | FK to user(id), NOT NULL | Child user |
| parent_email | VARCHAR(255) | NOT NULL | Parent email |
| parent_name | VARCHAR(255) | NOT NULL | Parent name |
| consent_given | BOOLEAN | DEFAULT false | Consent status |
| consent_date | TIMESTAMP | | When consent was given |
| consent_method | VARCHAR(50) | | How consent was obtained |
| verification_token | VARCHAR(255) | | Email verification token |
| expires_at | TIMESTAMP | | Consent expiration |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

## Database Indexes

### Performance Indexes
```sql
-- User queries
CREATE INDEX idx_user_email ON "user"(email);
CREATE INDEX idx_user_role ON "user"(role);
CREATE INDEX idx_user_created_at ON "user"(created_at);

-- Purchase queries
CREATE INDEX idx_purchase_buyer_email ON purchase(buyer_email);
CREATE INDEX idx_purchase_polymorphic ON purchase(purchasable_type, purchasable_id);
CREATE INDEX idx_purchase_status ON purchase(payment_status);

-- Game queries
CREATE INDEX idx_game_type ON game(game_type);
CREATE INDEX idx_game_published ON game(is_published);
CREATE INDEX idx_game_creator ON game(creator_user_id);

-- JSONB indexes for game settings
CREATE INDEX idx_game_pairs_count ON game
USING BTREE (((game_settings->>'pairs_count')::int))
WHERE game_type = 'memory_game';

CREATE INDEX idx_game_settings_published ON game
USING GIN ((game_settings->'is_published'));

-- Content queries
CREATE INDEX idx_content_type ON content_list(content_type);
CREATE INDEX idx_word_category ON word(category);
CREATE INDEX idx_image_public ON image(is_public);
```

## Data Relationships

### Primary Relationships
```
user (1) ←→ (M) classroom [teacher_user_id]
classroom (1) ←→ (M) classroom_membership
user (1) ←→ (M) classroom_membership [student_user_id]

user (1) ←→ (M) purchase [buyer_user_id]
purchase (M) ←→ (1) [workshop|course|file|tool] [polymorphic]

user (1) ←→ (M) subscription_history
subscription_history (M) ←→ (1) subscription_plan

user (1) ←→ (M) game [creator_user_id]
game (1) ←→ (M) game_content_usage
game_content_rule (M) ←→ (1) content_list

user (1) ←→ (M) parent_consent [child_user_id]
```

### Business Logic Relationships
- **Access Control**: Purchase records control access to purchased entities
- **Subscription Benefits**: Active subscriptions provide feature access
- **Content Resolution**: Game content rules resolve to actual content
- **Ownership**: Creator users can edit their created content
- **School Organization**: Schools contain classrooms, classrooms contain students

## Data Patterns

### JSONB Usage Patterns
1. **Game Settings**: Flexible game configuration per game type
2. **User Settings**: User preferences and app settings
3. **Content Tags**: Searchable tag arrays
4. **Purchase Metadata**: Additional purchase information
5. **Subscription Benefits**: Feature flags and limits

### Polymorphic Patterns
1. **Purchase System**: Single purchase table for all product types
2. **Content System**: Flexible content type support
3. **Game Rules**: Different rule types for content selection

For more details on JSONB patterns and query optimization, see [Database Patterns](./database-patterns.md).

## Migration Management

All schema changes are managed through Sequelize migrations located in `/ludora-api/migrations/`.

**Migration Naming Convention:**
```
YYYYMMDDHHMMSS-description-of-change.js
```

**Common Migration Patterns:**
- Table creation with proper indexes
- JSONB field additions with GIN indexes
- Foreign key constraint additions
- Data transformation migrations

For migration best practices, see [Development Guidelines](../development/database-migrations.md).
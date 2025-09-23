# Ludora Project Context for AI Assistants

This document provides essential context about the Ludora educational gaming platform to help AI assistants understand the project's goals, constraints, and current state.

## Project Overview

**Ludora** is a comprehensive educational gaming platform that creates, manages, and delivers interactive educational content for students, teachers, and educational institutions in Israel.

### Primary Goals
1. **Educational Excellence**: Create engaging game-based learning experiences
2. **Teacher Empowerment**: Provide tools for classroom management and student progress tracking
3. **Content Creator Economy**: Enable educators to create and monetize educational content
4. **Scalable Platform**: Support multiple schools and thousands of users
5. **Hebrew-First Design**: Native Hebrew support with English as secondary language

### Target Users
- **Students**: Ages 6-18, primarily Hebrew speakers
- **Teachers**: Classroom educators needing digital tools
- **Parents**: Monitoring child progress and permissions
- **Content Creators**: Educators creating educational products
- **School Administrators**: Managing institutional accounts

## Current System State

### Migration Status
- **FROM**: Base44 platform (legacy)
- **TO**: Custom API and modern React frontend
- **STATUS**: Migration mostly complete, some legacy references remain

### Technical Architecture
- **Backend**: Node.js + Express + PostgreSQL (fully custom)
- **Frontend**: React 18 + Vite + Tailwind CSS
- **Database**: PostgreSQL with hybrid JSONB patterns
- **Authentication**: Firebase Auth + JWT tokens
- **Storage**: AWS S3 with local fallback

### Deployment Environments
- **Development**: Local development with hot reload
- **Staging**: Pre-production testing environment
- **Production**: Live platform serving users

## Core Business Logic

### Educational Games System
**Game Types:**
- Memory Game - Matching pairs with educational content
- Scatter Game - Spatial learning with words/images
- Wisdom Maze - Quiz-based navigation game
- Sharp & Smooth - Audio discrimination game
- AR Up There - Augmented reality vocabulary game

**Content Management:**
- Multi-language support (Hebrew/English)
- Rich content types: words, images, audio, Q&A
- Rule-based content selection for personalized learning
- Template-driven game configuration

### Business Model
**Revenue Streams:**
1. **Individual Purchases**: One-time product purchases
2. **Subscriptions**: Monthly/annual plans with feature access
3. **School Licenses**: Institutional pricing for classrooms
4. **Content Creator Revenue**: Commission-based earnings

**Product Types:**
- Workshops (הדרכות) - Live or recorded educational sessions
- Courses (קורסים) - Multi-module learning programs
- Files (קבצים) - Digital downloads and resources
- Tools (כלים) - Educational utilities and applications
- Games (משחקים) - Interactive educational games

### User Management
**Role Hierarchy:**
- Admin (3) - Full platform access
- Staff (2) - Content moderation and support
- Teacher (1) - Classroom and content creation
- User (0) - Basic access and purchases

**Special Considerations:**
- COPPA compliance for users under 13
- Parent consent workflow
- Hebrew right-to-left text support
- Israeli payment processing (PayPlus)

## Architecture Constraints

### Performance Requirements
- **Page Load**: < 3 seconds on 3G connections
- **API Response**: < 500ms for typical requests
- **Video Streaming**: HTTP Range support for large files
- **Mobile Support**: Responsive design for tablets

### Security Requirements
- **Authentication**: Multi-factor authentication for admin roles
- **Data Protection**: Encryption at rest and in transit
- **Access Control**: Role-based permissions with ownership verification
- **Content Security**: Protected file access with time-limited URLs

### Scalability Considerations
- **Database**: Efficient JSONB indexing for game settings
- **File Storage**: S3 CDN for media delivery
- **API Design**: Stateless architecture for horizontal scaling
- **Frontend**: Code splitting and lazy loading

## Development Patterns

### Code Organization
- **Backend**: Feature-based routing with shared middleware
- **Frontend**: Component-based architecture with shared UI library
- **Database**: Hybrid approach with structured tables + JSONB flexibility
- **Testing**: Comprehensive test coverage for critical paths

### Naming Conventions
- **Database**: snake_case for tables and fields
- **API**: camelCase for JSON properties
- **Frontend**: PascalCase for components, camelCase for functions
- **Files**: kebab-case for file names

### Git Workflow
- **Main Branch**: Production-ready code
- **Feature Branches**: Feature development with descriptive names
- **Pull Requests**: Required for all changes with review
- **Commit Messages**: Conventional commits format

## Current Technical Debt

### Known Issues
1. **Legacy Product Table**: Being refactored to dedicated entity tables
2. **Mixed Auth Patterns**: Some endpoints use different auth methods
3. **Frontend Bundle Size**: Could benefit from further optimization
4. **Test Coverage**: Some newer features lack comprehensive tests

### Ongoing Refactoring
- **Product Entity Split**: Workshop, Course, File, Tool entities
- **Purchase System Enhancement**: Polymorphic relationships
- **Video Streaming**: Access control optimization
- **Database Indexing**: Performance optimization for JSONB queries

## Quality Standards

### Code Quality
- **Linting**: ESLint for JavaScript, automated formatting
- **Type Safety**: Zod validation for runtime type checking
- **Error Handling**: Structured error responses with proper status codes
- **Documentation**: Inline comments for complex business logic

### Testing Requirements
- **Unit Tests**: Critical business logic functions
- **Integration Tests**: API endpoints and database operations
- **Frontend Tests**: Component behavior and user interactions
- **End-to-End**: Critical user journeys

### Performance Standards
- **API Response Times**: 95th percentile < 1 second
- **Database Queries**: Indexed queries for common operations
- **Frontend Performance**: Lighthouse scores > 90
- **Bundle Size**: Critical chunks < 250KB

## Educational Domain Knowledge

### Hebrew Language Support
- **RTL Layout**: Right-to-left text and interface elements
- **Font Support**: Hebrew Unicode support with proper rendering
- **Input Methods**: Hebrew keyboard support and validation
- **Cultural Context**: Israeli educational system understanding

### Pedagogical Considerations
- **Age-Appropriate Content**: Different complexity levels for age groups
- **Learning Objectives**: Content mapped to educational standards
- **Progress Tracking**: Meaningful metrics for learning outcomes
- **Accessibility**: Support for learning disabilities and special needs

### Content Creation Guidelines
- **Quality Standards**: Educational value and accuracy requirements
- **Content Moderation**: Review process for user-generated content
- **Licensing**: Clear rights management for created content
- **Localization**: Hebrew-first with English translation support

## Integration Requirements

### External Services
- **Firebase**: Authentication and user management
- **AWS S3**: File storage and CDN delivery
- **PayPlus**: Israeli payment processing
- **Email Services**: Automated communication workflows

### API Compatibility
- **RESTful Design**: Consistent endpoint patterns
- **Versioning**: API versioning strategy for breaking changes
- **Rate Limiting**: Protection against abuse and overuse
- **Documentation**: OpenAPI/Swagger compatibility

## AI Assistant Guidelines

### When Working on Ludora
1. **Read Relevant Documentation**: Always check existing docs before making changes
2. **Follow Established Patterns**: Use existing patterns for consistency
3. **Update Documentation**: Document changes as you make them
4. **Consider Hebrew Support**: Test RTL layout and Hebrew text
5. **Maintain Security**: Follow authentication and authorization patterns
6. **Test Thoroughly**: Ensure changes don't break existing functionality

### Common Tasks
- **Adding New Features**: Follow the established entity pattern
- **Bug Fixes**: Check for similar patterns in working code
- **Database Changes**: Use Sequelize migrations, consider JSONB indexing
- **Frontend Changes**: Follow component patterns, maintain responsive design
- **API Changes**: Follow RESTful conventions, update documentation

### Avoid These Mistakes
- **Breaking Authentication**: Always maintain proper auth middleware
- **Ignoring RTL**: Consider Hebrew layout in UI changes
- **Database Direct Changes**: Use migrations, don't modify tables directly
- **Hardcoded Values**: Use environment variables for configuration
- **Missing Error Handling**: Implement proper error responses

## Project Priorities

### High Priority (Always Consider)
1. **User Experience**: Especially for Hebrew-speaking educators
2. **Security**: Protect student data and financial transactions
3. **Performance**: Maintain fast load times for classroom use
4. **Educational Value**: Ensure changes support learning objectives

### Medium Priority
1. **Code Quality**: Maintain patterns and documentation
2. **Testing**: Add tests for new functionality
3. **Scalability**: Consider future growth in design decisions
4. **Developer Experience**: Keep development workflows smooth

### Low Priority
1. **Feature Completeness**: Focus on core functionality first
2. **UI Polish**: Functionality over aesthetics
3. **Advanced Features**: Ensure basics work before adding complexity

This context should guide AI assistants to make informed decisions that align with Ludora's educational mission, technical architecture, and user needs.
# Ludora Frontend Documentation

Welcome to the Ludora frontend documentation. This guide provides comprehensive information about the architecture, patterns, and development practices used in the Ludora React application.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Development Guidelines](#development-guidelines)
4. [Component Patterns](#component-patterns)
5. [State Management](#state-management)
6. [API Integration](#api-integration)
7. [Styling Guide](#styling-guide)
8. [Testing](#testing)

## Project Overview

Ludora is a React-based educational gaming platform built with modern web technologies:

- **Framework**: React 18.2+ with Vite
- **Routing**: React Router v7
- **Styling**: Tailwind CSS with Radix UI components
- **Forms**: React Hook Form with Zod validation
- **State Management**: React Context API
- **Testing**: Vitest with Testing Library
- **Authentication**: Firebase Auth integration

## Architecture

The frontend follows a feature-based architecture with clear separation of concerns:

```
src/
├── components/          # Reusable UI components
│   ├── ui/             # Base UI components (Radix-based)
│   ├── auth/           # Authentication components
│   ├── layout/         # Layout components
│   ├── shared/         # Shared business components
│   └── [feature]/      # Feature-specific components
├── pages/              # Route-level page components
├── contexts/           # React Context providers
├── hooks/              # Custom React hooks
├── services/           # API services and entities
├── utils/              # Utility functions
├── lib/                # Library configurations
└── styles/             # Global styles
```

## Development Guidelines

### File Naming Conventions
- Components: PascalCase (e.g., `UserProfile.jsx`)
- Hooks: camelCase with `use` prefix (e.g., `useUserData.js`)
- Services: camelCase (e.g., `apiClient.js`)
- Utils: camelCase (e.g., `formatDate.js`)

### Component Structure
```jsx
// Import order: React, third-party, internal
import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { useUser } from '@/contexts/UserContext';

export default function ComponentName({ prop1, prop2 }) {
  // State declarations
  const [state, setState] = useState(null);

  // Context usage
  const { currentUser } = useUser();

  // Event handlers
  const handleClick = () => {
    // Implementation
  };

  // Early returns for loading/error states
  if (loading) return <div>Loading...</div>;

  // Main render
  return (
    <div className="container">
      {/* Component content */}
    </div>
  );
}
```

## Quick Start Links

- [Component Patterns](./component-patterns.md) - Reusable component patterns and best practices
- [State Management](./state-management.md) - Context usage and state patterns
- [API Integration](./api-integration.md) - Service layer and data fetching patterns
- [Styling Guide](./styling-guide.md) - Tailwind CSS and UI component usage
- [Form Handling](./form-handling.md) - React Hook Form patterns and validation
- [Authentication](./authentication.md) - Auth flow and protected routes
- [Testing Patterns](./testing-patterns.md) - Testing strategies and examples

## Key Features

### Responsive Design
- Mobile-first approach with Tailwind CSS
- Responsive breakpoints: 768px (mobile), 1024px (tablet), 1280px (desktop)
- RTL (Right-to-Left) language support for Hebrew

### Accessibility
- ARIA attributes on interactive elements
- Semantic HTML structure
- Keyboard navigation support
- Screen reader compatibility

### Performance
- Code splitting with React Router
- Lazy loading of components
- Optimized bundle size with Vite
- Image optimization

### Developer Experience
- Hot module replacement in development
- TypeScript support for type safety
- ESLint and Prettier for code quality
- Pre-commit hooks for quality assurance

For detailed information on specific topics, please refer to the individual documentation files in this directory.
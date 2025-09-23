# Styling Guide

This document covers the styling approach, design system, and UI patterns used in the Ludora frontend application.

## Design System Overview

Ludora uses a modern design system built on:
- **Tailwind CSS** for utility-first styling
- **Radix UI** for accessible component primitives
- **Class Variance Authority (CVA)** for component variants
- **Tailwind Merge** for class conflict resolution
- **CSS Variables** for dynamic theming

## Tailwind CSS Configuration

### Custom Configuration

```javascript
// tailwind.config.js
module.exports = {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{ts,tsx,js,jsx}"],
  theme: {
    extend: {
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)'
      },
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))'
        },
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))'
        },
        // ... more colors
      },
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' }
        }
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out'
      }
    }
  },
  plugins: [require("tailwindcss-animate")]
}
```

### CSS Variables for Theming

```css
/* /src/index.css */
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --card: 0 0% 100%;
  --card-foreground: 222.2 84% 4.9%;
  --popover: 0 0% 100%;
  --popover-foreground: 222.2 84% 4.9%;
  --primary: 221.2 83.2% 53.3%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222.2 84% 4.9%;
  --muted: 210 40% 96%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --accent: 210 40% 96%;
  --accent-foreground: 222.2 84% 4.9%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 210 40% 98%;
  --border: 214.3 31.8% 91.4%;
  --input: 214.3 31.8% 91.4%;
  --ring: 221.2 83.2% 53.3%;
  --radius: 0.5rem;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  /* ... dark theme variables */
}
```

## Component Styling Patterns

### Class Variance Authority (CVA) Pattern

```jsx
// /src/components/ui/button.jsx
import { cva } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  // Base classes
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
        outline: "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

const Button = React.forwardRef(({ className, variant, size, asChild = false, ...props }, ref) => {
  const Comp = asChild ? Slot : "button";
  return (
    <Comp
      className={cn(buttonVariants({ variant, size, className }))}
      ref={ref}
      {...props}
    />
  );
});
```

### Utility Function for Class Merging

```javascript
// /src/lib/utils.js
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs) {
  return twMerge(clsx(inputs));
}
```

## Radix UI Integration

### Dialog Component

```jsx
// /src/components/ui/dialog.jsx
import * as DialogPrimitive from "@radix-ui/react-dialog";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";

const Dialog = DialogPrimitive.Root;
const DialogTrigger = DialogPrimitive.Trigger;

const DialogOverlay = React.forwardRef(({ className, ...props }, ref) => (
  <DialogPrimitive.Overlay
    ref={ref}
    className={cn(
      "fixed inset-0 z-50 bg-black/80 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
      className
    )}
    {...props}
  />
));

const DialogContent = React.forwardRef(({ className, children, ...props }, ref) => (
  <DialogPortal>
    <DialogOverlay />
    <DialogPrimitive.Content
      ref={ref}
      className={cn(
        "fixed left-[50%] top-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-background p-6 shadow-lg duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%] data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%] sm:rounded-lg",
        className
      )}
      {...props}
    >
      {children}
      <DialogPrimitive.Close className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground">
        <X className="h-4 w-4" />
        <span className="sr-only">Close</span>
      </DialogPrimitive.Close>
    </DialogPrimitive.Content>
  </DialogPortal>
));
```

## Responsive Design Patterns

### Breakpoint Strategy

```jsx
// Mobile-first responsive design
<div className="
  grid grid-cols-1        // Mobile: 1 column
  md:grid-cols-2          // Tablet: 2 columns
  lg:grid-cols-3          // Desktop: 3 columns
  xl:grid-cols-4          // Large: 4 columns
  gap-4                   // Consistent gap
  p-4                     // Padding
  md:p-6                  // Larger padding on tablet+
  lg:p-8                  // Even larger on desktop
">
```

### Container Patterns

```jsx
// Page container
<div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-indigo-50/50">
  <div className="max-w-6xl mx-auto p-4 md:p-8">
    {/* Page content */}
  </div>
</div>

// Card container
<div className="bg-white/90 backdrop-blur-sm rounded-3xl p-12 shadow-2xl border border-gray-200/50">
  {/* Card content */}
</div>
```

### Mobile-First Hook

```jsx
// /src/hooks/use-mobile.jsx
import * as React from "react";

const MOBILE_BREAKPOINT = 768;

export function useIsMobile() {
  const [isMobile, setIsMobile] = React.useState(undefined);

  React.useEffect(() => {
    const mql = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`);
    const onChange = () => {
      setIsMobile(window.innerWidth < MOBILE_BREAKPOINT);
    };
    mql.addEventListener("change", onChange);
    setIsMobile(window.innerWidth < MOBILE_BREAKPOINT);
    return () => mql.removeEventListener("change", onChange);
  }, []);

  return !!isMobile;
}

// Usage
export default function ResponsiveComponent() {
  const isMobile = useIsMobile();

  return (
    <div className={cn(
      "grid gap-4",
      isMobile ? "grid-cols-1" : "grid-cols-3"
    )}>
      {/* Content */}
    </div>
  );
}
```

## RTL (Right-to-Left) Support

### RTL Styling Patterns

```jsx
// RTL container
<div className="container" dir="rtl">
  <div className="text-right">
    <h1 className="text-xl font-semibold text-gray-900">
      שלום, {currentUser?.display_name}
    </h1>
  </div>
</div>

// RTL navigation
<div className="flex items-center gap-4 mb-6">
  <Button
    variant="outline"
    onClick={onCancel}
    className="flex items-center gap-2"
  >
    <ArrowLeft className="w-4 h-4" />
    חזרה
  </Button>
</div>
```

## Animation Patterns

### CSS Animations

```css
/* Loading spinner */
.animate-spin {
  animation: spin 1s linear infinite;
}

/* Fade in */
.animate-in {
  animation: fadeIn 0.2s ease-out;
}

/* Accordion animations */
.accordion-down {
  animation: accordion-down 0.2s ease-out;
}

.accordion-up {
  animation: accordion-up 0.2s ease-out;
}
```

### Framer Motion Integration

```jsx
import { motion } from "framer-motion";

// Page transitions
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: -20 }}
  transition={{ duration: 0.3 }}
>
  {/* Page content */}
</motion.div>

// Stagger animations
<motion.div
  variants={{
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  }}
  initial="hidden"
  animate="show"
>
  {items.map((item, index) => (
    <motion.div
      key={item.id}
      variants={{
        hidden: { opacity: 0, y: 20 },
        show: { opacity: 1, y: 0 }
      }}
    >
      {item.content}
    </motion.div>
  ))}
</motion.div>
```

## Loading States

### Skeleton Loading

```jsx
// /src/components/ui/skeleton.jsx
export function Skeleton({ className, ...props }) {
  return (
    <div
      className={cn("animate-pulse rounded-md bg-muted", className)}
      {...props}
    />
  );
}

// Usage
<div className="space-y-4">
  <Skeleton className="h-4 w-[250px]" />
  <Skeleton className="h-4 w-[200px]" />
  <Skeleton className="h-4 w-[150px]" />
</div>
```

### Loading Spinner Patterns

```jsx
// Page-level loading
<div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-indigo-50/50 flex items-center justify-center">
  <div className="text-center">
    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
    <p className="text-gray-600">טוען...</p>
  </div>
</div>

// Button loading state
<Button disabled={isLoading}>
  {isLoading ? (
    <>
      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
      שומר...
    </>
  ) : (
    <>
      <Check className="w-4 h-4" />
      שמור
    </>
  )}
</Button>
```

## Form Styling

### Form Layout Patterns

```jsx
<Form {...form}>
  <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
    <FormField
      control={form.control}
      name="email"
      render={({ field }) => (
        <FormItem>
          <FormLabel>Email</FormLabel>
          <FormControl>
            <Input
              type="email"
              placeholder="Enter your email"
              className={cn(
                "transition-colors",
                field.error && "border-destructive focus:border-destructive"
              )}
              {...field}
            />
          </FormControl>
          <FormMessage />
        </FormItem>
      )}
    />
  </form>
</Form>
```

### Input Styling

```jsx
// /src/components/ui/input.jsx
const Input = React.forwardRef(({ className, type, ...props }, ref) => {
  return (
    <input
      type={type}
      className={cn(
        "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
        className
      )}
      ref={ref}
      {...props}
    />
  );
});
```

## Icon Usage

### Lucide React Icons

```jsx
import { User, Settings, LogOut, ChevronDown } from "lucide-react";

// Icon in button
<Button>
  <User className="w-4 h-4 mr-2" />
  Profile
</Button>

// Icon with consistent sizing
<div className="flex items-center gap-2">
  <Settings className="w-5 h-5 text-gray-500" />
  <span>Settings</span>
</div>
```

## Color System

### Semantic Colors

```jsx
// Status colors
<Badge variant="success">Active</Badge>        // Green
<Badge variant="destructive">Error</Badge>      // Red
<Badge variant="secondary">Inactive</Badge>     // Gray
<Badge variant="outline">Pending</Badge>        // Outlined

// Background gradients
<div className="bg-gradient-to-br from-gray-50 via-blue-50/30 to-indigo-50/50">
  {/* Content */}
</div>

// Text colors
<h1 className="text-gray-900">Primary heading</h1>
<p className="text-gray-600">Secondary text</p>
<span className="text-muted-foreground">Muted text</span>
```

## Best Practices

### 1. Class Organization
```jsx
// Group classes logically
<div className={cn(
  // Layout
  "flex items-center justify-between",
  // Spacing
  "p-4 mb-6",
  // Appearance
  "bg-white border border-gray-200 rounded-lg shadow-sm",
  // Responsive
  "md:p-6 lg:p-8",
  // Conditional
  isActive && "ring-2 ring-blue-500",
  className
)}>
```

### 2. Performance Considerations
- Use `cn()` utility for class merging
- Avoid inline styles when possible
- Leverage CSS custom properties for dynamic values
- Use appropriate specificity levels

### 3. Accessibility
- Maintain color contrast ratios
- Use semantic HTML elements
- Provide focus indicators
- Support keyboard navigation

### 4. Consistency
- Use design tokens consistently
- Follow established spacing scales
- Maintain consistent component variants
- Document custom patterns

### 5. Responsive Design
- Follow mobile-first approach
- Test across different screen sizes
- Use appropriate breakpoints
- Consider touch targets on mobile

This styling guide ensures consistency, maintainability, and accessibility across the Ludora application while providing a excellent developer experience.
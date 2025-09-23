# Component Patterns

This document outlines the reusable component patterns and best practices used in the Ludora frontend.

## Component Architecture

### Base UI Components (`/components/ui/`)

The application uses a design system built on Radix UI primitives with Tailwind CSS styling. All base components follow consistent patterns:

#### Button Component Pattern
```jsx
import { cva } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
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

**Key Patterns:**
- Use `class-variance-authority` (CVA) for variant-based styling
- Support `asChild` prop for composition
- Forward refs for accessibility
- Consistent naming for variants and sizes

### Form Components

#### Form Pattern with React Hook Form
```jsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

const formSchema = z.object({
  email: z.string().email('Invalid email address'),
  name: z.string().min(2, 'Name must be at least 2 characters'),
});

export default function ContactForm({ onSubmit }) {
  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: '',
      name: '',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input placeholder="Enter your name" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" placeholder="Enter your email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit" disabled={form.formState.isSubmitting}>
          Submit
        </Button>
      </form>
    </Form>
  );
}
```

### Wizard/Stepper Components

#### WizardShell Pattern
The application includes a reusable wizard shell for multi-step forms:

```jsx
import WizardShell from '@/components/shared/WizardShell';

const steps = [
  {
    id: 'basic-info',
    title: 'Basic Information',
    component: BasicInfoStep,
    validate: (data) => {
      // Return { isValid: boolean, errors: object }
    }
  },
  {
    id: 'details',
    title: 'Details',
    component: DetailsStep,
    validate: (data) => ({ isValid: true, errors: {} })
  }
];

export default function CreateItemWizard() {
  const [currentStep, setCurrentStep] = useState(0);
  const [data, setData] = useState({});

  return (
    <WizardShell
      title="Create New Item"
      subtitle="Follow the steps to create your item"
      steps={steps}
      currentStep={currentStep}
      onStepChange={setCurrentStep}
      data={data}
      onDataChange={setData}
      onSave={handleSave}
      onCancel={handleCancel}
    />
  );
}
```

**Features:**
- Automatic step validation
- Progress indicators
- Navigation controls
- Loading states
- Error handling

### Loading States

#### Consistent Loading Patterns
```jsx
// Page-level loading
if (isLoading) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50/30 to-indigo-50/50 flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto mb-4"></div>
        <p className="text-gray-600">Loading...</p>
      </div>
    </div>
  );
}

// Component-level loading
<Button disabled={isLoading}>
  {isLoading ? (
    <>
      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
      Loading...
    </>
  ) : (
    'Submit'
  )}
</Button>
```

### Modal/Dialog Patterns

#### Dialog Component Usage
```jsx
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

export default function SettingsModal({ children }) {
  return (
    <Dialog>
      <DialogTrigger asChild>
        {children}
      </DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Settings</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          {/* Modal content */}
        </div>
      </DialogContent>
    </Dialog>
  );
}
```

### Data Display Patterns

#### Card Layout Pattern
```jsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function DataCard({ title, data, actions }) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        {actions}
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{data.value}</div>
        <p className="text-xs text-muted-foreground">{data.description}</p>
      </CardContent>
    </Card>
  );
}
```

## Component Composition Patterns

### Higher-Order Components (HOCs)

#### Protected Route Pattern
```jsx
import { useUser } from '@/contexts/UserContext';
import { Navigate } from 'react-router-dom';

export default function ProtectedRoute({ children }) {
  const { currentUser, isLoading } = useUser();

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (!currentUser) {
    return <Navigate to="/" replace />;
  }

  return children;
}
```

### Render Props Pattern

#### Data Fetcher Component
```jsx
export default function DataFetcher({ url, children }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Fetch data logic
  }, [url]);

  return children({ data, loading, error });
}

// Usage
<DataFetcher url="/api/users">
  {({ data, loading, error }) => {
    if (loading) return <div>Loading...</div>;
    if (error) return <div>Error: {error.message}</div>;
    return <UserList users={data} />;
  }}
</DataFetcher>
```

## Best Practices

### 1. Component Naming
- Use descriptive, noun-based names
- Prefix with feature area when needed (e.g., `UserProfileCard`)
- Avoid abbreviations

### 2. Props Interface
```jsx
// Good: Clear prop types with defaults
export default function UserCard({
  user,
  showActions = true,
  onEdit,
  onDelete,
  className = ""
}) {
  // Component implementation
}

// Better: With PropTypes or TypeScript
UserCard.propTypes = {
  user: PropTypes.shape({
    id: PropTypes.string.required,
    name: PropTypes.string.required,
    email: PropTypes.string.required,
  }).required,
  showActions: PropTypes.bool,
  onEdit: PropTypes.func,
  onDelete: PropTypes.func,
  className: PropTypes.string,
};
```

### 3. Event Handling
```jsx
// Good: Descriptive handler names
const handleUserEdit = (userId) => {
  // Handle edit
};

const handleUserDelete = (userId) => {
  // Handle delete
};

// Good: Prevent default when needed
const handleFormSubmit = (e) => {
  e.preventDefault();
  // Handle submission
};
```

### 4. Conditional Rendering
```jsx
// Good: Early returns for loading states
if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorMessage error={error} />;

// Good: Logical AND for optional content
{showActions && (
  <div className="actions">
    <Button onClick={onEdit}>Edit</Button>
    <Button variant="destructive" onClick={onDelete}>Delete</Button>
  </div>
)}

// Good: Ternary for either/or scenarios
{user.isActive ? (
  <Badge variant="success">Active</Badge>
) : (
  <Badge variant="secondary">Inactive</Badge>
)}
```

### 5. Performance Optimization
```jsx
// Use React.memo for expensive components
const ExpensiveComponent = React.memo(({ data }) => {
  // Expensive rendering logic
  return <div>{/* Rendered content */}</div>;
});

// Use useMemo for expensive calculations
const expensiveValue = useMemo(() => {
  return data.reduce((acc, item) => acc + item.value, 0);
}, [data]);

// Use useCallback for event handlers passed to children
const handleItemClick = useCallback((id) => {
  // Handle click
}, []);
```

## Feature-Specific Component Patterns

### Authentication Components
Located in `/components/auth/`:
- `ProtectedRoute` - Route protection wrapper
- `AdminRoute` - Admin-only route protection
- `LoginModal` - Authentication modal

### Layout Components
Located in `/components/layout/`:
- Responsive navigation
- Header/footer components
- Sidebar layouts

### Game Builder Components
Located in `/components/gameBuilder/`:
- Multi-step game creation wizard
- Content management interfaces
- Rule builder components

This component architecture ensures consistency, reusability, and maintainability across the Ludora application.
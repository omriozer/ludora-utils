# Form Handling

This document covers form patterns, validation strategies, and best practices for handling forms in the Ludora frontend application.

## Form Architecture

Ludora uses React Hook Form with Zod validation for robust form handling. This combination provides:

- **Type-safe validation** with Zod schemas
- **Performance optimization** with uncontrolled components
- **Accessible form controls** with proper error handling
- **Consistent user experience** across all forms

## React Hook Form Setup

### Basic Form Pattern

```jsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

// Define validation schema
const formSchema = z.object({
  email: z.string()
    .email('Please enter a valid email address')
    .min(1, 'Email is required'),
  name: z.string()
    .min(2, 'Name must be at least 2 characters')
    .max(50, 'Name must be less than 50 characters'),
  age: z.number()
    .min(18, 'Must be at least 18 years old')
    .max(120, 'Age must be realistic'),
});

export default function UserForm({ onSubmit, defaultValues = {} }) {
  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: '',
      name: '',
      age: 18,
      ...defaultValues
    },
  });

  const handleSubmit = async (data) => {
    try {
      await onSubmit(data);
      form.reset();
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-6">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Full Name</FormLabel>
              <FormControl>
                <Input placeholder="Enter your full name" {...field} />
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
              <FormLabel>Email Address</FormLabel>
              <FormControl>
                <Input type="email" placeholder="Enter your email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="age"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Age</FormLabel>
              <FormControl>
                <Input
                  type="number"
                  placeholder="Enter your age"
                  {...field}
                  onChange={(e) => field.onChange(parseInt(e.target.value))}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button
          type="submit"
          disabled={form.formState.isSubmitting}
          className="w-full"
        >
          {form.formState.isSubmitting ? 'Submitting...' : 'Submit'}
        </Button>
      </form>
    </Form>
  );
}
```

## Advanced Form Patterns

### Multi-Step Form with Wizard

```jsx
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import WizardShell from '@/components/shared/WizardShell';

// Step schemas
const basicInfoSchema = z.object({
  firstName: z.string().min(2, 'First name is required'),
  lastName: z.string().min(2, 'Last name is required'),
  email: z.string().email('Invalid email address'),
});

const contactSchema = z.object({
  phone: z.string().min(10, 'Phone number is required'),
  address: z.string().min(5, 'Address is required'),
  city: z.string().min(2, 'City is required'),
});

const preferencesSchema = z.object({
  notifications: z.boolean(),
  newsletter: z.boolean(),
  language: z.enum(['en', 'he']),
});

// Complete form schema
const completeSchema = basicInfoSchema.and(contactSchema).and(preferencesSchema);

// Step components
function BasicInfoStep({ data, onDataChange, validationErrors }) {
  const form = useForm({
    resolver: zodResolver(basicInfoSchema),
    defaultValues: data,
  });

  useEffect(() => {
    const subscription = form.watch((value) => {
      onDataChange(value);
    });
    return () => subscription.unsubscribe();
  }, [form, onDataChange]);

  return (
    <Form {...form}>
      <div className="space-y-4">
        <FormField
          control={form.control}
          name="firstName"
          render={({ field }) => (
            <FormItem>
              <FormLabel>First Name</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        {/* More fields... */}
      </div>
    </Form>
  );
}

export default function MultiStepUserForm() {
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState({});
  const [validationErrors, setValidationErrors] = useState({});

  const steps = [
    {
      id: 'basic-info',
      title: 'Basic Information',
      component: BasicInfoStep,
      validate: (data) => {
        try {
          basicInfoSchema.parse(data);
          return { isValid: true, errors: {} };
        } catch (error) {
          const errors = {};
          error.errors.forEach(err => {
            errors[err.path[0]] = err.message;
          });
          return { isValid: false, errors };
        }
      }
    },
    {
      id: 'contact',
      title: 'Contact Information',
      component: ContactStep,
      validate: (data) => {
        // Similar validation logic
      }
    },
    {
      id: 'preferences',
      title: 'Preferences',
      component: PreferencesStep,
      validate: (data) => {
        // Similar validation logic
      }
    }
  ];

  const handleSave = async (data) => {
    try {
      // Validate complete form
      completeSchema.parse(data);

      // Submit to API
      await createUser(data);

      // Success handling
      toast.success('User created successfully');
      navigate('/users');
    } catch (error) {
      toast.error('Failed to create user');
      throw error;
    }
  };

  return (
    <WizardShell
      title="Create New User"
      subtitle="Fill in the user information"
      steps={steps}
      currentStep={currentStep}
      onStepChange={setCurrentStep}
      data={formData}
      onDataChange={setFormData}
      validationErrors={validationErrors}
      onSave={handleSave}
      onCancel={() => navigate('/users')}
    />
  );
}
```

### Dynamic Form Fields

```jsx
import { useFieldArray } from 'react-hook-form';

const skillsSchema = z.object({
  skills: z.array(z.object({
    name: z.string().min(1, 'Skill name is required'),
    level: z.enum(['beginner', 'intermediate', 'advanced']),
  })).min(1, 'At least one skill is required'),
});

export default function SkillsForm() {
  const form = useForm({
    resolver: zodResolver(skillsSchema),
    defaultValues: {
      skills: [{ name: '', level: 'beginner' }]
    }
  });

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'skills'
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium">Skills</h3>
            <Button
              type="button"
              variant="outline"
              onClick={() => append({ name: '', level: 'beginner' })}
            >
              Add Skill
            </Button>
          </div>

          {fields.map((field, index) => (
            <div key={field.id} className="flex gap-4 items-start">
              <FormField
                control={form.control}
                name={`skills.${index}.name`}
                render={({ field }) => (
                  <FormItem className="flex-1">
                    <FormControl>
                      <Input placeholder="Skill name" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name={`skills.${index}.level`}
                render={({ field }) => (
                  <FormItem className="w-40">
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="beginner">Beginner</SelectItem>
                        <SelectItem value="intermediate">Intermediate</SelectItem>
                        <SelectItem value="advanced">Advanced</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {fields.length > 1 && (
                <Button
                  type="button"
                  variant="outline"
                  size="icon"
                  onClick={() => remove(index)}
                >
                  <X className="h-4 w-4" />
                </Button>
              )}
            </div>
          ))}
        </div>

        <Button type="submit">Save Skills</Button>
      </form>
    </Form>
  );
}
```

## Validation Patterns

### Custom Validation Rules

```jsx
// Custom validation functions
const isValidIsraeliID = (id) => {
  // Israeli ID validation logic
  if (!/^\d{9}$/.test(id)) return false;

  const digits = id.split('').map(Number);
  let sum = 0;

  for (let i = 0; i < 9; i++) {
    let digit = digits[i];
    if (i % 2 === 1) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
  }

  return sum % 10 === 0;
};

// Zod schema with custom validation
const userSchema = z.object({
  israeliId: z.string()
    .refine(isValidIsraeliID, {
      message: 'Invalid Israeli ID number'
    }),

  confirmPassword: z.string(),
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
});

// Async validation
const checkEmailAvailability = async (email) => {
  const response = await fetch(`/api/check-email?email=${email}`);
  const data = await response.json();
  return data.available;
};

const registrationSchema = z.object({
  email: z.string()
    .email('Invalid email address')
    .refine(async (email) => {
      return await checkEmailAvailability(email);
    }, {
      message: 'Email address is already taken'
    }),
});
```

### Conditional Validation

```jsx
const accountSchema = z.object({
  accountType: z.enum(['personal', 'business']),
  personalName: z.string().optional(),
  businessName: z.string().optional(),
  businessId: z.string().optional(),
}).refine((data) => {
  if (data.accountType === 'personal') {
    return data.personalName && data.personalName.length > 0;
  }
  return data.businessName && data.businessName.length > 0 &&
         data.businessId && data.businessId.length > 0;
}, {
  message: 'Please fill in all required fields for the selected account type',
  path: ['personalName'] // or determine dynamically
});
```

## File Upload Forms

### Single File Upload

```jsx
import { useCallback } from 'react';
import { useDropzone } from 'react-dropzone';

const fileUploadSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  file: z.instanceof(File, 'Please select a file'),
});

export default function FileUploadForm() {
  const form = useForm({
    resolver: zodResolver(fileUploadSchema),
    defaultValues: {
      title: '',
      description: '',
      file: null,
    }
  });

  const onDrop = useCallback((acceptedFiles) => {
    if (acceptedFiles.length > 0) {
      form.setValue('file', acceptedFiles[0]);
    }
  }, [form]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.gif'],
      'application/pdf': ['.pdf'],
    },
    maxSize: 10 * 1024 * 1024, // 10MB
    multiple: false,
  });

  const selectedFile = form.watch('file');

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        <FormField
          control={form.control}
          name="title"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Title</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="file"
          render={({ field }) => (
            <FormItem>
              <FormLabel>File</FormLabel>
              <FormControl>
                <div
                  {...getRootProps()}
                  className={cn(
                    "border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors",
                    isDragActive ? "border-primary bg-primary/5" : "border-gray-300",
                    selectedFile && "border-green-500 bg-green-50"
                  )}
                >
                  <input {...getInputProps()} />
                  {selectedFile ? (
                    <div>
                      <p className="text-sm font-medium">{selectedFile.name}</p>
                      <p className="text-xs text-gray-500">
                        {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
                      </p>
                    </div>
                  ) : (
                    <div>
                      <p>Drag & drop a file here, or click to select</p>
                      <p className="text-sm text-gray-500">
                        Supports images and PDFs up to 10MB
                      </p>
                    </div>
                  )}
                </div>
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? 'Uploading...' : 'Upload File'}
        </Button>
      </form>
    </Form>
  );
}
```

## Form State Management

### Auto-save Pattern

```jsx
import { useEffect } from 'react';
import { useDebouncedCallback } from 'use-debounce';

export default function AutoSaveForm() {
  const form = useForm({
    defaultValues: {
      title: '',
      content: '',
    }
  });

  // Debounced auto-save function
  const debouncedSave = useDebouncedCallback(
    async (data) => {
      try {
        await saveDraft(data);
        toast.success('Draft saved');
      } catch (error) {
        toast.error('Failed to save draft');
      }
    },
    2000 // 2 second delay
  );

  // Watch form changes
  useEffect(() => {
    const subscription = form.watch((data) => {
      // Only auto-save if form is dirty and valid
      if (form.formState.isDirty && Object.keys(form.formState.errors).length === 0) {
        debouncedSave(data);
      }
    });

    return () => subscription.unsubscribe();
  }, [form, debouncedSave]);

  return (
    <Form {...form}>
      {/* Form fields */}
    </Form>
  );
}
```

### Form State Persistence

```jsx
import { useEffect } from 'react';

export function useFormPersistence(form, storageKey) {
  // Load saved data on mount
  useEffect(() => {
    const savedData = localStorage.getItem(storageKey);
    if (savedData) {
      try {
        const parsedData = JSON.parse(savedData);
        form.reset(parsedData);
      } catch (error) {
        console.error('Failed to load saved form data:', error);
      }
    }
  }, [form, storageKey]);

  // Save data on form changes
  useEffect(() => {
    const subscription = form.watch((data) => {
      localStorage.setItem(storageKey, JSON.stringify(data));
    });

    return () => subscription.unsubscribe();
  }, [form, storageKey]);

  // Clear saved data
  const clearSavedData = () => {
    localStorage.removeItem(storageKey);
  };

  return { clearSavedData };
}

// Usage
export default function PersistentForm() {
  const form = useForm({
    defaultValues: {
      title: '',
      content: '',
    }
  });

  const { clearSavedData } = useFormPersistence(form, 'form-draft');

  const handleSubmit = async (data) => {
    await submitForm(data);
    clearSavedData(); // Clear draft after successful submission
    form.reset();
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)}>
        {/* Form fields */}
      </form>
    </Form>
  );
}
```

## Error Handling

### Form Error Boundary

```jsx
class FormErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Form error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="p-4 border border-red-200 rounded-lg bg-red-50">
          <h3 className="text-red-800 font-medium">Form Error</h3>
          <p className="text-red-600 text-sm mt-1">
            Something went wrong with the form. Please refresh and try again.
          </p>
          <Button
            variant="outline"
            size="sm"
            className="mt-2"
            onClick={() => this.setState({ hasError: false, error: null })}
          >
            Try Again
          </Button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Server Error Handling

```jsx
const handleSubmit = async (data) => {
  try {
    await submitForm(data);
    toast.success('Form submitted successfully');
  } catch (error) {
    // Handle validation errors from server
    if (error.status === 400 && error.response?.details) {
      error.response.details.forEach(detail => {
        form.setError(detail.field, {
          type: 'server',
          message: detail.message
        });
      });
    } else {
      // Handle general errors
      toast.error(error.message || 'Failed to submit form');
    }
  }
};
```

## Best Practices

### 1. Validation Strategy
- Use Zod for type-safe validation schemas
- Validate on blur for immediate feedback
- Show validation errors clearly and contextually
- Implement both client and server-side validation

### 2. Performance Optimization
- Use uncontrolled components with React Hook Form
- Debounce expensive validation operations
- Implement lazy validation for non-critical fields
- Minimize re-renders with proper dependency management

### 3. User Experience
- Provide clear error messages
- Show loading states during submission
- Implement auto-save for long forms
- Support keyboard navigation and shortcuts

### 4. Accessibility
- Use proper form labels and ARIA attributes
- Ensure error messages are announced by screen readers
- Support keyboard navigation
- Maintain focus management

### 5. Testing
- Test form validation logic thoroughly
- Mock API calls in form tests
- Test error scenarios and edge cases
- Validate form accessibility

This form handling approach ensures robust, user-friendly forms throughout the Ludora application while maintaining consistency and best practices.
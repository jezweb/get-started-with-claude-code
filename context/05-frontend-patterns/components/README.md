# Component Architecture Patterns

Comprehensive guide to modern component architecture patterns, design systems, and reusable component development across frontend frameworks.

## 🎯 Component Architecture Overview

Modern component architecture focuses on building reusable, composable, and maintainable UI components:
- **Atomic Design** - Breaking UI into hierarchical components
- **Composition over Inheritance** - Building complex UIs from simple parts
- **Single Responsibility** - Each component has one clear purpose
- **Props Interface** - Clear, documented component APIs
- **Design Systems** - Consistent, scalable component libraries

## 🏗️ Atomic Design Methodology

### Design System Hierarchy
```
Design System
├── Tokens (Colors, Typography, Spacing)
├── Atoms (Button, Input, Icon)
├── Molecules (SearchBox, Card Header)
├── Organisms (Navigation, Product Grid)
├── Templates (Page Layout)
└── Pages (Home, Product Detail)
```

### Atoms (Basic Building Blocks)
```jsx
// components/atoms/Button/Button.jsx
import { forwardRef } from 'react'
import { cva } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export const Button = forwardRef(({ 
  className, 
  variant, 
  size, 
  loading,
  children,
  ...props 
}, ref) => {
  return (
    <button
      className={cn(buttonVariants({ variant, size, className }))}
      ref={ref}
      disabled={loading || props.disabled}
      {...props}
    >
      {loading && (
        <svg className="mr-2 h-4 w-4 animate-spin" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
      )}
      {children}
    </button>
  )
})

Button.displayName = "Button"

// components/atoms/Input/Input.jsx
export const Input = forwardRef(({ 
  className, 
  type, 
  error,
  ...props 
}, ref) => {
  return (
    <input
      type={type}
      className={cn(
        "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
        error && "border-destructive focus-visible:ring-destructive",
        className
      )}
      ref={ref}
      {...props}
    />
  )
})

Input.displayName = "Input"

// components/atoms/Icon/Icon.jsx
import * as LucideIcons from 'lucide-react'

export function Icon({ name, size = 24, className, ...props }) {
  const IconComponent = LucideIcons[name]
  
  if (!IconComponent) {
    console.warn(`Icon "${name}" not found`)
    return null
  }
  
  return (
    <IconComponent
      size={size}
      className={className}
      {...props}
    />
  )
}

// Icon registry for better tree shaking
export const iconRegistry = {
  // Navigation
  Menu: LucideIcons.Menu,
  X: LucideIcons.X,
  ChevronDown: LucideIcons.ChevronDown,
  ArrowLeft: LucideIcons.ArrowLeft,
  
  // Actions
  Plus: LucideIcons.Plus,
  Edit: LucideIcons.Edit,
  Trash2: LucideIcons.Trash2,
  Save: LucideIcons.Save,
  
  // Status
  Check: LucideIcons.Check,
  AlertCircle: LucideIcons.AlertCircle,
  Info: LucideIcons.Info,
  Loader2: LucideIcons.Loader2,
}
```

### Molecules (Component Combinations)
```jsx
// components/molecules/SearchBox/SearchBox.jsx
import { useState } from 'react'
import { Input } from '@/components/atoms/Input'
import { Button } from '@/components/atoms/Button'
import { Icon } from '@/components/atoms/Icon'

export function SearchBox({ 
  placeholder = "Search...",
  onSearch,
  className 
}) {
  const [query, setQuery] = useState('')
  
  const handleSubmit = (e) => {
    e.preventDefault()
    onSearch?.(query)
  }
  
  const handleClear = () => {
    setQuery('')
    onSearch?.('')
  }
  
  return (
    <form onSubmit={handleSubmit} className={cn("relative flex gap-2", className)}>
      <div className="relative flex-1">
        <Input
          type="search"
          placeholder={placeholder}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="pr-10"
        />
        {query && (
          <button
            type="button"
            onClick={handleClear}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
          >
            <Icon name="X" size={16} />
          </button>
        )}
      </div>
      <Button type="submit" variant="outline" size="icon">
        <Icon name="Search" size={16} />
      </Button>
    </form>
  )
}

// components/molecules/AlertMessage/AlertMessage.jsx
const alertVariants = cva(
  "relative w-full rounded-lg border p-4 [&>svg~*]:pl-7 [&>svg+div]:translate-y-[-3px] [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg]:text-foreground",
  {
    variants: {
      variant: {
        default: "bg-background text-foreground",
        destructive: "border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive",
        warning: "border-orange-500/50 text-orange-600 dark:border-orange-500 [&>svg]:text-orange-600",
        success: "border-green-500/50 text-green-600 dark:border-green-500 [&>svg]:text-green-600",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
)

export function AlertMessage({ 
  className, 
  variant,
  title,
  children,
  onClose,
  ...props 
}) {
  const iconMap = {
    default: 'Info',
    destructive: 'AlertCircle',
    warning: 'AlertTriangle',
    success: 'CheckCircle'
  }
  
  return (
    <div
      role="alert"
      className={cn(alertVariants({ variant }), className)}
      {...props}
    >
      <Icon name={iconMap[variant]} size={16} />
      <div>
        {title && <h5 className="mb-1 font-medium leading-none tracking-tight">{title}</h5>}
        <div className="text-sm [&_p]:leading-relaxed">{children}</div>
      </div>
      {onClose && (
        <button
          onClick={onClose}
          className="absolute right-4 top-4 text-foreground/50 hover:text-foreground"
        >
          <Icon name="X" size={16} />
        </button>
      )}
    </div>
  )
}

// components/molecules/FormField/FormField.jsx
export function FormField({ 
  label, 
  error, 
  hint, 
  required,
  children,
  className 
}) {
  const fieldId = useId()
  
  return (
    <div className={cn("space-y-2", className)}>
      {label && (
        <label htmlFor={fieldId} className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
          {label}
          {required && <span className="text-destructive ml-1">*</span>}
        </label>
      )}
      
      <div className="relative">
        {React.cloneElement(children, { 
          id: fieldId,
          error: !!error,
          'aria-describedby': error ? `${fieldId}-error` : hint ? `${fieldId}-hint` : undefined
        })}
      </div>
      
      {hint && !error && (
        <p id={`${fieldId}-hint`} className="text-sm text-muted-foreground">
          {hint}
        </p>
      )}
      
      {error && (
        <p id={`${fieldId}-error`} className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  )
}
```

### Organisms (Complex Components)
```jsx
// components/organisms/DataTable/DataTable.jsx
import { useState, useMemo } from 'react'
import { Button } from '@/components/atoms/Button'
import { Input } from '@/components/atoms/Input'
import { Icon } from '@/components/atoms/Icon'

export function DataTable({ 
  data, 
  columns, 
  pagination = false,
  searchable = false,
  sortable = true,
  selectable = false,
  actions,
  loading = false,
  onRowClick,
  className 
}) {
  const [search, setSearch] = useState('')
  const [sortField, setSortField] = useState('')
  const [sortDirection, setSortDirection] = useState('asc')
  const [selectedRows, setSelectedRows] = useState(new Set())
  const [currentPage, setCurrentPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  
  // Filter data based on search
  const filteredData = useMemo(() => {
    if (!search) return data
    
    return data.filter(row => 
      columns.some(column => {
        const value = row[column.key]
        return value?.toString().toLowerCase().includes(search.toLowerCase())
      })
    )
  }, [data, search, columns])
  
  // Sort data
  const sortedData = useMemo(() => {
    if (!sortField) return filteredData
    
    return [...filteredData].sort((a, b) => {
      const aValue = a[sortField]
      const bValue = b[sortField]
      
      if (aValue < bValue) return sortDirection === 'asc' ? -1 : 1
      if (aValue > bValue) return sortDirection === 'asc' ? 1 : -1
      return 0
    })
  }, [filteredData, sortField, sortDirection])
  
  // Paginate data
  const paginatedData = useMemo(() => {
    if (!pagination) return sortedData
    
    const start = (currentPage - 1) * pageSize
    return sortedData.slice(start, start + pageSize)
  }, [sortedData, currentPage, pageSize, pagination])
  
  const handleSort = (field) => {
    if (!sortable) return
    
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('asc')
    }
  }
  
  const handleSelectAll = (checked) => {
    if (checked) {
      setSelectedRows(new Set(paginatedData.map(row => row.id)))
    } else {
      setSelectedRows(new Set())
    }
  }
  
  const handleSelectRow = (id, checked) => {
    const newSelected = new Set(selectedRows)
    if (checked) {
      newSelected.add(id)
    } else {
      newSelected.delete(id)
    }
    setSelectedRows(newSelected)
  }
  
  const totalPages = Math.ceil(sortedData.length / pageSize)
  const isAllSelected = paginatedData.length > 0 && paginatedData.every(row => selectedRows.has(row.id))
  const isPartialSelected = paginatedData.some(row => selectedRows.has(row.id)) && !isAllSelected
  
  if (loading) {
    return (
      <div className="flex items-center justify-center h-48">
        <Icon name="Loader2" className="animate-spin" size={32} />
      </div>
    )
  }
  
  return (
    <div className={cn("space-y-4", className)}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          {searchable && (
            <SearchBox
              placeholder="Search..."
              onSearch={setSearch}
              className="w-64"
            />
          )}
          
          {selectedRows.size > 0 && actions && (
            <div className="flex items-center gap-2">
              <span className="text-sm text-muted-foreground">
                {selectedRows.size} selected
              </span>
              {actions.map((action, index) => (
                <Button
                  key={index}
                  variant="outline"
                  size="sm"
                  onClick={() => action.onClick(Array.from(selectedRows))}
                >
                  {action.icon && <Icon name={action.icon} size={16} className="mr-1" />}
                  {action.label}
                </Button>
              ))}
            </div>
          )}
        </div>
        
        {pagination && (
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">
              {(currentPage - 1) * pageSize + 1}-{Math.min(currentPage * pageSize, sortedData.length)} of {sortedData.length}
            </span>
          </div>
        )}
      </div>
      
      {/* Table */}
      <div className="border rounded-lg overflow-hidden">
        <table className="w-full">
          <thead className="bg-muted/50">
            <tr>
              {selectable && (
                <th className="w-12 p-4">
                  <input
                    type="checkbox"
                    checked={isAllSelected}
                    ref={input => {
                      if (input) input.indeterminate = isPartialSelected
                    }}
                    onChange={(e) => handleSelectAll(e.target.checked)}
                    className="rounded border-border"
                  />
                </th>
              )}
              
              {columns.map((column) => (
                <th
                  key={column.key}
                  className={cn(
                    "text-left p-4 font-medium",
                    sortable && column.sortable !== false && "cursor-pointer hover:bg-muted/70"
                  )}
                  onClick={() => column.sortable !== false && handleSort(column.key)}
                >
                  <div className="flex items-center gap-2">
                    {column.title}
                    {sortable && sortField === column.key && (
                      <Icon
                        name={sortDirection === 'asc' ? 'ChevronUp' : 'ChevronDown'}
                        size={16}
                      />
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          
          <tbody>
            {paginatedData.map((row, index) => (
              <tr
                key={row.id || index}
                className={cn(
                  "border-t hover:bg-muted/30",
                  onRowClick && "cursor-pointer",
                  selectedRows.has(row.id) && "bg-primary/5"
                )}
                onClick={() => onRowClick?.(row)}
              >
                {selectable && (
                  <td className="p-4">
                    <input
                      type="checkbox"
                      checked={selectedRows.has(row.id)}
                      onChange={(e) => handleSelectRow(row.id, e.target.checked)}
                      onClick={(e) => e.stopPropagation()}
                      className="rounded border-border"
                    />
                  </td>
                )}
                
                {columns.map((column) => (
                  <td key={column.key} className="p-4">
                    {column.render ? column.render(row[column.key], row) : row[column.key]}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
        
        {paginatedData.length === 0 && (
          <div className="text-center py-12 text-muted-foreground">
            No data available
          </div>
        )}
      </div>
      
      {/* Pagination */}
      {pagination && totalPages > 1 && (
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">Rows per page:</span>
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value))
                setCurrentPage(1)
              }}
              className="border rounded px-2 py-1"
            >
              <option value={5}>5</option>
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
            </select>
          </div>
          
          <div className="flex items-center gap-1">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(1)}
              disabled={currentPage === 1}
            >
              <Icon name="ChevronsLeft" size={16} />
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
              disabled={currentPage === 1}
            >
              <Icon name="ChevronLeft" size={16} />
            </Button>
            
            <span className="mx-4 text-sm">
              Page {currentPage} of {totalPages}
            </span>
            
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
              disabled={currentPage === totalPages}
            >
              <Icon name="ChevronRight" size={16} />
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(totalPages)}
              disabled={currentPage === totalPages}
            >
              <Icon name="ChevronsRight" size={16} />
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}

// Usage
const columns = [
  { key: 'name', title: 'Name' },
  { key: 'email', title: 'Email' },
  { 
    key: 'status', 
    title: 'Status',
    render: (value) => (
      <span className={cn(
        "px-2 py-1 rounded-full text-xs font-medium",
        value === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
      )}>
        {value}
      </span>
    )
  },
  {
    key: 'actions',
    title: 'Actions',
    sortable: false,
    render: (_, row) => (
      <div className="flex gap-2">
        <Button variant="ghost" size="sm">
          <Icon name="Edit" size={16} />
        </Button>
        <Button variant="ghost" size="sm">
          <Icon name="Trash2" size={16} />
        </Button>
      </div>
    )
  }
]

<DataTable
  data={users}
  columns={columns}
  searchable
  selectable
  pagination
  actions={[
    { label: 'Delete Selected', icon: 'Trash2', onClick: (ids) => console.log('Delete', ids) }
  ]}
  onRowClick={(row) => console.log('Row clicked', row)}
/>
```

## 🎨 Vue Component Patterns

### Composition API Components
```vue
<!-- components/atoms/BaseButton.vue -->
<template>
  <button
    :class="buttonClasses"
    :disabled="loading || disabled"
    v-bind="$attrs"
    @click="handleClick"
  >
    <Icon v-if="loading" name="loader-2" class="mr-2 h-4 w-4 animate-spin" />
    <Icon v-else-if="icon" :name="icon" :class="iconClasses" />
    <span v-if="$slots.default">
      <slot />
    </span>
  </button>
</template>

<script setup>
import { computed } from 'vue'
import { cva } from 'class-variance-authority'
import Icon from './Icon.vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: (value) => ['default', 'destructive', 'outline', 'secondary', 'ghost', 'link'].includes(value)
  },
  size: {
    type: String,
    default: 'default',
    validator: (value) => ['default', 'sm', 'lg', 'icon'].includes(value)
  },
  icon: String,
  loading: Boolean,
  disabled: Boolean
})

const emit = defineEmits(['click'])

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

const buttonClasses = computed(() => 
  buttonVariants({ variant: props.variant, size: props.size })
)

const iconClasses = computed(() => ({
  'mr-2': !!$slots.default,
  'h-4 w-4': props.size !== 'icon',
  'h-5 w-5': props.size === 'icon'
}))

const handleClick = (event) => {
  if (!props.loading && !props.disabled) {
    emit('click', event)
  }
}
</script>

<!-- components/molecules/FormField.vue -->
<template>
  <div class="space-y-2">
    <label 
      v-if="label" 
      :for="fieldId" 
      class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
    >
      {{ label }}
      <span v-if="required" class="text-destructive ml-1">*</span>
    </label>
    
    <div class="relative">
      <slot 
        :field-id="fieldId"
        :has-error="!!error"
        :aria-describedby="error ? `${fieldId}-error` : hint ? `${fieldId}-hint` : undefined"
      />
    </div>
    
    <p 
      v-if="hint && !error" 
      :id="`${fieldId}-hint`" 
      class="text-sm text-muted-foreground"
    >
      {{ hint }}
    </p>
    
    <p 
      v-if="error" 
      :id="`${fieldId}-error`" 
      class="text-sm text-destructive"
    >
      {{ error }}
    </p>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  label: String,
  error: String,
  hint: String,
  required: Boolean
})

const fieldId = computed(() => `field-${Math.random().toString(36).substr(2, 9)}`)
</script>

<!-- components/organisms/UserForm.vue -->
<template>
  <form @submit.prevent="handleSubmit" class="space-y-6">
    <FormField
      label="Full Name"
      :error="errors.name"
      required
    >
      <template #default="{ fieldId, hasError }">
        <BaseInput
          :id="fieldId"
          v-model="form.name"
          placeholder="Enter your full name"
          :error="hasError"
        />
      </template>
    </FormField>

    <FormField
      label="Email Address"
      :error="errors.email"
      required
    >
      <template #default="{ fieldId, hasError }">
        <BaseInput
          :id="fieldId"
          v-model="form.email"
          type="email"
          placeholder="Enter your email"
          :error="hasError"
        />
      </template>
    </FormField>

    <FormField
      label="Bio"
      :error="errors.bio"
      hint="Tell us a bit about yourself"
    >
      <template #default="{ fieldId, hasError }">
        <BaseTextarea
          :id="fieldId"
          v-model="form.bio"
          placeholder="Your bio..."
          rows="4"
          :error="hasError"
        />
      </template>
    </FormField>

    <div class="flex gap-3">
      <BaseButton
        type="submit"
        :loading="isSubmitting"
        :disabled="!isValid"
      >
        {{ isEditing ? 'Update User' : 'Create User' }}
      </BaseButton>
      
      <BaseButton
        type="button"
        variant="outline"
        @click="resetForm"
      >
        Reset
      </BaseButton>
    </div>
  </form>
</template>

<script setup>
import { reactive, computed } from 'vue'
import { useFormValidation } from '@/composables/useFormValidation'
import FormField from '@/components/molecules/FormField.vue'
import BaseInput from '@/components/atoms/BaseInput.vue'
import BaseTextarea from '@/components/atoms/BaseTextarea.vue'
import BaseButton from '@/components/atoms/BaseButton.vue'

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({})
  },
  isEditing: Boolean
})

const emit = defineEmits(['submit', 'cancel'])

const form = reactive({
  name: props.initialData.name || '',
  email: props.initialData.email || '',
  bio: props.initialData.bio || ''
})

const validationRules = {
  name: [
    { required: true, message: 'Name is required' },
    { minLength: 2, message: 'Name must be at least 2 characters' }
  ],
  email: [
    { required: true, message: 'Email is required' },
    { email: true, message: 'Please enter a valid email address' }
  ],
  bio: [
    { maxLength: 500, message: 'Bio must be less than 500 characters' }
  ]
}

const { errors, isValid, validate, clearErrors } = useFormValidation(form, validationRules)

const isSubmitting = ref(false)

const handleSubmit = async () => {
  if (!validate()) return
  
  isSubmitting.value = true
  try {
    await emit('submit', { ...form })
    clearErrors()
  } catch (error) {
    console.error('Form submission error:', error)
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  Object.assign(form, {
    name: props.initialData.name || '',
    email: props.initialData.email || '',
    bio: props.initialData.bio || ''
  })
  clearErrors()
}
</script>
```

## 🔧 Advanced Component Patterns

### Render Props Pattern
```jsx
// components/patterns/RenderProps.jsx
function DataFetcher({ url, children }) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)
      setError(null)
      
      try {
        const response = await fetch(url)
        if (!response.ok) throw new Error('Failed to fetch')
        const result = await response.json()
        setData(result)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }
    
    fetchData()
  }, [url])
  
  return children({ data, loading, error })
}

// Usage
<DataFetcher url="/api/users">
  {({ data, loading, error }) => (
    <div>
      {loading && <div>Loading...</div>}
      {error && <div>Error: {error}</div>}
      {data && <UserList users={data} />}
    </div>
  )}
</DataFetcher>
```

### Compound Component Pattern
```jsx
// components/patterns/Tabs.jsx
const TabsContext = createContext()

function Tabs({ defaultValue, children, className }) {
  const [activeTab, setActiveTab] = useState(defaultValue)
  
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className={cn("w-full", className)}>
        {children}
      </div>
    </TabsContext.Provider>
  )
}

function TabsList({ children, className }) {
  return (
    <div className={cn("inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground", className)}>
      {children}
    </div>
  )
}

function TabsTrigger({ value, children, className }) {
  const { activeTab, setActiveTab } = useContext(TabsContext)
  const isActive = activeTab === value
  
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
        isActive ? "bg-background text-foreground shadow-sm" : "hover:bg-background/50",
        className
      )}
      onClick={() => setActiveTab(value)}
    >
      {children}
    </button>
  )
}

function TabsContent({ value, children, className }) {
  const { activeTab } = useContext(TabsContext)
  
  if (activeTab !== value) return null
  
  return (
    <div className={cn("mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2", className)}>
      {children}
    </div>
  )
}

// Attach components to main component
Tabs.List = TabsList
Tabs.Trigger = TabsTrigger
Tabs.Content = TabsContent

// Usage
<Tabs defaultValue="account">
  <Tabs.List>
    <Tabs.Trigger value="account">Account</Tabs.Trigger>
    <Tabs.Trigger value="password">Password</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="account">
    <AccountSettings />
  </Tabs.Content>
  <Tabs.Content value="password">
    <PasswordSettings />
  </Tabs.Content>
</Tabs>
```

### Higher-Order Component Pattern
```jsx
// components/patterns/withLoading.jsx
function withLoading(WrappedComponent) {
  return function WithLoadingComponent(props) {
    const [loading, setLoading] = useState(false)
    
    const showLoading = () => setLoading(true)
    const hideLoading = () => setLoading(false)
    
    if (loading) {
      return (
        <div className="flex items-center justify-center p-8">
          <Icon name="Loader2" className="animate-spin" size={24} />
          <span className="ml-2">Loading...</span>
        </div>
      )
    }
    
    return (
      <WrappedComponent
        {...props}
        showLoading={showLoading}
        hideLoading={hideLoading}
      />
    )
  }
}

// Usage
const UserListWithLoading = withLoading(UserList)

function UserList({ users, showLoading, hideLoading }) {
  useEffect(() => {
    const fetchUsers = async () => {
      showLoading()
      try {
        const response = await fetch('/api/users')
        const data = await response.json()
        setUsers(data)
      } finally {
        hideLoading()
      }
    }
    
    fetchUsers()
  }, [])
  
  return (
    <div>
      {users.map(user => <UserCard key={user.id} user={user} />)}
    </div>
  )
}
```

### Polymorphic Component Pattern
```jsx
// components/patterns/Polymorphic.jsx
const Polymorphic = forwardRef(({ as: Component = 'div', className, ...props }, ref) => {
  return <Component ref={ref} className={className} {...props} />
})

// More advanced polymorphic component
function Box({ as: Component = 'div', className, ...props }, ref) {
  return (
    <Component
      ref={ref}
      className={cn("box-border", className)}
      {...props}
    />
  )
}

// Usage
<Box>Default div</Box>
<Box as="section">Section element</Box>
<Box as="button" onClick={handleClick}>Button element</Box>
<Box as={Link} to="/home">Link component</Box>
```

## 🎯 Design System Implementation

### Design Tokens
```javascript
// tokens/design-tokens.js
export const designTokens = {
  colors: {
    primary: {
      50: '#eff6ff',
      100: '#dbeafe',
      500: '#3b82f6',
      600: '#2563eb',
      900: '#1e3a8a',
    },
    semantic: {
      success: '#10b981',
      warning: '#f59e0b',
      error: '#ef4444',
      info: '#3b82f6',
    }
  },
  
  typography: {
    fontFamily: {
      sans: ['Inter', 'system-ui', 'sans-serif'],
      mono: ['JetBrains Mono', 'monospace'],
    },
    fontSize: {
      xs: ['0.75rem', { lineHeight: '1rem' }],
      sm: ['0.875rem', { lineHeight: '1.25rem' }],
      base: ['1rem', { lineHeight: '1.5rem' }],
      lg: ['1.125rem', { lineHeight: '1.75rem' }],
      xl: ['1.25rem', { lineHeight: '1.75rem' }],
    }
  },
  
  spacing: {
    0: '0px',
    1: '0.25rem',
    2: '0.5rem',
    3: '0.75rem',
    4: '1rem',
    6: '1.5rem',
    8: '2rem',
    12: '3rem',
    16: '4rem',
  },
  
  borderRadius: {
    none: '0px',
    sm: '0.125rem',
    default: '0.25rem',
    md: '0.375rem',
    lg: '0.5rem',
    xl: '0.75rem',
    full: '9999px',
  },
  
  shadows: {
    sm: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
    default: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
    md: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
    lg: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
  }
}

// Theme provider
import { createContext, useContext } from 'react'

const ThemeContext = createContext()

export function ThemeProvider({ theme = designTokens, children }) {
  return (
    <ThemeContext.Provider value={theme}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => {
  const context = useContext(ThemeContext)
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider')
  }
  return context
}

// Styled system utilities
export function getSpacing(value) {
  const theme = useTheme()
  return theme.spacing[value] || value
}

export function getColor(path) {
  const theme = useTheme()
  const keys = path.split('.')
  return keys.reduce((obj, key) => obj?.[key], theme.colors)
}
```

### Component Documentation
```jsx
// components/Button/Button.stories.js
export default {
  title: 'Components/Button',
  component: Button,
  parameters: {
    docs: {
      description: {
        component: 'A versatile button component with multiple variants and sizes.'
      }
    }
  },
  argTypes: {
    variant: {
      control: { type: 'select' },
      options: ['default', 'destructive', 'outline', 'secondary', 'ghost', 'link'],
      description: 'Visual style variant'
    },
    size: {
      control: { type: 'select' },
      options: ['default', 'sm', 'lg', 'icon'],
      description: 'Size of the button'
    },
    loading: {
      control: { type: 'boolean' },
      description: 'Shows loading spinner'
    },
    disabled: {
      control: { type: 'boolean' },
      description: 'Disables the button'
    }
  }
}

const Template = (args) => <Button {...args}>Button</Button>

export const Default = Template.bind({})
Default.args = {}

export const Variants = () => (
  <div className="flex gap-2 flex-wrap">
    <Button variant="default">Default</Button>
    <Button variant="destructive">Destructive</Button>
    <Button variant="outline">Outline</Button>
    <Button variant="secondary">Secondary</Button>
    <Button variant="ghost">Ghost</Button>
    <Button variant="link">Link</Button>
  </div>
)

export const Sizes = () => (
  <div className="flex gap-2 items-center">
    <Button size="sm">Small</Button>
    <Button size="default">Default</Button>
    <Button size="lg">Large</Button>
    <Button size="icon">
      <Icon name="Plus" size={16} />
    </Button>
  </div>
)

export const Loading = () => (
  <div className="flex gap-2">
    <Button loading>Loading</Button>
    <Button loading variant="outline">Loading</Button>
  </div>
)

export const WithIcons = () => (
  <div className="flex gap-2">
    <Button>
      <Icon name="Plus" size={16} className="mr-2" />
      Add Item
    </Button>
    <Button variant="outline">
      Save
      <Icon name="Save" size={16} className="ml-2" />
    </Button>
  </div>
)
```

## 🧪 Component Testing

### Unit Testing Components
```javascript
// components/Button/Button.test.jsx
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  test('renders children correctly', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button')).toHaveTextContent('Click me')
  })
  
  test('applies variant classes correctly', () => {
    const { rerender } = render(<Button variant="destructive">Button</Button>)
    expect(screen.getByRole('button')).toHaveClass('bg-destructive')
    
    rerender(<Button variant="outline">Button</Button>)
    expect(screen.getByRole('button')).toHaveClass('border')
  })
  
  test('handles click events', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click me</Button>)
    
    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })
  
  test('shows loading state', () => {
    render(<Button loading>Loading</Button>)
    
    expect(screen.getByRole('button')).toBeDisabled()
    expect(screen.getByRole('button')).toHaveTextContent('Loading')
  })
  
  test('forwards ref correctly', () => {
    const ref = React.createRef()
    render(<Button ref={ref}>Button</Button>)
    
    expect(ref.current).toBeInstanceOf(HTMLButtonElement)
  })
})

// components/DataTable/DataTable.test.jsx
describe('DataTable Component', () => {
  const mockData = [
    { id: 1, name: 'John Doe', email: 'john@example.com', status: 'active' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com', status: 'inactive' }
  ]
  
  const mockColumns = [
    { key: 'name', title: 'Name' },
    { key: 'email', title: 'Email' },
    { key: 'status', title: 'Status' }
  ]
  
  test('renders data correctly', () => {
    render(<DataTable data={mockData} columns={mockColumns} />)
    
    expect(screen.getByText('John Doe')).toBeInTheDocument()
    expect(screen.getByText('jane@example.com')).toBeInTheDocument()
  })
  
  test('handles sorting', () => {
    render(<DataTable data={mockData} columns={mockColumns} sortable />)
    
    const nameHeader = screen.getByText('Name')
    fireEvent.click(nameHeader)
    
    // Check if data is sorted (implementation depends on your sorting logic)
    const rows = screen.getAllByRole('row')
    expect(rows[1]).toHaveTextContent('Jane Smith')
    expect(rows[2]).toHaveTextContent('John Doe')
  })
  
  test('handles search', () => {
    render(<DataTable data={mockData} columns={mockColumns} searchable />)
    
    const searchInput = screen.getByPlaceholderText('Search...')
    fireEvent.change(searchInput, { target: { value: 'john' } })
    
    expect(screen.getByText('John Doe')).toBeInTheDocument()
    expect(screen.queryByText('Jane Smith')).not.toBeInTheDocument()
  })
})
```

### Integration Testing
```javascript
// tests/integration/UserManagement.test.jsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { rest } from 'msw'
import { setupServer } from 'msw/node'
import { UserManagement } from '../components/UserManagement'

const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json([
      { id: 1, name: 'John Doe', email: 'john@example.com' }
    ]))
  }),
  
  rest.post('/api/users', (req, res, ctx) => {
    return res(ctx.json({ id: 2, ...req.body }))
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('User Management Integration', () => {
  test('creates new user successfully', async () => {
    render(<UserManagement />)
    
    // Wait for initial data to load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
    })
    
    // Click add user button
    fireEvent.click(screen.getByText('Add User'))
    
    // Fill form
    fireEvent.change(screen.getByLabelText('Name'), {
      target: { value: 'Jane Smith' }
    })
    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'jane@example.com' }
    })
    
    // Submit form
    fireEvent.click(screen.getByText('Create User'))
    
    // Verify user was added
    await waitFor(() => {
      expect(screen.getByText('Jane Smith')).toBeInTheDocument()
    })
  })
})
```

## 📚 Best Practices

### 1. **Component Design Principles**
- **Single Responsibility**: Each component should have one clear purpose
- **Composition over Inheritance**: Build complex UIs from simple, reusable components
- **Props Interface**: Design clear, consistent APIs
- **Accessibility**: Follow WCAG guidelines and use semantic HTML

### 2. **Performance Optimization**
```jsx
// Memoization for expensive calculations
const ExpensiveComponent = memo(({ data }) => {
  const processedData = useMemo(() => {
    return data.map(item => expensiveCalculation(item))
  }, [data])
  
  return <div>{processedData}</div>
})

// Lazy loading for large components
const LazyDataTable = lazy(() => import('./DataTable'))

function App() {
  return (
    <Suspense fallback={<div>Loading table...</div>}>
      <LazyDataTable />
    </Suspense>
  )
}

// Virtual scrolling for large lists
import { FixedSizeList as List } from 'react-window'

function VirtualizedList({ items }) {
  const Row = ({ index, style }) => (
    <div style={style}>
      <ItemComponent item={items[index]} />
    </div>
  )
  
  return (
    <List
      height={400}
      itemCount={items.length}
      itemSize={50}
    >
      {Row}
    </List>
  )
}
```

### 3. **Error Handling**
```jsx
// Error boundaries for component isolation
class ComponentErrorBoundary extends React.Component {
  constructor(props) {
    super(props)
    this.state = { hasError: false, error: null }
  }
  
  static getDerivedStateFromError(error) {
    return { hasError: true, error }
  }
  
  componentDidCatch(error, errorInfo) {
    console.error('Component error:', error, errorInfo)
    // Log to error reporting service
  }
  
  render() {
    if (this.state.hasError) {
      return this.props.fallback || <div>Something went wrong</div>
    }
    
    return this.props.children
  }
}

// Usage
<ComponentErrorBoundary fallback={<ErrorComponent />}>
  <ComplexComponent />
</ComponentErrorBoundary>
```

### 4. **Documentation Standards**
```jsx
/**
 * Button component with multiple variants and sizes
 * 
 * @component
 * @example
 * <Button variant="primary" size="lg" onClick={handleClick}>
 *   Click me
 * </Button>
 */
export const Button = ({
  /**
   * Visual style variant
   * @type {'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link'}
   */
  variant = 'default',
  
  /**
   * Button size
   * @type {'default' | 'sm' | 'lg' | 'icon'}
   */
  size = 'default',
  
  /**
   * Shows loading spinner and disables interaction
   */
  loading = false,
  
  /**
   * Button content
   */
  children,
  
  /**
   * Click handler
   */
  onClick,
  
  ...props
}) => {
  // Implementation...
}
```

## 📖 Resources & References

### Documentation
- [React Component Patterns](https://react.dev/learn/thinking-in-react)
- [Vue Component Guide](https://vuejs.org/guide/essentials/component-basics.html)
- [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/)
- [Headless UI](https://headlessui.com/)

### Tools & Libraries
- **Design Systems**: Storybook, Chromatic, Figma
- **Component Libraries**: shadcn/ui, Ant Design, Material-UI
- **Testing**: React Testing Library, Vue Test Utils
- **Documentation**: Storybook, Docusaurus
- **Performance**: React DevTools, Lighthouse

---

*This guide covers modern component architecture patterns for building scalable, maintainable frontend applications. Focus on composition, reusability, and clear interfaces for sustainable development.*
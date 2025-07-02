# shadcn/vue Blocks and Advanced Patterns

## Overview

This comprehensive guide covers advanced shadcn/vue patterns, including blocks usage, complex UI compositions, state management integration, form handling, and production deployment strategies. Learn how to build scalable, maintainable applications with sophisticated user interfaces.

## 🧩 Understanding Blocks vs Components

### What Are Blocks?

Blocks are pre-designed, ready-to-use interface sections that combine multiple components into cohesive UI patterns. Unlike individual components, blocks represent complete functional areas of your application.

```vue
<!-- Component: Individual Button -->
<Button variant="outline" size="lg">
  Click me
</Button>

<!-- Block: Complete Login Form -->
<LoginBlock 
  :loading="isLoading"
  @submit="handleLogin"
  @forgot-password="handleForgotPassword"
/>
```

### Block Categories

**Navigation Blocks:**
- Sidebar layouts with nested navigation
- Header bars with user profiles
- Breadcrumb navigation systems
- Mobile-responsive navigation menus

**Form Blocks:**
- Multi-step wizards
- Complex data entry forms
- Search and filter interfaces
- User authentication flows

**Content Blocks:**
- Dashboard metric displays
- Data table configurations
- Media galleries
- Article/blog layouts

**E-commerce Blocks:**
- Product listing grids
- Shopping cart interfaces
- Checkout processes
- Order management

## 🏗️ Building Complex UI Patterns

### Multi-Step Form Wizard

Create sophisticated form flows with state management:

```vue
<!-- src/components/blocks/MultiStepWizard.vue -->
<template>
  <Card class="w-full max-w-2xl mx-auto">
    <CardHeader>
      <CardTitle>{{ currentStep.title }}</CardTitle>
      <CardDescription>{{ currentStep.description }}</CardDescription>
      
      <!-- Progress Indicator -->
      <div class="flex items-center space-x-2 mt-4">
        <div
          v-for="(step, index) in steps"
          :key="step.id"
          class="flex items-center"
        >
          <div
            :class="[
              'flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium transition-colors',
              index < currentStepIndex
                ? 'bg-primary text-primary-foreground'
                : index === currentStepIndex
                ? 'bg-primary/20 text-primary border-2 border-primary'
                : 'bg-muted text-muted-foreground'
            ]"
          >
            <Check v-if="index < currentStepIndex" class="w-4 h-4" />
            <span v-else>{{ index + 1 }}</span>
          </div>
          
          <div
            v-if="index < steps.length - 1"
            :class="[
              'w-12 h-0.5 mx-2 transition-colors',
              index < currentStepIndex ? 'bg-primary' : 'bg-muted'
            ]"
          />
        </div>
      </div>
    </CardHeader>
    
    <CardContent class="space-y-6">
      <!-- Step Content -->
      <form @submit.prevent="handleSubmit">
        <component
          :is="currentStep.component"
          v-model="formData"
          :errors="errors"
          :loading="isSubmitting"
          @validate="handleStepValidation"
        />
      </form>
    </CardContent>
    
    <CardFooter class="flex justify-between">
      <Button
        v-if="currentStepIndex > 0"
        @click="previousStep"
        variant="outline"
        :disabled="isSubmitting"
      >
        <ChevronLeft class="w-4 h-4 mr-2" />
        Previous
      </Button>
      
      <div class="ml-auto flex space-x-2">
        <Button
          v-if="currentStepIndex < steps.length - 1"
          @click="nextStep"
          :disabled="!isCurrentStepValid || isSubmitting"
        >
          Next
          <ChevronRight class="w-4 h-4 ml-2" />
        </Button>
        
        <Button
          v-else
          @click="handleSubmit"
          :disabled="!isFormValid || isSubmitting"
        >
          <Loader2 v-if="isSubmitting" class="w-4 h-4 mr-2 animate-spin" />
          Complete
        </Button>
      </div>
    </CardFooter>
  </Card>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from 'vue'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Check, ChevronLeft, ChevronRight, Loader2 } from 'lucide-vue-next'

interface WizardStep {
  id: string
  title: string
  description: string
  component: any
  validation?: (data: any) => Record<string, string>
}

interface Props {
  steps: WizardStep[]
  initialData?: Record<string, any>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'submit': [data: Record<string, any>]
  'step-change': [stepIndex: number, stepId: string]
}>()

// State
const currentStepIndex = ref(0)
const formData = reactive(props.initialData || {})
const errors = ref<Record<string, string>>({})
const stepValidation = ref<Record<string, boolean>>({})
const isSubmitting = ref(false)

// Computed
const currentStep = computed(() => props.steps[currentStepIndex.value])
const isCurrentStepValid = computed(() => stepValidation.value[currentStep.value.id] ?? false)
const isFormValid = computed(() => 
  props.steps.every(step => stepValidation.value[step.id] ?? false)
)

// Methods
const validateStep = (stepId: string): boolean => {
  const step = props.steps.find(s => s.id === stepId)
  if (!step?.validation) return true
  
  const stepErrors = step.validation(formData)
  const hasErrors = Object.keys(stepErrors).length > 0
  
  if (hasErrors) {
    errors.value = { ...errors.value, ...stepErrors }
  } else {
    // Clear errors for this step
    for (const key in stepErrors) {
      delete errors.value[key]
    }
  }
  
  return !hasErrors
}

const nextStep = () => {
  if (currentStepIndex.value < props.steps.length - 1) {
    if (validateStep(currentStep.value.id)) {
      currentStepIndex.value++
      emit('step-change', currentStepIndex.value, currentStep.value.id)
    }
  }
}

const previousStep = () => {
  if (currentStepIndex.value > 0) {
    currentStepIndex.value--
    emit('step-change', currentStepIndex.value, currentStep.value.id)
  }
}

const handleStepValidation = (stepId: string, isValid: boolean) => {
  stepValidation.value[stepId] = isValid
}

const handleSubmit = async () => {
  // Validate all steps
  const allValid = props.steps.every(step => validateStep(step.id))
  
  if (!allValid) return
  
  isSubmitting.value = true
  try {
    emit('submit', { ...formData })
  } finally {
    isSubmitting.value = false
  }
}

// Watch for step changes to clear errors
watch(currentStepIndex, () => {
  errors.value = {}
})
</script>
```

### Advanced Data Table with Actions

Create feature-rich data tables with complex interactions:

```vue
<!-- src/components/blocks/AdvancedDataTable.vue -->
<template>
  <div class="space-y-4">
    <!-- Table Header with Controls -->
    <div class="flex flex-col sm:flex-row gap-4">
      <div class="flex-1 flex items-center space-x-2">
        <div class="relative">
          <Search class="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
          <Input
            v-model="searchQuery"
            placeholder="Search..."
            class="pl-10 w-64"
          />
        </div>
        
        <Select v-model="filterStatus" v-if="showStatusFilter">
          <SelectTrigger class="w-40">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="inactive">Inactive</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
          </SelectContent>
        </Select>
        
        <Button @click="handleRefresh" variant="outline" size="sm" :disabled="loading">
          <RefreshCw :class="{ 'animate-spin': loading }" class="w-4 h-4 mr-2" />
          Refresh
        </Button>
      </div>
      
      <div class="flex items-center space-x-2">
        <DropdownMenu v-if="selectedRows.length > 0">
          <DropdownMenuTrigger as-child>
            <Button variant="outline" size="sm">
              Actions ({{ selectedRows.length }})
              <ChevronDown class="w-4 h-4 ml-2" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent>
            <DropdownMenuItem @click="handleBulkAction('export')">
              <Download class="w-4 h-4 mr-2" />
              Export Selected
            </DropdownMenuItem>
            <DropdownMenuItem @click="handleBulkAction('archive')">
              <Archive class="w-4 h-4 mr-2" />
              Archive Selected
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem 
              @click="handleBulkAction('delete')" 
              class="text-destructive focus:text-destructive"
            >
              <Trash class="w-4 h-4 mr-2" />
              Delete Selected
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        
        <Button @click="handleCreate" size="sm">
          <Plus class="w-4 h-4 mr-2" />
          Add New
        </Button>
      </div>
    </div>

    <!-- Table -->
    <div class="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead class="w-12">
              <Checkbox
                :checked="isAllSelected"
                :indeterminate="isPartiallySelected"
                @update:checked="toggleSelectAll"
              />
            </TableHead>
            
            <TableHead
              v-for="column in columns"
              :key="column.key"
              :class="getColumnClasses(column)"
              @click="handleSort(column)"
            >
              <div class="flex items-center space-x-2">
                <span>{{ column.title }}</span>
                <div v-if="column.sortable" class="flex flex-col">
                  <ChevronUp 
                    class="w-3 h-3" 
                    :class="getSortIcon(column, 'asc')"
                  />
                  <ChevronDown 
                    class="w-3 h-3 -mt-1" 
                    :class="getSortIcon(column, 'desc')"
                  />
                </div>
              </div>
            </TableHead>
            
            <TableHead class="w-16">Actions</TableHead>
          </TableRow>
        </TableHeader>
        
        <TableBody>
          <!-- Loading State -->
          <TableRow v-if="loading">
            <TableCell :colspan="columns.length + 2" class="text-center py-8">
              <div class="flex items-center justify-center space-x-2">
                <Loader2 class="w-4 h-4 animate-spin" />
                <span>Loading...</span>
              </div>
            </TableCell>
          </TableRow>
          
          <!-- Empty State -->
          <TableRow v-else-if="filteredData.length === 0">
            <TableCell :colspan="columns.length + 2" class="text-center py-8">
              <div class="flex flex-col items-center space-y-2">
                <SearchX class="w-8 h-8 text-muted-foreground" />
                <p class="text-muted-foreground">No results found</p>
                <Button @click="clearFilters" variant="outline" size="sm">
                  Clear Filters
                </Button>
              </div>
            </TableCell>
          </TableRow>
          
          <!-- Data Rows -->
          <TableRow
            v-else
            v-for="(item, index) in paginatedData"
            :key="getRowKey(item, index)"
            :class="getRowClasses(item)"
          >
            <TableCell>
              <Checkbox
                :checked="selectedRows.includes(item)"
                @update:checked="(checked) => toggleRowSelection(item, checked)"
              />
            </TableCell>
            
            <TableCell
              v-for="column in columns"
              :key="`${getRowKey(item, index)}-${column.key}`"
              :class="getCellClasses(column)"
            >
              <component
                v-if="column.component"
                :is="column.component"
                :value="item[column.key]"
                :row="item"
                :index="index"
              />
              <template v-else>
                {{ formatCellValue(item[column.key], column) }}
              </template>
            </TableCell>
            
            <TableCell>
              <DropdownMenu>
                <DropdownMenuTrigger as-child>
                  <Button variant="ghost" size="sm">
                    <MoreVertical class="w-4 h-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem @click="handleView(item)">
                    <Eye class="w-4 h-4 mr-2" />
                    View
                  </DropdownMenuItem>
                  <DropdownMenuItem @click="handleEdit(item)">
                    <Edit class="w-4 h-4 mr-2" />
                    Edit
                  </DropdownMenuItem>
                  <DropdownMenuItem @click="handleDuplicate(item)">
                    <Copy class="w-4 h-4 mr-2" />
                    Duplicate
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem 
                    @click="handleDelete(item)"
                    class="text-destructive focus:text-destructive"
                  >
                    <Trash class="w-4 h-4 mr-2" />
                    Delete
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </div>

    <!-- Pagination -->
    <div class="flex items-center justify-between">
      <div class="text-sm text-muted-foreground">
        Showing {{ startItem }} to {{ endItem }} of {{ filteredData.length }} results
      </div>
      
      <div class="flex items-center space-x-2">
        <Button
          @click="goToPage(currentPage - 1)"
          :disabled="currentPage === 1"
          variant="outline"
          size="sm"
        >
          <ChevronLeft class="w-4 h-4" />
        </Button>
        
        <div class="flex items-center space-x-1">
          <Button
            v-for="page in visiblePages"
            :key="page"
            @click="goToPage(page)"
            :variant="page === currentPage ? 'default' : 'outline'"
            size="sm"
            class="w-8 h-8 p-0"
          >
            {{ page }}
          </Button>
        </div>
        
        <Button
          @click="goToPage(currentPage + 1)"
          :disabled="currentPage === totalPages"
          variant="outline"
          size="sm"
        >
          <ChevronRight class="w-4 h-4" />
        </Button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Checkbox } from '@/components/ui/checkbox'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Search,
  RefreshCw,
  ChevronDown,
  ChevronUp,
  ChevronLeft,
  ChevronRight,
  Download,
  Archive,
  Trash,
  Plus,
  Loader2,
  SearchX,
  MoreVertical,
  Eye,
  Edit,
  Copy,
} from 'lucide-vue-next'

interface TableColumn {
  key: string
  title: string
  sortable?: boolean
  width?: string
  align?: 'left' | 'center' | 'right'
  component?: any
  format?: (value: any) => string
}

interface Props {
  data: any[]
  columns: TableColumn[]
  loading?: boolean
  pageSize?: number
  showStatusFilter?: boolean
  rowKey?: string | ((row: any, index: number) => string)
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  pageSize: 10,
  showStatusFilter: false,
  rowKey: 'id',
})

const emit = defineEmits<{
  'refresh': []
  'create': []
  'view': [item: any]
  'edit': [item: any]
  'delete': [item: any]
  'duplicate': [item: any]
  'bulk-action': [action: string, items: any[]]
}>()

// State
const searchQuery = ref('')
const filterStatus = ref('all')
const selectedRows = ref<any[]>([])
const currentPage = ref(1)
const sortKey = ref<string>('')
const sortDirection = ref<'asc' | 'desc'>('asc')

// Computed
const filteredData = computed(() => {
  let result = props.data

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(item =>
      props.columns.some(column => {
        const value = item[column.key]
        return String(value).toLowerCase().includes(query)
      })
    )
  }

  // Status filter
  if (filterStatus.value !== 'all') {
    result = result.filter(item => item.status === filterStatus.value)
  }

  // Sorting
  if (sortKey.value) {
    result = [...result].sort((a, b) => {
      const aVal = a[sortKey.value]
      const bVal = b[sortKey.value]
      
      if (aVal < bVal) return sortDirection.value === 'asc' ? -1 : 1
      if (aVal > bVal) return sortDirection.value === 'asc' ? 1 : -1
      return 0
    })
  }

  return result
})

const totalPages = computed(() => Math.ceil(filteredData.value.length / props.pageSize))

const paginatedData = computed(() => {
  const start = (currentPage.value - 1) * props.pageSize
  const end = start + props.pageSize
  return filteredData.value.slice(start, end)
})

const startItem = computed(() => {
  return filteredData.value.length === 0 ? 0 : (currentPage.value - 1) * props.pageSize + 1
})

const endItem = computed(() => {
  return Math.min(currentPage.value * props.pageSize, filteredData.value.length)
})

const visiblePages = computed(() => {
  const pages = []
  const total = totalPages.value
  const current = currentPage.value
  
  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      pages.push(i)
    }
  } else {
    if (current <= 4) {
      for (let i = 1; i <= 5; i++) {
        pages.push(i)
      }
      pages.push('...')
      pages.push(total)
    } else if (current >= total - 3) {
      pages.push(1)
      pages.push('...')
      for (let i = total - 4; i <= total; i++) {
        pages.push(i)
      }
    } else {
      pages.push(1)
      pages.push('...')
      for (let i = current - 1; i <= current + 1; i++) {
        pages.push(i)
      }
      pages.push('...')
      pages.push(total)
    }
  }
  
  return pages.filter(page => page !== '...' || pages.indexOf(page) === pages.lastIndexOf(page))
})

const isAllSelected = computed(() => {
  return paginatedData.value.length > 0 && 
         paginatedData.value.every(item => selectedRows.value.includes(item))
})

const isPartiallySelected = computed(() => {
  return selectedRows.value.length > 0 && !isAllSelected.value
})

// Methods
const getRowKey = (item: any, index: number): string => {
  if (typeof props.rowKey === 'function') {
    return props.rowKey(item, index)
  }
  return item[props.rowKey as string] || index.toString()
}

const getColumnClasses = (column: TableColumn) => {
  const classes = []
  if (column.sortable) classes.push('cursor-pointer', 'hover:bg-muted/50', 'select-none')
  if (column.align) classes.push(`text-${column.align}`)
  return classes.join(' ')
}

const getCellClasses = (column: TableColumn) => {
  const classes = []
  if (column.align) classes.push(`text-${column.align}`)
  return classes.join(' ')
}

const getRowClasses = (item: any) => {
  const classes = ['hover:bg-muted/50']
  if (selectedRows.value.includes(item)) classes.push('bg-muted/25')
  return classes.join(' ')
}

const getSortIcon = (column: TableColumn, direction: 'asc' | 'desc') => {
  const isActive = sortKey.value === column.key && sortDirection.value === direction
  return isActive ? 'text-foreground' : 'text-muted-foreground/50'
}

const formatCellValue = (value: any, column: TableColumn) => {
  if (column.format) return column.format(value)
  if (value === null || value === undefined) return '-'
  return String(value)
}

const handleSort = (column: TableColumn) => {
  if (!column.sortable) return
  
  if (sortKey.value === column.key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = column.key
    sortDirection.value = 'asc'
  }
}

const toggleSelectAll = (checked: boolean) => {
  if (checked) {
    selectedRows.value = [...paginatedData.value]
  } else {
    selectedRows.value = []
  }
}

const toggleRowSelection = (item: any, checked: boolean) => {
  if (checked) {
    if (!selectedRows.value.includes(item)) {
      selectedRows.value.push(item)
    }
  } else {
    const index = selectedRows.value.indexOf(item)
    if (index > -1) {
      selectedRows.value.splice(index, 1)
    }
  }
}

const goToPage = (page: number) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page
  }
}

const clearFilters = () => {
  searchQuery.value = ''
  filterStatus.value = 'all'
  currentPage.value = 1
}

const handleRefresh = () => emit('refresh')
const handleCreate = () => emit('create')
const handleView = (item: any) => emit('view', item)
const handleEdit = (item: any) => emit('edit', item)
const handleDelete = (item: any) => emit('delete', item)
const handleDuplicate = (item: any) => emit('duplicate', item)
const handleBulkAction = (action: string) => {
  emit('bulk-action', action, selectedRows.value)
  selectedRows.value = []
}

// Reset page when filters change
watch([searchQuery, filterStatus], () => {
  currentPage.value = 1
})
</script>
```

## 🎯 State Management Integration

### Pinia Store Integration

Integrate shadcn/vue components with Pinia for state management:

```typescript
// src/stores/useUIStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface Toast {
  id: string
  title: string
  description?: string
  variant: 'default' | 'destructive' | 'success' | 'warning'
  action?: {
    label: string
    onClick: () => void
  }
  duration?: number
}

interface Modal {
  id: string
  component: any
  props?: Record<string, any>
  onClose?: () => void
}

export const useUIStore = defineStore('ui', () => {
  // State
  const theme = ref<'light' | 'dark' | 'system'>('system')
  const sidebarCollapsed = ref(false)
  const toasts = ref<Toast[]>([])
  const modals = ref<Modal[]>([])
  const loading = ref<Record<string, boolean>>({})

  // Getters
  const activeToasts = computed(() => toasts.value)
  const activeModal = computed(() => modals.value[modals.value.length - 1])
  const isLoading = computed(() => (key: string) => loading.value[key] ?? false)

  // Actions
  const setTheme = (newTheme: 'light' | 'dark' | 'system') => {
    theme.value = newTheme
    localStorage.setItem('ui-theme', newTheme)
  }

  const toggleSidebar = () => {
    sidebarCollapsed.value = !sidebarCollapsed.value
    localStorage.setItem('ui-sidebar-collapsed', String(sidebarCollapsed.value))
  }

  const addToast = (toast: Omit<Toast, 'id'>) => {
    const id = Math.random().toString(36).substring(2)
    const newToast = { ...toast, id }
    
    toasts.value.push(newToast)
    
    // Auto-remove after duration
    if (toast.duration !== 0) {
      setTimeout(() => {
        removeToast(id)
      }, toast.duration || 5000)
    }
    
    return id
  }

  const removeToast = (id: string) => {
    const index = toasts.value.findIndex(toast => toast.id === id)
    if (index > -1) {
      toasts.value.splice(index, 1)
    }
  }

  const openModal = (component: any, props?: Record<string, any>, onClose?: () => void) => {
    const id = Math.random().toString(36).substring(2)
    modals.value.push({ id, component, props, onClose })
    return id
  }

  const closeModal = (id?: string) => {
    if (id) {
      const index = modals.value.findIndex(modal => modal.id === id)
      if (index > -1) {
        const modal = modals.value[index]
        modals.value.splice(index, 1)
        modal.onClose?.()
      }
    } else if (modals.value.length > 0) {
      const modal = modals.value.pop()
      modal?.onClose?.()
    }
  }

  const setLoading = (key: string, isLoading: boolean) => {
    if (isLoading) {
      loading.value[key] = true
    } else {
      delete loading.value[key]
    }
  }

  // Initialize from localStorage
  const initialize = () => {
    const savedTheme = localStorage.getItem('ui-theme') as 'light' | 'dark' | 'system'
    if (savedTheme) theme.value = savedTheme

    const savedSidebarState = localStorage.getItem('ui-sidebar-collapsed')
    if (savedSidebarState) sidebarCollapsed.value = savedSidebarState === 'true'
  }

  return {
    // State
    theme: readonly(theme),
    sidebarCollapsed: readonly(sidebarCollapsed),
    toasts: readonly(toasts),
    modals: readonly(modals),
    loading: readonly(loading),

    // Getters
    activeToasts,
    activeModal,
    isLoading,

    // Actions
    setTheme,
    toggleSidebar,
    addToast,
    removeToast,
    openModal,
    closeModal,
    setLoading,
    initialize,
  }
})
```

### Global Toast Provider

Create a toast system using the UI store:

```vue
<!-- src/components/providers/ToastProvider.vue -->
<template>
  <Teleport to="body">
    <div
      class="fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4 sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[420px]"
    >
      <TransitionGroup
        name="toast"
        tag="div"
        class="space-y-2"
      >
        <div
          v-for="toast in uiStore.activeToasts"
          :key="toast.id"
          :class="[
            'group pointer-events-auto relative flex w-full items-center justify-between space-x-2 overflow-hidden rounded-md border p-4 pr-6 shadow-lg transition-all',
            getToastClasses(toast.variant)
          ]"
        >
          <div class="grid gap-1">
            <div v-if="toast.title" class="text-sm font-semibold">
              {{ toast.title }}
            </div>
            <div v-if="toast.description" class="text-sm opacity-90">
              {{ toast.description }}
            </div>
          </div>
          
          <div v-if="toast.action" class="flex items-center space-x-2">
            <Button
              @click="toast.action!.onClick"
              variant="outline"
              size="sm"
              class="h-8"
            >
              {{ toast.action.label }}
            </Button>
          </div>
          
          <Button
            @click="uiStore.removeToast(toast.id)"
            variant="ghost"
            size="icon"
            class="absolute right-1 top-1 h-6 w-6 rounded-md opacity-0 group-hover:opacity-100"
          >
            <X class="h-3 w-3" />
          </Button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { useUIStore } from '@/stores/useUIStore'
import { X } from 'lucide-vue-next'

const uiStore = useUIStore()

const getToastClasses = (variant: string) => {
  switch (variant) {
    case 'destructive':
      return 'border-destructive/50 text-destructive dark:border-destructive [&>svg]:text-destructive'
    case 'success':
      return 'border-green-500/50 text-green-600 dark:border-green-500 [&>svg]:text-green-600'
    case 'warning':
      return 'border-yellow-500/50 text-yellow-600 dark:border-yellow-500 [&>svg]:text-yellow-600'
    default:
      return 'border bg-background text-foreground'
  }
}
</script>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%);
}
</style>
```

### Composable for Toast Management

Create a composable for easy toast usage:

```typescript
// src/composables/useToast.ts
import { useUIStore } from '@/stores/useUIStore'

export function useToast() {
  const uiStore = useUIStore()

  const toast = (options: {
    title: string
    description?: string
    variant?: 'default' | 'destructive' | 'success' | 'warning'
    duration?: number
    action?: {
      label: string
      onClick: () => void
    }
  }) => {
    return uiStore.addToast(options)
  }

  const success = (title: string, description?: string) => {
    return toast({ title, description, variant: 'success' })
  }

  const error = (title: string, description?: string) => {
    return toast({ title, description, variant: 'destructive' })
  }

  const warning = (title: string, description?: string) => {
    return toast({ title, description, variant: 'warning' })
  }

  const promise = async <T>(
    promise: Promise<T>,
    options: {
      loading: string
      success: string | ((data: T) => string)
      error: string | ((error: any) => string)
    }
  ) => {
    const loadingToastId = toast({
      title: options.loading,
      duration: 0,
    })

    try {
      const result = await promise
      uiStore.removeToast(loadingToastId)
      
      const successMessage = typeof options.success === 'function' 
        ? options.success(result) 
        : options.success
      
      success(successMessage)
      return result
    } catch (err) {
      uiStore.removeToast(loadingToastId)
      
      const errorMessage = typeof options.error === 'function' 
        ? options.error(err) 
        : options.error
      
      error(errorMessage)
      throw err
    }
  }

  const dismiss = (toastId: string) => {
    uiStore.removeToast(toastId)
  }

  return {
    toast,
    success,
    error,
    warning,
    promise,
    dismiss,
  }
}
```

## 🚀 Production Deployment Strategies

### Build Optimization

Configure optimal build settings for production:

```typescript
// vite.config.ts - Production optimizations
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig(({ mode }) => ({
  plugins: [vue()],
  
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  
  build: {
    // Generate sourcemaps for debugging
    sourcemap: mode === 'development',
    
    // Optimize bundle splitting
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-vue': ['vue', 'vue-router'],
          'vendor-ui': ['@radix-vue/vue', 'class-variance-authority'],
          'vendor-utils': ['clsx', 'tailwind-merge'],
          'vendor-icons': ['lucide-vue-next'],
        },
      },
    },
    
    // Minification settings
    minify: 'esbuild',
    target: 'esnext',
    
    // Chunk size warnings
    chunkSizeWarningLimit: 1000,
  },
  
  // Production optimizations
  ...(mode === 'production' && {
    esbuild: {
      drop: ['console', 'debugger'],
    },
  }),
}))
```

### Performance Monitoring

Implement performance monitoring for production:

```typescript
// src/utils/performance.ts
export class PerformanceMonitor {
  private static instance: PerformanceMonitor
  private metrics: Map<string, number> = new Map()

  static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor()
    }
    return PerformanceMonitor.instance
  }

  startMeasure(name: string): void {
    this.metrics.set(name, performance.now())
  }

  endMeasure(name: string): number {
    const start = this.metrics.get(name)
    if (!start) {
      console.warn(`No start time found for measure: ${name}`)
      return 0
    }

    const duration = performance.now() - start
    this.metrics.delete(name)

    // Log slow operations
    if (duration > 100) {
      console.warn(`Slow operation detected: ${name} took ${duration.toFixed(2)}ms`)
    }

    return duration
  }

  measureAsync<T>(name: string, fn: () => Promise<T>): Promise<T> {
    this.startMeasure(name)
    return fn().finally(() => {
      this.endMeasure(name)
    })
  }

  measureSync<T>(name: string, fn: () => T): T {
    this.startMeasure(name)
    try {
      return fn()
    } finally {
      this.endMeasure(name)
    }
  }
}

export const perf = PerformanceMonitor.getInstance()
```

### Error Boundary Implementation

Create error boundaries for production error handling:

```vue
<!-- src/components/ErrorBoundary.vue -->
<template>
  <div v-if="hasError" class="min-h-[400px] flex items-center justify-center p-8">
    <Card class="w-full max-w-md">
      <CardHeader class="text-center">
        <div class="mx-auto w-12 h-12 rounded-full bg-destructive/10 flex items-center justify-center mb-4">
          <AlertTriangle class="w-6 h-6 text-destructive" />
        </div>
        <CardTitle class="text-destructive">Something went wrong</CardTitle>
        <CardDescription>
          An unexpected error occurred while rendering this component.
        </CardDescription>
      </CardHeader>
      
      <CardContent class="text-center space-y-4">
        <div v-if="isDevelopment && error" class="text-left">
          <details class="text-sm">
            <summary class="cursor-pointer font-medium">Error Details</summary>
            <pre class="mt-2 p-2 bg-muted rounded text-xs overflow-auto">{{ error.stack }}</pre>
          </details>
        </div>
        
        <div class="flex space-x-2 justify-center">
          <Button @click="retry" variant="outline" size="sm">
            <RefreshCw class="w-4 h-4 mr-2" />
            Retry
          </Button>
          <Button @click="reportError" variant="default" size="sm">
            <Send class="w-4 h-4 mr-2" />
            Report Issue
          </Button>
        </div>
      </CardContent>
    </Card>
  </div>
  
  <slot v-else />
</template>

<script setup lang="ts">
import { ref, onErrorCaptured, nextTick } from 'vue'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { AlertTriangle, RefreshCw, Send } from 'lucide-vue-next'

const hasError = ref(false)
const error = ref<Error | null>(null)
const isDevelopment = import.meta.env.DEV

const emit = defineEmits<{
  'error': [error: Error]
}>()

onErrorCaptured((err: Error) => {
  hasError.value = true
  error.value = err
  
  // Log error for monitoring
  console.error('Component Error:', err)
  
  // Emit error for parent handling
  emit('error', err)
  
  // Report to error tracking service
  if (!isDevelopment) {
    reportErrorToService(err)
  }
  
  return false // Stop error propagation
})

const retry = async () => {
  hasError.value = false
  error.value = null
  await nextTick()
}

const reportError = () => {
  if (error.value) {
    // Implement error reporting logic
    const errorData = {
      message: error.value.message,
      stack: error.value.stack,
      url: window.location.href,
      userAgent: navigator.userAgent,
      timestamp: new Date().toISOString(),
    }
    
    // Send to error tracking service
    console.log('Reporting error:', errorData)
  }
}

const reportErrorToService = (err: Error) => {
  // Implement your error tracking service integration
  // e.g., Sentry, Bugsnag, etc.
  fetch('/api/errors', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: err.message,
      stack: err.stack,
      url: window.location.href,
      timestamp: new Date().toISOString(),
    }),
  }).catch(console.error)
}
</script>
```

### SEO and Accessibility

Ensure proper SEO and accessibility implementation:

```vue
<!-- src/components/SEOHead.vue -->
<template>
  <Head>
    <title>{{ fullTitle }}</title>
    <meta name="description" :content="description" />
    
    <!-- Open Graph -->
    <meta property="og:title" :content="fullTitle" />
    <meta property="og:description" :content="description" />
    <meta property="og:type" :content="type" />
    <meta property="og:url" :content="url" />
    <meta property="og:image" :content="image" />
    
    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" :content="fullTitle" />
    <meta name="twitter:description" :content="description" />
    <meta name="twitter:image" :content="image" />
    
    <!-- Additional meta tags -->
    <meta name="keywords" :content="keywords" />
    <meta name="author" :content="author" />
    <link rel="canonical" :href="canonical" />
    
    <!-- Schema.org structured data -->
    <script type="application/ld+json" v-if="structuredData">
      {{ JSON.stringify(structuredData) }}
    </script>
  </Head>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Head } from '@vueuse/head'

interface Props {
  title: string
  description: string
  type?: string
  image?: string
  keywords?: string
  author?: string
  structuredData?: object
}

const props = withDefaults(defineProps<Props>(), {
  type: 'website',
  image: '/og-image.jpg',
  keywords: '',
  author: 'Your Site Name',
})

const fullTitle = computed(() => {
  return props.title.includes('|') ? props.title : `${props.title} | Your Site Name`
})

const url = computed(() => window.location.href)
const canonical = computed(() => window.location.origin + window.location.pathname)
</script>
```

This completes the comprehensive shadcn/vue documentation covering all aspects from fundamentals to advanced production patterns. The documentation provides developers with everything needed to build sophisticated, maintainable applications using shadcn/vue components.

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"id": "shadcn-vue-1", "content": "Create shadcn-vue-docs folder and main README.md with overview and navigation", "status": "completed", "priority": "high"}, {"id": "shadcn-vue-2", "content": "Write shadcn-vue-fundamentals-setup.md covering core concepts, installation, and CLI", "status": "completed", "priority": "high"}, {"id": "shadcn-vue-3", "content": "Create shadcn-vue-components-reference.md with complete component catalog and examples", "status": "completed", "priority": "high"}, {"id": "shadcn-vue-4", "content": "Write shadcn-vue-styling-theming.md covering Tailwind integration and customization", "status": "completed", "priority": "high"}, {"id": "shadcn-vue-5", "content": "Create shadcn-vue-framework-integration.md for Vue 3, Nuxt, Vite patterns", "status": "completed", "priority": "medium"}, {"id": "shadcn-vue-6", "content": "Write shadcn-vue-blocks-advanced-patterns.md covering blocks and complex patterns", "status": "completed", "priority": "medium"}]
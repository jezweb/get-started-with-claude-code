# shadcn/vue Component Reference and Usage

## Overview

This comprehensive reference covers all 40+ shadcn/vue components with detailed examples, usage patterns, and best practices. Each component is built using Radix Vue primitives and styled with Tailwind CSS, providing accessible and customizable UI elements.

## 📋 Component Categories

### Basic UI Components
- [Accordion](#accordion) - Collapsible content sections
- [Alert](#alert) - Important messages and notifications
- [Avatar](#avatar) - User profile images and initials
- [Badge](#badge) - Labels and status indicators
- [Button](#button) - Interactive elements and actions
- [Card](#card) - Content containers
- [Checkbox](#checkbox) - Boolean input controls
- [Collapsible](#collapsible) - Show/hide content
- [Input](#input) - Text input fields
- [Label](#label) - Form field labels
- [Progress](#progress) - Task completion indicators
- [Separator](#separator) - Visual content dividers
- [Skeleton](#skeleton) - Loading placeholders
- [Switch](#switch) - Toggle controls

### Interactive Components
- [Combobox](#combobox) - Searchable select inputs
- [Command](#command) - Command palette interface
- [Context Menu](#context-menu) - Right-click menus
- [Dialog](#dialog) - Modal windows
- [Dropdown Menu](#dropdown-menu) - Action menus
- [Hover Card](#hover-card) - Hover-triggered content
- [Popover](#popover) - Floating content containers
- [Sheet](#sheet) - Slide-out panels
- [Tooltip](#tooltip) - Contextual help text

### Form & Data Components
- [Calendar](#calendar) - Date selection
- [Date Picker](#date-picker) - Date input with calendar
- [Form](#form) - Form validation and structure
- [Number Field](#number-field) - Numeric input controls
- [Radio Group](#radio-group) - Single-choice selection
- [Select](#select) - Dropdown selection
- [Slider](#slider) - Range input controls
- [Stepper](#stepper) - Multi-step processes
- [Tags Input](#tags-input) - Multiple tag selection
- [Textarea](#textarea) - Multi-line text input

### Navigation & Layout Components
- [Breadcrumb](#breadcrumb) - Navigation hierarchy
- [Menubar](#menubar) - Application menu
- [Navigation Menu](#navigation-menu) - Site navigation
- [Pagination](#pagination) - Page navigation
- [Resizable](#resizable) - Adjustable layout panels
- [Scroll Area](#scroll-area) - Custom scrollbars
- [Sidebar](#sidebar) - Application sidebar
- [Tabs](#tabs) - Tabbed content

### Advanced Components
- [Alert Dialog](#alert-dialog) - Confirmation dialogs
- [Aspect Ratio](#aspect-ratio) - Responsive containers
- [Carousel](#carousel) - Image/content sliders
- [Data Table](#data-table) - Complex data display
- [Drawer](#drawer) - Mobile-friendly dialogs
- [Range Calendar](#range-calendar) - Date range selection
- [Sonner](#sonner) - Toast notifications

---

## Basic UI Components

### Accordion

Collapsible content sections for organizing information hierarchically.

```vue
<template>
  <Accordion type="single" collapsible class="w-full">
    <AccordionItem value="item-1">
      <AccordionTrigger>Is it accessible?</AccordionTrigger>
      <AccordionContent>
        Yes. It adheres to the WAI-ARIA design pattern and uses proper ARIA attributes.
      </AccordionContent>
    </AccordionItem>
    
    <AccordionItem value="item-2">
      <AccordionTrigger>Is it styled?</AccordionTrigger>
      <AccordionContent>
        Yes. It comes with default styles that can be customized with Tailwind CSS.
      </AccordionContent>
    </AccordionItem>
    
    <AccordionItem value="item-3">
      <AccordionTrigger>Is it animated?</AccordionTrigger>
      <AccordionContent>
        Yes. It includes smooth animations using CSS transitions and Tailwind CSS.
      </AccordionContent>
    </AccordionItem>
  </Accordion>
</template>

<script setup lang="ts">
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion'
</script>
```

**Props:**
- `type: "single" | "multiple"` - Allow single or multiple items open
- `collapsible: boolean` - Allow all items to be closed
- `defaultValue: string | string[]` - Initially open items

### Alert

Display important messages and notifications to users.

```vue
<template>
  <div class="space-y-4">
    <!-- Default Alert -->
    <Alert>
      <Terminal class="h-4 w-4" />
      <AlertTitle>Heads up!</AlertTitle>
      <AlertDescription>
        You can add components to your app using the cli.
      </AlertDescription>
    </Alert>

    <!-- Destructive Alert -->
    <Alert variant="destructive">
      <AlertCircle class="h-4 w-4" />
      <AlertTitle>Error</AlertTitle>
      <AlertDescription>
        Your session has expired. Please log in again.
      </AlertDescription>
    </Alert>

    <!-- Custom Alert with Actions -->
    <Alert>
      <Info class="h-4 w-4" />
      <AlertTitle>Update Available</AlertTitle>
      <AlertDescription class="flex items-center justify-between">
        <span>A new version of the app is available.</span>
        <div class="ml-4 space-x-2">
          <Button variant="outline" size="sm">Later</Button>
          <Button size="sm">Update Now</Button>
        </div>
      </AlertDescription>
    </Alert>
  </div>
</template>

<script setup lang="ts">
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { Terminal, AlertCircle, Info } from 'lucide-vue-next'
</script>
```

**Variants:**
- `default` - Standard alert styling
- `destructive` - Error/warning styling

### Avatar

Display user profile images with fallback to initials.

```vue
<template>
  <div class="flex items-center space-x-4">
    <!-- Basic Avatar -->
    <Avatar>
      <AvatarImage src="https://github.com/shadcn.png" alt="@shadcn" />
      <AvatarFallback>CN</AvatarFallback>
    </Avatar>

    <!-- Large Avatar -->
    <Avatar class="h-16 w-16">
      <AvatarImage src="https://github.com/vercel.png" alt="@vercel" />
      <AvatarFallback>VC</AvatarFallback>
    </Avatar>

    <!-- Avatar Group -->
    <div class="flex -space-x-2">
      <Avatar class="border-2 border-background">
        <AvatarImage src="https://github.com/shadcn.png" />
        <AvatarFallback>CN</AvatarFallback>
      </Avatar>
      <Avatar class="border-2 border-background">
        <AvatarImage src="https://github.com/vercel.png" />
        <AvatarFallback>VC</AvatarFallback>
      </Avatar>
      <Avatar class="border-2 border-background">
        <AvatarFallback>+2</AvatarFallback>
      </Avatar>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
</script>
```

### Badge

Small labels for status, categories, or metadata.

```vue
<template>
  <div class="flex flex-wrap gap-2">
    <!-- Basic Badges -->
    <Badge>Default</Badge>
    <Badge variant="secondary">Secondary</Badge>
    <Badge variant="destructive">Destructive</Badge>
    <Badge variant="outline">Outline</Badge>

    <!-- Status Badges -->
    <Badge class="bg-green-500 hover:bg-green-600">
      <Check class="w-3 h-3 mr-1" />
      Completed
    </Badge>
    
    <Badge variant="outline" class="text-yellow-600 border-yellow-600">
      <Clock class="w-3 h-3 mr-1" />
      Pending
    </Badge>

    <!-- Interactive Badges -->
    <Badge 
      variant="secondary" 
      class="cursor-pointer hover:bg-secondary/80"
      @click="handleTagClick('vue')"
    >
      Vue.js
      <X class="w-3 h-3 ml-1" />
    </Badge>
  </div>
</template>

<script setup lang="ts">
import { Badge } from '@/components/ui/badge'
import { Check, Clock, X } from 'lucide-vue-next'

const handleTagClick = (tag: string) => {
  console.log('Tag clicked:', tag)
}
</script>
```

### Button

Interactive elements for user actions.

```vue
<template>
  <div class="space-y-4">
    <!-- Basic Variants -->
    <div class="flex space-x-2">
      <Button>Default</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="destructive">Destructive</Button>
      <Button variant="outline">Outline</Button>
      <Button variant="ghost">Ghost</Button>
      <Button variant="link">Link</Button>
    </div>

    <!-- Sizes -->
    <div class="flex items-center space-x-2">
      <Button size="sm">Small</Button>
      <Button size="default">Default</Button>
      <Button size="lg">Large</Button>
      <Button size="icon">
        <Heart class="h-4 w-4" />
      </Button>
    </div>

    <!-- Loading States -->
    <div class="flex space-x-2">
      <Button disabled>
        <Loader2 class="mr-2 h-4 w-4 animate-spin" />
        Loading
      </Button>
      
      <Button @click="handleAsyncAction" :disabled="isLoading">
        <Loader2 v-if="isLoading" class="mr-2 h-4 w-4 animate-spin" />
        {{ isLoading ? 'Processing...' : 'Submit' }}
      </Button>
    </div>

    <!-- With Icons -->
    <div class="flex space-x-2">
      <Button>
        <Mail class="mr-2 h-4 w-4" />
        Email
      </Button>
      
      <Button variant="outline">
        Download
        <Download class="ml-2 h-4 w-4" />
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Button } from '@/components/ui/button'
import { Heart, Loader2, Mail, Download } from 'lucide-vue-next'

const isLoading = ref(false)

const handleAsyncAction = async () => {
  isLoading.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 2000))
    // Handle success
  } finally {
    isLoading.value = false
  }
}
</script>
```

### Card

Flexible container for grouping related content.

```vue
<template>
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <!-- Basic Card -->
    <Card>
      <CardHeader>
        <CardTitle>Card Title</CardTitle>
        <CardDescription>
          Card Description
        </CardDescription>
      </CardHeader>
      <CardContent>
        <p>Card Content</p>
      </CardContent>
      <CardFooter class="flex justify-between">
        <Button variant="outline">Cancel</Button>
        <Button>Deploy</Button>
      </CardFooter>
    </Card>

    <!-- Product Card -->
    <Card class="overflow-hidden">
      <div class="aspect-video bg-muted relative">
        <img 
          src="https://images.unsplash.com/photo-1555041469-a586c61ea9bc"
          alt="Product"
          class="object-cover w-full h-full"
        />
        <Badge class="absolute top-2 right-2">Sale</Badge>
      </div>
      <CardHeader>
        <CardTitle>Wireless Headphones</CardTitle>
        <CardDescription>
          High-quality wireless headphones with noise cancellation.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div class="flex items-center justify-between">
          <span class="text-2xl font-bold">$199.99</span>
          <div class="flex items-center space-x-1">
            <Star class="w-4 h-4 fill-yellow-400 text-yellow-400" />
            <span class="text-sm text-muted-foreground">4.5 (120)</span>
          </div>
        </div>
      </CardContent>
      <CardFooter>
        <Button class="w-full">Add to Cart</Button>
      </CardFooter>
    </Card>

    <!-- Stats Card -->
    <Card>
      <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle class="text-sm font-medium">
          Total Revenue
        </CardTitle>
        <DollarSign class="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div class="text-2xl font-bold">$45,231.89</div>
        <p class="text-xs text-muted-foreground">
          +20.1% from last month
        </p>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Star, DollarSign } from 'lucide-vue-next'
</script>
```

### Input

Text input fields with various types and validation states.

```vue
<template>
  <div class="space-y-6">
    <!-- Basic Inputs -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <Label for="email">Email</Label>
        <Input 
          id="email" 
          type="email" 
          placeholder="m@example.com"
          v-model="form.email"
        />
      </div>
      
      <div>
        <Label for="password">Password</Label>
        <div class="relative">
          <Input 
            id="password" 
            :type="showPassword ? 'text' : 'password'"
            placeholder="••••••••"
            v-model="form.password"
          />
          <Button
            type="button"
            variant="ghost"
            size="icon"
            class="absolute right-0 top-0 h-full px-3"
            @click="showPassword = !showPassword"
          >
            <Eye v-if="!showPassword" class="h-4 w-4" />
            <EyeOff v-else class="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>

    <!-- Input with Icons -->
    <div class="space-y-2">
      <Label for="search">Search</Label>
      <div class="relative">
        <Search class="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
        <Input 
          id="search"
          placeholder="Search products..."
          class="pl-10"
          v-model="searchQuery"
        />
      </div>
    </div>

    <!-- Validation States -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <Label for="valid-input">Valid Input</Label>
        <Input 
          id="valid-input"
          value="valid@example.com"
          class="border-green-500 focus:border-green-500"
        />
        <p class="text-sm text-green-600 mt-1">✓ Email is valid</p>
      </div>
      
      <div>
        <Label for="invalid-input">Invalid Input</Label>
        <Input 
          id="invalid-input"
          value="invalid-email"
          class="border-red-500 focus:border-red-500"
        />
        <p class="text-sm text-red-600 mt-1">✗ Please enter a valid email</p>
      </div>
    </div>

    <!-- Disabled State -->
    <div>
      <Label for="disabled-input">Disabled Input</Label>
      <Input 
        id="disabled-input"
        placeholder="This input is disabled"
        disabled
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Eye, EyeOff, Search } from 'lucide-vue-next'

const showPassword = ref(false)
const searchQuery = ref('')

const form = reactive({
  email: '',
  password: ''
})
</script>
```

---

## Interactive Components

### Dialog

Modal windows for focused interactions.

```vue
<template>
  <div class="space-x-2">
    <Button @click="isOpen = true">Open Dialog</Button>
    
    <Dialog v-model:open="isOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Share this link</DialogTitle>
          <DialogDescription>
            Anyone who has this link will be able to view this.
          </DialogDescription>
        </DialogHeader>
        
        <div class="flex items-center space-x-2">
          <div class="grid flex-1 gap-2">
            <Label for="link" class="sr-only">Link</Label>
            <Input
              id="link"
              :value="shareLink"
              readonly
            />
          </div>
          <Button @click="copyToClipboard" size="sm" class="px-3">
            <span class="sr-only">Copy</span>
            <Copy class="h-4 w-4" />
          </Button>
        </div>
        
        <DialogFooter class="sm:justify-start">
          <DialogClose as-child>
            <Button type="button" variant="secondary">
              Close
            </Button>
          </DialogClose>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Confirmation Dialog -->
    <AlertDialog v-model:open="showConfirm">
      <AlertDialogTrigger as-child>
        <Button variant="destructive">Delete Account</Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
          <AlertDialogDescription>
            This action cannot be undone. This will permanently delete your
            account and remove your data from our servers.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction @click="deleteAccount">Continue</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Copy } from 'lucide-vue-next'

const isOpen = ref(false)
const showConfirm = ref(false)
const shareLink = ref('https://ui.shadcn.com/docs/installation')

const copyToClipboard = () => {
  navigator.clipboard.writeText(shareLink.value)
}

const deleteAccount = () => {
  console.log('Account deleted')
  showConfirm.value = false
}
</script>
```

### Dropdown Menu

Contextual action menus triggered by buttons or other elements.

```vue
<template>
  <div class="flex space-x-4">
    <!-- Basic Dropdown -->
    <DropdownMenu>
      <DropdownMenuTrigger as-child>
        <Button variant="outline">
          Open Menu
          <ChevronDown class="ml-2 h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent class="w-56">
        <DropdownMenuLabel>My Account</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuGroup>
          <DropdownMenuItem>
            <User class="mr-2 h-4 w-4" />
            <span>Profile</span>
            <DropdownMenuShortcut>⇧⌘P</DropdownMenuShortcut>
          </DropdownMenuItem>
          <DropdownMenuItem>
            <CreditCard class="mr-2 h-4 w-4" />
            <span>Billing</span>
            <DropdownMenuShortcut>⌘B</DropdownMenuShortcut>
          </DropdownMenuItem>
          <DropdownMenuItem>
            <Settings class="mr-2 h-4 w-4" />
            <span>Settings</span>
            <DropdownMenuShortcut>⌘S</DropdownMenuShortcut>
          </DropdownMenuItem>
        </DropdownMenuGroup>
        <DropdownMenuSeparator />
        <DropdownMenuItem>
          <LogOut class="mr-2 h-4 w-4" />
          <span>Log out</span>
          <DropdownMenuShortcut>⇧⌘Q</DropdownMenuShortcut>
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>

    <!-- Context Menu (Right-click) -->
    <ContextMenu>
      <ContextMenuTrigger>
        <div class="flex h-32 w-32 items-center justify-center rounded-md border border-dashed text-sm">
          Right click me
        </div>
      </ContextMenuTrigger>
      <ContextMenuContent>
        <ContextMenuItem>
          <Copy class="mr-2 h-4 w-4" />
          Copy
        </ContextMenuItem>
        <ContextMenuItem>
          <Edit class="mr-2 h-4 w-4" />
          Edit
        </ContextMenuItem>
        <ContextMenuSeparator />
        <ContextMenuItem class="text-red-600">
          <Trash class="mr-2 h-4 w-4" />
          Delete
        </ContextMenuItem>
      </ContextMenuContent>
    </ContextMenu>
  </div>
</template>

<script setup lang="ts">
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuShortcut,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuSeparator,
  ContextMenuTrigger,
} from '@/components/ui/context-menu'
import { Button } from '@/components/ui/button'
import {
  ChevronDown,
  User,
  CreditCard,
  Settings,
  LogOut,
  Copy,
  Edit,
  Trash,
} from 'lucide-vue-next'
</script>
```

---

## Form & Data Components

### Select

Dropdown selection with search and grouping capabilities.

```vue
<template>
  <div class="space-y-6">
    <!-- Basic Select -->
    <div>
      <Label for="framework">Framework</Label>
      <Select v-model="selectedFramework">
        <SelectTrigger>
          <SelectValue placeholder="Select a framework" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="vue">Vue.js</SelectItem>
          <SelectItem value="react">React</SelectItem>
          <SelectItem value="angular">Angular</SelectItem>
          <SelectItem value="svelte">Svelte</SelectItem>
        </SelectContent>
      </Select>
    </div>

    <!-- Grouped Select -->
    <div>
      <Label for="timezone">Timezone</Label>
      <Select v-model="selectedTimezone">
        <SelectTrigger>
          <SelectValue placeholder="Select timezone" />
        </SelectTrigger>
        <SelectContent>
          <SelectGroup>
            <SelectLabel>North America</SelectLabel>
            <SelectItem value="est">Eastern Standard Time (EST)</SelectItem>
            <SelectItem value="cst">Central Standard Time (CST)</SelectItem>
            <SelectItem value="mst">Mountain Standard Time (MST)</SelectItem>
            <SelectItem value="pst">Pacific Standard Time (PST)</SelectItem>
          </SelectGroup>
          <SelectGroup>
            <SelectLabel>Europe</SelectLabel>
            <SelectItem value="gmt">Greenwich Mean Time (GMT)</SelectItem>
            <SelectItem value="cet">Central European Time (CET)</SelectItem>
          </SelectGroup>
        </SelectContent>
      </Select>
    </div>

    <!-- Combobox (Searchable Select) -->
    <div>
      <Label for="language">Programming Language</Label>
      <Combobox 
        v-model="selectedLanguage"
        :options="languages"
        placeholder="Search languages..."
        empty-text="No language found."
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  SelectGroup,
  SelectLabel,
} from '@/components/ui/select'
import { Combobox } from '@/components/ui/combobox'
import { Label } from '@/components/ui/label'

const selectedFramework = ref('')
const selectedTimezone = ref('')
const selectedLanguage = ref('')

const languages = [
  { value: 'javascript', label: 'JavaScript' },
  { value: 'typescript', label: 'TypeScript' },
  { value: 'python', label: 'Python' },
  { value: 'java', label: 'Java' },
  { value: 'go', label: 'Go' },
  { value: 'rust', label: 'Rust' },
]
</script>
```

### Form

Complete form handling with validation and error display.

```vue
<template>
  <Card class="max-w-md mx-auto">
    <CardHeader>
      <CardTitle>Create Account</CardTitle>
      <CardDescription>
        Enter your information to create an account.
      </CardDescription>
    </CardHeader>
    
    <CardContent>
      <form @submit="onSubmit" class="space-y-4">
        <div>
          <Label for="name">Full Name</Label>
          <Input
            id="name"
            v-model="form.name"
            :class="errors.name ? 'border-red-500' : ''"
            placeholder="John Doe"
          />
          <p v-if="errors.name" class="text-sm text-red-500 mt-1">
            {{ errors.name }}
          </p>
        </div>

        <div>
          <Label for="email">Email</Label>
          <Input
            id="email"
            type="email"
            v-model="form.email"
            :class="errors.email ? 'border-red-500' : ''"
            placeholder="john@example.com"
          />
          <p v-if="errors.email" class="text-sm text-red-500 mt-1">
            {{ errors.email }}
          </p>
        </div>

        <div>
          <Label for="password">Password</Label>
          <Input
            id="password"
            type="password"
            v-model="form.password"
            :class="errors.password ? 'border-red-500' : ''"
            placeholder="••••••••"
          />
          <p v-if="errors.password" class="text-sm text-red-500 mt-1">
            {{ errors.password }}
          </p>
        </div>

        <div>
          <Label for="role">Role</Label>
          <Select v-model="form.role">
            <SelectTrigger :class="errors.role ? 'border-red-500' : ''">
              <SelectValue placeholder="Select a role" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="user">User</SelectItem>
              <SelectItem value="admin">Admin</SelectItem>
              <SelectItem value="moderator">Moderator</SelectItem>
            </SelectContent>
          </Select>
          <p v-if="errors.role" class="text-sm text-red-500 mt-1">
            {{ errors.role }}
          </p>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox 
            id="terms" 
            v-model:checked="form.acceptTerms"
            :class="errors.acceptTerms ? 'border-red-500' : ''"
          />
          <Label for="terms" class="text-sm">
            I accept the terms and conditions
          </Label>
        </div>
        <p v-if="errors.acceptTerms" class="text-sm text-red-500">
          {{ errors.acceptTerms }}
        </p>

        <Button type="submit" class="w-full" :disabled="isSubmitting">
          <Loader2 v-if="isSubmitting" class="mr-2 h-4 w-4 animate-spin" />
          {{ isSubmitting ? 'Creating Account...' : 'Create Account' }}
        </Button>
      </form>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Checkbox } from '@/components/ui/checkbox'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Loader2 } from 'lucide-vue-next'

const isSubmitting = ref(false)

const form = reactive({
  name: '',
  email: '',
  password: '',
  role: '',
  acceptTerms: false,
})

const errors = ref<Record<string, string>>({})

const validateForm = () => {
  const newErrors: Record<string, string> = {}

  if (!form.name.trim()) {
    newErrors.name = 'Name is required'
  }

  if (!form.email.trim()) {
    newErrors.email = 'Email is required'
  } else if (!/\S+@\S+\.\S+/.test(form.email)) {
    newErrors.email = 'Email is invalid'
  }

  if (!form.password) {
    newErrors.password = 'Password is required'
  } else if (form.password.length < 8) {
    newErrors.password = 'Password must be at least 8 characters'
  }

  if (!form.role) {
    newErrors.role = 'Role is required'
  }

  if (!form.acceptTerms) {
    newErrors.acceptTerms = 'You must accept the terms and conditions'
  }

  errors.value = newErrors
  return Object.keys(newErrors).length === 0
}

const onSubmit = async (e: Event) => {
  e.preventDefault()
  
  if (!validateForm()) return

  isSubmitting.value = true
  try {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 2000))
    console.log('Form submitted:', form)
    // Handle success
  } catch (error) {
    console.error('Submission error:', error)
  } finally {
    isSubmitting.value = false
  }
}
</script>
```

---

## Navigation & Layout Components

### Tabs

Organize content into multiple sections with tab navigation.

```vue
<template>
  <Tabs default-value="account" class="w-full max-w-md">
    <TabsList class="grid w-full grid-cols-2">
      <TabsTrigger value="account">Account</TabsTrigger>
      <TabsTrigger value="password">Password</TabsTrigger>
    </TabsList>
    
    <TabsContent value="account" class="space-y-4">
      <div>
        <Label for="name">Name</Label>
        <Input id="name" placeholder="Your name" />
      </div>
      <div>
        <Label for="username">Username</Label>
        <Input id="username" placeholder="@username" />
      </div>
      <Button>Save changes</Button>
    </TabsContent>
    
    <TabsContent value="password" class="space-y-4">
      <div>
        <Label for="current">Current password</Label>
        <Input id="current" type="password" />
      </div>
      <div>
        <Label for="new">New password</Label>
        <Input id="new" type="password" />
      </div>
      <Button>Update password</Button>
    </TabsContent>
  </Tabs>
</template>

<script setup lang="ts">
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
</script>
```

---

## Best Practices & Patterns

### 1. Component Composition

```vue
<template>
  <!-- Good: Compose multiple simple components -->
  <Card>
    <CardHeader>
      <div class="flex items-center justify-between">
        <div>
          <CardTitle>{{ title }}</CardTitle>
          <CardDescription>{{ description }}</CardDescription>
        </div>
        <Badge :variant="status === 'active' ? 'default' : 'secondary'">
          {{ status }}
        </Badge>
      </div>
    </CardHeader>
    <CardContent>
      <slot />
    </CardContent>
    <CardFooter v-if="$slots.footer">
      <slot name="footer" />
    </CardFooter>
  </Card>
</template>
```

### 2. Accessibility Considerations

```vue
<template>
  <!-- Always include proper labels and ARIA attributes -->
  <div class="space-y-2">
    <Label for="email" class="sr-only">Email address</Label>
    <Input
      id="email"
      type="email"
      placeholder="Enter your email"
      aria-describedby="email-error"
      :aria-invalid="!!errors.email"
    />
    <p id="email-error" class="text-sm text-red-500" aria-live="polite">
      {{ errors.email }}
    </p>
  </div>
</template>
```

### 3. Responsive Design

```vue
<template>
  <!-- Use responsive utilities for different screen sizes -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
    <Card v-for="item in items" :key="item.id" class="h-full">
      <!-- Card content -->
    </Card>
  </div>
</template>
```

### 4. Loading States

```vue
<template>
  <div class="space-y-4">
    <!-- Show skeletons while loading -->
    <template v-if="isLoading">
      <Skeleton class="h-4 w-full" />
      <Skeleton class="h-4 w-3/4" />
      <Skeleton class="h-8 w-1/2" />
    </template>
    
    <!-- Show actual content when loaded -->
    <template v-else>
      <h2>{{ data.title }}</h2>
      <p>{{ data.description }}</p>
      <Button>{{ data.action }}</Button>
    </template>
  </div>
</template>
```

---

*Next: [Styling and Theming](./shadcn-vue-styling-theming.md) - Comprehensive guide to customizing appearance, themes, and Tailwind CSS integration.*
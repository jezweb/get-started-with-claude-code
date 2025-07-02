# shadcn/vue Complete Documentation

## Overview

This comprehensive documentation set covers all aspects of shadcn/vue development, from fundamental concepts to advanced implementation patterns. shadcn/vue is a collection of beautifully designed Vue components built using Radix Vue and Tailwind CSS that you can copy and paste into your applications.

## 📚 Documentation Contents

### 1. [shadcn/vue Fundamentals and Setup](./shadcn-vue-fundamentals-setup.md)
- **Core Philosophy** - Copy/paste approach vs traditional component libraries
- **Installation Methods** - Vite, Nuxt, Astro, Laravel, and manual setup
- **CLI Tool** - Component management and project scaffolding
- **Project Structure** - File organization and configuration patterns
- **Basic Theming** - Initial customization and CSS variable setup

### 2. [Component Reference and Usage](./shadcn-vue-components-reference.md)
- **Complete Component Catalog** - All 40+ available components with examples
- **Component Categories** - Basic UI, Interactive, Forms, Navigation, and Advanced
- **Usage Patterns** - Props, slots, events, and composition patterns
- **Accessibility** - ARIA compliance and keyboard navigation
- **Best Practices** - Component composition and reusability patterns

### 3. [Styling and Theming](./shadcn-vue-styling-theming.md)
- **Tailwind CSS Integration** - Configuration and customization patterns
- **Theme System** - Creating and managing custom themes
- **Dark/Light Mode** - Implementation strategies and user preferences
- **CSS Variables** - Color schemes and design token management
- **Component Styling** - Overrides, variants, and custom styling approaches

### 4. [Framework Integration](./shadcn-vue-framework-integration.md)
- **Vue 3 Patterns** - Composition API integration and reactive patterns
- **Nuxt.js Implementation** - SSR considerations and module configuration
- **Vite Configuration** - Build optimization and development setup
- **Laravel Integration** - Backend integration and asset compilation
- **TypeScript Support** - Type safety and developer experience

### 5. [Blocks and Advanced Patterns](./shadcn-vue-blocks-advanced-patterns.md)
- **Blocks vs Components** - Understanding the distinction and use cases
- **Complex UI Patterns** - Layout composition and advanced interactions
- **Form Handling** - Validation, state management, and user experience
- **State Management** - Pinia/Vuex integration and reactive state patterns
- **Production Deployment** - Performance optimization and build strategies

## 🎯 Target Audience

This documentation is designed for:
- **Vue.js developers** building modern web applications
- **Frontend developers** seeking high-quality, customizable UI components
- **Design system architects** creating consistent user interfaces
- **Full-stack developers** integrating frontend components with backend APIs
- **Teams** looking to standardize their component library approach

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ (18+ recommended)
- Vue 3.2+ 
- Basic understanding of Vue Composition API and Tailwind CSS
- Familiarity with modern JavaScript and TypeScript (optional)

### Installation
```bash
# Using the CLI (recommended)
npx shadcn-vue@latest init

# Manual installation
npm install @radix-vue/vue @tailwindcss/forms class-variance-authority clsx tailwind-merge
```

### Basic Component Usage
```vue
<template>
  <div class="space-y-4">
    <Button variant="default" size="lg">
      Click me
    </Button>
    
    <Card>
      <CardHeader>
        <CardTitle>Welcome to shadcn/vue</CardTitle>
        <CardDescription>
          Beautiful components built with Radix Vue and Tailwind CSS
        </CardDescription>
      </CardHeader>
      <CardContent>
        <p>Start building amazing UIs with ready-to-use components.</p>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card'
</script>
```

## 📖 Key Concepts and Philosophy

### Copy and Paste Approach
Unlike traditional component libraries, shadcn/vue provides:
- **Source code ownership** - Components live in your codebase
- **Full customization** - Modify components to fit your exact needs
- **No external dependencies** - Reduce bundle size and version conflicts
- **Learning opportunity** - Understand how components work internally

### Design Principles
- **Accessibility first** - Built with screen readers and keyboard navigation in mind
- **Responsive design** - Components work seamlessly across all device sizes
- **Consistent styling** - Unified design language with Tailwind CSS
- **Developer experience** - TypeScript support and excellent IDE integration

## 🔧 Common Patterns and Examples

### 1. Form with Validation
```vue
<template>
  <form @submit="handleSubmit" class="space-y-6">
    <div>
      <Label for="email">Email</Label>
      <Input 
        id="email" 
        v-model="form.email" 
        type="email" 
        placeholder="Enter your email"
        :class="errors.email ? 'border-red-500' : ''"
      />
      <p v-if="errors.email" class="text-sm text-red-500 mt-1">
        {{ errors.email }}
      </p>
    </div>
    
    <Button type="submit" :disabled="isLoading" class="w-full">
      <Loader2 v-if="isLoading" class="mr-2 h-4 w-4 animate-spin" />
      {{ isLoading ? 'Processing...' : 'Submit' }}
    </Button>
  </form>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Loader2 } from 'lucide-vue-next'

const form = reactive({
  email: ''
})

const errors = ref({})
const isLoading = ref(false)

const handleSubmit = async (e: Event) => {
  e.preventDefault()
  // Form submission logic
}
</script>
```

### 2. Data Table with Actions
```vue
<template>
  <div class="space-y-4">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-bold">Users</h2>
      <Button @click="openCreateDialog">
        <Plus class="mr-2 h-4 w-4" />
        Add User
      </Button>
    </div>
    
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Name</TableHead>
          <TableHead>Email</TableHead>
          <TableHead>Role</TableHead>
          <TableHead class="text-right">Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        <TableRow v-for="user in users" :key="user.id">
          <TableCell>{{ user.name }}</TableCell>
          <TableCell>{{ user.email }}</TableCell>
          <TableCell>
            <Badge :variant="user.role === 'admin' ? 'default' : 'secondary'">
              {{ user.role }}
            </Badge>
          </TableCell>
          <TableCell class="text-right">
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <Button variant="ghost" size="sm">
                  <MoreVertical class="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem @click="editUser(user)">
                  Edit
                </DropdownMenuItem>
                <DropdownMenuItem @click="deleteUser(user.id)" class="text-red-600">
                  Delete
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </TableCell>
        </TableRow>
      </TableBody>
    </Table>
  </div>
</template>
```

### 3. Modal Dialog with Form
```vue
<template>
  <Dialog v-model:open="isOpen">
    <DialogContent class="sm:max-w-md">
      <DialogHeader>
        <DialogTitle>Create New Project</DialogTitle>
        <DialogDescription>
          Enter the details for your new project.
        </DialogDescription>
      </DialogHeader>
      
      <form @submit="handleSubmit" class="space-y-4">
        <div>
          <Label for="name">Project Name</Label>
          <Input 
            id="name" 
            v-model="projectForm.name" 
            placeholder="My awesome project"
          />
        </div>
        
        <div>
          <Label for="description">Description</Label>
          <Textarea 
            id="description" 
            v-model="projectForm.description" 
            placeholder="Project description..."
          />
        </div>
        
        <DialogFooter>
          <Button type="button" variant="outline" @click="isOpen = false">
            Cancel
          </Button>
          <Button type="submit">
            Create Project
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  </Dialog>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

const isOpen = ref(false)
const projectForm = reactive({
  name: '',
  description: ''
})

const handleSubmit = (e: Event) => {
  e.preventDefault()
  // Handle form submission
  isOpen.value = false
}
</script>
```

## 🎨 Theming and Customization

### CSS Variables Approach
```css
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 221.2 83.2% 53.3%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222.2 84% 4.9%;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --primary: 217.2 91.2% 59.8%;
  --primary-foreground: 222.2 84% 4.9%;
}
```

### Component Variants
```typescript
import { cva } from 'class-variance-authority'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)
```

## 🔗 Ecosystem Integration

### State Management
- **Pinia** - Recommended for complex state management
- **Vuex** - Legacy support and migration patterns
- **Local state** - Component-level reactive state

### Routing
- **Vue Router** - SPA navigation and route guards
- **Nuxt routing** - File-based routing and middleware

### Build Tools
- **Vite** - Fast development and optimized builds
- **Webpack** - Traditional bundling with Vue CLI
- **Rollup** - Library and component packaging

### Backend Integration
- **REST APIs** - HTTP clients and error handling
- **GraphQL** - Apollo Client and query management
- **WebSockets** - Real-time communication patterns

## 📊 Performance Considerations

### Bundle Size Optimization
- **Tree shaking** - Import only components you use
- **Code splitting** - Lazy loading for large applications
- **Dynamic imports** - Route-level and component-level splitting

### Runtime Performance
- **Virtual scrolling** - For large lists and tables
- **Memoization** - Expensive computations and renders
- **Reactive optimization** - Efficient state updates

## 🧪 Testing Strategies

### Component Testing
```typescript
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import Button from '@/components/ui/button/Button.vue'

describe('Button', () => {
  it('renders with correct variant', () => {
    const wrapper = mount(Button, {
      props: { variant: 'destructive' },
      slots: { default: 'Delete' }
    })
    
    expect(wrapper.classes()).toContain('bg-destructive')
    expect(wrapper.text()).toBe('Delete')
  })
})
```

### E2E Testing
```typescript
import { test, expect } from '@playwright/test'

test('user can create a new project', async ({ page }) => {
  await page.goto('/dashboard')
  await page.click('text=Add Project')
  await page.fill('[placeholder="My awesome project"]', 'Test Project')
  await page.click('text=Create Project')
  await expect(page.locator('text=Test Project')).toBeVisible()
})
```

## 🔗 Related Resources

### Official Documentation
- [shadcn/vue Official Site](https://www.shadcn-vue.com/)
- [Radix Vue Documentation](https://www.radix-vue.com/)
- [Tailwind CSS Documentation](https://tailwindcss.com/)
- [Vue 3 Documentation](https://vuejs.org/)

### Complementary Documentation
- [Vue 3 Composition API Guide](https://vuejs.org/guide/extras/composition-api-faq.html)
- [Tailwind CSS Best Practices](https://tailwindcss.com/docs/reusing-styles)
- [TypeScript with Vue](https://vuejs.org/guide/typescript/overview.html)

### Tools and Libraries
- **Development**: Vite, Vue DevTools, Tailwind IntelliSense
- **Testing**: Vitest, Vue Test Utils, Playwright
- **State Management**: Pinia, VueUse
- **Icons**: Lucide Vue, Heroicons
- **Animation**: Framer Motion Vue, Vue Transition

## 💡 Contributing

This documentation focuses on practical, production-ready patterns. Each section includes:
- **Complete working examples** that demonstrate real-world usage
- **Best practices** learned from production applications
- **Performance considerations** and optimization techniques
- **Accessibility guidelines** and inclusive design patterns
- **Testing strategies** for reliable component development

## 📝 Changelog

### Latest Updates
- **shadcn/vue 0.10+** compatibility
- **Vue 3.3+** performance optimizations
- **Tailwind CSS 3.3+** integration patterns
- **TypeScript 5.0+** type improvements
- **Radix Vue 1.0+** component updates

---

*This documentation is part of the comprehensive Vue.js & shadcn/vue Context Documentation Project, providing production-ready patterns for modern component-based development.*
# shadcn/vue Framework Integration

## Overview

This comprehensive guide covers integrating shadcn/vue components with various Vue.js frameworks and build tools. Learn how to optimize your setup for Vue 3, Nuxt.js, Vite, Laravel, and other popular development environments while maintaining performance, type safety, and developer experience.

## 🚀 Vue 3 Integration Patterns

### Composition API Best Practices

Leverage Vue 3's Composition API for optimal component integration:

```typescript
// src/composables/useComponentLibrary.ts
import { ref, computed, provide, inject, type InjectionKey } from 'vue'

// Component configuration
interface ComponentConfig {
  theme: 'light' | 'dark' | 'system'
  variant: 'default' | 'outline' | 'ghost'
  size: 'sm' | 'default' | 'lg'
  animations: boolean
}

const ComponentConfigKey: InjectionKey<ComponentConfig> = Symbol('component-config')

export function useComponentConfig() {
  const config = ref<ComponentConfig>({
    theme: 'system',
    variant: 'default',
    size: 'default',
    animations: true,
  })

  const updateConfig = (updates: Partial<ComponentConfig>) => {
    config.value = { ...config.value, ...updates }
  }

  const isDark = computed(() => {
    if (config.value.theme === 'system') {
      return window.matchMedia('(prefers-color-scheme: dark)').matches
    }
    return config.value.theme === 'dark'
  })

  provide(ComponentConfigKey, config.value)

  return {
    config: readonly(config),
    updateConfig,
    isDark,
  }
}

export function useInjectedConfig() {
  const config = inject(ComponentConfigKey)
  if (!config) {
    throw new Error('useInjectedConfig must be used within a component config provider')
  }
  return config
}
```

### Global Component Registration

Register commonly used components globally:

```typescript
// src/plugins/shadcn-vue.ts
import type { App } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

export default {
  install(app: App) {
    // Register commonly used components globally
    app.component('Button', Button)
    app.component('Input', Input)
    app.component('Label', Label)
    app.component('Card', Card)
    app.component('CardContent', CardContent)
    app.component('CardDescription', CardDescription)
    app.component('CardFooter', CardFooter)
    app.component('CardHeader', CardHeader)
    app.component('CardTitle', CardTitle)
    app.component('Badge', Badge)
    app.component('Avatar', Avatar)
    app.component('AvatarFallback', AvatarFallback)
    app.component('AvatarImage', AvatarImage)

    // Provide global configuration
    app.provide('shadcn-config', {
      theme: 'system',
      animations: true,
    })
  },
}
```

```typescript
// src/main.ts
import { createApp } from 'vue'
import App from './App.vue'
import ShadcnVue from './plugins/shadcn-vue'
import './styles/globals.css'

const app = createApp(App)

app.use(ShadcnVue)
app.mount('#app')
```

### Reactive Form Handling

Implement reactive forms with validation:

```vue
<!-- src/composables/useForm.ts -->
<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import type { Ref } from 'vue'

interface ValidationRule {
  required?: boolean
  minLength?: number
  maxLength?: number
  pattern?: RegExp
  custom?: (value: any) => string | null
}

interface FieldConfig {
  rules?: ValidationRule[]
  validateOn?: 'blur' | 'input' | 'submit'
}

export function useForm<T extends Record<string, any>>(
  initialValues: T,
  fieldConfigs: Partial<Record<keyof T, FieldConfig>> = {}
) {
  const values = reactive<T>({ ...initialValues })
  const errors = ref<Partial<Record<keyof T, string>>>({})
  const touched = ref<Partial<Record<keyof T, boolean>>>({})
  const isSubmitting = ref(false)

  const validateField = (field: keyof T): string | null => {
    const value = values[field]
    const config = fieldConfigs[field]
    
    if (!config?.rules) return null

    for (const rule of config.rules) {
      if (rule.required && (!value || value === '')) {
        return `${String(field)} is required`
      }
      
      if (rule.minLength && value.length < rule.minLength) {
        return `${String(field)} must be at least ${rule.minLength} characters`
      }
      
      if (rule.maxLength && value.length > rule.maxLength) {
        return `${String(field)} must be no more than ${rule.maxLength} characters`
      }
      
      if (rule.pattern && !rule.pattern.test(value)) {
        return `${String(field)} format is invalid`
      }
      
      if (rule.custom) {
        const customError = rule.custom(value)
        if (customError) return customError
      }
    }
    
    return null
  }

  const validateForm = (): boolean => {
    const newErrors: Partial<Record<keyof T, string>> = {}
    
    for (const field in fieldConfigs) {
      const error = validateField(field)
      if (error) {
        newErrors[field] = error
      }
    }
    
    errors.value = newErrors
    return Object.keys(newErrors).length === 0
  }

  const setFieldValue = (field: keyof T, value: any) => {
    values[field] = value
    
    const config = fieldConfigs[field]
    if (config?.validateOn === 'input') {
      const error = validateField(field)
      if (error) {
        errors.value[field] = error
      } else {
        delete errors.value[field]
      }
    }
  }

  const setFieldTouched = (field: keyof T) => {
    touched.value[field] = true
    
    const config = fieldConfigs[field]
    if (config?.validateOn === 'blur') {
      const error = validateField(field)
      if (error) {
        errors.value[field] = error
      } else {
        delete errors.value[field]
      }
    }
  }

  const resetForm = () => {
    Object.assign(values, initialValues)
    errors.value = {}
    touched.value = {}
    isSubmitting.value = false
  }

  const isValid = computed(() => Object.keys(errors.value).length === 0)

  return {
    values,
    errors: readonly(errors),
    touched: readonly(touched),
    isSubmitting: readonly(isSubmitting),
    isValid,
    setFieldValue,
    setFieldTouched,
    validateForm,
    resetForm,
    setSubmitting: (submitting: boolean) => {
      isSubmitting.value = submitting
    },
  }
}
</script>
```

```vue
<!-- Usage Example -->
<template>
  <form @submit="onSubmit" class="space-y-6">
    <div>
      <Label for="email">Email</Label>
      <Input
        id="email"
        type="email"
        :value="form.values.email"
        :class="form.errors.email ? 'border-red-500' : ''"
        @input="(e) => form.setFieldValue('email', e.target.value)"
        @blur="() => form.setFieldTouched('email')"
        placeholder="Enter your email"
      />
      <p v-if="form.errors.email" class="text-sm text-red-500 mt-1">
        {{ form.errors.email }}
      </p>
    </div>

    <div>
      <Label for="password">Password</Label>
      <Input
        id="password"
        type="password"
        :value="form.values.password"
        :class="form.errors.password ? 'border-red-500' : ''"
        @input="(e) => form.setFieldValue('password', e.target.value)"
        @blur="() => form.setFieldTouched('password')"
        placeholder="Enter your password"
      />
      <p v-if="form.errors.password" class="text-sm text-red-500 mt-1">
        {{ form.errors.password }}
      </p>
    </div>

    <Button 
      type="submit" 
      :disabled="!form.isValid || form.isSubmitting"
      class="w-full"
    >
      <Loader2 v-if="form.isSubmitting" class="mr-2 h-4 w-4 animate-spin" />
      {{ form.isSubmitting ? 'Signing in...' : 'Sign In' }}
    </Button>
  </form>
</template>

<script setup lang="ts">
import { useForm } from '@/composables/useForm'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Loader2 } from 'lucide-vue-next'

const form = useForm(
  {
    email: '',
    password: '',
  },
  {
    email: {
      rules: [
        { required: true },
        { pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ },
      ],
      validateOn: 'blur',
    },
    password: {
      rules: [
        { required: true },
        { minLength: 8 },
      ],
      validateOn: 'blur',
    },
  }
)

const onSubmit = async (e: Event) => {
  e.preventDefault()
  
  if (!form.validateForm()) return
  
  form.setSubmitting(true)
  try {
    // Handle form submission
    await new Promise(resolve => setTimeout(resolve, 2000))
    console.log('Form submitted:', form.values)
  } catch (error) {
    console.error('Submission error:', error)
  } finally {
    form.setSubmitting(false)
  }
}
</script>
```

## 🏗️ Nuxt.js Integration

### Nuxt Module Configuration

Create a Nuxt module for shadcn/vue integration:

```typescript
// modules/shadcn-vue/index.ts
import { defineNuxtModule, addPlugin, createResolver, addImports } from '@nuxt/kit'

export default defineNuxtModule({
  meta: {
    name: 'shadcn-vue',
    configKey: 'shadcnVue',
  },
  defaults: {
    prefix: '',
    theme: 'default',
    darkMode: true,
  },
  setup(options, nuxt) {
    const resolver = createResolver(import.meta.url)

    // Add plugin
    addPlugin(resolver.resolve('./runtime/plugin'))

    // Add auto-imports for composables
    addImports([
      {
        name: 'useTheme',
        from: resolver.resolve('./runtime/composables/useTheme'),
      },
      {
        name: 'useToast',
        from: resolver.resolve('./runtime/composables/useToast'),
      },
    ])

    // Extend Tailwind config
    nuxt.options.css.push(resolver.resolve('./runtime/assets/globals.css'))
    
    // Add Tailwind CSS module
    if (!nuxt.options.modules.includes('@nuxtjs/tailwindcss')) {
      nuxt.options.modules.push('@nuxtjs/tailwindcss')
    }
  },
})
```

### Nuxt Plugin Setup

```typescript
// modules/shadcn-vue/runtime/plugin.ts
import { defineNuxtPlugin } from '#app'
import { useTheme } from './composables/useTheme'

export default defineNuxtPlugin(() => {
  // Initialize theme on client side
  if (process.client) {
    const { initializeTheme } = useTheme()
    initializeTheme()
  }

  return {
    provide: {
      shadcnVue: {
        version: '1.0.0',
      },
    },
  }
})
```

### SSR-Compatible Theme Management

```typescript
// modules/shadcn-vue/runtime/composables/useTheme.ts
import { ref, computed, watch } from 'vue'
import { useCookie } from '#app'

type Theme = 'light' | 'dark' | 'system'

export function useTheme() {
  const themeCookie = useCookie<Theme>('theme', {
    default: () => 'system',
    sameSite: 'lax',
  })

  const theme = ref<Theme>(themeCookie.value)

  const getSystemTheme = (): 'light' | 'dark' => {
    if (process.server) return 'light'
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }

  const actualTheme = computed(() => {
    return theme.value === 'system' ? getSystemTheme() : theme.value
  })

  const setTheme = (newTheme: Theme) => {
    theme.value = newTheme
    themeCookie.value = newTheme
    applyTheme()
  }

  const applyTheme = () => {
    if (process.server) return

    const root = document.documentElement
    root.classList.remove('light', 'dark')
    root.classList.add(actualTheme.value)
  }

  const initializeTheme = () => {
    if (process.server) return

    // Apply theme immediately
    applyTheme()

    // Listen for system theme changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (theme.value === 'system') {
        applyTheme()
      }
    })
  }

  // Watch for theme changes
  watch(theme, applyTheme)

  return {
    theme: readonly(theme),
    actualTheme,
    setTheme,
    initializeTheme,
  }
}
```

### Nuxt Pages with shadcn/vue

```vue
<!-- pages/dashboard.vue -->
<template>
  <div class="min-h-screen bg-background">
    <nav class="border-b">
      <div class="container mx-auto px-4">
        <div class="flex h-16 items-center justify-between">
          <h1 class="text-xl font-semibold">Dashboard</h1>
          
          <div class="flex items-center space-x-4">
            <Button @click="toggleTheme" variant="outline" size="icon">
              <Sun v-if="actualTheme === 'dark'" class="h-4 w-4" />
              <Moon v-else class="h-4 w-4" />
            </Button>
            
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <Button variant="ghost" size="icon">
                  <User class="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem>Profile</DropdownMenuItem>
                <DropdownMenuItem>Settings</DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem>Logout</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>
    </nav>

    <main class="container mx-auto px-4 py-8">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Card v-for="metric in metrics" :key="metric.id">
          <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle class="text-sm font-medium">
              {{ metric.title }}
            </CardTitle>
            <component :is="metric.icon" class="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div class="text-2xl font-bold">{{ metric.value }}</div>
            <p class="text-xs text-muted-foreground">
              {{ metric.change }}
            </p>
          </CardContent>
        </Card>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { DollarSign, Users, CreditCard, Activity, Sun, Moon, User } from 'lucide-vue-next'

definePageMeta({
  title: 'Dashboard',
  description: 'Application dashboard with metrics and analytics',
})

const { actualTheme, setTheme } = useTheme()

const toggleTheme = () => {
  setTheme(actualTheme.value === 'dark' ? 'light' : 'dark')
}

const metrics = [
  {
    id: 1,
    title: 'Total Revenue',
    value: '$45,231.89',
    change: '+20.1% from last month',
    icon: DollarSign,
  },
  {
    id: 2,
    title: 'Subscriptions',
    value: '+2350',
    change: '+180.1% from last month',
    icon: Users,
  },
  {
    id: 3,
    title: 'Sales',
    value: '+12,234',
    change: '+19% from last month',
    icon: CreditCard,
  },
  {
    id: 4,
    title: 'Active Now',
    value: '+573',
    change: '+201 since last hour',
    icon: Activity,
  },
]
</script>
```

## ⚡ Vite Optimization

### Advanced Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [
    vue({
      script: {
        defineModel: true,
        propsDestructure: true,
      },
    }),
  ],
  
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      '~': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/styles/variables.scss";`,
      },
    },
  },
  
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Separate vendor chunks
          'vendor-vue': ['vue', 'vue-router'],
          'vendor-ui': ['@radix-vue/vue', 'class-variance-authority'],
          'vendor-icons': ['lucide-vue-next'],
          'vendor-utils': ['clsx', 'tailwind-merge'],
        },
      },
    },
    
    // Enable source maps in development
    sourcemap: true,
    
    // Optimize bundle size
    target: 'esnext',
    minify: 'esbuild',
  },
  
  optimizeDeps: {
    include: [
      'vue',
      'vue-router',
      '@radix-vue/vue',
      'class-variance-authority',
      'clsx',
      'tailwind-merge',
      'lucide-vue-next',
    ],
  },
  
  server: {
    host: true,
    port: 3000,
    strictPort: false,
  },
  
  preview: {
    port: 4173,
    strictPort: false,
  },
})
```

### Dynamic Component Loading

Implement lazy loading for better performance:

```typescript
// src/utils/lazy-components.ts
import { defineAsyncComponent, type AsyncComponentLoader } from 'vue'

export function createLazyComponent<T>(
  loader: AsyncComponentLoader<T>,
  loadingComponent?: T,
  errorComponent?: T,
  delay = 200,
  timeout = 3000
) {
  return defineAsyncComponent({
    loader,
    loadingComponent,
    errorComponent,
    delay,
    timeout,
  })
}

// Lazy load shadcn/vue components
export const LazyDataTable = createLazyComponent(
  () => import('@/components/ui/data-table/DataTable.vue')
)

export const LazyCalendar = createLazyComponent(
  () => import('@/components/ui/calendar/Calendar.vue')
)

export const LazyCarousel = createLazyComponent(
  () => import('@/components/ui/carousel/Carousel.vue')
)
```

### Build-Time Component Registration

Automatically register components at build time:

```typescript
// scripts/generate-component-registry.ts
import { readdir, writeFile } from 'fs/promises'
import { join } from 'path'

async function generateComponentRegistry() {
  const componentsDir = join(process.cwd(), 'src/components/ui')
  const components = await readdir(componentsDir, { withFileTypes: true })
  
  const imports: string[] = []
  const exports: string[] = []
  
  for (const component of components) {
    if (component.isDirectory()) {
      const componentName = component.name
      const pascalName = componentName
        .split('-')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join('')
      
      imports.push(`import ${pascalName} from './${componentName}/${pascalName}.vue'`)
      exports.push(pascalName)
    }
  }
  
  const registryContent = `
// Auto-generated component registry
${imports.join('\n')}

export {
  ${exports.join(',\n  ')}
}

export const components = {
  ${exports.join(',\n  ')}
}
`
  
  await writeFile(
    join(componentsDir, 'index.ts'),
    registryContent.trim()
  )
  
  console.log(`Generated registry for ${exports.length} components`)
}

generateComponentRegistry().catch(console.error)
```

## 🔧 Laravel Integration

### Laravel Inertia.js Setup

Integrate shadcn/vue with Laravel and Inertia.js:

```php
<?php
// app/Http/Middleware/HandleInertiaRequests.php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    public function share(Request $request): array
    {
        return array_merge(parent::share($request), [
            'auth' => [
                'user' => $request->user(),
            ],
            'flash' => [
                'message' => fn () => $request->session()->get('message'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'theme' => [
                'default' => config('app.theme', 'system'),
                'available' => ['light', 'dark', 'system'],
            ],
        ]);
    }
}
```

```vue
<!-- resources/js/Pages/Dashboard.vue -->
<template>
  <AppLayout title="Dashboard">
    <template #header>
      <div class="flex items-center justify-between">
        <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
          Dashboard
        </h2>
        
        <div class="flex items-center space-x-4">
          <Button @click="refreshData" variant="outline" size="sm">
            <RefreshCw :class="{ 'animate-spin': isRefreshing }" class="w-4 h-4 mr-2" />
            Refresh
          </Button>
          
          <ThemeToggle />
        </div>
      </div>
    </template>

    <div class="py-12">
      <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card v-for="stat in stats" :key="stat.name">
            <CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle class="text-sm font-medium">
                {{ stat.name }}
              </CardTitle>
              <component :is="stat.icon" class="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div class="text-2xl font-bold">{{ stat.value }}</div>
              <p class="text-xs text-muted-foreground">
                <span :class="stat.changeType === 'positive' ? 'text-green-600' : 'text-red-600'">
                  {{ stat.change }}
                </span>
                {{ stat.period }}
              </p>
            </CardContent>
          </Card>
        </div>

        <!-- Recent Activity -->
        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>
              Latest activities in your application
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div class="space-y-4">
              <div v-for="activity in recentActivity" :key="activity.id" class="flex items-center space-x-4">
                <Avatar class="h-9 w-9">
                  <AvatarImage :src="activity.user.avatar" :alt="activity.user.name" />
                  <AvatarFallback>{{ activity.user.initials }}</AvatarFallback>
                </Avatar>
                <div class="ml-4 space-y-1">
                  <p class="text-sm font-medium leading-none">{{ activity.description }}</p>
                  <p class="text-sm text-muted-foreground">
                    {{ formatTimeAgo(activity.created_at) }}
                  </p>
                </div>
                <div class="ml-auto font-medium">
                  <Badge :variant="activity.type === 'success' ? 'default' : 'secondary'">
                    {{ activity.type }}
                  </Badge>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { router, usePage } from '@inertiajs/vue3'
import AppLayout from '@/Layouts/AppLayout.vue'
import ThemeToggle from '@/Components/ThemeToggle.vue'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { DollarSign, Users, CreditCard, Activity, RefreshCw } from 'lucide-vue-next'

interface Props {
  stats: Array<{
    name: string
    value: string
    change: string
    changeType: 'positive' | 'negative'
    period: string
    icon: string
  }>
  recentActivity: Array<{
    id: number
    description: string
    type: string
    created_at: string
    user: {
      name: string
      avatar: string
      initials: string
    }
  }>
}

const props = defineProps<Props>()
const isRefreshing = ref(false)

const iconMap = {
  DollarSign,
  Users,
  CreditCard,
  Activity,
}

const stats = computed(() => 
  props.stats.map(stat => ({
    ...stat,
    icon: iconMap[stat.icon as keyof typeof iconMap] || Activity
  }))
)

const refreshData = async () => {
  isRefreshing.value = true
  try {
    await router.reload({ only: ['stats', 'recentActivity'] })
  } finally {
    isRefreshing.value = false
  }
}

const formatTimeAgo = (date: string) => {
  const now = new Date()
  const past = new Date(date)
  const diffInSeconds = Math.floor((now.getTime() - past.getTime()) / 1000)
  
  if (diffInSeconds < 60) return 'Just now'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
  return `${Math.floor(diffInSeconds / 86400)}d ago`
}
</script>
```

### Laravel API Integration

Create Laravel controllers that work seamlessly with shadcn/vue components:

```php
<?php
// app/Http/Controllers/DashboardController.php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\User;
use App\Models\Order;
use App\Models\Activity;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = $this->getDashboardStats();
        $recentActivity = $this->getRecentActivity();
        
        return Inertia::render('Dashboard', [
            'stats' => $stats,
            'recentActivity' => $recentActivity,
        ]);
    }
    
    private function getDashboardStats()
    {
        $totalRevenue = Order::sum('total');
        $totalUsers = User::count();
        $totalOrders = Order::count();
        $activeUsers = User::where('last_login_at', '>=', now()->subDay())->count();
        
        return [
            [
                'name' => 'Total Revenue',
                'value' => '$' . number_format($totalRevenue, 2),
                'change' => '+20.1%',
                'changeType' => 'positive',
                'period' => 'from last month',
                'icon' => 'DollarSign',
            ],
            [
                'name' => 'Users',
                'value' => number_format($totalUsers),
                'change' => '+180.1%',
                'changeType' => 'positive',
                'period' => 'from last month',
                'icon' => 'Users',
            ],
            [
                'name' => 'Orders',
                'value' => number_format($totalOrders),
                'change' => '+19%',
                'changeType' => 'positive',
                'period' => 'from last month',
                'icon' => 'CreditCard',
            ],
            [
                'name' => 'Active Users',
                'value' => number_format($activeUsers),
                'change' => '+201',
                'changeType' => 'positive',
                'period' => 'since last hour',
                'icon' => 'Activity',
            ],
        ];
    }
    
    private function getRecentActivity()
    {
        return Activity::with('user')
            ->latest()
            ->take(10)
            ->get()
            ->map(function ($activity) {
                return [
                    'id' => $activity->id,
                    'description' => $activity->description,
                    'type' => $activity->type,
                    'created_at' => $activity->created_at->toISOString(),
                    'user' => [
                        'name' => $activity->user->name,
                        'avatar' => $activity->user->avatar_url,
                        'initials' => $this->getInitials($activity->user->name),
                    ],
                ];
            });
    }
    
    private function getInitials($name)
    {
        return collect(explode(' ', $name))
            ->map(fn ($segment) => strtoupper(substr($segment, 0, 1)))
            ->take(2)
            ->implode('');
    }
}
```

## 📱 TypeScript Integration

### Enhanced Type Definitions

Create comprehensive type definitions for your components:

```typescript
// src/types/components.ts
import type { Component } from 'vue'
import type { VariantProps } from 'class-variance-authority'

// Base component props
export interface BaseComponentProps {
  class?: string
  id?: string
}

// Button component types
export interface ButtonProps extends BaseComponentProps {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link'
  size?: 'default' | 'sm' | 'lg' | 'icon'
  disabled?: boolean
  loading?: boolean
  type?: 'button' | 'submit' | 'reset'
  as?: string | Component
}

// Form field types
export interface FormFieldProps extends BaseComponentProps {
  label?: string
  description?: string
  error?: string
  required?: boolean
  disabled?: boolean
}

// Data table types
export interface DataTableColumn<T = any> {
  key: keyof T
  title: string
  sortable?: boolean
  searchable?: boolean
  width?: string | number
  align?: 'left' | 'center' | 'right'
  render?: (value: T[keyof T], row: T, index: number) => any
}

export interface DataTableProps<T = any> extends BaseComponentProps {
  data: T[]
  columns: DataTableColumn<T>[]
  loading?: boolean
  pagination?: {
    page: number
    pageSize: number
    total: number
  }
  sorting?: {
    key: keyof T
    direction: 'asc' | 'desc'
  }
  selection?: {
    enabled: boolean
    selectedRows: T[]
  }
}

// Theme types
export interface ThemeConfig {
  colors: {
    primary: string
    secondary: string
    background: string
    foreground: string
    muted: string
    accent: string
    destructive: string
    border: string
    input: string
    ring: string
  }
  borderRadius: string
  fontFamily: {
    sans: string[]
    mono: string[]
  }
}
```

### Component Type Safety

Implement strict typing for component props and events:

```vue
<!-- src/components/ui/enhanced-data-table/EnhancedDataTable.vue -->
<template>
  <div class="space-y-4">
    <!-- Table Header -->
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-2">
        <Input
          v-if="searchable"
          v-model="searchQuery"
          placeholder="Search..."
          class="w-64"
        />
        <Button
          v-if="refreshable"
          @click="emit('refresh')"
          variant="outline"
          size="sm"
          :disabled="loading"
        >
          <RefreshCw :class="{ 'animate-spin': loading }" class="w-4 h-4 mr-2" />
          Refresh
        </Button>
      </div>
      
      <div class="flex items-center space-x-2">
        <Button
          v-if="selection?.enabled && selection.selectedRows.length > 0"
          @click="emit('bulk-action', 'delete', selection.selectedRows)"
          variant="destructive"
          size="sm"
        >
          Delete ({{ selection.selectedRows.length }})
        </Button>
        
        <slot name="actions" />
      </div>
    </div>

    <!-- Table -->
    <div class="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead v-if="selection?.enabled" class="w-12">
              <Checkbox
                :checked="isAllSelected"
                @update:checked="toggleSelectAll"
              />
            </TableHead>
            
            <TableHead
              v-for="column in columns"
              :key="String(column.key)"
              :class="getHeaderClasses(column)"
              @click="handleSort(column)"
            >
              <div class="flex items-center space-x-2">
                <span>{{ column.title }}</span>
                <div v-if="column.sortable" class="flex flex-col">
                  <ChevronUp 
                    class="w-3 h-3" 
                    :class="getSortIconClasses(column, 'asc')"
                  />
                  <ChevronDown 
                    class="w-3 h-3 -mt-1" 
                    :class="getSortIconClasses(column, 'desc')"
                  />
                </div>
              </div>
            </TableHead>
          </TableRow>
        </TableHeader>
        
        <TableBody>
          <TableRow v-if="loading">
            <TableCell :colspan="totalColumns" class="text-center py-8">
              <Loader2 class="w-6 h-6 animate-spin mx-auto" />
              <p class="mt-2 text-muted-foreground">Loading...</p>
            </TableCell>
          </TableRow>
          
          <TableRow v-else-if="filteredData.length === 0">
            <TableCell :colspan="totalColumns" class="text-center py-8">
              <p class="text-muted-foreground">No data available</p>
            </TableCell>
          </TableRow>
          
          <TableRow
            v-else
            v-for="(row, index) in paginatedData"
            :key="getRowKey(row, index)"
            @click="emit('row-click', row, index)"
            :class="getRowClasses(row, index)"
          >
            <TableCell v-if="selection?.enabled">
              <Checkbox
                :checked="isRowSelected(row)"
                @update:checked="(checked) => toggleRowSelection(row, checked)"
              />
            </TableCell>
            
            <TableCell
              v-for="column in columns"
              :key="`${getRowKey(row, index)}-${String(column.key)}`"
              :class="getCellClasses(column)"
            >
              <component
                v-if="column.render"
                :is="column.render(row[column.key], row, index)"
              />
              <span v-else>{{ formatCellValue(row[column.key]) }}</span>
            </TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </div>

    <!-- Pagination -->
    <DataTablePagination
      v-if="pagination"
      :current-page="pagination.page"
      :page-size="pagination.pageSize"
      :total="pagination.total"
      @page-change="emit('page-change', $event)"
      @page-size-change="emit('page-size-change', $event)"
    />
  </div>
</template>

<script setup lang="ts" generic="T extends Record<string, any>">
import { computed, ref, watch } from 'vue'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import DataTablePagination from './DataTablePagination.vue'
import { RefreshCw, ChevronUp, ChevronDown, Loader2 } from 'lucide-vue-next'
import type { DataTableProps, DataTableColumn } from '@/types/components'

interface Props extends DataTableProps<T> {
  searchable?: boolean
  refreshable?: boolean
  rowKey?: keyof T | ((row: T, index: number) => string | number)
  clickableRows?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  searchable: true,
  refreshable: true,
  clickableRows: false,
})

interface Emits {
  'row-click': [row: T, index: number]
  'bulk-action': [action: string, rows: T[]]
  'refresh': []
  'page-change': [page: number]
  'page-size-change': [pageSize: number]
  'sort-change': [key: keyof T, direction: 'asc' | 'desc']
  'selection-change': [selectedRows: T[]]
}

const emit = defineEmits<Emits>()

const searchQuery = ref('')

// Computed properties
const totalColumns = computed(() => {
  let count = props.columns.length
  if (props.selection?.enabled) count++
  return count
})

const filteredData = computed(() => {
  if (!searchQuery.value) return props.data
  
  const query = searchQuery.value.toLowerCase()
  return props.data.filter(row => {
    return props.columns
      .filter(col => col.searchable !== false)
      .some(col => {
        const value = row[col.key]
        return String(value).toLowerCase().includes(query)
      })
  })
})

const sortedData = computed(() => {
  if (!props.sorting) return filteredData.value
  
  const { key, direction } = props.sorting
  return [...filteredData.value].sort((a, b) => {
    const aVal = a[key]
    const bVal = b[key]
    
    if (aVal < bVal) return direction === 'asc' ? -1 : 1
    if (aVal > bVal) return direction === 'asc' ? 1 : -1
    return 0
  })
})

const paginatedData = computed(() => {
  if (!props.pagination) return sortedData.value
  
  const { page, pageSize } = props.pagination
  const start = (page - 1) * pageSize
  const end = start + pageSize
  
  return sortedData.value.slice(start, end)
})

const isAllSelected = computed(() => {
  if (!props.selection?.enabled || filteredData.value.length === 0) return false
  return filteredData.value.every(row => isRowSelected(row))
})

// Methods
const getRowKey = (row: T, index: number): string | number => {
  if (typeof props.rowKey === 'function') {
    return props.rowKey(row, index)
  }
  if (props.rowKey) {
    return row[props.rowKey] as string | number
  }
  return index
}

const isRowSelected = (row: T): boolean => {
  if (!props.selection?.enabled) return false
  return props.selection.selectedRows.includes(row)
}

const toggleRowSelection = (row: T, checked: boolean) => {
  if (!props.selection?.enabled) return
  
  const currentSelection = [...props.selection.selectedRows]
  
  if (checked) {
    if (!currentSelection.includes(row)) {
      currentSelection.push(row)
    }
  } else {
    const index = currentSelection.indexOf(row)
    if (index > -1) {
      currentSelection.splice(index, 1)
    }
  }
  
  emit('selection-change', currentSelection)
}

const toggleSelectAll = (checked: boolean) => {
  if (!props.selection?.enabled) return
  
  const newSelection = checked ? [...filteredData.value] : []
  emit('selection-change', newSelection)
}

const handleSort = (column: DataTableColumn<T>) => {
  if (!column.sortable) return
  
  const currentSort = props.sorting
  let direction: 'asc' | 'desc' = 'asc'
  
  if (currentSort && currentSort.key === column.key) {
    direction = currentSort.direction === 'asc' ? 'desc' : 'asc'
  }
  
  emit('sort-change', column.key, direction)
}

const getHeaderClasses = (column: DataTableColumn<T>) => {
  const classes = ['select-none']
  
  if (column.sortable) {
    classes.push('cursor-pointer', 'hover:bg-muted/50')
  }
  
  if (column.align) {
    classes.push(`text-${column.align}`)
  }
  
  return classes.join(' ')
}

const getCellClasses = (column: DataTableColumn<T>) => {
  const classes: string[] = []
  
  if (column.align) {
    classes.push(`text-${column.align}`)
  }
  
  return classes.join(' ')
}

const getRowClasses = (row: T, index: number) => {
  const classes: string[] = []
  
  if (props.clickableRows) {
    classes.push('cursor-pointer', 'hover:bg-muted/50')
  }
  
  if (isRowSelected(row)) {
    classes.push('bg-muted/25')
  }
  
  return classes.join(' ')
}

const getSortIconClasses = (column: DataTableColumn<T>, direction: 'asc' | 'desc') => {
  const isActive = props.sorting?.key === column.key && props.sorting?.direction === direction
  return isActive ? 'text-foreground' : 'text-muted-foreground'
}

const formatCellValue = (value: any): string => {
  if (value === null || value === undefined) return '-'
  if (typeof value === 'boolean') return value ? 'Yes' : 'No'
  return String(value)
}
</script>
```

---

*Next: [Blocks and Advanced Patterns](./shadcn-vue-blocks-advanced-patterns.md) - Complex UI patterns, blocks usage, and production deployment strategies.*
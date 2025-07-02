# shadcn/vue Fundamentals and Setup

## Overview

This comprehensive guide covers the fundamental concepts, installation methods, and initial setup for shadcn/vue. Understanding these core principles will help you make the most of this powerful component collection and integrate it effectively into your Vue.js applications.

## 🎯 Core Philosophy

### Copy and Paste, Not a Library

shadcn/vue takes a unique approach that differs from traditional component libraries:

```typescript
// Traditional Component Library Approach
import { Button } from 'some-ui-library' // External dependency
// You're locked into their implementation

// shadcn/vue Approach
import { Button } from '@/components/ui/button' // Your code
// You own the code and can modify it freely
```

**Key Benefits:**
- **Full Control** - Modify components to fit your exact requirements
- **No External Dependencies** - Reduce bundle size and avoid version conflicts
- **Learning Opportunity** - Understand how modern Vue components work
- **Customization Freedom** - No limitations on styling or functionality

### Built on Modern Standards

shadcn/vue components are built using:
- **Radix Vue** - Unstyled, accessible component primitives
- **Tailwind CSS** - Utility-first CSS framework
- **class-variance-authority (CVA)** - Type-safe component variants
- **Vue 3 Composition API** - Modern reactive patterns

## 🚀 Installation Methods

### Method 1: CLI Installation (Recommended)

The shadcn/vue CLI provides the easiest setup experience:

```bash
# Initialize a new project with shadcn/vue
npx shadcn-vue@latest init
```

**Interactive Setup Process:**
```bash
✔ Would you like to use TypeScript (recommended)? … no / yes
✔ Which framework are you using? › Vite
✔ Which style would you like to use? › Default
✔ Which color would you like to use as base color? › Slate
✔ Where is your global CSS file? … src/style.css
✔ Would you like to use CSS variables for colors? … no / yes
✔ Where is your tailwind.config.js located? … tailwind.config.js
✔ Configure the import alias for components? … @/components
✔ Configure the import alias for utils? … @/lib/utils
```

**What the CLI Sets Up:**
- Tailwind CSS configuration
- Component directory structure
- Utility functions
- Base styles and CSS variables
- Import aliases

### Method 2: Vite Project Setup

For new Vite projects:

```bash
# Create Vite project
npm create vue@latest my-app
cd my-app

# Install dependencies
npm install

# Add shadcn/vue
npx shadcn-vue@latest init
```

**Manual Vite Configuration:**
```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

### Method 3: Nuxt.js Integration

For Nuxt applications:

```bash
# Create Nuxt project
npx nuxi@latest init my-nuxt-app
cd my-nuxt-app

# Install shadcn/vue
npx shadcn-vue@latest init
```

**Nuxt Configuration:**
```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@nuxtjs/tailwindcss'],
  css: ['~/assets/css/main.css'],
  components: {
    dirs: [
      {
        path: '~/components/ui',
        global: true
      }
    ]
  }
})
```

### Method 4: Astro Integration

For Astro projects:

```bash
# Create Astro project
npm create astro@latest my-astro-app
cd my-astro-app

# Add Vue integration
npx astro add vue tailwind

# Add shadcn/vue
npx shadcn-vue@latest init
```

**Astro Configuration:**
```typescript
// astro.config.mjs
import { defineConfig } from 'astro/config'
import vue from '@astrojs/vue'
import tailwind from '@astrojs/tailwind'

export default defineConfig({
  integrations: [vue(), tailwind()],
})
```

### Method 5: Laravel Integration

For Laravel + Inertia.js projects:

```bash
# Install Laravel dependencies
composer require laravel/breeze --dev
php artisan breeze:install vue

# Install shadcn/vue
npx shadcn-vue@latest init
```

**Laravel Vite Configuration:**
```javascript
// vite.config.js
import { defineConfig } from 'vite'
import laravel from 'laravel-vite-plugin'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
    plugins: [
        laravel({
            input: 'resources/js/app.js',
            refresh: true,
        }),
        vue({
            template: {
                transformAssetUrls: {
                    base: null,
                    includeAbsolute: false,
                },
            },
        }),
    ],
    resolve: {
        alias: {
            '@': path.resolve('resources/js'),
        },
    },
})
```

### Method 6: Manual Installation

For complete control over the setup:

```bash
# Install core dependencies
npm install @radix-vue/vue class-variance-authority clsx tailwind-merge lucide-vue-next

# Install Tailwind CSS
npm install -D tailwindcss postcss autoprefixer @tailwindcss/typography
npx tailwindcss init -p
```

**Manual File Structure:**
```
src/
├── components/
│   └── ui/           # shadcn/vue components go here
├── lib/
│   └── utils.ts      # Utility functions
├── styles/
│   └── globals.css   # Global styles and CSS variables
└── main.ts
```

## 🔧 CLI Tool Usage

### Adding Components

Add individual components to your project:

```bash
# Add a single component
npx shadcn-vue@latest add button

# Add multiple components
npx shadcn-vue@latest add button input label card

# Add all components (not recommended for production)
npx shadcn-vue@latest add --all
```

**What Happens When You Add a Component:**
1. Downloads the component files to `src/components/ui/`
2. Installs any required dependencies
3. Updates import statements if needed
4. Provides usage examples

### Component Organization

Components are organized by functionality:

```bash
# Add form-related components
npx shadcn-vue@latest add input label button form

# Add layout components
npx shadcn-vue@latest add card sheet dialog

# Add navigation components
npx shadcn-vue@latest add tabs menubar breadcrumb
```

### CLI Configuration

The CLI uses a configuration file for project settings:

```json
// components.json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/assets/index.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
```

## 📁 Project Structure

### Recommended Directory Layout

```
my-vue-app/
├── public/
├── src/
│   ├── components/
│   │   ├── ui/              # shadcn/vue components
│   │   │   ├── button.vue
│   │   │   ├── input.vue
│   │   │   ├── card.vue
│   │   │   └── ...
│   │   ├── forms/           # Custom form components
│   │   ├── layout/          # Layout components
│   │   └── pages/           # Page-specific components
│   ├── composables/         # Vue composables
│   ├── lib/
│   │   ├── utils.ts         # Utility functions
│   │   └── validators.ts    # Form validation
│   ├── stores/              # Pinia stores
│   ├── styles/
│   │   ├── globals.css      # Global styles
│   │   └── components.css   # Component overrides
│   ├── types/               # TypeScript types
│   ├── App.vue
│   └── main.ts
├── components.json          # shadcn/vue config
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

### Core Files Setup

**1. Global Styles (src/styles/globals.css):**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
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
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 84% 4.9%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 94.1%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

**2. Utility Functions (src/lib/utils.ts):**
```typescript
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  }).format(date)
}

export function slugify(str: string): string {
  return str
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
```

**3. Tailwind Configuration (tailwind.config.js):**
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx,vue}',
    './components/**/*.{ts,tsx,vue}',
    './app/**/*.{ts,tsx,vue}',
    './src/**/*.{ts,tsx,vue}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1400px',
      },
    },
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      keyframes: {
        'accordion-down': {
          from: { height: 0 },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: 0 },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
```

## 🎨 Basic Theming Setup

### CSS Variables Approach

shadcn/vue uses CSS variables for theming, allowing for:
- **Dynamic theme switching** - Change themes without rebuilding
- **Easy customization** - Modify colors without touching component code
- **Dark/light mode** - Automatic theme switching

**Custom Theme Example:**
```css
:root {
  /* Custom brand colors */
  --primary: 142 76% 36%;     /* Forest green */
  --secondary: 48 96% 89%;    /* Light yellow */
  --accent: 24 100% 50%;      /* Orange */
}

.theme-ocean {
  --primary: 200 100% 50%;    /* Ocean blue */
  --secondary: 187 85% 45%;   /* Teal */
  --accent: 340 75% 55%;      /* Pink accent */
}
```

### Component Variants

Use class-variance-authority for type-safe variants:

```typescript
// src/lib/variants.ts
import { cva } from 'class-variance-authority'

export const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'underline-offset-4 hover:underline text-primary',
      },
      size: {
        default: 'h-10 py-2 px-4',
        sm: 'h-9 px-3 rounded-md',
        lg: 'h-11 px-8 rounded-md',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)
```

## 🔄 Configuration Management

### Environment-Based Setup

```typescript
// src/config/index.ts
interface AppConfig {
  theme: {
    defaultMode: 'light' | 'dark' | 'system'
    enableAnimations: boolean
  }
  components: {
    defaultVariant: string
    iconLibrary: 'lucide' | 'heroicons'
  }
}

export const config: AppConfig = {
  theme: {
    defaultMode: import.meta.env.VITE_DEFAULT_THEME as 'light' | 'dark' | 'system' || 'system',
    enableAnimations: import.meta.env.VITE_ENABLE_ANIMATIONS !== 'false',
  },
  components: {
    defaultVariant: import.meta.env.VITE_DEFAULT_VARIANT || 'default',
    iconLibrary: import.meta.env.VITE_ICON_LIBRARY as 'lucide' | 'heroicons' || 'lucide',
  },
}
```

### Dynamic Component Loading

```typescript
// src/composables/useComponents.ts
import { ref, computed } from 'vue'

export function useComponents() {
  const loadedComponents = ref(new Set<string>())

  const loadComponent = async (name: string) => {
    if (loadedComponents.value.has(name)) return

    try {
      await import(`@/components/ui/${name}.vue`)
      loadedComponents.value.add(name)
    } catch (error) {
      console.warn(`Component ${name} not found`)
    }
  }

  const isLoaded = computed(() => (name: string) => 
    loadedComponents.value.has(name)
  )

  return {
    loadComponent,
    isLoaded,
  }
}
```

## 🚀 Getting Started Examples

### Basic Application Setup

```vue
<!-- src/App.vue -->
<template>
  <div class="min-h-screen bg-background">
    <header class="border-b">
      <div class="container flex h-16 items-center space-x-4">
        <h1 class="text-xl font-semibold">My App</h1>
        
        <nav class="flex space-x-2">
          <Button variant="ghost" size="sm">Home</Button>
          <Button variant="ghost" size="sm">About</Button>
          <Button variant="ghost" size="sm">Contact</Button>
        </nav>
        
        <div class="ml-auto">
          <Button @click="toggleTheme" variant="outline" size="icon">
            <Sun v-if="isDark" class="h-4 w-4" />
            <Moon v-else class="h-4 w-4" />
          </Button>
        </div>
      </div>
    </header>
    
    <main class="container py-8">
      <Card class="max-w-md mx-auto">
        <CardHeader>
          <CardTitle>Welcome to shadcn/vue</CardTitle>
          <CardDescription>
            Start building amazing interfaces with beautiful components.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="handleSubmit" class="space-y-4">
            <div>
              <Label for="name">Your Name</Label>
              <Input 
                id="name" 
                v-model="form.name" 
                placeholder="Enter your name"
              />
            </div>
            
            <Button type="submit" class="w-full">
              Get Started
            </Button>
          </form>
        </CardContent>
      </Card>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useDark, useToggle } from '@vueuse/core'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Sun, Moon } from 'lucide-vue-next'

const isDark = useDark()
const toggleTheme = useToggle(isDark)

const form = reactive({
  name: ''
})

const handleSubmit = () => {
  console.log('Form submitted:', form)
}
</script>
```

### Component Composition Pattern

```vue
<!-- src/components/UserProfile.vue -->
<template>
  <Card>
    <CardHeader class="pb-3">
      <div class="flex items-center space-x-4">
        <Avatar class="h-12 w-12">
          <AvatarImage :src="user.avatar" :alt="user.name" />
          <AvatarFallback>{{ initials }}</AvatarFallback>
        </Avatar>
        
        <div>
          <CardTitle class="text-lg">{{ user.name }}</CardTitle>
          <CardDescription>{{ user.email }}</CardDescription>
        </div>
        
        <div class="ml-auto">
          <Badge :variant="user.status === 'active' ? 'default' : 'secondary'">
            {{ user.status }}
          </Badge>
        </div>
      </div>
    </CardHeader>
    
    <CardContent>
      <div class="grid grid-cols-2 gap-4 text-sm">
        <div>
          <p class="text-muted-foreground">Joined</p>
          <p class="font-medium">{{ formatDate(user.joinedAt) }}</p>
        </div>
        <div>
          <p class="text-muted-foreground">Role</p>
          <p class="font-medium">{{ user.role }}</p>
        </div>
      </div>
      
      <div class="mt-4 flex space-x-2">
        <Button variant="outline" size="sm" @click="$emit('edit')">
          Edit Profile
        </Button>
        <Button variant="outline" size="sm" @click="$emit('message')">
          Send Message
        </Button>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

interface User {
  id: string
  name: string
  email: string
  avatar?: string
  status: 'active' | 'inactive'
  role: string
  joinedAt: Date
}

const props = defineProps<{
  user: User
}>()

defineEmits<{
  edit: []
  message: []
}>()

const initials = computed(() => 
  props.user.name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
)

const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    year: 'numeric'
  }).format(date)
}
</script>
```

## 🔍 Troubleshooting

### Common Issues and Solutions

**1. Components Not Found**
```bash
# Ensure component is added
npx shadcn-vue@latest add button

# Check import path
import { Button } from '@/components/ui/button' // ✅ Correct
import { Button } from '@/components/button'    // ❌ Wrong
```

**2. Styling Issues**
```css
/* Ensure Tailwind directives are included */
@tailwind base;     /* Required for CSS variables */
@tailwind components;
@tailwind utilities;

/* Check CSS variable definitions */
:root {
  --primary: 221.2 83.2% 53.3%; /* HSL values without hsl() */
}
```

**3. TypeScript Errors**
```typescript
// Ensure proper type imports
import type { VariantProps } from 'class-variance-authority'
import { buttonVariants } from '@/lib/variants'

type ButtonProps = VariantProps<typeof buttonVariants>
```

**4. Build Issues**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Rebuild Tailwind
npx tailwindcss -i ./src/styles/globals.css -o ./dist/output.css --watch
```

---

*Next: [Component Reference and Usage](./shadcn-vue-components-reference.md) - Complete catalog of all available components with detailed examples and usage patterns.*
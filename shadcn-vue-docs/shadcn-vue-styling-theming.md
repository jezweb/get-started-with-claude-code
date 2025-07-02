# shadcn/vue Styling and Theming

## Overview

This comprehensive guide covers styling and theming strategies for shadcn/vue components, including Tailwind CSS integration, custom theme creation, dark/light mode implementation, and advanced customization techniques. Learn how to create consistent, maintainable design systems that scale across your application.

## 🎨 Tailwind CSS Integration

### Core Configuration

shadcn/vue is built on Tailwind CSS with custom configuration for seamless integration:

```javascript
// tailwind.config.js
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
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Menlo', 'Monaco', 'monospace'],
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
        'fade-in': {
          from: { opacity: 0 },
          to: { opacity: 1 },
        },
        'slide-in-from-top': {
          from: { transform: 'translateY(-100%)' },
          to: { transform: 'translateY(0)' },
        },
        'slide-in-from-bottom': {
          from: { transform: 'translateY(100%)' },
          to: { transform: 'translateY(0)' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
        'fade-in': 'fade-in 0.15s ease-out',
        'slide-in-from-top': 'slide-in-from-top 0.3s ease-out',
        'slide-in-from-bottom': 'slide-in-from-bottom 0.3s ease-out',
      },
    },
  },
  plugins: [
    require('tailwindcss-animate'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
  ],
}
```

### Custom Utility Classes

Extend Tailwind with project-specific utilities:

```css
/* src/styles/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  /* Custom component classes */
  .btn-primary {
    @apply bg-primary text-primary-foreground hover:bg-primary/90 px-4 py-2 rounded-md font-medium transition-colors;
  }
  
  .card-elevated {
    @apply bg-card text-card-foreground shadow-lg border rounded-lg;
  }
  
  .input-field {
    @apply flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50;
  }
}

@layer utilities {
  /* Custom utility classes */
  .text-balance {
    text-wrap: balance;
  }
  
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
  
  .gradient-text {
    @apply bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent;
  }
}
```

## 🌈 CSS Variables and Theme System

### Base Theme Variables

shadcn/vue uses HSL color values stored in CSS variables for dynamic theming:

```css
/* src/styles/globals.css */
@layer base {
  :root {
    /* Light theme colors */
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
    /* Dark theme colors */
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
```

### Custom Theme Creation

Create branded themes by extending the base system:

```css
/* Custom brand themes */
.theme-ocean {
  --primary: 199 89% 48%;        /* Ocean blue */
  --primary-foreground: 0 0% 100%;
  --secondary: 199 89% 90%;      /* Light ocean */
  --secondary-foreground: 199 89% 20%;
  --accent: 43 74% 66%;          /* Sandy yellow */
  --accent-foreground: 43 74% 20%;
  --destructive: 0 84% 60%;      /* Coral red */
  --ring: 199 89% 48%;
}

.theme-forest {
  --primary: 142 76% 36%;        /* Forest green */
  --primary-foreground: 0 0% 100%;
  --secondary: 142 76% 90%;      /* Light green */
  --secondary-foreground: 142 76% 20%;
  --accent: 48 96% 89%;          /* Light yellow */
  --accent-foreground: 48 96% 20%;
  --destructive: 0 84% 60%;
  --ring: 142 76% 36%;
}

.theme-sunset {
  --primary: 14 100% 57%;        /* Orange */
  --primary-foreground: 0 0% 100%;
  --secondary: 14 100% 90%;      /* Light orange */
  --secondary-foreground: 14 100% 20%;
  --accent: 340 75% 55%;         /* Pink */
  --accent-foreground: 340 75% 20%;
  --destructive: 0 84% 60%;
  --ring: 14 100% 57%;
}
```

### Dynamic Theme Switching

Implement theme switching with Vue composables:

```typescript
// src/composables/useTheme.ts
import { ref, computed, watch } from 'vue'

type Theme = 'light' | 'dark' | 'system'
type CustomTheme = 'default' | 'ocean' | 'forest' | 'sunset'

export function useTheme() {
  const theme = ref<Theme>('system')
  const customTheme = ref<CustomTheme>('default')

  // Get system preference
  const getSystemTheme = (): 'light' | 'dark' => {
    if (typeof window === 'undefined') return 'light'
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }

  // Computed actual theme
  const actualTheme = computed(() => {
    return theme.value === 'system' ? getSystemTheme() : theme.value
  })

  // Apply theme to document
  const applyTheme = () => {
    const root = document.documentElement
    
    // Remove all theme classes
    root.classList.remove('light', 'dark', 'theme-ocean', 'theme-forest', 'theme-sunset')
    
    // Add current theme class
    root.classList.add(actualTheme.value)
    
    // Add custom theme class
    if (customTheme.value !== 'default') {
      root.classList.add(`theme-${customTheme.value}`)
    }
  }

  // Watch for changes
  watch([theme, customTheme], applyTheme, { immediate: true })

  // Listen for system theme changes
  if (typeof window !== 'undefined') {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (theme.value === 'system') {
        applyTheme()
      }
    })
  }

  // Set theme functions
  const setTheme = (newTheme: Theme) => {
    theme.value = newTheme
    localStorage.setItem('theme', newTheme)
  }

  const setCustomTheme = (newCustomTheme: CustomTheme) => {
    customTheme.value = newCustomTheme
    localStorage.setItem('custom-theme', newCustomTheme)
  }

  const toggleTheme = () => {
    setTheme(actualTheme.value === 'dark' ? 'light' : 'dark')
  }

  // Initialize from localStorage
  if (typeof window !== 'undefined') {
    const savedTheme = localStorage.getItem('theme') as Theme
    const savedCustomTheme = localStorage.getItem('custom-theme') as CustomTheme
    
    if (savedTheme) theme.value = savedTheme
    if (savedCustomTheme) customTheme.value = savedCustomTheme
  }

  return {
    theme: readonly(theme),
    customTheme: readonly(customTheme),
    actualTheme,
    setTheme,
    setCustomTheme,
    toggleTheme,
  }
}
```

## 🌙 Dark/Light Mode Implementation

### Theme Toggle Component

Create a comprehensive theme switcher:

```vue
<!-- src/components/ThemeToggle.vue -->
<template>
  <DropdownMenu>
    <DropdownMenuTrigger as-child>
      <Button variant="outline" size="icon">
        <Sun class="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
        <Moon class="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
        <span class="sr-only">Toggle theme</span>
      </Button>
    </DropdownMenuTrigger>
    
    <DropdownMenuContent align="end">
      <DropdownMenuItem @click="setTheme('light')">
        <Sun class="mr-2 h-4 w-4" />
        Light
      </DropdownMenuItem>
      <DropdownMenuItem @click="setTheme('dark')">
        <Moon class="mr-2 h-4 w-4" />
        Dark
      </DropdownMenuItem>
      <DropdownMenuItem @click="setTheme('system')">
        <Monitor class="mr-2 h-4 w-4" />
        System
      </DropdownMenuItem>
      
      <DropdownMenuSeparator />
      
      <DropdownMenuLabel>Custom Themes</DropdownMenuLabel>
      <DropdownMenuItem @click="setCustomTheme('ocean')">
        <Waves class="mr-2 h-4 w-4" />
        Ocean
      </DropdownMenuItem>
      <DropdownMenuItem @click="setCustomTheme('forest')">
        <Trees class="mr-2 h-4 w-4" />
        Forest
      </DropdownMenuItem>
      <DropdownMenuItem @click="setCustomTheme('sunset')">
        <Sunset class="mr-2 h-4 w-4" />
        Sunset
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
</template>

<script setup lang="ts">
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { useTheme } from '@/composables/useTheme'
import { Sun, Moon, Monitor, Waves, Trees, Sunset } from 'lucide-vue-next'

const { setTheme, setCustomTheme } = useTheme()
</script>
```

### Theme-Aware Components

Create components that adapt to theme changes:

```vue
<!-- src/components/ThemedCard.vue -->
<template>
  <Card :class="cardClasses">
    <CardHeader>
      <CardTitle :class="titleClasses">
        {{ title }}
      </CardTitle>
      <CardDescription>
        {{ description }}
      </CardDescription>
    </CardHeader>
    
    <CardContent>
      <slot />
    </CardContent>
    
    <CardFooter v-if="$slots.footer">
      <slot name="footer" />
    </CardFooter>
  </Card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { useTheme } from '@/composables/useTheme'

interface Props {
  title: string
  description?: string
  variant?: 'default' | 'elevated' | 'bordered' | 'glass'
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'default'
})

const { actualTheme } = useTheme()

const cardClasses = computed(() => {
  const base = 'transition-all duration-200'
  
  switch (props.variant) {
    case 'elevated':
      return `${base} shadow-lg hover:shadow-xl dark:shadow-2xl`
    case 'bordered':
      return `${base} border-2 hover:border-primary/50`
    case 'glass':
      return `${base} backdrop-blur-md bg-background/80 border-border/50`
    default:
      return base
  }
})

const titleClasses = computed(() => {
  return actualTheme.value === 'dark' 
    ? 'text-foreground font-semibold' 
    : 'text-foreground font-medium'
})
</script>
```

## 🎯 Component Customization Strategies

### Class Variance Authority (CVA) Integration

Use CVA for type-safe component variants:

```typescript
// src/lib/component-variants.ts
import { cva, type VariantProps } from 'class-variance-authority'

export const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
        gradient: 'bg-gradient-to-r from-primary to-accent text-white hover:from-primary/90 hover:to-accent/90',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'h-10 w-10',
        xl: 'h-12 rounded-lg px-10 text-base',
      },
      loading: {
        true: 'cursor-not-allowed',
        false: '',
      },
    },
    compoundVariants: [
      {
        variant: 'ghost',
        size: 'icon',
        class: 'hover:bg-accent/50',
      },
      {
        variant: 'outline',
        size: 'sm',
        class: 'border-2',
      },
    ],
    defaultVariants: {
      variant: 'default',
      size: 'default',
      loading: false,
    },
  }
)

export const cardVariants = cva(
  'rounded-lg border bg-card text-card-foreground shadow-sm',
  {
    variants: {
      variant: {
        default: '',
        elevated: 'shadow-lg',
        flat: 'shadow-none',
        outline: 'border-2',
        glass: 'backdrop-blur-md bg-card/80',
      },
      padding: {
        none: 'p-0',
        sm: 'p-4',
        md: 'p-6',
        lg: 'p-8',
      },
      hover: {
        none: '',
        lift: 'hover:shadow-md transition-shadow',
        scale: 'hover:scale-[1.02] transition-transform',
        glow: 'hover:shadow-lg hover:shadow-primary/25 transition-shadow',
      },
    },
    defaultVariants: {
      variant: 'default',
      padding: 'md',
      hover: 'none',
    },
  }
)

export type ButtonVariants = VariantProps<typeof buttonVariants>
export type CardVariants = VariantProps<typeof cardVariants>
```

### Enhanced Button Component

Create an extended button with more features:

```vue
<!-- src/components/ui/enhanced-button/EnhancedButton.vue -->
<template>
  <button
    :class="cn(buttonVariants({ variant, size, loading }), className)"
    :disabled="disabled || loading"
    v-bind="$attrs"
  >
    <Loader2 v-if="loading" class="mr-2 h-4 w-4 animate-spin" />
    <component :is="iconLeft" v-else-if="iconLeft" class="mr-2 h-4 w-4" />
    
    <slot />
    
    <component :is="iconRight" v-if="iconRight && !loading" class="ml-2 h-4 w-4" />
  </button>
</template>

<script setup lang="ts">
import { type Component } from 'vue'
import { cn } from '@/lib/utils'
import { buttonVariants, type ButtonVariants } from '@/lib/component-variants'
import { Loader2 } from 'lucide-vue-next'

interface Props extends ButtonVariants {
  disabled?: boolean
  loading?: boolean
  iconLeft?: Component
  iconRight?: Component
  className?: string
}

withDefaults(defineProps<Props>(), {
  disabled: false,
  loading: false,
})

defineOptions({
  inheritAttrs: false,
})
</script>
```

### Advanced Input Styling

Create styled input components with validation states:

```vue
<!-- src/components/ui/enhanced-input/EnhancedInput.vue -->
<template>
  <div class="space-y-2">
    <Label v-if="label" :for="id" :class="labelClasses">
      {{ label }}
      <span v-if="required" class="text-destructive">*</span>
    </Label>
    
    <div class="relative">
      <component 
        :is="iconLeft" 
        v-if="iconLeft" 
        class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" 
      />
      
      <input
        :id="id"
        :class="inputClasses"
        :value="modelValue"
        :disabled="disabled"
        :readonly="readonly"
        :placeholder="placeholder"
        @input="handleInput"
        @blur="handleBlur"
        @focus="handleFocus"
        v-bind="$attrs"
      />
      
      <component 
        :is="iconRight" 
        v-if="iconRight" 
        class="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" 
      />
      
      <div v-if="loading" class="absolute right-3 top-1/2 -translate-y-1/2">
        <Loader2 class="h-4 w-4 animate-spin text-muted-foreground" />
      </div>
    </div>
    
    <p v-if="hint && !error" class="text-sm text-muted-foreground">
      {{ hint }}
    </p>
    
    <p v-if="error" class="text-sm text-destructive">
      {{ error }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { computed, type Component } from 'vue'
import { cn } from '@/lib/utils'
import { Label } from '@/components/ui/label'
import { Loader2 } from 'lucide-vue-next'

interface Props {
  id?: string
  label?: string
  modelValue?: string
  placeholder?: string
  disabled?: boolean
  readonly?: boolean
  loading?: boolean
  required?: boolean
  error?: string
  hint?: string
  iconLeft?: Component
  iconRight?: Component
  variant?: 'default' | 'ghost' | 'filled'
  size?: 'sm' | 'default' | 'lg'
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'default',
  size: 'default',
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  'blur': [event: FocusEvent]
  'focus': [event: FocusEvent]
}>()

const inputClasses = computed(() => {
  const base = 'flex w-full rounded-md border text-sm ring-offset-background transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50'
  
  const sizeClasses = {
    sm: 'h-8 px-3 py-1',
    default: 'h-10 px-3 py-2',
    lg: 'h-12 px-4 py-3',
  }
  
  const variantClasses = {
    default: 'border-input bg-background',
    ghost: 'border-transparent bg-transparent hover:bg-accent/50',
    filled: 'border-input bg-muted',
  }
  
  const stateClasses = props.error 
    ? 'border-destructive focus-visible:ring-destructive' 
    : 'border-input'
    
  const paddingClasses = cn(
    props.iconLeft && 'pl-10',
    props.iconRight && 'pr-10',
    props.loading && 'pr-10'
  )
  
  return cn(
    base,
    sizeClasses[props.size],
    variantClasses[props.variant],
    stateClasses,
    paddingClasses
  )
})

const labelClasses = computed(() => cn(
  'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
  props.error && 'text-destructive'
))

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}

const handleBlur = (event: FocusEvent) => {
  emit('blur', event)
}

const handleFocus = (event: FocusEvent) => {
  emit('focus', event)
}

defineOptions({
  inheritAttrs: false,
})
</script>
```

## 🎨 Advanced Styling Patterns

### Responsive Design

Implement responsive design patterns with Tailwind:

```vue
<template>
  <!-- Responsive Grid Layout -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6">
    <Card 
      v-for="item in items" 
      :key="item.id"
      class="h-full flex flex-col"
    >
      <CardHeader class="flex-shrink-0">
        <CardTitle class="text-base sm:text-lg">{{ item.title }}</CardTitle>
      </CardHeader>
      <CardContent class="flex-grow">
        <p class="text-sm sm:text-base text-muted-foreground">{{ item.description }}</p>
      </CardContent>
      <CardFooter class="flex-shrink-0">
        <Button size="sm" class="w-full sm:w-auto">
          {{ item.action }}
        </Button>
      </CardFooter>
    </Card>
  </div>

  <!-- Responsive Navigation -->
  <nav class="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4">
    <Button variant="ghost" size="sm" class="w-full sm:w-auto justify-start sm:justify-center">
      Home
    </Button>
    <Button variant="ghost" size="sm" class="w-full sm:w-auto justify-start sm:justify-center">
      Products
    </Button>
    <Button variant="ghost" size="sm" class="w-full sm:w-auto justify-start sm:justify-center">
      About
    </Button>
  </nav>
</template>
```

### Animation and Transitions

Add smooth animations and transitions:

```css
/* Custom animations */
@keyframes slideInFromLeft {
  from {
    transform: translateX(-100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes bounceIn {
  0%, 20%, 40%, 60%, 80% {
    transform: translateY(0);
  }
  10% {
    transform: translateY(-10px);
  }
  30% {
    transform: translateY(-5px);
  }
  50% {
    transform: translateY(-3px);
  }
  70% {
    transform: translateY(-1px);
  }
}

@layer utilities {
  .animate-slide-in-left {
    animation: slideInFromLeft 0.3s ease-out;
  }
  
  .animate-bounce-in {
    animation: bounceIn 0.6s ease-out;
  }
  
  .transition-all-300 {
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  }
}
```

```vue
<template>
  <!-- Animated List Items -->
  <div class="space-y-2">
    <Card 
      v-for="(item, index) in items" 
      :key="item.id"
      class="animate-slide-in-left transition-all-300 hover:scale-[1.02] hover:shadow-lg"
      :style="{ animationDelay: `${index * 100}ms` }"
    >
      <CardContent class="p-4">
        <h3 class="font-semibold">{{ item.title }}</h3>
        <p class="text-sm text-muted-foreground">{{ item.description }}</p>
      </CardContent>
    </Card>
  </div>

  <!-- Hover Effects -->
  <div class="grid grid-cols-2 gap-4">
    <Button class="group transition-all duration-300 hover:shadow-lg">
      <span class="group-hover:scale-110 transition-transform duration-200">
        Click me
      </span>
    </Button>
    
    <Card class="relative overflow-hidden group cursor-pointer">
      <div class="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
      <CardContent class="relative z-10 p-4">
        <p class="group-hover:text-primary transition-colors duration-200">
          Hover for effect
        </p>
      </CardContent>
    </Card>
  </div>
</template>
```

### Focus and Accessibility Styles

Ensure proper focus management and accessibility:

```css
@layer utilities {
  /* Enhanced focus styles */
  .focus-ring {
    @apply focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background;
  }
  
  .focus-ring-destructive {
    @apply focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive focus-visible:ring-offset-2 focus-visible:ring-offset-background;
  }
  
  /* High contrast mode support */
  @media (prefers-contrast: high) {
    .contrast-border {
      border-width: 2px;
    }
    
    .contrast-text {
      font-weight: 600;
    }
  }
  
  /* Reduced motion support */
  @media (prefers-reduced-motion: reduce) {
    .motion-safe-animate {
      animation: none;
    }
    
    .motion-safe-transition {
      transition: none;
    }
  }
}
```

### Print Styles

Add print-specific styling:

```css
@layer utilities {
  /* Print styles */
  @media print {
    .print-hidden {
      display: none !important;
    }
    
    .print-visible {
      display: block !important;
    }
    
    .print-break-after {
      page-break-after: always;
    }
    
    .print-break-before {
      page-break-before: always;
    }
    
    .print-break-inside-avoid {
      page-break-inside: avoid;
    }
  }
}
```

## 🔧 Performance Optimization

### CSS Purging and Optimization

Optimize CSS delivery for production:

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{vue,js,ts,jsx,tsx}',
    './components/**/*.{vue,js,ts,jsx,tsx}',
  ],
  safelist: [
    // Preserve dynamic classes
    'bg-red-500',
    'bg-green-500',
    'bg-blue-500',
    {
      pattern: /^(bg|text|border)-(red|green|blue|yellow|purple)-(100|200|300|400|500|600|700|800|900)$/,
    },
  ],
  theme: {
    // Your theme config
  },
  plugins: [
    require('tailwindcss-animate'),
  ],
}
```

### Critical CSS Loading

Implement critical CSS loading strategy:

```vue
<!-- src/App.vue -->
<template>
  <div id="app">
    <router-view />
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'

onMounted(() => {
  // Load non-critical CSS after initial render
  const link = document.createElement('link')
  link.rel = 'stylesheet'
  link.href = '/css/non-critical.css'
  document.head.appendChild(link)
})
</script>

<style>
/* Critical CSS inlined here */
.critical-above-fold {
  /* Styles for above-the-fold content */
}
</style>
```

---

*Next: [Framework Integration](./shadcn-vue-framework-integration.md) - Vue 3, Nuxt, Vite integration patterns and best practices.*
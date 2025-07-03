# Tailwind CSS Patterns & Best Practices

Comprehensive guide to building production-ready applications with Tailwind CSS, including advanced patterns, customization, and performance optimization.

## 🎯 What is Tailwind CSS?

Tailwind CSS is a utility-first CSS framework for rapidly building custom user interfaces:
- **Utility-First** - Build complex components from simple utility classes
- **Responsive** - Built-in responsive design modifiers
- **Customizable** - Completely customizable design system
- **Performance** - Purge unused CSS for tiny production builds
- **Developer Experience** - IntelliSense, JIT mode, and excellent tooling

## 🚀 Quick Start

### Installation with PostCSS (Recommended)
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Vite + Tailwind Setup
```bash
npm create vite@latest my-tailwind-app
cd my-tailwind-app
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Configuration Files
```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx,vue}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          900: '#1e3a8a',
        },
        brand: {
          light: '#7c3aed',
          DEFAULT: '#5b21b6',
          dark: '#4c1d95',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
}
```

```css
/* src/styles/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    @apply scroll-smooth;
  }
  
  body {
    @apply bg-gray-50 text-gray-900 font-sans;
  }
}

@layer components {
  .btn {
    @apply px-4 py-2 rounded-lg font-medium transition-colors duration-200;
  }
  
  .btn-primary {
    @apply btn bg-primary-600 text-white hover:bg-primary-700;
  }
  
  .btn-secondary {
    @apply btn bg-gray-200 text-gray-900 hover:bg-gray-300;
  }
}
```

## 🎨 Design System with Tailwind

### Color Palette Organization
```javascript
// tailwind.config.js - Extended color system
module.exports = {
  theme: {
    extend: {
      colors: {
        // Primary brand colors
        brand: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',  // Primary
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        },
        
        // Semantic colors
        success: {
          50: '#f0fdf4',
          500: '#22c55e',
          600: '#16a34a',
        },
        warning: {
          50: '#fffbeb',
          500: '#f59e0b',
          600: '#d97706',
        },
        error: {
          50: '#fef2f2',
          500: '#ef4444',
          600: '#dc2626',
        },
        
        // Neutral grays
        neutral: {
          0: '#ffffff',
          50: '#fafafa',
          100: '#f5f5f5',
          200: '#e5e5e5',
          300: '#d4d4d4',
          400: '#a3a3a3',
          500: '#737373',
          600: '#525252',
          700: '#404040',
          800: '#262626',
          900: '#171717',
          950: '#0a0a0a',
        }
      }
    }
  }
}
```

### Typography Scale
```javascript
// tailwind.config.js - Typography system
module.exports = {
  theme: {
    extend: {
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1' }],
        '6xl': ['3.75rem', { lineHeight: '1' }],
      },
      fontWeight: {
        thin: '100',
        light: '300',
        normal: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
        extrabold: '800',
        black: '900',
      }
    }
  }
}
```

### Spacing & Sizing
```javascript
// tailwind.config.js - Custom spacing
module.exports = {
  theme: {
    extend: {
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
        '144': '36rem',
      },
      maxWidth: {
        '8xl': '88rem',
        '9xl': '96rem',
      },
      minHeight: {
        '16': '4rem',
        '20': '5rem',
        '24': '6rem',
      }
    }
  }
}
```

## 🧩 Component Patterns

### Card Components
```html
<!-- Basic Card -->
<div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">Card Title</h3>
  <p class="text-gray-600">Card content goes here...</p>
</div>

<!-- Featured Card -->
<div class="bg-white rounded-lg shadow-lg border-2 border-brand-500 p-6 relative overflow-hidden">
  <div class="absolute top-0 right-0 bg-brand-500 text-white px-3 py-1 text-xs font-medium">
    Featured
  </div>
  <h3 class="text-lg font-semibold text-gray-900 mb-2">Featured Content</h3>
  <p class="text-gray-600">This card has special styling...</p>
</div>

<!-- Card with Image -->
<div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
  <img src="image.jpg" alt="Card image" class="w-full h-48 object-cover">
  <div class="p-6">
    <h3 class="text-lg font-semibold text-gray-900 mb-2">Image Card</h3>
    <p class="text-gray-600">Card with header image...</p>
    <div class="mt-4 flex justify-between items-center">
      <span class="text-sm text-gray-500">2 days ago</span>
      <button class="btn-primary">Read More</button>
    </div>
  </div>
</div>
```

### Button System
```html
<!-- Primary Buttons -->
<button class="btn-primary">Primary Action</button>
<button class="btn-primary btn-sm">Small Primary</button>
<button class="btn-primary btn-lg">Large Primary</button>

<!-- Secondary Buttons -->
<button class="btn-secondary">Secondary Action</button>
<button class="btn-outline">Outline Button</button>
<button class="btn-ghost">Ghost Button</button>

<!-- Icon Buttons -->
<button class="btn-primary inline-flex items-center">
  <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
    <path d="M10 12l-4-4h8l-4 4z"/>
  </svg>
  With Icon
</button>

<!-- Loading State -->
<button class="btn-primary" disabled>
  <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
  </svg>
  Loading...
</button>
```

### Form Components
```html
<!-- Form Group -->
<div class="space-y-4">
  <!-- Input with Label -->
  <div>
    <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
      Email Address
    </label>
    <input 
      type="email" 
      id="email"
      class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-brand-500 focus:border-brand-500"
      placeholder="you@example.com"
    >
  </div>

  <!-- Textarea -->
  <div>
    <label for="message" class="block text-sm font-medium text-gray-700 mb-1">
      Message
    </label>
    <textarea 
      id="message"
      rows="4"
      class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-brand-500 focus:border-brand-500"
      placeholder="Your message..."
    ></textarea>
  </div>

  <!-- Select -->
  <div>
    <label for="category" class="block text-sm font-medium text-gray-700 mb-1">
      Category
    </label>
    <select 
      id="category"
      class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-brand-500 focus:border-brand-500"
    >
      <option>Choose a category</option>
      <option>General</option>
      <option>Support</option>
    </select>
  </div>

  <!-- Checkbox -->
  <div class="flex items-center">
    <input 
      type="checkbox" 
      id="terms"
      class="h-4 w-4 text-brand-600 focus:ring-brand-500 border-gray-300 rounded"
    >
    <label for="terms" class="ml-2 block text-sm text-gray-700">
      I agree to the <a href="#" class="text-brand-600 hover:text-brand-500">Terms and Conditions</a>
    </label>
  </div>
</div>
```

### Navigation Components
```html
<!-- Horizontal Navigation -->
<nav class="bg-white shadow-sm border-b border-gray-200">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex justify-between h-16">
      <div class="flex items-center">
        <img src="logo.png" alt="Logo" class="h-8 w-auto">
        <div class="hidden md:flex ml-10 space-x-8">
          <a href="#" class="text-gray-900 hover:text-brand-600 px-3 py-2 text-sm font-medium">
            Home
          </a>
          <a href="#" class="text-gray-500 hover:text-brand-600 px-3 py-2 text-sm font-medium">
            About
          </a>
          <a href="#" class="text-gray-500 hover:text-brand-600 px-3 py-2 text-sm font-medium">
            Services
          </a>
        </div>
      </div>
      <div class="flex items-center space-x-4">
        <button class="btn-secondary">Login</button>
        <button class="btn-primary">Sign Up</button>
      </div>
    </div>
  </div>
</nav>

<!-- Breadcrumb -->
<nav class="flex" aria-label="Breadcrumb">
  <ol class="flex items-center space-x-2">
    <li>
      <a href="#" class="text-gray-500 hover:text-gray-700">Home</a>
    </li>
    <li class="flex items-center">
      <svg class="flex-shrink-0 h-4 w-4 text-gray-400 mx-2" fill="currentColor" viewBox="0 0 20 20">
        <path d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"/>
      </svg>
      <a href="#" class="text-gray-500 hover:text-gray-700">Products</a>
    </li>
    <li class="flex items-center">
      <svg class="flex-shrink-0 h-4 w-4 text-gray-400 mx-2" fill="currentColor" viewBox="0 0 20 20">
        <path d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"/>
      </svg>
      <span class="text-gray-900 font-medium">Current Page</span>
    </li>
  </ol>
</nav>
```

## 📱 Responsive Design Patterns

### Mobile-First Approach
```html
<!-- Responsive Grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div class="bg-white p-6 rounded-lg shadow-sm">Column 1</div>
  <div class="bg-white p-6 rounded-lg shadow-sm">Column 2</div>
  <div class="bg-white p-6 rounded-lg shadow-sm">Column 3</div>
</div>

<!-- Responsive Typography -->
<h1 class="text-2xl md:text-4xl lg:text-6xl font-bold text-gray-900">
  Responsive Heading
</h1>
<p class="text-sm md:text-base lg:text-lg text-gray-600 mt-4">
  Responsive paragraph text that scales appropriately.
</p>

<!-- Responsive Layout -->
<div class="flex flex-col lg:flex-row gap-8">
  <!-- Sidebar -->
  <aside class="w-full lg:w-64 bg-gray-50 p-6 rounded-lg">
    <h3 class="font-semibold mb-4">Sidebar</h3>
    <nav class="space-y-2">
      <a href="#" class="block p-2 text-gray-700 hover:bg-gray-200 rounded">Link 1</a>
      <a href="#" class="block p-2 text-gray-700 hover:bg-gray-200 rounded">Link 2</a>
    </nav>
  </aside>
  
  <!-- Main Content -->
  <main class="flex-1">
    <div class="bg-white p-6 rounded-lg shadow-sm">
      <h2 class="text-xl font-semibold mb-4">Main Content</h2>
      <p class="text-gray-600">Content area that adapts to available space.</p>
    </div>
  </main>
</div>

<!-- Hide/Show Elements -->
<div class="block md:hidden">
  <!-- Mobile only -->
  <button class="w-full btn-primary">Mobile Menu</button>
</div>

<div class="hidden md:block">
  <!-- Desktop only -->
  <nav class="flex space-x-6">
    <a href="#">Desktop Nav Link</a>
  </nav>
</div>
```

### Container Queries (Experimental)
```html
<!-- Component that adapts based on its container size -->
<div class="@container">
  <div class="@lg:grid @lg:grid-cols-2 @lg:gap-4">
    <div class="bg-white p-4 rounded">Adapts to container</div>
    <div class="bg-white p-4 rounded">Not viewport</div>
  </div>
</div>
```

## 🎭 Animation & Transitions

### Custom Animations
```javascript
// tailwind.config.js - Custom animations
module.exports = {
  theme: {
    extend: {
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'fade-out': 'fadeOut 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'slide-left': 'slideLeft 0.3s ease-out',
        'slide-right': 'slideRight 0.3s ease-out',
        'bounce-in': 'bounceIn 0.6s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeOut: {
          '0%': { opacity: '1' },
          '100%': { opacity: '0' },
        },
        slideUp: {
          '0%': { transform: 'translateY(100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideLeft: {
          '0%': { transform: 'translateX(100%)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' },
        },
        slideRight: {
          '0%': { transform: 'translateX(-100%)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' },
        },
        bounceIn: {
          '0%': { transform: 'scale(0.3)', opacity: '0' },
          '50%': { transform: 'scale(1.05)' },
          '70%': { transform: 'scale(0.9)' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      }
    }
  }
}
```

### Transition Patterns
```html
<!-- Hover Transitions -->
<div class="bg-white p-6 rounded-lg shadow-sm hover:shadow-lg transition-shadow duration-300">
  Card with shadow transition
</div>

<button class="bg-brand-500 text-white px-4 py-2 rounded-lg hover:bg-brand-600 transform hover:scale-105 transition-all duration-200">
  Button with scale effect
</button>

<!-- Loading States -->
<div class="bg-gray-200 animate-pulse rounded-lg h-48">
  <div class="space-y-4 p-6">
    <div class="h-4 bg-gray-300 rounded w-3/4"></div>
    <div class="h-4 bg-gray-300 rounded w-1/2"></div>
    <div class="h-4 bg-gray-300 rounded w-5/6"></div>
  </div>
</div>

<!-- Fade In Animation -->
<div class="animate-fade-in bg-white p-6 rounded-lg shadow-sm">
  Content that fades in
</div>

<!-- Slide Up Animation -->
<div class="animate-slide-up bg-white p-6 rounded-lg shadow-sm">
  Content that slides up
</div>
```

## 🚀 Performance Optimization

### PurgeCSS Configuration
```javascript
// tailwind.config.js - Production optimization
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx,vue}",
    "./components/**/*.{js,ts,jsx,tsx,vue}",
  ],
  safelist: [
    'bg-red-500',
    'text-3xl',
    'lg:text-4xl',
    // Add classes that are generated dynamically
  ],
  theme: {
    // Your theme config
  },
  plugins: [],
}
```

### JIT Mode Benefits
```html
<!-- Arbitrary values (JIT only) -->
<div class="top-[117px] left-[344px]">
  Precise positioning
</div>

<div class="bg-[#1da1f2] text-[14px]">
  Custom colors and sizes
</div>

<div class="grid-cols-[1fr_500px_2fr]">
  Custom grid template
</div>

<!-- Dynamic class generation -->
<div class="rotate-[17deg] skew-y-[8deg]">
  Custom transforms
</div>
```

### Bundle Size Optimization
```javascript
// vite.config.js - Tailwind with Vite
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  css: {
    postcss: {
      plugins: [
        require('tailwindcss'),
        require('autoprefixer'),
      ],
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },
})
```

## 🔧 Advanced Patterns

### Dark Mode Support
```javascript
// tailwind.config.js - Dark mode configuration
module.exports = {
  darkMode: 'class', // or 'media' for system preference
  theme: {
    extend: {
      colors: {
        gray: {
          50: '#fafafa',
          900: '#0a0a0a',
          950: '#050505',
        }
      }
    }
  }
}
```

```html
<!-- Dark mode classes -->
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
    Light and Dark Mode
  </h1>
  <p class="text-gray-600 dark:text-gray-300">
    Content that adapts to theme
  </p>
  <button class="bg-blue-500 hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-700 text-white px-4 py-2 rounded">
    Theme-aware button
  </button>
</div>
```

```javascript
// Dark mode toggle
function toggleDarkMode() {
  document.documentElement.classList.toggle('dark')
  localStorage.setItem('darkMode', 
    document.documentElement.classList.contains('dark')
  )
}

// Initialize dark mode
if (localStorage.getItem('darkMode') === 'true' || 
    (!localStorage.getItem('darkMode') && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
  document.documentElement.classList.add('dark')
}
```

### Component Variants with CVA
```javascript
// utils/variants.js - Class Variance Authority pattern
import { cva } from 'class-variance-authority'

export const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none',
  {
    variants: {
      variant: {
        default: 'bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500',
        secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
        outline: 'border border-gray-300 bg-transparent text-gray-700 hover:bg-gray-50 focus:ring-gray-500',
        ghost: 'bg-transparent text-gray-700 hover:bg-gray-100 focus:ring-gray-500',
        destructive: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        default: 'h-10 px-4 text-base',
        lg: 'h-12 px-6 text-lg',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

// Usage in React
export function Button({ variant, size, className, ...props }) {
  return (
    <button
      className={buttonVariants({ variant, size, className })}
      {...props}
    />
  )
}
```

### Plugin Development
```javascript
// Custom Tailwind plugin
const plugin = require('tailwindcss/plugin')

module.exports = {
  plugins: [
    plugin(function({ addUtilities, theme }) {
      const newUtilities = {
        '.text-shadow': {
          textShadow: '2px 2px 4px rgba(0, 0, 0, 0.1)',
        },
        '.text-shadow-md': {
          textShadow: '4px 4px 8px rgba(0, 0, 0, 0.12)',
        },
        '.text-shadow-lg': {
          textShadow: '8px 8px 16px rgba(0, 0, 0, 0.15)',
        },
        '.glass': {
          backgroundColor: 'rgba(255, 255, 255, 0.1)',
          backdropFilter: 'blur(10px)',
          border: '1px solid rgba(255, 255, 255, 0.2)',
        },
      }

      addUtilities(newUtilities, ['responsive', 'hover'])
    }),
  ],
}
```

## 🧪 Testing with Tailwind

### Testing Utilities
```javascript
// test-utils.js - Testing utilities for Tailwind classes
export function hasClass(element, className) {
  return element.classList.contains(className)
}

export function hasClasses(element, classNames) {
  return classNames.every(className => 
    element.classList.contains(className)
  )
}

export function getComputedStyle(element, property) {
  return window.getComputedStyle(element).getPropertyValue(property)
}
```

```javascript
// Component.test.js - Testing Tailwind components
import { render, screen } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  test('applies primary variant classes', () => {
    render(<Button variant="primary">Click me</Button>)
    const button = screen.getByRole('button')
    
    expect(button).toHaveClass('bg-primary-600')
    expect(button).toHaveClass('text-white')
    expect(button).toHaveClass('hover:bg-primary-700')
  })

  test('applies size variant classes', () => {
    render(<Button size="lg">Large Button</Button>)
    const button = screen.getByRole('button')
    
    expect(button).toHaveClass('h-12')
    expect(button).toHaveClass('px-6')
    expect(button).toHaveClass('text-lg')
  })
})
```

## 📚 Best Practices & Tips

### 1. **Semantic Class Organization**
```html
<!-- Group related utilities -->
<div class="
  flex items-center justify-between
  p-4 mx-auto
  bg-white border border-gray-200 rounded-lg shadow-sm
  hover:shadow-md transition-shadow duration-200
">
  Well-organized classes
</div>
```

### 2. **Extract Component Classes**
```css
@layer components {
  .card {
    @apply bg-white border border-gray-200 rounded-lg shadow-sm p-6;
  }
  
  .card-header {
    @apply border-b border-gray-200 pb-4 mb-4;
  }
  
  .form-input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-brand-500 focus:border-brand-500;
  }
}
```

### 3. **Responsive Design Strategy**
```html
<!-- Mobile-first approach -->
<div class="
  grid grid-cols-1 gap-4
  sm:grid-cols-2 sm:gap-6
  lg:grid-cols-3 lg:gap-8
  xl:grid-cols-4
">
  Responsive grid
</div>
```

### 4. **Performance Considerations**
- Use JIT mode for better build performance
- Configure content paths accurately
- Use `safelist` for dynamic classes
- Minimize arbitrary value usage
- Use CSS variables for theming

### 5. **Accessibility**
```html
<!-- Focus states -->
<button class="focus:ring-2 focus:ring-brand-500 focus:ring-offset-2">
  Accessible button
</button>

<!-- Screen reader friendly -->
<div class="sr-only">Screen reader only content</div>

<!-- High contrast support -->
<div class="bg-white text-gray-900 contrast-more:bg-black contrast-more:text-white">
  High contrast support
</div>
```

## 🔗 Integration Examples

### With React/Next.js
```javascript
// components/ui/Button.jsx
import { forwardRef } from 'react'
import { cn } from '@/lib/utils'

const Button = forwardRef(({ className, variant, size, ...props }, ref) => {
  return (
    <button
      className={cn(buttonVariants({ variant, size }), className)}
      ref={ref}
      {...props}
    />
  )
})
```

### With Vue.js
```vue
<!-- components/BaseButton.vue -->
<template>
  <button 
    :class="buttonClasses"
    v-bind="$attrs"
  >
    <slot />
  </button>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'primary'
  },
  size: {
    type: String,
    default: 'default'
  }
})

const buttonClasses = computed(() => {
  const base = 'inline-flex items-center justify-center rounded-lg font-medium transition-colors'
  const variants = {
    primary: 'bg-primary-600 text-white hover:bg-primary-700',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300'
  }
  const sizes = {
    sm: 'h-8 px-3 text-sm',
    default: 'h-10 px-4 text-base',
    lg: 'h-12 px-6 text-lg'
  }
  
  return `${base} ${variants[props.variant]} ${sizes[props.size]}`
})
</script>
```

### With Headless UI
```javascript
// Modal component with Tailwind + Headless UI
import { Dialog, Transition } from '@headlessui/react'
import { Fragment } from 'react'

export function Modal({ isOpen, closeModal, title, children }) {
  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-10" onClose={closeModal}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black bg-opacity-25" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4 text-center">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-white p-6 text-left align-middle shadow-xl transition-all">
                <Dialog.Title className="text-lg font-medium leading-6 text-gray-900">
                  {title}
                </Dialog.Title>
                <div className="mt-2">
                  {children}
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  )
}
```

## 📖 Resources & References

### Official Documentation
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Tailwind UI Components](https://tailwindui.com/)
- [Headless UI](https://headlessui.com/)

### Useful Tools
- **Tailwind IntelliSense** - VS Code extension
- **Tailwind CSS Playground** - Online editor
- **Heroicons** - Beautiful SVG icons
- **Tailwind Forms** - Form styling plugin
- **Tailwind Typography** - Prose styling plugin

### Community Resources
- [Tailwind Components](https://tailwindcomponents.com/)
- [Tailwind Starter Kit](https://github.com/creativetimofficial/tailwind-starter-kit)
- [Awesome Tailwind CSS](https://github.com/aniftyco/awesome-tailwindcss)

---

*This guide covers essential Tailwind CSS patterns for building production-ready applications. Focus on utility-first methodology, responsive design, and maintainable component patterns.*
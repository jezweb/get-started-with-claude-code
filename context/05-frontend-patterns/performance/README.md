# Frontend Performance Optimization

Comprehensive guide to optimizing frontend applications for speed, efficiency, and user experience across React, Vue, and modern web technologies.

## 🎯 Performance Overview

Frontend performance encompasses multiple aspects:
- **Load Performance** - Time to first meaningful paint
- **Runtime Performance** - Smooth interactions and animations
- **Memory Usage** - Efficient resource management
- **Network Efficiency** - Optimized data transfer
- **Core Web Vitals** - Google's user experience metrics

## ⚡ Core Web Vitals

### Understanding the Metrics
```javascript
// Web Vitals measurement
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals'

function sendToAnalytics(metric) {
  // Send to your analytics service
  console.log(metric)
}

// Measure all Core Web Vitals
getCLS(sendToAnalytics)  // Cumulative Layout Shift
getFID(sendToAnalytics)  // First Input Delay
getFCP(sendToAnalytics)  // First Contentful Paint
getLCP(sendToAnalytics)  // Largest Contentful Paint
getTTFB(sendToAnalytics) // Time to First Byte

// Performance Observer for custom metrics
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.entryType === 'navigation') {
      console.log('Page Load Time:', entry.loadEventEnd - entry.loadEventStart)
    }
    
    if (entry.entryType === 'paint') {
      console.log(`${entry.name}:`, entry.startTime)
    }
  }
})

observer.observe({ entryTypes: ['navigation', 'paint', 'largest-contentful-paint'] })
```

### Optimizing Core Web Vitals
```javascript
// Cumulative Layout Shift (CLS) optimization
// 1. Always include size attributes for images and videos
<img src="hero.jpg" width="800" height="400" alt="Hero image" />

// 2. Use aspect-ratio CSS to reserve space
.video-container {
  aspect-ratio: 16 / 9;
  width: 100%;
}

// 3. Avoid inserting content above existing content
// Bad: Dynamically inserting banner
const banner = document.createElement('div')
document.body.insertBefore(banner, document.body.firstChild)

// Good: Reserve space for dynamic content
<div className="banner-placeholder min-h-16">
  {showBanner && <Banner />}
</div>

// First Input Delay (FID) optimization
// 1. Break up long tasks
function processLargeDataset(data) {
  const chunkSize = 100
  let index = 0
  
  function processChunk() {
    const endIndex = Math.min(index + chunkSize, data.length)
    
    for (let i = index; i < endIndex; i++) {
      // Process data[i]
      processItem(data[i])
    }
    
    index = endIndex
    
    if (index < data.length) {
      // Use scheduler if available, otherwise setTimeout
      if (typeof scheduler?.postTask === 'function') {
        scheduler.postTask(processChunk, { priority: 'background' })
      } else {
        setTimeout(processChunk, 0)
      }
    }
  }
  
  processChunk()
}

// 2. Use Web Workers for heavy computations
// worker.js
self.onmessage = function(e) {
  const { data, operation } = e.data
  
  switch (operation) {
    case 'sort':
      const sorted = data.sort((a, b) => a.value - b.value)
      self.postMessage({ result: sorted })
      break
    case 'filter':
      const filtered = data.filter(item => item.active)
      self.postMessage({ result: filtered })
      break
  }
}

// main.js
const worker = new Worker('worker.js')
worker.postMessage({ data: largeDataset, operation: 'sort' })
worker.onmessage = (e) => {
  const sortedData = e.data.result
  updateUI(sortedData)
}

// Largest Contentful Paint (LCP) optimization
// 1. Optimize images
<img 
  src="hero-small.jpg"
  srcSet="hero-small.jpg 480w, hero-medium.jpg 800w, hero-large.jpg 1200w"
  sizes="(max-width: 480px) 480px, (max-width: 800px) 800px, 1200px"
  loading="eager" // For above-the-fold images
  decoding="async"
  alt="Hero"
/>

// 2. Preload critical resources
<link rel="preload" href="hero-large.jpg" as="image" />
<link rel="preload" href="critical.css" as="style" />
<link rel="preload" href="app.js" as="script" />

// 3. Use resource hints
<link rel="dns-prefetch" href="//fonts.googleapis.com" />
<link rel="preconnect" href="https://api.example.com" crossorigin />
```

## 🚀 React Performance Optimization

### Memoization Strategies
```jsx
// React.memo for component memoization
const ExpensiveComponent = React.memo(({ data, config }) => {
  const processedData = useMemo(() => {
    return data.map(item => complexCalculation(item, config))
  }, [data, config])
  
  return (
    <div>
      {processedData.map(item => (
        <ItemComponent key={item.id} item={item} />
      ))}
    </div>
  )
}, (prevProps, nextProps) => {
  // Custom comparison function
  return (
    prevProps.data.length === nextProps.data.length &&
    prevProps.config.mode === nextProps.config.mode
  )
})

// useMemo for expensive calculations
function DataProcessor({ rawData, filters }) {
  const processedData = useMemo(() => {
    console.log('Processing data...') // This will only run when dependencies change
    
    return rawData
      .filter(item => filters.every(filter => filter(item)))
      .sort((a, b) => a.priority - b.priority)
      .map(item => ({
        ...item,
        processed: true,
        score: calculateComplexScore(item)
      }))
  }, [rawData, filters])
  
  return <DataTable data={processedData} />
}

// useCallback for function memoization
function TodoList({ todos }) {
  const [filter, setFilter] = useState('all')
  
  // Memoize event handlers to prevent child re-renders
  const handleToggle = useCallback((id) => {
    setTodos(prev => prev.map(todo => 
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    ))
  }, [setTodos])
  
  const handleDelete = useCallback((id) => {
    setTodos(prev => prev.filter(todo => todo.id !== id))
  }, [setTodos])
  
  const filteredTodos = useMemo(() => {
    switch (filter) {
      case 'active': return todos.filter(todo => !todo.completed)
      case 'completed': return todos.filter(todo => todo.completed)
      default: return todos
    }
  }, [todos, filter])
  
  return (
    <div>
      <FilterButtons filter={filter} onChange={setFilter} />
      {filteredTodos.map(todo => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onToggle={handleToggle}
          onDelete={handleDelete}
        />
      ))}
    </div>
  )
}

// Optimized TodoItem with memo
const TodoItem = React.memo(({ todo, onToggle, onDelete }) => (
  <div className="todo-item">
    <input
      type="checkbox"
      checked={todo.completed}
      onChange={() => onToggle(todo.id)}
    />
    <span className={todo.completed ? 'completed' : ''}>{todo.text}</span>
    <button onClick={() => onDelete(todo.id)}>Delete</button>
  </div>
))
```

### Code Splitting & Lazy Loading
```jsx
// Route-based code splitting
import { lazy, Suspense } from 'react'
import { Routes, Route } from 'react-router-dom'

const Home = lazy(() => import('./pages/Home'))
const About = lazy(() => import('./pages/About'))
const Dashboard = lazy(() => 
  import('./pages/Dashboard').then(module => ({
    default: module.Dashboard
  }))
)

// Component with loading fallback
const LoadingSpinner = () => (
  <div className="flex justify-center items-center h-48">
    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
  </div>
)

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </Suspense>
  )
}

// Component-based code splitting
const HeavyChart = lazy(() => import('./HeavyChart'))

function Dashboard() {
  const [showChart, setShowChart] = useState(false)
  
  return (
    <div>
      <h1>Dashboard</h1>
      <button onClick={() => setShowChart(true)}>
        Load Chart
      </button>
      
      {showChart && (
        <Suspense fallback={<div>Loading chart...</div>}>
          <HeavyChart />
        </Suspense>
      )}
    </div>
  )
}

// Dynamic imports with error handling
async function loadComponent() {
  try {
    const { default: Component } = await import('./HeavyComponent')
    return Component
  } catch (error) {
    console.error('Failed to load component:', error)
    return () => <div>Failed to load component</div>
  }
}
```

### Virtual Scrolling
```jsx
// React Window for large lists
import { FixedSizeList as List } from 'react-window'
import { memo } from 'react'

const Row = memo(({ index, style, data }) => (
  <div style={style} className="flex items-center p-2 border-b">
    <img 
      src={data[index].avatar} 
      alt="Avatar" 
      className="w-10 h-10 rounded-full mr-3"
      loading="lazy"
    />
    <div>
      <div className="font-medium">{data[index].name}</div>
      <div className="text-sm text-gray-500">{data[index].email}</div>
    </div>
  </div>
))

function VirtualizedUserList({ users }) {
  return (
    <List
      height={400}
      itemCount={users.length}
      itemSize={60}
      itemData={users}
      overscanCount={5} // Render extra items for smooth scrolling
    >
      {Row}
    </List>
  )
}

// Variable height lists with react-window-infinite-loader
import { VariableSizeList as List } from 'react-window'
import InfiniteLoader from 'react-window-infinite-loader'

function InfiniteVirtualList({ items, loadMore, hasNextPage, isLoading }) {
  const itemCount = hasNextPage ? items.length + 1 : items.length
  const isItemLoaded = index => !!items[index]
  
  const getItemSize = index => {
    // Calculate item height based on content
    const item = items[index]
    if (!item) return 50 // Loading placeholder
    
    // Estimate height based on content length
    const baseHeight = 60
    const additionalHeight = Math.floor(item.description.length / 50) * 20
    return baseHeight + additionalHeight
  }
  
  const Item = ({ index, style }) => {
    if (!isItemLoaded(index)) {
      return (
        <div style={style} className="flex justify-center items-center">
          Loading...
        </div>
      )
    }
    
    const item = items[index]
    return (
      <div style={style} className="p-4 border-b">
        <h3 className="font-bold">{item.title}</h3>
        <p className="text-gray-600">{item.description}</p>
      </div>
    )
  }
  
  return (
    <InfiniteLoader
      isItemLoaded={isItemLoaded}
      itemCount={itemCount}
      loadMoreItems={loadMore}
    >
      {({ onItemsRendered, ref }) => (
        <List
          ref={ref}
          height={600}
          itemCount={itemCount}
          itemSize={getItemSize}
          onItemsRendered={onItemsRendered}
        >
          {Item}
        </List>
      )}
    </InfiniteLoader>
  )
}
```

## 🎨 Vue Performance Optimization

### Vue 3 Optimization Techniques
```vue
<!-- Reactive performance -->
<template>
  <div>
    <!-- Use v-memo for expensive lists -->
    <div
      v-for="item in expensiveList"
      :key="item.id"
      v-memo="[item.id, item.lastModified]"
    >
      <ExpensiveComponent :item="item" />
    </div>
    
    <!-- Use v-once for static content -->
    <div v-once>
      <h1>{{ title }}</h1>
      <p>{{ staticDescription }}</p>
    </div>
    
    <!-- Optimize v-show vs v-if -->
    <ExpensiveModal v-show="showModal" /> <!-- Use v-show for frequent toggles -->
    <RarelyUsedComponent v-if="shouldRender" /> <!-- Use v-if for conditional rendering -->
  </div>
</template>

<script setup>
import { ref, computed, shallowRef, markRaw, defineAsyncComponent } from 'vue'

// Use shallowRef for large, rarely-changing objects
const largeDataset = shallowRef([])

// Use markRaw for non-reactive objects
const chartInstance = markRaw(new Chart())

// Computed values with proper dependencies
const expensiveComputed = computed(() => {
  // Only re-compute when specific dependencies change
  return expensiveCalculation(props.data, settings.value.mode)
})

// Async components for code splitting
const HeavyChart = defineAsyncComponent({
  loader: () => import('./HeavyChart.vue'),
  loadingComponent: LoadingSpinner,
  errorComponent: ErrorComponent,
  delay: 200,
  timeout: 3000
})

// Optimize large list updates
const updateLargeList = (newData) => {
  // Use nextTick for batch updates
  nextTick(() => {
    largeDataset.value = newData
  })
}
</script>

<!-- Optimized list component -->
<template>
  <div class="virtual-list" ref="containerRef">
    <div 
      v-for="item in visibleItems" 
      :key="item.id"
      :style="{ transform: `translateY(${item.offsetY}px)` }"
      class="list-item"
    >
      <slot :item="item.data" />
    </div>
  </div>
</template>

<script setup>
// Virtual scrolling composable
import { useVirtualList } from '@vueuse/core'

const props = defineProps({
  items: Array,
  itemHeight: {
    type: Number,
    default: 50
  }
})

const containerRef = ref()

const { list: visibleItems } = useVirtualList(
  toRef(props, 'items'),
  {
    itemHeight: props.itemHeight,
    containerElement: containerRef,
    overscan: 5
  }
)
</script>
```

### Pinia Performance
```javascript
// stores/optimized-store.js
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

export const useOptimizedStore = defineStore('optimized', () => {
  // State
  const items = ref([])
  const filters = ref({})
  const loading = ref(false)
  
  // Getters with proper memoization
  const filteredItems = computed(() => {
    if (Object.keys(filters.value).length === 0) return items.value
    
    return items.value.filter(item => {
      return Object.entries(filters.value).every(([key, value]) => {
        if (!value) return true
        return item[key]?.toString().toLowerCase().includes(value.toLowerCase())
      })
    })
  })
  
  const itemsById = computed(() => {
    return items.value.reduce((acc, item) => {
      acc[item.id] = item
      return acc
    }, {})
  })
  
  // Optimized actions
  const addItems = (newItems) => {
    // Batch updates
    items.value.push(...newItems)
  }
  
  const updateItem = (id, updates) => {
    // Find and update without triggering full reactivity
    const index = items.value.findIndex(item => item.id === id)
    if (index !== -1) {
      Object.assign(items.value[index], updates)
    }
  }
  
  const bulkUpdate = (updates) => {
    // Batch multiple updates
    updates.forEach(({ id, data }) => {
      updateItem(id, data)
    })
  }
  
  return {
    // State
    items,
    filters,
    loading,
    
    // Getters
    filteredItems,
    itemsById,
    
    // Actions
    addItems,
    updateItem,
    bulkUpdate
  }
})

// Optimized component using the store
<template>
  <div>
    <SearchFilter v-model="searchQuery" />
    <ItemGrid :items="visibleItems" />
    <LoadMoreButton @click="loadMore" :loading="loading" />
  </div>
</template>

<script setup>
import { storeToRefs } from 'pinia'
import { useOptimizedStore } from '@/stores/optimized-store'
import { useIntersectionObserver } from '@vueuse/core'

const store = useOptimizedStore()

// Use storeToRefs to maintain reactivity
const { filteredItems, loading } = storeToRefs(store)

// Implement virtual pagination
const pageSize = 50
const currentPage = ref(1)

const visibleItems = computed(() => {
  const start = 0
  const end = currentPage.value * pageSize
  return filteredItems.value.slice(start, end)
})

// Infinite scrolling with intersection observer
const target = ref()
const { stop } = useIntersectionObserver(
  target,
  ([{ isIntersecting }]) => {
    if (isIntersecting && !loading.value) {
      loadMore()
    }
  }
)

const loadMore = () => {
  if (visibleItems.value.length < filteredItems.value.length) {
    currentPage.value++
  } else {
    // Load more data from API
    store.loadMoreItems()
  }
}
</script>
```

## 📦 Bundle Optimization

### Webpack/Vite Configuration
```javascript
// vite.config.js - Optimized build configuration
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    // Enable code splitting
    rollupOptions: {
      output: {
        manualChunks: {
          // Vendor chunks
          vendor: ['react', 'react-dom'],
          ui: ['@headlessui/react', 'framer-motion'],
          utils: ['lodash', 'date-fns'],
          
          // Route-based chunks
          home: ['./src/pages/Home'],
          dashboard: ['./src/pages/Dashboard'],
        }
      }
    },
    
    // Optimize chunk sizes
    chunkSizeWarningLimit: 1000,
    
    // Enable minification
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  
  // Optimize dependencies
  optimizeDeps: {
    include: ['react', 'react-dom'],
    exclude: ['@vite/client', '@vite/env']
  },
  
  // Enable CSS code splitting
  css: {
    codeStyle: 'split'
  }
})

// webpack.config.js - Advanced optimization
module.exports = {
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
        },
        common: {
          name: 'common',
          minChunks: 2,
          chunks: 'all',
          enforce: true
        }
      }
    },
    
    // Tree shaking configuration
    usedExports: true,
    sideEffects: false,
    
    // Runtime chunk for better caching
    runtimeChunk: 'single'
  },
  
  // Module resolution optimization
  resolve: {
    modules: ['node_modules'],
    extensions: ['.js', '.jsx', '.ts', '.tsx'],
    alias: {
      '@': resolve(__dirname, 'src')
    }
  }
}
```

### Tree Shaking Optimization
```javascript
// Optimize imports for better tree shaking
// ❌ Bad - imports entire library
import _ from 'lodash'
import * as icons from 'lucide-react'

// ✅ Good - imports only what's needed
import { debounce, throttle } from 'lodash'
import { Search, User, Settings } from 'lucide-react'

// ❌ Bad - side effects prevent tree shaking
import 'some-library/styles.css'
import 'some-library' // This might import everything

// ✅ Good - explicit imports
import { specificFunction } from 'some-library/specific-module'
import 'some-library/styles.css' // If needed, mark as side effect

// Package.json configuration for tree shaking
{
  "sideEffects": [
    "*.css",
    "*.scss",
    "./src/polyfills.js"
  ]
}

// Mark specific imports as side-effect free
import /*#__PURE__*/ { heavyFunction } from './utils'

// Conditional imports for better tree shaking
const isDevelopment = process.env.NODE_ENV === 'development'

// Only import in development
if (isDevelopment) {
  import('./dev-tools').then(({ setupDevTools }) => {
    setupDevTools()
  })
}

// Use dynamic imports for optional features
async function loadOptionalFeature() {
  if (shouldLoadFeature) {
    const { OptionalComponent } = await import('./OptionalFeature')
    return OptionalComponent
  }
  return null
}
```

## 🖼️ Image Optimization

### Modern Image Techniques
```jsx
// Responsive images with modern formats
function OptimizedImage({ 
  src, 
  alt, 
  width, 
  height, 
  className,
  priority = false,
  sizes = "100vw"
}) {
  const webpSrc = src.replace(/\.(jpg|jpeg|png)$/, '.webp')
  const avifSrc = src.replace(/\.(jpg|jpeg|png)$/, '.avif')
  
  return (
    <picture>
      {/* Modern formats first */}
      <source srcSet={avifSrc} type="image/avif" />
      <source srcSet={webpSrc} type="image/webp" />
      
      {/* Fallback */}
      <img
        src={src}
        alt={alt}
        width={width}
        height={height}
        className={className}
        loading={priority ? "eager" : "lazy"}
        decoding="async"
        sizes={sizes}
      />
    </picture>
  )
}

// Progressive image loading
function ProgressiveImage({ src, placeholder, alt, ...props }) {
  const [imageSrc, setImageSrc] = useState(placeholder)
  const [isLoaded, setIsLoaded] = useState(false)
  
  useEffect(() => {
    const img = new Image()
    img.onload = () => {
      setImageSrc(src)
      setIsLoaded(true)
    }
    img.src = src
  }, [src])
  
  return (
    <div className="relative overflow-hidden">
      <img
        src={imageSrc}
        alt={alt}
        className={`transition-opacity duration-300 ${
          isLoaded ? 'opacity-100' : 'opacity-0'
        }`}
        {...props}
      />
      
      {!isLoaded && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse" />
      )}
    </div>
  )
}

// Image preloading hook
function useImagePreloader(imageUrls) {
  const [loadedImages, setLoadedImages] = useState(new Set())
  
  useEffect(() => {
    const preloadImage = (url) => {
      return new Promise((resolve, reject) => {
        const img = new Image()
        img.onload = () => resolve(url)
        img.onerror = reject
        img.src = url
      })
    }
    
    Promise.allSettled(imageUrls.map(preloadImage))
      .then(results => {
        const loaded = results
          .filter(result => result.status === 'fulfilled')
          .map(result => result.value)
        
        setLoadedImages(new Set(loaded))
      })
  }, [imageUrls])
  
  return loadedImages
}

// Next.js Image optimization
import Image from 'next/image'

function OptimizedImageGallery({ images }) {
  return (
    <div className="grid grid-cols-3 gap-4">
      {images.map((image, index) => (
        <Image
          key={image.id}
          src={image.src}
          alt={image.alt}
          width={400}
          height={300}
          priority={index < 3} // Prioritize first 3 images
          placeholder="blur"
          blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..." // Low quality placeholder
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
        />
      ))}
    </div>
  )
}
```

## 🌐 Network Optimization

### Data Fetching Strategies
```javascript
// Service Worker for caching
// sw.js
const CACHE_NAME = 'app-cache-v1'
const urlsToCache = [
  '/',
  '/static/css/main.css',
  '/static/js/main.js',
  '/api/critical-data'
]

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  )
})

self.addEventListener('fetch', (event) => {
  // Cache-first strategy for static assets
  if (event.request.url.includes('/static/')) {
    event.respondWith(
      caches.match(event.request)
        .then((response) => response || fetch(event.request))
    )
    return
  }
  
  // Network-first strategy for API calls
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          // Clone and cache successful responses
          if (response.status === 200) {
            const responseClone = response.clone()
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseClone)
            })
          }
          return response
        })
        .catch(() => {
          // Fallback to cache on network error
          return caches.match(event.request)
        })
    )
  }
})

// Request optimization with batching
class RequestBatcher {
  constructor(batchSize = 10, delay = 100) {
    this.batchSize = batchSize
    this.delay = delay
    this.queue = []
    this.timeoutId = null
  }
  
  add(request) {
    return new Promise((resolve, reject) => {
      this.queue.push({ request, resolve, reject })
      
      if (this.queue.length >= this.batchSize) {
        this.flush()
      } else if (!this.timeoutId) {
        this.timeoutId = setTimeout(() => this.flush(), this.delay)
      }
    })
  }
  
  async flush() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }
    
    const batch = this.queue.splice(0, this.batchSize)
    if (batch.length === 0) return
    
    try {
      const requests = batch.map(({ request }) => request)
      const responses = await this.executeBatch(requests)
      
      batch.forEach(({ resolve }, index) => {
        resolve(responses[index])
      })
    } catch (error) {
      batch.forEach(({ reject }) => {
        reject(error)
      })
    }
  }
  
  async executeBatch(requests) {
    // Send batched request to server
    const response = await fetch('/api/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requests })
    })
    
    return response.json()
  }
}

const batcher = new RequestBatcher()

// Usage
async function fetchUser(id) {
  return batcher.add({ type: 'user', id })
}

// Request deduplication
class RequestDeduplicator {
  constructor() {
    this.cache = new Map()
  }
  
  async request(key, requestFn) {
    if (this.cache.has(key)) {
      return this.cache.get(key)
    }
    
    const promise = requestFn()
    this.cache.set(key, promise)
    
    try {
      const result = await promise
      // Cache successful results for a short time
      setTimeout(() => this.cache.delete(key), 5000)
      return result
    } catch (error) {
      // Remove failed requests immediately
      this.cache.delete(key)
      throw error
    }
  }
}

const deduplicator = new RequestDeduplicator()

// Usage
async function getUser(id) {
  return deduplicator.request(`user-${id}`, () => 
    fetch(`/api/users/${id}`).then(r => r.json())
  )
}
```

### HTTP/2 & HTTP/3 Optimization
```javascript
// Resource loading optimization
function optimizeResourceLoading() {
  // Preload critical resources
  const criticalResources = [
    { href: '/fonts/main.woff2', as: 'font', type: 'font/woff2' },
    { href: '/api/user', as: 'fetch', crossorigin: 'anonymous' },
    { href: '/images/hero.jpg', as: 'image' }
  ]
  
  criticalResources.forEach(resource => {
    const link = document.createElement('link')
    link.rel = 'preload'
    Object.assign(link, resource)
    document.head.appendChild(link)
  })
  
  // DNS prefetching for external resources
  const externalDomains = [
    'fonts.googleapis.com',
    'api.analytics.com',
    'cdn.example.com'
  ]
  
  externalDomains.forEach(domain => {
    const link = document.createElement('link')
    link.rel = 'dns-prefetch'
    link.href = `//${domain}`
    document.head.appendChild(link)
  })
  
  // Early hints (HTTP/2 Server Push alternative)
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').then(registration => {
      // Service worker can implement early hints
      registration.addEventListener('message', event => {
        if (event.data.type === 'EARLY_HINTS') {
          event.data.resources.forEach(resource => {
            const link = document.createElement('link')
            link.rel = 'preload'
            link.href = resource.url
            link.as = resource.as
            document.head.appendChild(link)
          })
        }
      })
    })
  }
}

// HTTP/2 push simulation with link prefetch
function simulateHTTP2Push(resources) {
  resources.forEach(resource => {
    const link = document.createElement('link')
    link.rel = 'prefetch'
    link.href = resource.url
    link.as = resource.type
    document.head.appendChild(link)
  })
}
```

## 📱 Mobile Performance

### Touch & Scroll Optimization
```javascript
// Optimized scroll handling
function useOptimizedScroll(callback, deps = []) {
  const ticking = useRef(false)
  
  const handleScroll = useCallback(() => {
    if (!ticking.current) {
      requestAnimationFrame(() => {
        callback()
        ticking.current = false
      })
      ticking.current = true
    }
  }, deps)
  
  useEffect(() => {
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [handleScroll])
}

// Touch event optimization
function useTouchGestures(elementRef) {
  const [gesture, setGesture] = useState(null)
  
  useEffect(() => {
    const element = elementRef.current
    if (!element) return
    
    let startX, startY, startTime
    
    const handleTouchStart = (e) => {
      startX = e.touches[0].clientX
      startY = e.touches[0].clientY
      startTime = Date.now()
    }
    
    const handleTouchEnd = (e) => {
      const endX = e.changedTouches[0].clientX
      const endY = e.changedTouches[0].clientY
      const endTime = Date.now()
      
      const deltaX = endX - startX
      const deltaY = endY - startY
      const deltaTime = endTime - startTime
      
      // Determine gesture
      if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 50) {
        setGesture(deltaX > 0 ? 'swipe-right' : 'swipe-left')
      } else if (Math.abs(deltaY) > 50) {
        setGesture(deltaY > 0 ? 'swipe-down' : 'swipe-up')
      } else if (deltaTime < 300) {
        setGesture('tap')
      }
    }
    
    element.addEventListener('touchstart', handleTouchStart, { passive: true })
    element.addEventListener('touchend', handleTouchEnd, { passive: true })
    
    return () => {
      element.removeEventListener('touchstart', handleTouchStart)
      element.removeEventListener('touchend', handleTouchEnd)
    }
  }, [])
  
  return gesture
}

// Viewport optimization
function useViewportOptimization() {
  const [viewport, setViewport] = useState({
    width: window.innerWidth,
    height: window.innerHeight,
    pixelRatio: window.devicePixelRatio
  })
  
  useEffect(() => {
    const handleResize = throttle(() => {
      setViewport({
        width: window.innerWidth,
        height: window.innerHeight,
        pixelRatio: window.devicePixelRatio
      })
    }, 100)
    
    window.addEventListener('resize', handleResize)
    window.addEventListener('orientationchange', handleResize)
    
    return () => {
      window.removeEventListener('resize', handleResize)
      window.removeEventListener('orientationchange', handleResize)
    }
  }, [])
  
  return viewport
}
```

### Battery & CPU Optimization
```javascript
// Battery-aware performance
async function getBatteryInfo() {
  if ('getBattery' in navigator) {
    try {
      const battery = await navigator.getBattery()
      return {
        charging: battery.charging,
        level: battery.level,
        dischargingTime: battery.dischargingTime
      }
    } catch (error) {
      console.warn('Battery API not available')
    }
  }
  return null
}

function useBatteryOptimization() {
  const [batteryInfo, setBatteryInfo] = useState(null)
  const [performanceMode, setPerformanceMode] = useState('normal')
  
  useEffect(() => {
    getBatteryInfo().then(info => {
      setBatteryInfo(info)
      
      // Adjust performance based on battery
      if (info) {
        if (info.level < 0.2 && !info.charging) {
          setPerformanceMode('low-power')
        } else if (info.level > 0.8 && info.charging) {
          setPerformanceMode('high-performance')
        } else {
          setPerformanceMode('normal')
        }
      }
    })
  }, [])
  
  return { batteryInfo, performanceMode }
}

// CPU usage monitoring
function useCPUMonitoring() {
  const [cpuUsage, setCpuUsage] = useState('normal')
  
  useEffect(() => {
    let frameCount = 0
    let startTime = performance.now()
    
    function measurePerformance() {
      frameCount++
      
      if (frameCount % 60 === 0) { // Check every 60 frames
        const currentTime = performance.now()
        const fps = 60000 / (currentTime - startTime)
        
        if (fps < 30) {
          setCpuUsage('high')
        } else if (fps > 55) {
          setCpuUsage('low')
        } else {
          setCpuUsage('normal')
        }
        
        startTime = currentTime
      }
      
      requestAnimationFrame(measurePerformance)
    }
    
    const rafId = requestAnimationFrame(measurePerformance)
    
    return () => cancelAnimationFrame(rafId)
  }, [])
  
  return cpuUsage
}
```

## 🔧 Performance Monitoring

### Real User Monitoring (RUM)
```javascript
// Custom performance monitoring
class PerformanceMonitor {
  constructor(config = {}) {
    this.config = {
      sampleRate: 0.1, // Monitor 10% of users
      apiEndpoint: '/api/analytics/performance',
      ...config
    }
    this.metrics = new Map()
    this.observers = new Map()
    
    this.init()
  }
  
  init() {
    if (Math.random() > this.config.sampleRate) return
    
    this.setupObservers()
    this.trackPageLoad()
    this.trackUserInteractions()
  }
  
  setupObservers() {
    // Performance Observer for various metrics
    const perfObserver = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        this.recordMetric(entry.entryType, {
          name: entry.name,
          duration: entry.duration,
          startTime: entry.startTime,
          timestamp: Date.now()
        })
      }
    })
    
    perfObserver.observe({ 
      entryTypes: ['navigation', 'paint', 'largest-contentful-paint', 'layout-shift'] 
    })
    
    // Long task observer
    const longTaskObserver = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        this.recordMetric('long-task', {
          duration: entry.duration,
          startTime: entry.startTime
        })
      }
    })
    
    longTaskObserver.observe({ entryTypes: ['longtask'] })
  }
  
  trackPageLoad() {
    window.addEventListener('load', () => {
      setTimeout(() => {
        const navigation = performance.getEntriesByType('navigation')[0]
        
        this.recordMetric('page-load', {
          domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
          loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
          firstByte: navigation.responseStart - navigation.requestStart,
          domInteractive: navigation.domInteractive - navigation.navigationStart
        })
        
        this.sendMetrics()
      }, 0)
    })
  }
  
  trackUserInteractions() {
    // Track click response times
    document.addEventListener('click', (e) => {
      const startTime = performance.now()
      
      // Measure time to next paint
      requestAnimationFrame(() => {
        const endTime = performance.now()
        this.recordMetric('interaction', {
          type: 'click',
          target: e.target.tagName,
          responseTime: endTime - startTime
        })
      })
    })
    
    // Track input lag
    let inputStart = 0
    document.addEventListener('keydown', () => {
      inputStart = performance.now()
    })
    
    document.addEventListener('input', () => {
      if (inputStart) {
        const inputLag = performance.now() - inputStart
        this.recordMetric('input-lag', { duration: inputLag })
        inputStart = 0
      }
    })
  }
  
  recordMetric(type, data) {
    if (!this.metrics.has(type)) {
      this.metrics.set(type, [])
    }
    
    this.metrics.get(type).push({
      ...data,
      timestamp: Date.now(),
      url: window.location.pathname,
      userAgent: navigator.userAgent,
      connection: navigator.connection?.effectiveType
    })
    
    // Send metrics in batches
    if (this.metrics.get(type).length >= 10) {
      this.sendMetrics(type)
    }
  }
  
  async sendMetrics(type = null) {
    const metricsToSend = type ? 
      { [type]: this.metrics.get(type) } : 
      Object.fromEntries(this.metrics)
    
    try {
      await fetch(this.config.apiEndpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          metrics: metricsToSend,
          session: this.getSessionId(),
          timestamp: Date.now()
        })
      })
      
      // Clear sent metrics
      if (type) {
        this.metrics.set(type, [])
      } else {
        this.metrics.clear()
      }
    } catch (error) {
      console.warn('Failed to send performance metrics:', error)
    }
  }
  
  getSessionId() {
    let sessionId = sessionStorage.getItem('performance-session-id')
    if (!sessionId) {
      sessionId = Math.random().toString(36).substr(2, 9)
      sessionStorage.setItem('performance-session-id', sessionId)
    }
    return sessionId
  }
}

// Initialize monitoring
const monitor = new PerformanceMonitor({
  sampleRate: 0.05, // Monitor 5% of users
  apiEndpoint: '/api/performance'
})

// Custom timing measurements
function measureAsyncOperation(name, operation) {
  return new Promise((resolve, reject) => {
    const startTime = performance.now()
    
    operation()
      .then(result => {
        const duration = performance.now() - startTime
        monitor.recordMetric('async-operation', {
          name,
          duration,
          success: true
        })
        resolve(result)
      })
      .catch(error => {
        const duration = performance.now() - startTime
        monitor.recordMetric('async-operation', {
          name,
          duration,
          success: false,
          error: error.message
        })
        reject(error)
      })
  })
}
```

## 📚 Performance Best Practices

### 1. **Critical Rendering Path**
```html
<!-- Optimize critical rendering path -->
<!DOCTYPE html>
<html>
<head>
  <!-- Minimize render-blocking resources -->
  <style>
    /* Inline critical CSS */
    .hero { background: #000; color: #fff; }
  </style>
  
  <!-- Preload critical resources -->
  <link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="/api/critical-data" as="fetch" crossorigin>
  
  <!-- Non-critical CSS -->
  <link rel="preload" href="/styles/main.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
  
  <!-- Critical JavaScript -->
  <script>
    // Inline critical scripts
    window.APP_CONFIG = { theme: 'light' }
  </script>
</head>
<body>
  <!-- Content -->
  
  <!-- Defer non-critical JavaScript -->
  <script src="/js/main.js" defer></script>
  <script src="/js/analytics.js" async></script>
</body>
</html>
```

### 2. **Resource Loading Priority**
```javascript
// Resource loading strategies
const resourcePriorities = {
  critical: [
    { url: '/api/user', type: 'fetch' },
    { url: '/fonts/main.woff2', type: 'font' }
  ],
  important: [
    { url: '/images/hero.jpg', type: 'image' },
    { url: '/api/navigation', type: 'fetch' }
  ],
  normal: [
    { url: '/api/recommendations', type: 'fetch' },
    { url: '/images/gallery', type: 'image' }
  ]
}

async function loadResourcesByPriority() {
  // Load critical resources immediately
  await Promise.all(
    resourcePriorities.critical.map(resource => loadResource(resource))
  )
  
  // Load important resources after critical
  setTimeout(() => {
    resourcePriorities.important.forEach(resource => loadResource(resource))
  }, 100)
  
  // Load normal resources when idle
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => {
      resourcePriorities.normal.forEach(resource => loadResource(resource))
    })
  } else {
    setTimeout(() => {
      resourcePriorities.normal.forEach(resource => loadResource(resource))
    }, 2000)
  }
}

function loadResource(resource) {
  switch (resource.type) {
    case 'fetch':
      return fetch(resource.url)
    case 'image':
      return new Promise((resolve, reject) => {
        const img = new Image()
        img.onload = resolve
        img.onerror = reject
        img.src = resource.url
      })
    case 'font':
      return new FontFace('MainFont', `url(${resource.url})`).load()
    default:
      return Promise.resolve()
  }
}
```

### 3. **Memory Management**
```javascript
// Memory leak prevention
class ComponentManager {
  constructor() {
    this.components = new WeakMap()
    this.eventListeners = new Map()
    this.timers = new Set()
    this.observers = new Set()
  }
  
  registerComponent(component) {
    this.components.set(component, {
      mounted: Date.now(),
      listeners: [],
      timers: [],
      observers: []
    })
  }
  
  addEventListener(element, event, handler, options) {
    element.addEventListener(event, handler, options)
    
    const cleanup = () => element.removeEventListener(event, handler, options)
    this.eventListeners.set(`${element}-${event}`, cleanup)
    
    return cleanup
  }
  
  setTimeout(callback, delay) {
    const timerId = setTimeout(() => {
      this.timers.delete(timerId)
      callback()
    }, delay)
    
    this.timers.add(timerId)
    return timerId
  }
  
  setInterval(callback, interval) {
    const intervalId = setInterval(callback, interval)
    this.timers.add(intervalId)
    
    return () => {
      clearInterval(intervalId)
      this.timers.delete(intervalId)
    }
  }
  
  createObserver(observerClass, callback, options) {
    const observer = new observerClass(callback, options)
    this.observers.add(observer)
    
    return {
      observer,
      disconnect: () => {
        observer.disconnect()
        this.observers.delete(observer)
      }
    }
  }
  
  cleanup() {
    // Clear all timers
    this.timers.forEach(timerId => {
      clearTimeout(timerId)
      clearInterval(timerId)
    })
    this.timers.clear()
    
    // Remove all event listeners
    this.eventListeners.forEach(cleanup => cleanup())
    this.eventListeners.clear()
    
    // Disconnect all observers
    this.observers.forEach(observer => observer.disconnect())
    this.observers.clear()
  }
}

// Usage in React
function useComponentManager() {
  const managerRef = useRef(new ComponentManager())
  
  useEffect(() => {
    return () => managerRef.current.cleanup()
  }, [])
  
  return managerRef.current
}
```

## 📖 Resources & References

### Documentation
- [Web Performance Working Group](https://www.w3.org/webperf/)
- [Core Web Vitals](https://web.dev/vitals/)
- [React Performance](https://react.dev/learn/render-and-commit)
- [Vue Performance](https://vuejs.org/guide/best-practices/performance.html)

### Tools & Libraries
- **Monitoring**: Lighthouse, WebPageTest, Core Web Vitals
- **Bundling**: Webpack Bundle Analyzer, Vite Bundle Analyzer
- **Runtime**: React DevTools Profiler, Vue DevTools
- **Images**: Sharp, Squoosh, Imagemin
- **Fonts**: Font Display, Preload Key Requests

---

*This guide covers comprehensive frontend performance optimization techniques. Focus on measuring first, then optimizing the most impactful areas for your specific use case.*
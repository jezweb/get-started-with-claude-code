# Vue Performance Optimization

Comprehensive techniques for optimizing Vue 3 applications for maximum performance.

## Vue 3 Optimization Techniques

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

## Pinia Performance Optimization

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

## Component Optimization Patterns

```vue
<!-- Functional components for stateless renders -->
<template functional>
  <div class="user-badge">
    <img :src="props.avatar" :alt="props.name" />
    <span>{{ props.name }}</span>
  </div>
</template>

<!-- Slot optimization -->
<template>
  <div class="container">
    <!-- Use scoped slots efficiently -->
    <template v-for="item in items" :key="item.id">
      <slot name="item" :item="item">
        <!-- Default fallback content -->
        <DefaultItem :item="item" />
      </slot>
    </template>
  </div>
</template>

<script setup>
// Dynamic component optimization
import { shallowRef, watchEffect } from 'vue'

const componentMap = {
  text: () => import('./TextComponent.vue'),
  image: () => import('./ImageComponent.vue'),
  video: () => import('./VideoComponent.vue')
}

const currentComponent = shallowRef(null)

watchEffect(async () => {
  const loader = componentMap[props.type]
  if (loader) {
    const { default: component } = await loader()
    currentComponent.value = markRaw(component)
  }
})
</script>
```

## Reactivity Optimization

```javascript
// Optimizing reactive data structures
import { ref, shallowReactive, shallowRef, toRaw } from 'vue'

// Use shallowReactive for nested objects when deep reactivity isn't needed
const state = shallowReactive({
  user: { id: 1, name: 'John' },
  settings: { theme: 'dark', lang: 'en' }
})

// Use toRaw for performance-critical operations
const performBatchOperation = () => {
  const rawData = toRaw(state.data)
  // Perform operations on raw data without triggering reactivity
  const result = expensiveCalculation(rawData)
  
  // Update reactive state once
  state.result = result
}

// Optimize watchers
import { watchEffect, watch } from 'vue'

// Use watchEffect with proper cleanup
const stop = watchEffect((onCleanup) => {
  const timer = setInterval(() => {
    updateData()
  }, 1000)
  
  onCleanup(() => {
    clearInterval(timer)
  })
})

// Use immediate and deep options wisely
watch(
  () => state.filters,
  (newFilters) => {
    // Only runs when filters change
    applyFilters(newFilters)
  },
  { 
    deep: true, // Only use when necessary
    immediate: false // Avoid initial execution if not needed
  }
)

// Debounce reactive updates
import { debounce } from 'lodash-es'

const searchQuery = ref('')
const debouncedSearch = debounce((query) => {
  performSearch(query)
}, 300)

watch(searchQuery, debouncedSearch)
```

## Template Optimization

```vue
<template>
  <!-- Use key properly for list rendering -->
  <TransitionGroup name="list" tag="ul">
    <li 
      v-for="item in sortedItems" 
      :key="item.id"
      class="list-item"
    >
      {{ item.name }}
    </li>
  </TransitionGroup>
  
  <!-- Avoid inline functions in templates -->
  <!-- Bad -->
  <button @click="() => handleClick(item.id)">Click</button>
  
  <!-- Good -->
  <button @click="handleClick(item.id)">Click</button>
  
  <!-- Use template refs efficiently -->
  <div ref="containerRef">
    <ChildComponent 
      v-for="(item, index) in items" 
      :key="item.id"
      :ref="el => itemRefs[index] = el"
    />
  </div>
</template>

<script setup>
// Template ref optimization
const containerRef = ref()
const itemRefs = ref([])

// Clean up refs when items change
watch(() => items.value.length, (newLength) => {
  itemRefs.value = itemRefs.value.slice(0, newLength)
})
</script>
```

## Build-time Optimization

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'

export default defineConfig({
  plugins: [
    vue(),
    // Auto-import components
    Components({
      resolvers: [ElementPlusResolver()],
      // Only include components that are actually used
      include: [/\.vue$/, /\.vue\?vue/],
      exclude: [/node_modules/, /\.git/, /\.nuxt/]
    })
  ],
  
  build: {
    // Optimize chunk splitting
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['vue', 'vue-router', 'pinia'],
          'ui': ['element-plus'],
          'utils': ['lodash-es', 'date-fns']
        }
      }
    },
    
    // Enable build optimizations
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
    include: ['vue', 'vue-router', 'pinia'],
    exclude: ['@vueuse/core']
  }
})
```

## Memory Management

```vue
<script setup>
import { onUnmounted, effectScope } from 'vue'

// Manage effect scope for better cleanup
const scope = effectScope()

scope.run(() => {
  // All reactive effects in this scope
  const data = ref([])
  const filtered = computed(() => data.value.filter(/* ... */))
  
  watch(filtered, (newVal) => {
    // Handle changes
  })
})

// Clean up all effects at once
onUnmounted(() => {
  scope.stop()
})

// Manual memory management for heavy resources
const heavyResource = ref(null)

const initResource = async () => {
  heavyResource.value = await createHeavyResource()
}

const cleanupResource = () => {
  if (heavyResource.value) {
    heavyResource.value.destroy()
    heavyResource.value = null
  }
}

onMounted(initResource)
onUnmounted(cleanupResource)

// WeakMap for component instances
const componentCache = new WeakMap()

const getCachedData = (instance) => {
  if (!componentCache.has(instance)) {
    componentCache.set(instance, computeExpensiveData())
  }
  return componentCache.get(instance)
}
</script>
```

## Performance Monitoring

```javascript
// Custom performance monitoring composable
import { onMounted, onUpdated, onUnmounted } from 'vue'

export function usePerformanceMonitor(componentName) {
  let renderCount = 0
  let mountTime = 0
  let updateTimes = []
  
  onMounted(() => {
    mountTime = performance.now()
    console.log(`[${componentName}] Mounted in ${mountTime}ms`)
  })
  
  onUpdated(() => {
    renderCount++
    const updateTime = performance.now()
    updateTimes.push(updateTime)
    
    console.log(`[${componentName}] Update #${renderCount} at ${updateTime}ms`)
    
    // Warn if too many updates
    if (renderCount > 10) {
      console.warn(`[${componentName}] High update frequency detected`)
    }
  })
  
  onUnmounted(() => {
    const lifetime = performance.now() - mountTime
    const avgUpdateTime = updateTimes.length > 0
      ? updateTimes.reduce((a, b) => a + b, 0) / updateTimes.length
      : 0
      
    console.log(`[${componentName}] Performance Summary:`, {
      lifetime,
      totalUpdates: renderCount,
      avgUpdateTime
    })
  })
  
  return {
    getRenderCount: () => renderCount,
    getPerformanceStats: () => ({
      mountTime,
      renderCount,
      updateTimes
    })
  }
}

// Usage in component
const { getRenderCount } = usePerformanceMonitor('UserList')
```
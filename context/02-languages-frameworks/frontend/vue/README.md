# Vue 3 Modern Patterns & Best Practices

Comprehensive guide to building production-ready Vue 3 applications with Composition API, modern patterns, and performance optimizations.

## 🎯 What is Vue 3?

Vue 3 is a progressive JavaScript framework for building user interfaces:
- **Progressive** - Can be adopted incrementally
- **Composition API** - Better logic reuse and TypeScript support
- **Reactive** - Efficient reactivity system with Proxy
- **Component-Based** - Build complex UIs from small, reusable pieces
- **Performant** - Smaller bundle size and faster runtime

## 🚀 Quick Start

### Vue CLI (Traditional)
```bash
npm install -g @vue/cli
vue create my-vue-app
cd my-vue-app
npm run serve
```

### Vite (Recommended - Fast & Modern)
```bash
npm create vue@latest my-vue-app
cd my-vue-app
npm install
npm run dev
```

### Vite Manual Setup
```bash
npm create vite@latest my-vue-app -- --template vue
cd my-vue-app
npm install
npm run dev
```

## 📁 Project Structure

### Modern Vue 3 Project Structure
```
src/
├── components/          # Reusable UI components
│   ├── ui/             # Basic UI components (Button, Input, Modal)
│   ├── forms/          # Form-specific components
│   └── layout/         # Layout components (Header, Sidebar, Footer)
├── views/              # Page components (router views)
├── composables/        # Composition API logic (Vue's custom hooks)
├── stores/             # Pinia stores (state management)
├── router/             # Vue Router configuration
├── services/           # API calls and external services
├── utils/              # Helper functions and utilities
├── types/              # TypeScript type definitions
├── constants/          # Application constants
├── assets/             # Static assets (images, fonts, etc.)
├── styles/             # Global styles and themes
├── __tests__/          # Test files
├── App.vue            # Root component
└── main.js            # Entry point
```

### Component Organization
```
components/
├── UserCard/
│   ├── UserCard.vue
│   ├── UserCard.test.js
│   ├── UserCard.stories.js    # Storybook stories
│   └── index.js              # Export file
├── BaseButton/
│   ├── BaseButton.vue
│   ├── BaseButton.test.js
│   └── index.js
└── index.js                  # Barrel exports
```

## 🎨 Composition API Patterns

### Basic Component with Composition API
```vue
<!-- components/UserProfile.vue -->
<template>
  <div class="user-profile">
    <div v-if="loading" class="loading">
      Loading user data...
    </div>
    
    <div v-else-if="error" class="error">
      Error: {{ error.message }}
    </div>
    
    <div v-else-if="user" class="user-content">
      <div class="user-avatar">
        <img :src="user.avatar" :alt="`${user.name}'s avatar`" />
      </div>
      
      <UserEditForm 
        v-if="isEditing"
        :user="user"
        @save="handleSave"
        @cancel="isEditing = false"
      />
      
      <UserDetails 
        v-else
        :user="user"
        @edit="isEditing = true"
      />
    </div>
    
    <div v-else class="not-found">
      User not found
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useUser } from '@/composables/useUser'
import UserEditForm from './UserEditForm.vue'
import UserDetails from './UserDetails.vue'

// Props
const props = defineProps({
  userId: {
    type: [String, Number],
    required: true
  }
})

// Emits
const emit = defineEmits(['userUpdated'])

// Local state
const isEditing = ref(false)

// Composables
const { user, loading, error, updateUser } = useUser(props.userId)

// Computed
const displayName = computed(() => {
  return user.value ? `${user.value.firstName} ${user.value.lastName}` : ''
})

// Methods
const handleSave = async (userData) => {
  try {
    const updatedUser = await updateUser(userData)
    isEditing.value = false
    emit('userUpdated', updatedUser)
  } catch (error) {
    console.error('Failed to update user:', error)
  }
}

// Expose for template ref access
defineExpose({
  startEditing: () => { isEditing.value = true },
  user: readonly(user)
})
</script>

<style scoped>
.user-profile {
  max-width: 500px;
  margin: 0 auto;
  padding: 1rem;
}

.user-avatar img {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  object-fit: cover;
}

.loading, .error, .not-found {
  text-align: center;
  padding: 2rem;
}

.error {
  color: #dc2626;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 0.5rem;
}
</style>
```

### Composables (Vue's Custom Hooks)
```js
// composables/useUser.js
import { ref, computed, watch } from 'vue'
import { userService } from '@/services/userService'

export function useUser(userId) {
  const user = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const fetchUser = async () => {
    if (!userId) return

    try {
      loading.value = true
      error.value = null
      const userData = await userService.getById(userId)
      user.value = userData
    } catch (err) {
      error.value = err
      user.value = null
    } finally {
      loading.value = false
    }
  }

  const updateUser = async (updates) => {
    try {
      const updatedUser = await userService.update(userId, updates)
      user.value = updatedUser
      return updatedUser
    } catch (err) {
      error.value = err
      throw err
    }
  }

  const deleteUser = async () => {
    try {
      await userService.delete(userId)
      user.value = null
    } catch (err) {
      error.value = err
      throw err
    }
  }

  // Computed properties
  const isVip = computed(() => {
    return user.value?.subscription === 'premium'
  })

  const fullName = computed(() => {
    if (!user.value) return ''
    return `${user.value.firstName} ${user.value.lastName}`
  })

  // Watch for userId changes
  watch(() => userId, fetchUser, { immediate: true })

  return {
    user: readonly(user),
    loading: readonly(loading),
    error: readonly(error),
    isVip,
    fullName,
    updateUser,
    deleteUser,
    refetch: fetchUser
  }
}
```

### Advanced Composable with Lifecycle
```js
// composables/useApiData.js
import { ref, computed, onMounted, onUnmounted } from 'vue'

export function useApiData(url, options = {}) {
  const data = ref(null)
  const loading = ref(false)
  const error = ref(null)
  const abortController = ref(null)

  const {
    immediate = true,
    pollInterval = null,
    onSuccess = null,
    onError = null,
    transform = (data) => data
  } = options

  let intervalId = null

  const fetchData = async () => {
    try {
      loading.value = true
      error.value = null

      // Cancel previous request
      if (abortController.value) {
        abortController.value.abort()
      }

      abortController.value = new AbortController()

      const response = await fetch(url, {
        signal: abortController.value.signal
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()
      data.value = transform(result)

      if (onSuccess) {
        onSuccess(data.value)
      }
    } catch (err) {
      if (err.name !== 'AbortError') {
        error.value = err
        if (onError) {
          onError(err)
        }
      }
    } finally {
      loading.value = false
      abortController.value = null
    }
  }

  const startPolling = () => {
    if (pollInterval && !intervalId) {
      intervalId = setInterval(fetchData, pollInterval)
    }
  }

  const stopPolling = () => {
    if (intervalId) {
      clearInterval(intervalId)
      intervalId = null
    }
  }

  // Computed properties
  const hasData = computed(() => data.value !== null)
  const isEmpty = computed(() => {
    if (!data.value) return true
    if (Array.isArray(data.value)) return data.value.length === 0
    if (typeof data.value === 'object') return Object.keys(data.value).length === 0
    return false
  })

  // Lifecycle
  onMounted(() => {
    if (immediate) {
      fetchData()
    }
    if (pollInterval) {
      startPolling()
    }
  })

  onUnmounted(() => {
    stopPolling()
    if (abortController.value) {
      abortController.value.abort()
    }
  })

  return {
    data: readonly(data),
    loading: readonly(loading),
    error: readonly(error),
    hasData,
    isEmpty,
    refetch: fetchData,
    startPolling,
    stopPolling
  }
}

// Usage example:
/*
<script setup>
import { useApiData } from '@/composables/useApiData'

const { data: users, loading, error, refetch } = useApiData('/api/users', {
  pollInterval: 30000, // Poll every 30 seconds
  transform: (data) => data.users, // Extract users array
  onSuccess: (users) => console.log(`Loaded ${users.length} users`),
  onError: (err) => console.error('Failed to load users:', err)
})
</script>
*/
```

## 🗃️ State Management with Pinia

### Basic Pinia Store
```js
// stores/userStore.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { userService } from '@/services/userService'

export const useUserStore = defineStore('user', () => {
  // State
  const users = ref([])
  const currentUser = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Getters (computed)
  const userCount = computed(() => users.value.length)
  
  const activeUsers = computed(() => 
    users.value.filter(user => user.status === 'active')
  )
  
  const getUserById = computed(() => {
    return (id) => users.value.find(user => user.id === id)
  })

  const isLoggedIn = computed(() => currentUser.value !== null)

  // Actions
  const fetchUsers = async () => {
    try {
      loading.value = true
      error.value = null
      const data = await userService.getAll()
      users.value = data
    } catch (err) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const createUser = async (userData) => {
    try {
      const newUser = await userService.create(userData)
      users.value.push(newUser)
      return newUser
    } catch (err) {
      error.value = err.message
      throw err
    }
  }

  const updateUser = async (id, updates) => {
    try {
      const updatedUser = await userService.update(id, updates)
      const index = users.value.findIndex(user => user.id === id)
      if (index !== -1) {
        users.value[index] = updatedUser
      }
      
      // Update current user if it's the same
      if (currentUser.value?.id === id) {
        currentUser.value = updatedUser
      }
      
      return updatedUser
    } catch (err) {
      error.value = err.message
      throw err
    }
  }

  const deleteUser = async (id) => {
    try {
      await userService.delete(id)
      users.value = users.value.filter(user => user.id !== id)
      
      // Clear current user if deleted
      if (currentUser.value?.id === id) {
        currentUser.value = null
      }
    } catch (err) {
      error.value = err.message
      throw err
    }
  }

  const login = async (credentials) => {
    try {
      loading.value = true
      const user = await userService.login(credentials)
      currentUser.value = user
      return user
    } catch (err) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    try {
      await userService.logout()
    } finally {
      currentUser.value = null
    }
  }

  const clearError = () => {
    error.value = null
  }

  // Reset store state
  const $reset = () => {
    users.value = []
    currentUser.value = null
    loading.value = false
    error.value = null
  }

  return {
    // State
    users: readonly(users),
    currentUser: readonly(currentUser),
    loading: readonly(loading),
    error: readonly(error),
    
    // Getters
    userCount,
    activeUsers,
    getUserById,
    isLoggedIn,
    
    // Actions
    fetchUsers,
    createUser,
    updateUser,
    deleteUser,
    login,
    logout,
    clearError,
    $reset
  }
})
```

### Store with Persistence
```js
// stores/settingsStore.js
import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

export const useSettingsStore = defineStore('settings', () => {
  // Load from localStorage
  const loadFromStorage = (key, defaultValue) => {
    try {
      const item = localStorage.getItem(key)
      return item ? JSON.parse(item) : defaultValue
    } catch {
      return defaultValue
    }
  }

  // Save to localStorage
  const saveToStorage = (key, value) => {
    try {
      localStorage.setItem(key, JSON.stringify(value))
    } catch (error) {
      console.error('Failed to save to localStorage:', error)
    }
  }

  // State with persistence
  const theme = ref(loadFromStorage('theme', 'light'))
  const language = ref(loadFromStorage('language', 'en'))
  const notifications = ref(loadFromStorage('notifications', {
    email: true,
    push: false,
    sms: false
  }))

  // Watch for changes and persist
  watch(theme, (newTheme) => {
    saveToStorage('theme', newTheme)
    document.documentElement.setAttribute('data-theme', newTheme)
  }, { immediate: true })

  watch(language, (newLanguage) => {
    saveToStorage('language', newLanguage)
  })

  watch(notifications, (newNotifications) => {
    saveToStorage('notifications', newNotifications)
  }, { deep: true })

  // Actions
  const setTheme = (newTheme) => {
    theme.value = newTheme
  }

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
  }

  const setLanguage = (newLanguage) => {
    language.value = newLanguage
  }

  const updateNotifications = (updates) => {
    notifications.value = { ...notifications.value, ...updates }
  }

  const resetSettings = () => {
    theme.value = 'light'
    language.value = 'en'
    notifications.value = {
      email: true,
      push: false,
      sms: false
    }
  }

  return {
    theme: readonly(theme),
    language: readonly(language),
    notifications: readonly(notifications),
    setTheme,
    toggleTheme,
    setLanguage,
    updateNotifications,
    resetSettings
  }
})
```

## 🎨 Advanced Component Patterns

### Renderless Component (Scoped Slots)
```vue
<!-- components/DataProvider.vue -->
<template>
  <div>
    <slot 
      :data="data"
      :loading="loading"
      :error="error"
      :refetch="refetch"
    />
  </div>
</template>

<script setup>
import { useApiData } from '@/composables/useApiData'

const props = defineProps({
  url: {
    type: String,
    required: true
  },
  pollInterval: Number,
  immediate: {
    type: Boolean,
    default: true
  }
})

const { data, loading, error, refetch } = useApiData(props.url, {
  immediate: props.immediate,
  pollInterval: props.pollInterval
})
</script>

<!-- Usage -->
<!--
<DataProvider url="/api/users" v-slot="{ data: users, loading, error, refetch }">
  <div v-if="loading">Loading users...</div>
  <div v-else-if="error">Error: {{ error.message }}</div>
  <div v-else>
    <UserList :users="users" />
    <button @click="refetch">Refresh</button>
  </div>
</DataProvider>
-->
```

### Dynamic Component with Props
```vue
<!-- components/DynamicForm.vue -->
<template>
  <form @submit.prevent="handleSubmit" class="dynamic-form">
    <div
      v-for="field in fields"
      :key="field.name"
      class="form-field"
    >
      <label :for="field.name">{{ field.label }}</label>
      
      <component
        :is="getFieldComponent(field.type)"
        :id="field.name"
        v-model="formData[field.name]"
        v-bind="field.props"
        :class="{ error: errors[field.name] }"
      />
      
      <span v-if="errors[field.name]" class="error-message">
        {{ errors[field.name] }}
      </span>
    </div>

    <div class="form-actions">
      <button type="button" @click="resetForm">Reset</button>
      <button type="submit" :disabled="isSubmitting">
        {{ isSubmitting ? 'Submitting...' : 'Submit' }}
      </button>
    </div>
  </form>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import BaseInput from './form/BaseInput.vue'
import BaseTextarea from './form/BaseTextarea.vue'
import BaseSelect from './form/BaseSelect.vue'
import BaseCheckbox from './form/BaseCheckbox.vue'

const props = defineProps({
  fields: {
    type: Array,
    required: true
  },
  initialData: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['submit'])

// Component mapping
const componentMap = {
  text: BaseInput,
  email: BaseInput,
  password: BaseInput,
  textarea: BaseTextarea,
  select: BaseSelect,
  checkbox: BaseCheckbox
}

const getFieldComponent = (type) => componentMap[type] || BaseInput

// Form state
const formData = reactive({ ...props.initialData })
const errors = ref({})
const isSubmitting = ref(false)

// Initialize form data from fields
props.fields.forEach(field => {
  if (!(field.name in formData)) {
    formData[field.name] = field.defaultValue || ''
  }
})

// Validation
const validateField = (field) => {
  const value = formData[field.name]
  
  if (field.required && (!value || value.toString().trim() === '')) {
    return `${field.label} is required`
  }
  
  if (field.minLength && value.length < field.minLength) {
    return `${field.label} must be at least ${field.minLength} characters`
  }
  
  if (field.pattern && !field.pattern.test(value)) {
    return field.patternMessage || `${field.label} format is invalid`
  }
  
  if (field.customValidator) {
    return field.customValidator(value, formData)
  }
  
  return null
}

const validateForm = () => {
  const newErrors = {}
  
  props.fields.forEach(field => {
    const error = validateField(field)
    if (error) {
      newErrors[field.name] = error
    }
  })
  
  errors.value = newErrors
  return Object.keys(newErrors).length === 0
}

// Form methods
const handleSubmit = async () => {
  if (!validateForm()) return
  
  try {
    isSubmitting.value = true
    await emit('submit', { ...formData })
  } catch (error) {
    console.error('Form submission error:', error)
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  props.fields.forEach(field => {
    formData[field.name] = field.defaultValue || ''
  })
  errors.value = {}
}

// Clear error when field value changes
const clearFieldError = (fieldName) => {
  if (errors.value[fieldName]) {
    delete errors.value[fieldName]
  }
}

// Watch for field changes to clear errors
props.fields.forEach(field => {
  watch(() => formData[field.name], () => clearFieldError(field.name))
})
</script>

<style scoped>
.dynamic-form {
  max-width: 500px;
}

.form-field {
  margin-bottom: 1rem;
}

.form-field label {
  display: block;
  margin-bottom: 0.25rem;
  font-weight: 500;
}

.error {
  border-color: #dc2626;
}

.error-message {
  color: #dc2626;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

.form-actions button {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
}

.form-actions button[type="submit"] {
  background-color: #3b82f6;
  color: white;
}

.form-actions button[type="button"] {
  background-color: #e5e7eb;
  color: #374151;
}
</style>

<!-- Usage Example -->
<!--
<script setup>
const formFields = [
  {
    name: 'name',
    type: 'text',
    label: 'Full Name',
    required: true,
    minLength: 2
  },
  {
    name: 'email',
    type: 'email',
    label: 'Email Address',
    required: true,
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    patternMessage: 'Please enter a valid email address'
  },
  {
    name: 'message',
    type: 'textarea',
    label: 'Message',
    required: true,
    props: { rows: 4 }
  }
]

const handleFormSubmit = async (data) => {
  console.log('Form submitted:', data)
  // Handle form submission
}
</script>

<template>
  <DynamicForm 
    :fields="formFields"
    @submit="handleFormSubmit"
  />
</template>
-->
```

## 🔧 Vue Router Patterns

### Route Configuration with Meta
```js
// router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/userStore'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue'),
    meta: {
      title: 'Home',
      requiresAuth: false
    }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('@/views/Dashboard.vue'),
    meta: {
      title: 'Dashboard',
      requiresAuth: true,
      roles: ['user', 'admin']
    }
  },
  {
    path: '/admin',
    name: 'Admin',
    component: () => import('@/views/Admin.vue'),
    meta: {
      title: 'Admin Panel',
      requiresAuth: true,
      roles: ['admin']
    }
  },
  {
    path: '/profile/:id',
    name: 'UserProfile',
    component: () => import('@/views/UserProfile.vue'),
    meta: {
      title: 'User Profile',
      requiresAuth: true
    },
    props: route => ({
      userId: Number(route.params.id),
      tab: route.query.tab || 'overview'
    })
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: {
      title: 'Login',
      requiresAuth: false,
      hideForAuth: true // Hide this route if user is already authenticated
    }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFound.vue'),
    meta: {
      title: 'Page Not Found'
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else if (to.hash) {
      return { el: to.hash, behavior: 'smooth' }
    } else {
      return { top: 0 }
    }
  }
})

// Navigation guards
router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore()
  
  // Set page title
  document.title = to.meta.title ? `${to.meta.title} - My App` : 'My App'
  
  // Check authentication requirements
  if (to.meta.requiresAuth && !userStore.isLoggedIn) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
    return
  }
  
  // Hide certain routes for authenticated users
  if (to.meta.hideForAuth && userStore.isLoggedIn) {
    next({ name: 'Dashboard' })
    return
  }
  
  // Check role-based access
  if (to.meta.roles && userStore.currentUser) {
    const userRole = userStore.currentUser.role
    if (!to.meta.roles.includes(userRole)) {
      next({ name: 'Dashboard' }) // or show 403 page
      return
    }
  }
  
  next()
})

export default router
```

### Dynamic Route Components
```vue
<!-- views/UserProfile.vue -->
<template>
  <div class="user-profile">
    <nav class="profile-nav">
      <router-link
        v-for="tab in tabs"
        :key="tab.name"
        :to="{ name: 'UserProfile', params: { id: userId }, query: { tab: tab.name } }"
        class="nav-tab"
        :class="{ active: currentTab === tab.name }"
      >
        {{ tab.label }}
      </router-link>
    </nav>

    <div class="profile-content">
      <Suspense>
        <component :is="currentTabComponent" :user-id="userId" />
        <template #fallback>
          <div class="loading">Loading tab content...</div>
        </template>
      </Suspense>
    </div>
  </div>
</template>

<script setup>
import { computed, defineAsyncComponent } from 'vue'
import { useRoute } from 'vue-router'

const props = defineProps({
  userId: {
    type: Number,
    required: true
  }
})

const route = useRoute()

// Tab configuration
const tabs = [
  { name: 'overview', label: 'Overview' },
  { name: 'posts', label: 'Posts' },
  { name: 'settings', label: 'Settings' }
]

// Current tab from route query
const currentTab = computed(() => route.query.tab || 'overview')

// Dynamic component loading
const currentTabComponent = computed(() => {
  const componentMap = {
    overview: defineAsyncComponent(() => import('@/components/profile/OverviewTab.vue')),
    posts: defineAsyncComponent(() => import('@/components/profile/PostsTab.vue')),
    settings: defineAsyncComponent(() => import('@/components/profile/SettingsTab.vue'))
  }
  
  return componentMap[currentTab.value] || componentMap.overview
})
</script>

<style scoped>
.profile-nav {
  display: flex;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 2rem;
}

.nav-tab {
  padding: 0.75rem 1rem;
  text-decoration: none;
  color: #6b7280;
  border-bottom: 2px solid transparent;
  transition: all 0.2s;
}

.nav-tab:hover {
  color: #374151;
}

.nav-tab.active {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.loading {
  text-align: center;
  padding: 2rem;
  color: #6b7280;
}
</style>
```

## 🎯 Performance Optimization

### Lazy Loading and Code Splitting
```js
// router/index.js - Route-based code splitting
const routes = [
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import(
      /* webpackChunkName: "dashboard" */ 
      '@/views/Dashboard.vue'
    )
  },
  {
    path: '/admin',
    name: 'Admin',
    component: () => import(
      /* webpackChunkName: "admin" */ 
      '@/views/Admin.vue'
    )
  }
]

// Component-based code splitting
export default defineAsyncComponent({
  loader: () => import('./HeavyComponent.vue'),
  loadingComponent: LoadingSpinner,
  errorComponent: ErrorComponent,
  delay: 200,
  timeout: 3000
})
```

### Virtual Scrolling for Large Lists
```vue
<!-- components/VirtualList.vue -->
<template>
  <div 
    ref="containerRef"
    class="virtual-list-container"
    @scroll="handleScroll"
  >
    <div 
      class="virtual-list-spacer"
      :style="{ height: `${totalHeight}px` }"
    >
      <div
        class="virtual-list-items"
        :style="{ transform: `translateY(${offsetY}px)` }"
      >
        <div
          v-for="item in visibleItems"
          :key="item.id"
          class="virtual-list-item"
          :style="{ height: `${itemHeight}px` }"
        >
          <slot :item="item" :index="item.index" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  items: {
    type: Array,
    required: true
  },
  itemHeight: {
    type: Number,
    default: 50
  },
  containerHeight: {
    type: Number,
    default: 400
  },
  overscan: {
    type: Number,
    default: 5
  }
})

const containerRef = ref(null)
const scrollTop = ref(0)

// Computed properties
const totalHeight = computed(() => props.items.length * props.itemHeight)

const visibleCount = computed(() => 
  Math.ceil(props.containerHeight / props.itemHeight)
)

const startIndex = computed(() => 
  Math.max(0, Math.floor(scrollTop.value / props.itemHeight) - props.overscan)
)

const endIndex = computed(() => 
  Math.min(
    props.items.length - 1,
    startIndex.value + visibleCount.value + props.overscan * 2
  )
)

const visibleItems = computed(() => {
  return props.items.slice(startIndex.value, endIndex.value + 1)
    .map((item, index) => ({
      ...item,
      index: startIndex.value + index
    }))
})

const offsetY = computed(() => startIndex.value * props.itemHeight)

// Methods
const handleScroll = (event) => {
  scrollTop.value = event.target.scrollTop
}

// Scroll to specific item
const scrollToItem = (index) => {
  if (containerRef.value) {
    containerRef.value.scrollTop = index * props.itemHeight
  }
}

// Expose methods
defineExpose({
  scrollToItem
})

onMounted(() => {
  if (containerRef.value) {
    containerRef.value.style.height = `${props.containerHeight}px`
  }
})
</script>

<style scoped>
.virtual-list-container {
  overflow-y: auto;
  position: relative;
}

.virtual-list-spacer {
  position: relative;
}

.virtual-list-items {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
}

.virtual-list-item {
  border-bottom: 1px solid #e5e7eb;
}
</style>

<!-- Usage -->
<!--
<VirtualList
  :items="largeDataset"
  :item-height="60"
  :container-height="500"
  v-slot="{ item, index }"
>
  <UserCard :user="item" />
</VirtualList>
-->
```

### Memoization and Reactivity Optimization
```vue
<!-- components/OptimizedComponent.vue -->
<template>
  <div class="optimized-component">
    <!-- Use v-memo for expensive list rendering -->
    <div
      v-for="item in expensiveList"
      :key="item.id"
      v-memo="[item.id, item.updatedAt]"
      class="list-item"
    >
      <ExpensiveItemComponent :item="item" />
    </div>

    <!-- Use v-once for static content -->
    <div v-once class="static-content">
      {{ expensiveComputation() }}
    </div>
  </div>
</template>

<script setup>
import { computed, shallowRef, triggerRef } from 'vue'

const props = defineProps({
  items: Array,
  filters: Object
})

// Use shallowRef for large objects that don't need deep reactivity
const cache = shallowRef(new Map())

// Memoized expensive computation
const expensiveList = computed(() => {
  const cacheKey = JSON.stringify(props.filters)
  
  if (cache.value.has(cacheKey)) {
    return cache.value.get(cacheKey)
  }
  
  // Expensive filtering/sorting operation
  const result = props.items
    .filter(item => matchesFilters(item, props.filters))
    .sort((a, b) => a.priority - b.priority)
  
  cache.value.set(cacheKey, result)
  
  // Limit cache size
  if (cache.value.size > 100) {
    const firstKey = cache.value.keys().next().value
    cache.value.delete(firstKey)
  }
  
  return result
})

// Clear cache when needed
const clearCache = () => {
  cache.value.clear()
  triggerRef(cache)
}

const matchesFilters = (item, filters) => {
  // Complex filtering logic
  return Object.entries(filters).every(([key, value]) => {
    if (!value) return true
    return item[key]?.toString().toLowerCase().includes(value.toLowerCase())
  })
}

const expensiveComputation = () => {
  // This will only run once due to v-once
  return props.items.reduce((sum, item) => sum + item.value, 0)
}
</script>
```

## 🧪 Testing Patterns

### Component Testing with Vue Test Utils
```js
// components/__tests__/UserCard.test.js
import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'
import UserCard from '../UserCard.vue'

describe('UserCard', () => {
  const mockUser = {
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
    avatar: '/avatar.jpg'
  }

  it('renders user information correctly', () => {
    const wrapper = mount(UserCard, {
      props: { user: mockUser }
    })

    expect(wrapper.text()).toContain('John Doe')
    expect(wrapper.text()).toContain('john@example.com')
    expect(wrapper.find('img').attributes('src')).toBe('/avatar.jpg')
  })

  it('emits edit event when edit button is clicked', async () => {
    const wrapper = mount(UserCard, {
      props: { user: mockUser }
    })

    await wrapper.find('[data-testid="edit-button"]').trigger('click')
    
    expect(wrapper.emitted('edit')).toBeTruthy()
    expect(wrapper.emitted('edit')[0]).toEqual([mockUser.id])
  })

  it('shows loading state when user is null', () => {
    const wrapper = mount(UserCard, {
      props: { user: null }
    })

    expect(wrapper.find('[data-testid="loading"]').exists()).toBe(true)
  })
})
```

### Composable Testing
```js
// composables/__tests__/useCounter.test.js
import { ref } from 'vue'
import { describe, it, expect } from 'vitest'
import { useCounter } from '../useCounter'

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { count, increment, decrement } = useCounter()
    expect(count.value).toBe(0)
  })

  it('initializes with custom value', () => {
    const { count } = useCounter(10)
    expect(count.value).toBe(10)
  })

  it('increments count', () => {
    const { count, increment } = useCounter(0)
    increment()
    expect(count.value).toBe(1)
  })

  it('decrements count', () => {
    const { count, decrement } = useCounter(5)
    decrement()
    expect(count.value).toBe(4)
  })

  it('resets count to initial value', () => {
    const { count, increment, reset } = useCounter(3)
    increment()
    increment()
    expect(count.value).toBe(5)
    
    reset()
    expect(count.value).toBe(3)
  })
})
```

## 🛠️ Development Tools

### Vite Configuration
```js
// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@components': resolve(__dirname, 'src/components'),
      '@views': resolve(__dirname, 'src/views'),
      '@stores': resolve(__dirname, 'src/stores'),
      '@composables': resolve(__dirname, 'src/composables')
    }
  },
  
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/styles/variables.scss";`
      }
    }
  },
  
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia'],
          ui: ['@headlessui/vue', 'heroicons/vue']
        }
      }
    }
  },
  
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
})
```

### TypeScript Setup
```ts
// types/index.ts
export interface User {
  id: number
  name: string
  email: string
  avatar?: string
  role: 'user' | 'admin'
  createdAt: string
  updatedAt: string
}

export interface ApiResponse<T> {
  data: T
  message: string
  success: boolean
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
}

// Component prop types
export interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  loading?: boolean
}
```

```vue
<!-- TypeScript component example -->
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { User, ButtonProps } from '@/types'

interface Props {
  user: User
  variant?: ButtonProps['variant']
}

interface Emits {
  (e: 'edit', userId: number): void
  (e: 'delete', userId: number): void
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary'
})

const emit = defineEmits<Emits>()

const isEditing = ref(false)

const displayName = computed((): string => {
  return `${props.user.name} (${props.user.role})`
})

const handleEdit = (): void => {
  isEditing.value = true
  emit('edit', props.user.id)
}
</script>
```

## 🛠️ Best Practices Summary

### 1. Component Design
- Use Composition API for better logic reuse and TypeScript support
- Keep components small and focused on single responsibility
- Use props and emits properly with TypeScript types
- Prefer composition over mixins
- Use scoped slots for flexible, reusable components

### 2. Performance
- Use `v-memo` for expensive list items
- Implement virtual scrolling for large datasets
- Lazy load routes and heavy components
- Use `shallowRef` and `shallowReactive` when appropriate
- Optimize computed properties and watchers

### 3. State Management
- Start with Composition API for local state
- Use Pinia for global state management
- Keep stores focused and modular
- Implement proper error handling in stores
- Use TypeScript for better store typing

### 4. Reactivity
- Understand the difference between `ref` and `reactive`
- Use `readonly` to prevent unwanted mutations
- Be careful with destructuring reactive objects
- Use `toRefs` when destructuring reactive objects
- Prefer `computed` over methods for derived state

### 5. Developer Experience
- Use TypeScript for better development experience
- Set up proper ESLint and Prettier configuration
- Use Vue DevTools for debugging
- Write tests for critical functionality
- Implement proper error boundaries

---

*Vue 3 with Composition API provides excellent developer experience and performance. Following these patterns ensures maintainable, scalable, and efficient applications.*
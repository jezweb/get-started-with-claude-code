# Frontend State Management Patterns

Comprehensive guide to state management patterns across different frontend frameworks, covering client-side state, server state, and application architecture.

## 🎯 State Management Overview

Frontend state management involves organizing and sharing data across components:
- **Local State** - Component-specific state
- **Global State** - Application-wide state  
- **Server State** - Data from APIs (caching, synchronization)
- **URL State** - Route parameters and query strings
- **Form State** - Form data and validation

## 🚀 React State Management

### Built-in State Management

#### useState Hook
```jsx
// components/Counter.jsx
import { useState } from 'react'

export function Counter() {
  const [count, setCount] = useState(0)
  const [user, setUser] = useState(null)

  // Update patterns
  const increment = () => setCount(prev => prev + 1)
  const updateUser = (updates) => setUser(prev => ({ ...prev, ...updates }))

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>Increment</button>
      
      {user && <p>Welcome, {user.name}!</p>}
      <button onClick={() => updateUser({ name: 'John' })}>
        Set User
      </button>
    </div>
  )
}
```

#### useReducer Hook
```jsx
// hooks/useShoppingCart.js
import { useReducer } from 'react'

const cartReducer = (state, action) => {
  switch (action.type) {
    case 'ADD_ITEM':
      const existingItem = state.items.find(item => item.id === action.payload.id)
      if (existingItem) {
        return {
          ...state,
          items: state.items.map(item =>
            item.id === action.payload.id
              ? { ...item, quantity: item.quantity + 1 }
              : item
          )
        }
      }
      return {
        ...state,
        items: [...state.items, { ...action.payload, quantity: 1 }]
      }

    case 'REMOVE_ITEM':
      return {
        ...state,
        items: state.items.filter(item => item.id !== action.payload.id)
      }

    case 'UPDATE_QUANTITY':
      return {
        ...state,
        items: state.items.map(item =>
          item.id === action.payload.id
            ? { ...item, quantity: action.payload.quantity }
            : item
        )
      }

    case 'CLEAR_CART':
      return { ...state, items: [] }

    default:
      throw new Error(`Unknown action type: ${action.type}`)
  }
}

const initialState = {
  items: [],
  total: 0
}

export function useShoppingCart() {
  const [state, dispatch] = useReducer(cartReducer, initialState)

  // Calculate total whenever items change
  const total = state.items.reduce((sum, item) => sum + (item.price * item.quantity), 0)

  const addItem = (item) => dispatch({ type: 'ADD_ITEM', payload: item })
  const removeItem = (id) => dispatch({ type: 'REMOVE_ITEM', payload: { id } })
  const updateQuantity = (id, quantity) => dispatch({ 
    type: 'UPDATE_QUANTITY', 
    payload: { id, quantity } 
  })
  const clearCart = () => dispatch({ type: 'CLEAR_CART' })

  return {
    items: state.items,
    total,
    addItem,
    removeItem,
    updateQuantity,
    clearCart
  }
}
```

#### Context API
```jsx
// contexts/AuthContext.jsx
import { createContext, useContext, useReducer, useEffect } from 'react'

const AuthContext = createContext()

const authReducer = (state, action) => {
  switch (action.type) {
    case 'LOGIN_START':
      return { ...state, loading: true, error: null }
    case 'LOGIN_SUCCESS':
      return { ...state, loading: false, user: action.payload, isAuthenticated: true }
    case 'LOGIN_ERROR':
      return { ...state, loading: false, error: action.payload, isAuthenticated: false }
    case 'LOGOUT':
      return { ...state, user: null, isAuthenticated: false }
    default:
      return state
  }
}

const initialState = {
  user: null,
  isAuthenticated: false,
  loading: false,
  error: null
}

export function AuthProvider({ children }) {
  const [state, dispatch] = useReducer(authReducer, initialState)

  useEffect(() => {
    // Check for stored auth token on mount
    const token = localStorage.getItem('authToken')
    if (token) {
      // Validate token and restore user session
      validateToken(token)
    }
  }, [])

  const login = async (credentials) => {
    dispatch({ type: 'LOGIN_START' })
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials)
      })
      
      if (!response.ok) throw new Error('Login failed')
      
      const data = await response.json()
      localStorage.setItem('authToken', data.token)
      dispatch({ type: 'LOGIN_SUCCESS', payload: data.user })
    } catch (error) {
      dispatch({ type: 'LOGIN_ERROR', payload: error.message })
    }
  }

  const logout = () => {
    localStorage.removeItem('authToken')
    dispatch({ type: 'LOGOUT' })
  }

  const validateToken = async (token) => {
    try {
      const response = await fetch('/api/auth/verify', {
        headers: { Authorization: `Bearer ${token}` }
      })
      
      if (response.ok) {
        const data = await response.json()
        dispatch({ type: 'LOGIN_SUCCESS', payload: data.user })
      } else {
        localStorage.removeItem('authToken')
      }
    } catch (error) {
      localStorage.removeItem('authToken')
    }
  }

  return (
    <AuthContext.Provider value={{ ...state, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
```

### Zustand (Lightweight State Management)

```javascript
// stores/useUserStore.js
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

export const useUserStore = create(
  persist(
    (set, get) => ({
      // State
      user: null,
      preferences: {
        theme: 'light',
        language: 'en',
        notifications: true
      },
      
      // Actions
      setUser: (user) => set({ user }),
      
      updatePreferences: (newPreferences) => 
        set((state) => ({
          preferences: { ...state.preferences, ...newPreferences }
        })),
      
      logout: () => set({ user: null }),
      
      // Computed values (getters)
      get isAuthenticated() {
        return get().user !== null
      },
      
      get fullName() {
        const user = get().user
        return user ? `${user.firstName} ${user.lastName}` : ''
      }
    }),
    {
      name: 'user-storage',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({ 
        user: state.user, 
        preferences: state.preferences 
      })
    }
  )
)

// stores/useCartStore.js
export const useCartStore = create((set, get) => ({
  items: [],
  
  addItem: (product) => set((state) => {
    const existingItem = state.items.find(item => item.id === product.id)
    if (existingItem) {
      return {
        items: state.items.map(item =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        )
      }
    }
    return { items: [...state.items, { ...product, quantity: 1 }] }
  }),
  
  removeItem: (id) => set((state) => ({
    items: state.items.filter(item => item.id !== id)
  })),
  
  updateQuantity: (id, quantity) => set((state) => ({
    items: state.items.map(item =>
      item.id === id ? { ...item, quantity } : item
    )
  })),
  
  clearCart: () => set({ items: [] }),
  
  get total() {
    return get().items.reduce((sum, item) => sum + (item.price * item.quantity), 0)
  },
  
  get itemCount() {
    return get().items.reduce((sum, item) => sum + item.quantity, 0)
  }
}))

// Usage in components
function CartComponent() {
  const { items, total, addItem, removeItem } = useCartStore()
  const itemCount = useCartStore(state => state.itemCount)
  
  return (
    <div>
      <h2>Cart ({itemCount} items)</h2>
      <p>Total: ${total.toFixed(2)}</p>
      {items.map(item => (
        <div key={item.id}>
          {item.name} - Qty: {item.quantity}
          <button onClick={() => removeItem(item.id)}>Remove</button>
        </div>
      ))}
    </div>
  )
}
```

### TanStack Query (Server State)

```javascript
// hooks/useUsers.js
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const userService = {
  getAll: () => fetch('/api/users').then(res => res.json()),
  getById: (id) => fetch(`/api/users/${id}`).then(res => res.json()),
  create: (user) => fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(user)
  }).then(res => res.json()),
  update: (id, user) => fetch(`/api/users/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(user)
  }).then(res => res.json()),
  delete: (id) => fetch(`/api/users/${id}`, { method: 'DELETE' })
}

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: userService.getAll,
    staleTime: 5 * 60 * 1000, // 5 minutes
    cacheTime: 10 * 60 * 1000, // 10 minutes
  })
}

export function useUser(id) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: () => userService.getById(id),
    enabled: !!id,
  })
}

export function useCreateUser() {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: userService.create,
    onSuccess: () => {
      // Invalidate and refetch users list
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
    onError: (error) => {
      console.error('Failed to create user:', error)
    }
  })
}

export function useUpdateUser() {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, ...user }) => userService.update(id, user),
    onSuccess: (data, variables) => {
      // Update the specific user in cache
      queryClient.setQueryData(['users', variables.id], data)
      // Invalidate users list to ensure consistency
      queryClient.invalidateQueries({ queryKey: ['users'] })
    }
  })
}

// Usage in component
function UsersList() {
  const { data: users, isLoading, error } = useUsers()
  const createUser = useCreateUser()
  const updateUser = useUpdateUser()

  const handleCreateUser = async (userData) => {
    try {
      await createUser.mutateAsync(userData)
      toast.success('User created successfully!')
    } catch (error) {
      toast.error('Failed to create user')
    }
  }

  if (isLoading) return <div>Loading users...</div>
  if (error) return <div>Error: {error.message}</div>

  return (
    <div>
      {users?.map(user => (
        <UserCard 
          key={user.id} 
          user={user}
          onUpdate={(updates) => updateUser.mutate({ id: user.id, ...updates })}
        />
      ))}
    </div>
  )
}
```

## 🎨 Vue State Management

### Vue 3 Composition API

```javascript
// composables/useCounter.js
import { ref, computed } from 'vue'

export function useCounter(initialValue = 0) {
  const count = ref(initialValue)
  
  const increment = () => count.value++
  const decrement = () => count.value--
  const reset = () => count.value = initialValue
  
  const isEven = computed(() => count.value % 2 === 0)
  const isPositive = computed(() => count.value > 0)
  
  return {
    count: readonly(count),
    increment,
    decrement,
    reset,
    isEven,
    isPositive
  }
}

// composables/useLocalStorage.js
import { ref, watch } from 'vue'

export function useLocalStorage(key, defaultValue) {
  const storedValue = localStorage.getItem(key)
  const initialValue = storedValue ? JSON.parse(storedValue) : defaultValue
  
  const value = ref(initialValue)
  
  watch(value, (newValue) => {
    localStorage.setItem(key, JSON.stringify(newValue))
  }, { deep: true })
  
  return value
}

// composables/useAsyncData.js
import { ref, toRefs } from 'vue'

export function useAsyncData(asyncFunction) {
  const data = ref(null)
  const loading = ref(false)
  const error = ref(null)
  
  const execute = async (...args) => {
    loading.value = true
    error.value = null
    
    try {
      data.value = await asyncFunction(...args)
    } catch (err) {
      error.value = err
    } finally {
      loading.value = false
    }
  }
  
  const reset = () => {
    data.value = null
    error.value = null
    loading.value = false
  }
  
  return {
    ...toRefs({ data, loading, error }),
    execute,
    reset
  }
}
```

### Pinia (Vue State Management)

```javascript
// stores/auth.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const token = ref(localStorage.getItem('token'))
  const loading = ref(false)
  const error = ref(null)
  
  // Getters
  const isAuthenticated = computed(() => !!user.value)
  const fullName = computed(() => 
    user.value ? `${user.value.firstName} ${user.value.lastName}` : ''
  )
  
  // Actions
  const login = async (credentials) => {
    loading.value = true
    error.value = null
    
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials)
      })
      
      if (!response.ok) throw new Error('Login failed')
      
      const data = await response.json()
      
      user.value = data.user
      token.value = data.token
      localStorage.setItem('token', data.token)
    } catch (err) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }
  
  const logout = () => {
    user.value = null
    token.value = null
    localStorage.removeItem('token')
  }
  
  const updateProfile = async (updates) => {
    try {
      const response = await fetch('/api/user/profile', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`
        },
        body: JSON.stringify(updates)
      })
      
      if (!response.ok) throw new Error('Update failed')
      
      const updatedUser = await response.json()
      user.value = { ...user.value, ...updatedUser }
    } catch (err) {
      error.value = err.message
      throw err
    }
  }
  
  return {
    user,
    token,
    loading,
    error,
    isAuthenticated,
    fullName,
    login,
    logout,
    updateProfile
  }
})

// stores/products.js
export const useProductsStore = defineStore('products', () => {
  const products = ref([])
  const loading = ref(false)
  const searchQuery = ref('')
  const selectedCategory = ref('')
  
  // Getters
  const filteredProducts = computed(() => {
    return products.value.filter(product => {
      const matchesSearch = product.name
        .toLowerCase()
        .includes(searchQuery.value.toLowerCase())
      const matchesCategory = !selectedCategory.value || 
        product.category === selectedCategory.value
      
      return matchesSearch && matchesCategory
    })
  })
  
  const categories = computed(() => {
    const cats = [...new Set(products.value.map(p => p.category))]
    return cats.sort()
  })
  
  const productById = computed(() => {
    return (id) => products.value.find(p => p.id === id)
  })
  
  // Actions
  const fetchProducts = async () => {
    loading.value = true
    try {
      const response = await fetch('/api/products')
      products.value = await response.json()
    } catch (error) {
      console.error('Failed to fetch products:', error)
    } finally {
      loading.value = false
    }
  }
  
  const addProduct = (product) => {
    products.value.push({ ...product, id: Date.now() })
  }
  
  const updateProduct = (id, updates) => {
    const index = products.value.findIndex(p => p.id === id)
    if (index !== -1) {
      products.value[index] = { ...products.value[index], ...updates }
    }
  }
  
  const deleteProduct = (id) => {
    const index = products.value.findIndex(p => p.id === id)
    if (index !== -1) {
      products.value.splice(index, 1)
    }
  }
  
  return {
    products,
    loading,
    searchQuery,
    selectedCategory,
    filteredProducts,
    categories,
    productById,
    fetchProducts,
    addProduct,
    updateProduct,
    deleteProduct
  }
})

// Usage in components
<!-- UserProfile.vue -->
<template>
  <div>
    <div v-if="authStore.loading">Loading...</div>
    <div v-else-if="authStore.isAuthenticated">
      <h1>Welcome, {{ authStore.fullName }}!</h1>
      <button @click="handleLogout">Logout</button>
    </div>
    <div v-else>
      <LoginForm @submit="handleLogin" />
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const handleLogin = async (credentials) => {
  try {
    await authStore.login(credentials)
  } catch (error) {
    console.error('Login failed:', error)
  }
}

const handleLogout = () => {
  authStore.logout()
}
</script>
```

## 🔧 Advanced Patterns

### State Machines with XState

```javascript
// machines/authMachine.js
import { createMachine, assign } from 'xstate'

export const authMachine = createMachine({
  id: 'auth',
  initial: 'idle',
  context: {
    user: null,
    error: null
  },
  states: {
    idle: {
      on: {
        LOGIN: 'authenticating',
        LOGOUT: 'loggedOut'
      }
    },
    authenticating: {
      invoke: {
        id: 'authenticate',
        src: 'authenticate',
        onDone: {
          target: 'authenticated',
          actions: assign({
            user: (context, event) => event.data.user,
            error: null
          })
        },
        onError: {
          target: 'idle',
          actions: assign({
            error: (context, event) => event.data.message
          })
        }
      }
    },
    authenticated: {
      on: {
        LOGOUT: 'loggedOut',
        UPDATE_PROFILE: 'updatingProfile'
      }
    },
    updatingProfile: {
      invoke: {
        id: 'updateProfile',
        src: 'updateProfile',
        onDone: {
          target: 'authenticated',
          actions: assign({
            user: (context, event) => ({ ...context.user, ...event.data })
          })
        },
        onError: 'authenticated'
      }
    },
    loggedOut: {
      entry: assign({
        user: null,
        error: null
      }),
      on: {
        LOGIN: 'authenticating'
      }
    }
  }
}, {
  services: {
    authenticate: async (context, event) => {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(event.credentials)
      })
      
      if (!response.ok) {
        throw new Error('Authentication failed')
      }
      
      return await response.json()
    },
    updateProfile: async (context, event) => {
      const response = await fetch('/api/user/profile', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(event.updates)
      })
      
      return await response.json()
    }
  }
})

// hooks/useAuthMachine.js
import { useMachine } from '@xstate/react'
import { authMachine } from '../machines/authMachine'

export function useAuthMachine() {
  const [state, send] = useMachine(authMachine)
  
  const login = (credentials) => send({ type: 'LOGIN', credentials })
  const logout = () => send('LOGOUT')
  const updateProfile = (updates) => send({ type: 'UPDATE_PROFILE', updates })
  
  return {
    state,
    user: state.context.user,
    error: state.context.error,
    isAuthenticated: state.matches('authenticated'),
    isLoading: state.matches('authenticating') || state.matches('updatingProfile'),
    login,
    logout,
    updateProfile
  }
}
```

### Redux Toolkit (Modern Redux)

```javascript
// store/slices/authSlice.js
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit'

// Async thunks
export const loginUser = createAsyncThunk(
  'auth/login',
  async (credentials, { rejectWithValue }) => {
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials)
      })
      
      if (!response.ok) {
        const error = await response.json()
        return rejectWithValue(error.message)
      }
      
      const data = await response.json()
      localStorage.setItem('token', data.token)
      return data
    } catch (error) {
      return rejectWithValue(error.message)
    }
  }
)

export const logoutUser = createAsyncThunk(
  'auth/logout',
  async (_, { dispatch }) => {
    localStorage.removeItem('token')
    // Additional cleanup can be performed here
  }
)

const authSlice = createSlice({
  name: 'auth',
  initialState: {
    user: null,
    token: localStorage.getItem('token'),
    loading: false,
    error: null
  },
  reducers: {
    clearError: (state) => {
      state.error = null
    },
    updateUser: (state, action) => {
      state.user = { ...state.user, ...action.payload }
    }
  },
  extraReducers: (builder) => {
    builder
      // Login
      .addCase(loginUser.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(loginUser.fulfilled, (state, action) => {
        state.loading = false
        state.user = action.payload.user
        state.token = action.payload.token
      })
      .addCase(loginUser.rejected, (state, action) => {
        state.loading = false
        state.error = action.payload
      })
      // Logout
      .addCase(logoutUser.fulfilled, (state) => {
        state.user = null
        state.token = null
      })
  }
})

export const { clearError, updateUser } = authSlice.actions
export default authSlice.reducer

// store/index.js
import { configureStore } from '@reduxjs/toolkit'
import authReducer from './slices/authSlice'
import productsReducer from './slices/productsSlice'

export const store = configureStore({
  reducer: {
    auth: authReducer,
    products: productsReducer
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST', 'persist/REHYDRATE']
      }
    })
})

export type RootState = ReturnType<typeof store.getState>
export type AppDispatch = typeof store.dispatch

// hooks/redux.ts
import { useDispatch, useSelector, TypedUseSelectorHook } from 'react-redux'
import type { RootState, AppDispatch } from '../store'

export const useAppDispatch = () => useDispatch<AppDispatch>()
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector
```

### Form State Management

```javascript
// hooks/useForm.js
import { useState, useCallback } from 'react'

export function useForm(initialValues, validationSchema) {
  const [values, setValues] = useState(initialValues)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  const setValue = useCallback((name, value) => {
    setValues(prev => ({ ...prev, [name]: value }))
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }))
    }
  }, [errors])

  const setFieldTouched = useCallback((name) => {
    setTouched(prev => ({ ...prev, [name]: true }))
  }, [])

  const validate = useCallback(() => {
    if (!validationSchema) return {}
    
    const newErrors = {}
    
    Object.keys(validationSchema).forEach(field => {
      const rules = validationSchema[field]
      const value = values[field]
      
      for (const rule of rules) {
        if (rule.required && (!value || value.toString().trim() === '')) {
          newErrors[field] = rule.message || `${field} is required`
          break
        }
        
        if (rule.pattern && value && !rule.pattern.test(value)) {
          newErrors[field] = rule.message || `${field} format is invalid`
          break
        }
        
        if (rule.minLength && value && value.length < rule.minLength) {
          newErrors[field] = rule.message || `${field} must be at least ${rule.minLength} characters`
          break
        }
        
        if (rule.custom && !rule.custom(value, values)) {
          newErrors[field] = rule.message || `${field} is invalid`
          break
        }
      }
    })
    
    return newErrors
  }, [values, validationSchema])

  const handleSubmit = useCallback(async (onSubmit) => {
    const validationErrors = validate()
    setErrors(validationErrors)
    
    // Mark all fields as touched
    const allTouched = Object.keys(values).reduce((acc, key) => {
      acc[key] = true
      return acc
    }, {})
    setTouched(allTouched)
    
    if (Object.keys(validationErrors).length === 0) {
      setIsSubmitting(true)
      try {
        await onSubmit(values)
      } catch (error) {
        console.error('Form submission error:', error)
      } finally {
        setIsSubmitting(false)
      }
    }
  }, [values, validate])

  const reset = useCallback(() => {
    setValues(initialValues)
    setErrors({})
    setTouched({})
    setIsSubmitting(false)
  }, [initialValues])

  return {
    values,
    errors,
    touched,
    isSubmitting,
    setValue,
    setFieldTouched,
    handleSubmit,
    reset,
    isValid: Object.keys(validate()).length === 0
  }
}

// Usage example
function ContactForm() {
  const { values, errors, touched, isSubmitting, setValue, setFieldTouched, handleSubmit, reset } = useForm(
    {
      name: '',
      email: '',
      message: ''
    },
    {
      name: [
        { required: true, message: 'Name is required' },
        { minLength: 2, message: 'Name must be at least 2 characters' }
      ],
      email: [
        { required: true, message: 'Email is required' },
        { pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: 'Please enter a valid email' }
      ],
      message: [
        { required: true, message: 'Message is required' },
        { minLength: 10, message: 'Message must be at least 10 characters' }
      ]
    }
  )

  const onSubmit = async (formData) => {
    const response = await fetch('/api/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    })
    
    if (response.ok) {
      alert('Message sent successfully!')
      reset()
    }
  }

  return (
    <form onSubmit={(e) => { e.preventDefault(); handleSubmit(onSubmit) }}>
      <div>
        <input
          type="text"
          placeholder="Name"
          value={values.name}
          onChange={(e) => setValue('name', e.target.value)}
          onBlur={() => setFieldTouched('name')}
        />
        {touched.name && errors.name && <span>{errors.name}</span>}
      </div>
      
      <div>
        <input
          type="email"
          placeholder="Email"
          value={values.email}
          onChange={(e) => setValue('email', e.target.value)}
          onBlur={() => setFieldTouched('email')}
        />
        {touched.email && errors.email && <span>{errors.email}</span>}
      </div>
      
      <div>
        <textarea
          placeholder="Message"
          value={values.message}
          onChange={(e) => setValue('message', e.target.value)}
          onBlur={() => setFieldTouched('message')}
        />
        {touched.message && errors.message && <span>{errors.message}</span>}
      </div>
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Sending...' : 'Send Message'}
      </button>
    </form>
  )
}
```

## 🎯 State Management Patterns

### 1. **Lifting State Up**
```jsx
// When multiple components need the same state
function ShoppingApp() {
  const [cartItems, setCartItems] = useState([])
  
  return (
    <div>
      <ProductList onAddToCart={(item) => setCartItems(prev => [...prev, item])} />
      <Cart items={cartItems} onRemove={(id) => setCartItems(prev => prev.filter(item => item.id !== id))} />
    </div>
  )
}
```

### 2. **Compound Component Pattern**
```jsx
function Accordion({ children }) {
  const [openItems, setOpenItems] = useState(new Set())
  
  const toggleItem = (id) => {
    setOpenItems(prev => {
      const newSet = new Set(prev)
      if (newSet.has(id)) {
        newSet.delete(id)
      } else {
        newSet.add(id)
      }
      return newSet
    })
  }
  
  return (
    <div className="accordion">
      {React.Children.map(children, (child, index) =>
        React.cloneElement(child, {
          isOpen: openItems.has(index),
          onToggle: () => toggleItem(index)
        })
      )}
    </div>
  )
}

function AccordionItem({ title, children, isOpen, onToggle }) {
  return (
    <div className="accordion-item">
      <button onClick={onToggle} className="accordion-header">
        {title}
      </button>
      {isOpen && (
        <div className="accordion-content">
          {children}
        </div>
      )}
    </div>
  )
}

// Usage
<Accordion>
  <AccordionItem title="Section 1">Content 1</AccordionItem>
  <AccordionItem title="Section 2">Content 2</AccordionItem>
</Accordion>
```

### 3. **Observer Pattern**
```javascript
// Simple event emitter for cross-component communication
class EventEmitter {
  constructor() {
    this.events = {}
  }
  
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = []
    }
    this.events[event].push(callback)
    
    // Return unsubscribe function
    return () => {
      this.events[event] = this.events[event].filter(cb => cb !== callback)
    }
  }
  
  emit(event, data) {
    if (this.events[event]) {
      this.events[event].forEach(callback => callback(data))
    }
  }
}

const eventBus = new EventEmitter()

// Usage in components
function NotificationProvider({ children }) {
  const [notifications, setNotifications] = useState([])
  
  useEffect(() => {
    const unsubscribe = eventBus.on('notification', (notification) => {
      setNotifications(prev => [...prev, { ...notification, id: Date.now() }])
    })
    
    return unsubscribe
  }, [])
  
  return (
    <div>
      {children}
      <div className="notifications">
        {notifications.map(notification => (
          <div key={notification.id}>{notification.message}</div>
        ))}
      </div>
    </div>
  )
}

// Emit notifications from anywhere
eventBus.emit('notification', { message: 'Success!', type: 'success' })
```

## 📚 Best Practices

### 1. **State Normalization**
```javascript
// Instead of nested data
const badState = {
  users: [
    { id: 1, name: 'John', posts: [{ id: 1, title: 'Post 1' }] },
    { id: 2, name: 'Jane', posts: [{ id: 2, title: 'Post 2' }] }
  ]
}

// Normalized state
const goodState = {
  users: {
    byId: {
      1: { id: 1, name: 'John', postIds: [1] },
      2: { id: 2, name: 'Jane', postIds: [2] }
    },
    allIds: [1, 2]
  },
  posts: {
    byId: {
      1: { id: 1, title: 'Post 1', authorId: 1 },
      2: { id: 2, title: 'Post 2', authorId: 2 }
    },
    allIds: [1, 2]
  }
}
```

### 2. **Optimistic Updates**
```javascript
function useOptimisticUpdate() {
  const [items, setItems] = useState([])
  
  const updateItem = async (id, updates) => {
    // Optimistic update
    const optimisticItems = items.map(item =>
      item.id === id ? { ...item, ...updates } : item
    )
    setItems(optimisticItems)
    
    try {
      const response = await fetch(`/api/items/${id}`, {
        method: 'PUT',
        body: JSON.stringify(updates)
      })
      
      if (!response.ok) throw new Error('Update failed')
      
      const updatedItem = await response.json()
      setItems(current => 
        current.map(item => item.id === id ? updatedItem : item)
      )
    } catch (error) {
      // Revert on error
      setItems(items)
      throw error
    }
  }
  
  return { items, updateItem }
}
```

### 3. **Error Boundaries for State**
```jsx
class StateErrorBoundary extends React.Component {
  constructor(props) {
    super(props)
    this.state = { hasError: false, error: null }
  }
  
  static getDerivedStateFromError(error) {
    return { hasError: true, error }
  }
  
  componentDidCatch(error, errorInfo) {
    console.error('State error:', error, errorInfo)
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div>
          <h2>Something went wrong with the application state.</h2>
          <button onClick={() => this.setState({ hasError: false, error: null })}>
            Try Again
          </button>
        </div>
      )
    }
    
    return this.props.children
  }
}
```

## 🔗 Integration & Testing

### Testing State Management
```javascript
// Testing Zustand stores
import { renderHook, act } from '@testing-library/react'
import { useCartStore } from '../stores/useCartStore'

describe('Cart Store', () => {
  beforeEach(() => {
    useCartStore.getState().clearCart()
  })
  
  test('should add item to cart', () => {
    const { result } = renderHook(() => useCartStore())
    
    act(() => {
      result.current.addItem({ id: 1, name: 'Product 1', price: 10 })
    })
    
    expect(result.current.items).toHaveLength(1)
    expect(result.current.total).toBe(10)
  })
  
  test('should increase quantity for existing item', () => {
    const { result } = renderHook(() => useCartStore())
    const product = { id: 1, name: 'Product 1', price: 10 }
    
    act(() => {
      result.current.addItem(product)
      result.current.addItem(product)
    })
    
    expect(result.current.items).toHaveLength(1)
    expect(result.current.items[0].quantity).toBe(2)
    expect(result.current.total).toBe(20)
  })
})

// Testing React Context
function renderWithContext(ui, { contextValue, ...renderOptions } = {}) {
  function Wrapper({ children }) {
    return (
      <AuthContext.Provider value={contextValue}>
        {children}
      </AuthContext.Provider>
    )
  }
  return render(ui, { wrapper: Wrapper, ...renderOptions })
}

test('displays user name when authenticated', () => {
  const contextValue = {
    user: { name: 'John Doe' },
    isAuthenticated: true
  }
  
  renderWithContext(<UserProfile />, { contextValue })
  
  expect(screen.getByText('Welcome, John Doe!')).toBeInTheDocument()
})
```

## 📖 Resources & References

### Documentation
- [React State Management](https://react.dev/learn/managing-state)
- [Vue 3 State Management](https://vuejs.org/guide/scaling-up/state-management.html)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [Pinia Documentation](https://pinia.vuejs.org/)
- [TanStack Query](https://tanstack.com/query/latest)
- [Redux Toolkit](https://redux-toolkit.js.org/)

### Tools & Libraries
- **React**: useState, useReducer, Context API, Zustand, Redux Toolkit
- **Vue**: Composition API, Pinia, VueX
- **Server State**: TanStack Query, SWR, Apollo Client
- **Form State**: React Hook Form, Formik, VeeValidate (Vue)
- **State Machines**: XState

---

*This guide covers modern state management patterns across frontend frameworks. Choose the right tool based on your application's complexity and requirements.*
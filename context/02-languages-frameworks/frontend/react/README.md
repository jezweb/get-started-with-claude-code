# React Modern Patterns & Best Practices

Comprehensive guide to building production-ready React applications with modern patterns, hooks, and performance optimizations.

## 🎯 What is React?

React is a JavaScript library for building user interfaces, especially web applications:
- **Component-Based** - Build encapsulated components that manage their state
- **Declarative** - Describe what the UI should look like for any given state
- **Virtual DOM** - Efficient updates and rendering
- **Ecosystem** - Rich ecosystem of tools and libraries
- **Server-Side Rendering** - Support for SSR with Next.js

## 🚀 Quick Start

### Create React App (CRA) - Simple Setup
```bash
npx create-react-app my-app
cd my-app
npm start
```

### Vite - Modern & Fast (Recommended)
```bash
npm create vite@latest my-react-app -- --template react
cd my-react-app
npm install
npm run dev
```

### Next.js - Full-Stack Framework
```bash
npx create-next-app@latest my-next-app
cd my-next-app
npm run dev
```

## 📁 Project Structure

### Modern React Project Structure
```
src/
├── components/          # Reusable UI components
│   ├── ui/             # Basic UI components (Button, Input, etc.)
│   ├── forms/          # Form-specific components
│   └── layout/         # Layout components (Header, Footer, etc.)
├── pages/              # Page components (routing)
├── hooks/              # Custom React hooks
├── context/            # React Context providers
├── services/           # API calls and external services
├── utils/              # Helper functions and utilities
├── types/              # TypeScript type definitions
├── constants/          # Application constants
├── styles/             # Global styles and themes
├── __tests__/          # Test files
├── App.jsx            # Main App component
└── main.jsx           # Entry point
```

### Component Organization
```
components/
├── Button/
│   ├── Button.jsx
│   ├── Button.test.jsx
│   ├── Button.stories.jsx    # Storybook stories
│   └── index.js             # Export file
├── UserCard/
│   ├── UserCard.jsx
│   ├── UserCard.test.jsx
│   └── index.js
└── index.js                 # Barrel exports
```

## 🎨 Modern Component Patterns

### Functional Components with Hooks
```jsx
// components/UserProfile.jsx
import React, { useState, useEffect, useCallback } from 'react';
import { useUser } from '../hooks/useUser';

const UserProfile = ({ userId }) => {
  const [isEditing, setIsEditing] = useState(false);
  const { user, loading, error, updateUser } = useUser(userId);

  const handleSave = useCallback(async (userData) => {
    try {
      await updateUser(userData);
      setIsEditing(false);
    } catch (error) {
      console.error('Failed to update user:', error);
    }
  }, [updateUser]);

  if (loading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;
  if (!user) return <div className="not-found">User not found</div>;

  return (
    <div className="user-profile">
      <div className="user-avatar">
        <img src={user.avatar} alt={`${user.name}'s avatar`} />
      </div>
      
      {isEditing ? (
        <UserEditForm 
          user={user} 
          onSave={handleSave}
          onCancel={() => setIsEditing(false)}
        />
      ) : (
        <UserDetails 
          user={user} 
          onEdit={() => setIsEditing(true)}
        />
      )}
    </div>
  );
};

export default UserProfile;
```

### Custom Hooks for Logic Reuse
```jsx
// hooks/useUser.js
import { useState, useEffect, useCallback } from 'react';
import { userService } from '../services/userService';

export const useUser = (userId) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchUser = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const userData = await userService.getById(userId);
      setUser(userData);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  const updateUser = useCallback(async (updates) => {
    try {
      const updatedUser = await userService.update(userId, updates);
      setUser(updatedUser);
      return updatedUser;
    } catch (err) {
      setError(err);
      throw err;
    }
  }, [userId]);

  useEffect(() => {
    if (userId) {
      fetchUser();
    }
  }, [fetchUser]);

  return {
    user,
    loading,
    error,
    updateUser,
    refetch: fetchUser
  };
};
```

### Context for Global State
```jsx
// context/AuthContext.jsx
import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { authService } from '../services/authService';

const AuthContext = createContext(null);

const authReducer = (state, action) => {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
    
    case 'SET_USER':
      return { 
        ...state, 
        user: action.payload, 
        isAuthenticated: !!action.payload,
        loading: false 
      };
    
    case 'SET_ERROR':
      return { ...state, error: action.payload, loading: false };
    
    case 'LOGOUT':
      return { 
        user: null, 
        isAuthenticated: false, 
        loading: false, 
        error: null 
      };
    
    default:
      return state;
  }
};

const initialState = {
  user: null,
  isAuthenticated: false,
  loading: true,
  error: null
};

export const AuthProvider = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, initialState);

  const login = async (credentials) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      const user = await authService.login(credentials);
      dispatch({ type: 'SET_USER', payload: user });
      return user;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  const logout = async () => {
    try {
      await authService.logout();
    } finally {
      dispatch({ type: 'LOGOUT' });
    }
  };

  const checkAuth = async () => {
    try {
      const user = await authService.getCurrentUser();
      dispatch({ type: 'SET_USER', payload: user });
    } catch (error) {
      dispatch({ type: 'LOGOUT' });
    }
  };

  useEffect(() => {
    checkAuth();
  }, []);

  const value = {
    ...state,
    login,
    logout,
    checkAuth
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

## 🎯 Advanced Patterns

### Compound Components
```jsx
// components/Tabs/Tabs.jsx
import React, { createContext, useContext, useState } from 'react';

const TabsContext = createContext();

const Tabs = ({ children, defaultTab = 0, onChange }) => {
  const [activeTab, setActiveTab] = useState(defaultTab);

  const handleTabChange = (index) => {
    setActiveTab(index);
    onChange?.(index);
  };

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab: handleTabChange }}>
      <div className="tabs">
        {children}
      </div>
    </TabsContext.Provider>
  );
};

const TabList = ({ children }) => (
  <div className="tab-list" role="tablist">
    {children}
  </div>
);

const Tab = ({ children, index, disabled = false }) => {
  const { activeTab, setActiveTab } = useContext(TabsContext);
  const isActive = activeTab === index;

  return (
    <button
      className={`tab ${isActive ? 'active' : ''} ${disabled ? 'disabled' : ''}`}
      role="tab"
      aria-selected={isActive}
      disabled={disabled}
      onClick={() => !disabled && setActiveTab(index)}
    >
      {children}
    </button>
  );
};

const TabPanels = ({ children }) => (
  <div className="tab-panels">
    {children}
  </div>
);

const TabPanel = ({ children, index }) => {
  const { activeTab } = useContext(TabsContext);
  const isActive = activeTab === index;

  return (
    <div 
      className={`tab-panel ${isActive ? 'active' : ''}`}
      role="tabpanel"
      hidden={!isActive}
    >
      {children}
    </div>
  );
};

// Export compound component
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panels = TabPanels;
Tabs.Panel = TabPanel;

export default Tabs;

// Usage:
/*
<Tabs defaultTab={0} onChange={(index) => console.log(index)}>
  <Tabs.List>
    <Tabs.Tab index={0}>Tab 1</Tabs.Tab>
    <Tabs.Tab index={1}>Tab 2</Tabs.Tab>
    <Tabs.Tab index={2} disabled>Tab 3</Tabs.Tab>
  </Tabs.List>
  
  <Tabs.Panels>
    <Tabs.Panel index={0}>Content 1</Tabs.Panel>
    <Tabs.Panel index={1}>Content 2</Tabs.Panel>
    <Tabs.Panel index={2}>Content 3</Tabs.Panel>
  </Tabs.Panels>
</Tabs>
*/
```

### Render Props Pattern
```jsx
// components/DataProvider.jsx
import React, { useState, useEffect } from 'react';

const DataProvider = ({ url, render, fallback, errorComponent: ErrorComponent }) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);
        
        const response = await fetch(url);
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const result = await response.json();
        setData(result);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [url]);

  if (loading) {
    return fallback || <div>Loading...</div>;
  }

  if (error) {
    return ErrorComponent ? 
      <ErrorComponent error={error} /> : 
      <div>Error: {error.message}</div>;
  }

  return render({ data, loading, error });
};

// Usage:
/*
<DataProvider 
  url="/api/users"
  render={({ data }) => (
    <UserList users={data} />
  )}
  fallback={<UserListSkeleton />}
  errorComponent={({ error }) => <ErrorAlert message={error.message} />}
/>
*/

export default DataProvider;
```

### Higher-Order Components (HOCs)
```jsx
// hocs/withAuth.jsx
import React from 'react';
import { useAuth } from '../context/AuthContext';

const withAuth = (WrappedComponent, options = {}) => {
  const { requireAuth = true, redirectTo = '/login' } = options;

  return function AuthenticatedComponent(props) {
    const { isAuthenticated, loading } = useAuth();

    if (loading) {
      return <div className="loading">Checking authentication...</div>;
    }

    if (requireAuth && !isAuthenticated) {
      // In a real app, you'd use React Router for navigation
      window.location.href = redirectTo;
      return null;
    }

    if (!requireAuth && isAuthenticated) {
      // Redirect authenticated users away from login/register pages
      window.location.href = '/dashboard';
      return null;
    }

    return <WrappedComponent {...props} />;
  };
};

// Usage:
/*
const ProtectedDashboard = withAuth(Dashboard);
const LoginPage = withAuth(Login, { requireAuth: false });
*/

export default withAuth;
```

## 🎣 Essential Hooks

### useLocalStorage Hook
```jsx
// hooks/useLocalStorage.js
import { useState, useEffect } from 'react';

export const useLocalStorage = (key, initialValue) => {
  // Get initial value from localStorage or use provided initial value
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(`Error reading localStorage key "${key}":`, error);
      return initialValue;
    }
  });

  // Update localStorage when state changes
  const setValue = (value) => {
    try {
      // Allow value to be a function so we have the same API as useState
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  };

  // Listen for changes to the localStorage key from other tabs
  useEffect(() => {
    const handleStorageChange = (e) => {
      if (e.key === key && e.newValue !== null) {
        try {
          setStoredValue(JSON.parse(e.newValue));
        } catch (error) {
          console.error(`Error parsing localStorage value for key "${key}":`, error);
        }
      }
    };

    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, [key]);

  return [storedValue, setValue];
};
```

### useDebounce Hook
```jsx
// hooks/useDebounce.js
import { useState, useEffect } from 'react';

export const useDebounce = (value, delay) => {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
};

// Usage in a search component:
/*
const SearchInput = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearchTerm = useDebounce(searchTerm, 500);

  useEffect(() => {
    if (debouncedSearchTerm) {
      // Perform search API call
      searchAPI(debouncedSearchTerm);
    }
  }, [debouncedSearchTerm]);

  return (
    <input
      type="text"
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
      placeholder="Search..."
    />
  );
};
*/
```

### useAsync Hook
```jsx
// hooks/useAsync.js
import { useState, useEffect, useCallback } from 'react';

export const useAsync = (asyncFn, dependencies = []) => {
  const [status, setStatus] = useState('idle');
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  const execute = useCallback(async (...args) => {
    setStatus('pending');
    setData(null);
    setError(null);

    try {
      const result = await asyncFn(...args);
      setData(result);
      setStatus('success');
      return result;
    } catch (error) {
      setError(error);
      setStatus('error');
      throw error;
    }
  }, dependencies);

  useEffect(() => {
    execute();
  }, [execute]);

  return {
    data,
    error,
    status,
    isIdle: status === 'idle',
    isPending: status === 'pending',
    isSuccess: status === 'success',
    isError: status === 'error',
    execute
  };
};

// Usage:
/*
const UserList = () => {
  const { data: users, isPending, isError, error } = useAsync(
    () => fetch('/api/users').then(res => res.json()),
    []
  );

  if (isPending) return <div>Loading users...</div>;
  if (isError) return <div>Error: {error.message}</div>;

  return (
    <ul>
      {users?.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
};
*/
```

## 🎨 Styling Approaches

### CSS Modules
```jsx
// components/Button/Button.module.css
.button {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.25rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.primary {
  background-color: #3b82f6;
  color: white;
}

.primary:hover {
  background-color: #2563eb;
}

.secondary {
  background-color: #e5e7eb;
  color: #374151;
}

.secondary:hover {
  background-color: #d1d5db;
}

.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

```jsx
// components/Button/Button.jsx
import styles from './Button.module.css';
import { clsx } from 'clsx';

const Button = ({ 
  children, 
  variant = 'primary', 
  disabled = false, 
  className,
  ...props 
}) => {
  return (
    <button
      className={clsx(
        styles.button,
        styles[variant],
        disabled && styles.disabled,
        className
      )}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

export default Button;
```

### Styled Components
```jsx
// components/Button/Button.styled.js
import styled, { css } from 'styled-components';

const ButtonVariants = {
  primary: css`
    background-color: #3b82f6;
    color: white;
    
    &:hover:not(:disabled) {
      background-color: #2563eb;
    }
  `,
  
  secondary: css`
    background-color: #e5e7eb;
    color: #374151;
    
    &:hover:not(:disabled) {
      background-color: #d1d5db;
    }
  `,
  
  danger: css`
    background-color: #ef4444;
    color: white;
    
    &:hover:not(:disabled) {
      background-color: #dc2626;
    }
  `
};

export const StyledButton = styled.button`
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.25rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  
  ${props => ButtonVariants[props.variant] || ButtonVariants.primary}
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  ${props => props.fullWidth && css`
    width: 100%;
  `}
`;
```

```jsx
// components/Button/Button.jsx
import { StyledButton } from './Button.styled';

const Button = ({ children, variant = 'primary', ...props }) => {
  return (
    <StyledButton variant={variant} {...props}>
      {children}
    </StyledButton>
  );
};

export default Button;
```

## 🚀 Performance Optimization

### React.memo for Component Memoization
```jsx
// components/UserCard.jsx
import React, { memo } from 'react';

const UserCard = memo(({ user, onEdit, onDelete }) => {
  console.log('UserCard rendered for:', user.name);
  
  return (
    <div className="user-card">
      <img src={user.avatar} alt={user.name} />
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      
      <div className="actions">
        <button onClick={() => onEdit(user.id)}>Edit</button>
        <button onClick={() => onDelete(user.id)}>Delete</button>
      </div>
    </div>
  );
});

UserCard.displayName = 'UserCard';

export default UserCard;
```

### useMemo and useCallback
```jsx
// components/ExpensiveComponent.jsx
import React, { useMemo, useCallback, useState } from 'react';

const ExpensiveComponent = ({ items, category, onItemSelect }) => {
  const [sortOrder, setSortOrder] = useState('asc');

  // Expensive computation - only recalculate when items or category changes
  const filteredItems = useMemo(() => {
    console.log('Filtering items...');
    return items.filter(item => item.category === category);
  }, [items, category]);

  // Expensive computation - only recalculate when filteredItems or sortOrder changes
  const sortedItems = useMemo(() => {
    console.log('Sorting items...');
    return [...filteredItems].sort((a, b) => {
      const comparison = a.name.localeCompare(b.name);
      return sortOrder === 'asc' ? comparison : -comparison;
    });
  }, [filteredItems, sortOrder]);

  // Stable callback reference
  const handleItemClick = useCallback((item) => {
    onItemSelect(item);
  }, [onItemSelect]);

  const handleSortToggle = useCallback(() => {
    setSortOrder(prev => prev === 'asc' ? 'desc' : 'asc');
  }, []);

  return (
    <div>
      <button onClick={handleSortToggle}>
        Sort: {sortOrder.toUpperCase()}
      </button>
      
      <ul>
        {sortedItems.map(item => (
          <li key={item.id} onClick={() => handleItemClick(item)}>
            {item.name}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default ExpensiveComponent;
```

### Code Splitting with React.lazy
```jsx
// App.jsx
import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ErrorBoundary from './components/ErrorBoundary';
import LoadingSpinner from './components/LoadingSpinner';

// Lazy load components
const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const UserProfile = lazy(() => import('./pages/UserProfile'));
const Settings = lazy(() => import('./pages/Settings'));

// Preload components that are likely to be needed soon
const preloadDashboard = () => import('./pages/Dashboard');
const preloadSettings = () => import('./pages/Settings');

const App = () => {
  return (
    <ErrorBoundary>
      <Router>
        <div className="app">
          <nav>
            <Link 
              to="/dashboard" 
              onMouseEnter={preloadDashboard} // Preload on hover
            >
              Dashboard
            </Link>
            <Link 
              to="/settings"
              onMouseEnter={preloadSettings}
            >
              Settings
            </Link>
          </nav>

          <main>
            <Suspense fallback={<LoadingSpinner />}>
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/profile/:id" element={<UserProfile />} />
                <Route path="/settings" element={<Settings />} />
              </Routes>
            </Suspense>
          </main>
        </div>
      </Router>
    </ErrorBoundary>
  );
};

export default App;
```

## 🔄 State Management

### useState for Local State
```jsx
// components/ContactForm.jsx
import React, { useState } from 'react';

const ContactForm = ({ onSubmit }) => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: ''
  });
  
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    
    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }
    
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }
    
    if (!formData.message.trim()) {
      newErrors.message = 'Message is required';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    try {
      setIsSubmitting(true);
      await onSubmit(formData);
      setFormData({ name: '', email: '', message: '' });
    } catch (error) {
      setErrors({ submit: error.message });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="contact-form">
      <div className="form-group">
        <label htmlFor="name">Name</label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleChange}
          className={errors.name ? 'error' : ''}
        />
        {errors.name && <span className="error-message">{errors.name}</span>}
      </div>

      <div className="form-group">
        <label htmlFor="email">Email</label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          className={errors.email ? 'error' : ''}
        />
        {errors.email && <span className="error-message">{errors.email}</span>}
      </div>

      <div className="form-group">
        <label htmlFor="message">Message</label>
        <textarea
          id="message"
          name="message"
          rows={4}
          value={formData.message}
          onChange={handleChange}
          className={errors.message ? 'error' : ''}
        />
        {errors.message && <span className="error-message">{errors.message}</span>}
      </div>

      {errors.submit && (
        <div className="error-message">{errors.submit}</div>
      )}

      <button 
        type="submit" 
        disabled={isSubmitting}
        className="submit-button"
      >
        {isSubmitting ? 'Sending...' : 'Send Message'}
      </button>
    </form>
  );
};

export default ContactForm;
```

### useReducer for Complex State
```jsx
// hooks/useShoppingCart.js
import { useReducer } from 'react';

const cartReducer = (state, action) => {
  switch (action.type) {
    case 'ADD_ITEM':
      const existingItem = state.items.find(item => item.id === action.payload.id);
      
      if (existingItem) {
        return {
          ...state,
          items: state.items.map(item =>
            item.id === action.payload.id
              ? { ...item, quantity: item.quantity + 1 }
              : item
          )
        };
      }
      
      return {
        ...state,
        items: [...state.items, { ...action.payload, quantity: 1 }]
      };

    case 'REMOVE_ITEM':
      return {
        ...state,
        items: state.items.filter(item => item.id !== action.payload)
      };

    case 'UPDATE_QUANTITY':
      return {
        ...state,
        items: state.items.map(item =>
          item.id === action.payload.id
            ? { ...item, quantity: Math.max(0, action.payload.quantity) }
            : item
        ).filter(item => item.quantity > 0)
      };

    case 'CLEAR_CART':
      return {
        ...state,
        items: []
      };

    case 'APPLY_DISCOUNT':
      return {
        ...state,
        discount: action.payload
      };

    default:
      return state;
  }
};

const initialState = {
  items: [],
  discount: 0
};

export const useShoppingCart = () => {
  const [state, dispatch] = useReducer(cartReducer, initialState);

  const addItem = (item) => {
    dispatch({ type: 'ADD_ITEM', payload: item });
  };

  const removeItem = (itemId) => {
    dispatch({ type: 'REMOVE_ITEM', payload: itemId });
  };

  const updateQuantity = (itemId, quantity) => {
    dispatch({ type: 'UPDATE_QUANTITY', payload: { id: itemId, quantity } });
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
  };

  const applyDiscount = (discount) => {
    dispatch({ type: 'APPLY_DISCOUNT', payload: discount });
  };

  const getTotalPrice = () => {
    const subtotal = state.items.reduce((total, item) => {
      return total + (item.price * item.quantity);
    }, 0);
    
    return subtotal - (subtotal * state.discount / 100);
  };

  const getTotalItems = () => {
    return state.items.reduce((total, item) => total + item.quantity, 0);
  };

  return {
    items: state.items,
    discount: state.discount,
    addItem,
    removeItem,
    updateQuantity,
    clearCart,
    applyDiscount,
    getTotalPrice,
    getTotalItems
  };
};
```

## 🔧 Development Tools

### Error Boundary
```jsx
// components/ErrorBoundary.jsx
import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    this.setState({
      error,
      errorInfo
    });

    // Log error to monitoring service
    console.error('Error caught by boundary:', error, errorInfo);
    
    // In production, send to error reporting service
    if (process.env.NODE_ENV === 'production') {
      // errorReportingService.captureException(error, { extra: errorInfo });
    }
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <h2>Something went wrong</h2>
          <p>We're sorry, but something unexpected happened.</p>
          
          {process.env.NODE_ENV === 'development' && (
            <details style={{ whiteSpace: 'pre-wrap', marginTop: '1rem' }}>
              <summary>Error Details (Development Only)</summary>
              <p><strong>Error:</strong> {this.state.error && this.state.error.toString()}</p>
              <p><strong>Stack Trace:</strong></p>
              <pre>{this.state.errorInfo.componentStack}</pre>
            </details>
          )}
          
          <button onClick={this.handleReset} className="retry-button">
            Try Again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
```

### Development Environment Setup
```jsx
// utils/devTools.js
export const isDevelopment = process.env.NODE_ENV === 'development';

// React DevTools enhancement
if (isDevelopment && typeof window !== 'undefined') {
  // Add helpful debugging utilities to window object
  window.React = React;
  
  // Component tree inspector
  window.inspectComponents = () => {
    console.log('React DevTools available in browser extension');
  };
}

// Performance profiling
export const withProfiler = (Component, id) => {
  if (!isDevelopment) return Component;
  
  return React.forwardRef((props, ref) => (
    <React.Profiler
      id={id}
      onRender={(id, phase, actualDuration, baseDuration, startTime, commitTime) => {
        console.log(`Profiler [${id}]:`, {
          phase,
          actualDuration,
          baseDuration,
          startTime,
          commitTime
        });
      }}
    >
      <Component {...props} ref={ref} />
    </React.Profiler>
  ));
};

// Usage:
// export default withProfiler(MyComponent, 'MyComponent');
```

## 🧪 Testing Patterns

### Component Testing with React Testing Library
```jsx
// components/__tests__/Button.test.jsx
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Button from '../Button';

describe('Button Component', () => {
  test('renders button with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  test('calls onClick handler when clicked', async () => {
    const handleClick = jest.fn();
    const user = userEvent.setup();
    
    render(<Button onClick={handleClick}>Click me</Button>);
    
    await user.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  test('applies correct CSS class for variant', () => {
    render(<Button variant="secondary">Secondary Button</Button>);
    expect(screen.getByRole('button')).toHaveClass('secondary');
  });

  test('is disabled when disabled prop is true', () => {
    render(<Button disabled>Disabled Button</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  test('does not call onClick when disabled', async () => {
    const handleClick = jest.fn();
    const user = userEvent.setup();
    
    render(<Button onClick={handleClick} disabled>Disabled Button</Button>);
    
    await user.click(screen.getByRole('button'));
    expect(handleClick).not.toHaveBeenCalled();
  });
});
```

### Custom Hook Testing
```jsx
// hooks/__tests__/useLocalStorage.test.js
import { renderHook, act } from '@testing-library/react';
import { useLocalStorage } from '../useLocalStorage';

// Mock localStorage
const mockLocalStorage = (() => {
  let store = {};
  return {
    getItem: jest.fn((key) => store[key] || null),
    setItem: jest.fn((key, value) => {
      store[key] = value.toString();
    }),
    removeItem: jest.fn((key) => {
      delete store[key];
    }),
    clear: jest.fn(() => {
      store = {};
    })
  };
})();

Object.defineProperty(window, 'localStorage', {
  value: mockLocalStorage
});

describe('useLocalStorage Hook', () => {
  beforeEach(() => {
    mockLocalStorage.clear();
    jest.clearAllMocks();
  });

  test('should return initial value when localStorage is empty', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));
    expect(result.current[0]).toBe('initial');
  });

  test('should return stored value from localStorage', () => {
    mockLocalStorage.setItem('test-key', JSON.stringify('stored-value'));
    
    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));
    expect(result.current[0]).toBe('stored-value');
  });

  test('should update localStorage when value changes', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 'initial'));
    
    act(() => {
      result.current[1]('new-value');
    });
    
    expect(mockLocalStorage.setItem).toHaveBeenCalledWith(
      'test-key',
      JSON.stringify('new-value')
    );
    expect(result.current[0]).toBe('new-value');
  });

  test('should handle function updater', () => {
    const { result } = renderHook(() => useLocalStorage('counter', 0));
    
    act(() => {
      result.current[1](prev => prev + 1);
    });
    
    expect(result.current[0]).toBe(1);
  });
});
```

## 🛠️ Best Practices Summary

### 1. Component Design
- Keep components small and focused on a single responsibility
- Use composition over inheritance
- Prefer functional components with hooks
- Create reusable, configurable components
- Use proper TypeScript types for better development experience

### 2. Performance
- Use React.memo for expensive components
- Implement useMemo and useCallback judiciously
- Code-split large components and routes
- Optimize images and assets
- Monitor bundle size and performance metrics

### 3. State Management
- Start with local state (useState, useReducer)
- Use Context for truly global state
- Consider external libraries (Redux, Zustand) for complex apps
- Keep state as close to where it's used as possible
- Avoid prop drilling with composition patterns

### 4. Accessibility
- Use semantic HTML elements
- Provide proper ARIA attributes
- Ensure keyboard navigation works
- Test with screen readers
- Maintain good color contrast ratios

### 5. Error Handling
- Implement Error Boundaries for graceful error recovery
- Provide meaningful error messages to users
- Log errors to monitoring services in production
- Handle loading and error states consistently
- Validate props with TypeScript or PropTypes

---

*React provides a powerful foundation for building modern user interfaces. Following these patterns and best practices ensures maintainable, performant, and accessible applications.*
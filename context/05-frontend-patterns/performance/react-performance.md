# React Performance Optimization

Advanced techniques and patterns for optimizing React applications for maximum performance.

## Memoization Strategies

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

## Code Splitting & Lazy Loading

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

## Virtual Scrolling

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

## State Management Optimization

```jsx
// Context optimization with useMemo
const AppContext = createContext()

function AppProvider({ children }) {
  const [user, setUser] = useState(null)
  const [theme, setTheme] = useState('light')
  const [preferences, setPreferences] = useState({})
  
  // Split contexts to avoid unnecessary re-renders
  const userValue = useMemo(() => ({ user, setUser }), [user])
  const themeValue = useMemo(() => ({ theme, setTheme }), [theme])
  const preferencesValue = useMemo(() => ({ preferences, setPreferences }), [preferences])
  
  return (
    <UserContext.Provider value={userValue}>
      <ThemeContext.Provider value={themeValue}>
        <PreferencesContext.Provider value={preferencesValue}>
          {children}
        </PreferencesContext.Provider>
      </ThemeContext.Provider>
    </UserContext.Provider>
  )
}

// Optimize Redux selectors
import { createSelector } from '@reduxjs/toolkit'

const selectTodos = state => state.todos
const selectFilter = state => state.filter

// Memoized selector
export const selectFilteredTodos = createSelector(
  [selectTodos, selectFilter],
  (todos, filter) => {
    switch (filter) {
      case 'active':
        return todos.filter(todo => !todo.completed)
      case 'completed':
        return todos.filter(todo => todo.completed)
      default:
        return todos
    }
  }
)

// Component using optimized selector
function TodoList() {
  const filteredTodos = useSelector(selectFilteredTodos)
  
  return (
    <ul>
      {filteredTodos.map(todo => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
    </ul>
  )
}
```

## React 18 Performance Features

```jsx
// Concurrent features
import { useTransition, useDeferredValue, startTransition } from 'react'

function SearchResults({ query }) {
  const [isPending, startTransition] = useTransition()
  const [results, setResults] = useState([])
  
  useEffect(() => {
    startTransition(() => {
      // This update will be interruptible
      fetchResults(query).then(setResults)
    })
  }, [query])
  
  return (
    <div style={{ opacity: isPending ? 0.5 : 1 }}>
      {results.map(result => (
        <ResultItem key={result.id} result={result} />
      ))}
    </div>
  )
}

// useDeferredValue for expensive renders
function ExpensiveFilter({ data, filter }) {
  const deferredFilter = useDeferredValue(filter)
  
  const filteredData = useMemo(() => {
    return data.filter(item => 
      item.name.toLowerCase().includes(deferredFilter.toLowerCase())
    )
  }, [data, deferredFilter])
  
  return <DataList data={filteredData} />
}

// Automatic batching
function Component() {
  const [count, setCount] = useState(0)
  const [flag, setFlag] = useState(false)
  
  // These updates will be batched automatically in React 18
  setTimeout(() => {
    setCount(c => c + 1)
    setFlag(f => !f)
    // Only one re-render
  }, 1000)
}
```

## Render Optimization Patterns

```jsx
// Prevent unnecessary renders with proper key usage
function ItemList({ items }) {
  return (
    <div>
      {items.map(item => (
        // Use stable, unique keys
        <Item key={item.id} {...item} />
      ))}
    </div>
  )
}

// Optimize conditional rendering
function ConditionalComponent({ condition, data }) {
  // Bad: Creates new component on each render
  const Component = condition ? ComplexComponent : SimpleComponent
  
  // Good: Use conditional rendering
  return condition ? (
    <ComplexComponent data={data} />
  ) : (
    <SimpleComponent data={data} />
  )
}

// Avoid inline object/array creation
function Component() {
  // Bad: Creates new object on every render
  return <Child config={{ setting: 'value' }} />
  
  // Good: Define outside or memoize
  const config = useMemo(() => ({ setting: 'value' }), [])
  return <Child config={config} />
}

// Optimize event handlers
function List({ items }) {
  // Bad: Creates new function for each item
  return items.map(item => (
    <button key={item.id} onClick={() => handleClick(item.id)}>
      {item.name}
    </button>
  ))
  
  // Good: Use data attributes
  const handleClick = (e) => {
    const id = e.currentTarget.dataset.id
    // Handle click
  }
  
  return items.map(item => (
    <button key={item.id} data-id={item.id} onClick={handleClick}>
      {item.name}
    </button>
  ))
}
```

## Performance Monitoring

```jsx
// React DevTools Profiler API
import { Profiler } from 'react'

function onRenderCallback(
  id, // the "id" prop of the Profiler tree that has just committed
  phase, // either "mount" (if the tree just mounted) or "update"
  actualDuration, // time spent rendering the committed update
  baseDuration, // estimated time to render the entire subtree without memoization
  startTime, // when React began rendering this update
  commitTime, // when React committed this update
  interactions // the Set of interactions belonging to this update
) {
  // Log or send to analytics
  console.log('Profiler data:', {
    componentId: id,
    phase,
    actualDuration,
    baseDuration,
    renderTime: commitTime - startTime
  })
}

function App() {
  return (
    <Profiler id="App" onRender={onRenderCallback}>
      <Header />
      <Main />
      <Footer />
    </Profiler>
  )
}

// Custom performance hook
function usePerformanceMonitor(componentName) {
  const renderCount = useRef(0)
  const renderTime = useRef(performance.now())
  
  useEffect(() => {
    renderCount.current++
    const currentTime = performance.now()
    const timeSinceLastRender = currentTime - renderTime.current
    
    console.log(`${componentName} render #${renderCount.current}`, {
      timeSinceLastRender,
      timestamp: new Date().toISOString()
    })
    
    renderTime.current = currentTime
  })
  
  return renderCount.current
}
```
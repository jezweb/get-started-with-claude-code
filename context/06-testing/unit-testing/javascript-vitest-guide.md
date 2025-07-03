# JavaScript Unit Testing with Vitest

Modern, fast unit testing for JavaScript/TypeScript applications using Vitest, the next-generation testing framework built for Vite.

## 🚀 Quick Start

### Installation
```bash
# Install Vitest and testing utilities
npm install -D vitest @vitest/ui
npm install -D jsdom @testing-library/dom
npm install -D @testing-library/user-event

# For React testing
npm install -D @testing-library/react

# For Vue testing  
npm install -D @testing-library/vue @vue/test-utils
```

### Basic Configuration
```javascript
// vitest.config.js
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
      ],
    },
  },
})
```

### Test Setup File
```typescript
// src/test/setup.ts
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

// Extend Vitest's expect with Testing Library matchers
expect.extend(matchers)

// Clean up after each test
afterEach(() => {
  cleanup()
})
```

## 📁 Project Structure

```
project/
├── src/
│   ├── components/
│   │   ├── Button.tsx
│   │   └── __tests__/
│   │       └── Button.test.tsx
│   ├── utils/
│   │   ├── math.ts
│   │   └── __tests__/
│   │       └── math.test.ts
│   └── test/
│       ├── setup.ts
│       └── mocks/
├── vitest.config.js
└── package.json
```

## 🧪 Basic Testing Patterns

### Simple Function Testing
```typescript
// src/utils/math.ts
export function add(a: number, b: number): number {
  return a + b
}

export function divide(a: number, b: number): number {
  if (b === 0) {
    throw new Error('Division by zero')
  }
  return a / b
}

// src/utils/__tests__/math.test.ts
import { describe, it, expect } from 'vitest'
import { add, divide } from '../math'

describe('Math utilities', () => {
  it('should add two numbers correctly', () => {
    expect(add(2, 3)).toBe(5)
    expect(add(-1, 1)).toBe(0)
  })

  it('should divide numbers correctly', () => {
    expect(divide(10, 2)).toBe(5)
    expect(divide(7, 2)).toBe(3.5)
  })

  it('should throw error when dividing by zero', () => {
    expect(() => divide(10, 0)).toThrow('Division by zero')
  })
})
```

### Async Function Testing
```typescript
// src/api/users.ts
export async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`)
  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.status}`)
  }
  return response.json()
}

// src/api/__tests__/users.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fetchUser } from '../users'

// Mock fetch globally
global.fetch = vi.fn()

describe('User API', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('should fetch user successfully', async () => {
    const mockUser = { id: 1, name: 'John Doe', email: 'john@example.com' }
    
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockUser),
    } as Response)

    const user = await fetchUser(1)
    
    expect(fetch).toHaveBeenCalledWith('/api/users/1')
    expect(user).toEqual(mockUser)
  })

  it('should throw error on failed request', async () => {
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: false,
      status: 404,
    } as Response)

    await expect(fetchUser(999)).rejects.toThrow('Failed to fetch user: 404')
  })
})
```

## ⚛️ React Component Testing

### Basic Component Testing
```tsx
// src/components/Button.tsx
import React from 'react'

interface ButtonProps {
  children: React.ReactNode
  onClick?: () => void
  variant?: 'primary' | 'secondary'
  disabled?: boolean
}

export function Button({ 
  children, 
  onClick, 
  variant = 'primary', 
  disabled = false 
}: ButtonProps) {
  return (
    <button
      className={`btn btn-${variant}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  )
}

// src/components/__tests__/Button.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from '../Button'

describe('Button', () => {
  it('renders button with text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument()
  })

  it('applies correct variant class', () => {
    render(<Button variant="secondary">Secondary</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('btn-secondary')
  })

  it('handles click events', async () => {
    const handleClick = vi.fn()
    const user = userEvent.setup()
    
    render(<Button onClick={handleClick}>Click me</Button>)
    
    await user.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledOnce()
  })

  it('does not trigger onClick when disabled', async () => {
    const handleClick = vi.fn()
    const user = userEvent.setup()
    
    render(
      <Button onClick={handleClick} disabled>
        Disabled
      </Button>
    )
    
    await user.click(screen.getByRole('button'))
    expect(handleClick).not.toHaveBeenCalled()
  })
})
```

### Testing Hooks
```typescript
// src/hooks/useCounter.ts
import { useState, useCallback } from 'react'

export function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue)

  const increment = useCallback(() => {
    setCount(prev => prev + 1)
  }, [])

  const decrement = useCallback(() => {
    setCount(prev => prev - 1)
  }, [])

  const reset = useCallback(() => {
    setCount(initialValue)
  }, [initialValue])

  return { count, increment, decrement, reset }
}

// src/hooks/__tests__/useCounter.test.ts
import { describe, it, expect } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useCounter } from '../useCounter'

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter())
    expect(result.current.count).toBe(0)
  })

  it('initializes with custom value', () => {
    const { result } = renderHook(() => useCounter(5))
    expect(result.current.count).toBe(5)
  })

  it('increments count', () => {
    const { result } = renderHook(() => useCounter())
    
    act(() => {
      result.current.increment()
    })
    
    expect(result.current.count).toBe(1)
  })

  it('decrements count', () => {
    const { result } = renderHook(() => useCounter(5))
    
    act(() => {
      result.current.decrement()
    })
    
    expect(result.current.count).toBe(4)
  })

  it('resets to initial value', () => {
    const { result } = renderHook(() => useCounter(10))
    
    act(() => {
      result.current.increment()
      result.current.increment()
    })
    
    expect(result.current.count).toBe(12)
    
    act(() => {
      result.current.reset()
    })
    
    expect(result.current.count).toBe(10)
  })
})
```

## 🎭 Mocking Strategies

### Module Mocking
```typescript
// src/services/analytics.ts
export function trackEvent(event: string, data?: Record<string, any>) {
  // Real implementation
  console.log('Tracking:', event, data)
}

// src/components/__tests__/UserForm.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

// Mock the entire module
vi.mock('../../services/analytics', () => ({
  trackEvent: vi.fn(),
}))

import { trackEvent } from '../../services/analytics'
import { UserForm } from '../UserForm'

describe('UserForm', () => {
  it('tracks form submission', async () => {
    const user = userEvent.setup()
    render(<UserForm />)
    
    await user.type(screen.getByLabelText('Name'), 'John Doe')
    await user.click(screen.getByRole('button', { name: 'Submit' }))
    
    expect(trackEvent).toHaveBeenCalledWith('form_submitted', {
      form: 'user_form',
      name: 'John Doe'
    })
  })
})
```

### Partial Mocking
```typescript
import { vi } from 'vitest'

// Mock only specific functions
vi.mock('../../utils/api', async () => {
  const actual = await vi.importActual('../../utils/api')
  return {
    ...actual,
    post: vi.fn(),
  }
})
```

### MSW (Mock Service Worker) Integration
```typescript
// src/test/mocks/handlers.ts
import { rest } from 'msw'

export const handlers = [
  rest.get('/api/users/:id', (req, res, ctx) => {
    const { id } = req.params
    return res(
      ctx.json({
        id: Number(id),
        name: 'John Doe',
        email: 'john@example.com'
      })
    )
  }),

  rest.post('/api/users', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({ id: 1, ...req.body })
    )
  }),
]

// src/test/setup.ts
import { setupServer } from 'msw/node'
import { handlers } from './mocks/handlers'

const server = setupServer(...handlers)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

## 🔄 Parametrized Tests

```typescript
import { describe, it, expect } from 'vitest'

describe('validateEmail', () => {
  it.each([
    ['valid@email.com', true],
    ['user@domain.co.uk', true],
    ['test+tag@gmail.com', true],
    ['invalid-email', false],
    ['@domain.com', false],
    ['user@', false],
    ['', false],
  ])('should validate "%s" as %s', (email, expected) => {
    expect(validateEmail(email)).toBe(expected)
  })
})

// Alternative syntax
describe('Calculator', () => {
  const testCases = [
    { a: 2, b: 3, operation: 'add', expected: 5 },
    { a: 10, b: 4, operation: 'subtract', expected: 6 },
    { a: 3, b: 7, operation: 'multiply', expected: 21 },
    { a: 15, b: 3, operation: 'divide', expected: 5 },
  ]

  testCases.forEach(({ a, b, operation, expected }) => {
    it(`should ${operation} ${a} and ${b} to get ${expected}`, () => {
      const calculator = new Calculator()
      const result = calculator[operation](a, b)
      expect(result).toBe(expected)
    })
  })
})
```

## ⚡ Performance Testing

```typescript
import { describe, it, expect, vi } from 'vitest'
import { performance } from 'perf_hooks'

describe('Performance tests', () => {
  it('should execute within time limit', () => {
    const start = performance.now()
    
    // Function under test
    const result = expensiveCalculation(1000)
    
    const end = performance.now()
    const duration = end - start
    
    expect(duration).toBeLessThan(100) // Should complete in under 100ms
    expect(result).toBeDefined()
  })

  it('should handle large datasets efficiently', () => {
    const largeArray = Array.from({ length: 10000 }, (_, i) => i)
    
    const start = performance.now()
    const result = processArray(largeArray)
    const end = performance.now()
    
    expect(end - start).toBeLessThan(50)
    expect(result).toHaveLength(10000)
  })
})
```

## 🎯 Advanced Features

### Custom Matchers
```typescript
// src/test/matchers.ts
import { expect } from 'vitest'

expect.extend({
  toBeValidEmail(received: string) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const pass = emailRegex.test(received)
    
    return {
      pass,
      message: () => 
        pass 
          ? `Expected ${received} not to be a valid email`
          : `Expected ${received} to be a valid email`
    }
  },

  toHaveBeenCalledWithObjectContaining(received: any, expected: object) {
    const calls = received.mock.calls
    const pass = calls.some((call: any[]) => 
      call.some(arg => 
        typeof arg === 'object' && 
        Object.entries(expected).every(([key, value]) => arg[key] === value)
      )
    )

    return {
      pass,
      message: () => 
        pass
          ? `Expected mock not to have been called with object containing ${JSON.stringify(expected)}`
          : `Expected mock to have been called with object containing ${JSON.stringify(expected)}`
    }
  }
})

// Usage in tests
it('validates email format', () => {
  expect('user@domain.com').toBeValidEmail()
  expect('invalid-email').not.toBeValidEmail()
})
```

### Snapshot Testing
```typescript
import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { UserCard } from '../UserCard'

describe('UserCard', () => {
  it('matches snapshot', () => {
    const user = {
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      avatar: 'https://example.com/avatar.jpg'
    }

    const { container } = render(<UserCard user={user} />)
    expect(container.firstChild).toMatchSnapshot()
  })

  it('matches inline snapshot', () => {
    const result = formatUserData({ name: 'John', age: 30 })
    expect(result).toMatchInlineSnapshot(`
      {
        "age": 30,
        "displayName": "John (30 years old)",
        "name": "John",
      }
    `)
  })
})
```

## 📊 Test Configuration

### Package.json Scripts
```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest run --coverage",
    "test:watch": "vitest --watch",
    "test:reporter": "vitest run --reporter=verbose"
  }
}
```

### Environment-Specific Configuration
```typescript
// vitest.config.integration.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    include: ['src/**/*.integration.test.{js,ts,tsx}'],
    environment: 'node',
    testTimeout: 10000,
    setupFiles: ['./src/test/integration-setup.ts'],
  },
})
```

## 🚀 CI/CD Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm run test:coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/coverage-final.json
```

## 🛠️ Best Practices

### 1. Test Organization
```typescript
// Group related tests
describe('UserService', () => {
  describe('when user exists', () => {
    it('should return user data', () => {})
    it('should include user preferences', () => {})
  })

  describe('when user does not exist', () => {
    it('should throw UserNotFound error', () => {})
    it('should log the attempt', () => {})
  })
})
```

### 2. Setup and Teardown
```typescript
import { describe, it, beforeEach, afterEach, vi } from 'vitest'

describe('Component with side effects', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  afterEach(() => {
    vi.restoreAllMocks()
    cleanup()
  })

  it('should work correctly', () => {
    // Test implementation
  })
})
```

### 3. Test Data Management
```typescript
// Test data factory
export function createUser(overrides = {}) {
  return {
    id: Math.floor(Math.random() * 1000),
    name: 'Test User',
    email: 'test@example.com',
    createdAt: new Date().toISOString(),
    ...overrides,
  }
}

// Usage
const adminUser = createUser({ role: 'admin' })
const newUser = createUser({ createdAt: new Date().toISOString() })
```

## 🔗 Resources

- [Vitest Documentation](https://vitest.dev/)
- [Testing Library](https://testing-library.com/)
- [MSW (Mock Service Worker)](https://mswjs.io/)
- [React Testing Patterns](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)

---

*Vitest brings the speed and developer experience of Vite to testing, making it the modern choice for JavaScript testing.*
# Unit Testing Patterns

Comprehensive guide to unit testing strategies, frameworks, and best practices for JavaScript/TypeScript and Python applications.

## 🎯 Unit Testing Overview

Unit testing focuses on testing individual components in isolation:
- **Fast Execution** - Tests run in milliseconds
- **Isolated Testing** - No external dependencies
- **High Coverage** - Test all code paths
- **Early Bug Detection** - Catch issues during development
- **Documentation** - Tests serve as usage examples
- **Refactoring Safety** - Confidence when changing code

## 🧪 JavaScript/TypeScript Testing

### Vitest Setup (Recommended for Vite projects)

```bash
# Install Vitest and utilities
npm install -D vitest @vitest/ui @testing-library/react @testing-library/vue
npm install -D @testing-library/jest-dom @testing-library/user-event
npm install -D jsdom happy-dom
npm install -D @vitest/coverage-v8

# For Vue projects
npm install -D @vue/test-utils

# For React projects  
npm install -D @testing-library/react-hooks
```

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()], // or react()
  test: {
    globals: true,
    environment: 'jsdom', // or 'happy-dom', 'node'
    setupFiles: './src/test/setup.ts',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/mockData/*'
      ]
    },
    include: ['src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    mockReset: true,
    restoreMocks: true
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src')
    }
  }
})

// src/test/setup.ts
import '@testing-library/jest-dom'
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react' // or vue
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

afterEach(() => {
  cleanup()
})

// Mock global objects
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn()
}))
```

### Testing Utilities and Helpers

```typescript
// src/test/utils.tsx
import { render, RenderOptions } from '@testing-library/react'
import { ReactElement } from 'react'
import { BrowserRouter } from 'react-router-dom'
import { Provider } from 'react-redux'
import { store } from '@/store'

// Custom render with providers
const AllTheProviders = ({ children }: { children: React.ReactNode }) => {
  return (
    <Provider store={store}>
      <BrowserRouter>
        {children}
      </BrowserRouter>
    </Provider>
  )
}

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options })

export * from '@testing-library/react'
export { customRender as render }

// Test data factories
export const createUser = (overrides = {}) => ({
  id: '1',
  name: 'John Doe',
  email: 'john@example.com',
  role: 'user',
  ...overrides
})

export const createPost = (overrides = {}) => ({
  id: '1',
  title: 'Test Post',
  content: 'Test content',
  authorId: '1',
  published: true,
  createdAt: new Date().toISOString(),
  ...overrides
})
```

### Component Testing Examples

```typescript
// Button.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@/test/utils'
import { Button } from './Button'

describe('Button', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button')).toHaveTextContent('Click me')
  })

  it('handles click events', () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick}>Click me</Button>)
    
    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('can be disabled', () => {
    render(<Button disabled>Click me</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })

  it('applies variant classes', () => {
    const { rerender } = render(<Button variant="primary">Click me</Button>)
    expect(screen.getByRole('button')).toHaveClass('btn-primary')
    
    rerender(<Button variant="secondary">Click me</Button>)
    expect(screen.getByRole('button')).toHaveClass('btn-secondary')
  })
})

// UserProfile.test.tsx - Testing with async data
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@/test/utils'
import { UserProfile } from './UserProfile'
import * as api from '@/services/api'

vi.mock('@/services/api')

describe('UserProfile', () => {
  const mockUser = createUser()

  beforeEach(() => {
    vi.mocked(api.getUser).mockResolvedValue(mockUser)
  })

  it('displays loading state initially', () => {
    render(<UserProfile userId="1" />)
    expect(screen.getByText(/loading/i)).toBeInTheDocument()
  })

  it('displays user data when loaded', async () => {
    render(<UserProfile userId="1" />)
    
    await waitFor(() => {
      expect(screen.getByText(mockUser.name)).toBeInTheDocument()
      expect(screen.getByText(mockUser.email)).toBeInTheDocument()
    })
  })

  it('displays error message on fetch failure', async () => {
    vi.mocked(api.getUser).mockRejectedValue(new Error('Network error'))
    render(<UserProfile userId="1" />)
    
    await waitFor(() => {
      expect(screen.getByText(/error loading user/i)).toBeInTheDocument()
    })
  })
})
```

### Hook Testing

```typescript
// useCounter.test.ts
import { describe, it, expect } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter())
    expect(result.current.count).toBe(0)
  })

  it('initializes with custom value', () => {
    const { result } = renderHook(() => useCounter(10))
    expect(result.current.count).toBe(10)
  })

  it('increments counter', () => {
    const { result } = renderHook(() => useCounter())
    
    act(() => {
      result.current.increment()
    })
    
    expect(result.current.count).toBe(1)
  })

  it('decrements counter', () => {
    const { result } = renderHook(() => useCounter(5))
    
    act(() => {
      result.current.decrement()
    })
    
    expect(result.current.count).toBe(4)
  })

  it('resets counter', () => {
    const { result } = renderHook(() => useCounter(5))
    
    act(() => {
      result.current.increment()
      result.current.increment()
      result.current.reset()
    })
    
    expect(result.current.count).toBe(5)
  })
})
```

### Store/State Testing

```typescript
// Pinia Store Testing (Vue)
import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useUserStore } from './userStore'

describe('User Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('initializes with empty user', () => {
    const store = useUserStore()
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })

  it('sets user on login', async () => {
    const store = useUserStore()
    const mockUser = createUser()
    
    await store.login('test@example.com', 'password')
    
    expect(store.user).toEqual(mockUser)
    expect(store.isAuthenticated).toBe(true)
  })

  it('clears user on logout', () => {
    const store = useUserStore()
    store.user = createUser()
    
    store.logout()
    
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })
})

// Redux Slice Testing
import { describe, it, expect } from 'vitest'
import userReducer, { 
  setUser, 
  clearUser, 
  updateProfile 
} from './userSlice'

describe('userSlice', () => {
  const initialState = {
    user: null,
    loading: false,
    error: null
  }

  it('sets user', () => {
    const user = createUser()
    const action = setUser(user)
    const state = userReducer(initialState, action)
    
    expect(state.user).toEqual(user)
    expect(state.loading).toBe(false)
  })

  it('updates user profile', () => {
    const currentState = {
      ...initialState,
      user: createUser()
    }
    
    const updates = { name: 'Jane Doe' }
    const action = updateProfile(updates)
    const state = userReducer(currentState, action)
    
    expect(state.user.name).toBe('Jane Doe')
  })
})
```

## 🐍 Python Testing with Pytest

### Pytest Setup

```bash
# Install pytest and utilities
pip install pytest pytest-cov pytest-asyncio pytest-mock
pip install pytest-xdist  # Parallel execution
pip install pytest-timeout
pip install factory-boy faker  # Test data generation

# FastAPI specific
pip install httpx pytest-httpx
```

### Pytest Configuration

```ini
# pytest.ini
[tool:pytest]
minversion = 6.0
addopts = 
    -ra
    --strict-markers
    --cov=app
    --cov-branch
    --cov-report=term-missing:skip-covered
    --cov-report=html
    --cov-report=xml
    --maxfail=1
    --ff
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    unit: marks tests as unit tests

# conftest.py
import pytest
from typing import Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.main import app
from app.database import get_db, Base

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db_session() -> Generator[Session, None, None]:
    """Create a fresh database session for a test."""
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db_session: Session) -> Generator[TestClient, None, None]:
    """Create a test client."""
    def override_get_db():
        try:
            yield db_session
        finally:
            db_session.close()
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
```

### Test Structure and Organization

```python
# tests/unit/test_models.py
import pytest
from datetime import datetime
from app.models import User, Post
from app.utils.security import get_password_hash, verify_password

class TestUserModel:
    """Test User model functionality."""
    
    def test_create_user(self, db_session):
        """Test user creation."""
        user = User(
            email="test@example.com",
            username="testuser",
            hashed_password=get_password_hash("password123")
        )
        db_session.add(user)
        db_session.commit()
        
        assert user.id is not None
        assert user.email == "test@example.com"
        assert user.is_active is True
        assert verify_password("password123", user.hashed_password)
    
    def test_user_repr(self):
        """Test user string representation."""
        user = User(id=1, email="test@example.com")
        assert str(user) == "<User(email='test@example.com')>"
    
    def test_user_relationships(self, db_session):
        """Test user relationships."""
        user = User(email="test@example.com", username="testuser")
        post = Post(title="Test Post", content="Content", author=user)
        
        db_session.add_all([user, post])
        db_session.commit()
        
        assert len(user.posts) == 1
        assert user.posts[0].title == "Test Post"
        assert post.author == user

# tests/unit/test_utils.py
import pytest
from app.utils.validators import validate_email, validate_password
from app.utils.formatters import format_datetime, slugify

class TestValidators:
    """Test validation utilities."""
    
    @pytest.mark.parametrize("email,expected", [
        ("valid@example.com", True),
        ("user.name@example.co.uk", True),
        ("invalid@", False),
        ("@example.com", False),
        ("no-at-sign.com", False),
        ("", False),
        (None, False),
    ])
    def test_validate_email(self, email, expected):
        """Test email validation."""
        assert validate_email(email) == expected
    
    @pytest.mark.parametrize("password,expected", [
        ("StrongP@ss123", True),
        ("weak", False),
        ("no-uppercase123!", False),
        ("NO-LOWERCASE123!", False),
        ("NoSpecialChar123", False),
        ("NoDigits!@#", False),
        ("", False),
    ])
    def test_validate_password(self, password, expected):
        """Test password validation."""
        assert validate_password(password) == expected

class TestFormatters:
    """Test formatting utilities."""
    
    def test_format_datetime(self):
        """Test datetime formatting."""
        dt = datetime(2023, 1, 15, 14, 30, 0)
        assert format_datetime(dt) == "2023-01-15 14:30:00"
        assert format_datetime(dt, "%Y-%m-%d") == "2023-01-15"
    
    @pytest.mark.parametrize("text,expected", [
        ("Hello World", "hello-world"),
        ("Python 3.9", "python-3-9"),
        ("Multiple   Spaces", "multiple-spaces"),
        ("Special!@#$%Characters", "special-characters"),
    ])
    def test_slugify(self, text, expected):
        """Test text slugification."""
        assert slugify(text) == expected
```

### Service Layer Testing

```python
# tests/unit/test_services.py
import pytest
from unittest.mock import Mock, patch, AsyncMock
from app.services.user_service import UserService
from app.services.email_service import EmailService
from app.exceptions import UserNotFoundError, DuplicateEmailError

class TestUserService:
    """Test user service functionality."""
    
    @pytest.fixture
    def user_service(self):
        """Create user service with mocked dependencies."""
        mock_db = Mock()
        mock_email_service = Mock()
        return UserService(db=mock_db, email_service=mock_email_service)
    
    async def test_create_user_success(self, user_service):
        """Test successful user creation."""
        # Arrange
        user_data = {
            "email": "new@example.com",
            "username": "newuser",
            "password": "SecurePass123!"
        }
        user_service.db.query().filter().first.return_value = None
        
        # Act
        user = await user_service.create_user(**user_data)
        
        # Assert
        assert user.email == user_data["email"]
        user_service.email_service.send_welcome_email.assert_called_once()
    
    async def test_create_user_duplicate_email(self, user_service):
        """Test user creation with duplicate email."""
        # Arrange
        existing_user = Mock(email="existing@example.com")
        user_service.db.query().filter().first.return_value = existing_user
        
        # Act & Assert
        with pytest.raises(DuplicateEmailError):
            await user_service.create_user(
                email="existing@example.com",
                username="newuser",
                password="password"
            )
    
    @patch('app.services.user_service.send_notification')
    async def test_update_user_profile(self, mock_send_notification, user_service):
        """Test user profile update."""
        # Arrange
        user = Mock(id=1, email="user@example.com")
        updates = {"bio": "New bio", "avatar_url": "https://example.com/avatar.jpg"}
        
        # Act
        updated_user = await user_service.update_profile(user, updates)
        
        # Assert
        for key, value in updates.items():
            assert getattr(updated_user, key) == value
        mock_send_notification.assert_called_once()
```

### Fixture Factories

```python
# tests/factories.py
import factory
from factory import Faker, SubFactory, LazyAttribute
from app.models import User, Post, Comment
from datetime import datetime

class UserFactory(factory.Factory):
    """Factory for creating User instances."""
    
    class Meta:
        model = User
    
    id = factory.Sequence(lambda n: n)
    email = Faker('email')
    username = factory.LazyAttribute(lambda obj: obj.email.split('@')[0])
    hashed_password = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN/LbGhXiE"  # "password"
    is_active = True
    is_verified = True
    created_at = factory.LazyFunction(datetime.utcnow)

class PostFactory(factory.Factory):
    """Factory for creating Post instances."""
    
    class Meta:
        model = Post
    
    id = factory.Sequence(lambda n: n)
    title = Faker('sentence', nb_words=4)
    content = Faker('text', max_nb_chars=500)
    slug = factory.LazyAttribute(lambda obj: slugify(obj.title))
    author = SubFactory(UserFactory)
    published = True
    created_at = factory.LazyFunction(datetime.utcnow)

# Usage in tests
def test_post_creation():
    user = UserFactory(username="testuser")
    post = PostFactory(author=user, title="Test Post")
    
    assert post.author.username == "testuser"
    assert post.slug == "test-post"
```

## 🎯 Testing Best Practices

### Test Structure (AAA Pattern)

```python
def test_user_can_update_profile():
    # Arrange - Set up test data and mocks
    user = create_test_user()
    new_data = {"bio": "Updated bio"}
    
    # Act - Execute the code being tested
    result = user_service.update_profile(user.id, new_data)
    
    # Assert - Verify the outcome
    assert result.bio == "Updated bio"
    assert result.updated_at > user.updated_at
```

### Mock External Dependencies

```python
# Python example
@pytest.fixture
def mock_external_api():
    with patch('app.services.external_api') as mock:
        mock.fetch_data.return_value = {"status": "success"}
        yield mock

def test_service_with_external_call(mock_external_api):
    result = my_service.process_data()
    assert result["status"] == "success"
    mock_external_api.fetch_data.assert_called_once()

# JavaScript example
vi.mock('@/services/api', () => ({
  fetchUser: vi.fn(),
  updateUser: vi.fn()
}))

it('fetches user data', async () => {
  const mockUser = { id: 1, name: 'John' }
  vi.mocked(api.fetchUser).mockResolvedValue(mockUser)
  
  const user = await getUserData(1)
  expect(user).toEqual(mockUser)
})
```

### Test Coverage Guidelines

```yaml
# Coverage targets
coverage:
  statements: 80%
  branches: 75%
  functions: 80%
  lines: 80%

# What to test:
- Business logic
- Edge cases
- Error handling
- Public APIs
- Complex calculations
- State changes

# What not to test:
- Framework code
- Simple getters/setters
- Configuration files
- Third-party libraries
- Trivial code
```

### Parameterized Tests

```python
# Python
@pytest.mark.parametrize("input,expected", [
    (0, 0),
    (1, 1),
    (2, 1),
    (3, 2),
    (4, 3),
    (5, 5),
])
def test_fibonacci(input, expected):
    assert fibonacci(input) == expected

# JavaScript/TypeScript
describe.each([
  [0, 0],
  [1, 1],
  [2, 1],
  [3, 2],
  [4, 3],
  [5, 5],
])('fibonacci(%i)', (input, expected) => {
  it(`returns ${expected}`, () => {
    expect(fibonacci(input)).toBe(expected)
  })
})
```

## 🚀 Advanced Testing Patterns

### Snapshot Testing

```typescript
// Component snapshots
it('renders correctly', () => {
  const { container } = render(<UserCard user={mockUser} />)
  expect(container.firstChild).toMatchSnapshot()
})

// API response snapshots
it('returns expected user data structure', async () => {
  const response = await api.getUser(1)
  expect(response).toMatchSnapshot({
    id: expect.any(Number),
    createdAt: expect.any(String),
    updatedAt: expect.any(String)
  })
})
```

### Property-Based Testing

```python
# Using hypothesis
from hypothesis import given, strategies as st

@given(st.integers(min_value=0, max_value=1000))
def test_fibonacci_properties(n):
    result = fibonacci(n)
    
    # Property: Result is always non-negative
    assert result >= 0
    
    # Property: F(n) = F(n-1) + F(n-2) for n > 1
    if n > 1:
        assert result == fibonacci(n-1) + fibonacci(n-2)
```

### Test Data Builders

```typescript
// Builder pattern for test data
class UserBuilder {
  private user = {
    id: '1',
    name: 'Test User',
    email: 'test@example.com',
    role: 'user'
  }

  withId(id: string) {
    this.user.id = id
    return this
  }

  withName(name: string) {
    this.user.name = name
    return this
  }

  withRole(role: string) {
    this.user.role = role
    return this
  }

  withAdmin() {
    this.user.role = 'admin'
    return this
  }

  build() {
    return { ...this.user }
  }
}

// Usage
const adminUser = new UserBuilder()
  .withName('Admin User')
  .withAdmin()
  .build()
```

## 📊 Running and Analyzing Tests

### Test Commands

```bash
# JavaScript/TypeScript
npm test                  # Run all tests
npm test -- --watch      # Watch mode
npm test -- --coverage   # With coverage
npm test Button.test     # Specific test file
npm test -- --ui        # Vitest UI

# Python
pytest                   # Run all tests
pytest -v               # Verbose output
pytest -k "user"        # Run tests matching "user"
pytest -m unit          # Run tests marked as "unit"
pytest --cov           # With coverage
pytest -n auto         # Parallel execution
pytest --lf            # Run last failed
```

### Continuous Testing

```json
// package.json scripts
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest run --coverage",
    "test:ui": "vitest --ui",
    "test:ci": "vitest run --coverage --reporter=junit"
  }
}
```

---

*Unit tests are the foundation of a reliable test suite. Write tests that are fast, isolated, and focused on single units of functionality. Aim for high coverage but prioritize testing critical business logic and edge cases.*
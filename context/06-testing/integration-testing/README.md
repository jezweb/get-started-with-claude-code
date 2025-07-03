# Integration Testing Patterns

Testing how different components, services, and systems work together. Integration tests validate that modules cooperate correctly and data flows properly between boundaries.

## 🎯 What Are Integration Tests?

Integration tests sit between unit tests and E2E tests, focusing on:
- **Component interaction** - How modules work together
- **Data flow** - Information passing between layers
- **External dependencies** - APIs, databases, file systems
- **Service boundaries** - Microservice communication

## 📁 Testing Approaches

### 1. **API Integration Testing**
Testing REST APIs, GraphQL endpoints, and service communication

### 2. **Database Integration Testing**  
Testing data access layers, migrations, and database operations

### 3. **Service Layer Testing**
Testing business logic that combines multiple components

### 4. **Contract Testing**
Testing API contracts between services (consumer/provider)

## 🚀 API Integration Testing

### FastAPI Testing (Python)
```python
# tests/integration/test_user_api.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from database import get_db, Base

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    Base.metadata.create_all(bind=engine)
    with TestClient(app) as c:
        yield c
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def authenticated_client(client):
    # Create a test user and authenticate
    response = client.post("/auth/register", json={
        "email": "test@example.com",
        "password": "testpass123",
        "name": "Test User"
    })
    
    login_response = client.post("/auth/login", data={
        "username": "test@example.com",
        "password": "testpass123"
    })
    
    token = login_response.json()["access_token"]
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client

def test_user_registration_flow(client):
    """Test complete user registration process."""
    # Register new user
    response = client.post("/auth/register", json={
        "email": "newuser@example.com",
        "password": "password123",
        "name": "New User"
    })
    
    assert response.status_code == 201
    user_data = response.json()
    assert user_data["email"] == "newuser@example.com"
    assert "id" in user_data
    
    # Verify user can login
    login_response = client.post("/auth/login", data={
        "username": "newuser@example.com",
        "password": "password123"
    })
    
    assert login_response.status_code == 200
    assert "access_token" in login_response.json()

def test_protected_endpoint_access(authenticated_client):
    """Test accessing protected endpoints with authentication."""
    response = authenticated_client.get("/users/me")
    
    assert response.status_code == 200
    user_data = response.json()
    assert user_data["email"] == "test@example.com"

def test_user_crud_operations(authenticated_client):
    """Test complete CRUD operations for users."""
    # Create
    create_response = authenticated_client.post("/users", json={
        "name": "Created User",
        "email": "created@example.com"
    })
    assert create_response.status_code == 201
    user_id = create_response.json()["id"]
    
    # Read
    read_response = authenticated_client.get(f"/users/{user_id}")
    assert read_response.status_code == 200
    assert read_response.json()["name"] == "Created User"
    
    # Update
    update_response = authenticated_client.put(f"/users/{user_id}", json={
        "name": "Updated User",
        "email": "updated@example.com"
    })
    assert update_response.status_code == 200
    assert update_response.json()["name"] == "Updated User"
    
    # Delete
    delete_response = authenticated_client.delete(f"/users/{user_id}")
    assert delete_response.status_code == 204
    
    # Verify deletion
    get_response = authenticated_client.get(f"/users/{user_id}")
    assert get_response.status_code == 404

def test_pagination_and_filtering(authenticated_client):
    """Test API pagination and filtering functionality."""
    # Create test data
    for i in range(15):
        authenticated_client.post("/posts", json={
            "title": f"Test Post {i}",
            "content": f"Content for post {i}",
            "published": i % 2 == 0
        })
    
    # Test pagination
    response = authenticated_client.get("/posts?page=1&size=10")
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 10
    assert data["total"] == 15
    assert data["page"] == 1
    
    # Test filtering
    published_response = authenticated_client.get("/posts?published=true")
    published_data = published_response.json()
    assert all(post["published"] for post in published_data["items"])

def test_error_handling(client):
    """Test API error handling and responses."""
    # Test 404 for non-existent resource
    response = client.get("/users/99999")
    assert response.status_code == 404
    assert "detail" in response.json()
    
    # Test 401 for unauthorized access
    response = client.get("/users/me")
    assert response.status_code == 401
    
    # Test 422 for validation errors
    response = client.post("/users", json={
        "email": "invalid-email",
        "name": ""
    })
    assert response.status_code == 422
    errors = response.json()["detail"]
    assert any(error["field"] == "email" for error in errors)
```

### Express.js Testing (Node.js)
```javascript
// tests/integration/auth.test.js
const request = require('supertest')
const app = require('../../src/app')
const { setupTestDB, cleanupTestDB } = require('../helpers/database')

describe('Authentication Integration', () => {
  beforeAll(async () => {
    await setupTestDB()
  })

  afterAll(async () => {
    await cleanupTestDB()
  })

  describe('POST /auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User'
      }

      const response = await request(app)
        .post('/auth/register')
        .send(userData)
        .expect(201)

      expect(response.body).toMatchObject({
        user: {
          email: userData.email,
          name: userData.name
        },
        token: expect.any(String)
      })
      expect(response.body.user.password).toBeUndefined()
    })

    it('should reject duplicate email registration', async () => {
      const userData = {
        email: 'duplicate@example.com',
        password: 'password123',
        name: 'Test User'
      }

      // First registration
      await request(app)
        .post('/auth/register')
        .send(userData)
        .expect(201)

      // Duplicate registration
      const response = await request(app)
        .post('/auth/register')
        .send(userData)
        .expect(400)

      expect(response.body.error).toContain('email already exists')
    })
  })

  describe('POST /auth/login', () => {
    beforeEach(async () => {
      await request(app)
        .post('/auth/register')
        .send({
          email: 'login@example.com',
          password: 'password123',
          name: 'Login User'
        })
    })

    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'login@example.com',
          password: 'password123'
        })
        .expect(200)

      expect(response.body).toMatchObject({
        user: {
          email: 'login@example.com',
          name: 'Login User'
        },
        token: expect.any(String)
      })
    })

    it('should reject invalid credentials', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'login@example.com',
          password: 'wrongpassword'
        })
        .expect(401)

      expect(response.body.error).toContain('Invalid credentials')
    })
  })
})
```

## 🗄️ Database Integration Testing

### SQLAlchemy Testing (Python)
```python
# tests/integration/test_database.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timedelta

from database import Base
from models import User, Post, Comment
from repositories import UserRepository, PostRepository

@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///./test.db")
    Base.metadata.create_all(engine)
    
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    
    yield session
    
    session.close()
    Base.metadata.drop_all(engine)

@pytest.fixture
def sample_users(db_session):
    users = [
        User(name="John Doe", email="john@example.com"),
        User(name="Jane Smith", email="jane@example.com"),
        User(name="Bob Wilson", email="bob@example.com")
    ]
    
    for user in users:
        db_session.add(user)
    db_session.commit()
    
    return users

def test_user_repository_operations(db_session):
    """Test repository layer database operations."""
    repo = UserRepository(db_session)
    
    # Create user
    user_data = {
        "name": "Test User",
        "email": "test@example.com"
    }
    user = repo.create(user_data)
    
    assert user.id is not None
    assert user.name == "Test User"
    assert user.created_at is not None
    
    # Find user
    found_user = repo.find_by_email("test@example.com")
    assert found_user.id == user.id
    
    # Update user
    updated_user = repo.update(user.id, {"name": "Updated Name"})
    assert updated_user.name == "Updated Name"
    
    # Delete user
    repo.delete(user.id)
    deleted_user = repo.find_by_id(user.id)
    assert deleted_user is None

def test_complex_query_operations(db_session, sample_users):
    """Test complex database queries and relationships."""
    user = sample_users[0]
    
    # Create posts for user
    posts = [
        Post(title="First Post", content="Content 1", author=user),
        Post(title="Second Post", content="Content 2", author=user),
        Post(title="Third Post", content="Content 3", author=user, published=True)
    ]
    
    for post in posts:
        db_session.add(post)
    db_session.commit()
    
    # Test queries
    repo = PostRepository(db_session)
    
    # Find published posts
    published_posts = repo.find_published()
    assert len(published_posts) == 1
    assert published_posts[0].title == "Third Post"
    
    # Find posts by author
    user_posts = repo.find_by_author(user.id)
    assert len(user_posts) == 3
    
    # Test pagination
    paginated = repo.find_paginated(page=1, size=2)
    assert len(paginated.items) == 2
    assert paginated.total == 3

def test_transaction_rollback(db_session):
    """Test database transaction handling."""
    repo = UserRepository(db_session)
    
    try:
        # Start transaction
        user1 = repo.create({"name": "User 1", "email": "user1@example.com"})
        user2 = repo.create({"name": "User 2", "email": "user2@example.com"})
        
        # This should fail due to duplicate email
        user3 = repo.create({"name": "User 3", "email": "user1@example.com"})
        
        db_session.commit()
    except Exception:
        db_session.rollback()
    
    # Verify rollback worked
    users = repo.find_all()
    assert len(users) == 0

def test_database_constraints(db_session):
    """Test database constraints and validations."""
    # Test unique constraint
    user1 = User(name="User 1", email="same@example.com")
    user2 = User(name="User 2", email="same@example.com")
    
    db_session.add(user1)
    db_session.commit()
    
    with pytest.raises(Exception):  # IntegrityError
        db_session.add(user2)
        db_session.commit()
```

### Prisma Testing (Node.js)
```javascript
// tests/integration/database.test.js
const { PrismaClient } = require('@prisma/client')
const { execSync } = require('child_process')

const prisma = new PrismaClient()

beforeAll(async () => {
  // Reset test database
  execSync('npx prisma migrate reset --force', { 
    env: { ...process.env, DATABASE_URL: process.env.TEST_DATABASE_URL } 
  })
})

afterAll(async () => {
  await prisma.$disconnect()
})

beforeEach(async () => {
  // Clean all tables
  await prisma.comment.deleteMany()
  await prisma.post.deleteMany()
  await prisma.user.deleteMany()
})

describe('Database Operations', () => {
  describe('User Operations', () => {
    it('should create and retrieve user', async () => {
      const userData = {
        email: 'test@example.com',
        name: 'Test User'
      }

      const user = await prisma.user.create({
        data: userData
      })

      expect(user).toMatchObject(userData)
      expect(user.id).toBeDefined()
      expect(user.createdAt).toBeInstanceOf(Date)

      const foundUser = await prisma.user.findUnique({
        where: { email: userData.email }
      })

      expect(foundUser.id).toBe(user.id)
    })

    it('should handle unique constraint violations', async () => {
      const userData = {
        email: 'duplicate@example.com',
        name: 'Test User'
      }

      await prisma.user.create({ data: userData })

      await expect(
        prisma.user.create({ data: userData })
      ).rejects.toThrow(/Unique constraint/)
    })
  })

  describe('Relationship Operations', () => {
    it('should create and query related data', async () => {
      // Create user with posts
      const user = await prisma.user.create({
        data: {
          email: 'author@example.com',
          name: 'Author',
          posts: {
            create: [
              { title: 'First Post', content: 'Content 1' },
              { title: 'Second Post', content: 'Content 2' }
            ]
          }
        },
        include: {
          posts: true
        }
      })

      expect(user.posts).toHaveLength(2)

      // Query with nested includes
      const userWithPosts = await prisma.user.findUnique({
        where: { id: user.id },
        include: {
          posts: {
            include: {
              comments: true
            }
          }
        }
      })

      expect(userWithPosts.posts).toHaveLength(2)
    })

    it('should handle cascade deletes', async () => {
      const user = await prisma.user.create({
        data: {
          email: 'cascade@example.com',
          name: 'Cascade User',
          posts: {
            create: [
              { title: 'Post to be deleted', content: 'Content' }
            ]
          }
        }
      })

      // Delete user should cascade to posts
      await prisma.user.delete({
        where: { id: user.id }
      })

      const posts = await prisma.post.findMany({
        where: { authorId: user.id }
      })

      expect(posts).toHaveLength(0)
    })
  })

  describe('Transaction Operations', () => {
    it('should handle successful transactions', async () => {
      const result = await prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: {
            email: 'transaction@example.com',
            name: 'Transaction User'
          }
        })

        const post = await tx.post.create({
          data: {
            title: 'Transaction Post',
            content: 'Transaction Content',
            authorId: user.id
          }
        })

        return { user, post }
      })

      expect(result.user.email).toBe('transaction@example.com')
      expect(result.post.authorId).toBe(result.user.id)

      // Verify data was committed
      const user = await prisma.user.findUnique({
        where: { id: result.user.id }
      })
      expect(user).toBeTruthy()
    })

    it('should rollback failed transactions', async () => {
      await expect(
        prisma.$transaction(async (tx) => {
          await tx.user.create({
            data: {
              email: 'rollback@example.com',
              name: 'Rollback User'
            }
          })

          // This will fail and cause rollback
          throw new Error('Transaction failed')
        })
      ).rejects.toThrow('Transaction failed')

      // Verify rollback
      const user = await prisma.user.findUnique({
        where: { email: 'rollback@example.com' }
      })
      expect(user).toBe(null)
    })
  })
})
```

## 🔄 Service Layer Integration Testing

### Testing Business Logic Integration
```python
# tests/integration/test_user_service.py
import pytest
from unittest.mock import Mock, patch
from datetime import datetime, timedelta

from services import UserService, EmailService, NotificationService
from repositories import UserRepository
from exceptions import UserNotFoundError, EmailAlreadyExistsError

@pytest.fixture
def mock_dependencies():
    return {
        'user_repo': Mock(spec=UserRepository),
        'email_service': Mock(spec=EmailService),
        'notification_service': Mock(spec=NotificationService)
    }

@pytest.fixture
def user_service(mock_dependencies):
    return UserService(
        user_repo=mock_dependencies['user_repo'],
        email_service=mock_dependencies['email_service'],
        notification_service=mock_dependencies['notification_service']
    )

def test_user_registration_integration(user_service, mock_dependencies):
    """Test complete user registration workflow."""
    # Setup mocks
    mock_dependencies['user_repo'].find_by_email.return_value = None
    mock_dependencies['user_repo'].create.return_value = Mock(
        id=1, 
        email='test@example.com',
        name='Test User',
        is_verified=False
    )
    mock_dependencies['email_service'].send_verification_email.return_value = True
    
    # Execute registration
    user_data = {
        'email': 'test@example.com',
        'password': 'password123',
        'name': 'Test User'
    }
    
    result = user_service.register_user(user_data)
    
    # Verify interactions
    mock_dependencies['user_repo'].find_by_email.assert_called_with('test@example.com')
    mock_dependencies['user_repo'].create.assert_called_once()
    mock_dependencies['email_service'].send_verification_email.assert_called_with(
        'test@example.com', 
        'Test User',
        verification_token=result.verification_token
    )
    mock_dependencies['notification_service'].send_welcome_notification.assert_called_once()
    
    assert result.user.email == 'test@example.com'
    assert result.verification_token is not None

def test_user_registration_duplicate_email(user_service, mock_dependencies):
    """Test registration with existing email."""
    # Setup existing user
    existing_user = Mock(email='existing@example.com')
    mock_dependencies['user_repo'].find_by_email.return_value = existing_user
    
    with pytest.raises(EmailAlreadyExistsError):
        user_service.register_user({
            'email': 'existing@example.com',
            'password': 'password123',
            'name': 'Test User'
        })
    
    # Verify no user creation was attempted
    mock_dependencies['user_repo'].create.assert_not_called()
    mock_dependencies['email_service'].send_verification_email.assert_not_called()

@patch('services.user_service.generate_password_reset_token')
def test_password_reset_workflow(mock_token_gen, user_service, mock_dependencies):
    """Test complete password reset workflow."""
    # Setup
    reset_token = 'reset_token_123'
    mock_token_gen.return_value = reset_token
    
    user = Mock(id=1, email='user@example.com', name='User')
    mock_dependencies['user_repo'].find_by_email.return_value = user
    mock_dependencies['user_repo'].update.return_value = user
    
    # Request password reset
    result = user_service.request_password_reset('user@example.com')
    
    # Verify workflow
    mock_dependencies['user_repo'].find_by_email.assert_called_with('user@example.com')
    mock_dependencies['user_repo'].update.assert_called_with(
        user.id, 
        {
            'password_reset_token': reset_token,
            'password_reset_expires': pytest.approx(datetime.utcnow() + timedelta(hours=1), abs=timedelta(minutes=1))
        }
    )
    mock_dependencies['email_service'].send_password_reset_email.assert_called_with(
        'user@example.com',
        'User',
        reset_token
    )
    
    assert result.success is True

def test_user_profile_update_integration(user_service, mock_dependencies):
    """Test user profile update with validation."""
    user = Mock(id=1, email='user@example.com', name='Old Name')
    mock_dependencies['user_repo'].find_by_id.return_value = user
    mock_dependencies['user_repo'].update.return_value = Mock(
        id=1, 
        email='user@example.com', 
        name='New Name'
    )
    
    # Update profile
    update_data = {'name': 'New Name', 'bio': 'New bio'}
    result = user_service.update_profile(user_id=1, data=update_data)
    
    # Verify
    mock_dependencies['user_repo'].find_by_id.assert_called_with(1)
    mock_dependencies['user_repo'].update.assert_called_with(1, update_data)
    mock_dependencies['notification_service'].send_profile_updated_notification.assert_called_once()
    
    assert result.name == 'New Name'
```

## 🌐 Contract Testing

### Pact Testing (Consumer/Provider)
```javascript
// tests/contract/user-api.pact.test.js
const { Pact } = require('@pact-foundation/pact')
const { UserApiClient } = require('../../src/clients/user-api')

describe('User API Contract Tests', () => {
  const provider = new Pact({
    consumer: 'web-app',
    provider: 'user-service',
    port: 3001,
    log: path.resolve(process.cwd(), 'logs', 'pact.log'),
    dir: path.resolve(process.cwd(), 'pacts'),
    logLevel: 'INFO'
  })

  beforeAll(() => provider.setup())
  afterAll(() => provider.finalize())
  afterEach(() => provider.verify())

  describe('GET /users/:id', () => {
    beforeEach(() => {
      return provider
        .given('user with ID 1 exists')
        .uponReceiving('a request for user 1')
        .withRequest({
          method: 'GET',
          path: '/users/1',
          headers: {
            'Accept': 'application/json'
          }
        })
        .willRespondWith({
          status: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            createdAt: '2023-01-01T00:00:00Z'
          }
        })
    })

    it('should return user data', async () => {
      const client = new UserApiClient('http://localhost:3001')
      const user = await client.getUser(1)

      expect(user).toMatchObject({
        id: 1,
        name: 'John Doe',
        email: 'john@example.com'
      })
    })
  })

  describe('POST /users', () => {
    beforeEach(() => {
      return provider
        .given('no users exist')
        .uponReceiving('a request to create a user')
        .withRequest({
          method: 'POST',
          path: '/users',
          headers: {
            'Content-Type': 'application/json'
          },
          body: {
            name: 'Jane Doe',
            email: 'jane@example.com'
          }
        })
        .willRespondWith({
          status: 201,
          headers: {
            'Content-Type': 'application/json'
          },
          body: {
            id: 2,
            name: 'Jane Doe',
            email: 'jane@example.com',
            createdAt: '2023-01-01T00:00:00Z'
          }
        })
    })

    it('should create a new user', async () => {
      const client = new UserApiClient('http://localhost:3001')
      const user = await client.createUser({
        name: 'Jane Doe',
        email: 'jane@example.com'
      })

      expect(user).toMatchObject({
        id: expect.any(Number),
        name: 'Jane Doe',
        email: 'jane@example.com'
      })
    })
  })
})
```

## 🐳 Test Containers

### Using Testcontainers for Real Dependencies
```python
# tests/integration/test_with_containers.py
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import redis

from database import Base
from services import UserService, CacheService

@pytest.fixture(scope="session")
def postgres_container():
    with PostgresContainer("postgres:15") as postgres:
        yield postgres

@pytest.fixture(scope="session")  
def redis_container():
    with RedisContainer("redis:7") as redis_cont:
        yield redis_cont

@pytest.fixture
def db_session(postgres_container):
    engine = create_engine(postgres_container.get_connection_url())
    Base.metadata.create_all(engine)
    
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    
    yield session
    
    session.close()
    Base.metadata.drop_all(engine)

@pytest.fixture
def cache_service(redis_container):
    redis_client = redis.from_url(redis_container.get_connection_url())
    return CacheService(redis_client)

def test_user_service_with_real_dependencies(db_session, cache_service):
    """Test user service with real database and cache."""
    user_service = UserService(db_session, cache_service)
    
    # Create user
    user_data = {
        "name": "Integration User",
        "email": "integration@example.com"
    }
    
    user = user_service.create_user(user_data)
    assert user.id is not None
    
    # Verify caching works
    cached_user = user_service.get_user(user.id)
    assert cached_user.email == user.email
    
    # Verify cache hit
    cache_key = f"user:{user.id}"
    cached_data = cache_service.get(cache_key)
    assert cached_data is not None

def test_cache_invalidation_on_update(db_session, cache_service):
    """Test cache invalidation when user is updated."""
    user_service = UserService(db_session, cache_service)
    
    # Create and cache user
    user = user_service.create_user({
        "name": "Cache User",
        "email": "cache@example.com"
    })
    
    # Get user to cache it
    user_service.get_user(user.id)
    
    # Update user
    updated_user = user_service.update_user(user.id, {"name": "Updated Name"})
    
    # Verify cache was invalidated and refreshed
    cache_key = f"user:{user.id}"
    cached_data = cache_service.get(cache_key)
    assert cached_data["name"] == "Updated Name"
```

## 📊 Best Practices

### 1. Test Data Management
```python
# Use factories for consistent test data
class UserFactory:
    @staticmethod
    def create(**kwargs):
        defaults = {
            "name": "Test User",
            "email": f"test{random.randint(1000, 9999)}@example.com",
            "created_at": datetime.utcnow()
        }
        defaults.update(kwargs)
        return User(**defaults)

# Use fixtures for common setups
@pytest.fixture
def authenticated_user(db_session):
    user = UserFactory.create()
    db_session.add(user)
    db_session.commit()
    return user
```

### 2. Environment Isolation
```bash
# Use separate test databases
TEST_DATABASE_URL=postgresql://test:test@localhost:5433/test_db
REDIS_TEST_URL=redis://localhost:6380/1

# Environment-specific configs
export NODE_ENV=test
export RAILS_ENV=test
export FLASK_ENV=testing
```

### 3. Parallel Test Execution
```yaml
# pytest-xdist for parallel execution
pytest -n auto  # Use all CPU cores
pytest -n 4     # Use 4 processes

# Jest parallel execution
jest --maxWorkers=4
```

### 4. Test Documentation
```python
def test_user_registration_sends_welcome_email():
    """
    Test that user registration triggers welcome email.
    
    Given: A new user registration request
    When: The user is successfully created
    Then: A welcome email should be sent
    And: The user should receive a verification token
    """
    pass
```

## 🚦 Quick Navigation

**API Testing** → [API Integration Patterns](./api-integration/)

**Database Testing** → [Database Integration Patterns](./database-integration/)

**Service Testing** → [Service Layer Testing](./service-integration/)

**Contract Testing** → [Contract Testing Patterns](./contract-testing/)

---

*Integration tests give you confidence that your application components work together correctly, catching issues that unit tests might miss.*
# Integration Testing Patterns

Comprehensive guide to integration testing strategies for testing component interactions, API endpoints, database operations, and external service integrations.

## 🎯 Integration Testing Overview

Integration testing verifies that different parts of your application work together correctly:
- **Component Integration** - Multiple units working together
- **API Testing** - HTTP endpoints and middleware
- **Database Integration** - Real database operations
- **Service Integration** - External API interactions
- **Message Queue Testing** - Async communication
- **Authentication Flows** - End-to-end auth testing

## 🌐 API Integration Testing

### FastAPI Testing (Python)

```python
# tests/integration/test_api_users.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.main import app
from app.models import User
from app.core.security import create_access_token
from tests.factories import UserFactory

@pytest.mark.asyncio
class TestUserAPI:
    """Test user API endpoints integration."""
    
    async def test_create_user(self, async_client: AsyncClient, db: AsyncSession):
        """Test user registration flow."""
        user_data = {
            "email": "newuser@example.com",
            "username": "newuser",
            "password": "SecurePass123!",
            "confirm_password": "SecurePass123!"
        }
        
        response = await async_client.post("/api/v1/users/register", json=user_data)
        
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == user_data["email"]
        assert "password" not in data
        assert "access_token" in data
        
        # Verify user in database
        user = await db.get(User, data["id"])
        assert user is not None
        assert user.email == user_data["email"]
        assert user.verify_password(user_data["password"])
    
    async def test_get_current_user(self, async_client: AsyncClient, db: AsyncSession):
        """Test authenticated user retrieval."""
        # Create test user
        user = UserFactory()
        db.add(user)
        await db.commit()
        
        # Generate token
        token = create_access_token(subject=str(user.id))
        headers = {"Authorization": f"Bearer {token}"}
        
        response = await async_client.get("/api/v1/users/me", headers=headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == user.id
        assert data["email"] == user.email
    
    async def test_update_user_profile(self, async_client: AsyncClient, db: AsyncSession):
        """Test user profile update flow."""
        user = UserFactory()
        db.add(user)
        await db.commit()
        
        token = create_access_token(subject=str(user.id))
        headers = {"Authorization": f"Bearer {token}"}
        
        update_data = {
            "bio": "Updated bio",
            "location": "New York",
            "website": "https://example.com"
        }
        
        response = await async_client.patch(
            f"/api/v1/users/{user.id}",
            headers=headers,
            json=update_data
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["bio"] == update_data["bio"]
        
        # Verify in database
        await db.refresh(user)
        assert user.profile.bio == update_data["bio"]
    
    async def test_user_pagination(self, async_client: AsyncClient, db: AsyncSession):
        """Test user list pagination."""
        # Create multiple users
        users = [UserFactory() for _ in range(25)]
        db.add_all(users)
        await db.commit()
        
        # Test first page
        response = await async_client.get("/api/v1/users?page=1&limit=10")
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 10
        assert data["total"] == 25
        assert data["page"] == 1
        assert data["pages"] == 3
        
        # Test second page
        response = await async_client.get("/api/v1/users?page=2&limit=10")
        data = response.json()
        assert len(data["items"]) == 10
        assert data["page"] == 2

# tests/integration/test_auth_flow.py
@pytest.mark.asyncio
class TestAuthenticationFlow:
    """Test complete authentication flows."""
    
    async def test_login_flow(self, async_client: AsyncClient, db: AsyncSession):
        """Test complete login flow."""
        # Create user
        password = "TestPass123!"
        user = UserFactory(password=password)
        db.add(user)
        await db.commit()
        
        # Login
        login_data = {
            "username": user.email,
            "password": password
        }
        response = await async_client.post("/api/v1/auth/login", data=login_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
        
        # Use access token
        headers = {"Authorization": f"Bearer {data['access_token']}"}
        profile_response = await async_client.get("/api/v1/users/me", headers=headers)
        assert profile_response.status_code == 200
    
    async def test_refresh_token_flow(self, async_client: AsyncClient, db: AsyncSession):
        """Test token refresh flow."""
        user = UserFactory()
        db.add(user)
        await db.commit()
        
        # Get initial tokens
        login_response = await async_client.post(
            "/api/v1/auth/login",
            data={"username": user.email, "password": "password"}
        )
        tokens = login_response.json()
        
        # Refresh token
        refresh_response = await async_client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": tokens["refresh_token"]}
        )
        
        assert refresh_response.status_code == 200
        new_tokens = refresh_response.json()
        assert new_tokens["access_token"] != tokens["access_token"]
        assert "refresh_token" in new_tokens
```

### Express.js Testing (Node.js)

```javascript
// tests/integration/users.test.js
const request = require('supertest');
const app = require('../../src/app');
const { sequelize } = require('../../src/models');
const { User, Post } = require('../../src/models');
const { generateToken } = require('../../src/utils/auth');

describe('User API Integration', () => {
  let authToken;
  let testUser;

  beforeAll(async () => {
    await sequelize.sync({ force: true });
  });

  beforeEach(async () => {
    // Create test user
    testUser = await User.create({
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    });
    authToken = generateToken(testUser.id);
  });

  afterEach(async () => {
    await User.destroy({ where: {} });
    await Post.destroy({ where: {} });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('POST /api/users/register', () => {
    it('should register a new user', async () => {
      const userData = {
        email: 'newuser@example.com',
        username: 'newuser',
        password: 'SecurePass123!'
      };

      const response = await request(app)
        .post('/api/users/register')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('user');
      expect(response.body).toHaveProperty('token');
      expect(response.body.user.email).toBe(userData.email);
      
      // Verify user in database
      const user = await User.findOne({ 
        where: { email: userData.email } 
      });
      expect(user).toBeTruthy();
      expect(await user.comparePassword(userData.password)).toBe(true);
    });

    it('should not register user with existing email', async () => {
      const response = await request(app)
        .post('/api/users/register')
        .send({
          email: testUser.email,
          username: 'anotheruser',
          password: 'password123'
        })
        .expect(409);

      expect(response.body.error).toContain('already exists');
    });
  });

  describe('GET /api/users/:id', () => {
    it('should get user with their posts', async () => {
      // Create posts for user
      await Post.bulkCreate([
        { title: 'Post 1', content: 'Content 1', userId: testUser.id },
        { title: 'Post 2', content: 'Content 2', userId: testUser.id }
      ]);

      const response = await request(app)
        .get(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(testUser.id);
      expect(response.body.posts).toHaveLength(2);
      expect(response.body.posts[0]).toHaveProperty('title');
    });
  });

  describe('PATCH /api/users/:id', () => {
    it('should update user profile', async () => {
      const updates = {
        bio: 'Updated bio',
        location: 'San Francisco'
      };

      const response = await request(app)
        .patch(`/api/users/${testUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);

      expect(response.body.bio).toBe(updates.bio);
      expect(response.body.location).toBe(updates.location);

      // Verify in database
      const updatedUser = await User.findByPk(testUser.id);
      expect(updatedUser.bio).toBe(updates.bio);
    });

    it('should not allow updating other users', async () => {
      const otherUser = await User.create({
        email: 'other@example.com',
        username: 'otheruser',
        password: 'password123'
      });

      await request(app)
        .patch(`/api/users/${otherUser.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ bio: 'Hacked!' })
        .expect(403);
    });
  });
});
```

## 💾 Database Integration Testing

### Testing with Real Database

```python
# tests/integration/test_database_operations.py
import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models import User, Post, Tag
from app.repositories import UserRepository, PostRepository

@pytest.mark.asyncio
class TestDatabaseOperations:
    """Test complex database operations."""
    
    async def test_transaction_rollback(self, db: AsyncSession):
        """Test transaction rollback on error."""
        user_repo = UserRepository(db)
        initial_count = await user_repo.count()
        
        try:
            async with db.begin():
                # Create user
                user = await user_repo.create(
                    email="test@example.com",
                    username="testuser"
                )
                
                # Force an error
                raise Exception("Simulated error")
        except Exception:
            pass
        
        # Verify rollback
        final_count = await user_repo.count()
        assert final_count == initial_count
    
    async def test_cascade_delete(self, db: AsyncSession):
        """Test cascade delete operations."""
        # Create user with related data
        user = User(email="test@example.com", username="testuser")
        post = Post(title="Test Post", content="Content", author=user)
        db.add_all([user, post])
        await db.commit()
        
        # Delete user
        await db.delete(user)
        await db.commit()
        
        # Verify post is also deleted
        posts = await db.execute(select(Post))
        assert posts.scalar() is None
    
    async def test_complex_query(self, db: AsyncSession):
        """Test complex query with joins and aggregations."""
        # Create test data
        users = []
        for i in range(5):
            user = User(email=f"user{i}@example.com", username=f"user{i}")
            users.append(user)
            
            # Create posts for each user
            for j in range(i + 1):
                post = Post(
                    title=f"Post {j} by User {i}",
                    content="Content",
                    author=user,
                    published=j % 2 == 0
                )
                db.add(post)
        
        db.add_all(users)
        await db.commit()
        
        # Complex query: Users with published post count
        query = (
            select(
                User,
                func.count(Post.id).filter(Post.published == True).label('published_count')
            )
            .outerjoin(Post)
            .group_by(User.id)
            .having(func.count(Post.id).filter(Post.published == True) > 0)
        )
        
        result = await db.execute(query)
        users_with_posts = result.all()
        
        assert len(users_with_posts) == 4  # User 0 has no posts
        assert users_with_posts[0][1] == 1  # User 1 has 1 published post
    
    async def test_bulk_operations(self, db: AsyncSession):
        """Test bulk insert and update operations."""
        # Bulk insert
        users_data = [
            {"email": f"bulk{i}@example.com", "username": f"bulk{i}"}
            for i in range(100)
        ]
        
        await db.execute(User.__table__.insert(), users_data)
        await db.commit()
        
        # Verify
        count = await db.scalar(select(func.count(User.id)))
        assert count == 100
        
        # Bulk update
        await db.execute(
            User.__table__.update().values(is_active=False).where(
                User.email.like('bulk%@example.com')
            )
        )
        await db.commit()
        
        # Verify updates
        inactive_count = await db.scalar(
            select(func.count(User.id)).where(User.is_active == False)
        )
        assert inactive_count == 100
```

### Testing with Test Containers

```javascript
// tests/integration/database.test.js
const { GenericContainer } = require('testcontainers');
const { Client } = require('pg');

describe('Database Integration with TestContainers', () => {
  let container;
  let client;

  beforeAll(async () => {
    // Start PostgreSQL container
    container = await new GenericContainer('postgres:14')
      .withEnv('POSTGRES_PASSWORD', 'test')
      .withEnv('POSTGRES_DB', 'testdb')
      .withExposedPorts(5432)
      .start();

    const port = container.getMappedPort(5432);
    
    client = new Client({
      host: 'localhost',
      port,
      database: 'testdb',
      user: 'postgres',
      password: 'test'
    });

    await client.connect();
    
    // Run migrations
    await runMigrations(client);
  }, 30000);

  afterAll(async () => {
    await client.end();
    await container.stop();
  });

  it('should handle concurrent transactions', async () => {
    // Test transaction isolation
    const promises = [];
    
    for (let i = 0; i < 10; i++) {
      promises.push(
        client.query('BEGIN')
          .then(() => client.query(
            'INSERT INTO users (email, username) VALUES ($1, $2)',
            [`user${i}@example.com`, `user${i}`]
          ))
          .then(() => client.query('COMMIT'))
      );
    }

    await Promise.all(promises);

    const result = await client.query('SELECT COUNT(*) FROM users');
    expect(parseInt(result.rows[0].count)).toBe(10);
  });
});
```

## 🔌 External Service Integration

### Testing with Mock Servers

```python
# tests/integration/test_external_services.py
import pytest
import httpx
from unittest.mock import patch, Mock
import responses
from app.services.payment_service import PaymentService
from app.services.email_service import EmailService

class TestPaymentIntegration:
    """Test payment service integration."""
    
    @responses.activate
    def test_process_payment_success(self):
        """Test successful payment processing."""
        # Mock payment API response
        responses.add(
            responses.POST,
            "https://api.payment.com/charge",
            json={"id": "ch_123", "status": "succeeded"},
            status=200
        )
        
        payment_service = PaymentService()
        result = payment_service.charge_card(
            amount=1000,
            currency="usd",
            card_token="tok_visa"
        )
        
        assert result["status"] == "succeeded"
        assert result["id"] == "ch_123"
        assert len(responses.calls) == 1
    
    @responses.activate
    def test_handle_payment_failure(self):
        """Test payment failure handling."""
        responses.add(
            responses.POST,
            "https://api.payment.com/charge",
            json={"error": {"message": "Card declined"}},
            status=402
        )
        
        payment_service = PaymentService()
        
        with pytest.raises(PaymentError) as exc_info:
            payment_service.charge_card(
                amount=1000,
                currency="usd",
                card_token="tok_declined"
            )
        
        assert "Card declined" in str(exc_info.value)
    
    async def test_webhook_processing(self, async_client, db):
        """Test webhook event processing."""
        webhook_data = {
            "id": "evt_123",
            "type": "payment.succeeded",
            "data": {
                "object": {
                    "id": "ch_123",
                    "amount": 1000,
                    "metadata": {"order_id": "order_456"}
                }
            }
        }
        
        # Mock signature verification
        with patch('app.services.payment_service.verify_webhook_signature') as mock_verify:
            mock_verify.return_value = True
            
            response = await async_client.post(
                "/api/v1/webhooks/payment",
                json=webhook_data,
                headers={"Stripe-Signature": "test_sig"}
            )
            
            assert response.status_code == 200
            
            # Verify order was updated
            order = await db.get(Order, "order_456")
            assert order.payment_status == "paid"
            assert order.payment_id == "ch_123"
```

### Testing with WireMock

```javascript
// tests/integration/external-api.test.js
const WireMock = require('wiremock-standalone');
const axios = require('axios');
const { WeatherService } = require('../../src/services/weatherService');

describe('Weather API Integration', () => {
  let wireMock;
  const port = 8080;

  beforeAll(async () => {
    wireMock = new WireMock({
      port,
      verbose: true
    });
    await wireMock.start();
  });

  afterAll(async () => {
    await wireMock.stop();
  });

  beforeEach(async () => {
    await wireMock.resetAll();
  });

  it('should fetch weather data', async () => {
    // Setup mock response
    await wireMock.stubFor({
      request: {
        method: 'GET',
        urlPath: '/weather',
        queryParameters: {
          city: { equalTo: 'London' }
        }
      },
      response: {
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        jsonBody: {
          temperature: 20,
          condition: 'sunny',
          humidity: 65
        }
      }
    });

    const weatherService = new WeatherService(`http://localhost:${port}`);
    const weather = await weatherService.getWeather('London');

    expect(weather.temperature).toBe(20);
    expect(weather.condition).toBe('sunny');

    // Verify the request was made
    const requests = await wireMock.getRequests();
    expect(requests).toHaveLength(1);
    expect(requests[0].request.queryParams.city).toBe('London');
  });

  it('should handle API errors gracefully', async () => {
    await wireMock.stubFor({
      request: {
        method: 'GET',
        urlPath: '/weather'
      },
      response: {
        status: 503,
        body: 'Service Unavailable'
      }
    });

    const weatherService = new WeatherService(`http://localhost:${port}`);
    
    await expect(weatherService.getWeather('London'))
      .rejects.toThrow('Weather service unavailable');
  });
});
```

## 🔄 Message Queue Integration

### Testing with RabbitMQ

```python
# tests/integration/test_messaging.py
import pytest
import asyncio
from unittest.mock import AsyncMock, patch
import aio_pika
from app.messaging.publisher import MessagePublisher
from app.messaging.consumer import MessageConsumer

@pytest.mark.asyncio
class TestMessagingIntegration:
    """Test message queue integration."""
    
    @pytest.fixture
    async def rabbitmq_connection(self):
        """Create RabbitMQ connection for tests."""
        connection = await aio_pika.connect_robust(
            "amqp://guest:guest@localhost/"
        )
        yield connection
        await connection.close()
    
    async def test_publish_and_consume(self, rabbitmq_connection):
        """Test publishing and consuming messages."""
        channel = await rabbitmq_connection.channel()
        queue_name = "test_queue"
        
        # Create queue
        queue = await channel.declare_queue(queue_name, auto_delete=True)
        
        # Publish message
        publisher = MessagePublisher(channel)
        message_data = {"event": "user.created", "user_id": 123}
        await publisher.publish(queue_name, message_data)
        
        # Consume message
        consumed_messages = []
        
        async def message_handler(message):
            consumed_messages.append(message)
        
        consumer = MessageConsumer(channel)
        await consumer.consume(queue_name, message_handler)
        
        # Wait for message processing
        await asyncio.sleep(0.1)
        
        assert len(consumed_messages) == 1
        assert consumed_messages[0]["event"] == "user.created"
        assert consumed_messages[0]["user_id"] == 123
    
    async def test_message_acknowledgment(self, rabbitmq_connection):
        """Test message acknowledgment and redelivery."""
        channel = await rabbitmq_connection.channel()
        queue = await channel.declare_queue("ack_test", auto_delete=True)
        
        # Publish message
        await channel.default_exchange.publish(
            aio_pika.Message(body=b'{"test": "data"}'),
            routing_key=queue.name
        )
        
        # First consumer - reject message
        async with queue.iterator() as queue_iter:
            async for message in queue_iter:
                await message.reject(requeue=True)
                break
        
        # Second consumer - acknowledge message
        message_received = False
        async with queue.iterator() as queue_iter:
            async for message in queue_iter:
                await message.ack()
                message_received = True
                break
        
        assert message_received
```

### Testing with Kafka

```javascript
// tests/integration/kafka.test.js
const { Kafka } = require('kafkajs');
const { KafkaProducer, KafkaConsumer } = require('../../src/messaging');

describe('Kafka Integration', () => {
  let kafka;
  let producer;
  let consumer;
  const topic = 'test-events';

  beforeAll(async () => {
    kafka = new Kafka({
      clientId: 'test-app',
      brokers: ['localhost:9092']
    });

    producer = new KafkaProducer(kafka);
    consumer = new KafkaConsumer(kafka, 'test-group');

    await producer.connect();
    await consumer.connect();
    await consumer.subscribe(topic);
  });

  afterAll(async () => {
    await producer.disconnect();
    await consumer.disconnect();
  });

  it('should produce and consume messages', async () => {
    const messages = [];
    
    // Set up consumer
    consumer.onMessage(async ({ message }) => {
      messages.push(JSON.parse(message.value.toString()));
    });

    // Start consuming
    const consumerPromise = consumer.run();

    // Produce messages
    await producer.send(topic, {
      key: 'user-123',
      value: { event: 'user.updated', userId: 123 }
    });

    // Wait for consumption
    await new Promise(resolve => setTimeout(resolve, 1000));

    expect(messages).toHaveLength(1);
    expect(messages[0].event).toBe('user.updated');
  });

  it('should handle batch messages', async () => {
    const batchMessages = Array.from({ length: 100 }, (_, i) => ({
      key: `key-${i}`,
      value: { id: i, timestamp: Date.now() }
    }));

    await producer.sendBatch(topic, batchMessages);

    // Verify messages were sent
    const metadata = await producer.getTopicMetadata(topic);
    expect(metadata.partitions.length).toBeGreaterThan(0);
  });
});
```

## 🔒 Authentication & Authorization Testing

### Complete Auth Flow Testing

```python
# tests/integration/test_auth_integration.py
@pytest.mark.asyncio
class TestAuthenticationIntegration:
    """Test complete authentication and authorization flows."""
    
    async def test_oauth2_flow(self, async_client, db):
        """Test OAuth2 authentication flow."""
        # Register user
        register_response = await async_client.post(
            "/api/v1/auth/register",
            json={
                "email": "oauth@example.com",
                "password": "SecurePass123!",
                "username": "oauthuser"
            }
        )
        assert register_response.status_code == 201
        
        # Login with OAuth2 password flow
        login_response = await async_client.post(
            "/api/v1/auth/token",
            data={
                "grant_type": "password",
                "username": "oauth@example.com",
                "password": "SecurePass123!"
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        assert login_response.status_code == 200
        tokens = login_response.json()
        assert tokens["token_type"] == "bearer"
        assert "access_token" in tokens
        assert "refresh_token" in tokens
        
        # Access protected resource
        headers = {"Authorization": f"Bearer {tokens['access_token']}"}
        protected_response = await async_client.get(
            "/api/v1/users/profile",
            headers=headers
        )
        assert protected_response.status_code == 200
        
        # Refresh token
        refresh_response = await async_client.post(
            "/api/v1/auth/token",
            data={
                "grant_type": "refresh_token",
                "refresh_token": tokens["refresh_token"]
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        assert refresh_response.status_code == 200
        new_tokens = refresh_response.json()
        assert new_tokens["access_token"] != tokens["access_token"]
    
    async def test_role_based_access(self, async_client, db):
        """Test role-based access control."""
        # Create users with different roles
        admin_user = UserFactory(role="admin")
        regular_user = UserFactory(role="user")
        db.add_all([admin_user, regular_user])
        await db.commit()
        
        admin_token = create_access_token(subject=str(admin_user.id))
        user_token = create_access_token(subject=str(regular_user.id))
        
        # Admin-only endpoint
        admin_response = await async_client.get(
            "/api/v1/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"}
        )
        assert admin_response.status_code == 200
        
        # Regular user should be forbidden
        user_response = await async_client.get(
            "/api/v1/admin/users",
            headers={"Authorization": f"Bearer {user_token}"}
        )
        assert user_response.status_code == 403
    
    async def test_api_key_authentication(self, async_client, db):
        """Test API key authentication."""
        # Create API key
        api_key = await create_api_key(
            name="Test API Key",
            scopes=["read:users", "write:posts"]
        )
        db.add(api_key)
        await db.commit()
        
        # Use API key
        headers = {"X-API-Key": api_key.key}
        
        # Allowed scope
        response = await async_client.get(
            "/api/v1/users",
            headers=headers
        )
        assert response.status_code == 200
        
        # Forbidden scope
        response = await async_client.delete(
            "/api/v1/users/1",
            headers=headers
        )
        assert response.status_code == 403
```

## 🎯 Best Practices

### Test Data Management

```python
# tests/fixtures/database.py
@pytest.fixture
async def seed_data(db: AsyncSession):
    """Seed database with test data."""
    # Create test data
    users = []
    for i in range(5):
        user = User(
            email=f"user{i}@example.com",
            username=f"user{i}",
            is_active=i % 2 == 0
        )
        users.append(user)
    
    db.add_all(users)
    await db.commit()
    
    yield users
    
    # Cleanup
    for user in users:
        await db.delete(user)
    await db.commit()
```

### Integration Test Structure

```javascript
// tests/helpers/setup.js
const setupTestDatabase = async () => {
  await sequelize.sync({ force: true });
  
  // Seed essential data
  await Role.bulkCreate([
    { name: 'admin', permissions: ['all'] },
    { name: 'user', permissions: ['read'] }
  ]);
};

const cleanupDatabase = async () => {
  await sequelize.truncate({ cascade: true });
};

module.exports = {
  setupTestDatabase,
  cleanupDatabase
};
```

### Performance Testing

```python
# tests/integration/test_performance.py
import time
import statistics

@pytest.mark.performance
async def test_api_response_time(async_client):
    """Test API response time under load."""
    response_times = []
    
    for _ in range(100):
        start = time.time()
        response = await async_client.get("/api/v1/health")
        end = time.time()
        
        response_times.append(end - start)
        assert response.status_code == 200
    
    avg_time = statistics.mean(response_times)
    p95_time = statistics.quantiles(response_times, n=20)[18]  # 95th percentile
    
    assert avg_time < 0.1  # Average under 100ms
    assert p95_time < 0.2  # 95th percentile under 200ms
```

---

*Integration tests verify that your application components work together correctly. Focus on testing real interactions between services, databases, and external APIs while maintaining test isolation and repeatability.*
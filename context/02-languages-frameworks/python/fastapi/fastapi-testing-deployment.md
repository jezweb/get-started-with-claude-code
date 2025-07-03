# FastAPI Testing Strategies and Production Deployment

## Overview
This guide covers comprehensive testing strategies for FastAPI applications and production deployment best practices, including unit testing, integration testing, performance testing, and deployment patterns.

## Testing Fundamentals

### Test Environment Setup
```python
import pytest
import asyncio
from fastapi.testclient import TestClient
from httpx import AsyncClient
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import sessionmaker
import tempfile
import os
from typing import Generator, AsyncGenerator

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Test app configuration
from main import app, get_db

def override_get_db():
    """Override database dependency for testing."""
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

# Test client setup
client = TestClient(app)

# Pytest fixtures
@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="function")
def test_db():
    """Create a fresh database for each test."""
    # Create all tables
    Base.metadata.create_all(bind=engine)
    
    yield TestingSessionLocal()
    
    # Drop all tables after test
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_client() -> Generator[TestClient, None, None]:
    """Create test client for synchronous tests."""
    with TestClient(app) as client:
        yield client

@pytest.fixture
async def async_client() -> AsyncGenerator[AsyncClient, None]:
    """Create async client for async tests."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.fixture
def sample_user_data():
    """Sample user data for testing."""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "TestPass123!",
        "confirm_password": "TestPass123!",
        "full_name": "Test User",
        "age": 25
    }

@pytest.fixture
def authenticated_headers(test_client: TestClient, sample_user_data: dict):
    """Get authentication headers for testing protected endpoints."""
    # Create user
    response = test_client.post("/users", json=sample_user_data)
    assert response.status_code == 201
    
    # Login to get token
    login_data = {
        "username": sample_user_data["username"],
        "password": sample_user_data["password"]
    }
    response = test_client.post("/auth/login", json=login_data)
    assert response.status_code == 200
    
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
```

### Unit Testing Patterns
```python
import pytest
from unittest.mock import Mock, patch, AsyncMock
from fastapi import HTTPException
from pydantic import ValidationError

# Test Pydantic models
class TestUserModels:
    """Test user model validation."""
    
    def test_user_create_valid_data(self, sample_user_data):
        """Test user creation with valid data."""
        user = UserCreate(**sample_user_data)
        assert user.username == "testuser"
        assert user.email == "test@example.com"
        assert user.age == 25
    
    def test_user_create_invalid_email(self, sample_user_data):
        """Test user creation with invalid email."""
        sample_user_data["email"] = "invalid-email"
        
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(**sample_user_data)
        
        errors = exc_info.value.errors()
        assert any(error["type"] == "value_error.email" for error in errors)
    
    def test_user_create_weak_password(self, sample_user_data):
        """Test user creation with weak password."""
        sample_user_data["password"] = "weak"
        sample_user_data["confirm_password"] = "weak"
        
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(**sample_user_data)
        
        errors = exc_info.value.errors()
        assert any("password" in str(error) for error in errors)
    
    def test_user_create_password_mismatch(self, sample_user_data):
        """Test user creation with password mismatch."""
        sample_user_data["confirm_password"] = "DifferentPass123!"
        
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(**sample_user_data)
        
        errors = exc_info.value.errors()
        assert any("confirmation" in str(error).lower() for error in errors)
    
    def test_user_create_reserved_username(self, sample_user_data):
        """Test user creation with reserved username."""
        sample_user_data["username"] = "admin"
        
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(**sample_user_data)
        
        errors = exc_info.value.errors()
        assert any("reserved" in str(error).lower() for error in errors)
    
    @pytest.mark.parametrize("age,should_pass", [
        (12, False),  # Too young
        (13, True),   # Minimum age
        (25, True),   # Normal age
        (120, True),  # Maximum age
        (121, False), # Too old
    ])
    def test_user_age_validation(self, sample_user_data, age, should_pass):
        """Test age validation with various values."""
        sample_user_data["age"] = age
        
        if should_pass:
            user = UserCreate(**sample_user_data)
            assert user.age == age
        else:
            with pytest.raises(ValidationError):
                UserCreate(**sample_user_data)

# Test business logic functions
class TestUserService:
    """Test user service business logic."""
    
    @pytest.fixture
    def user_service(self):
        """Create user service instance for testing."""
        return UserService()
    
    def test_password_hashing(self, user_service):
        """Test password hashing functionality."""
        password = "TestPassword123!"
        hashed = user_service.hash_password(password)
        
        assert hashed != password
        assert user_service.verify_password(password, hashed)
        assert not user_service.verify_password("wrong_password", hashed)
    
    def test_generate_username_suggestions(self, user_service):
        """Test username suggestion generation."""
        base_name = "john"
        existing_usernames = ["john", "john1", "john2"]
        
        suggestions = user_service.generate_username_suggestions(base_name, existing_usernames)
        
        assert len(suggestions) > 0
        assert all(suggestion not in existing_usernames for suggestion in suggestions)
        assert all(suggestion.startswith(base_name) for suggestion in suggestions)
    
    @patch('user_service.send_email')
    def test_send_welcome_email(self, mock_send_email, user_service, sample_user_data):
        """Test welcome email sending with mocked email service."""
        user = UserCreate(**sample_user_data)
        
        user_service.send_welcome_email(user)
        
        mock_send_email.assert_called_once()
        call_args = mock_send_email.call_args
        assert user.email in call_args[0]
        assert "welcome" in call_args[1].lower()

# Test async functions
class TestAsyncUserService:
    """Test async user service methods."""
    
    @pytest.mark.asyncio
    async def test_async_user_creation(self):
        """Test async user creation."""
        user_data = {
            "username": "asyncuser",
            "email": "async@example.com",
            "password": "AsyncPass123!"
        }
        
        service = AsyncUserService()
        result = await service.create_user(user_data)
        
        assert result["username"] == "asyncuser"
        assert "password" not in result  # Password should not be in response
    
    @pytest.mark.asyncio
    async def test_async_database_error_handling(self):
        """Test handling of database errors in async methods."""
        service = AsyncUserService()
        
        # Mock database to raise an exception
        with patch.object(service, 'db') as mock_db:
            mock_db.execute.side_effect = Exception("Database connection failed")
            
            with pytest.raises(HTTPException) as exc_info:
                await service.get_user_by_id(999)
            
            assert exc_info.value.status_code == 500
    
    @pytest.mark.asyncio
    async def test_concurrent_user_operations(self):
        """Test concurrent user operations."""
        service = AsyncUserService()
        
        # Create multiple users concurrently
        user_data_list = [
            {"username": f"user{i}", "email": f"user{i}@example.com", "password": "Pass123!"}
            for i in range(5)
        ]
        
        tasks = [service.create_user(data) for data in user_data_list]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Check that all operations completed successfully
        successful_results = [r for r in results if not isinstance(r, Exception)]
        assert len(successful_results) == 5

# Test validation functions
class TestValidationFunctions:
    """Test custom validation functions."""
    
    def test_validate_phone_number(self):
        """Test phone number validation."""
        valid_phones = ["+1234567890", "1234567890", "+12345678901234"]
        invalid_phones = ["123", "abc123", "+123abc456"]
        
        for phone in valid_phones:
            assert validate_phone_number(phone)
        
        for phone in invalid_phones:
            assert not validate_phone_number(phone)
    
    def test_validate_website_url(self):
        """Test website URL validation."""
        valid_urls = [
            "https://example.com",
            "http://test.org",
            "https://sub.domain.com/path"
        ]
        invalid_urls = [
            "not-a-url",
            "ftp://example.com",
            "https://"
        ]
        
        for url in valid_urls:
            result = validate_website_url(url)
            assert result.startswith(('http://', 'https://'))
        
        for url in invalid_urls:
            with pytest.raises(ValueError):
                validate_website_url(url)
```

### Integration Testing
```python
class TestUserEndpoints:
    """Integration tests for user endpoints."""
    
    def test_create_user_success(self, test_client: TestClient, sample_user_data):
        """Test successful user creation."""
        response = test_client.post("/users", json=sample_user_data)
        
        assert response.status_code == 201
        data = response.json()
        assert data["username"] == sample_user_data["username"]
        assert data["email"] == sample_user_data["email"]
        assert "password" not in data
        assert "id" in data
        assert "created_at" in data
    
    def test_create_user_duplicate_username(self, test_client: TestClient, sample_user_data):
        """Test user creation with duplicate username."""
        # Create first user
        response = test_client.post("/users", json=sample_user_data)
        assert response.status_code == 201
        
        # Try to create user with same username
        duplicate_data = sample_user_data.copy()
        duplicate_data["email"] = "different@example.com"
        
        response = test_client.post("/users", json=duplicate_data)
        assert response.status_code == 400
        assert "username" in response.json()["detail"].lower()
    
    def test_get_user_success(self, test_client: TestClient, sample_user_data):
        """Test successful user retrieval."""
        # Create user
        create_response = test_client.post("/users", json=sample_user_data)
        user_id = create_response.json()["id"]
        
        # Get user
        response = test_client.get(f"/users/{user_id}")
        assert response.status_code == 200
        
        data = response.json()
        assert data["id"] == user_id
        assert data["username"] == sample_user_data["username"]
    
    def test_get_user_not_found(self, test_client: TestClient):
        """Test user retrieval for non-existent user."""
        response = test_client.get("/users/99999")
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()
    
    def test_update_user_success(self, test_client: TestClient, sample_user_data):
        """Test successful user update."""
        # Create user
        create_response = test_client.post("/users", json=sample_user_data)
        user_id = create_response.json()["id"]
        
        # Update user
        update_data = {"full_name": "Updated Name", "age": 30}
        response = test_client.put(f"/users/{user_id}", json=update_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"
        assert data["age"] == 30
        assert data["username"] == sample_user_data["username"]  # Unchanged
    
    def test_delete_user_success(self, test_client: TestClient, sample_user_data):
        """Test successful user deletion."""
        # Create user
        create_response = test_client.post("/users", json=sample_user_data)
        user_id = create_response.json()["id"]
        
        # Delete user
        response = test_client.delete(f"/users/{user_id}")
        assert response.status_code == 204
        
        # Verify user is deleted
        get_response = test_client.get(f"/users/{user_id}")
        assert get_response.status_code == 404
    
    def test_list_users_pagination(self, test_client: TestClient):
        """Test user listing with pagination."""
        # Create multiple users
        for i in range(15):
            user_data = {
                "username": f"user{i}",
                "email": f"user{i}@example.com",
                "password": "TestPass123!",
                "confirm_password": "TestPass123!",
                "full_name": f"User {i}",
                "age": 25 + i
            }
            response = test_client.post("/users", json=user_data)
            assert response.status_code == 201
        
        # Test first page
        response = test_client.get("/users?limit=10&offset=0")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10
        
        # Test second page
        response = test_client.get("/users?limit=10&offset=10")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5
    
    def test_user_search_functionality(self, test_client: TestClient):
        """Test user search functionality."""
        # Create test users
        users_data = [
            {"username": "alice", "email": "alice@example.com", "full_name": "Alice Johnson", "age": 25},
            {"username": "bob", "email": "bob@example.com", "full_name": "Bob Smith", "age": 30},
            {"username": "charlie", "email": "charlie@example.com", "full_name": "Charlie Brown", "age": 35},
        ]
        
        for user_data in users_data:
            full_data = {**user_data, "password": "TestPass123!", "confirm_password": "TestPass123!"}
            response = test_client.post("/users", json=full_data)
            assert response.status_code == 201
        
        # Search by username
        response = test_client.get("/users/search?username_contains=ali")
        assert response.status_code == 200
        results = response.json()
        assert len(results) == 1
        assert results[0]["username"] == "alice"
        
        # Search by age range
        response = test_client.get("/users/search?age_min=30")
        assert response.status_code == 200
        results = response.json()
        assert len(results) == 2
        assert all(user["age"] >= 30 for user in results)

# Test authentication endpoints
class TestAuthenticationEndpoints:
    """Integration tests for authentication."""
    
    def test_login_success(self, test_client: TestClient, sample_user_data):
        """Test successful login."""
        # Create user
        create_response = test_client.post("/users", json=sample_user_data)
        assert create_response.status_code == 201
        
        # Login
        login_data = {
            "username": sample_user_data["username"],
            "password": sample_user_data["password"]
        }
        response = test_client.post("/auth/login", json=login_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
    
    def test_login_invalid_credentials(self, test_client: TestClient, sample_user_data):
        """Test login with invalid credentials."""
        # Create user
        test_client.post("/users", json=sample_user_data)
        
        # Try login with wrong password
        login_data = {
            "username": sample_user_data["username"],
            "password": "wrong_password"
        }
        response = test_client.post("/auth/login", json=login_data)
        
        assert response.status_code == 401
        assert "incorrect" in response.json()["detail"].lower()
    
    def test_protected_endpoint_without_token(self, test_client: TestClient):
        """Test access to protected endpoint without token."""
        response = test_client.get("/protected")
        assert response.status_code == 401
    
    def test_protected_endpoint_with_token(self, test_client: TestClient, authenticated_headers):
        """Test access to protected endpoint with valid token."""
        response = test_client.get("/protected", headers=authenticated_headers)
        assert response.status_code == 200
        assert "authenticated" in response.json()["message"].lower()
    
    def test_token_refresh(self, test_client: TestClient, sample_user_data):
        """Test token refresh functionality."""
        # Create user and login
        test_client.post("/users", json=sample_user_data)
        login_data = {
            "username": sample_user_data["username"],
            "password": sample_user_data["password"]
        }
        login_response = test_client.post("/auth/login", json=login_data)
        refresh_token = login_response.json()["refresh_token"]
        
        # Refresh token
        headers = {"Authorization": f"Bearer {refresh_token}"}
        response = test_client.post("/auth/refresh", headers=headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data

# Test async endpoints
class TestAsyncEndpoints:
    """Test async endpoint functionality."""
    
    @pytest.mark.asyncio
    async def test_async_user_creation(self, async_client: AsyncClient, sample_user_data):
        """Test async user creation endpoint."""
        response = await async_client.post("/users", json=sample_user_data)
        
        assert response.status_code == 201
        data = response.json()
        assert data["username"] == sample_user_data["username"]
    
    @pytest.mark.asyncio
    async def test_concurrent_requests(self, async_client: AsyncClient):
        """Test handling of concurrent requests."""
        # Create multiple concurrent requests
        tasks = []
        for i in range(10):
            user_data = {
                "username": f"concurrent_user_{i}",
                "email": f"concurrent_{i}@example.com",
                "password": "TestPass123!",
                "confirm_password": "TestPass123!",
                "full_name": f"Concurrent User {i}",
                "age": 25
            }
            task = async_client.post("/users", json=user_data)
            tasks.append(task)
        
        responses = await asyncio.gather(*tasks)
        
        # All requests should succeed
        assert all(response.status_code == 201 for response in responses)
        
        # All users should have unique IDs
        user_ids = [response.json()["id"] for response in responses]
        assert len(set(user_ids)) == len(user_ids)
```

### Performance Testing
```python
import time
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed
import psutil
import threading

class PerformanceTestCase:
    """Base class for performance testing."""
    
    def __init__(self, test_client: TestClient):
        self.client = test_client
        self.response_times = []
        self.error_count = 0
        self.success_count = 0
    
    def measure_response_time(self, func, *args, **kwargs):
        """Measure response time for a function call."""
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            end_time = time.time()
            self.response_times.append(end_time - start_time)
            
            if hasattr(result, 'status_code') and result.status_code < 400:
                self.success_count += 1
            else:
                self.error_count += 1
                
            return result
        except Exception as e:
            end_time = time.time()
            self.response_times.append(end_time - start_time)
            self.error_count += 1
            raise e
    
    def get_stats(self):
        """Get performance statistics."""
        if not self.response_times:
            return {}
        
        return {
            "total_requests": len(self.response_times),
            "success_count": self.success_count,
            "error_count": self.error_count,
            "success_rate": self.success_count / len(self.response_times) * 100,
            "avg_response_time": statistics.mean(self.response_times),
            "median_response_time": statistics.median(self.response_times),
            "min_response_time": min(self.response_times),
            "max_response_time": max(self.response_times),
            "95th_percentile": statistics.quantiles(self.response_times, n=20)[18] if len(self.response_times) > 20 else max(self.response_times)
        }

class TestAPIPerformance:
    """Performance tests for API endpoints."""
    
    @pytest.fixture
    def performance_tester(self, test_client):
        """Create performance tester instance."""
        return PerformanceTestCase(test_client)
    
    def test_user_creation_performance(self, test_client: TestClient, performance_tester: PerformanceTestCase):
        """Test user creation endpoint performance."""
        
        def create_user(index):
            user_data = {
                "username": f"perf_user_{index}",
                "email": f"perf_user_{index}@example.com",
                "password": "TestPass123!",
                "confirm_password": "TestPass123!",
                "full_name": f"Performance User {index}",
                "age": 25
            }
            return performance_tester.measure_response_time(
                test_client.post, "/users", json=user_data
            )
        
        # Sequential test
        num_requests = 100
        for i in range(num_requests):
            create_user(i)
        
        stats = performance_tester.get_stats()
        
        # Performance assertions
        assert stats["success_rate"] >= 95  # At least 95% success rate
        assert stats["avg_response_time"] < 1.0  # Average response time under 1 second
        assert stats["95th_percentile"] < 2.0  # 95th percentile under 2 seconds
        
        print(f"Performance Stats: {stats}")
    
    def test_concurrent_user_creation(self, test_client: TestClient):
        """Test concurrent user creation performance."""
        num_threads = 10
        requests_per_thread = 10
        
        results = []
        start_time = time.time()
        
        def worker(thread_id):
            thread_results = []
            for i in range(requests_per_thread):
                user_data = {
                    "username": f"concurrent_user_{thread_id}_{i}",
                    "email": f"concurrent_user_{thread_id}_{i}@example.com",
                    "password": "TestPass123!",
                    "confirm_password": "TestPass123!",
                    "full_name": f"Concurrent User {thread_id} {i}",
                    "age": 25
                }
                
                request_start = time.time()
                response = test_client.post("/users", json=user_data)
                request_end = time.time()
                
                thread_results.append({
                    "status_code": response.status_code,
                    "response_time": request_end - request_start
                })
            
            return thread_results
        
        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = [executor.submit(worker, i) for i in range(num_threads)]
            
            for future in as_completed(futures):
                results.extend(future.result())
        
        end_time = time.time()
        total_time = end_time - start_time
        
        # Analyze results
        successful_requests = [r for r in results if r["status_code"] < 400]
        response_times = [r["response_time"] for r in results]
        
        success_rate = len(successful_requests) / len(results) * 100
        avg_response_time = statistics.mean(response_times)
        throughput = len(results) / total_time
        
        # Performance assertions
        assert success_rate >= 90  # At least 90% success rate under load
        assert avg_response_time < 2.0  # Average response time under 2 seconds
        assert throughput >= 10  # At least 10 requests per second
        
        print(f"Concurrent Performance:")
        print(f"  Success Rate: {success_rate:.2f}%")
        print(f"  Average Response Time: {avg_response_time:.3f}s")
        print(f"  Throughput: {throughput:.2f} req/s")
        print(f"  Total Time: {total_time:.3f}s")
    
    def test_memory_usage_under_load(self, test_client: TestClient):
        """Test memory usage under load."""
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Create load
        for i in range(200):
            user_data = {
                "username": f"memory_test_user_{i}",
                "email": f"memory_test_{i}@example.com",
                "password": "TestPass123!",
                "confirm_password": "TestPass123!",
                "full_name": f"Memory Test User {i}",
                "age": 25
            }
            response = test_client.post("/users", json=user_data)
            assert response.status_code == 201
        
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        print(f"Memory Usage:")
        print(f"  Initial: {initial_memory:.2f} MB")
        print(f"  Final: {final_memory:.2f} MB")
        print(f"  Increase: {memory_increase:.2f} MB")
        
        # Memory should not increase dramatically (adjust threshold as needed)
        assert memory_increase < 100  # Less than 100MB increase

# Load testing with locust (optional)
try:
    from locust import HttpUser, task, between
    
    class APILoadTest(HttpUser):
        """Locust load test for API endpoints."""
        
        wait_time = between(1, 3)
        
        def on_start(self):
            """Setup for each user."""
            self.user_count = 0
        
        @task(3)
        def create_user(self):
            """Create user task (higher weight)."""
            self.user_count += 1
            user_data = {
                "username": f"load_user_{self.user_count}_{int(time.time())}",
                "email": f"load_user_{self.user_count}_{int(time.time())}@example.com",
                "password": "TestPass123!",
                "confirm_password": "TestPass123!",
                "full_name": f"Load Test User {self.user_count}",
                "age": 25
            }
            
            with self.client.post("/users", json=user_data, catch_response=True) as response:
                if response.status_code == 201:
                    response.success()
                else:
                    response.failure(f"Failed to create user: {response.status_code}")
        
        @task(1)
        def get_users(self):
            """Get users list task."""
            with self.client.get("/users", catch_response=True) as response:
                if response.status_code == 200:
                    response.success()
                else:
                    response.failure(f"Failed to get users: {response.status_code}")

except ImportError:
    print("Locust not installed. Skipping load test definitions.")
```

## Production Deployment

### Docker Configuration
```dockerfile
# Dockerfile
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create and set work directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=${SECRET_KEY}
      - DEBUG=False
    depends_on:
      - db
      - redis
    volumes:
      - ./app:/app
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
```

### Production Configuration
```python
# config.py
import os
from typing import Optional
from pydantic import BaseSettings, validator

class Settings(BaseSettings):
    """Application settings."""
    
    # Basic settings
    app_name: str = "FastAPI App"
    debug: bool = False
    version: str = "1.0.0"
    
    # Security
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # Database
    database_url: str
    database_pool_size: int = 20
    database_max_overflow: int = 0
    database_pool_timeout: int = 30
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    # CORS
    cors_origins: list[str] = ["*"]
    
    # Rate limiting
    rate_limit_requests: int = 100
    rate_limit_window: int = 60
    
    # Logging
    log_level: str = "INFO"
    log_format: str = "json"
    
    # Monitoring
    enable_metrics: bool = True
    metrics_port: int = 9090
    
    # File upload
    max_file_size: int = 10 * 1024 * 1024  # 10MB
    upload_dir: str = "/app/uploads"
    
    # Email
    smtp_host: Optional[str] = None
    smtp_port: int = 587
    smtp_username: Optional[str] = None
    smtp_password: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = False
    
    @validator('cors_origins', pre=True)
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v
    
    @validator('secret_key')
    def validate_secret_key(cls, v):
        if not v or len(v) < 32:
            raise ValueError('Secret key must be at least 32 characters long')
        return v

# Load settings
settings = Settings()

# Logging configuration
import logging
import sys
from logging.handlers import RotatingFileHandler

def setup_logging():
    """Setup application logging."""
    
    # Create logger
    logger = logging.getLogger("fastapi_app")
    logger.setLevel(getattr(logging, settings.log_level))
    
    # Create formatters
    if settings.log_format == "json":
        import json
        
        class JsonFormatter(logging.Formatter):
            def format(self, record):
                log_entry = {
                    "timestamp": self.formatTime(record),
                    "level": record.levelname,
                    "logger": record.name,
                    "message": record.getMessage(),
                    "module": record.module,
                    "function": record.funcName,
                    "line": record.lineno
                }
                
                if record.exc_info:
                    log_entry["exception"] = self.formatException(record.exc_info)
                
                return json.dumps(log_entry)
        
        formatter = JsonFormatter()
    else:
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler (in production)
    if not settings.debug:
        file_handler = RotatingFileHandler(
            'app.log',
            maxBytes=10485760,  # 10MB
            backupCount=5
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    
    return logger

logger = setup_logging()
```

### Monitoring and Observability
```python
# monitoring.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import time
import psutil
import os

# Prometheus metrics
REQUEST_COUNT = Counter(
    'fastapi_requests_total',
    'Total requests',
    ['method', 'endpoint', 'status_code']
)

REQUEST_DURATION = Histogram(
    'fastapi_request_duration_seconds',
    'Request duration',
    ['method', 'endpoint']
)

ACTIVE_CONNECTIONS = Gauge(
    'fastapi_active_connections',
    'Active connections'
)

MEMORY_USAGE = Gauge(
    'fastapi_memory_usage_bytes',
    'Memory usage in bytes'
)

CPU_USAGE = Gauge(
    'fastapi_cpu_usage_percent',
    'CPU usage percentage'
)

class PrometheusMiddleware(BaseHTTPMiddleware):
    """Middleware to collect Prometheus metrics."""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Increment active connections
        ACTIVE_CONNECTIONS.inc()
        
        try:
            response = await call_next(request)
            
            # Record metrics
            duration = time.time() - start_time
            
            REQUEST_COUNT.labels(
                method=request.method,
                endpoint=request.url.path,
                status_code=response.status_code
            ).inc()
            
            REQUEST_DURATION.labels(
                method=request.method,
                endpoint=request.url.path
            ).observe(duration)
            
            return response
            
        finally:
            # Decrement active connections
            ACTIVE_CONNECTIONS.dec()

def update_system_metrics():
    """Update system metrics."""
    process = psutil.Process(os.getpid())
    
    # Memory usage
    memory_info = process.memory_info()
    MEMORY_USAGE.set(memory_info.rss)
    
    # CPU usage
    cpu_percent = process.cpu_percent()
    CPU_USAGE.set(cpu_percent)

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    try:
        # Check database connection
        async with get_db() as db:
            await db.execute("SELECT 1")
        
        # Check Redis connection
        redis_client = await get_redis()
        await redis_client.ping()
        
        # Update system metrics
        update_system_metrics()
        
        return {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "version": settings.version
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(500, "Service unhealthy")

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(
        generate_latest(),
        media_type="text/plain"
    )

# Add middleware
app.add_middleware(PrometheusMiddleware)

# Structured logging with correlation IDs
class CorrelationMiddleware(BaseHTTPMiddleware):
    """Add correlation ID to requests."""
    
    async def dispatch(self, request: Request, call_next):
        correlation_id = request.headers.get("X-Correlation-ID") or str(uuid.uuid4())
        
        # Add to request state
        request.state.correlation_id = correlation_id
        
        # Add to logging context
        with logger.bind(correlation_id=correlation_id):
            response = await call_next(request)
            response.headers["X-Correlation-ID"] = correlation_id
            return response

app.add_middleware(CorrelationMiddleware)
```

### Deployment Scripts
```bash
#!/bin/bash
# deploy.sh

set -e

echo "Starting deployment..."

# Environment variables
ENVIRONMENT=${1:-production}
VERSION=$(git rev-parse --short HEAD)
IMAGE_NAME="myapp:${VERSION}"

echo "Deploying version: ${VERSION}"
echo "Environment: ${ENVIRONMENT}"

# Build Docker image
echo "Building Docker image..."
docker build -t "${IMAGE_NAME}" .

# Tag for registry
docker tag "${IMAGE_NAME}" "registry.example.com/${IMAGE_NAME}"

# Push to registry
echo "Pushing to registry..."
docker push "registry.example.com/${IMAGE_NAME}"

# Deploy with docker-compose
echo "Deploying with docker-compose..."
export IMAGE_TAG="${VERSION}"
docker-compose -f docker-compose.${ENVIRONMENT}.yml up -d

# Health check
echo "Performing health check..."
sleep 10

for i in {1..30}; do
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "Deployment successful!"
        exit 0
    fi
    echo "Waiting for service to be ready... ($i/30)"
    sleep 2
done

echo "Deployment failed - service not responding"
exit 1
```

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-asyncio
      
      - name: Run tests
        run: pytest tests/ -v --cov=app --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to production
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          SERVER_HOST: ${{ secrets.SERVER_HOST }}
        run: |
          echo "$DEPLOY_KEY" | tr -d '\r' | ssh-add -
          ssh -o StrictHostKeyChecking=no user@$SERVER_HOST 'bash -s' < deploy.sh
```

### Security Best Practices
```python
# security.py
from fastapi import Security, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import secrets
import hashlib
import hmac
from typing import Optional

# Security headers middleware
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to all responses."""
    
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        
        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        
        return response

# Rate limiting with Redis
class RedisRateLimiter:
    """Redis-based rate limiter."""
    
    def __init__(self, redis_client, max_requests: int = 100, window_seconds: int = 60):
        self.redis = redis_client
        self.max_requests = max_requests
        self.window_seconds = window_seconds
    
    async def is_allowed(self, identifier: str) -> bool:
        """Check if request is allowed."""
        key = f"rate_limit:{identifier}"
        
        # Use sliding window
        now = time.time()
        pipeline = self.redis.pipeline()
        
        # Remove old entries
        pipeline.zremrangebyscore(key, 0, now - self.window_seconds)
        
        # Count current requests
        pipeline.zcard(key)
        
        # Add current request
        pipeline.zadd(key, {str(now): now})
        
        # Set expiration
        pipeline.expire(key, self.window_seconds)
        
        results = await pipeline.execute()
        request_count = results[1]
        
        return request_count < self.max_requests

# Input sanitization
def sanitize_input(value: str) -> str:
    """Sanitize user input."""
    if not value:
        return value
    
    # Remove HTML tags
    import re
    value = re.sub(r'<[^>]+>', '', value)
    
    # Remove potentially dangerous characters
    dangerous_chars = ['<', '>', '"', "'", '&', '\x00']
    for char in dangerous_chars:
        value = value.replace(char, '')
    
    return value.strip()

# SQL injection prevention (using parameterized queries)
async def safe_database_query(query: str, params: tuple):
    """Execute database query safely."""
    # Always use parameterized queries
    async with get_db() as db:
        result = await db.execute(query, params)
        return result.fetchall()

# API key validation
def validate_api_signature(
    payload: str,
    signature: str,
    secret: str
) -> bool:
    """Validate API signature."""
    expected_signature = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(signature, expected_signature)

# Environment-specific configuration
class ProductionSettings(Settings):
    """Production-specific settings."""
    
    debug: bool = False
    
    # Force HTTPS
    force_https: bool = True
    
    # Database connection with SSL
    database_url: str = Field(..., regex=r'^postgresql.*sslmode=require')
    
    # Secure cookies
    session_cookie_secure: bool = True
    session_cookie_httponly: bool = True
    session_cookie_samesite: str = "strict"
    
    # Strong secrets
    secret_key: str = Field(..., min_length=64)
    
    # Rate limiting
    rate_limit_requests: int = 50  # Stricter in production
    
    # Logging
    log_level: str = "WARNING"
    
    # CORS - restrict origins
    cors_origins: list[str] = Field(default_factory=list)
```

---

**Last Updated:** Based on FastAPI 0.100+, pytest 7+, and modern deployment practices
**References:**
- [FastAPI Testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [pytest Documentation](https://docs.pytest.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Prometheus Python Client](https://github.com/prometheus/client_python)
# FastAPI Core Concepts and Dependency Injection

## Overview
This guide covers FastAPI's core concepts, dependency injection system, and essential patterns for building robust web APIs. FastAPI combines the simplicity of Flask with the power of modern Python type hints and automatic API documentation.

## FastAPI Fundamentals

### Basic FastAPI Application
```python
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

# Create FastAPI instance
app = FastAPI(
    title="My API",
    description="A comprehensive API built with FastAPI",
    version="1.0.0",
    docs_url="/docs",  # Swagger UI
    redoc_url="/redoc"  # ReDoc
)

# Basic models
class User(BaseModel):
    id: int
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    created_at: datetime = Field(default_factory=datetime.now)
    is_active: bool = True

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')

class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[str] = Field(None, regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    is_active: Optional[bool] = None

# In-memory storage (replace with database in production)
users_db: dict[int, User] = {}
next_user_id = 1

# Basic endpoints
@app.get("/")
async def root():
    """Root endpoint with welcome message."""
    return {"message": "Welcome to FastAPI"}

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "timestamp": datetime.now()}
```

### Path Parameters and Query Parameters
```python
from fastapi import Query, Path
from typing import Annotated

@app.get("/users/{user_id}")
async def get_user(
    user_id: Annotated[int, Path(description="The ID of the user", gt=0)]
) -> User:
    """Get a specific user by ID."""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    return users_db[user_id]

@app.get("/users")
async def list_users(
    skip: Annotated[int, Query(description="Number of users to skip", ge=0)] = 0,
    limit: Annotated[int, Query(description="Maximum number of users to return", gt=0, le=100)] = 10,
    active_only: Annotated[bool, Query(description="Filter by active users only")] = False,
    search: Annotated[Optional[str], Query(description="Search users by name", max_length=50)] = None
) -> List[User]:
    """List users with pagination and filtering."""
    filtered_users = list(users_db.values())
    
    # Apply filters
    if active_only:
        filtered_users = [user for user in filtered_users if user.is_active]
    
    if search:
        filtered_users = [
            user for user in filtered_users 
            if search.lower() in user.name.lower()
        ]
    
    # Apply pagination
    return filtered_users[skip:skip + limit]

@app.post("/users", status_code=status.HTTP_201_CREATED)
async def create_user(user_data: UserCreate) -> User:
    """Create a new user."""
    global next_user_id
    
    # Check if email already exists
    for existing_user in users_db.values():
        if existing_user.email == user_data.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # Create new user
    new_user = User(
        id=next_user_id,
        name=user_data.name,
        email=user_data.email
    )
    
    users_db[next_user_id] = new_user
    next_user_id += 1
    
    return new_user

@app.put("/users/{user_id}")
async def update_user(
    user_id: Annotated[int, Path(gt=0)],
    user_updates: UserUpdate
) -> User:
    """Update an existing user."""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    
    user = users_db[user_id]
    update_data = user_updates.dict(exclude_unset=True)
    
    # Check email uniqueness if email is being updated
    if "email" in update_data:
        for uid, existing_user in users_db.items():
            if uid != user_id and existing_user.email == update_data["email"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )
    
    # Update user
    for field, value in update_data.items():
        setattr(user, field, value)
    
    return user

@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: Annotated[int, Path(gt=0)]):
    """Delete a user."""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    
    del users_db[user_id]
```

## Dependency Injection System

### Basic Dependencies
```python
from fastapi import Depends, Header, HTTPException
from typing import Annotated, Optional

# Simple dependency function
def get_current_timestamp() -> datetime:
    """Dependency that provides current timestamp."""
    return datetime.now()

def get_api_key(
    x_api_key: Annotated[Optional[str], Header()] = None
) -> str:
    """Dependency that validates API key."""
    if not x_api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required"
        )
    
    # In production, validate against database or config
    valid_keys = ["secret-api-key-123", "another-valid-key"]
    if x_api_key not in valid_keys:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid API key"
        )
    
    return x_api_key

def get_user_agent(
    user_agent: Annotated[Optional[str], Header()] = None
) -> str:
    """Dependency that provides user agent."""
    return user_agent or "Unknown"

# Using dependencies in endpoints
@app.get("/protected")
async def protected_endpoint(
    timestamp: Annotated[datetime, Depends(get_current_timestamp)],
    api_key: Annotated[str, Depends(get_api_key)],
    user_agent: Annotated[str, Depends(get_user_agent)]
):
    """Protected endpoint that requires API key."""
    return {
        "message": "Access granted",
        "timestamp": timestamp,
        "api_key": api_key[:8] + "...",  # Don't expose full key
        "user_agent": user_agent
    }
```

### Database Connection Dependencies
```python
import asyncpg
from contextlib import asynccontextmanager
from typing import AsyncGenerator

# Database configuration
DATABASE_URL = "postgresql://user:password@localhost/mydb"

class DatabaseManager:
    """Database connection manager."""
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.pool: Optional[asyncpg.Pool] = None
    
    async def create_pool(self):
        """Create database connection pool."""
        self.pool = await asyncpg.create_pool(self.database_url)
    
    async def close_pool(self):
        """Close database connection pool."""
        if self.pool:
            await self.pool.close()
    
    @asynccontextmanager
    async def get_connection(self) -> AsyncGenerator[asyncpg.Connection, None]:
        """Get database connection from pool."""
        if not self.pool:
            raise RuntimeError("Database pool not initialized")
        
        async with self.pool.acquire() as connection:
            yield connection

# Global database manager
db_manager = DatabaseManager(DATABASE_URL)

# Dependency to get database connection
async def get_db_connection() -> AsyncGenerator[asyncpg.Connection, None]:
    """Dependency that provides database connection."""
    async with db_manager.get_connection() as connection:
        yield connection

# Application lifespan events
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    await db_manager.create_pool()
    yield
    # Shutdown
    await db_manager.close_pool()

# Update FastAPI app with lifespan
app = FastAPI(lifespan=lifespan)

# Using database dependency
@app.get("/users/db")
async def get_users_from_db(
    db: Annotated[asyncpg.Connection, Depends(get_db_connection)]
) -> List[dict]:
    """Get users from database."""
    rows = await db.fetch("SELECT id, name, email FROM users ORDER BY id")
    return [dict(row) for row in rows]

@app.post("/users/db")
async def create_user_in_db(
    user_data: UserCreate,
    db: Annotated[asyncpg.Connection, Depends(get_db_connection)]
) -> dict:
    """Create user in database."""
    row = await db.fetchrow(
        "INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id, name, email, created_at",
        user_data.name,
        user_data.email
    )
    return dict(row)
```

### Class-Based Dependencies
```python
from dataclasses import dataclass
from typing import Protocol

class UserRepository(Protocol):
    """User repository protocol."""
    async def get_by_id(self, user_id: int) -> Optional[User]: ...
    async def create(self, user_data: UserCreate) -> User: ...
    async def update(self, user_id: int, updates: dict) -> Optional[User]: ...
    async def delete(self, user_id: int) -> bool: ...

@dataclass
class MemoryUserRepository:
    """In-memory user repository implementation."""
    
    def __init__(self):
        self.users: dict[int, User] = {}
        self.next_id = 1
    
    async def get_by_id(self, user_id: int) -> Optional[User]:
        return self.users.get(user_id)
    
    async def create(self, user_data: UserCreate) -> User:
        user = User(
            id=self.next_id,
            name=user_data.name,
            email=user_data.email
        )
        self.users[self.next_id] = user
        self.next_id += 1
        return user
    
    async def update(self, user_id: int, updates: dict) -> Optional[User]:
        user = self.users.get(user_id)
        if not user:
            return None
        
        for field, value in updates.items():
            setattr(user, field, value)
        
        return user
    
    async def delete(self, user_id: int) -> bool:
        if user_id in self.users:
            del self.users[user_id]
            return True
        return False

class DatabaseUserRepository:
    """Database user repository implementation."""
    
    def __init__(self, db_connection: asyncpg.Connection):
        self.db = db_connection
    
    async def get_by_id(self, user_id: int) -> Optional[User]:
        row = await self.db.fetchrow(
            "SELECT id, name, email, created_at, is_active FROM users WHERE id = $1",
            user_id
        )
        return User(**dict(row)) if row else None
    
    async def create(self, user_data: UserCreate) -> User:
        row = await self.db.fetchrow(
            "INSERT INTO users (name, email) VALUES ($1, $2) "
            "RETURNING id, name, email, created_at, is_active",
            user_data.name,
            user_data.email
        )
        return User(**dict(row))
    
    async def update(self, user_id: int, updates: dict) -> Optional[User]:
        # Build dynamic update query
        set_clauses = []
        values = []
        for i, (field, value) in enumerate(updates.items(), 1):
            set_clauses.append(f"{field} = ${i}")
            values.append(value)
        
        values.append(user_id)
        query = f"""
            UPDATE users SET {', '.join(set_clauses)}
            WHERE id = ${len(values)}
            RETURNING id, name, email, created_at, is_active
        """
        
        row = await self.db.fetchrow(query, *values)
        return User(**dict(row)) if row else None
    
    async def delete(self, user_id: int) -> bool:
        result = await self.db.execute("DELETE FROM users WHERE id = $1", user_id)
        return result == "DELETE 1"

# Repository factory dependency
def get_user_repository(
    db: Annotated[Optional[asyncpg.Connection], Depends(get_db_connection)] = None
) -> UserRepository:
    """Factory function to get appropriate user repository."""
    if db:
        return DatabaseUserRepository(db)
    else:
        # Fallback to in-memory repository
        return MemoryUserRepository()

# Service layer with dependency injection
class UserService:
    """User service with business logic."""
    
    def __init__(self, repository: UserRepository):
        self.repository = repository
    
    async def get_user(self, user_id: int) -> User:
        user = await self.repository.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found"
            )
        return user
    
    async def create_user(self, user_data: UserCreate) -> User:
        # Add business logic here (validation, notifications, etc.)
        return await self.repository.create(user_data)
    
    async def update_user(self, user_id: int, updates: UserUpdate) -> User:
        update_data = updates.dict(exclude_unset=True)
        user = await self.repository.update(user_id, update_data)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found"
            )
        return user
    
    async def delete_user(self, user_id: int) -> None:
        success = await self.repository.delete(user_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found"
            )

def get_user_service(
    repository: Annotated[UserRepository, Depends(get_user_repository)]
) -> UserService:
    """Get user service with injected repository."""
    return UserService(repository)

# Endpoints using service layer
@app.get("/api/users/{user_id}")
async def get_user_api(
    user_id: Annotated[int, Path(gt=0)],
    service: Annotated[UserService, Depends(get_user_service)]
) -> User:
    """Get user via service layer."""
    return await service.get_user(user_id)

@app.post("/api/users", status_code=status.HTTP_201_CREATED)
async def create_user_api(
    user_data: UserCreate,
    service: Annotated[UserService, Depends(get_user_service)]
) -> User:
    """Create user via service layer."""
    return await service.create_user(user_data)
```

### Advanced Dependency Patterns
```python
from functools import lru_cache
from typing import Generator

# Configuration dependency
class Settings:
    """Application settings."""
    
    def __init__(self):
        self.database_url = "postgresql://localhost/mydb"
        self.redis_url = "redis://localhost:6379"
        self.secret_key = "your-secret-key"
        self.debug = False
        self.api_rate_limit = 100

@lru_cache()
def get_settings() -> Settings:
    """Get application settings (cached)."""
    return Settings()

# Authentication dependency
class CurrentUser:
    """Current authenticated user."""
    
    def __init__(self, user: User, permissions: set[str]):
        self.user = user
        self.permissions = permissions
    
    def has_permission(self, permission: str) -> bool:
        return permission in self.permissions

async def get_current_user(
    api_key: Annotated[str, Depends(get_api_key)],
    user_service: Annotated[UserService, Depends(get_user_service)]
) -> CurrentUser:
    """Get current authenticated user."""
    # In production, decode JWT token or lookup session
    # For demo, just return a mock user
    user = User(id=1, name="Admin User", email="admin@example.com")
    permissions = {"read", "write", "admin"}
    
    return CurrentUser(user, permissions)

def require_permission(permission: str):
    """Dependency factory for permission checking."""
    
    def permission_checker(
        current_user: Annotated[CurrentUser, Depends(get_current_user)]
    ) -> CurrentUser:
        if not current_user.has_permission(permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission '{permission}' required"
            )
        return current_user
    
    return permission_checker

# Rate limiting dependency
class RateLimiter:
    """Simple rate limiter."""
    
    def __init__(self, max_requests: int, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: dict[str, list[datetime]] = {}
    
    def is_allowed(self, identifier: str) -> bool:
        now = datetime.now()
        
        # Clean old requests
        if identifier in self.requests:
            self.requests[identifier] = [
                req_time for req_time in self.requests[identifier]
                if (now - req_time).seconds < self.window_seconds
            ]
        else:
            self.requests[identifier] = []
        
        # Check rate limit
        if len(self.requests[identifier]) >= self.max_requests:
            return False
        
        # Add current request
        self.requests[identifier].append(now)
        return True

rate_limiter = RateLimiter(max_requests=100)

def check_rate_limit(
    request: Request,
    settings: Annotated[Settings, Depends(get_settings)]
) -> None:
    """Rate limiting dependency."""
    client_ip = request.client.host
    
    if not rate_limiter.is_allowed(client_ip):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded"
        )

# Sub-dependencies and dependency chains
async def get_cache_client():
    """Get Redis cache client."""
    import aioredis
    redis = await aioredis.create_redis_pool("redis://localhost")
    try:
        yield redis
    finally:
        redis.close()
        await redis.wait_closed()

class CacheService:
    """Cache service with Redis."""
    
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def get(self, key: str) -> Optional[str]:
        return await self.redis.get(key)
    
    async def set(self, key: str, value: str, expire: int = 300) -> None:
        await self.redis.setex(key, expire, value)
    
    async def delete(self, key: str) -> None:
        await self.redis.delete(key)

def get_cache_service(
    redis_client: Annotated[aioredis.Redis, Depends(get_cache_client)]
) -> CacheService:
    """Get cache service with Redis dependency."""
    return CacheService(redis_client)

# Protected endpoint with multiple dependencies
@app.get("/admin/users")
async def admin_get_users(
    current_user: Annotated[CurrentUser, Depends(require_permission("admin"))],
    cache_service: Annotated[CacheService, Depends(get_cache_service)],
    _: Annotated[None, Depends(check_rate_limit)],
    settings: Annotated[Settings, Depends(get_settings)]
) -> List[User]:
    """Admin endpoint with multiple dependency layers."""
    
    # Try cache first
    cached_users = await cache_service.get("admin:users")
    if cached_users:
        import json
        return [User(**user_data) for user_data in json.loads(cached_users)]
    
    # Fetch from database
    users = list(users_db.values())
    
    # Cache results
    import json
    await cache_service.set(
        "admin:users",
        json.dumps([user.dict() for user in users]),
        expire=300
    )
    
    return users
```

### Dependency Override for Testing
```python
from unittest.mock import AsyncMock

# Override dependencies for testing
def override_get_db_connection():
    """Mock database connection for testing."""
    mock_db = AsyncMock()
    mock_db.fetchrow.return_value = {
        "id": 1,
        "name": "Test User",
        "email": "test@example.com",
        "created_at": datetime.now(),
        "is_active": True
    }
    return mock_db

def override_get_cache_service():
    """Mock cache service for testing."""
    mock_cache = AsyncMock()
    mock_cache.get.return_value = None
    mock_cache.set.return_value = None
    return mock_cache

# Test configuration
def create_test_app() -> FastAPI:
    """Create FastAPI app with dependency overrides for testing."""
    test_app = FastAPI()
    
    # Override dependencies
    test_app.dependency_overrides[get_db_connection] = override_get_db_connection
    test_app.dependency_overrides[get_cache_service] = override_get_cache_service
    
    return test_app

# Example test
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_get_user():
    """Test getting a user with mocked dependencies."""
    test_app = create_test_app()
    
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        response = await ac.get("/api/users/1")
    
    assert response.status_code == 200
    assert response.json()["name"] == "Test User"
```

## Error Handling and Validation

### Custom Exception Handlers
```python
from fastapi.exception_handlers import http_exception_handler
from starlette.exceptions import HTTPException as StarletteHTTPException

class BusinessLogicError(Exception):
    """Custom business logic exception."""
    
    def __init__(self, message: str, code: str = "BUSINESS_ERROR"):
        self.message = message
        self.code = code
        super().__init__(message)

class ValidationError(Exception):
    """Custom validation exception."""
    
    def __init__(self, field: str, message: str):
        self.field = field
        self.message = message
        super().__init__(f"{field}: {message}")

@app.exception_handler(BusinessLogicError)
async def business_logic_exception_handler(request: Request, exc: BusinessLogicError):
    """Handle business logic exceptions."""
    return JSONResponse(
        status_code=422,
        content={
            "error": "Business Logic Error",
            "code": exc.code,
            "message": exc.message,
            "timestamp": datetime.now().isoformat()
        }
    )

@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    """Handle validation exceptions."""
    return JSONResponse(
        status_code=400,
        content={
            "error": "Validation Error",
            "field": exc.field,
            "message": exc.message,
            "timestamp": datetime.now().isoformat()
        }
    )

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle unexpected exceptions."""
    import traceback
    
    # Log the full traceback
    print(f"Unexpected error: {traceback.format_exc()}")
    
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "An unexpected error occurred",
            "timestamp": datetime.now().isoformat()
        }
    )
```

## Request and Response Models

### Advanced Pydantic Models
```python
from pydantic import BaseModel, Field, validator, root_validator
from typing import Literal, Union
from enum import Enum

class UserRole(str, Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

class UserStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"

class UserCreateRequest(BaseModel):
    """Request model for creating users."""
    name: str = Field(..., min_length=1, max_length=100, description="User's full name")
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$', description="User's email address")
    role: UserRole = Field(default=UserRole.USER, description="User's role")
    age: Optional[int] = Field(None, ge=13, le=120, description="User's age")
    
    @validator('name')
    def validate_name(cls, v):
        if not v.replace(' ', '').isalpha():
            raise ValueError('Name must contain only letters and spaces')
        return v.title()
    
    @validator('email')
    def validate_email_domain(cls, v):
        allowed_domains = ['example.com', 'company.com']
        domain = v.split('@')[1].lower()
        if domain not in allowed_domains:
            raise ValueError(f'Email domain must be one of: {allowed_domains}')
        return v.lower()
    
    @root_validator
    def validate_admin_requirements(cls, values):
        role = values.get('role')
        age = values.get('age')
        
        if role == UserRole.ADMIN and (age is None or age < 18):
            raise ValueError('Admin users must be at least 18 years old')
        
        return values

class UserResponse(BaseModel):
    """Response model for user data."""
    id: int
    name: str
    email: str
    role: UserRole
    status: UserStatus = UserStatus.ACTIVE
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class PaginatedUsers(BaseModel):
    """Paginated response for users."""
    users: List[UserResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool

class ErrorResponse(BaseModel):
    """Standard error response."""
    error: str
    message: str
    details: Optional[dict] = None
    timestamp: datetime = Field(default_factory=datetime.now)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

# Using response models in endpoints
@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user_with_models(user_data: UserCreateRequest) -> UserResponse:
    """Create user with comprehensive models."""
    # Simulate user creation
    new_user = UserResponse(
        id=len(users_db) + 1,
        name=user_data.name,
        email=user_data.email,
        role=user_data.role,
        created_at=datetime.now()
    )
    return new_user

@app.get("/users", response_model=PaginatedUsers)
async def list_users_paginated(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100)
) -> PaginatedUsers:
    """List users with pagination model."""
    total = len(users_db)
    total_pages = (total + per_page - 1) // per_page
    start = (page - 1) * per_page
    end = start + per_page
    
    users = list(users_db.values())[start:end]
    
    return PaginatedUsers(
        users=users,
        total=total,
        page=page,
        per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1
    )
```

## Best Practices

### Project Structure
```
fastapi_project/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app instance
│   ├── dependencies.py     # Dependency functions
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py         # Pydantic models
│   │   └── common.py       # Shared models
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── users.py        # User endpoints
│   │   └── auth.py         # Authentication endpoints
│   ├── services/
│   │   ├── __init__.py
│   │   ├── user_service.py # Business logic
│   │   └── auth_service.py # Authentication logic
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── user_repository.py # Data access
│   └── config.py           # Configuration
├── tests/
├── requirements.txt
└── README.md
```

### Configuration Management
```python
from functools import lru_cache
from typing import Optional
import os

class Settings:
    """Application settings with environment variable support."""
    
    def __init__(self):
        self.database_url: str = os.getenv("DATABASE_URL", "sqlite:///./app.db")
        self.redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.secret_key: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
        self.debug: bool = os.getenv("DEBUG", "false").lower() == "true"
        self.api_rate_limit: int = int(os.getenv("API_RATE_LIMIT", "100"))
        self.cors_origins: list[str] = os.getenv("CORS_ORIGINS", "").split(",")
        
        # Validation
        if not self.secret_key or self.secret_key == "your-secret-key-change-in-production":
            raise ValueError("SECRET_KEY must be set in production")

@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()

# Use in dependencies
def get_database_url(settings: Annotated[Settings, Depends(get_settings)]) -> str:
    return settings.database_url
```

---

**Last Updated:** Based on FastAPI 0.100+ and modern Python patterns
**References:**
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Dependency Injection in FastAPI](https://fastapi.tiangolo.com/tutorial/dependencies/)
- [Pydantic Models](https://docs.pydantic.dev/)
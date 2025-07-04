# API Design Patterns

Comprehensive guide to designing scalable, maintainable, and developer-friendly APIs using modern patterns and best practices.

## 🎯 API Design Overview

Well-designed APIs are crucial for building successful applications:
- **RESTful Design** - Resource-oriented architecture
- **GraphQL** - Query language for flexible data fetching
- **API Versioning** - Evolution without breaking changes
- **Rate Limiting** - Protecting services from abuse
- **Documentation** - OpenAPI/Swagger specifications
- **Error Handling** - Consistent, informative error responses

## 🚀 RESTful API Design

### Resource-Oriented Architecture

```javascript
// Good: Resource-oriented URLs
GET    /api/users              // List users
GET    /api/users/123          // Get specific user
POST   /api/users              // Create user
PUT    /api/users/123          // Update entire user
PATCH  /api/users/123          // Partial update
DELETE /api/users/123          // Delete user

// Nested resources
GET    /api/users/123/orders   // User's orders
POST   /api/users/123/orders   // Create order for user

// Bad: Action-oriented URLs
GET    /api/getUser/123        // Avoid verbs in URLs
POST   /api/createUser         // Resource should be in URL
POST   /api/users/123/activate // Use PATCH for state changes
```

### HTTP Method Semantics

```python
# FastAPI example with proper HTTP methods
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

app = FastAPI()

class UserBase(BaseModel):
    email: str
    name: str
    is_active: bool = True

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[str] = None
    name: Optional[str] = None
    is_active: Optional[bool] = None

class User(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# GET - Safe, idempotent, cacheable
@app.get("/api/users", response_model=List[User])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    is_active: Optional[bool] = None
):
    """List users with pagination and filtering"""
    query = db.query(UserModel)
    if is_active is not None:
        query = query.filter(UserModel.is_active == is_active)
    
    return query.offset(skip).limit(limit).all()

# POST - Not idempotent, creates resources
@app.post("/api/users", 
    response_model=User,
    status_code=status.HTTP_201_CREATED
)
async def create_user(user: UserCreate):
    """Create a new user"""
    # Check if user exists
    if db.query(UserModel).filter(UserModel.email == user.email).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User with this email already exists"
        )
    
    db_user = UserModel(**user.dict())
    db.add(db_user)
    db.commit()
    
    return db_user

# PUT - Idempotent, full replacement
@app.put("/api/users/{user_id}", response_model=User)
async def replace_user(user_id: int, user: UserCreate):
    """Replace entire user resource"""
    db_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Replace all fields
    for field, value in user.dict().items():
        setattr(db_user, field, value)
    
    db_user.updated_at = datetime.utcnow()
    db.commit()
    
    return db_user

# PATCH - Idempotent, partial update
@app.patch("/api/users/{user_id}", response_model=User)
async def update_user(user_id: int, user: UserUpdate):
    """Partially update user"""
    db_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Update only provided fields
    update_data = user.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_user, field, value)
    
    db_user.updated_at = datetime.utcnow()
    db.commit()
    
    return db_user

# DELETE - Idempotent
@app.delete("/api/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: int):
    """Delete user"""
    db_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if db_user:
        db.delete(db_user)
        db.commit()
    
    # Return 204 even if user didn't exist (idempotent)
    return None
```

### Query Parameters & Filtering

```python
# Advanced filtering and pagination
from enum import Enum
from typing import Optional, List
from datetime import date

class SortOrder(str, Enum):
    asc = "asc"
    desc = "desc"

class UserSortField(str, Enum):
    created_at = "created_at"
    updated_at = "updated_at"
    name = "name"
    email = "email"

@app.get("/api/users", response_model=PaginatedResponse[User])
async def list_users(
    # Pagination
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    
    # Filtering
    email: Optional[str] = Query(None, description="Filter by email (partial match)"),
    name: Optional[str] = Query(None, description="Filter by name (partial match)"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    created_after: Optional[date] = Query(None, description="Filter by creation date"),
    created_before: Optional[date] = Query(None, description="Filter by creation date"),
    
    # Sorting
    sort_by: UserSortField = Query(UserSortField.created_at, description="Sort field"),
    sort_order: SortOrder = Query(SortOrder.desc, description="Sort order"),
    
    # Field selection
    fields: Optional[List[str]] = Query(None, description="Fields to include in response")
):
    """
    List users with advanced filtering, pagination, and sorting.
    
    Example queries:
    - /api/users?page=2&per_page=50
    - /api/users?email=john&is_active=true
    - /api/users?created_after=2024-01-01&sort_by=name&sort_order=asc
    - /api/users?fields=id,email,name
    """
    query = db.query(UserModel)
    
    # Apply filters
    if email:
        query = query.filter(UserModel.email.contains(email))
    if name:
        query = query.filter(UserModel.name.contains(name))
    if is_active is not None:
        query = query.filter(UserModel.is_active == is_active)
    if created_after:
        query = query.filter(UserModel.created_at >= created_after)
    if created_before:
        query = query.filter(UserModel.created_at <= created_before)
    
    # Get total count
    total_count = query.count()
    
    # Apply sorting
    order_column = getattr(UserModel, sort_by.value)
    if sort_order == SortOrder.desc:
        order_column = order_column.desc()
    query = query.order_by(order_column)
    
    # Apply pagination
    skip = (page - 1) * per_page
    users = query.offset(skip).limit(per_page).all()
    
    # Field selection (if specified)
    if fields:
        users = [
            {field: getattr(user, field) for field in fields if hasattr(user, field)}
            for user in users
        ]
    
    return PaginatedResponse(
        items=users,
        total=total_count,
        page=page,
        per_page=per_page,
        pages=(total_count + per_page - 1) // per_page
    )
```

### Response Formats

```python
# Consistent response structures
from typing import Generic, TypeVar, List, Optional
from pydantic import BaseModel, Field

T = TypeVar('T')

class PaginatedResponse(BaseModel, Generic[T]):
    """Standard paginated response"""
    items: List[T]
    total: int = Field(..., description="Total number of items")
    page: int = Field(..., description="Current page number")
    per_page: int = Field(..., description="Items per page")
    pages: int = Field(..., description="Total number of pages")
    
    class Config:
        schema_extra = {
            "example": {
                "items": [...],
                "total": 100,
                "page": 1,
                "per_page": 20,
                "pages": 5
            }
        }

class APIResponse(BaseModel, Generic[T]):
    """Standard API response wrapper"""
    success: bool = True
    data: Optional[T] = None
    error: Optional[str] = None
    message: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class ErrorDetail(BaseModel):
    """Detailed error information"""
    code: str
    message: str
    field: Optional[str] = None
    context: Optional[dict] = None

class ErrorResponse(BaseModel):
    """Standard error response"""
    success: bool = False
    error: ErrorDetail
    request_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
# Usage examples
@app.get("/api/users/{user_id}", response_model=APIResponse[User])
async def get_user(user_id: int):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return APIResponse(
        data=user,
        message="User retrieved successfully"
    )

# Batch operations response
class BatchOperationResult(BaseModel):
    succeeded: List[int] = Field(default_factory=list)
    failed: List[dict] = Field(default_factory=list)
    total: int
    success_count: int
    failure_count: int

@app.post("/api/users/batch", response_model=BatchOperationResult)
async def create_users_batch(users: List[UserCreate]):
    result = BatchOperationResult(total=len(users), success_count=0, failure_count=0)
    
    for idx, user in enumerate(users):
        try:
            # Create user
            db_user = UserModel(**user.dict())
            db.add(db_user)
            db.flush()
            result.succeeded.append(db_user.id)
            result.success_count += 1
        except Exception as e:
            result.failed.append({
                "index": idx,
                "email": user.email,
                "error": str(e)
            })
            result.failure_count += 1
    
    db.commit()
    return result
```

## 🔧 GraphQL Design Patterns

### Schema Design

```python
# GraphQL with Strawberry
import strawberry
from typing import List, Optional
from datetime import datetime

@strawberry.type
class User:
    id: strawberry.ID
    email: str
    name: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    @strawberry.field
    async def orders(self, info) -> List["Order"]:
        """Resolve user's orders"""
        return await OrderLoader.load(self.id)
    
    @strawberry.field
    async def total_spent(self, info) -> float:
        """Calculate total amount spent"""
        orders = await self.orders(info)
        return sum(order.total for order in orders)

@strawberry.type
class Order:
    id: strawberry.ID
    user_id: strawberry.ID
    total: float
    status: str
    created_at: datetime
    
    @strawberry.field
    async def user(self, info) -> User:
        """Resolve order's user"""
        return await UserLoader.load(self.user_id)

@strawberry.input
class UserFilter:
    email: Optional[str] = None
    name: Optional[str] = None
    is_active: Optional[bool] = None
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None

@strawberry.input
class UserInput:
    email: str
    name: str
    password: str
    is_active: bool = True

@strawberry.type
class Query:
    @strawberry.field
    async def users(
        self,
        info,
        filter: Optional[UserFilter] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[User]:
        """Query users with filtering"""
        query = db.query(UserModel)
        
        if filter:
            if filter.email:
                query = query.filter(UserModel.email.contains(filter.email))
            if filter.name:
                query = query.filter(UserModel.name.contains(filter.name))
            if filter.is_active is not None:
                query = query.filter(UserModel.is_active == filter.is_active)
            if filter.created_after:
                query = query.filter(UserModel.created_at >= filter.created_after)
            if filter.created_before:
                query = query.filter(UserModel.created_at <= filter.created_before)
        
        return query.offset(offset).limit(limit).all()
    
    @strawberry.field
    async def user(self, info, id: strawberry.ID) -> Optional[User]:
        """Get single user by ID"""
        return db.query(UserModel).filter(UserModel.id == id).first()

@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_user(self, info, input: UserInput) -> User:
        """Create new user"""
        user = UserModel(**input.__dict__)
        db.add(user)
        db.commit()
        return user
    
    @strawberry.mutation
    async def update_user(
        self,
        info,
        id: strawberry.ID,
        input: UserInput
    ) -> Optional[User]:
        """Update existing user"""
        user = db.query(UserModel).filter(UserModel.id == id).first()
        if not user:
            return None
        
        for key, value in input.__dict__.items():
            setattr(user, key, value)
        
        user.updated_at = datetime.utcnow()
        db.commit()
        return user

# DataLoader for N+1 query prevention
from strawberry.dataloader import DataLoader

async def load_users(keys: List[int]) -> List[Optional[User]]:
    users = db.query(UserModel).filter(UserModel.id.in_(keys)).all()
    user_map = {user.id: user for user in users}
    return [user_map.get(key) for key in keys]

UserLoader = DataLoader(load_fn=load_users)
```

### GraphQL Subscriptions

```python
# Real-time subscriptions
import asyncio
from typing import AsyncGenerator

@strawberry.type
class Subscription:
    @strawberry.subscription
    async def user_created(self, info) -> AsyncGenerator[User, None]:
        """Subscribe to new user creations"""
        async for user in user_created_stream():
            yield user
    
    @strawberry.subscription
    async def order_status_changed(
        self,
        info,
        user_id: Optional[strawberry.ID] = None
    ) -> AsyncGenerator[Order, None]:
        """Subscribe to order status changes"""
        async for order in order_status_stream():
            if user_id is None or order.user_id == user_id:
                yield order

# Event emitter pattern
class EventEmitter:
    def __init__(self):
        self._subscribers = {}
    
    def subscribe(self, event_type: str, callback):
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(callback)
    
    async def emit(self, event_type: str, data):
        if event_type in self._subscribers:
            for callback in self._subscribers[event_type]:
                await callback(data)

event_emitter = EventEmitter()

# Usage in mutations
@strawberry.mutation
async def create_user(self, info, input: UserInput) -> User:
    user = UserModel(**input.__dict__)
    db.add(user)
    db.commit()
    
    # Emit event for subscriptions
    await event_emitter.emit("user_created", user)
    
    return user
```

## 🎯 API Versioning Strategies

### URL Path Versioning

```python
# Version in URL path
from fastapi import APIRouter

# Version 1 routes
v1_router = APIRouter(prefix="/api/v1")

@v1_router.get("/users")
async def get_users_v1():
    return {"version": 1, "users": [...]}

# Version 2 routes with breaking changes
v2_router = APIRouter(prefix="/api/v2")

@v2_router.get("/users")
async def get_users_v2():
    # Different response structure
    return {
        "version": 2,
        "data": {
            "users": [...],
            "metadata": {...}
        }
    }

app.include_router(v1_router)
app.include_router(v2_router)
```

### Header-Based Versioning

```python
# Version in headers
from fastapi import Header, HTTPException

@app.get("/api/users")
async def get_users(
    api_version: Optional[str] = Header(None, alias="X-API-Version")
):
    if api_version == "2.0":
        return {"version": "2.0", "data": {"users": [...]}}
    elif api_version == "1.0" or api_version is None:
        return {"version": "1.0", "users": [...]}
    else:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported API version: {api_version}"
        )
```

### Content-Type Versioning

```python
# Version in Accept header
from fastapi import Request

@app.get("/api/users")
async def get_users(request: Request):
    accept = request.headers.get("Accept", "")
    
    if "application/vnd.api.v2+json" in accept:
        return {"version": 2, "data": {"users": [...]}}
    else:
        return {"version": 1, "users": [...]}
```

### Backward Compatibility

```python
# Deprecation handling
from warnings import warn
from functools import wraps

def deprecated(version, alternative=None):
    """Decorator to mark endpoints as deprecated"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            warning = f"This endpoint is deprecated as of version {version}."
            if alternative:
                warning += f" Use {alternative} instead."
            
            # Add deprecation header
            response = await func(*args, **kwargs)
            response.headers["X-API-Deprecation"] = warning
            response.headers["Sunset"] = "2024-12-31"  # RFC 8594
            
            return response
        return wrapper
    return decorator

@app.get("/api/old-users")
@deprecated("2.0", "/api/v2/users")
async def get_old_users():
    return {"users": [...]}
```

## ⚡ Rate Limiting & Throttling

### Token Bucket Algorithm

```python
# Rate limiting implementation
import time
from typing import Dict, Tuple
from fastapi import Request, HTTPException
import redis

class RateLimiter:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    async def check_rate_limit(
        self,
        key: str,
        limit: int,
        window: int
    ) -> Tuple[bool, Dict[str, int]]:
        """
        Check if request is within rate limit.
        Returns (allowed, headers_dict)
        """
        current_time = int(time.time())
        window_start = current_time - window
        
        # Remove old entries
        self.redis.zremrangebyscore(key, 0, window_start)
        
        # Count requests in window
        request_count = self.redis.zcard(key)
        
        headers = {
            "X-RateLimit-Limit": str(limit),
            "X-RateLimit-Remaining": str(max(0, limit - request_count)),
            "X-RateLimit-Reset": str(current_time + window)
        }
        
        if request_count >= limit:
            return False, headers
        
        # Add current request
        self.redis.zadd(key, {str(current_time): current_time})
        self.redis.expire(key, window)
        
        headers["X-RateLimit-Remaining"] = str(limit - request_count - 1)
        return True, headers

# Rate limiting middleware
from fastapi import Response

rate_limiter = RateLimiter(redis.Redis())

async def rate_limit_middleware(request: Request, call_next):
    # Get client identifier
    client_id = request.client.host
    if auth_header := request.headers.get("Authorization"):
        # Use user ID for authenticated requests
        client_id = extract_user_id(auth_header)
    
    # Check rate limit
    key = f"rate_limit:{client_id}"
    allowed, headers = await rate_limiter.check_rate_limit(
        key=key,
        limit=100,  # 100 requests
        window=3600  # per hour
    )
    
    if not allowed:
        return Response(
            content="Rate limit exceeded",
            status_code=429,
            headers=headers
        )
    
    response = await call_next(request)
    
    # Add rate limit headers
    for header, value in headers.items():
        response.headers[header] = value
    
    return response

app.add_middleware(rate_limit_middleware)
```

### API Key Quotas

```python
# API key management with quotas
from datetime import datetime, timedelta
from sqlalchemy import Column, Integer, String, DateTime, Boolean

class APIKey(Base):
    __tablename__ = "api_keys"
    
    id = Column(Integer, primary_key=True)
    key = Column(String, unique=True, index=True)
    name = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Quotas
    requests_per_hour = Column(Integer, default=1000)
    requests_per_day = Column(Integer, default=10000)
    requests_per_month = Column(Integer, default=100000)
    
    # Tracking
    total_requests = Column(Integer, default=0)
    last_used_at = Column(DateTime)
    expires_at = Column(DateTime)
    is_active = Column(Boolean, default=True)
    
    # Permissions
    allowed_endpoints = Column(JSON)  # List of allowed endpoints
    allowed_methods = Column(JSON)    # List of allowed HTTP methods

class APIKeyValidator:
    def __init__(self, db_session):
        self.db = db_session
        self.redis = redis.Redis()
    
    async def validate_key(self, api_key: str) -> Optional[APIKey]:
        """Validate API key and check quotas"""
        # Check cache first
        cached = self.redis.get(f"api_key:{api_key}")
        if cached:
            return json.loads(cached)
        
        # Query database
        key_obj = self.db.query(APIKey).filter(
            APIKey.key == api_key,
            APIKey.is_active == True
        ).first()
        
        if not key_obj:
            return None
        
        # Check expiration
        if key_obj.expires_at and key_obj.expires_at < datetime.utcnow():
            return None
        
        # Cache for 5 minutes
        self.redis.setex(
            f"api_key:{api_key}",
            300,
            json.dumps(key_obj.to_dict())
        )
        
        return key_obj
    
    async def check_quota(self, api_key: str) -> Tuple[bool, Dict[str, any]]:
        """Check if API key has remaining quota"""
        now = datetime.utcnow()
        
        # Get current usage
        hour_key = f"quota:hour:{api_key}:{now.strftime('%Y%m%d%H')}"
        day_key = f"quota:day:{api_key}:{now.strftime('%Y%m%d')}"
        month_key = f"quota:month:{api_key}:{now.strftime('%Y%m')}"
        
        hour_count = int(self.redis.get(hour_key) or 0)
        day_count = int(self.redis.get(day_key) or 0)
        month_count = int(self.redis.get(month_key) or 0)
        
        key_obj = await self.validate_key(api_key)
        if not key_obj:
            return False, {"error": "Invalid API key"}
        
        # Check quotas
        if hour_count >= key_obj.requests_per_hour:
            return False, {
                "error": "Hourly quota exceeded",
                "limit": key_obj.requests_per_hour,
                "reset_at": (now + timedelta(hours=1)).replace(
                    minute=0, second=0, microsecond=0
                )
            }
        
        if day_count >= key_obj.requests_per_day:
            return False, {
                "error": "Daily quota exceeded",
                "limit": key_obj.requests_per_day,
                "reset_at": (now + timedelta(days=1)).replace(
                    hour=0, minute=0, second=0, microsecond=0
                )
            }
        
        if month_count >= key_obj.requests_per_month:
            return False, {
                "error": "Monthly quota exceeded",
                "limit": key_obj.requests_per_month,
                "reset_at": (now.replace(day=1) + timedelta(days=32)).replace(
                    day=1, hour=0, minute=0, second=0, microsecond=0
                )
            }
        
        # Increment counters
        pipe = self.redis.pipeline()
        pipe.incr(hour_key).expire(hour_key, 3600)
        pipe.incr(day_key).expire(day_key, 86400)
        pipe.incr(month_key).expire(month_key, 2592000)
        pipe.execute()
        
        # Update last used
        key_obj.last_used_at = now
        key_obj.total_requests += 1
        self.db.commit()
        
        return True, {
            "hourly_remaining": key_obj.requests_per_hour - hour_count - 1,
            "daily_remaining": key_obj.requests_per_day - day_count - 1,
            "monthly_remaining": key_obj.requests_per_month - month_count - 1
        }
```

## 📝 API Documentation

### OpenAPI/Swagger Integration

```python
# Rich OpenAPI documentation
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(
    title="My API",
    description="A comprehensive API with rich documentation",
    version="2.0.0",
    terms_of_service="https://example.com/terms",
    contact={
        "name": "API Support",
        "url": "https://example.com/support",
        "email": "api@example.com"
    },
    license_info={
        "name": "Apache 2.0",
        "url": "https://www.apache.org/licenses/LICENSE-2.0.html"
    },
    servers=[
        {"url": "https://api.example.com", "description": "Production"},
        {"url": "https://staging-api.example.com", "description": "Staging"},
        {"url": "http://localhost:8000", "description": "Development"}
    ]
)

# Custom OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # Add security schemes
    openapi_schema["components"]["securitySchemes"] = {
        "bearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        },
        "apiKey": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key"
        }
    }
    
    # Add tags with descriptions
    openapi_schema["tags"] = [
        {
            "name": "users",
            "description": "User management operations",
            "externalDocs": {
                "description": "User guide",
                "url": "https://docs.example.com/users"
            }
        },
        {
            "name": "orders",
            "description": "Order processing operations"
        }
    ]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Rich endpoint documentation
class UserResponse(BaseModel):
    """User response model with detailed field descriptions"""
    id: int = Field(..., description="Unique user identifier", example=123)
    email: str = Field(
        ...,
        description="User's email address",
        example="user@example.com",
        pattern=r"^[\w\.-]+@[\w\.-]+\.\w+$"
    )
    name: str = Field(
        ...,
        description="User's full name",
        example="John Doe",
        min_length=1,
        max_length=100
    )
    is_active: bool = Field(
        True,
        description="Whether the user account is active"
    )
    created_at: datetime = Field(
        ...,
        description="Account creation timestamp",
        example="2024-01-15T10:30:00Z"
    )

@app.get(
    "/api/users/{user_id}",
    response_model=UserResponse,
    tags=["users"],
    summary="Get user by ID",
    description="""
    Retrieve detailed information about a specific user.
    
    This endpoint requires authentication and returns user data
    including profile information and account status.
    """,
    response_description="User details",
    responses={
        200: {
            "description": "Successful response",
            "content": {
                "application/json": {
                    "example": {
                        "id": 123,
                        "email": "user@example.com",
                        "name": "John Doe",
                        "is_active": True,
                        "created_at": "2024-01-15T10:30:00Z"
                    }
                }
            }
        },
        404: {
            "description": "User not found",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "User not found"
                    }
                }
            }
        }
    }
)
async def get_user(
    user_id: int = Path(
        ...,
        description="The ID of the user to retrieve",
        example=123,
        ge=1
    ),
    include_stats: bool = Query(
        False,
        description="Include additional statistics in the response"
    )
):
    """Get user by ID with optional statistics."""
    # Implementation
    pass
```

### API Documentation Best Practices

```python
# Documentation utilities
from typing import Dict, Any
import yaml
import json

class APIDocumentor:
    """Generate various documentation formats"""
    
    @staticmethod
    def generate_postman_collection(app: FastAPI) -> Dict[str, Any]:
        """Generate Postman collection from FastAPI app"""
        collection = {
            "info": {
                "name": app.title,
                "description": app.description,
                "version": app.version,
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            },
            "item": []
        }
        
        for route in app.routes:
            if hasattr(route, "methods") and hasattr(route, "path"):
                for method in route.methods:
                    item = {
                        "name": route.name,
                        "request": {
                            "method": method,
                            "url": {
                                "raw": f"{{{{base_url}}}}{route.path}",
                                "host": ["{{base_url}}"],
                                "path": route.path.strip("/").split("/")
                            },
                            "header": [
                                {
                                    "key": "Content-Type",
                                    "value": "application/json"
                                }
                            ]
                        }
                    }
                    
                    # Add request body example if POST/PUT/PATCH
                    if method in ["POST", "PUT", "PATCH"] and hasattr(route, "body_field"):
                        if route.body_field:
                            schema = route.body_field.type_.schema()
                            item["request"]["body"] = {
                                "mode": "raw",
                                "raw": json.dumps(schema.get("example", {}), indent=2)
                            }
                    
                    collection["item"].append(item)
        
        return collection
    
    @staticmethod
    def generate_markdown_docs(app: FastAPI) -> str:
        """Generate Markdown documentation"""
        md = f"# {app.title}\n\n"
        md += f"{app.description}\n\n"
        md += f"**Version:** {app.version}\n\n"
        
        # Group routes by tags
        routes_by_tag = {}
        for route in app.routes:
            if hasattr(route, "tags"):
                for tag in route.tags:
                    if tag not in routes_by_tag:
                        routes_by_tag[tag] = []
                    routes_by_tag[tag].append(route)
        
        # Generate documentation for each tag
        for tag, routes in routes_by_tag.items():
            md += f"## {tag.title()}\n\n"
            
            for route in routes:
                if hasattr(route, "methods"):
                    method = list(route.methods)[0]
                    md += f"### {method} {route.path}\n\n"
                    
                    if route.description:
                        md += f"{route.description}\n\n"
                    
                    # Parameters
                    if hasattr(route, "dependant") and route.dependant.path_params:
                        md += "**Path Parameters:**\n\n"
                        for param in route.dependant.path_params:
                            md += f"- `{param.name}` ({param.type_.__name__}): "
                            md += f"{param.field_info.description or 'No description'}\n"
                        md += "\n"
                    
                    # Request body
                    if hasattr(route, "body_field") and route.body_field:
                        md += "**Request Body:**\n\n"
                        md += "```json\n"
                        schema = route.body_field.type_.schema()
                        md += json.dumps(schema.get("example", {}), indent=2)
                        md += "\n```\n\n"
                    
                    # Response
                    if hasattr(route, "response_model") and route.response_model:
                        md += "**Response:**\n\n"
                        md += "```json\n"
                        schema = route.response_model.schema()
                        md += json.dumps(schema.get("example", {}), indent=2)
                        md += "\n```\n\n"
        
        return md

# Usage
@app.get("/docs/postman")
async def get_postman_collection():
    """Download Postman collection"""
    collection = APIDocumentor.generate_postman_collection(app)
    return Response(
        content=json.dumps(collection, indent=2),
        media_type="application/json",
        headers={
            "Content-Disposition": "attachment; filename=api-collection.json"
        }
    )

@app.get("/docs/markdown")
async def get_markdown_docs():
    """Get API documentation in Markdown format"""
    docs = APIDocumentor.generate_markdown_docs(app)
    return Response(
        content=docs,
        media_type="text/markdown",
        headers={
            "Content-Disposition": "attachment; filename=api-docs.md"
        }
    )
```

## 🚨 Error Handling Standards

### Consistent Error Responses

```python
# Standard error handling
from enum import Enum
from typing import Optional, List, Dict, Any
from fastapi import Request, status
from fastapi.responses import JSONResponse

class ErrorCode(str, Enum):
    """Standard error codes"""
    # Client errors
    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    AUTHORIZATION_ERROR = "AUTHORIZATION_ERROR"
    NOT_FOUND = "NOT_FOUND"
    CONFLICT = "CONFLICT"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    
    # Server errors
    INTERNAL_ERROR = "INTERNAL_ERROR"
    SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE"
    DATABASE_ERROR = "DATABASE_ERROR"
    EXTERNAL_SERVICE_ERROR = "EXTERNAL_SERVICE_ERROR"

class ValidationError(BaseModel):
    field: str
    message: str
    code: str

class ErrorResponse(BaseModel):
    error: ErrorCode
    message: str
    details: Optional[List[ValidationError]] = None
    request_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        schema_extra = {
            "example": {
                "error": "VALIDATION_ERROR",
                "message": "Invalid request data",
                "details": [
                    {
                        "field": "email",
                        "message": "Invalid email format",
                        "code": "invalid_format"
                    }
                ],
                "request_id": "req_123456",
                "timestamp": "2024-01-15T10:30:00Z"
            }
        }

# Custom exception classes
class APIException(Exception):
    def __init__(
        self,
        status_code: int,
        error_code: ErrorCode,
        message: str,
        details: Optional[List[Dict[str, Any]]] = None
    ):
        self.status_code = status_code
        self.error_code = error_code
        self.message = message
        self.details = details

class ValidationException(APIException):
    def __init__(self, errors: List[ValidationError]):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            error_code=ErrorCode.VALIDATION_ERROR,
            message="Validation failed",
            details=errors
        )

class NotFoundException(APIException):
    def __init__(self, resource: str, identifier: Any):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            error_code=ErrorCode.NOT_FOUND,
            message=f"{resource} not found: {identifier}",
            details=None
        )

# Global exception handler
@app.exception_handler(APIException)
async def api_exception_handler(request: Request, exc: APIException):
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error=exc.error_code,
            message=exc.message,
            details=exc.details,
            request_id=request.state.request_id
        ).dict()
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for error in exc.errors():
        errors.append(ValidationError(
            field=".".join(str(loc) for loc in error["loc"]),
            message=error["msg"],
            code=error["type"]
        ))
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=ErrorResponse(
            error=ErrorCode.VALIDATION_ERROR,
            message="Request validation failed",
            details=errors,
            request_id=request.state.request_id
        ).dict()
    )

# Problem Details (RFC 7807)
class ProblemDetail(BaseModel):
    type: str = Field(..., description="URI reference that identifies the problem type")
    title: str = Field(..., description="Short, human-readable summary")
    status: int = Field(..., description="HTTP status code")
    detail: str = Field(..., description="Human-readable explanation")
    instance: str = Field(..., description="URI reference for this occurrence")
    
    class Config:
        schema_extra = {
            "example": {
                "type": "https://example.com/probs/out-of-credit",
                "title": "You do not have enough credit.",
                "status": 403,
                "detail": "Your current balance is 30, but that costs 50.",
                "instance": "/account/12345/msgs/abc"
            }
        }

@app.exception_handler(500)
async def internal_error_handler(request: Request, exc: Exception):
    # Log the error
    logger.error(f"Internal error: {exc}", exc_info=True)
    
    # Return problem details
    return JSONResponse(
        status_code=500,
        content=ProblemDetail(
            type="https://api.example.com/errors/internal-server-error",
            title="Internal Server Error",
            status=500,
            detail="An unexpected error occurred while processing your request",
            instance=request.url.path
        ).dict(),
        headers={"Content-Type": "application/problem+json"}
    )
```

## 🚀 Best Practices

### 1. **URL Design**
- Use nouns for resources, not verbs
- Use plural forms consistently
- Keep URLs predictable and hierarchical
- Use hyphens for multi-word resources

### 2. **HTTP Methods**
- Use GET for safe, idempotent reads
- Use POST for creating resources
- Use PUT for full replacements
- Use PATCH for partial updates
- Use DELETE for removing resources

### 3. **Status Codes**
- 200 OK - Successful GET/PUT/PATCH
- 201 Created - Successful POST
- 204 No Content - Successful DELETE
- 400 Bad Request - Client error
- 401 Unauthorized - Authentication required
- 403 Forbidden - Authorization failed
- 404 Not Found - Resource doesn't exist
- 422 Unprocessable Entity - Validation failed
- 429 Too Many Requests - Rate limit exceeded
- 500 Internal Server Error - Server error

### 4. **Response Format**
- Use consistent response envelopes
- Include pagination metadata
- Provide meaningful error messages
- Support field filtering
- Use ISO 8601 for dates

### 5. **Security**
- Always use HTTPS
- Implement proper authentication
- Validate all inputs
- Use rate limiting
- Follow OWASP guidelines

### 6. **Performance**
- Implement caching strategies
- Use pagination for large datasets
- Support partial responses
- Enable compression
- Monitor API performance

## 📖 Resources & References

### Standards & Specifications
- [REST API Design Best Practices](https://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api)
- [JSON:API Specification](https://jsonapi.org/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [GraphQL Specification](https://spec.graphql.org/)
- [RFC 7807 - Problem Details](https://tools.ietf.org/html/rfc7807)

### Tools & Libraries
- **API Testing** - Postman, Insomnia, HTTPie
- **Documentation** - Swagger UI, Redoc, Spectacle
- **Mocking** - Mockoon, JSON Server, WireMock
- **Monitoring** - Datadog, New Relic, Prometheus

---

*This guide covers essential API design patterns for building scalable, maintainable APIs. Focus on consistency, documentation, and developer experience for successful API adoption.*
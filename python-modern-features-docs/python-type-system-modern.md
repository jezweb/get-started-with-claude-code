# Python Modern Type System and Type Hints

## Overview
This guide covers Python's modern type system improvements from Python 3.9+ through 3.12, focusing on practical applications for web development, API design, and robust application architecture.

## Built-in Collection Types (Python 3.9+)

### Generic Built-in Collections
Python 3.9+ allows using built-in collection types directly for type hints:

```python
# Old style (still valid)
from typing import List, Dict, Set, Tuple, Optional, Union

def process_users_old(
    users: List[Dict[str, str]], 
    permissions: Set[str]
) -> Optional[Dict[str, List[str]]]:
    pass

# New style (Python 3.9+)
def process_users_new(
    users: list[dict[str, str]], 
    permissions: set[str]
) -> dict[str, list[str]] | None:
    """Process users with modern type hints."""
    result = {}
    for user in users:
        user_id = user.get("id")
        if user_id and "admin" in permissions:
            result[user_id] = list(permissions)
    return result if result else None

# FastAPI with modern type hints
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class UserResponse(BaseModel):
    id: int
    name: str
    tags: list[str] = []
    metadata: dict[str, str | int | bool] = {}

class UserUpdate(BaseModel):
    name: str | None = None
    tags: list[str] | None = None
    metadata: dict[str, str | int | bool] | None = None

@app.get("/users/{user_id}")
async def get_user(user_id: int) -> UserResponse:
    """Get user with modern return type annotation."""
    user_data = await fetch_user_data(user_id)
    if not user_data:
        raise HTTPException(404, "User not found")
    return UserResponse(**user_data)

@app.patch("/users/{user_id}")
async def update_user(
    user_id: int, 
    updates: UserUpdate
) -> UserResponse | dict[str, str]:
    """Update user with union return type."""
    try:
        updated_user = await update_user_data(user_id, updates.dict(exclude_unset=True))
        return UserResponse(**updated_user)
    except ValueError as e:
        return {"error": str(e), "user_id": str(user_id)}
```

### Complex Type Compositions
```python
from typing import Any, Callable, Awaitable
from datetime import datetime

# Complex nested types
UserData = dict[str, str | int | bool | list[str]]
DatabaseRecord = dict[str, Any]
QueryResult = list[DatabaseRecord] | None

# Function type annotations
ProcessorFunction = Callable[[UserData], Awaitable[DatabaseRecord]]
ValidationFunction = Callable[[dict[str, Any]], bool]
TransformFunction = Callable[[list[dict]], list[dict]]

# Web application types
class APIEndpoint:
    """Type-safe API endpoint definition."""
    
    def __init__(
        self,
        path: str,
        methods: list[str],
        handler: Callable[..., Awaitable[dict[str, Any]]],
        middleware: list[Callable] = None
    ):
        self.path = path
        self.methods = methods
        self.handler = handler
        self.middleware = middleware or []

# Usage with FastAPI
async def user_handler(user_id: int) -> dict[str, Any]:
    """Type-safe endpoint handler."""
    return {"user_id": user_id, "status": "active"}

user_endpoint = APIEndpoint(
    path="/users/{user_id}",
    methods=["GET"],
    handler=user_handler
)

# Generic repository pattern with modern types
class Repository[T]:
    """Generic repository with modern type parameters."""
    
    def __init__(self, model_class: type[T]):
        self.model_class = model_class
        self._storage: dict[int, T] = {}
    
    async def find_by_criteria(
        self, 
        criteria: dict[str, Any]
    ) -> list[T]:
        """Find records matching criteria."""
        return [
            item for item in self._storage.values()
            if all(
                getattr(item, key, None) == value 
                for key, value in criteria.items()
            )
        ]
    
    async def bulk_update(
        self, 
        updates: dict[int, dict[str, Any]]
    ) -> list[T]:
        """Bulk update records."""
        updated = []
        for item_id, update_data in updates.items():
            if item_id in self._storage:
                item = self._storage[item_id]
                for key, value in update_data.items():
                    setattr(item, key, value)
                updated.append(item)
        return updated
```

## Union Types and Optional Values

### Union Type Patterns (Python 3.10+)
```python
# Union types with | operator
def parse_input(data: str | int | dict) -> dict[str, Any]:
    """Parse various input types."""
    match data:
        case str() if data.isdigit():
            return {"type": "numeric_string", "value": int(data)}
        case int():
            return {"type": "integer", "value": data}
        case dict():
            return {"type": "dictionary", "value": data}
        case _:
            return {"type": "unknown", "value": str(data)}

# Optional values (None | T)
def get_user_by_email(email: str) -> UserResponse | None:
    """Get user by email, return None if not found."""
    user_data = find_user_by_email(email)
    return UserResponse(**user_data) if user_data else None

# Multiple union types
def process_api_response(
    response: dict[str, Any]
) -> UserResponse | list[UserResponse] | dict[str, str]:
    """Process API response with multiple possible return types."""
    match response.get("type"):
        case "single_user":
            return UserResponse(**response["data"])
        case "user_list":
            return [UserResponse(**user) for user in response["data"]]
        case "error":
            return {"error": response.get("message", "Unknown error")}
        case _:
            return {"error": "Invalid response format"}

# FastAPI with union return types
@app.get("/search")
async def search_users(
    query: str,
    format: str = "json"
) -> list[UserResponse] | dict[str, Any] | str:
    """Search users with different response formats."""
    users = await search_users_database(query)
    
    match format:
        case "json":
            return [UserResponse(**user) for user in users]
        case "csv":
            return generate_csv_string(users)
        case "summary":
            return {
                "total": len(users),
                "query": query,
                "results": [user["name"] for user in users[:5]]
            }
        case _:
            raise HTTPException(400, "Invalid format")
```

### Discriminated Unions
```python
from typing import Literal
from pydantic import BaseModel, Field

# Discriminated union types for API responses
class SuccessResponse(BaseModel):
    status: Literal["success"]
    data: dict[str, Any]
    message: str = "Operation completed successfully"

class ErrorResponse(BaseModel):
    status: Literal["error"]
    error_code: str
    message: str
    details: dict[str, Any] = {}

class PendingResponse(BaseModel):
    status: Literal["pending"]
    request_id: str
    estimated_completion: datetime | None = None

# Union of discriminated types
APIResponse = SuccessResponse | ErrorResponse | PendingResponse

def create_api_response(
    success: bool, 
    data: dict[str, Any] = None,
    error: str = None,
    request_id: str = None
) -> APIResponse:
    """Create appropriate API response based on outcome."""
    match success, data, error, request_id:
        case True, dict() as result_data, None, None:
            return SuccessResponse(status="success", data=result_data)
        case False, None, str() as error_msg, None:
            return ErrorResponse(
                status="error", 
                error_code="PROCESSING_ERROR",
                message=error_msg
            )
        case None, None, None, str() as req_id:
            return PendingResponse(status="pending", request_id=req_id)
        case _:
            return ErrorResponse(
                status="error",
                error_code="INVALID_PARAMETERS",
                message="Invalid response parameters"
            )

# FastAPI endpoint with discriminated unions
@app.post("/process-data")
async def process_data(data: dict[str, Any]) -> APIResponse:
    """Process data with typed response."""
    try:
        if not data:
            return ErrorResponse(
                status="error",
                error_code="EMPTY_DATA",
                message="No data provided"
            )
        
        # Simulate async processing
        result = await process_data_async(data)
        
        if result.get("async_processing"):
            return PendingResponse(
                status="pending",
                request_id=result["request_id"],
                estimated_completion=result.get("eta")
            )
        
        return SuccessResponse(
            status="success",
            data=result
        )
        
    except Exception as e:
        return ErrorResponse(
            status="error",
            error_code="PROCESSING_FAILED",
            message=str(e),
            details={"data_keys": list(data.keys())}
        )
```

## Generic Types and Type Variables

### Generic Classes with Type Parameters (Python 3.12+)
```python
# Modern generic syntax
class APIClient[T]:
    """Generic API client with response type."""
    
    def __init__(self, base_url: str, response_model: type[T]):
        self.base_url = base_url
        self.response_model = response_model
        self.session: aiohttp.ClientSession | None = None
    
    async def get(self, endpoint: str) -> T | None:
        """Get resource with typed response."""
        async with self.session.get(f"{self.base_url}/{endpoint}") as response:
            if response.status == 200:
                data = await response.json()
                return self.response_model(**data)
            return None
    
    async def post(self, endpoint: str, data: dict) -> T | None:
        """Post data with typed response."""
        async with self.session.post(
            f"{self.base_url}/{endpoint}", 
            json=data
        ) as response:
            if response.status in (200, 201):
                response_data = await response.json()
                return self.response_model(**response_data)
            return None
    
    async def list(self, endpoint: str) -> list[T]:
        """List resources with typed response."""
        async with self.session.get(f"{self.base_url}/{endpoint}") as response:
            if response.status == 200:
                data = await response.json()
                return [self.response_model(**item) for item in data]
            return []

# Usage with different models
user_client = APIClient[UserResponse]("https://api.users.com", UserResponse)
product_client = APIClient[ProductResponse]("https://api.products.com", ProductResponse)

# Generic cache with type parameters
class TypedCache[K, V]:
    """Generic cache with key and value types."""
    
    def __init__(self, max_size: int = 100):
        self.max_size = max_size
        self._cache: dict[K, V] = {}
        self._access_order: list[K] = []
    
    def get(self, key: K) -> V | None:
        """Get value by key."""
        if key in self._cache:
            # Update access order
            self._access_order.remove(key)
            self._access_order.append(key)
            return self._cache[key]
        return None
    
    def set(self, key: K, value: V) -> None:
        """Set key-value pair."""
        if len(self._cache) >= self.max_size:
            # Remove LRU item
            lru_key = self._access_order.pop(0)
            del self._cache[lru_key]
        
        self._cache[key] = value
        if key in self._access_order:
            self._access_order.remove(key)
        self._access_order.append(key)
    
    def clear_by_pattern(self, pattern_fn: Callable[[K], bool]) -> int:
        """Clear entries matching pattern."""
        keys_to_remove = [key for key in self._cache if pattern_fn(key)]
        for key in keys_to_remove:
            del self._cache[key]
            self._access_order.remove(key)
        return len(keys_to_remove)

# Type-safe cache usage
user_cache = TypedCache[int, UserResponse](max_size=1000)
session_cache = TypedCache[str, dict[str, Any]](max_size=500)

# Generic function types
async def batch_process[T, R](
    items: list[T],
    processor: Callable[[T], Awaitable[R]],
    max_concurrency: int = 10
) -> list[R]:
    """Process items concurrently with type safety."""
    semaphore = asyncio.Semaphore(max_concurrency)
    
    async def bounded_process(item: T) -> R:
        async with semaphore:
            return await processor(item)
    
    tasks = [bounded_process(item) for item in items]
    return await asyncio.gather(*tasks)

# Usage with strong typing
async def process_user_data(user: UserResponse) -> dict[str, Any]:
    """Process individual user data."""
    return {
        "user_id": user.id,
        "processed_at": datetime.now().isoformat(),
        "status": "completed"
    }

# Type-safe batch processing
users: list[UserResponse] = await fetch_users()
results: list[dict[str, Any]] = await batch_process(users, process_user_data)
```

### Variance and Bounds
```python
from typing import TypeVar, Generic, Protocol, runtime_checkable

# Bounded type variables
T_Numeric = TypeVar('T_Numeric', bound=int | float)
T_Model = TypeVar('T_Model', bound=BaseModel)

class Calculator[T: int | float]:
    """Calculator with numeric type bounds."""
    
    def __init__(self, initial_value: T):
        self.value = initial_value
    
    def add(self, other: T) -> T:
        return self.value + other
    
    def multiply(self, other: T) -> T:
        return self.value * other

# Protocol for type safety
@runtime_checkable
class Serializable(Protocol):
    """Protocol for serializable objects."""
    
    def to_dict(self) -> dict[str, Any]: ...
    def from_dict(self, data: dict[str, Any]) -> None: ...

class SerializableService[T: Serializable]:
    """Service for serializable objects."""
    
    def __init__(self, item_class: type[T]):
        self.item_class = item_class
    
    async def save_to_storage(self, items: list[T]) -> bool:
        """Save serializable items to storage."""
        try:
            serialized_data = [item.to_dict() for item in items]
            await store_data(serialized_data)
            return True
        except Exception:
            return False
    
    async def load_from_storage(self, item_ids: list[str]) -> list[T]:
        """Load items from storage."""
        data_list = await fetch_data(item_ids)
        items = []
        for data in data_list:
            item = self.item_class()
            item.from_dict(data)
            items.append(item)
        return items

# Covariant and contravariant examples
from typing import TypeVar

T_co = TypeVar('T_co', covariant=True)  # Output type
T_contra = TypeVar('T_contra', contravariant=True)  # Input type

class Producer[T_co]:
    """Producer that outputs T_co."""
    
    def __init__(self, items: list[T_co]):
        self._items = items
    
    def get_next(self) -> T_co | None:
        return self._items.pop(0) if self._items else None

class Consumer[T_contra]:
    """Consumer that accepts T_contra."""
    
    def __init__(self):
        self._processed: list[T_contra] = []
    
    def process(self, item: T_contra) -> None:
        self._processed.append(item)
    
    def get_processed_count(self) -> int:
        return len(self._processed)
```

## Advanced Type Patterns

### TypedDict for Structured Data
```python
from typing import TypedDict, Required, NotRequired
from datetime import datetime

# Required and optional fields
class UserDict(TypedDict):
    id: Required[int]
    name: Required[str]
    email: Required[str]
    created_at: Required[datetime]
    last_login: NotRequired[datetime]  # Optional field
    metadata: NotRequired[dict[str, str]]

class UserUpdateDict(TypedDict, total=False):
    """All fields optional for updates."""
    name: str
    email: str
    metadata: dict[str, str]

# Database interaction with TypedDict
async def create_user_record(user_data: UserDict) -> int:
    """Create user record in database."""
    query = """
        INSERT INTO users (id, name, email, created_at, last_login, metadata)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id
    """
    
    return await db.fetchval(
        query,
        user_data["id"],
        user_data["name"],
        user_data["email"],
        user_data["created_at"],
        user_data.get("last_login"),
        user_data.get("metadata", {})
    )

async def update_user_record(user_id: int, updates: UserUpdateDict) -> bool:
    """Update user record with partial data."""
    if not updates:
        return False
    
    # Build dynamic query based on provided fields
    set_clauses = []
    values = []
    param_num = 1
    
    for field, value in updates.items():
        set_clauses.append(f"{field} = ${param_num}")
        values.append(value)
        param_num += 1
    
    query = f"UPDATE users SET {', '.join(set_clauses)} WHERE id = ${param_num}"
    values.append(user_id)
    
    result = await db.execute(query, *values)
    return result == "UPDATE 1"

# FastAPI with TypedDict
@app.post("/users/typed")
async def create_user_typed(user_data: UserDict) -> dict[str, Any]:
    """Create user with TypedDict validation."""
    try:
        user_id = await create_user_record(user_data)
        return {"user_id": user_id, "status": "created"}
    except Exception as e:
        return {"error": str(e)}

@app.patch("/users/{user_id}/typed")
async def update_user_typed(
    user_id: int, 
    updates: UserUpdateDict
) -> dict[str, Any]:
    """Update user with TypedDict validation."""
    success = await update_user_record(user_id, updates)
    return {"updated": success, "user_id": user_id}
```

### Literal Types and Enums
```python
from typing import Literal
from enum import Enum, auto

# Literal types for exact values
UserRole = Literal["admin", "user", "guest"]
APIVersion = Literal["v1", "v2", "v3"]
HTTPMethod = Literal["GET", "POST", "PUT", "DELETE", "PATCH"]

class OrderStatus(Enum):
    """Order status enumeration."""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"

class LogLevel(Enum):
    """Log level enumeration."""
    DEBUG = auto()
    INFO = auto()
    WARNING = auto()
    ERROR = auto()
    CRITICAL = auto()

# Function with literal types
def check_user_permission(
    user_role: UserRole, 
    required_permission: Literal["read", "write", "admin"]
) -> bool:
    """Check if user role has required permission."""
    permissions = {
        "admin": ["read", "write", "admin"],
        "user": ["read", "write"],
        "guest": ["read"]
    }
    
    return required_permission in permissions.get(user_role, [])

# API versioning with literals
def handle_api_request(
    version: APIVersion,
    method: HTTPMethod,
    endpoint: str
) -> dict[str, Any]:
    """Handle API request based on version."""
    match version, method:
        case "v1", "GET":
            return handle_v1_get(endpoint)
        case "v1", ("POST" | "PUT"):
            return handle_v1_write(endpoint, method)
        case "v2", _:
            return handle_v2_request(endpoint, method)
        case "v3", _:
            return handle_v3_request(endpoint, method)
        case _:
            return {"error": "Unsupported version or method"}

# FastAPI with enums and literals
class APIRequest(BaseModel):
    method: HTTPMethod
    version: APIVersion
    user_role: UserRole
    data: dict[str, Any] = {}

@app.post("/api-proxy")
async def proxy_api_request(request: APIRequest) -> dict[str, Any]:
    """Proxy API request with type validation."""
    # Check permissions
    if not check_user_permission(request.user_role, "write") and request.method != "GET":
        return {"error": "Insufficient permissions"}
    
    # Route request based on version and method
    return handle_api_request(request.version, request.method, "/proxy")

# Order processing with enum states
class OrderProcessor:
    """Process orders with type-safe status transitions."""
    
    def __init__(self):
        self.valid_transitions: dict[OrderStatus, list[OrderStatus]] = {
            OrderStatus.PENDING: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
            OrderStatus.CONFIRMED: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
            OrderStatus.SHIPPED: [OrderStatus.DELIVERED],
            OrderStatus.DELIVERED: [],
            OrderStatus.CANCELLED: []
        }
    
    def can_transition(
        self, 
        from_status: OrderStatus, 
        to_status: OrderStatus
    ) -> bool:
        """Check if status transition is valid."""
        return to_status in self.valid_transitions.get(from_status, [])
    
    async def update_order_status(
        self, 
        order_id: int,
        new_status: OrderStatus,
        current_status: OrderStatus
    ) -> bool:
        """Update order status with validation."""
        if not self.can_transition(current_status, new_status):
            return False
        
        await db.execute(
            "UPDATE orders SET status = $1 WHERE id = $2",
            new_status.value,
            order_id
        )
        return True
```

### Callable Types and Protocols
```python
from typing import Callable, Protocol, ParamSpec, TypeVar, Concatenate
from collections.abc import Awaitable

P = ParamSpec('P')
T = TypeVar('T')

# Callable type annotations
AsyncHandler = Callable[[dict[str, Any]], Awaitable[dict[str, Any]]]
ValidationFunction = Callable[[Any], bool]
TransformFunction = Callable[[list[dict]], list[dict]]

# Protocol for dependency injection
class DatabaseConnection(Protocol):
    """Protocol for database connections."""
    
    async def execute(self, query: str, *args) -> str: ...
    async def fetch(self, query: str, *args) -> list[dict]: ...
    async def fetchrow(self, query: str, *args) -> dict | None: ...

class CacheProvider(Protocol):
    """Protocol for cache providers."""
    
    async def get(self, key: str) -> str | None: ...
    async def set(self, key: str, value: str, ttl: int = None) -> bool: ...
    async def delete(self, key: str) -> bool: ...

# Service with protocol dependencies
class UserService:
    """User service with protocol-based dependencies."""
    
    def __init__(
        self, 
        db: DatabaseConnection,
        cache: CacheProvider,
        validators: dict[str, ValidationFunction]
    ):
        self.db = db
        self.cache = cache
        self.validators = validators
    
    async def get_user(self, user_id: int) -> UserResponse | None:
        """Get user with caching."""
        # Check cache first
        cache_key = f"user:{user_id}"
        cached_data = await self.cache.get(cache_key)
        
        if cached_data:
            user_data = json.loads(cached_data)
            return UserResponse(**user_data)
        
        # Fetch from database
        user_data = await self.db.fetchrow(
            "SELECT * FROM users WHERE id = $1", user_id
        )
        
        if user_data:
            # Cache for 5 minutes
            await self.cache.set(
                cache_key, 
                json.dumps(dict(user_data)),
                ttl=300
            )
            return UserResponse(**user_data)
        
        return None
    
    async def validate_and_create_user(
        self, 
        user_data: dict[str, Any]
    ) -> UserResponse | dict[str, str]:
        """Validate and create user."""
        # Run all validations
        for field, validator in self.validators.items():
            if field in user_data and not validator(user_data[field]):
                return {"error": f"Validation failed for {field}"}
        
        # Create user
        user_id = await self.db.fetchval(
            """
            INSERT INTO users (name, email, created_at)
            VALUES ($1, $2, $3)
            RETURNING id
            """,
            user_data["name"],
            user_data["email"],
            datetime.now()
        )
        
        return UserResponse(
            id=user_id,
            name=user_data["name"],
            email=user_data["email"],
            created_at=datetime.now()
        )

# Decorator types with ParamSpec
def log_calls[**P, T](func: Callable[P, Awaitable[T]]) -> Callable[P, Awaitable[T]]:
    """Decorator to log function calls with proper typing."""
    @wraps(func)
    async def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        logger.info(f"Calling {func.__name__} with args={args}, kwargs={kwargs}")
        try:
            result = await func(*args, **kwargs)
            logger.info(f"{func.__name__} completed successfully")
            return result
        except Exception as e:
            logger.error(f"{func.__name__} failed: {e}")
            raise
    return wrapper

# Middleware type with proper parameter preservation
def require_auth[**P, T](
    func: Callable[Concatenate[UserResponse, P], Awaitable[T]]
) -> Callable[P, Awaitable[T]]:
    """Authentication decorator with type preservation."""
    @wraps(func)
    async def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        # Extract user from context (simplified)
        current_user = get_current_user()
        if not current_user:
            raise HTTPException(401, "Authentication required")
        
        # Call original function with user as first argument
        return await func(current_user, *args, **kwargs)
    return wrapper

# Usage with type safety
@log_calls
@require_auth
async def update_user_profile(
    current_user: UserResponse,
    user_id: int,
    updates: UserUpdateDict
) -> UserResponse:
    """Update user profile with logging and auth."""
    if current_user.id != user_id:
        raise HTTPException(403, "Cannot update other user's profile")
    
    # Update logic here
    return await update_user_data(user_id, updates)
```

## Type Checking and Validation

### Runtime Type Checking
```python
from typing import get_type_hints, get_origin, get_args
import inspect

def validate_function_args(func: Callable, *args, **kwargs) -> bool:
    """Validate function arguments against type hints."""
    try:
        # Get function signature and type hints
        sig = inspect.signature(func)
        type_hints = get_type_hints(func)
        
        # Bind arguments to parameters
        bound_args = sig.bind(*args, **kwargs)
        bound_args.apply_defaults()
        
        # Validate each argument
        for param_name, value in bound_args.arguments.items():
            if param_name in type_hints:
                expected_type = type_hints[param_name]
                if not isinstance(value, expected_type):
                    # Handle union types
                    origin = get_origin(expected_type)
                    if origin is Union:
                        union_args = get_args(expected_type)
                        if not any(isinstance(value, arg) for arg in union_args):
                            return False
                    else:
                        return False
        
        return True
    except Exception:
        return False

# Runtime type validation decorator
def runtime_type_check[**P, T](func: Callable[P, T]) -> Callable[P, T]:
    """Decorator for runtime type checking."""
    @wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        if not validate_function_args(func, *args, **kwargs):
            raise TypeError(f"Type validation failed for {func.__name__}")
        return func(*args, **kwargs)
    return wrapper

# Type guards for narrowing
def is_user_dict(value: Any) -> TypeGuard[UserDict]:
    """Type guard for UserDict."""
    return (
        isinstance(value, dict) and
        "id" in value and isinstance(value["id"], int) and
        "name" in value and isinstance(value["name"], str) and
        "email" in value and isinstance(value["email"], str)
    )

def process_unknown_data(data: Any) -> UserResponse | None:
    """Process data with type narrowing."""
    if is_user_dict(data):
        # Type checker knows data is UserDict here
        return UserResponse(
            id=data["id"],
            name=data["name"],
            email=data["email"],
            created_at=data.get("created_at", datetime.now())
        )
    return None

# Pydantic integration for runtime validation
class TypedAPIHandler:
    """API handler with runtime type validation."""
    
    @runtime_type_check
    async def handle_user_creation(
        self,
        user_data: dict[str, Any],
        validation_rules: dict[str, ValidationFunction]
    ) -> UserResponse | dict[str, str]:
        """Handle user creation with type validation."""
        try:
            # Validate using Pydantic
            validated_data = UserCreate(**user_data)
            
            # Additional custom validation
            for field, rule in validation_rules.items():
                field_value = getattr(validated_data, field, None)
                if field_value and not rule(field_value):
                    return {"error": f"Custom validation failed for {field}"}
            
            # Create user
            user = await self.create_user(validated_data)
            return user
            
        except ValidationError as e:
            return {"error": f"Validation error: {e}"}
        except Exception as e:
            return {"error": f"Unexpected error: {e}"}
```

## Integration with Popular Libraries

### FastAPI Advanced Type Patterns
```python
from fastapi import FastAPI, Depends, HTTPException, Query, Path, Body
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field, validator

app = FastAPI()
security = HTTPBearer()

# Advanced Pydantic models with type validation
class PaginationParams(BaseModel):
    page: int = Field(ge=1, default=1, description="Page number")
    per_page: int = Field(ge=1, le=100, default=20, description="Items per page")
    sort_by: str | None = Field(default=None, regex=r'^[a-zA-Z_][a-zA-Z0-9_]*$')
    sort_order: Literal["asc", "desc"] = Field(default="asc")

class UserFilter(BaseModel):
    name_contains: str | None = None
    email_domain: str | None = None
    is_active: bool | None = None
    created_after: datetime | None = None
    created_before: datetime | None = None
    
    @validator('email_domain')
    def validate_email_domain(cls, v):
        if v and not v.startswith('@'):
            v = f'@{v}'
        return v

class UserListResponse(BaseModel):
    users: list[UserResponse]
    pagination: dict[str, int]
    filters_applied: dict[str, Any]

# Dependency injection with advanced types
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> UserResponse:
    """Get current authenticated user."""
    user = await authenticate_user(credentials.credentials)
    if not user:
        raise HTTPException(401, "Invalid authentication")
    return user

async def require_admin_user(
    current_user: UserResponse = Depends(get_current_user)
) -> UserResponse:
    """Require admin user."""
    if not hasattr(current_user, 'role') or current_user.role != 'admin':
        raise HTTPException(403, "Admin access required")
    return current_user

# Complex endpoint with multiple type validations
@app.get("/users/advanced-search")
async def advanced_user_search(
    filters: UserFilter = Depends(),
    pagination: PaginationParams = Depends(),
    include_inactive: bool = Query(False, description="Include inactive users"),
    fields: list[str] = Query(
        default=["id", "name", "email"], 
        description="Fields to include in response"
    ),
    current_user: UserResponse = Depends(get_current_user)
) -> UserListResponse:
    """Advanced user search with comprehensive type validation."""
    
    # Build query based on filters
    query_params = filters.dict(exclude_unset=True)
    if not include_inactive:
        query_params["is_active"] = True
    
    # Execute search
    users, total_count = await search_users_with_pagination(
        filters=query_params,
        page=pagination.page,
        per_page=pagination.per_page,
        sort_by=pagination.sort_by,
        sort_order=pagination.sort_order
    )
    
    # Filter fields if specified
    if set(fields) != {"id", "name", "email"}:
        filtered_users = []
        for user in users:
            user_dict = user.dict()
            filtered_user = {k: v for k, v in user_dict.items() if k in fields}
            filtered_users.append(UserResponse(**filtered_user))
        users = filtered_users
    
    return UserListResponse(
        users=users,
        pagination={
            "page": pagination.page,
            "per_page": pagination.per_page,
            "total": total_count,
            "pages": (total_count + pagination.per_page - 1) // pagination.per_page
        },
        filters_applied=query_params
    )

# Batch operations with type safety
class BatchOperation[T](BaseModel):
    operation: Literal["create", "update", "delete"]
    items: list[T]
    options: dict[str, Any] = {}

class BatchResult[T](BaseModel):
    successful: list[T]
    failed: list[dict[str, str]]
    total_processed: int
    success_rate: float

@app.post("/users/batch")
async def batch_user_operations(
    batch: BatchOperation[UserCreate | UserUpdate],
    admin_user: UserResponse = Depends(require_admin_user)
) -> BatchResult[UserResponse]:
    """Batch user operations with type safety."""
    successful = []
    failed = []
    
    for i, item in enumerate(batch.items):
        try:
            match batch.operation, item:
                case "create", UserCreate() as user_create:
                    user = await create_user(user_create)
                    successful.append(user)
                case "update", UserUpdate() as user_update:
                    # Need user ID for update - simplified for example
                    user = await update_user(user_update.id, user_update)
                    successful.append(user)
                case "delete", dict() as delete_data if "id" in delete_data:
                    await delete_user(delete_data["id"])
                    successful.append(UserResponse(id=delete_data["id"], deleted=True))
                case _:
                    failed.append({
                        "index": i,
                        "error": f"Invalid operation {batch.operation} for item type"
                    })
        except Exception as e:
            failed.append({
                "index": i,
                "error": str(e)
            })
    
    total = len(batch.items)
    success_count = len(successful)
    
    return BatchResult[UserResponse](
        successful=successful,
        failed=failed,
        total_processed=total,
        success_rate=success_count / total if total > 0 else 0.0
    )
```

## Best Practices and Performance

### Type System Best Practices
```python
# 1. Use specific types over Any
# Bad
def process_data(data: Any) -> Any:
    return data

# Good
def process_data(data: dict[str, str | int]) -> list[dict[str, Any]]:
    return [{"processed": True, **data}]

# 2. Use Union types appropriately
# Bad - too many possibilities
def handle_input(data: str | int | float | list | dict | None) -> Any:
    pass

# Good - specific, meaningful unions
def handle_api_response(response: SuccessResponse | ErrorResponse) -> dict[str, Any]:
    match response:
        case SuccessResponse():
            return {"status": "ok", "data": response.data}
        case ErrorResponse():
            return {"status": "error", "message": response.message}

# 3. Use generics for reusable components
class Repository[T]:
    def __init__(self, model: type[T]):
        self.model = model
    
    async def find_all(self) -> list[T]:
        # Implementation
        pass

# 4. Use protocols for flexible interfaces
class Processor(Protocol):
    async def process(self, data: dict[str, Any]) -> dict[str, Any]: ...

def create_pipeline(processors: list[Processor]) -> Processor:
    # Create processing pipeline
    pass

# 5. Use TypedDict for structured dictionaries
class ConfigDict(TypedDict):
    database_url: str
    redis_url: str
    debug: bool
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"]

def initialize_app(config: ConfigDict) -> FastAPI:
    # Type-safe configuration
    pass

# 6. Combine type hints with runtime validation
def validated_endpoint[T: BaseModel](
    model: type[T]
) -> Callable[[T], Awaitable[dict[str, Any]]]:
    """Decorator for validated endpoints."""
    def decorator(func: Callable[[T], Awaitable[dict[str, Any]]]):
        @wraps(func)
        async def wrapper(data: T) -> dict[str, Any]:
            # Runtime validation already done by FastAPI/Pydantic
            return await func(data)
        return wrapper
    return decorator

@validated_endpoint(UserCreate)
async def create_user_endpoint(user_data: UserCreate) -> dict[str, Any]:
    # Type-safe and runtime-validated
    user = await create_user(user_data)
    return {"user": user.dict(), "status": "created"}
```

### Performance Considerations
```python
import sys
from typing import get_type_hints
import time

# Type hint caching for performance
_type_hint_cache: dict[Callable, dict[str, type]] = {}

def get_cached_type_hints(func: Callable) -> dict[str, type]:
    """Get type hints with caching for better performance."""
    if func not in _type_hint_cache:
        _type_hint_cache[func] = get_type_hints(func)
    return _type_hint_cache[func]

# Efficient type checking patterns
def efficient_type_validation(value: Any, expected_type: type) -> bool:
    """Efficient type validation with early returns."""
    # Quick check for exact type match
    if type(value) is expected_type:
        return True
    
    # Handle union types efficiently
    origin = get_origin(expected_type)
    if origin is Union:
        return any(isinstance(value, arg) for arg in get_args(expected_type))
    
    # Generic type checking
    if hasattr(expected_type, '__origin__'):
        origin = expected_type.__origin__
        if origin is list:
            return isinstance(value, list)
        elif origin is dict:
            return isinstance(value, dict)
    
    return isinstance(value, expected_type)

# Memory-efficient type annotations
class MemoryEfficientModel:
    """Model with memory-efficient type annotations."""
    __slots__ = ('id', 'name', 'data', '_cached_hash')
    
    def __init__(self, id: int, name: str, data: dict[str, Any]):
        self.id = id
        self.name = name
        self.data = data
        self._cached_hash: int | None = None
    
    def __hash__(self) -> int:
        if self._cached_hash is None:
            self._cached_hash = hash((self.id, self.name, tuple(sorted(self.data.items()))))
        return self._cached_hash

# Lazy type evaluation for large applications
if sys.version_info >= (3, 10):
    from typing import TYPE_CHECKING
    
    if TYPE_CHECKING:
        # Import heavy dependencies only for type checking
        from some_heavy_library import HeavyModel
    else:
        HeavyModel = "HeavyModel"  # String annotation

def process_heavy_model(model: "HeavyModel") -> dict[str, Any]:
    """Function with lazy type evaluation."""
    # Implementation doesn't import heavy library unless needed
    return {"processed": True}
```

---

**Last Updated:** Based on Python 3.9-3.12 type system improvements
**References:**
- [Python Typing Documentation](https://docs.python.org/3/library/typing.html)
- [PEP 585 - Built-in Generic Types](https://peps.python.org/pep-0585/)
- [PEP 604 - Union Operators](https://peps.python.org/pep-0604/)
- [PEP 695 - Type Parameter Syntax](https://peps.python.org/pep-0695/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
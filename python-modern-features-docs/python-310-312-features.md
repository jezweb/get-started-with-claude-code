# Python 3.10-3.12 Modern Features

## Overview
This document covers the key features introduced in Python 3.10, 3.11, and 3.12 that are particularly valuable for web application development, AI/ML integration, and modern software engineering practices.

## Python 3.10 Features

### Structural Pattern Matching (Match-Case)
One of the most significant additions to Python, enabling powerful pattern matching capabilities:

#### Basic Pattern Matching
```python
def handle_api_response(response_data):
    """Handle different types of API responses using pattern matching."""
    match response_data:
        case {"status": "success", "data": data}:
            return process_success_data(data)
        case {"status": "error", "code": 404}:
            return handle_not_found()
        case {"status": "error", "code": error_code, "message": msg}:
            return handle_error(error_code, msg)
        case {"status": "pending", "retry_after": seconds}:
            return schedule_retry(seconds)
        case _:
            return handle_unknown_response(response_data)

# Web framework routing example
def route_handler(request):
    match request.method, request.path:
        case "GET", "/api/users":
            return get_users()
        case "POST", "/api/users":
            return create_user(request.json)
        case "GET", f"/api/users/{user_id}":
            return get_user(user_id)
        case "PUT", f"/api/users/{user_id}":
            return update_user(user_id, request.json)
        case "DELETE", f"/api/users/{user_id}":
            return delete_user(user_id)
        case _:
            return {"error": "Route not found"}, 404
```

#### Advanced Pattern Matching for Data Processing
```python
def process_ml_model_config(config):
    """Process machine learning model configurations."""
    match config:
        case {
            "model_type": "neural_network",
            "layers": [*layer_configs],
            "optimizer": {"type": opt_type, "learning_rate": lr}
        }:
            return build_neural_network(layer_configs, opt_type, lr)
        
        case {
            "model_type": "random_forest",
            "n_estimators": n_trees,
            "max_depth": depth
        } if n_trees > 0 and depth > 0:
            return build_random_forest(n_trees, depth)
        
        case {
            "model_type": "ensemble",
            "models": [*model_list]
        } if len(model_list) >= 2:
            return build_ensemble(model_list)
        
        case {"model_type": model_type}:
            raise ValueError(f"Unsupported model type: {model_type}")
        
        case _:
            raise ValueError("Invalid model configuration")

# FastAPI dependency injection with pattern matching
def create_database_connection(db_config):
    match db_config:
        case {"type": "postgresql", "host": host, "port": port, "database": db}:
            return f"postgresql://{host}:{port}/{db}"
        case {"type": "sqlite", "path": path}:
            return f"sqlite:///{path}"
        case {"type": "mysql", "host": host, "database": db}:
            return f"mysql://{host}/{db}"
        case _:
            raise ValueError("Unsupported database configuration")
```

#### Pattern Matching for Error Handling
```python
def handle_service_errors(exception):
    """Advanced error handling with pattern matching."""
    match exception:
        case ConnectionError(msg) if "timeout" in msg.lower():
            return {"error": "Service timeout", "retry": True}
        
        case ConnectionError():
            return {"error": "Connection failed", "retry": True}
        
        case PermissionError():
            return {"error": "Access denied", "retry": False}
        
        case ValueError(msg) if "validation" in msg.lower():
            return {"error": "Invalid input", "details": str(msg)}
        
        case Exception() as e:
            logger.error(f"Unexpected error: {e}")
            return {"error": "Internal server error", "retry": False}
```

### Union Types with | Operator
Cleaner type annotations using the union operator:

```python
# Old style (still valid)
from typing import Union, Optional, List, Dict
def process_data(data: Union[str, int, List[str]]) -> Optional[Dict[str, str]]:
    pass

# New style with | operator
def process_data(data: str | int | list[str]) -> dict[str, str] | None:
    """Process various data types with cleaner type hints."""
    match data:
        case str() if data.isdigit():
            return {"type": "numeric_string", "value": data}
        case int():
            return {"type": "integer", "value": str(data)}
        case list() if all(isinstance(item, str) for item in data):
            return {"type": "string_list", "value": ",".join(data)}
        case _:
            return None

# FastAPI endpoint with modern type hints
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

class UserResponse(BaseModel):
    id: int
    name: str
    email: str | None = None
    is_active: bool = True

class UserUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    is_active: bool | None = None

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(user_id: int) -> UserResponse | dict[str, str]:
    """Get user by ID with modern type annotations."""
    user = await fetch_user(user_id)
    if user is None:
        return {"error": "User not found"}
    return UserResponse(**user)

@app.patch("/users/{user_id}")
async def update_user(
    user_id: int, 
    updates: UserUpdate
) -> UserResponse | dict[str, str]:
    """Update user with partial data."""
    try:
        updated_user = await update_user_data(user_id, updates.dict(exclude_unset=True))
        return UserResponse(**updated_user)
    except ValueError as e:
        return {"error": str(e)}
```

### Improved Error Messages
Python 3.10 provides much more helpful error messages:

```python
# Better error messages for attribute errors
class APIClient:
    def __init__(self):
        self.session = None
    
    def make_request(self):
        # Python 3.10+ will suggest 'session' if you mistype
        return self.sesion.get("/api/data")  # Better error message

# Better syntax error messages
def broken_function():
    # More helpful parentheses mismatch errors
    result = some_function(
        param1="value1",
        param2="value2"
    # Missing closing parenthesis - better error message

# Improved traceback information
try:
    process_complex_data()
except Exception:
    # More precise line numbers and context in tracebacks
    raise
```

## Python 3.11 Features

### Exception Groups and except*
Handle multiple exceptions simultaneously:

```python
from contextlib import asynccontextmanager
import asyncio

class ValidationError(Exception):
    pass

class NetworkError(Exception):
    pass

class DatabaseError(Exception):
    pass

async def validate_and_process_batch(items: list[dict]):
    """Process multiple items, collecting all errors."""
    errors = []
    
    for i, item in enumerate(items):
        try:
            # Validate item
            if not item.get("name"):
                raise ValidationError(f"Item {i}: Missing name")
            if not item.get("email"):
                raise ValidationError(f"Item {i}: Missing email")
            
            # Process item (might raise NetworkError or DatabaseError)
            await process_item(item)
            
        except (ValidationError, NetworkError, DatabaseError) as e:
            errors.append(e)
    
    if errors:
        raise ExceptionGroup("Batch processing failed", errors)

# FastAPI error handler for exception groups
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(ExceptionGroup)
async def exception_group_handler(request: Request, exc_group: ExceptionGroup):
    """Handle multiple exceptions from batch operations."""
    errors_by_type = {}
    
    try:
        # Handle validation errors
        raise exc_group
    except* ValidationError as validation_errors:
        errors_by_type["validation"] = [str(e) for e in validation_errors.exceptions]
    except* NetworkError as network_errors:
        errors_by_type["network"] = [str(e) for e in network_errors.exceptions]
    except* DatabaseError as db_errors:
        errors_by_type["database"] = [str(e) for e in db_errors.exceptions]
    
    return JSONResponse(
        status_code=400,
        content={
            "error": "Multiple errors occurred",
            "details": errors_by_type,
            "total_errors": len(exc_group.exceptions)
        }
    )

# Web scraping example with exception groups
async def scrape_multiple_urls(urls: list[str]):
    """Scrape multiple URLs, handling various failure types."""
    import aiohttp
    
    errors = []
    results = []
    
    async with aiohttp.ClientSession() as session:
        for url in urls:
            try:
                async with session.get(url, timeout=10) as response:
                    if response.status == 200:
                        content = await response.text()
                        results.append({"url": url, "content": content})
                    else:
                        raise NetworkError(f"HTTP {response.status} for {url}")
                        
            except asyncio.TimeoutError:
                errors.append(NetworkError(f"Timeout for {url}"))
            except aiohttp.ClientError as e:
                errors.append(NetworkError(f"Client error for {url}: {e}"))
            except Exception as e:
                errors.append(Exception(f"Unexpected error for {url}: {e}"))
    
    if errors:
        if results:
            # Partial success - you might want to handle this differently
            raise ExceptionGroup("Some URLs failed", errors)
        else:
            # Total failure
            raise ExceptionGroup("All URLs failed", errors)
    
    return results
```

### Task and Exception Groups for Async Operations
```python
import asyncio
from typing import Any

async def process_user_data_pipeline(user_ids: list[int]):
    """Process multiple users through a data pipeline."""
    
    async def fetch_user_profile(user_id: int) -> dict:
        # Simulate API call
        await asyncio.sleep(0.1)
        if user_id < 0:
            raise ValueError(f"Invalid user ID: {user_id}")
        return {"id": user_id, "name": f"User {user_id}"}
    
    async def enrich_user_data(user_data: dict) -> dict:
        # Simulate data enrichment
        await asyncio.sleep(0.1)
        if user_data["id"] == 999:
            raise NetworkError("External service unavailable")
        user_data["enriched"] = True
        return user_data
    
    async def save_to_database(user_data: dict) -> dict:
        # Simulate database save
        await asyncio.sleep(0.1)
        if user_data["id"] == 888:
            raise DatabaseError("Database connection failed")
        user_data["saved"] = True
        return user_data
    
    # Process users in parallel with exception grouping
    async with asyncio.TaskGroup() as tg:
        # Create tasks for each stage
        profile_tasks = [
            tg.create_task(fetch_user_profile(uid)) 
            for uid in user_ids
        ]
    
    # Collect results and handle any failures
    profiles = []
    for task in profile_tasks:
        try:
            profiles.append(await task)
        except Exception as e:
            # Individual task failures are handled by TaskGroup
            pass
    
    # Continue pipeline for successful profiles
    if profiles:
        async with asyncio.TaskGroup() as tg:
            enrichment_tasks = [
                tg.create_task(enrich_user_data(profile))
                for profile in profiles
            ]
        
        enriched_data = [await task for task in enrichment_tasks]
        
        async with asyncio.TaskGroup() as tg:
            save_tasks = [
                tg.create_task(save_to_database(data))
                for data in enriched_data
            ]
        
        final_results = [await task for task in save_tasks]
        return final_results
    
    return []
```

### Performance Improvements
Python 3.11 offers significant performance improvements:

```python
# Faster function calls and loops
import time
from typing import Callable

def performance_comparison():
    """Demonstrate performance improvements in Python 3.11+."""
    
    # Function call optimization
    def fast_computation(x: int, y: int) -> int:
        return x * y + x // y
    
    # List comprehensions are faster
    data = list(range(1000000))
    
    start = time.time()
    result = [fast_computation(x, x + 1) for x in data if x % 2 == 0]
    end = time.time()
    
    print(f"List comprehension took: {end - start:.4f} seconds")
    
    # Dictionary operations are faster
    start = time.time()
    lookup = {str(i): i for i in range(100000)}
    values = [lookup[str(i)] for i in range(0, 100000, 2)]
    end = time.time()
    
    print(f"Dictionary operations took: {end - start:.4f} seconds")

# Optimized async/await performance
async def optimized_async_operations():
    """Async operations are significantly faster in Python 3.11+."""
    
    async def async_task(n: int) -> int:
        await asyncio.sleep(0.001)  # Simulate async work
        return n * 2
    
    start = time.time()
    tasks = [async_task(i) for i in range(1000)]
    results = await asyncio.gather(*tasks)
    end = time.time()
    
    print(f"1000 async tasks took: {end - start:.4f} seconds")
    return results
```

## Python 3.12 Features

### Type Parameter Syntax (PEP 695)
Simplified generic type syntax:

```python
# Old style (still valid)
from typing import TypeVar, Generic, List

T = TypeVar('T')
K = TypeVar('K')
V = TypeVar('V')

class OldRepository(Generic[T]):
    def __init__(self):
        self._items: List[T] = []

# New style with type parameters
class Repository[T]:
    """Generic repository with modern type parameter syntax."""
    
    def __init__(self):
        self._items: list[T] = []
    
    def add(self, item: T) -> None:
        self._items.append(item)
    
    def get_all(self) -> list[T]:
        return self._items.copy()
    
    def find_by(self, predicate: Callable[[T], bool]) -> list[T]:
        return [item for item in self._items if predicate(item)]

# Generic functions with type parameters
def process_api_response[T](
    data: dict[str, any], 
    parser: Callable[[dict], T]
) -> T | None:
    """Process API response with generic type support."""
    try:
        return parser(data)
    except (KeyError, ValueError, TypeError):
        return None

def cache_result[K, V](
    cache: dict[K, V], 
    key: K, 
    factory: Callable[[], V]
) -> V:
    """Generic caching function."""
    if key not in cache:
        cache[key] = factory()
    return cache[key]

# FastAPI with generic types
from fastapi import FastAPI, Depends
from pydantic import BaseModel

class APIResponse[T](BaseModel):
    """Generic API response wrapper."""
    success: bool
    data: T | None = None
    error: str | None = None
    metadata: dict[str, any] = {}

class PaginatedResponse[T](BaseModel):
    """Generic paginated response."""
    items: list[T]
    total: int
    page: int
    per_page: int
    has_next: bool

class User(BaseModel):
    id: int
    name: str
    email: str

class Product(BaseModel):
    id: int
    name: str
    price: float

app = FastAPI()

@app.get("/users")
async def get_users(
    page: int = 1, 
    per_page: int = 10
) -> PaginatedResponse[User]:
    """Get paginated users with generic response type."""
    users = await fetch_users(page, per_page)
    total = await count_users()
    
    return PaginatedResponse[User](
        items=users,
        total=total,
        page=page,
        per_page=per_page,
        has_next=(page * per_page) < total
    )

@app.get("/products")
async def get_products() -> APIResponse[list[Product]]:
    """Get products with generic response wrapper."""
    try:
        products = await fetch_products()
        return APIResponse[list[Product]](
            success=True,
            data=products
        )
    except Exception as e:
        return APIResponse[list[Product]](
            success=False,
            error=str(e)
        )
```

### Improved Error Messages
Even better error messages than Python 3.11:

```python
# More specific error suggestions
def example_function():
    my_dict = {"key1": "value1", "key2": "value2"}
    
    # Python 3.12 provides better suggestions for typos
    print(my_dict["ky1"])  # Suggests "key1"
    
    # Better import error messages
    from collections import defalutdict  # Suggests "defaultdict"
    
    # More helpful syntax error messages
    if condition
        print("Missing colon - better error message")

# Enhanced traceback information
def process_nested_data():
    try:
        data = [{"users": [{"name": "John"}]}]
        return data[0]["users"][0]["nme"]  # Typo in "name"
    except KeyError as e:
        # Python 3.12 provides better context about where the error occurred
        raise

# Improved suggestions for attribute errors
class APIClient:
    def __init__(self):
        self.session = requests.Session()
        self.base_url = "https://api.example.com"
    
    def get_data(self):
        # Better suggestions for attribute typos
        return self.sesion.get(f"{self.base_url}/data")  # Suggests "session"
```

### Performance and Memory Improvements
Further performance enhancements:

```python
import sys
from typing import NamedTuple

# Improved memory usage for classes
class OptimizedDataClass:
    """Classes use less memory in Python 3.12."""
    __slots__ = ('name', 'value', 'metadata')
    
    def __init__(self, name: str, value: int, metadata: dict):
        self.name = name
        self.value = value
        self.metadata = metadata

# More efficient string operations
def efficient_string_processing(data: list[str]) -> str:
    """String operations are more efficient in Python 3.12."""
    # Faster string concatenation
    result = "".join(f"Item: {item}\n" for item in data)
    
    # More efficient string formatting
    formatted = f"Processing {len(data)} items: {', '.join(data[:5])}"
    
    return result + formatted

# Improved list and dict performance
def improved_collections_performance():
    """Collections operations are faster."""
    # Faster list operations
    large_list = list(range(1000000))
    filtered = [x for x in large_list if x % 100 == 0]
    
    # More efficient dictionary operations
    large_dict = {f"key_{i}": i for i in range(100000)}
    values = [large_dict[f"key_{i}"] for i in range(0, 100000, 10)]
    
    return len(filtered), len(values)
```

## Web Development Integration Patterns

### FastAPI with Modern Python Features
```python
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Annotated
import asyncio

app = FastAPI()

# Modern type annotations with FastAPI
class UserCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str = Field(pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    age: int | None = Field(default=None, ge=0, le=150)

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    age: int | None = None
    is_active: bool = True

# Generic service with type parameters
class Service[T]:
    def __init__(self, model_class: type[T]):
        self.model_class = model_class
        self._storage: dict[int, T] = {}
        self._next_id = 1
    
    async def create(self, data: dict) -> T:
        item = self.model_class(id=self._next_id, **data)
        self._storage[self._next_id] = item
        self._next_id += 1
        return item
    
    async def get(self, item_id: int) -> T | None:
        return self._storage.get(item_id)
    
    async def list_all(self) -> list[T]:
        return list(self._storage.values())

# Dependency injection with modern types
user_service = Service[UserResponse](UserResponse)

def get_user_service() -> Service[UserResponse]:
    return user_service

# Endpoints with pattern matching and modern types
@app.post("/users", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    service: Annotated[Service[UserResponse], Depends(get_user_service)]
) -> UserResponse:
    """Create a new user with modern Python features."""
    try:
        return await service.create(user_data.model_dump())
    except Exception as e:
        match e:
            case ValueError(msg) if "email" in msg.lower():
                raise HTTPException(400, "Invalid email format")
            case ValueError(msg) if "age" in msg.lower():
                raise HTTPException(400, "Invalid age value")
            case _:
                raise HTTPException(500, "Internal server error")

@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    service: Annotated[Service[UserResponse], Depends(get_user_service)]
) -> UserResponse | dict[str, str]:
    """Get user with modern return type annotations."""
    user = await service.get(user_id)
    match user:
        case UserResponse() as found_user:
            return found_user
        case None:
            return {"error": "User not found", "user_id": str(user_id)}

# Batch operations with exception groups
@app.post("/users/batch")
async def create_users_batch(
    users_data: list[UserCreate],
    service: Annotated[Service[UserResponse], Depends(get_user_service)]
) -> dict[str, any]:
    """Create multiple users with exception group handling."""
    created_users = []
    errors = []
    
    for i, user_data in enumerate(users_data):
        try:
            user = await service.create(user_data.model_dump())
            created_users.append(user)
        except Exception as e:
            errors.append(Exception(f"User {i}: {str(e)}"))
    
    if errors and not created_users:
        # All failed
        raise ExceptionGroup("All user creations failed", errors)
    elif errors:
        # Partial success - return what we have with warnings
        return {
            "created_users": created_users,
            "warnings": [str(e) for e in errors],
            "total_requested": len(users_data),
            "total_created": len(created_users)
        }
    else:
        # All succeeded
        return {
            "created_users": created_users,
            "total_created": len(created_users)
        }
```

### Async Patterns with Modern Python
```python
import asyncio
from contextlib import asynccontextmanager
import aiohttp
import aiofiles

# Modern async context managers
@asynccontextmanager
async def managed_http_session():
    """Async context manager for HTTP sessions."""
    session = aiohttp.ClientSession()
    try:
        yield session
    finally:
        await session.close()

@asynccontextmanager
async def managed_file_operations(filepath: str):
    """Async context manager for file operations."""
    async with aiofiles.open(filepath, 'w') as f:
        yield f

# Task groups for parallel processing
async def process_multiple_apis(api_endpoints: list[str]) -> dict[str, any]:
    """Process multiple API endpoints in parallel with task groups."""
    results = {}
    
    async with managed_http_session() as session:
        async with asyncio.TaskGroup() as tg:
            tasks = {
                endpoint: tg.create_task(fetch_api_data(session, endpoint))
                for endpoint in api_endpoints
            }
        
        # Collect results
        for endpoint, task in tasks.items():
            try:
                results[endpoint] = await task
            except Exception as e:
                results[endpoint] = {"error": str(e)}
    
    return results

async def fetch_api_data(session: aiohttp.ClientSession, endpoint: str) -> dict:
    """Fetch data from API endpoint."""
    async with session.get(endpoint) as response:
        if response.status == 200:
            return await response.json()
        else:
            raise aiohttp.ClientResponseError(
                response.request_info,
                response.history,
                status=response.status
            )

# Pattern matching with async operations
async def handle_async_response(response_future: asyncio.Future) -> dict[str, any]:
    """Handle async response with pattern matching."""
    try:
        result = await response_future
    except Exception as e:
        match e:
            case asyncio.TimeoutError():
                return {"error": "Request timeout", "retry": True}
            case aiohttp.ClientConnectorError():
                return {"error": "Connection failed", "retry": True}
            case aiohttp.ClientResponseError() as http_err:
                match http_err.status:
                    case 404:
                        return {"error": "Resource not found", "retry": False}
                    case 429:
                        return {"error": "Rate limited", "retry": True, "backoff": 60}
                    case status if 500 <= status < 600:
                        return {"error": "Server error", "retry": True}
                    case _:
                        return {"error": f"HTTP {http_err.status}", "retry": False}
            case _:
                return {"error": "Unexpected error", "retry": False}
    
    return {"data": result, "success": True}
```

## Performance Best Practices

### Optimization Techniques for Modern Python
```python
from functools import lru_cache, cache
from typing import Any
import time

# Use built-in optimizations
@cache  # Python 3.9+ - unlimited cache
def expensive_computation(n: int) -> int:
    """Cache expensive computations."""
    time.sleep(0.1)  # Simulate expensive operation
    return sum(range(n))

@lru_cache(maxsize=128)  # Limited cache
def fetch_user_permissions(user_id: int, role: str) -> set[str]:
    """Cache user permissions with LRU eviction."""
    # Simulate database lookup
    return {"read", "write"} if role == "admin" else {"read"}

# Efficient data structures with type hints
class OptimizedDataProcessor:
    """Use efficient data structures and algorithms."""
    
    def __init__(self):
        self._lookup: dict[str, int] = {}
        self._data: list[dict[str, Any]] = []
    
    def add_item(self, item: dict[str, Any]) -> None:
        """Add item with O(1) lookup."""
        item_id = item.get("id")
        if item_id:
            self._lookup[str(item_id)] = len(self._data)
        self._data.append(item)
    
    def find_by_id(self, item_id: str) -> dict[str, Any] | None:
        """O(1) lookup by ID."""
        index = self._lookup.get(item_id)
        return self._data[index] if index is not None else None
    
    def bulk_update(self, updates: dict[str, dict[str, Any]]) -> None:
        """Efficient bulk updates."""
        for item_id, update_data in updates.items():
            index = self._lookup.get(item_id)
            if index is not None:
                self._data[index].update(update_data)

# Memory-efficient generators
def process_large_dataset(file_path: str) -> Generator[dict[str, Any], None, None]:
    """Process large files without loading everything into memory."""
    import json
    
    with open(file_path, 'r') as f:
        for line in f:
            try:
                yield json.loads(line.strip())
            except json.JSONDecodeError:
                continue  # Skip invalid lines

# Optimized async patterns
async def concurrent_processing[T](
    items: list[T], 
    processor: Callable[[T], Awaitable[Any]],
    max_concurrency: int = 10
) -> list[Any]:
    """Process items concurrently with controlled concurrency."""
    semaphore = asyncio.Semaphore(max_concurrency)
    
    async def bounded_processor(item: T) -> Any:
        async with semaphore:
            return await processor(item)
    
    return await asyncio.gather(*[
        bounded_processor(item) for item in items
    ])
```

## Migration Guidelines

### Upgrading from Older Python Versions
```python
# Migration checklist for modern Python features

# 1. Replace Union types with | operator
# Old:
from typing import Union, Optional, List, Dict
def process(data: Union[str, int]) -> Optional[Dict[str, List[str]]]:
    pass

# New:
def process(data: str | int) -> dict[str, list[str]] | None:
    pass

# 2. Replace if/elif chains with match/case
# Old:
def handle_status(status):
    if status == "pending":
        return handle_pending()
    elif status == "completed":
        return handle_completed()
    elif status == "failed":
        return handle_failed()
    else:
        return handle_unknown()

# New:
def handle_status(status):
    match status:
        case "pending":
            return handle_pending()
        case "completed":
            return handle_completed()
        case "failed":
            return handle_failed()
        case _:
            return handle_unknown()

# 3. Use exception groups for multiple errors
# Old:
errors = []
for item in items:
    try:
        process_item(item)
    except Exception as e:
        errors.append(e)
if errors:
    raise Exception(f"Multiple errors: {errors}")

# New:
errors = []
for item in items:
    try:
        process_item(item)
    except Exception as e:
        errors.append(e)
if errors:
    raise ExceptionGroup("Processing failed", errors)

# 4. Modernize generic classes
# Old:
from typing import TypeVar, Generic
T = TypeVar('T')
class Container(Generic[T]):
    pass

# New:
class Container[T]:
    pass
```

## Best Practices Summary

### Code Style and Patterns
1. **Use pattern matching** for complex conditional logic
2. **Prefer | operator** for union types in new code
3. **Leverage exception groups** for batch operations
4. **Use type parameters** for cleaner generic code
5. **Take advantage of performance improvements** in newer versions

### Web Development Guidelines
1. **Combine FastAPI with modern type hints** for better API documentation
2. **Use pattern matching for request routing** and error handling
3. **Implement exception groups** for batch API operations
4. **Leverage async task groups** for concurrent processing
5. **Apply modern caching patterns** for performance optimization

### Migration Strategy
1. **Gradual adoption**: Start with new code, gradually update existing code
2. **Type annotation modernization**: Replace Union with | operator
3. **Error handling upgrade**: Move to exception groups where appropriate
4. **Performance optimization**: Utilize Python 3.11+ speed improvements
5. **Testing**: Ensure compatibility when upgrading Python versions

---

**Last Updated:** Based on Python 3.10, 3.11, and 3.12 official documentation
**References:** 
- [Python 3.10 What's New](https://docs.python.org/3/whatsnew/3.10.html)
- [Python 3.11 What's New](https://docs.python.org/3/whatsnew/3.11.html)
- [Python 3.12 What's New](https://docs.python.org/3/whatsnew/3.12.html)
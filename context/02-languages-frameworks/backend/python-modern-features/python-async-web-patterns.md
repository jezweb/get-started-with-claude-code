# Python Async/Await Patterns for Web Development

## Overview
This guide covers modern async/await patterns specifically designed for web application development, including FastAPI integration, concurrent processing, streaming responses, and production-ready async patterns.

## Core Async Concepts for Web Development

### Basic Async/Await Patterns
```python
import asyncio
import aiohttp
import aiofiles
from typing import Any, AsyncGenerator, Callable, Awaitable
from contextlib import asynccontextmanager

# Basic async function patterns
async def fetch_user_data(user_id: int) -> dict[str, Any]:
    """Basic async function for web applications."""
    # Simulate database call
    await asyncio.sleep(0.1)
    return {"id": user_id, "name": f"User {user_id}", "active": True}

async def process_user_request(user_id: int) -> dict[str, Any]:
    """Combine multiple async operations."""
    # Fetch data concurrently
    user_data, permissions, preferences = await asyncio.gather(
        fetch_user_data(user_id),
        fetch_user_permissions(user_id),
        fetch_user_preferences(user_id)
    )
    
    return {
        "user": user_data,
        "permissions": permissions,
        "preferences": preferences
    }

async def fetch_user_permissions(user_id: int) -> list[str]:
    """Fetch user permissions asynchronously."""
    await asyncio.sleep(0.05)
    return ["read", "write", "admin"]

async def fetch_user_preferences(user_id: int) -> dict[str, Any]:
    """Fetch user preferences asynchronously."""
    await asyncio.sleep(0.05)
    return {"theme": "dark", "language": "en"}
```

### Async Context Managers for Web Services
```python
import aioredis
import asyncpg
from contextlib import asynccontextmanager

@asynccontextmanager
async def database_connection():
    """Async context manager for database connections."""
    conn = await asyncpg.connect("postgresql://user:pass@localhost/db")
    try:
        yield conn
    finally:
        await conn.close()

@asynccontextmanager
async def redis_connection():
    """Async context manager for Redis connections."""
    redis = await aioredis.create_redis_pool("redis://localhost")
    try:
        yield redis
    finally:
        redis.close()
        await redis.wait_closed()

@asynccontextmanager
async def http_session():
    """Async context manager for HTTP sessions."""
    session = aiohttp.ClientSession()
    try:
        yield session
    finally:
        await session.close()

# Usage in web applications
async def get_user_data_with_cache(user_id: int) -> dict[str, Any]:
    """Get user data with Redis caching."""
    async with redis_connection() as redis:
        # Check cache first
        cached = await redis.get(f"user:{user_id}")
        if cached:
            return json.loads(cached)
        
        # Fetch from database
        async with database_connection() as db:
            user = await db.fetchrow(
                "SELECT * FROM users WHERE id = $1", user_id
            )
            user_data = dict(user) if user else None
            
            # Cache for 5 minutes
            if user_data:
                await redis.setex(
                    f"user:{user_id}", 
                    300, 
                    json.dumps(user_data)
                )
            
            return user_data
```

## FastAPI Async Integration

### Async Endpoints and Dependencies
```python
from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import asyncio
from typing import AsyncGenerator

app = FastAPI()

# Pydantic models
class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    is_active: bool

class UserCreate(BaseModel):
    name: str
    email: str

# Async dependency injection
async def get_database():
    """Async dependency for database connection."""
    async with database_connection() as db:
        yield db

async def get_current_user(
    user_id: int,
    db = Depends(get_database)
) -> UserResponse:
    """Async dependency to get current user."""
    user = await db.fetchrow(
        "SELECT * FROM users WHERE id = $1", user_id
    )
    if not user:
        raise HTTPException(404, "User not found")
    return UserResponse(**user)

# Async endpoints
@app.get("/users/{user_id}")
async def get_user(
    user_id: int,
    db = Depends(get_database)
) -> UserResponse:
    """Get user by ID asynchronously."""
    user = await db.fetchrow(
        "SELECT id, name, email, is_active FROM users WHERE id = $1", 
        user_id
    )
    if not user:
        raise HTTPException(404, "User not found")
    return UserResponse(**user)

@app.post("/users")
async def create_user(
    user: UserCreate,
    background_tasks: BackgroundTasks,
    db = Depends(get_database)
) -> UserResponse:
    """Create user with background tasks."""
    # Insert user
    user_id = await db.fetchval(
        """
        INSERT INTO users (name, email, is_active) 
        VALUES ($1, $2, $3) 
        RETURNING id
        """,
        user.name, user.email, True
    )
    
    # Schedule background tasks
    background_tasks.add_task(send_welcome_email, user.email)
    background_tasks.add_task(update_user_analytics, user_id)
    
    return UserResponse(
        id=user_id,
        name=user.name,
        email=user.email,
        is_active=True
    )

async def send_welcome_email(email: str):
    """Background task to send welcome email."""
    async with http_session() as session:
        await session.post(
            "https://api.mailservice.com/send",
            json={
                "to": email,
                "subject": "Welcome!",
                "body": "Welcome to our service!"
            }
        )

async def update_user_analytics(user_id: int):
    """Background task to update analytics."""
    await asyncio.sleep(1)  # Simulate processing
    print(f"Analytics updated for user {user_id}")
```

### Async Middleware and Request Processing
```python
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
import time
import logging

class AsyncLoggingMiddleware(BaseHTTPMiddleware):
    """Async middleware for request logging."""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Log request
        logger.info(f"Request: {request.method} {request.url}")
        
        # Process request
        response = await call_next(request)
        
        # Log response
        process_time = time.time() - start_time
        logger.info(
            f"Response: {response.status_code} "
            f"in {process_time:.4f}s"
        )
        
        response.headers["X-Process-Time"] = str(process_time)
        return response

class AsyncRateLimitMiddleware(BaseHTTPMiddleware):
    """Async rate limiting middleware."""
    
    def __init__(self, app, calls_per_minute: int = 60):
        super().__init__(app)
        self.calls_per_minute = calls_per_minute
        self.request_counts = {}
    
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host
        current_time = time.time()
        
        # Clean old entries
        self.request_counts = {
            ip: timestamps for ip, timestamps in self.request_counts.items()
            if timestamps and max(timestamps) > current_time - 60
        }
        
        # Check rate limit
        if client_ip in self.request_counts:
            recent_requests = [
                t for t in self.request_counts[client_ip]
                if t > current_time - 60
            ]
            if len(recent_requests) >= self.calls_per_minute:
                return Response(
                    content="Rate limit exceeded",
                    status_code=429,
                    headers={"Retry-After": "60"}
                )
            self.request_counts[client_ip] = recent_requests + [current_time]
        else:
            self.request_counts[client_ip] = [current_time]
        
        return await call_next(request)

# Add middleware to FastAPI app
app.add_middleware(AsyncLoggingMiddleware)
app.add_middleware(AsyncRateLimitMiddleware, calls_per_minute=100)
```

## Streaming Responses and Server-Sent Events

### Async Streaming Responses
```python
import json
from fastapi.responses import StreamingResponse

async def generate_data_stream() -> AsyncGenerator[str, None]:
    """Generate streaming data."""
    for i in range(100):
        data = {"id": i, "timestamp": time.time(), "value": i * 2}
        yield f"data: {json.dumps(data)}\n\n"
        await asyncio.sleep(0.1)  # Simulate processing time

@app.get("/stream/data")
async def stream_data():
    """Stream data to client."""
    return StreamingResponse(
        generate_data_stream(),
        media_type="text/plain",
        headers={"Cache-Control": "no-cache"}
    )

async def generate_file_stream(file_path: str) -> AsyncGenerator[bytes, None]:
    """Stream file content asynchronously."""
    async with aiofiles.open(file_path, 'rb') as file:
        while chunk := await file.read(8192):  # 8KB chunks
            yield chunk

@app.get("/download/{filename}")
async def download_file(filename: str):
    """Stream file download."""
    file_path = f"/uploads/{filename}"
    return StreamingResponse(
        generate_file_stream(file_path),
        media_type="application/octet-stream",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

# Server-Sent Events (SSE)
async def event_stream() -> AsyncGenerator[str, None]:
    """Generate server-sent events."""
    event_id = 0
    while True:
        # Simulate real-time data
        data = {
            "id": event_id,
            "timestamp": time.time(),
            "message": f"Event {event_id}"
        }
        
        yield f"id: {event_id}\n"
        yield f"event: update\n"
        yield f"data: {json.dumps(data)}\n\n"
        
        event_id += 1
        await asyncio.sleep(1)  # Send event every second

@app.get("/events")
async def stream_events():
    """Stream server-sent events."""
    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )
```

### WebSocket Async Patterns
```python
from fastapi import WebSocket, WebSocketDisconnect
import json

class ConnectionManager:
    """Manage WebSocket connections."""
    
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self.user_connections: dict[int, WebSocket] = {}
    
    async def connect(self, websocket: WebSocket, user_id: int = None):
        """Accept WebSocket connection."""
        await websocket.accept()
        self.active_connections.append(websocket)
        if user_id:
            self.user_connections[user_id] = websocket
    
    def disconnect(self, websocket: WebSocket, user_id: int = None):
        """Remove WebSocket connection."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if user_id and user_id in self.user_connections:
            del self.user_connections[user_id]
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        """Send message to specific connection."""
        await websocket.send_text(message)
    
    async def send_user_message(self, message: str, user_id: int):
        """Send message to specific user."""
        if user_id in self.user_connections:
            websocket = self.user_connections[user_id]
            await websocket.send_text(message)
    
    async def broadcast(self, message: str):
        """Broadcast message to all connections."""
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except:
                disconnected.append(connection)
        
        # Remove disconnected connections
        for connection in disconnected:
            if connection in self.active_connections:
                self.active_connections.remove(connection)

manager = ConnectionManager()

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for real-time communication."""
    await manager.connect(websocket, user_id)
    try:
        while True:
            # Receive message
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Process message based on type
            match message_data.get("type"):
                case "chat":
                    await handle_chat_message(message_data, user_id)
                case "notification":
                    await handle_notification(message_data, user_id)
                case "status":
                    await handle_status_update(message_data, user_id)
                case _:
                    await manager.send_user_message(
                        json.dumps({"error": "Unknown message type"}),
                        user_id
                    )
    
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        await manager.broadcast(
            json.dumps({
                "type": "user_disconnected", 
                "user_id": user_id
            })
        )

async def handle_chat_message(message_data: dict, user_id: int):
    """Handle chat message."""
    response = {
        "type": "chat",
        "user_id": user_id,
        "message": message_data.get("message"),
        "timestamp": time.time()
    }
    await manager.broadcast(json.dumps(response))

async def handle_notification(message_data: dict, user_id: int):
    """Handle notification message."""
    # Process notification asynchronously
    await process_notification(message_data, user_id)

async def handle_status_update(message_data: dict, user_id: int):
    """Handle user status update."""
    status = message_data.get("status")
    response = {
        "type": "status_update",
        "user_id": user_id,
        "status": status,
        "timestamp": time.time()
    }
    await manager.broadcast(json.dumps(response))
```

## Concurrent Processing Patterns

### Task Management and Concurrency Control
```python
import asyncio
from asyncio import Semaphore, Queue
from typing import Callable, Any

class AsyncTaskManager:
    """Manage concurrent async tasks with rate limiting."""
    
    def __init__(self, max_concurrent: int = 10):
        self.semaphore = Semaphore(max_concurrent)
        self.active_tasks: set[asyncio.Task] = set()
    
    async def run_task(
        self, 
        coro: Callable[..., Awaitable[Any]], 
        *args, 
        **kwargs
    ) -> Any:
        """Run task with concurrency control."""
        async with self.semaphore:
            result = await coro(*args, **kwargs)
            return result
    
    async def run_tasks_concurrently(
        self, 
        tasks: list[tuple[Callable, tuple, dict]]
    ) -> list[Any]:
        """Run multiple tasks concurrently."""
        async def bounded_task(coro, args, kwargs):
            return await self.run_task(coro, *args, **kwargs)
        
        task_coroutines = [
            bounded_task(coro, args, kwargs)
            for coro, args, kwargs in tasks
        ]
        
        return await asyncio.gather(*task_coroutines, return_exceptions=True)
    
    def add_background_task(
        self, 
        coro: Callable[..., Awaitable[Any]], 
        *args, 
        **kwargs
    ):
        """Add background task without waiting."""
        task = asyncio.create_task(self.run_task(coro, *args, **kwargs))
        self.active_tasks.add(task)
        task.add_done_callback(self.active_tasks.discard)
    
    async def wait_for_all_tasks(self):
        """Wait for all background tasks to complete."""
        await asyncio.gather(*self.active_tasks, return_exceptions=True)

# Usage example
task_manager = AsyncTaskManager(max_concurrent=5)

@app.post("/process-batch")
async def process_batch_data(items: list[dict]):
    """Process multiple items concurrently."""
    
    async def process_single_item(item: dict) -> dict:
        # Simulate processing
        await asyncio.sleep(0.1)
        return {"id": item["id"], "processed": True}
    
    # Create task list
    tasks = [
        (process_single_item, (item,), {})
        for item in items
    ]
    
    # Run concurrently
    results = await task_manager.run_tasks_concurrently(tasks)
    
    # Filter out exceptions
    successful_results = [
        result for result in results 
        if not isinstance(result, Exception)
    ]
    
    return {
        "processed": len(successful_results),
        "total": len(items),
        "results": successful_results
    }
```

### Producer-Consumer Patterns
```python
from asyncio import Queue
import logging

class AsyncProducerConsumer:
    """Async producer-consumer pattern for web applications."""
    
    def __init__(self, queue_size: int = 100):
        self.queue: Queue = Queue(maxsize=queue_size)
        self.consumers: list[asyncio.Task] = []
        self.is_running = False
    
    async def start_consumers(self, num_consumers: int = 3):
        """Start consumer tasks."""
        self.is_running = True
        self.consumers = [
            asyncio.create_task(self._consumer(f"consumer-{i}"))
            for i in range(num_consumers)
        ]
    
    async def stop_consumers(self):
        """Stop all consumers."""
        self.is_running = False
        
        # Add sentinel values to wake up consumers
        for _ in self.consumers:
            await self.queue.put(None)
        
        # Wait for consumers to finish
        await asyncio.gather(*self.consumers, return_exceptions=True)
    
    async def produce(self, item: Any):
        """Add item to queue."""
        await self.queue.put(item)
    
    async def _consumer(self, consumer_id: str):
        """Consumer coroutine."""
        logger.info(f"Consumer {consumer_id} started")
        
        while self.is_running:
            try:
                # Get item from queue with timeout
                item = await asyncio.wait_for(self.queue.get(), timeout=1.0)
                
                if item is None:  # Sentinel value
                    break
                
                # Process item
                await self._process_item(item, consumer_id)
                
                # Mark task as done
                self.queue.task_done()
                
            except asyncio.TimeoutError:
                continue  # Check if still running
            except Exception as e:
                logger.error(f"Consumer {consumer_id} error: {e}")
        
        logger.info(f"Consumer {consumer_id} stopped")
    
    async def _process_item(self, item: Any, consumer_id: str):
        """Process individual item."""
        logger.info(f"{consumer_id} processing {item}")
        
        # Simulate async work
        await asyncio.sleep(0.1)
        
        # Example: send email, update database, call API, etc.
        match item.get("type"):
            case "email":
                await self._send_email(item)
            case "notification":
                await self._send_notification(item)
            case "analytics":
                await self._update_analytics(item)
            case _:
                logger.warning(f"Unknown item type: {item.get('type')}")
    
    async def _send_email(self, item: dict):
        """Send email asynchronously."""
        # Simulate email sending
        await asyncio.sleep(0.2)
        logger.info(f"Email sent to {item.get('recipient')}")
    
    async def _send_notification(self, item: dict):
        """Send notification asynchronously."""
        await asyncio.sleep(0.1)
        logger.info(f"Notification sent: {item.get('message')}")
    
    async def _update_analytics(self, item: dict):
        """Update analytics asynchronously."""
        await asyncio.sleep(0.05)
        logger.info(f"Analytics updated for {item.get('user_id')}")

# Global producer-consumer instance
processor = AsyncProducerConsumer()

# FastAPI lifespan events
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan."""
    # Startup
    await processor.start_consumers(num_consumers=3)
    yield
    # Shutdown
    await processor.stop_consumers()

app = FastAPI(lifespan=lifespan)

@app.post("/queue-task")
async def queue_task(task_data: dict):
    """Add task to processing queue."""
    await processor.produce(task_data)
    return {"message": "Task queued successfully"}
```

## Error Handling and Resilience

### Async Error Handling Patterns
```python
import asyncio
from typing import Any, Callable, TypeVar
from functools import wraps
import logging

T = TypeVar('T')

async def retry_async(
    func: Callable[..., Awaitable[T]], 
    max_retries: int = 3,
    backoff_factor: float = 1.0,
    exceptions: tuple = (Exception,)
) -> T:
    """Retry async function with exponential backoff."""
    last_exception = None
    
    for attempt in range(max_retries + 1):
        try:
            return await func()
        except exceptions as e:
            last_exception = e
            if attempt == max_retries:
                break
            
            wait_time = backoff_factor * (2 ** attempt)
            logger.warning(
                f"Attempt {attempt + 1} failed, retrying in {wait_time}s: {e}"
            )
            await asyncio.sleep(wait_time)
    
    raise last_exception

def async_circuit_breaker(
    failure_threshold: int = 5,
    recovery_timeout: int = 60,
    expected_exception: type = Exception
):
    """Circuit breaker decorator for async functions."""
    def decorator(func: Callable[..., Awaitable[T]]) -> Callable[..., Awaitable[T]]:
        failure_count = 0
        last_failure_time = None
        is_open = False
        
        @wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            nonlocal failure_count, last_failure_time, is_open
            
            # Check if circuit should be closed
            if is_open and last_failure_time:
                if time.time() - last_failure_time > recovery_timeout:
                    is_open = False
                    failure_count = 0
                    logger.info(f"Circuit breaker closed for {func.__name__}")
                else:
                    raise Exception(f"Circuit breaker open for {func.__name__}")
            
            try:
                result = await func(*args, **kwargs)
                failure_count = 0  # Reset on success
                return result
            except expected_exception as e:
                failure_count += 1
                last_failure_time = time.time()
                
                if failure_count >= failure_threshold:
                    is_open = True
                    logger.error(f"Circuit breaker opened for {func.__name__}")
                
                raise e
        
        return wrapper
    return decorator

# Usage examples
@async_circuit_breaker(failure_threshold=3, recovery_timeout=30)
async def external_api_call(url: str) -> dict:
    """Call external API with circuit breaker."""
    async with aiohttp.ClientSession() as session:
        async with session.get(url, timeout=10) as response:
            if response.status != 200:
                raise aiohttp.ClientResponseError(
                    response.request_info,
                    response.history,
                    status=response.status
                )
            return await response.json()

async def resilient_api_call(url: str) -> dict:
    """Make resilient API call with retry and circuit breaker."""
    return await retry_async(
        lambda: external_api_call(url),
        max_retries=3,
        backoff_factor=0.5,
        exceptions=(aiohttp.ClientError, asyncio.TimeoutError)
    )

# Exception grouping for batch operations
async def process_urls_with_error_grouping(urls: list[str]) -> dict:
    """Process URLs with comprehensive error handling."""
    results = []
    errors = []
    
    async def process_single_url(url: str) -> dict:
        try:
            return await resilient_api_call(url)
        except Exception as e:
            error_info = {
                "url": url,
                "error": str(e),
                "type": type(e).__name__
            }
            errors.append(Exception(f"Failed to process {url}: {e}"))
            return error_info
    
    # Process all URLs concurrently
    tasks = [process_single_url(url) for url in urls]
    task_results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Separate successful results from errors
    for result in task_results:
        if isinstance(result, Exception):
            errors.append(result)
        else:
            results.append(result)
    
    # Raise exception group if there were errors
    if errors:
        if not results:
            raise ExceptionGroup("All URL processing failed", errors)
        else:
            # Partial success - you might want to handle this differently
            logger.warning(f"Partial success: {len(results)}/{len(urls)} URLs processed")
    
    return {
        "successful": results,
        "error_count": len(errors),
        "total_processed": len(results),
        "total_requested": len(urls)
    }
```

## Performance Optimization

### Async Connection Pooling
```python
import aiohttp
import asyncpg
import aioredis
from typing import Optional

class AsyncConnectionManager:
    """Manage async connection pools for web applications."""
    
    def __init__(self):
        self.http_session: Optional[aiohttp.ClientSession] = None
        self.db_pool: Optional[asyncpg.Pool] = None
        self.redis_pool: Optional[aioredis.Redis] = None
    
    async def initialize(self):
        """Initialize all connection pools."""
        # HTTP connection pool
        connector = aiohttp.TCPConnector(
            limit=100,  # Total connection pool size
            limit_per_host=30,  # Per-host connection limit
            ttl_dns_cache=300,  # DNS cache TTL
            use_dns_cache=True,
            keepalive_timeout=60
        )
        
        timeout = aiohttp.ClientTimeout(
            total=30,  # Total timeout
            connect=10,  # Connection timeout
            sock_read=20  # Socket read timeout
        )
        
        self.http_session = aiohttp.ClientSession(
            connector=connector,
            timeout=timeout
        )
        
        # Database connection pool
        self.db_pool = await asyncpg.create_pool(
            "postgresql://user:pass@localhost/db",
            min_size=5,  # Minimum pool size
            max_size=20,  # Maximum pool size
            max_queries=50000,  # Max queries per connection
            max_inactive_connection_lifetime=300,  # 5 minutes
            command_timeout=60
        )
        
        # Redis connection pool
        self.redis_pool = await aioredis.create_redis_pool(
            "redis://localhost",
            minsize=5,
            maxsize=20,
            encoding="utf-8"
        )
    
    async def close(self):
        """Close all connection pools."""
        if self.http_session:
            await self.http_session.close()
        
        if self.db_pool:
            await self.db_pool.close()
        
        if self.redis_pool:
            self.redis_pool.close()
            await self.redis_pool.wait_closed()
    
    async def http_request(
        self, 
        method: str, 
        url: str, 
        **kwargs
    ) -> aiohttp.ClientResponse:
        """Make HTTP request using connection pool."""
        return await self.http_session.request(method, url, **kwargs)
    
    async def db_execute(self, query: str, *args) -> Any:
        """Execute database query using connection pool."""
        async with self.db_pool.acquire() as conn:
            return await conn.execute(query, *args)
    
    async def db_fetch(self, query: str, *args) -> list:
        """Fetch database records using connection pool."""
        async with self.db_pool.acquire() as conn:
            return await conn.fetch(query, *args)
    
    async def cache_get(self, key: str) -> Optional[str]:
        """Get value from Redis cache."""
        return await self.redis_pool.get(key)
    
    async def cache_set(
        self, 
        key: str, 
        value: str, 
        expire: int = None
    ) -> bool:
        """Set value in Redis cache."""
        return await self.redis_pool.set(key, value, expire=expire)

# Global connection manager
connection_manager = AsyncConnectionManager()

# FastAPI lifespan with connection management
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan with connection pools."""
    # Startup
    await connection_manager.initialize()
    yield
    # Shutdown
    await connection_manager.close()

app = FastAPI(lifespan=lifespan)

# Dependency for connection manager
def get_connection_manager() -> AsyncConnectionManager:
    return connection_manager

@app.get("/optimized-endpoint")
async def optimized_endpoint(
    cm: AsyncConnectionManager = Depends(get_connection_manager)
):
    """Endpoint using optimized connection pools."""
    # Check cache first
    cached_data = await cm.cache_get("endpoint_data")
    if cached_data:
        return json.loads(cached_data)
    
    # Fetch from database and external API concurrently
    db_task = cm.db_fetch("SELECT * FROM data_table LIMIT 10")
    api_task = cm.http_request("GET", "https://api.example.com/data")
    
    db_results, api_response = await asyncio.gather(db_task, api_task)
    
    # Process results
    api_data = await api_response.json()
    combined_data = {
        "database": [dict(row) for row in db_results],
        "external": api_data
    }
    
    # Cache results for 5 minutes
    await cm.cache_set(
        "endpoint_data", 
        json.dumps(combined_data), 
        expire=300
    )
    
    return combined_data
```

### Async Caching Strategies
```python
import time
import hashlib
from typing import Any, Callable, Optional
from functools import wraps

class AsyncCache:
    """Async cache with TTL and LRU eviction."""
    
    def __init__(self, max_size: int = 1000, default_ttl: int = 300):
        self.max_size = max_size
        self.default_ttl = default_ttl
        self.cache: dict[str, dict] = {}
        self.access_order: list[str] = []
    
    def _generate_key(self, func_name: str, args: tuple, kwargs: dict) -> str:
        """Generate cache key from function and arguments."""
        key_data = f"{func_name}:{args}:{sorted(kwargs.items())}"
        return hashlib.md5(key_data.encode()).hexdigest()
    
    def _is_expired(self, entry: dict) -> bool:
        """Check if cache entry is expired."""
        return time.time() > entry["expires_at"]
    
    def _evict_lru(self):
        """Evict least recently used entry."""
        if self.access_order:
            lru_key = self.access_order.pop(0)
            self.cache.pop(lru_key, None)
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if key not in self.cache:
            return None
        
        entry = self.cache[key]
        if self._is_expired(entry):
            del self.cache[key]
            if key in self.access_order:
                self.access_order.remove(key)
            return None
        
        # Update access order
        if key in self.access_order:
            self.access_order.remove(key)
        self.access_order.append(key)
        
        return entry["value"]
    
    async def set(self, key: str, value: Any, ttl: int = None):
        """Set value in cache."""
        if len(self.cache) >= self.max_size:
            self._evict_lru()
        
        ttl = ttl or self.default_ttl
        self.cache[key] = {
            "value": value,
            "expires_at": time.time() + ttl,
            "created_at": time.time()
        }
        
        # Update access order
        if key in self.access_order:
            self.access_order.remove(key)
        self.access_order.append(key)
    
    async def invalidate(self, pattern: str = None):
        """Invalidate cache entries."""
        if pattern is None:
            self.cache.clear()
            self.access_order.clear()
        else:
            keys_to_remove = [
                key for key in self.cache.keys()
                if pattern in key
            ]
            for key in keys_to_remove:
                del self.cache[key]
                if key in self.access_order:
                    self.access_order.remove(key)

# Global cache instance
async_cache = AsyncCache(max_size=1000, default_ttl=300)

def async_cached(ttl: int = None):
    """Decorator for caching async function results."""
    def decorator(func: Callable[..., Awaitable[Any]]):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = async_cache._generate_key(
                func.__name__, args, kwargs
            )
            
            # Try to get from cache
            cached_result = await async_cache.get(cache_key)
            if cached_result is not None:
                return cached_result
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            await async_cache.set(cache_key, result, ttl)
            
            return result
        return wrapper
    return decorator

# Usage examples
@async_cached(ttl=600)  # Cache for 10 minutes
async def expensive_database_query(user_id: int) -> dict:
    """Expensive query that benefits from caching."""
    async with connection_manager.db_pool.acquire() as conn:
        result = await conn.fetchrow(
            """
            SELECT u.*, p.permissions, s.settings 
            FROM users u
            LEFT JOIN user_permissions p ON u.id = p.user_id
            LEFT JOIN user_settings s ON u.id = s.user_id
            WHERE u.id = $1
            """,
            user_id
        )
        return dict(result) if result else None

@async_cached(ttl=300)  # Cache for 5 minutes
async def fetch_external_data(api_endpoint: str) -> dict:
    """Cache external API responses."""
    async with connection_manager.http_session.get(api_endpoint) as response:
        return await response.json()

@app.get("/cached-user/{user_id}")
async def get_cached_user(user_id: int):
    """Endpoint using cached database query."""
    user_data = await expensive_database_query(user_id)
    if not user_data:
        raise HTTPException(404, "User not found")
    return user_data
```

## Best Practices and Patterns

### Production-Ready Async Patterns
```python
import signal
import logging
from contextlib import asynccontextmanager

class GracefulShutdown:
    """Handle graceful shutdown of async services."""
    
    def __init__(self):
        self.shutdown_event = asyncio.Event()
        self.tasks: set[asyncio.Task] = set()
    
    def setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown."""
        for sig in (signal.SIGTERM, signal.SIGINT):
            signal.signal(sig, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals."""
        logger.info(f"Received signal {signum}, initiating graceful shutdown")
        self.shutdown_event.set()
    
    def add_task(self, task: asyncio.Task):
        """Track a task for graceful shutdown."""
        self.tasks.add(task)
        task.add_done_callback(self.tasks.discard)
    
    async def wait_for_shutdown(self):
        """Wait for shutdown signal."""
        await self.shutdown_event.wait()
    
    async def shutdown_tasks(self, timeout: int = 30):
        """Shutdown all tracked tasks."""
        if not self.tasks:
            return
        
        logger.info(f"Shutting down {len(self.tasks)} tasks")
        
        # Cancel all tasks
        for task in self.tasks:
            task.cancel()
        
        # Wait for tasks to complete or timeout
        try:
            await asyncio.wait_for(
                asyncio.gather(*self.tasks, return_exceptions=True),
                timeout=timeout
            )
        except asyncio.TimeoutError:
            logger.warning(f"Some tasks didn't shutdown within {timeout}s")

# Global shutdown manager
shutdown_manager = GracefulShutdown()

# Comprehensive async application pattern
class AsyncWebApplication:
    """Complete async web application with all best practices."""
    
    def __init__(self):
        self.app = FastAPI()
        self.connection_manager = AsyncConnectionManager()
        self.task_manager = AsyncTaskManager()
        self.processor = AsyncProducerConsumer()
        self.shutdown_manager = GracefulShutdown()
    
    async def startup(self):
        """Application startup sequence."""
        logger.info("Starting async web application")
        
        # Initialize connection pools
        await self.connection_manager.initialize()
        
        # Start background processors
        await self.processor.start_consumers(num_consumers=3)
        
        # Setup signal handlers
        self.shutdown_manager.setup_signal_handlers()
        
        # Start health check task
        health_task = asyncio.create_task(self._health_check_loop())
        self.shutdown_manager.add_task(health_task)
        
        logger.info("Application startup complete")
    
    async def shutdown(self):
        """Application shutdown sequence."""
        logger.info("Starting application shutdown")
        
        # Stop accepting new tasks
        await self.processor.stop_consumers()
        
        # Wait for existing tasks to complete
        await self.task_manager.wait_for_all_tasks()
        
        # Shutdown connection pools
        await self.connection_manager.close()
        
        # Shutdown tracked tasks
        await self.shutdown_manager.shutdown_tasks()
        
        logger.info("Application shutdown complete")
    
    async def _health_check_loop(self):
        """Background health check task."""
        while not self.shutdown_manager.shutdown_event.is_set():
            try:
                # Perform health checks
                await self._check_database_health()
                await self._check_redis_health()
                await self._check_external_services()
                
                # Wait before next check
                await asyncio.sleep(30)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Health check failed: {e}")
                await asyncio.sleep(10)  # Shorter interval on errors
    
    async def _check_database_health(self):
        """Check database connectivity."""
        async with self.connection_manager.db_pool.acquire() as conn:
            await conn.execute("SELECT 1")
    
    async def _check_redis_health(self):
        """Check Redis connectivity."""
        await self.connection_manager.redis_pool.ping()
    
    async def _check_external_services(self):
        """Check external service health."""
        response = await self.connection_manager.http_request(
            "GET", 
            "https://api.example.com/health"
        )
        if response.status != 200:
            raise Exception("External service unhealthy")

# Application instance
web_app = AsyncWebApplication()

# FastAPI lifespan management
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Complete application lifespan management."""
    try:
        await web_app.startup()
        yield
    finally:
        await web_app.shutdown()

app = FastAPI(lifespan=lifespan)

# Health check endpoint
@app.get("/health")
async def health_check():
    """Application health check endpoint."""
    try:
        # Quick health checks
        await web_app.connection_manager.db_execute("SELECT 1")
        await web_app.connection_manager.cache_get("health_check")
        
        return {
            "status": "healthy",
            "timestamp": time.time(),
            "services": {
                "database": "ok",
                "cache": "ok",
                "task_queue": "ok"
            }
        }
    except Exception as e:
        raise HTTPException(503, f"Service unhealthy: {e}")
```

## Testing Async Code

### Async Testing Patterns
```python
import pytest
import pytest_asyncio
from httpx import AsyncClient
from unittest.mock import AsyncMock, patch

# Async test fixtures
@pytest_asyncio.fixture
async def async_client():
    """Async test client for FastAPI."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest_asyncio.fixture
async def mock_database():
    """Mock database for testing."""
    mock_pool = AsyncMock()
    mock_conn = AsyncMock()
    mock_pool.acquire.return_value.__aenter__.return_value = mock_conn
    return mock_pool, mock_conn

# Test async endpoints
@pytest.mark.asyncio
async def test_async_endpoint(async_client: AsyncClient):
    """Test async endpoint."""
    response = await async_client.get("/users/1")
    assert response.status_code == 200
    assert "id" in response.json()

@pytest.mark.asyncio
async def test_concurrent_processing():
    """Test concurrent task processing."""
    async def mock_task(item: int) -> int:
        await asyncio.sleep(0.1)
        return item * 2
    
    items = list(range(10))
    tasks = [mock_task(item) for item in items]
    
    start_time = time.time()
    results = await asyncio.gather(*tasks)
    end_time = time.time()
    
    # Should complete in about 0.1 seconds (concurrent)
    assert end_time - start_time < 0.2
    assert results == [item * 2 for item in items]

@pytest.mark.asyncio
async def test_error_handling():
    """Test async error handling."""
    async def failing_task():
        await asyncio.sleep(0.1)
        raise ValueError("Test error")
    
    with pytest.raises(ValueError, match="Test error"):
        await failing_task()

@pytest.mark.asyncio
async def test_retry_logic():
    """Test retry logic."""
    call_count = 0
    
    async def flaky_function():
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise ConnectionError("Temporary failure")
        return "success"
    
    result = await retry_async(
        flaky_function, 
        max_retries=3, 
        backoff_factor=0.01
    )
    
    assert result == "success"
    assert call_count == 3

# Mock async dependencies
@pytest.mark.asyncio
async def test_with_mocked_dependencies(mock_database):
    """Test with mocked async dependencies."""
    mock_pool, mock_conn = mock_database
    
    # Setup mock return values
    mock_conn.fetchrow.return_value = {
        "id": 1, "name": "Test User", "email": "test@example.com"
    }
    
    with patch.object(connection_manager, 'db_pool', mock_pool):
        user = await expensive_database_query(1)
        assert user["name"] == "Test User"
        mock_conn.fetchrow.assert_called_once()
```

---

**Last Updated:** Based on Python 3.10+ async/await features and FastAPI best practices
**References:**
- [Python asyncio Documentation](https://docs.python.org/3/library/asyncio.html)
- [FastAPI Async Documentation](https://fastapi.tiangolo.com/async/)
- [aiohttp Documentation](https://docs.aiohttp.org/)
- [asyncpg Documentation](https://magicstack.github.io/asyncpg/)
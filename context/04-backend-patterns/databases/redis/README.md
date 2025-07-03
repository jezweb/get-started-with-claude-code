# Redis Patterns & Best Practices

Comprehensive guide to using Redis for caching, sessions, real-time features, and high-performance data structures in modern applications.

## 🎯 What is Redis?

Redis (Remote Dictionary Server) is an in-memory data structure store used as:
- **Cache** - High-speed data caching
- **Session Store** - User session management
- **Message Broker** - Pub/Sub messaging
- **Database** - NoSQL key-value database
- **Real-time Analytics** - Counters, leaderboards, analytics

## ✅ When to Use Redis

### Perfect For:
- **Caching** - Frequently accessed data, API responses
- **Session Management** - User sessions, temporary data
- **Rate Limiting** - API throttling, request limiting
- **Real-time Features** - Chat, notifications, live updates
- **Queues** - Background job processing
- **Analytics** - Counters, metrics, leaderboards
- **Pub/Sub** - Real-time messaging, event streaming

### Consider Alternatives For:
- **Complex Queries** - Use PostgreSQL for relational data
- **Large Data Sets** - Redis is memory-bound
- **ACID Transactions** - Use traditional databases
- **Long-term Storage** - Redis is best for temporary/cached data

## 🚀 Setup & Configuration

### Docker Development Setup
```yaml
# docker-compose.yml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    
  redis-commander:
    image: rediscommander/redis-commander:latest
    environment:
      - REDIS_HOSTS=local:redis:6379
    ports:
      - "8081:8081"
    depends_on:
      - redis

volumes:
  redis_data:
```

### Redis Configuration
```conf
# redis.conf
# Memory optimization
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence (choose based on needs)
save 900 1      # Save if at least 1 key changed in 900 seconds
save 300 10     # Save if at least 10 keys changed in 300 seconds
save 60 10000   # Save if at least 10000 keys changed in 60 seconds

# AOF persistence for durability
appendonly yes
appendfsync everysec

# Security
requirepass your_redis_password
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""

# Network
bind 0.0.0.0
protected-mode yes
port 6379

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log
```

### Python Redis Setup
```python
# redis_client.py
import redis
import json
import pickle
from typing import Any, Optional, Union, Dict, List
from functools import wraps
import logging
import time

logger = logging.getLogger(__name__)

class RedisClient:
    def __init__(self, 
                 host: str = 'localhost', 
                 port: int = 6379, 
                 db: int = 0,
                 password: Optional[str] = None,
                 decode_responses: bool = True,
                 max_connections: int = 50):
        
        # Connection pool for efficiency
        self.pool = redis.ConnectionPool(
            host=host,
            port=port,
            db=db,
            password=password,
            decode_responses=decode_responses,
            max_connections=max_connections,
            socket_connect_timeout=5,
            socket_timeout=5,
            retry_on_timeout=True
        )
        
        self.redis = redis.Redis(connection_pool=self.pool)
        
        # Test connection
        try:
            self.redis.ping()
            logger.info("Redis connection established")
        except redis.ConnectionError as e:
            logger.error(f"Redis connection failed: {e}")
            raise

    def get(self, key: str, default: Any = None) -> Any:
        """Get value with automatic JSON deserialization."""
        try:
            value = self.redis.get(key)
            if value is None:
                return default
            
            # Try to deserialize JSON
            try:
                return json.loads(value)
            except (json.JSONDecodeError, TypeError):
                return value
        except redis.RedisError as e:
            logger.error(f"Redis GET error for key {key}: {e}")
            return default

    def set(self, 
            key: str, 
            value: Any, 
            ex: Optional[int] = None,
            px: Optional[int] = None,
            nx: bool = False,
            xx: bool = False) -> bool:
        """Set value with automatic JSON serialization."""
        try:
            # Serialize complex objects
            if isinstance(value, (dict, list, tuple)):
                value = json.dumps(value)
            
            return self.redis.set(key, value, ex=ex, px=px, nx=nx, xx=xx)
        except redis.RedisError as e:
            logger.error(f"Redis SET error for key {key}: {e}")
            return False

    def delete(self, *keys: str) -> int:
        """Delete one or more keys."""
        try:
            return self.redis.delete(*keys)
        except redis.RedisError as e:
            logger.error(f"Redis DELETE error: {e}")
            return 0

    def exists(self, key: str) -> bool:
        """Check if key exists."""
        try:
            return bool(self.redis.exists(key))
        except redis.RedisError as e:
            logger.error(f"Redis EXISTS error for key {key}: {e}")
            return False

    def expire(self, key: str, seconds: int) -> bool:
        """Set expiration time for key."""
        try:
            return self.redis.expire(key, seconds)
        except redis.RedisError as e:
            logger.error(f"Redis EXPIRE error for key {key}: {e}")
            return False

    def ttl(self, key: str) -> int:
        """Get time to live for key."""
        try:
            return self.redis.ttl(key)
        except redis.RedisError as e:
            logger.error(f"Redis TTL error for key {key}: {e}")
            return -2

    def keys(self, pattern: str = "*") -> List[str]:
        """Get keys matching pattern (use carefully in production)."""
        try:
            return self.redis.keys(pattern)
        except redis.RedisError as e:
            logger.error(f"Redis KEYS error: {e}")
            return []

    def pipeline(self):
        """Create Redis pipeline for batch operations."""
        return self.redis.pipeline()

    def health_check(self) -> Dict[str, Any]:
        """Check Redis health and get basic info."""
        try:
            info = self.redis.info()
            return {
                'status': 'healthy',
                'version': info.get('redis_version'),
                'memory_usage': info.get('used_memory_human'),
                'connected_clients': info.get('connected_clients'),
                'total_commands_processed': info.get('total_commands_processed'),
                'uptime_seconds': info.get('uptime_in_seconds')
            }
        except redis.RedisError as e:
            return {
                'status': 'unhealthy',
                'error': str(e)
            }

# Global Redis client instance
redis_client = RedisClient()
```

## 💾 Caching Patterns

### Basic Caching Service
```python
# cache_service.py
import hashlib
from typing import Any, Optional, Callable
from functools import wraps
import time

class CacheService:
    def __init__(self, redis_client: RedisClient, default_ttl: int = 3600):
        self.redis = redis_client
        self.default_ttl = default_ttl

    def cache_key(self, *args, prefix: str = "") -> str:
        """Generate consistent cache key from arguments."""
        key_parts = [str(arg) for arg in args if arg is not None]
        key_string = ":".join(key_parts)
        
        # Hash long keys to avoid Redis key length limits
        if len(key_string) > 200:
            key_string = hashlib.md5(key_string.encode()).hexdigest()
        
        return f"{prefix}:{key_string}" if prefix else key_string

    def get_or_set(self, 
                   key: str, 
                   fetch_func: Callable, 
                   ttl: Optional[int] = None) -> Any:
        """Get from cache or compute and cache the result."""
        # Try to get from cache first
        cached_value = self.redis.get(key)
        if cached_value is not None:
            return cached_value

        # Cache miss - compute value
        value = fetch_func()
        
        # Cache the result
        if value is not None:
            self.redis.set(key, value, ex=ttl or self.default_ttl)
        
        return value

    def invalidate_pattern(self, pattern: str) -> int:
        """Invalidate all keys matching pattern."""
        keys = self.redis.keys(pattern)
        if keys:
            return self.redis.delete(*keys)
        return 0

    def tag_cache(self, key: str, tags: List[str], value: Any, ttl: Optional[int] = None):
        """Cache with tags for group invalidation."""
        # Store the actual data
        self.redis.set(key, value, ex=ttl or self.default_ttl)
        
        # Store tag relationships
        for tag in tags:
            tag_key = f"tag:{tag}"
            self.redis.sadd(tag_key, key)
            self.redis.expire(tag_key, (ttl or self.default_ttl) + 60)  # Slightly longer TTL

    def invalidate_by_tag(self, tag: str) -> int:
        """Invalidate all cached items with specific tag."""
        tag_key = f"tag:{tag}"
        keys = self.redis.smembers(tag_key)
        
        if keys:
            # Delete cached data
            deleted = self.redis.delete(*keys)
            # Clean up tag
            self.redis.delete(tag_key)
            return deleted
        return 0

# Caching decorators
def cached(ttl: int = 3600, key_prefix: str = "", tags: Optional[List[str]] = None):
    """Decorator to cache function results."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_service = CacheService(redis_client)
            
            # Generate cache key
            key_parts = [func.__name__] + list(args) + [f"{k}={v}" for k, v in sorted(kwargs.items())]
            cache_key = cache_service.cache_key(*key_parts, prefix=key_prefix)
            
            def fetch_data():
                return func(*args, **kwargs)
            
            if tags:
                # Check if cached value exists
                cached_value = redis_client.get(cache_key)
                if cached_value is not None:
                    return cached_value
                
                # Compute and cache with tags
                result = fetch_data()
                cache_service.tag_cache(cache_key, tags, result, ttl)
                return result
            else:
                # Simple caching
                return cache_service.get_or_set(cache_key, fetch_data, ttl)
        
        return wrapper
    return decorator

# Usage examples
@cached(ttl=1800, key_prefix="user", tags=["users"])
def get_user_profile(user_id: str):
    # Expensive database operation
    return fetch_user_from_database(user_id)

@cached(ttl=300, key_prefix="api")
def get_weather_data(city: str):
    # External API call
    return fetch_weather_from_api(city)
```

### Advanced Caching Strategies
```python
# advanced_cache.py
import time
import random
from enum import Enum
from typing import Optional, Any, Dict, List

class CacheStrategy(Enum):
    LRU = "lru"
    LFU = "lfu"
    WRITE_THROUGH = "write_through"
    WRITE_BEHIND = "write_behind"
    REFRESH_AHEAD = "refresh_ahead"

class AdvancedCache:
    def __init__(self, redis_client: RedisClient):
        self.redis = redis_client

    def cache_aside(self, key: str, fetch_func: Callable, ttl: int = 3600) -> Any:
        """Cache-aside pattern (lazy loading)."""
        value = self.redis.get(key)
        if value is None:
            value = fetch_func()
            if value is not None:
                self.redis.set(key, value, ex=ttl)
        return value

    def write_through(self, key: str, value: Any, write_func: Callable, ttl: int = 3600) -> bool:
        """Write-through pattern - write to cache and storage simultaneously."""
        try:
            # Write to primary storage first
            write_func(value)
            
            # Then update cache
            return self.redis.set(key, value, ex=ttl)
        except Exception as e:
            # If storage write fails, don't cache
            logger.error(f"Write-through failed for key {key}: {e}")
            return False

    def write_behind(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Write-behind pattern - write to cache immediately, storage asynchronously."""
        # Write to cache immediately
        cache_success = self.redis.set(key, value, ex=ttl)
        
        # Queue for async write to storage
        write_queue_key = "write_queue"
        write_task = {
            'key': key,
            'value': value,
            'timestamp': time.time()
        }
        self.redis.lpush(write_queue_key, json.dumps(write_task))
        
        return cache_success

    def refresh_ahead(self, key: str, fetch_func: Callable, ttl: int = 3600, refresh_threshold: float = 0.8) -> Any:
        """Refresh-ahead pattern - refresh cache before expiration."""
        value = self.redis.get(key)
        key_ttl = self.redis.ttl(key)
        
        # If key doesn't exist, fetch and cache
        if value is None:
            value = fetch_func()
            if value is not None:
                self.redis.set(key, value, ex=ttl)
            return value
        
        # If TTL is below threshold, refresh asynchronously
        if key_ttl > 0 and key_ttl < (ttl * refresh_threshold):
            # Queue refresh task
            refresh_queue_key = "refresh_queue"
            refresh_task = {
                'key': key,
                'fetch_func_name': fetch_func.__name__,
                'ttl': ttl,
                'timestamp': time.time()
            }
            self.redis.lpush(refresh_queue_key, json.dumps(refresh_task))
        
        return value

    def multi_level_cache(self, 
                          l1_key: str, 
                          l2_key: str, 
                          fetch_func: Callable,
                          l1_ttl: int = 300,
                          l2_ttl: int = 3600) -> Any:
        """Multi-level caching (L1: short TTL, L2: long TTL)."""
        # Try L1 cache first (hot data)
        value = self.redis.get(l1_key)
        if value is not None:
            return value
        
        # Try L2 cache (warm data)
        value = self.redis.get(l2_key)
        if value is not None:
            # Promote to L1
            self.redis.set(l1_key, value, ex=l1_ttl)
            return value
        
        # Cache miss - fetch from source
        value = fetch_func()
        if value is not None:
            # Store in both levels
            pipeline = self.redis.pipeline()
            pipeline.set(l1_key, value, ex=l1_ttl)
            pipeline.set(l2_key, value, ex=l2_ttl)
            pipeline.execute()
        
        return value

    def circuit_breaker_cache(self, 
                              key: str, 
                              fetch_func: Callable,
                              ttl: int = 3600,
                              failure_threshold: int = 5,
                              recovery_timeout: int = 60) -> Any:
        """Circuit breaker pattern with cache fallback."""
        circuit_key = f"circuit:{fetch_func.__name__}"
        failure_count_key = f"failures:{fetch_func.__name__}"
        
        # Check if circuit is open
        circuit_state = self.redis.get(circuit_key)
        if circuit_state == "open":
            # Return cached value if available
            cached_value = self.redis.get(key)
            if cached_value is not None:
                return cached_value
            raise Exception("Circuit breaker open and no cached data available")
        
        try:
            # Try to fetch fresh data
            value = fetch_func()
            
            # Success - reset failure count and cache result
            self.redis.delete(failure_count_key)
            if value is not None:
                self.redis.set(key, value, ex=ttl)
            
            return value
            
        except Exception as e:
            # Increment failure count
            failure_count = self.redis.incr(failure_count_key)
            self.redis.expire(failure_count_key, recovery_timeout)
            
            # Open circuit if threshold reached
            if failure_count >= failure_threshold:
                self.redis.set(circuit_key, "open", ex=recovery_timeout)
            
            # Try to return cached value
            cached_value = self.redis.get(key)
            if cached_value is not None:
                return cached_value
            
            # No cached data available
            raise e
```

## 🔐 Session Management

### Session Service
```python
# session_service.py
import uuid
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

class SessionService:
    def __init__(self, redis_client: RedisClient, default_ttl: int = 86400):  # 24 hours
        self.redis = redis_client
        self.default_ttl = default_ttl
        self.session_prefix = "session:"

    def create_session(self, user_id: str, user_data: Dict[str, Any], ttl: Optional[int] = None) -> str:
        """Create a new session and return session ID."""
        session_id = str(uuid.uuid4())
        session_key = f"{self.session_prefix}{session_id}"
        
        session_data = {
            'user_id': user_id,
            'user_data': user_data,
            'created_at': datetime.utcnow().isoformat(),
            'last_accessed': datetime.utcnow().isoformat(),
            'ip_address': None,  # Set from request context
            'user_agent': None   # Set from request context
        }
        
        self.redis.set(session_key, session_data, ex=ttl or self.default_ttl)
        
        # Track user sessions for management
        user_sessions_key = f"user_sessions:{user_id}"
        self.redis.sadd(user_sessions_key, session_id)
        self.redis.expire(user_sessions_key, ttl or self.default_ttl)
        
        return session_id

    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session data and update last accessed time."""
        session_key = f"{self.session_prefix}{session_id}"
        session_data = self.redis.get(session_key)
        
        if session_data:
            # Update last accessed time
            session_data['last_accessed'] = datetime.utcnow().isoformat()
            self.redis.set(session_key, session_data, ex=self.redis.ttl(session_key))
            return session_data
        
        return None

    def update_session(self, session_id: str, updates: Dict[str, Any]) -> bool:
        """Update session data."""
        session_key = f"{self.session_prefix}{session_id}"
        session_data = self.redis.get(session_key)
        
        if session_data:
            session_data.update(updates)
            session_data['last_accessed'] = datetime.utcnow().isoformat()
            return self.redis.set(session_key, session_data, ex=self.redis.ttl(session_key))
        
        return False

    def delete_session(self, session_id: str) -> bool:
        """Delete a specific session."""
        session_key = f"{self.session_prefix}{session_id}"
        
        # Get session to find user_id for cleanup
        session_data = self.redis.get(session_key)
        if session_data and 'user_id' in session_data:
            user_sessions_key = f"user_sessions:{session_data['user_id']}"
            self.redis.srem(user_sessions_key, session_id)
        
        return bool(self.redis.delete(session_key))

    def delete_user_sessions(self, user_id: str) -> int:
        """Delete all sessions for a specific user."""
        user_sessions_key = f"user_sessions:{user_id}"
        session_ids = self.redis.smembers(user_sessions_key)
        
        if session_ids:
            # Delete all session keys
            session_keys = [f"{self.session_prefix}{sid}" for sid in session_ids]
            deleted = self.redis.delete(*session_keys)
            
            # Clean up user sessions set
            self.redis.delete(user_sessions_key)
            
            return deleted
        
        return 0

    def extend_session(self, session_id: str, additional_ttl: int = None) -> bool:
        """Extend session expiration time."""
        session_key = f"{self.session_prefix}{session_id}"
        return self.redis.expire(session_key, additional_ttl or self.default_ttl)

    def get_active_sessions(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all active sessions for a user."""
        user_sessions_key = f"user_sessions:{user_id}"
        session_ids = self.redis.smembers(user_sessions_key)
        
        sessions = []
        for session_id in session_ids:
            session_data = self.get_session(session_id)
            if session_data:
                session_data['session_id'] = session_id
                sessions.append(session_data)
        
        return sessions

    def cleanup_expired_sessions(self) -> int:
        """Clean up expired sessions (run periodically)."""
        # This is a simplified version - in production, use Redis key expiration
        pattern = f"{self.session_prefix}*"
        session_keys = self.redis.keys(pattern)
        
        expired_count = 0
        for key in session_keys:
            if self.redis.ttl(key) <= 0:
                self.redis.delete(key)
                expired_count += 1
        
        return expired_count
```

### Flask Session Integration
```python
# flask_session.py
from flask import Flask, request, session, g
from functools import wraps

app = Flask(__name__)
session_service = SessionService(redis_client)

def login_required(f):
    """Decorator to require authentication."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        session_id = request.headers.get('X-Session-ID') or request.cookies.get('session_id')
        
        if not session_id:
            return {'error': 'Authentication required'}, 401
        
        session_data = session_service.get_session(session_id)
        if not session_data:
            return {'error': 'Invalid or expired session'}, 401
        
        # Store session data in Flask's g object
        g.session_data = session_data
        g.user_id = session_data['user_id']
        
        return f(*args, **kwargs)
    
    return decorated_function

@app.route('/login', methods=['POST'])
def login():
    """User login endpoint."""
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    # Authenticate user (implement your auth logic)
    user = authenticate_user(email, password)
    if not user:
        return {'error': 'Invalid credentials'}, 401
    
    # Create session
    session_id = session_service.create_session(
        user_id=user['id'],
        user_data={
            'email': user['email'],
            'name': user['name'],
            'role': user['role']
        }
    )
    
    response = {
        'session_id': session_id,
        'user': user
    }
    
    # Set cookie (optional)
    resp = app.response_class(
        response=json.dumps(response),
        status=200,
        mimetype='application/json'
    )
    resp.set_cookie('session_id', session_id, httponly=True, secure=True)
    
    return resp

@app.route('/logout', methods=['POST'])
@login_required
def logout():
    """User logout endpoint."""
    session_id = request.headers.get('X-Session-ID') or request.cookies.get('session_id')
    session_service.delete_session(session_id)
    
    resp = app.response_class(
        response=json.dumps({'message': 'Logged out successfully'}),
        status=200,
        mimetype='application/json'
    )
    resp.set_cookie('session_id', '', expires=0)
    
    return resp

@app.route('/profile')
@login_required
def get_profile():
    """Get user profile (requires authentication)."""
    return {
        'user': g.session_data['user_data'],
        'session_info': {
            'created_at': g.session_data['created_at'],
            'last_accessed': g.session_data['last_accessed']
        }
    }
```

## 🚦 Rate Limiting

### Rate Limiter Service
```python
# rate_limiter.py
import time
from typing import Optional, Tuple
from enum import Enum

class RateLimitStrategy(Enum):
    FIXED_WINDOW = "fixed_window"
    SLIDING_WINDOW = "sliding_window"
    TOKEN_BUCKET = "token_bucket"
    LEAKY_BUCKET = "leaky_bucket"

class RateLimiter:
    def __init__(self, redis_client: RedisClient):
        self.redis = redis_client

    def fixed_window(self, 
                     key: str, 
                     limit: int, 
                     window_seconds: int,
                     identifier: Optional[str] = None) -> Tuple[bool, Dict[str, Any]]:
        """Fixed window rate limiting."""
        current_time = int(time.time())
        window_start = current_time - (current_time % window_seconds)
        
        rate_key = f"rate_limit:fixed:{key}:{window_start}"
        if identifier:
            rate_key = f"{rate_key}:{identifier}"
        
        pipeline = self.redis.pipeline()
        pipeline.incr(rate_key)
        pipeline.expire(rate_key, window_seconds)
        results = pipeline.execute()
        
        current_count = results[0]
        allowed = current_count <= limit
        
        return allowed, {
            'allowed': allowed,
            'count': current_count,
            'limit': limit,
            'window_seconds': window_seconds,
            'reset_time': window_start + window_seconds
        }

    def sliding_window(self,
                       key: str,
                       limit: int,
                       window_seconds: int,
                       identifier: Optional[str] = None) -> Tuple[bool, Dict[str, Any]]:
        """Sliding window rate limiting using sorted sets."""
        current_time = time.time()
        rate_key = f"rate_limit:sliding:{key}"
        if identifier:
            rate_key = f"{rate_key}:{identifier}"
        
        pipeline = self.redis.pipeline()
        
        # Remove old entries outside the window
        pipeline.zremrangebyscore(rate_key, 0, current_time - window_seconds)
        
        # Count current entries
        pipeline.zcard(rate_key)
        
        # Add current request
        pipeline.zadd(rate_key, {str(current_time): current_time})
        
        # Set expiration
        pipeline.expire(rate_key, window_seconds)
        
        results = pipeline.execute()
        current_count = results[1] + 1  # +1 for the current request
        
        allowed = current_count <= limit
        
        if not allowed:
            # Remove the request we just added
            self.redis.zrem(rate_key, str(current_time))
        
        return allowed, {
            'allowed': allowed,
            'count': current_count,
            'limit': limit,
            'window_seconds': window_seconds,
            'oldest_request': current_time - window_seconds
        }

    def token_bucket(self,
                     key: str,
                     capacity: int,
                     refill_rate: float,
                     tokens_requested: int = 1,
                     identifier: Optional[str] = None) -> Tuple[bool, Dict[str, Any]]:
        """Token bucket rate limiting."""
        rate_key = f"rate_limit:token:{key}"
        if identifier:
            rate_key = f"{rate_key}:{identifier}"
        
        current_time = time.time()
        
        # Get current bucket state
        bucket_data = self.redis.hmget(rate_key, ['tokens', 'last_refill'])
        tokens = float(bucket_data[0]) if bucket_data[0] else capacity
        last_refill = float(bucket_data[1]) if bucket_data[1] else current_time
        
        # Calculate tokens to add based on time passed
        time_passed = current_time - last_refill
        tokens_to_add = time_passed * refill_rate
        tokens = min(capacity, tokens + tokens_to_add)
        
        allowed = tokens >= tokens_requested
        
        if allowed:
            tokens -= tokens_requested
        
        # Update bucket state
        pipeline = self.redis.pipeline()
        pipeline.hmset(rate_key, {
            'tokens': tokens,
            'last_refill': current_time
        })
        pipeline.expire(rate_key, int(capacity / refill_rate) + 60)  # Cleanup after inactivity
        pipeline.execute()
        
        return allowed, {
            'allowed': allowed,
            'tokens_remaining': tokens,
            'capacity': capacity,
            'refill_rate': refill_rate,
            'tokens_requested': tokens_requested
        }

    def check_rate_limit(self,
                         key: str,
                         strategy: RateLimitStrategy,
                         **kwargs) -> Tuple[bool, Dict[str, Any]]:
        """Generic rate limit checker."""
        if strategy == RateLimitStrategy.FIXED_WINDOW:
            return self.fixed_window(key, **kwargs)
        elif strategy == RateLimitStrategy.SLIDING_WINDOW:
            return self.sliding_window(key, **kwargs)
        elif strategy == RateLimitStrategy.TOKEN_BUCKET:
            return self.token_bucket(key, **kwargs)
        else:
            raise ValueError(f"Unsupported rate limit strategy: {strategy}")

# Rate limiting decorators
def rate_limit(strategy: RateLimitStrategy, key_func: Callable, **limit_kwargs):
    """Decorator for rate limiting functions."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            rate_limiter = RateLimiter(redis_client)
            
            # Generate rate limit key
            rate_key = key_func(*args, **kwargs)
            
            # Check rate limit
            allowed, info = rate_limiter.check_rate_limit(rate_key, strategy, **limit_kwargs)
            
            if not allowed:
                raise Exception(f"Rate limit exceeded: {info}")
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator

# Usage examples
def user_rate_key(user_id: str, *args, **kwargs) -> str:
    return f"user:{user_id}"

def ip_rate_key(request, *args, **kwargs) -> str:
    return f"ip:{request.remote_addr}"

@rate_limit(
    strategy=RateLimitStrategy.SLIDING_WINDOW,
    key_func=user_rate_key,
    limit=100,
    window_seconds=3600
)
def api_endpoint(user_id: str):
    # API logic here
    pass
```

## 📊 Real-time Analytics & Counters

### Analytics Service
```python
# analytics.py
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

class AnalyticsService:
    def __init__(self, redis_client: RedisClient):
        self.redis = redis_client

    def increment_counter(self, metric: str, value: int = 1, tags: Optional[Dict[str, str]] = None):
        """Increment a counter with optional tags."""
        # Basic counter
        counter_key = f"counter:{metric}"
        self.redis.incr(counter_key, value)
        
        # Time-based counters
        now = datetime.utcnow()
        time_keys = [
            f"counter:{metric}:hourly:{now.strftime('%Y%m%d%H')}",
            f"counter:{metric}:daily:{now.strftime('%Y%m%d')}",
            f"counter:{metric}:monthly:{now.strftime('%Y%m')}"
        ]
        
        pipeline = self.redis.pipeline()
        for key in time_keys:
            pipeline.incr(key, value)
            # Set expiration based on granularity
            if 'hourly' in key:
                pipeline.expire(key, 86400 * 7)  # 7 days
            elif 'daily' in key:
                pipeline.expire(key, 86400 * 90)  # 90 days
            elif 'monthly' in key:
                pipeline.expire(key, 86400 * 365)  # 1 year
        
        # Tagged counters
        if tags:
            for tag_key, tag_value in tags.items():
                tagged_key = f"counter:{metric}:tag:{tag_key}:{tag_value}"
                pipeline.incr(tagged_key, value)
                pipeline.expire(tagged_key, 86400 * 30)  # 30 days
        
        pipeline.execute()

    def get_counter(self, metric: str, time_range: Optional[str] = None) -> int:
        """Get counter value."""
        if time_range:
            key = f"counter:{metric}:{time_range}"
        else:
            key = f"counter:{metric}"
        
        value = self.redis.get(key)
        return int(value) if value else 0

    def get_counter_range(self, metric: str, start_date: datetime, end_date: datetime, granularity: str = 'daily') -> Dict[str, int]:
        """Get counter values for a date range."""
        results = {}
        current_date = start_date
        
        while current_date <= end_date:
            if granularity == 'hourly':
                key = f"counter:{metric}:hourly:{current_date.strftime('%Y%m%d%H')}"
                current_date += timedelta(hours=1)
            elif granularity == 'daily':
                key = f"counter:{metric}:daily:{current_date.strftime('%Y%m%d')}"
                current_date += timedelta(days=1)
            elif granularity == 'monthly':
                key = f"counter:{metric}:monthly:{current_date.strftime('%Y%m')}"
                # Move to next month
                if current_date.month == 12:
                    current_date = current_date.replace(year=current_date.year + 1, month=1)
                else:
                    current_date = current_date.replace(month=current_date.month + 1)
            
            value = self.redis.get(key)
            results[key] = int(value) if value else 0
        
        return results

    def track_event(self, event: str, user_id: str, properties: Optional[Dict[str, Any]] = None):
        """Track an event with properties."""
        timestamp = time.time()
        
        event_data = {
            'event': event,
            'user_id': user_id,
            'timestamp': timestamp,
            'properties': properties or {}
        }
        
        # Store in event stream
        stream_key = f"events:{event}"
        self.redis.xadd(stream_key, event_data)
        
        # Set stream expiration
        self.redis.expire(stream_key, 86400 * 30)  # 30 days
        
        # Update counters
        self.increment_counter(f"event:{event}")
        self.increment_counter(f"event:{event}:user", tags={'user_id': user_id})

    def create_leaderboard(self, name: str, score_updates: Dict[str, float]):
        """Update leaderboard scores."""
        leaderboard_key = f"leaderboard:{name}"
        
        # Update scores using sorted set
        self.redis.zadd(leaderboard_key, score_updates)
        
        # Set expiration
        self.redis.expire(leaderboard_key, 86400 * 30)  # 30 days

    def get_leaderboard(self, name: str, start: int = 0, end: int = 9, reverse: bool = True) -> List[Dict[str, Any]]:
        """Get leaderboard rankings."""
        leaderboard_key = f"leaderboard:{name}"
        
        if reverse:
            # Get top scores (highest first)
            results = self.redis.zrevrange(leaderboard_key, start, end, withscores=True)
        else:
            # Get bottom scores (lowest first)
            results = self.redis.zrange(leaderboard_key, start, end, withscores=True)
        
        leaderboard = []
        for i, (member, score) in enumerate(results):
            leaderboard.append({
                'rank': start + i + 1,
                'member': member,
                'score': score
            })
        
        return leaderboard

    def get_member_rank(self, leaderboard_name: str, member: str) -> Optional[int]:
        """Get specific member's rank in leaderboard."""
        leaderboard_key = f"leaderboard:{leaderboard_name}"
        rank = self.redis.zrevrank(leaderboard_key, member)
        return rank + 1 if rank is not None else None

    def time_series_add(self, metric: str, value: float, timestamp: Optional[float] = None):
        """Add value to time series (using sorted sets)."""
        if timestamp is None:
            timestamp = time.time()
        
        ts_key = f"timeseries:{metric}"
        self.redis.zadd(ts_key, {timestamp: value})
        
        # Keep only last 24 hours of data
        cutoff = timestamp - 86400
        self.redis.zremrangebyscore(ts_key, 0, cutoff)

    def time_series_get(self, metric: str, start_time: float, end_time: float) -> List[Tuple[float, float]]:
        """Get time series data for time range."""
        ts_key = f"timeseries:{metric}"
        results = self.redis.zrangebyscore(ts_key, start_time, end_time, withscores=True)
        return [(float(value), float(timestamp)) for timestamp, value in results]

    def get_analytics_summary(self) -> Dict[str, Any]:
        """Get overall analytics summary."""
        # Get all counter keys
        counter_keys = self.redis.keys("counter:*")
        
        summary = {
            'total_counters': len(counter_keys),
            'top_metrics': {},
            'recent_activity': {}
        }
        
        # Get top metrics
        pipeline = self.redis.pipeline()
        for key in counter_keys[:20]:  # Limit to top 20
            pipeline.get(key)
        
        values = pipeline.execute()
        
        for key, value in zip(counter_keys[:20], values):
            metric_name = key.replace('counter:', '')
            summary['top_metrics'][metric_name] = int(value) if value else 0
        
        return summary
```

## 🔄 Pub/Sub Messaging

### Message Broker Service
```python
# pubsub.py
import json
import threading
import time
from typing import Callable, Dict, Any, Optional, List
import logging

logger = logging.getLogger(__name__)

class MessageBroker:
    def __init__(self, redis_client: RedisClient):
        self.redis = redis_client
        self.pubsub = self.redis.redis.pubsub()
        self.subscribers = {}
        self.is_running = False
        self.listener_thread = None

    def publish(self, channel: str, message: Dict[str, Any]) -> int:
        """Publish message to channel."""
        serialized_message = json.dumps({
            'data': message,
            'timestamp': time.time(),
            'channel': channel
        })
        
        return self.redis.redis.publish(channel, serialized_message)

    def subscribe(self, channel: str, callback: Callable[[Dict[str, Any]], None]):
        """Subscribe to channel with callback."""
        if channel not in self.subscribers:
            self.subscribers[channel] = []
        
        self.subscribers[channel].append(callback)
        self.pubsub.subscribe(channel)
        
        # Start listener thread if not running
        if not self.is_running:
            self.start_listening()

    def unsubscribe(self, channel: str, callback: Optional[Callable] = None):
        """Unsubscribe from channel."""
        if channel in self.subscribers:
            if callback:
                self.subscribers[channel].remove(callback)
            else:
                del self.subscribers[channel]
            
            if not self.subscribers.get(channel):
                self.pubsub.unsubscribe(channel)

    def start_listening(self):
        """Start listening for messages in background thread."""
        if self.is_running:
            return
        
        self.is_running = True
        self.listener_thread = threading.Thread(target=self._listen_loop, daemon=True)
        self.listener_thread.start()

    def stop_listening(self):
        """Stop listening for messages."""
        self.is_running = False
        if self.listener_thread:
            self.listener_thread.join(timeout=5)

    def _listen_loop(self):
        """Background thread loop for listening to messages."""
        while self.is_running:
            try:
                message = self.pubsub.get_message(timeout=1.0)
                if message and message['type'] == 'message':
                    channel = message['channel']
                    
                    try:
                        data = json.loads(message['data'])
                        
                        # Call all subscribers for this channel
                        for callback in self.subscribers.get(channel, []):
                            try:
                                callback(data)
                            except Exception as e:
                                logger.error(f"Error in subscriber callback: {e}")
                    
                    except json.JSONDecodeError:
                        logger.error(f"Invalid JSON message received on channel {channel}")
            
            except Exception as e:
                logger.error(f"Error in pub/sub listener: {e}")
                time.sleep(1)  # Wait before retrying

# Event system using pub/sub
class EventSystem:
    def __init__(self, redis_client: RedisClient):
        self.broker = MessageBroker(redis_client)
        self.event_handlers = {}

    def emit(self, event: str, data: Dict[str, Any]):
        """Emit an event."""
        event_data = {
            'event': event,
            'data': data,
            'timestamp': time.time()
        }
        
        # Publish to event-specific channel
        self.broker.publish(f"event:{event}", event_data)
        
        # Also publish to general events channel
        self.broker.publish("events", event_data)

    def on(self, event: str, handler: Callable[[Dict[str, Any]], None]):
        """Register event handler."""
        def wrapper(message_data):
            if message_data.get('event') == event:
                handler(message_data.get('data', {}))
        
        self.broker.subscribe(f"event:{event}", wrapper)
        
        if event not in self.event_handlers:
            self.event_handlers[event] = []
        self.event_handlers[event].append(handler)

    def off(self, event: str, handler: Optional[Callable] = None):
        """Unregister event handler."""
        if handler:
            self.event_handlers[event].remove(handler)
        else:
            del self.event_handlers[event]
        
        # Clean up pub/sub subscription if no more handlers
        if not self.event_handlers.get(event):
            self.broker.unsubscribe(f"event:{event}")

# Chat system example
class ChatService:
    def __init__(self, redis_client: RedisClient):
        self.redis = redis_client
        self.broker = MessageBroker(redis_client)

    def send_message(self, room_id: str, user_id: str, message: str):
        """Send message to chat room."""
        message_data = {
            'room_id': room_id,
            'user_id': user_id,
            'message': message,
            'timestamp': time.time()
        }
        
        # Store message in Redis list (chat history)
        history_key = f"chat:history:{room_id}"
        self.redis.redis.lpush(history_key, json.dumps(message_data))
        self.redis.redis.ltrim(history_key, 0, 999)  # Keep last 1000 messages
        self.redis.expire(history_key, 86400 * 30)  # 30 days
        
        # Publish to room channel
        self.broker.publish(f"chat:room:{room_id}", message_data)

    def join_room(self, room_id: str, user_id: str, message_handler: Callable):
        """Join chat room and listen for messages."""
        # Subscribe to room messages
        self.broker.subscribe(f"chat:room:{room_id}", message_handler)
        
        # Add user to room members
        members_key = f"chat:members:{room_id}"
        self.redis.redis.sadd(members_key, user_id)
        self.redis.expire(members_key, 86400)  # 24 hours

    def leave_room(self, room_id: str, user_id: str):
        """Leave chat room."""
        # Remove from room members
        members_key = f"chat:members:{room_id}"
        self.redis.redis.srem(members_key, user_id)
        
        # Unsubscribe from room messages
        self.broker.unsubscribe(f"chat:room:{room_id}")

    def get_room_history(self, room_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent chat history for room."""
        history_key = f"chat:history:{room_id}"
        messages = self.redis.redis.lrange(history_key, 0, limit - 1)
        
        return [json.loads(msg) for msg in messages]

    def get_room_members(self, room_id: str) -> List[str]:
        """Get current room members."""
        members_key = f"chat:members:{room_id}"
        return list(self.redis.redis.smembers(members_key))
```

## 🔧 Redis Management & Monitoring

### Redis Monitor
```python
# redis_monitor.py
import time
from typing import Dict, List, Any

class RedisMonitor:
    def __init__(self, redis_client: RedisClient):
        self.redis = redis_client

    def get_info(self) -> Dict[str, Any]:
        """Get comprehensive Redis information."""
        info = self.redis.redis.info()
        
        return {
            'server': {
                'version': info.get('redis_version'),
                'mode': info.get('redis_mode'),
                'uptime_seconds': info.get('uptime_in_seconds'),
                'uptime_days': info.get('uptime_in_days')
            },
            'memory': {
                'used_memory': info.get('used_memory'),
                'used_memory_human': info.get('used_memory_human'),
                'used_memory_peak': info.get('used_memory_peak'),
                'used_memory_peak_human': info.get('used_memory_peak_human'),
                'memory_fragmentation_ratio': info.get('mem_fragmentation_ratio')
            },
            'clients': {
                'connected_clients': info.get('connected_clients'),
                'blocked_clients': info.get('blocked_clients'),
                'client_longest_output_list': info.get('client_longest_output_list')
            },
            'stats': {
                'total_connections_received': info.get('total_connections_received'),
                'total_commands_processed': info.get('total_commands_processed'),
                'instantaneous_ops_per_sec': info.get('instantaneous_ops_per_sec'),
                'keyspace_hits': info.get('keyspace_hits'),
                'keyspace_misses': info.get('keyspace_misses'),
                'hit_rate': self._calculate_hit_rate(info)
            },
            'persistence': {
                'rdb_last_save_time': info.get('rdb_last_save_time'),
                'rdb_changes_since_last_save': info.get('rdb_changes_since_last_save'),
                'aof_enabled': info.get('aof_enabled'),
                'aof_rewrite_in_progress': info.get('aof_rewrite_in_progress')
            }
        }

    def _calculate_hit_rate(self, info: Dict) -> float:
        """Calculate cache hit rate percentage."""
        hits = info.get('keyspace_hits', 0)
        misses = info.get('keyspace_misses', 0)
        total = hits + misses
        
        if total == 0:
            return 0.0
        
        return round((hits / total) * 100, 2)

    def get_slow_log(self, count: int = 10) -> List[Dict[str, Any]]:
        """Get slow query log."""
        slow_log = self.redis.redis.slowlog_get(count)
        
        results = []
        for entry in slow_log:
            results.append({
                'id': entry['id'],
                'timestamp': entry['start_time'],
                'duration_microseconds': entry['duration'],
                'command': ' '.join(entry['command']),
                'client_address': entry.get('client_address', 'N/A'),
                'client_name': entry.get('client_name', 'N/A')
            })
        
        return results

    def get_config(self, pattern: str = "*") -> Dict[str, str]:
        """Get Redis configuration."""
        config = self.redis.redis.config_get(pattern)
        return dict(config)

    def analyze_memory_usage(self) -> Dict[str, Any]:
        """Analyze memory usage by data type."""
        memory_info = self.redis.redis.memory_usage_sample()
        
        # Get key sample for analysis
        sample_keys = self.redis.keys("*")[:1000]  # Sample first 1000 keys
        
        type_distribution = {}
        memory_by_type = {}
        
        for key in sample_keys:
            key_type = self.redis.redis.type(key)
            key_memory = self.redis.redis.memory_usage(key) or 0
            
            if key_type not in type_distribution:
                type_distribution[key_type] = 0
                memory_by_type[key_type] = 0
            
            type_distribution[key_type] += 1
            memory_by_type[key_type] += key_memory
        
        return {
            'total_keys_sampled': len(sample_keys),
            'type_distribution': type_distribution,
            'memory_by_type': memory_by_type,
            'memory_efficiency': memory_info
        }

    def get_client_list(self) -> List[Dict[str, Any]]:
        """Get connected clients information."""
        clients = self.redis.redis.client_list()
        
        client_info = []
        for client in clients:
            client_info.append({
                'id': client.get('id'),
                'addr': client.get('addr'),
                'name': client.get('name'),
                'age': client.get('age'),
                'idle': client.get('idle'),
                'flags': client.get('flags'),
                'db': client.get('db'),
                'cmd': client.get('cmd'),
                'sub': client.get('sub'),
                'psub': client.get('psub')
            })
        
        return client_info

    def cleanup_expired_keys(self, pattern: str = "*", batch_size: int = 1000) -> int:
        """Clean up expired keys manually."""
        cursor = 0
        deleted_count = 0
        
        while True:
            cursor, keys = self.redis.redis.scan(cursor, match=pattern, count=batch_size)
            
            for key in keys:
                ttl = self.redis.ttl(key)
                if ttl == -1:  # Key exists but has no expiration
                    continue
                elif ttl == -2:  # Key doesn't exist
                    continue
                elif ttl == 0:  # Key expired
                    if self.redis.delete(key):
                        deleted_count += 1
            
            if cursor == 0:
                break
        
        return deleted_count

    def optimize_memory(self) -> Dict[str, Any]:
        """Run memory optimization operations."""
        results = {}
        
        # Get initial memory usage
        initial_memory = self.redis.redis.info()['used_memory']
        
        # Run MEMORY PURGE if available
        try:
            self.redis.redis.memory_purge()
            results['memory_purge'] = 'completed'
        except:
            results['memory_purge'] = 'not_available'
        
        # Cleanup expired keys
        expired_cleaned = self.cleanup_expired_keys()
        results['expired_keys_cleaned'] = expired_cleaned
        
        # Get final memory usage
        final_memory = self.redis.redis.info()['used_memory']
        memory_saved = initial_memory - final_memory
        
        results['memory_optimization'] = {
            'initial_memory': initial_memory,
            'final_memory': final_memory,
            'memory_saved': memory_saved,
            'memory_saved_percent': round((memory_saved / initial_memory) * 100, 2) if initial_memory > 0 else 0
        }
        
        return results
```

## 🛠️ Best Practices Summary

### 1. Key Naming Conventions
```python
# Use consistent, hierarchical naming
user_session = "session:user:123"
user_cache = "cache:user:profile:123"
rate_limit = "rate_limit:api:user:123"
analytics = "analytics:page_views:daily:20231201"
```

### 2. Memory Management
- Set appropriate expiration times for all keys
- Use memory-efficient data types (HyperLogLog for counting, Bloom filters for membership)
- Monitor memory usage and set maxmemory policies
- Regular cleanup of expired and unnecessary keys

### 3. Connection Management
- Use connection pooling
- Set appropriate timeout values
- Monitor connection count and performance
- Handle connection failures gracefully

### 4. Security
- Use password authentication
- Disable dangerous commands in production
- Use SSL/TLS for connections
- Implement proper network security (VPC, firewalls)

### 5. Monitoring & Maintenance
- Monitor key metrics (memory, connections, hit rate)
- Set up alerts for critical thresholds
- Regular backup of persistent data
- Performance tuning based on usage patterns

---

*Redis excels at high-performance caching, session management, and real-time features. Proper configuration and monitoring ensure optimal performance and reliability.*
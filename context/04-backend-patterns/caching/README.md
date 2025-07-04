# Caching Strategies

Comprehensive guide to implementing effective caching strategies including cache patterns, Redis implementation, CDN integration, and cache invalidation techniques.

## 🎯 Caching Overview

Caching is crucial for application performance:
- **Cache-Aside** - Application manages cache population
- **Write-Through** - Write to cache and database simultaneously
- **Write-Behind** - Write to cache first, database later
- **Refresh-Ahead** - Proactively refresh cache before expiration
- **Cache Invalidation** - Strategies for keeping cache fresh
- **Distributed Caching** - Scaling cache across multiple nodes

## 🔄 Cache Patterns

### Cache-Aside (Lazy Loading)

```python
# Basic cache-aside implementation
import hashlib
import json
from typing import Optional, Any, Callable
from datetime import datetime, timedelta
import redis
from functools import wraps

class CacheAsideManager:
    """Cache-Aside pattern implementation"""
    
    def __init__(self, redis_client: redis.Redis, default_ttl: int = 3600):
        self.redis = redis_client
        self.default_ttl = default_ttl
    
    def _generate_key(self, namespace: str, key: str) -> str:
        """Generate cache key with namespace"""
        return f"{namespace}:{key}"
    
    async def get_or_set(
        self,
        namespace: str,
        key: str,
        fetch_func: Callable,
        ttl: Optional[int] = None
    ) -> Any:
        """Get from cache or fetch and set"""
        cache_key = self._generate_key(namespace, key)
        
        # Try to get from cache
        cached = self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Fetch from source
        data = await fetch_func()
        
        # Store in cache
        self.redis.setex(
            cache_key,
            ttl or self.default_ttl,
            json.dumps(data)
        )
        
        return data
    
    def invalidate(self, namespace: str, key: str):
        """Invalidate specific cache entry"""
        cache_key = self._generate_key(namespace, key)
        self.redis.delete(cache_key)
    
    def invalidate_pattern(self, pattern: str):
        """Invalidate all keys matching pattern"""
        keys = self.redis.keys(pattern)
        if keys:
            self.redis.delete(*keys)

# Decorator for cache-aside
def cache_aside(
    namespace: str,
    key_func: Callable = None,
    ttl: int = 3600
):
    """Decorator for cache-aside pattern"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            if key_func:
                cache_key = key_func(*args, **kwargs)
            else:
                # Default key generation
                key_data = f"{func.__name__}:{args}:{kwargs}"
                cache_key = hashlib.md5(key_data.encode()).hexdigest()
            
            # Use cache manager
            cache_manager = CacheAsideManager(redis_client)
            return await cache_manager.get_or_set(
                namespace=namespace,
                key=cache_key,
                fetch_func=lambda: func(*args, **kwargs),
                ttl=ttl
            )
        return wrapper
    return decorator

# Usage example
@cache_aside(namespace="users", ttl=300)
async def get_user_profile(user_id: int):
    """Get user profile with caching"""
    user = await db.query(User).filter(User.id == user_id).first()
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "profile": await user.get_profile()
    }
```

### Write-Through Cache

```python
# Write-through cache implementation
class WriteThroughCache:
    """Write-through caching pattern"""
    
    def __init__(self, redis_client: redis.Redis, db_session):
        self.redis = redis_client
        self.db = db_session
    
    async def write(
        self,
        namespace: str,
        key: str,
        data: dict,
        model_class,
        ttl: int = 3600
    ):
        """Write to both cache and database"""
        cache_key = f"{namespace}:{key}"
        
        # Write to database first
        db_record = model_class(**data)
        self.db.add(db_record)
        await self.db.commit()
        
        # Write to cache
        cache_data = {
            "id": db_record.id,
            **data,
            "cached_at": datetime.utcnow().isoformat()
        }
        self.redis.setex(
            cache_key,
            ttl,
            json.dumps(cache_data)
        )
        
        return db_record
    
    async def update(
        self,
        namespace: str,
        key: str,
        data: dict,
        model_class,
        record_id: int,
        ttl: int = 3600
    ):
        """Update both cache and database"""
        cache_key = f"{namespace}:{key}"
        
        # Update database
        db_record = await self.db.query(model_class).filter(
            model_class.id == record_id
        ).first()
        
        if not db_record:
            raise ValueError(f"Record {record_id} not found")
        
        for key, value in data.items():
            setattr(db_record, key, value)
        
        await self.db.commit()
        
        # Update cache
        cache_data = {
            "id": db_record.id,
            **data,
            "cached_at": datetime.utcnow().isoformat()
        }
        self.redis.setex(
            cache_key,
            ttl,
            json.dumps(cache_data)
        )
        
        return db_record
    
    async def delete(
        self,
        namespace: str,
        key: str,
        model_class,
        record_id: int
    ):
        """Delete from both cache and database"""
        cache_key = f"{namespace}:{key}"
        
        # Delete from database
        db_record = await self.db.query(model_class).filter(
            model_class.id == record_id
        ).first()
        
        if db_record:
            await self.db.delete(db_record)
            await self.db.commit()
        
        # Delete from cache
        self.redis.delete(cache_key)

# Usage with FastAPI
from fastapi import Depends

write_through_cache = WriteThroughCache(redis_client, db_session)

@app.post("/api/products")
async def create_product(
    product: ProductCreate,
    cache: WriteThroughCache = Depends(lambda: write_through_cache)
):
    """Create product with write-through caching"""
    result = await cache.write(
        namespace="products",
        key=product.sku,
        data=product.dict(),
        model_class=Product,
        ttl=7200
    )
    return result
```

### Write-Behind (Write-Back) Cache

```python
# Write-behind cache with async queue
import asyncio
from collections import deque
from typing import Dict, List
import pickle

class WriteBehindCache:
    """Write-behind caching with batch writes"""
    
    def __init__(
        self,
        redis_client: redis.Redis,
        db_session,
        batch_size: int = 100,
        flush_interval: int = 5
    ):
        self.redis = redis_client
        self.db = db_session
        self.batch_size = batch_size
        self.flush_interval = flush_interval
        self.write_queue = deque()
        self._running = False
        self._flush_task = None
    
    async def start(self):
        """Start background flush task"""
        self._running = True
        self._flush_task = asyncio.create_task(self._flush_loop())
    
    async def stop(self):
        """Stop background flush task"""
        self._running = False
        if self._flush_task:
            await self._flush_task
        # Flush remaining items
        await self._flush_queue()
    
    async def _flush_loop(self):
        """Background task to flush write queue"""
        while self._running:
            await asyncio.sleep(self.flush_interval)
            await self._flush_queue()
    
    async def _flush_queue(self):
        """Flush write queue to database"""
        if not self.write_queue:
            return
        
        batch = []
        while self.write_queue and len(batch) < self.batch_size:
            batch.append(self.write_queue.popleft())
        
        if batch:
            await self._write_batch_to_db(batch)
    
    async def _write_batch_to_db(self, batch: List[Dict]):
        """Write batch to database"""
        try:
            # Group by operation type
            inserts = [item for item in batch if item["op"] == "insert"]
            updates = [item for item in batch if item["op"] == "update"]
            deletes = [item for item in batch if item["op"] == "delete"]
            
            # Bulk insert
            if inserts:
                self.db.bulk_insert_mappings(
                    inserts[0]["model"],
                    [item["data"] for item in inserts]
                )
            
            # Bulk update
            if updates:
                for item in updates:
                    await self.db.query(item["model"]).filter(
                        item["model"].id == item["id"]
                    ).update(item["data"])
            
            # Bulk delete
            if deletes:
                delete_ids = [item["id"] for item in deletes]
                await self.db.query(deletes[0]["model"]).filter(
                    deletes[0]["model"].id.in_(delete_ids)
                ).delete()
            
            await self.db.commit()
            
        except Exception as e:
            logger.error(f"Failed to flush batch: {e}")
            await self.db.rollback()
            # Re-queue failed items
            self.write_queue.extend(batch)
    
    async def write(
        self,
        namespace: str,
        key: str,
        data: dict,
        model_class
    ):
        """Write to cache immediately, queue for database"""
        cache_key = f"{namespace}:{key}"
        
        # Write to cache immediately
        self.redis.setex(
            cache_key,
            3600,
            json.dumps(data)
        )
        
        # Queue for database write
        self.write_queue.append({
            "op": "insert",
            "model": model_class,
            "data": data
        })
        
        # Check if immediate flush needed
        if len(self.write_queue) >= self.batch_size:
            await self._flush_queue()
    
    async def update(
        self,
        namespace: str,
        key: str,
        record_id: int,
        data: dict,
        model_class
    ):
        """Update cache immediately, queue for database"""
        cache_key = f"{namespace}:{key}"
        
        # Update cache
        cached = self.redis.get(cache_key)
        if cached:
            cache_data = json.loads(cached)
            cache_data.update(data)
            self.redis.setex(
                cache_key,
                3600,
                json.dumps(cache_data)
            )
        
        # Queue for database update
        self.write_queue.append({
            "op": "update",
            "model": model_class,
            "id": record_id,
            "data": data
        })

# Lifecycle management
write_behind_cache = WriteBehindCache(redis_client, db_session)

@app.on_event("startup")
async def startup_event():
    await write_behind_cache.start()

@app.on_event("shutdown")
async def shutdown_event():
    await write_behind_cache.stop()
```

### Refresh-Ahead Cache

```python
# Refresh-ahead caching
import asyncio
from datetime import datetime, timedelta
from typing import Dict, Callable, Any

class RefreshAheadCache:
    """Proactive cache refresh before expiration"""
    
    def __init__(
        self,
        redis_client: redis.Redis,
        refresh_threshold: float = 0.8  # Refresh at 80% of TTL
    ):
        self.redis = redis_client
        self.refresh_threshold = refresh_threshold
        self.refresh_tasks: Dict[str, asyncio.Task] = {}
        self.refresh_callbacks: Dict[str, Callable] = {}
    
    async def get_with_refresh(
        self,
        key: str,
        fetch_func: Callable,
        ttl: int = 3600
    ) -> Any:
        """Get value with automatic refresh"""
        # Check cache
        cached = self.redis.get(key)
        if cached:
            # Check remaining TTL
            remaining_ttl = self.redis.ttl(key)
            
            # Schedule refresh if needed
            if remaining_ttl < (ttl * (1 - self.refresh_threshold)):
                await self._schedule_refresh(key, fetch_func, ttl)
            
            return json.loads(cached)
        
        # Fetch and cache
        data = await fetch_func()
        self.redis.setex(key, ttl, json.dumps(data))
        
        # Schedule future refresh
        await self._schedule_refresh(key, fetch_func, ttl)
        
        return data
    
    async def _schedule_refresh(
        self,
        key: str,
        fetch_func: Callable,
        ttl: int
    ):
        """Schedule cache refresh"""
        # Cancel existing refresh task if any
        if key in self.refresh_tasks:
            self.refresh_tasks[key].cancel()
        
        # Calculate refresh time
        refresh_delay = ttl * self.refresh_threshold
        
        # Create refresh task
        async def refresh_cache():
            await asyncio.sleep(refresh_delay)
            try:
                # Fetch fresh data
                data = await fetch_func()
                # Update cache
                self.redis.setex(key, ttl, json.dumps(data))
                # Schedule next refresh
                await self._schedule_refresh(key, fetch_func, ttl)
            except Exception as e:
                logger.error(f"Failed to refresh cache for {key}: {e}")
        
        task = asyncio.create_task(refresh_cache())
        self.refresh_tasks[key] = task
    
    def stop_refresh(self, key: str):
        """Stop refresh for specific key"""
        if key in self.refresh_tasks:
            self.refresh_tasks[key].cancel()
            del self.refresh_tasks[key]
    
    def stop_all_refreshes(self):
        """Stop all refresh tasks"""
        for task in self.refresh_tasks.values():
            task.cancel()
        self.refresh_tasks.clear()

# Hot data identification and preloading
class HotDataManager:
    """Manage frequently accessed data"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.access_counts: Dict[str, int] = {}
        self.hot_threshold = 10  # Access count threshold
    
    async def track_access(self, key: str):
        """Track data access patterns"""
        # Increment access counter
        count = self.redis.hincrby("access_counts", key, 1)
        
        # Check if data is hot
        if count >= self.hot_threshold:
            await self._mark_as_hot(key)
    
    async def _mark_as_hot(self, key: str):
        """Mark data as hot and adjust caching"""
        # Add to hot data set
        self.redis.sadd("hot_data_keys", key)
        
        # Extend TTL for hot data
        current_ttl = self.redis.ttl(key)
        if current_ttl > 0:
            self.redis.expire(key, current_ttl * 2)
    
    async def preload_hot_data(self, fetch_funcs: Dict[str, Callable]):
        """Preload frequently accessed data"""
        hot_keys = self.redis.smembers("hot_data_keys")
        
        tasks = []
        for key in hot_keys:
            if key in fetch_funcs:
                task = self._preload_key(key, fetch_funcs[key])
                tasks.append(task)
        
        await asyncio.gather(*tasks)
    
    async def _preload_key(self, key: str, fetch_func: Callable):
        """Preload single key"""
        try:
            data = await fetch_func()
            self.redis.setex(key, 7200, json.dumps(data))  # 2 hour TTL for hot data
        except Exception as e:
            logger.error(f"Failed to preload {key}: {e}")
```

## 🗄️ Redis Implementation

### Advanced Redis Patterns

```python
# Redis configuration and connection management
from redis import Redis, ConnectionPool
from redis.sentinel import Sentinel
import redis.asyncio as aioredis

class RedisConfig:
    """Redis configuration"""
    
    def __init__(
        self,
        host: str = "localhost",
        port: int = 6379,
        password: Optional[str] = None,
        db: int = 0,
        max_connections: int = 50,
        decode_responses: bool = True
    ):
        self.host = host
        self.port = port
        self.password = password
        self.db = db
        self.max_connections = max_connections
        self.decode_responses = decode_responses
    
    def create_pool(self) -> ConnectionPool:
        """Create connection pool"""
        return ConnectionPool(
            host=self.host,
            port=self.port,
            password=self.password,
            db=self.db,
            max_connections=self.max_connections,
            decode_responses=self.decode_responses
        )
    
    async def create_async_pool(self) -> aioredis.Redis:
        """Create async Redis connection"""
        return await aioredis.from_url(
            f"redis://{self.host}:{self.port}/{self.db}",
            password=self.password,
            max_connections=self.max_connections,
            decode_responses=self.decode_responses
        )

# Redis data structures and patterns
class RedisDataStructures:
    """Advanced Redis data structure usage"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    # Sorted sets for leaderboards
    async def update_leaderboard(
        self,
        leaderboard_key: str,
        user_id: str,
        score: float
    ):
        """Update user score in leaderboard"""
        self.redis.zadd(leaderboard_key, {user_id: score})
    
    async def get_top_users(
        self,
        leaderboard_key: str,
        count: int = 10
    ) -> List[tuple]:
        """Get top users from leaderboard"""
        return self.redis.zrevrange(
            leaderboard_key,
            0,
            count - 1,
            withscores=True
        )
    
    async def get_user_rank(
        self,
        leaderboard_key: str,
        user_id: str
    ) -> Optional[int]:
        """Get user's rank in leaderboard"""
        rank = self.redis.zrevrank(leaderboard_key, user_id)
        return rank + 1 if rank is not None else None
    
    # HyperLogLog for unique counts
    async def track_unique_visitor(
        self,
        date: str,
        visitor_id: str
    ):
        """Track unique visitor"""
        key = f"unique_visitors:{date}"
        self.redis.pfadd(key, visitor_id)
    
    async def get_unique_visitor_count(self, date: str) -> int:
        """Get unique visitor count"""
        key = f"unique_visitors:{date}"
        return self.redis.pfcount(key)
    
    # Geospatial data
    async def add_location(
        self,
        key: str,
        longitude: float,
        latitude: float,
        member: str
    ):
        """Add geospatial location"""
        self.redis.geoadd(key, longitude, latitude, member)
    
    async def find_nearby(
        self,
        key: str,
        longitude: float,
        latitude: float,
        radius: float,
        unit: str = "km"
    ) -> List[tuple]:
        """Find nearby locations"""
        return self.redis.georadius(
            key,
            longitude,
            latitude,
            radius,
            unit=unit,
            withdist=True,
            sort="ASC"
        )
    
    # Pub/Sub for real-time updates
    async def publish_update(
        self,
        channel: str,
        message: dict
    ):
        """Publish update to channel"""
        self.redis.publish(channel, json.dumps(message))
    
    # Lua scripting for atomic operations
    def register_scripts(self):
        """Register Lua scripts"""
        # Atomic increment with limit
        self.increment_with_limit = self.redis.register_script("""
            local key = KEYS[1]
            local limit = tonumber(ARGV[1])
            local current = tonumber(redis.call('GET', key) or 0)
            
            if current < limit then
                return redis.call('INCR', key)
            else
                return current
            end
        """)
        
        # Sliding window rate limiter
        self.sliding_window_limiter = self.redis.register_script("""
            local key = KEYS[1]
            local limit = tonumber(ARGV[1])
            local window = tonumber(ARGV[2])
            local now = tonumber(ARGV[3])
            
            -- Remove old entries
            redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
            
            -- Count current entries
            local current = redis.call('ZCARD', key)
            
            if current < limit then
                -- Add new entry
                redis.call('ZADD', key, now, now)
                redis.call('EXPIRE', key, window)
                return 1
            else
                return 0
            end
        """)

# Redis Sentinel for high availability
class RedisSentinelManager:
    """Redis Sentinel connection manager"""
    
    def __init__(
        self,
        sentinels: List[tuple],
        service_name: str,
        password: Optional[str] = None
    ):
        self.sentinel = Sentinel(sentinels)
        self.service_name = service_name
        self.password = password
    
    def get_master(self) -> Redis:
        """Get master Redis instance"""
        return self.sentinel.master_for(
            self.service_name,
            password=self.password,
            decode_responses=True
        )
    
    def get_slave(self) -> Redis:
        """Get slave Redis instance for reads"""
        return self.sentinel.slave_for(
            self.service_name,
            password=self.password,
            decode_responses=True
        )
```

### Redis Caching Strategies

```python
# Multi-level caching with Redis
class MultiLevelCache:
    """L1 (memory) + L2 (Redis) caching"""
    
    def __init__(
        self,
        redis_client: Redis,
        l1_max_size: int = 1000,
        l1_ttl: int = 60
    ):
        self.redis = redis_client
        self.l1_cache = {}  # In-memory cache
        self.l1_max_size = l1_max_size
        self.l1_ttl = l1_ttl
        self.l1_timestamps = {}
    
    async def get(self, key: str) -> Optional[Any]:
        """Get from multi-level cache"""
        # Check L1 cache
        if key in self.l1_cache:
            # Check if expired
            if (datetime.utcnow() - self.l1_timestamps[key]).seconds < self.l1_ttl:
                return self.l1_cache[key]
            else:
                # Remove expired entry
                del self.l1_cache[key]
                del self.l1_timestamps[key]
        
        # Check L2 cache (Redis)
        value = self.redis.get(key)
        if value:
            # Populate L1 cache
            self._add_to_l1(key, json.loads(value))
            return json.loads(value)
        
        return None
    
    async def set(
        self,
        key: str,
        value: Any,
        ttl: int = 3600
    ):
        """Set in multi-level cache"""
        # Set in L2 (Redis)
        self.redis.setex(key, ttl, json.dumps(value))
        
        # Set in L1
        self._add_to_l1(key, value)
    
    def _add_to_l1(self, key: str, value: Any):
        """Add to L1 cache with LRU eviction"""
        # Check size limit
        if len(self.l1_cache) >= self.l1_max_size:
            # Evict oldest entry
            oldest_key = min(
                self.l1_timestamps.keys(),
                key=lambda k: self.l1_timestamps[k]
            )
            del self.l1_cache[oldest_key]
            del self.l1_timestamps[oldest_key]
        
        # Add new entry
        self.l1_cache[key] = value
        self.l1_timestamps[key] = datetime.utcnow()

# Tagged cache invalidation
class TaggedCache:
    """Cache with tag-based invalidation"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    async def set_with_tags(
        self,
        key: str,
        value: Any,
        tags: List[str],
        ttl: int = 3600
    ):
        """Set cache entry with tags"""
        # Store value
        self.redis.setex(key, ttl, json.dumps(value))
        
        # Store tags
        for tag in tags:
            tag_key = f"tag:{tag}"
            self.redis.sadd(tag_key, key)
            self.redis.expire(tag_key, ttl)
    
    async def invalidate_by_tag(self, tag: str):
        """Invalidate all entries with tag"""
        tag_key = f"tag:{tag}"
        
        # Get all keys with this tag
        keys = self.redis.smembers(tag_key)
        
        if keys:
            # Delete all keys
            self.redis.delete(*keys)
            
        # Delete tag set
        self.redis.delete(tag_key)
    
    async def get_with_tags(self, key: str) -> Optional[tuple]:
        """Get value and its tags"""
        value = self.redis.get(key)
        if not value:
            return None
        
        # Find tags for this key
        tags = []
        for tag_key in self.redis.scan_iter(match="tag:*"):
            if self.redis.sismember(tag_key, key):
                tag = tag_key.split(":", 1)[1]
                tags.append(tag)
        
        return json.loads(value), tags
```

## 🌐 CDN Integration

### CDN Cache Headers

```python
# CDN cache control
from fastapi import Response
from datetime import datetime, timezone
import hashlib

class CDNCacheControl:
    """CDN cache header management"""
    
    @staticmethod
    def set_cache_headers(
        response: Response,
        max_age: int = 3600,
        s_maxage: Optional[int] = None,
        public: bool = True,
        immutable: bool = False,
        must_revalidate: bool = False
    ):
        """Set CDN cache control headers"""
        directives = []
        
        if public:
            directives.append("public")
        else:
            directives.append("private")
        
        directives.append(f"max-age={max_age}")
        
        if s_maxage is not None:
            directives.append(f"s-maxage={s_maxage}")
        
        if immutable:
            directives.append("immutable")
        
        if must_revalidate:
            directives.append("must-revalidate")
        
        response.headers["Cache-Control"] = ", ".join(directives)
    
    @staticmethod
    def set_etag(response: Response, content: str):
        """Set ETag header"""
        etag = hashlib.md5(content.encode()).hexdigest()
        response.headers["ETag"] = f'"{etag}"'
        return etag
    
    @staticmethod
    def set_last_modified(
        response: Response,
        last_modified: datetime
    ):
        """Set Last-Modified header"""
        response.headers["Last-Modified"] = last_modified.strftime(
            "%a, %d %b %Y %H:%M:%S GMT"
        )
    
    @staticmethod
    def check_not_modified(
        request_headers: dict,
        etag: Optional[str] = None,
        last_modified: Optional[datetime] = None
    ) -> bool:
        """Check if resource not modified"""
        # Check If-None-Match
        if etag and "if-none-match" in request_headers:
            if request_headers["if-none-match"] == f'"{etag}"':
                return True
        
        # Check If-Modified-Since
        if last_modified and "if-modified-since" in request_headers:
            try:
                if_modified = datetime.strptime(
                    request_headers["if-modified-since"],
                    "%a, %d %b %Y %H:%M:%S GMT"
                ).replace(tzinfo=timezone.utc)
                
                if last_modified <= if_modified:
                    return True
            except ValueError:
                pass
        
        return False

# CDN purging
class CDNPurgeManager:
    """CDN cache purging"""
    
    def __init__(self, cdn_api_key: str, cdn_zone_id: str):
        self.api_key = cdn_api_key
        self.zone_id = cdn_zone_id
    
    async def purge_url(self, url: str):
        """Purge specific URL from CDN"""
        # Example for Cloudflare
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"https://api.cloudflare.com/client/v4/zones/{self.zone_id}/purge_cache",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={"files": [url]}
            )
            return response.json()
    
    async def purge_tag(self, tag: str):
        """Purge by cache tag"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"https://api.cloudflare.com/client/v4/zones/{self.zone_id}/purge_cache",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={"tags": [tag]}
            )
            return response.json()
    
    async def purge_all(self):
        """Purge entire zone cache"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"https://api.cloudflare.com/client/v4/zones/{self.zone_id}/purge_cache",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                },
                json={"purge_everything": True}
            )
            return response.json()

# Edge caching with Cloudflare Workers KV
class EdgeCache:
    """Edge caching with Cloudflare Workers KV"""
    
    def __init__(self, account_id: str, api_token: str):
        self.account_id = account_id
        self.api_token = api_token
        self.base_url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}"
    
    async def put(
        self,
        namespace_id: str,
        key: str,
        value: str,
        expiration: Optional[int] = None,
        metadata: Optional[dict] = None
    ):
        """Put value in edge cache"""
        url = f"{self.base_url}/storage/kv/namespaces/{namespace_id}/values/{key}"
        
        params = {}
        if expiration:
            params["expiration"] = expiration
        if metadata:
            params["metadata"] = json.dumps(metadata)
        
        async with httpx.AsyncClient() as client:
            response = await client.put(
                url,
                params=params,
                content=value,
                headers={
                    "Authorization": f"Bearer {self.api_token}",
                    "Content-Type": "text/plain"
                }
            )
            return response.status_code == 200
    
    async def get(
        self,
        namespace_id: str,
        key: str
    ) -> Optional[str]:
        """Get value from edge cache"""
        url = f"{self.base_url}/storage/kv/namespaces/{namespace_id}/values/{key}"
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {self.api_token}"}
            )
            
            if response.status_code == 200:
                return response.text
            return None
```

## 🔄 Cache Invalidation

### Invalidation Strategies

```python
# Smart cache invalidation
from typing import Set, Dict
import re

class CacheInvalidationManager:
    """Intelligent cache invalidation"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
        self.dependency_graph: Dict[str, Set[str]] = {}
    
    def register_dependency(self, key: str, depends_on: List[str]):
        """Register cache dependencies"""
        for dep in depends_on:
            if dep not in self.dependency_graph:
                self.dependency_graph[dep] = set()
            self.dependency_graph[dep].add(key)
    
    async def invalidate_cascade(self, key: str):
        """Invalidate key and all dependents"""
        # Delete the key
        self.redis.delete(key)
        
        # Find and invalidate dependents
        if key in self.dependency_graph:
            dependents = self.dependency_graph[key]
            for dependent in dependents:
                await self.invalidate_cascade(dependent)
    
    async def invalidate_pattern(self, pattern: str):
        """Invalidate keys matching pattern"""
        # Use SCAN for efficient pattern matching
        cursor = 0
        while True:
            cursor, keys = self.redis.scan(
                cursor,
                match=pattern,
                count=100
            )
            
            if keys:
                self.redis.delete(*keys)
            
            if cursor == 0:
                break
    
    async def invalidate_by_time(self, older_than: datetime):
        """Invalidate entries older than specified time"""
        # This requires storing timestamps with cache entries
        # Implementation depends on your cache structure
        pass

# Event-based invalidation
class EventBasedInvalidation:
    """Invalidate cache based on domain events"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
        self.invalidation_rules = {}
    
    def register_rule(
        self,
        event_type: str,
        invalidation_func: Callable
    ):
        """Register invalidation rule for event type"""
        self.invalidation_rules[event_type] = invalidation_func
    
    async def handle_event(self, event: dict):
        """Handle domain event and invalidate cache"""
        event_type = event.get("type")
        
        if event_type in self.invalidation_rules:
            invalidation_func = self.invalidation_rules[event_type]
            await invalidation_func(self.redis, event)
    
    # Example invalidation rules
    @staticmethod
    async def invalidate_user_cache(redis: Redis, event: dict):
        """Invalidate user-related cache"""
        user_id = event.get("user_id")
        if user_id:
            # Invalidate user profile
            redis.delete(f"user:{user_id}")
            # Invalidate user's posts
            redis.delete(f"user:{user_id}:posts")
            # Invalidate user's followers
            redis.delete(f"user:{user_id}:followers")
    
    @staticmethod
    async def invalidate_product_cache(redis: Redis, event: dict):
        """Invalidate product-related cache"""
        product_id = event.get("product_id")
        if product_id:
            # Invalidate product details
            redis.delete(f"product:{product_id}")
            # Invalidate category listing
            category_id = event.get("category_id")
            if category_id:
                redis.delete(f"category:{category_id}:products")

# Time-based invalidation with versioning
class VersionedCache:
    """Cache with version-based invalidation"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    async def get_version(self, namespace: str) -> int:
        """Get current version for namespace"""
        version = self.redis.get(f"version:{namespace}")
        return int(version) if version else 1
    
    async def increment_version(self, namespace: str):
        """Increment version to invalidate namespace"""
        self.redis.incr(f"version:{namespace}")
    
    async def get_with_version(
        self,
        namespace: str,
        key: str
    ) -> Optional[Any]:
        """Get value with version check"""
        version = await self.get_version(namespace)
        versioned_key = f"{namespace}:v{version}:{key}"
        
        value = self.redis.get(versioned_key)
        return json.loads(value) if value else None
    
    async def set_with_version(
        self,
        namespace: str,
        key: str,
        value: Any,
        ttl: int = 3600
    ):
        """Set value with current version"""
        version = await self.get_version(namespace)
        versioned_key = f"{namespace}:v{version}:{key}"
        
        self.redis.setex(
            versioned_key,
            ttl,
            json.dumps(value)
        )
```

## 📊 Cache Monitoring

### Performance Metrics

```python
# Cache metrics collection
from prometheus_client import Counter, Histogram, Gauge
import time

class CacheMetrics:
    """Cache performance metrics"""
    
    def __init__(self):
        # Prometheus metrics
        self.cache_hits = Counter(
            'cache_hits_total',
            'Total number of cache hits',
            ['cache_type', 'namespace']
        )
        self.cache_misses = Counter(
            'cache_misses_total',
            'Total number of cache misses',
            ['cache_type', 'namespace']
        )
        self.cache_errors = Counter(
            'cache_errors_total',
            'Total number of cache errors',
            ['cache_type', 'error_type']
        )
        self.cache_latency = Histogram(
            'cache_operation_duration_seconds',
            'Cache operation duration',
            ['cache_type', 'operation']
        )
        self.cache_size = Gauge(
            'cache_size_bytes',
            'Current cache size in bytes',
            ['cache_type']
        )
        self.cache_evictions = Counter(
            'cache_evictions_total',
            'Total number of cache evictions',
            ['cache_type', 'reason']
        )
    
    def record_hit(self, cache_type: str, namespace: str):
        """Record cache hit"""
        self.cache_hits.labels(
            cache_type=cache_type,
            namespace=namespace
        ).inc()
    
    def record_miss(self, cache_type: str, namespace: str):
        """Record cache miss"""
        self.cache_misses.labels(
            cache_type=cache_type,
            namespace=namespace
        ).inc()
    
    def record_error(self, cache_type: str, error_type: str):
        """Record cache error"""
        self.cache_errors.labels(
            cache_type=cache_type,
            error_type=error_type
        ).inc()
    
    def record_operation(
        self,
        cache_type: str,
        operation: str,
        duration: float
    ):
        """Record operation duration"""
        self.cache_latency.labels(
            cache_type=cache_type,
            operation=operation
        ).observe(duration)
    
    def update_size(self, cache_type: str, size: int):
        """Update cache size"""
        self.cache_size.labels(cache_type=cache_type).set(size)

# Cache monitoring wrapper
class MonitoredCache:
    """Cache wrapper with monitoring"""
    
    def __init__(
        self,
        cache_impl,
        cache_type: str,
        metrics: CacheMetrics
    ):
        self.cache = cache_impl
        self.cache_type = cache_type
        self.metrics = metrics
    
    async def get(self, key: str, namespace: str = "default"):
        """Get with monitoring"""
        start_time = time.time()
        
        try:
            value = await self.cache.get(key)
            
            if value is not None:
                self.metrics.record_hit(self.cache_type, namespace)
            else:
                self.metrics.record_miss(self.cache_type, namespace)
            
            return value
            
        except Exception as e:
            self.metrics.record_error(
                self.cache_type,
                type(e).__name__
            )
            raise
        finally:
            duration = time.time() - start_time
            self.metrics.record_operation(
                self.cache_type,
                "get",
                duration
            )
    
    async def set(
        self,
        key: str,
        value: Any,
        ttl: int = 3600,
        namespace: str = "default"
    ):
        """Set with monitoring"""
        start_time = time.time()
        
        try:
            await self.cache.set(key, value, ttl)
        except Exception as e:
            self.metrics.record_error(
                self.cache_type,
                type(e).__name__
            )
            raise
        finally:
            duration = time.time() - start_time
            self.metrics.record_operation(
                self.cache_type,
                "set",
                duration
            )

# Cache health checks
class CacheHealthCheck:
    """Cache health monitoring"""
    
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    async def check_health(self) -> dict:
        """Comprehensive health check"""
        health_status = {
            "status": "healthy",
            "checks": {},
            "metrics": {}
        }
        
        # Check Redis connectivity
        try:
            self.redis.ping()
            health_status["checks"]["redis_connection"] = "ok"
        except Exception as e:
            health_status["status"] = "unhealthy"
            health_status["checks"]["redis_connection"] = str(e)
        
        # Check Redis memory
        try:
            info = self.redis.info("memory")
            used_memory = info["used_memory"]
            max_memory = info.get("maxmemory", 0)
            
            health_status["metrics"]["memory_used"] = used_memory
            health_status["metrics"]["memory_max"] = max_memory
            
            if max_memory > 0:
                usage_percent = (used_memory / max_memory) * 100
                health_status["metrics"]["memory_usage_percent"] = usage_percent
                
                if usage_percent > 90:
                    health_status["status"] = "warning"
                    health_status["checks"]["memory_usage"] = "high"
                
        except Exception as e:
            health_status["checks"]["memory_check"] = str(e)
        
        # Check hit rate
        try:
            stats = self.redis.info("stats")
            hits = stats.get("keyspace_hits", 0)
            misses = stats.get("keyspace_misses", 0)
            
            if hits + misses > 0:
                hit_rate = (hits / (hits + misses)) * 100
                health_status["metrics"]["hit_rate"] = hit_rate
                
                if hit_rate < 50:
                    health_status["status"] = "warning"
                    health_status["checks"]["hit_rate"] = "low"
                    
        except Exception as e:
            health_status["checks"]["stats_check"] = str(e)
        
        return health_status
```

## 🚀 Best Practices

### 1. **Cache Strategy Selection**
- Use cache-aside for read-heavy workloads
- Use write-through for data consistency
- Use write-behind for write performance
- Use refresh-ahead for predictable access patterns
- Consider multi-level caching for hot data

### 2. **Cache Key Design**
- Use consistent naming conventions
- Include version in keys when needed
- Keep keys short but descriptive
- Use namespaces to organize keys
- Consider key expiration patterns

### 3. **TTL Management**
- Set appropriate TTLs based on data volatility
- Use longer TTLs for static content
- Implement TTL randomization to avoid thundering herd
- Monitor and adjust TTLs based on usage patterns
- Consider sliding expiration for active data

### 4. **Cache Warming**
- Preload critical data on startup
- Use background jobs for cache warming
- Implement gradual cache warming
- Monitor cache warming performance
- Avoid overwhelming the database

### 5. **Monitoring & Observability**
- Track hit/miss ratios
- Monitor cache latency
- Alert on high eviction rates
- Monitor memory usage
- Log cache errors

### 6. **Cache Invalidation**
- Use event-driven invalidation
- Implement cascade invalidation carefully
- Consider versioned caching
- Use cache tags for group invalidation
- Monitor invalidation patterns

## 📖 Resources & References

### Documentation
- [Redis Documentation](https://redis.io/documentation)
- [Memcached Wiki](https://github.com/memcached/memcached/wiki)
- [Cloudflare Cache Docs](https://developers.cloudflare.com/cache/)
- [AWS ElastiCache Guide](https://docs.aws.amazon.com/elasticache/)

### Books & Articles
- "Designing Data-Intensive Applications" by Martin Kleppmann
- "High Performance Browser Networking" by Ilya Grigorik
- [Facebook's Memcached Paper](https://www.usenix.org/system/files/conference/nsdi13/nsdi13-final170_update.pdf)
- [Google's Bigtable Paper](https://static.googleusercontent.com/media/research.google.com/en//archive/bigtable-osdi06.pdf)

### Tools
- **Cache Servers** - Redis, Memcached, Hazelcast
- **CDN Providers** - Cloudflare, Fastly, Akamai
- **Monitoring** - Prometheus, Grafana, DataDog
- **Testing** - Redis Memory Analyzer, redis-cli

---

*This guide covers essential caching strategies for building high-performance applications. Remember that caching is not a silver bullet - use it wisely and monitor its effectiveness.*
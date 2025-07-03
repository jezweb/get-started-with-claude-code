# Python Performance Optimization for Web Applications

## Overview
This guide covers Python performance optimization techniques specifically focused on web application development, including FastAPI optimization, async performance, memory management, and profiling strategies.

## Profiling and Benchmarking

### Built-in Profiling Tools
```python
import cProfile
import pstats
import time
import asyncio
from functools import wraps
from typing import Any, Callable, Dict, List
from memory_profiler import profile
import tracemalloc

# Basic timing decorator
def time_it(func: Callable) -> Callable:
    """Simple timing decorator."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        end = time.perf_counter()
        print(f"{func.__name__} took {end - start:.4f} seconds")
        return result
    return wrapper

# Async timing decorator
def async_time_it(func: Callable) -> Callable:
    """Async timing decorator."""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = await func(*args, **kwargs)
        end = time.perf_counter()
        print(f"{func.__name__} took {end - start:.4f} seconds")
        return result
    return wrapper

# Comprehensive profiling decorator
def profile_performance(func: Callable) -> Callable:
    """Profile function performance with cProfile."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        profiler = cProfile.Profile()
        profiler.enable()
        
        try:
            result = func(*args, **kwargs)
        finally:
            profiler.disable()
            
            # Print stats
            stats = pstats.Stats(profiler)
            stats.sort_stats('cumulative')
            stats.print_stats(10)  # Top 10 functions
            
        return result
    return wrapper

# Memory profiling
def memory_profile_function(func: Callable) -> Callable:
    """Profile memory usage of function."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        tracemalloc.start()
        
        result = func(*args, **kwargs)
        
        current, peak = tracemalloc.get_traced_memory()
        print(f"{func.__name__} - Current memory: {current / 1024 / 1024:.2f} MB")
        print(f"{func.__name__} - Peak memory: {peak / 1024 / 1024:.2f} MB")
        
        tracemalloc.stop()
        return result
    return wrapper

# Usage examples
@time_it
def slow_function():
    """Example slow function."""
    time.sleep(1)
    return sum(range(1000000))

@async_time_it
async def async_slow_function():
    """Example async slow function."""
    await asyncio.sleep(1)
    return sum(range(1000000))

@memory_profile_function
def memory_intensive_function():
    """Example memory-intensive function."""
    large_list = [i for i in range(1000000)]
    return len(large_list)
```

### Advanced Profiling for Web Applications
```python
import asyncio
import time
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from collections import defaultdict
import json

@dataclass
class PerformanceMetrics:
    """Performance metrics collection."""
    function_name: str
    start_time: float
    end_time: float
    memory_before: int
    memory_after: int
    cpu_time: float
    
    @property
    def duration(self) -> float:
        return self.end_time - self.start_time
    
    @property
    def memory_delta(self) -> int:
        return self.memory_after - self.memory_before

class PerformanceMonitor:
    """Comprehensive performance monitoring for web applications."""
    
    def __init__(self):
        self.metrics: List[PerformanceMetrics] = []
        self.aggregated_stats: Dict[str, Dict[str, Any]] = defaultdict(dict)
    
    def start_monitoring(self):
        """Start system-wide performance monitoring."""
        tracemalloc.start()
    
    def stop_monitoring(self):
        """Stop monitoring and generate report."""
        tracemalloc.stop()
        return self.generate_report()
    
    def monitor_function(self, func: Callable) -> Callable:
        """Decorator to monitor function performance."""
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            start_time = time.perf_counter()
            memory_before = tracemalloc.get_traced_memory()[0]
            cpu_start = time.process_time()
            
            try:
                result = func(*args, **kwargs)
            finally:
                end_time = time.perf_counter()
                memory_after = tracemalloc.get_traced_memory()[0]
                cpu_end = time.process_time()
                
                metrics = PerformanceMetrics(
                    function_name=func.__name__,
                    start_time=start_time,
                    end_time=end_time,
                    memory_before=memory_before,
                    memory_after=memory_after,
                    cpu_time=cpu_end - cpu_start
                )
                
                self.metrics.append(metrics)
                self._update_aggregated_stats(metrics)
            
            return result
        
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            start_time = time.perf_counter()
            memory_before = tracemalloc.get_traced_memory()[0]
            cpu_start = time.process_time()
            
            try:
                result = await func(*args, **kwargs)
            finally:
                end_time = time.perf_counter()
                memory_after = tracemalloc.get_traced_memory()[0]
                cpu_end = time.process_time()
                
                metrics = PerformanceMetrics(
                    function_name=func.__name__,
                    start_time=start_time,
                    end_time=end_time,
                    memory_before=memory_before,
                    memory_after=memory_after,
                    cpu_time=cpu_end - cpu_start
                )
                
                self.metrics.append(metrics)
                self._update_aggregated_stats(metrics)
            
            return result
        
        return async_wrapper if asyncio.iscoroutinefunction(func) else sync_wrapper
    
    def _update_aggregated_stats(self, metrics: PerformanceMetrics):
        """Update aggregated statistics."""
        func_name = metrics.function_name
        stats = self.aggregated_stats[func_name]
        
        if 'count' not in stats:
            stats.update({
                'count': 0,
                'total_duration': 0,
                'total_memory': 0,
                'max_duration': 0,
                'min_duration': float('inf'),
                'max_memory': 0
            })
        
        stats['count'] += 1
        stats['total_duration'] += metrics.duration
        stats['total_memory'] += metrics.memory_delta
        stats['max_duration'] = max(stats['max_duration'], metrics.duration)
        stats['min_duration'] = min(stats['min_duration'], metrics.duration)
        stats['max_memory'] = max(stats['max_memory'], metrics.memory_delta)
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate performance report."""
        report = {
            'summary': {
                'total_functions_monitored': len(self.aggregated_stats),
                'total_function_calls': sum(stats['count'] for stats in self.aggregated_stats.values()),
                'total_execution_time': sum(stats['total_duration'] for stats in self.aggregated_stats.values())
            },
            'function_stats': {}
        }
        
        for func_name, stats in self.aggregated_stats.items():
            if stats['count'] > 0:
                report['function_stats'][func_name] = {
                    'call_count': stats['count'],
                    'avg_duration': stats['total_duration'] / stats['count'],
                    'max_duration': stats['max_duration'],
                    'min_duration': stats['min_duration'],
                    'total_duration': stats['total_duration'],
                    'avg_memory_delta': stats['total_memory'] / stats['count'],
                    'max_memory_delta': stats['max_memory']
                }
        
        return report

# Global performance monitor
perf_monitor = PerformanceMonitor()

# Usage in web applications
@perf_monitor.monitor_function
async def database_query(query: str) -> List[Dict[str, Any]]:
    """Example database query function."""
    await asyncio.sleep(0.1)  # Simulate query time
    return [{"id": i, "data": f"item_{i}"} for i in range(100)]

@perf_monitor.monitor_function
def data_processing(data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Example data processing function."""
    return [
        {**item, "processed": True, "timestamp": time.time()}
        for item in data
    ]
```

## Memory Optimization

### Memory-Efficient Data Structures
```python
import sys
from typing import Any, List, Dict, Set, Iterator
from collections import deque, defaultdict
import array
from dataclasses import dataclass

# Memory-efficient alternatives
class MemoryEfficientStorage:
    """Demonstrate memory-efficient storage patterns."""
    
    def __init__(self):
        # Use array for numeric data instead of list
        self.numeric_data = array.array('i')  # Integer array
        
        # Use deque for queue operations
        self.queue_data = deque(maxlen=1000)  # Fixed-size queue
        
        # Use sets for membership testing
        self.lookup_set: Set[str] = set()
        
        # Use defaultdict to avoid key checking
        self.counters = defaultdict(int)
        
        # Use generators for large datasets
        self.large_dataset = self._generate_data()
    
    def _generate_data(self) -> Iterator[Dict[str, Any]]:
        """Generator for memory-efficient iteration."""
        for i in range(1000000):
            yield {"id": i, "value": i * 2}
    
    def add_numeric(self, value: int):
        """Add numeric value efficiently."""
        self.numeric_data.append(value)
    
    def add_to_queue(self, item: Any):
        """Add item to fixed-size queue."""
        self.queue_data.append(item)
    
    def check_membership(self, item: str) -> bool:
        """Fast membership checking."""
        return item in self.lookup_set
    
    def increment_counter(self, key: str):
        """Increment counter without key checking."""
        self.counters[key] += 1
    
    def process_large_dataset(self) -> int:
        """Process large dataset without loading all into memory."""
        total = 0
        for item in self.large_dataset:
            total += item["value"]
            if total > 1000000:  # Early termination
                break
        return total

# __slots__ for memory efficiency
@dataclass
class EfficientUser:
    """Memory-efficient user class."""
    __slots__ = ('id', 'name', 'email', 'is_active')
    
    id: int
    name: str
    email: str
    is_active: bool = True

class RegularUser:
    """Regular user class for comparison."""
    def __init__(self, id: int, name: str, email: str, is_active: bool = True):
        self.id = id
        self.name = name
        self.email = email
        self.is_active = is_active

# Memory usage comparison
def compare_memory_usage():
    """Compare memory usage of different approaches."""
    # Test with 10,000 users
    n_users = 10000
    
    # Regular users
    regular_users = [
        RegularUser(i, f"User {i}", f"user{i}@example.com")
        for i in range(n_users)
    ]
    
    # Efficient users
    efficient_users = [
        EfficientUser(i, f"User {i}", f"user{i}@example.com")
        for i in range(n_users)
    ]
    
    print(f"Regular users memory: {sys.getsizeof(regular_users[0])} bytes per object")
    print(f"Efficient users memory: {sys.getsizeof(efficient_users[0])} bytes per object")

# String interning for memory savings
class StringOptimizer:
    """Optimize string memory usage."""
    
    def __init__(self):
        self._string_cache: Dict[str, str] = {}
    
    def intern_string(self, s: str) -> str:
        """Intern string to save memory."""
        if s not in self._string_cache:
            self._string_cache[s] = sys.intern(s)
        return self._string_cache[s]
    
    def optimize_repeated_strings(self, data: List[Dict[str, str]]) -> List[Dict[str, str]]:
        """Optimize repeated strings in data."""
        optimized_data = []
        for item in data:
            optimized_item = {
                key: self.intern_string(value) if isinstance(value, str) else value
                for key, value in item.items()
            }
            optimized_data.append(optimized_item)
        return optimized_data

# Lazy loading patterns
class LazyDataLoader:
    """Lazy loading for memory efficiency."""
    
    def __init__(self, data_source: str):
        self.data_source = data_source
        self._cache: Dict[str, Any] = {}
        self._loaded_chunks: Set[int] = set()
    
    def get_chunk(self, chunk_id: int) -> List[Dict[str, Any]]:
        """Load data chunk on demand."""
        if chunk_id not in self._loaded_chunks:
            # Simulate loading chunk from storage
            chunk_data = self._load_chunk_from_source(chunk_id)
            self._cache[f"chunk_{chunk_id}"] = chunk_data
            self._loaded_chunks.add(chunk_id)
        
        return self._cache[f"chunk_{chunk_id}"]
    
    def _load_chunk_from_source(self, chunk_id: int) -> List[Dict[str, Any]]:
        """Simulate loading chunk from external source."""
        # In real implementation, this would load from database, file, etc.
        return [
            {"id": chunk_id * 100 + i, "data": f"item_{i}"}
            for i in range(100)
        ]
    
    def clear_cache(self):
        """Clear cache to free memory."""
        self._cache.clear()
        self._loaded_chunks.clear()
```

### Memory Profiling and Monitoring
```python
import psutil
import gc
from typing import Dict, Any, Optional
import weakref

class MemoryMonitor:
    """Monitor memory usage in web applications."""
    
    def __init__(self):
        self.process = psutil.Process()
        self.baseline_memory = self.get_memory_usage()
    
    def get_memory_usage(self) -> Dict[str, float]:
        """Get current memory usage."""
        memory_info = self.process.memory_info()
        return {
            "rss": memory_info.rss / 1024 / 1024,  # MB
            "vms": memory_info.vms / 1024 / 1024,  # MB
            "percent": self.process.memory_percent()
        }
    
    def get_memory_delta(self) -> Dict[str, float]:
        """Get memory usage delta from baseline."""
        current = self.get_memory_usage()
        return {
            key: current[key] - self.baseline_memory[key]
            for key in current
        }
    
    def force_garbage_collection(self) -> Dict[str, int]:
        """Force garbage collection and return stats."""
        before_objects = len(gc.get_objects())
        collected = gc.collect()
        after_objects = len(gc.get_objects())
        
        return {
            "objects_before": before_objects,
            "objects_after": after_objects,
            "objects_collected": collected,
            "objects_freed": before_objects - after_objects
        }
    
    def get_largest_objects(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get largest objects in memory."""
        objects = gc.get_objects()
        object_sizes = [
            {
                "type": type(obj).__name__,
                "size": sys.getsizeof(obj),
                "id": id(obj)
            }
            for obj in objects
        ]
        
        return sorted(object_sizes, key=lambda x: x["size"], reverse=True)[:limit]

# Weak reference patterns for memory management
class CacheWithWeakRefs:
    """Cache using weak references to prevent memory leaks."""
    
    def __init__(self):
        self._cache: weakref.WeakValueDictionary = weakref.WeakValueDictionary()
        self._stats = {"hits": 0, "misses": 0, "evictions": 0}
    
    def get(self, key: str) -> Optional[Any]:
        """Get item from cache."""
        item = self._cache.get(key)
        if item is not None:
            self._stats["hits"] += 1
            return item
        else:
            self._stats["misses"] += 1
            return None
    
    def set(self, key: str, value: Any):
        """Set item in cache."""
        # Only store objects that can be weakly referenced
        try:
            self._cache[key] = value
        except TypeError:
            # Object cannot be weakly referenced
            pass
    
    def get_stats(self) -> Dict[str, int]:
        """Get cache statistics."""
        return {
            **self._stats,
            "size": len(self._cache)
        }

# Object pooling for memory efficiency
class ObjectPool:
    """Object pool for memory-efficient object reuse."""
    
    def __init__(self, factory_func: Callable, max_size: int = 100):
        self.factory_func = factory_func
        self.max_size = max_size
        self._pool: List[Any] = []
        self._in_use: Set[int] = set()
    
    def acquire(self) -> Any:
        """Acquire object from pool."""
        if self._pool:
            obj = self._pool.pop()
        else:
            obj = self.factory_func()
        
        self._in_use.add(id(obj))
        return obj
    
    def release(self, obj: Any):
        """Release object back to pool."""
        obj_id = id(obj)
        if obj_id in self._in_use:
            self._in_use.remove(obj_id)
            
            # Reset object state if needed
            if hasattr(obj, 'reset'):
                obj.reset()
            
            # Add back to pool if not at capacity
            if len(self._pool) < self.max_size:
                self._pool.append(obj)
    
    def get_stats(self) -> Dict[str, int]:
        """Get pool statistics."""
        return {
            "pool_size": len(self._pool),
            "in_use": len(self._in_use),
            "max_size": self.max_size
        }

# Usage example
def create_user_object():
    """Factory function for user objects."""
    return {"id": None, "name": None, "email": None, "data": []}

user_pool = ObjectPool(create_user_object, max_size=50)
```

## Algorithm and Data Structure Optimization

### Efficient Algorithms for Web Applications
```python
import bisect
from typing import List, Dict, Any, Optional, Tuple
from collections import Counter, defaultdict
import heapq

class OptimizedSearchEngine:
    """Optimized search functionality for web applications."""
    
    def __init__(self):
        self.documents: Dict[int, Dict[str, Any]] = {}
        self.inverted_index: Dict[str, List[int]] = defaultdict(list)
        self.sorted_doc_ids: List[int] = []
    
    def add_document(self, doc_id: int, content: Dict[str, Any]):
        """Add document with optimized indexing."""
        self.documents[doc_id] = content
        
        # Update inverted index
        text_content = str(content.get("title", "")) + " " + str(content.get("body", ""))
        words = text_content.lower().split()
        
        for word in words:
            if doc_id not in self.inverted_index[word]:
                # Use binary search for insertion
                bisect.insort(self.inverted_index[word], doc_id)
        
        # Maintain sorted document IDs
        bisect.insort(self.sorted_doc_ids, doc_id)
    
    def search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Optimized text search."""
        query_words = query.lower().split()
        
        if not query_words:
            return []
        
        # Find intersection of document sets for each word
        result_sets = [set(self.inverted_index[word]) for word in query_words]
        
        if not result_sets:
            return []
        
        # Intersection of all sets
        matching_docs = set.intersection(*result_sets)
        
        # Score and sort results
        scored_results = []
        for doc_id in matching_docs:
            score = self._calculate_relevance_score(doc_id, query_words)
            scored_results.append((score, doc_id))
        
        # Sort by score (descending) and limit results
        scored_results.sort(reverse=True)
        
        return [
            self.documents[doc_id]
            for _, doc_id in scored_results[:limit]
        ]
    
    def _calculate_relevance_score(self, doc_id: int, query_words: List[str]) -> float:
        """Calculate relevance score for document."""
        doc = self.documents[doc_id]
        text_content = str(doc.get("title", "")) + " " + str(doc.get("body", ""))
        words = text_content.lower().split()
        word_counts = Counter(words)
        
        score = 0.0
        for query_word in query_words:
            # TF (term frequency)
            tf = word_counts.get(query_word, 0) / len(words) if words else 0
            
            # IDF (inverse document frequency) - simplified
            docs_with_word = len(self.inverted_index[query_word])
            idf = len(self.documents) / (docs_with_word + 1)
            
            score += tf * idf
        
        return score

class OptimizedCache:
    """LRU Cache with optimized operations."""
    
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache: Dict[str, Any] = {}
        self.access_order: List[str] = []
        self.access_positions: Dict[str, int] = {}
    
    def get(self, key: str) -> Optional[Any]:
        """Get value with O(1) access time."""
        if key not in self.cache:
            return None
        
        # Update access order efficiently
        self._update_access_order(key)
        return self.cache[key]
    
    def set(self, key: str, value: Any):
        """Set value with efficient eviction."""
        if key in self.cache:
            self.cache[key] = value
            self._update_access_order(key)
            return
        
        # Check capacity
        if len(self.cache) >= self.capacity:
            self._evict_lru()
        
        # Add new item
        self.cache[key] = value
        self.access_order.append(key)
        self.access_positions[key] = len(self.access_order) - 1
    
    def _update_access_order(self, key: str):
        """Update access order efficiently."""
        # Remove from current position
        current_pos = self.access_positions[key]
        self.access_order.pop(current_pos)
        
        # Update positions for items after the removed item
        for i in range(current_pos, len(self.access_order)):
            self.access_positions[self.access_order[i]] = i
        
        # Add to end
        self.access_order.append(key)
        self.access_positions[key] = len(self.access_order) - 1
    
    def _evict_lru(self):
        """Evict least recently used item."""
        if self.access_order:
            lru_key = self.access_order.pop(0)
            del self.cache[lru_key]
            del self.access_positions[lru_key]
            
            # Update positions
            for i, key in enumerate(self.access_order):
                self.access_positions[key] = i

class PriorityTaskQueue:
    """Optimized priority queue for task processing."""
    
    def __init__(self):
        self.heap: List[Tuple[int, int, Dict[str, Any]]] = []
        self.counter = 0  # For stable sorting
        self.task_index: Dict[str, int] = {}
    
    def add_task(self, priority: int, task_id: str, task_data: Dict[str, Any]):
        """Add task with priority."""
        if task_id in self.task_index:
            # Update existing task
            self.remove_task(task_id)
        
        entry = (priority, self.counter, {"id": task_id, **task_data})
        heapq.heappush(self.heap, entry)
        self.task_index[task_id] = self.counter
        self.counter += 1
    
    def get_next_task(self) -> Optional[Dict[str, Any]]:
        """Get highest priority task."""
        while self.heap:
            priority, counter, task_data = heapq.heappop(self.heap)
            task_id = task_data["id"]
            
            if task_id in self.task_index and self.task_index[task_id] == counter:
                del self.task_index[task_id]
                return task_data
        
        return None
    
    def remove_task(self, task_id: str) -> bool:
        """Remove task by ID."""
        if task_id in self.task_index:
            # Mark as removed (lazy deletion)
            del self.task_index[task_id]
            return True
        return False
    
    def peek_next(self) -> Optional[Dict[str, Any]]:
        """Peek at next task without removing."""
        while self.heap:
            priority, counter, task_data = self.heap[0]
            task_id = task_data["id"]
            
            if task_id in self.task_index and self.task_index[task_id] == counter:
                return task_data
            else:
                # Remove stale entry
                heapq.heappop(self.heap)
        
        return None
    
    def size(self) -> int:
        """Get number of active tasks."""
        return len(self.task_index)

# Efficient batch operations
class BatchProcessor:
    """Optimized batch processing for large datasets."""
    
    @staticmethod
    def batch_update_optimized(
        items: List[Dict[str, Any]], 
        update_func: Callable[[Dict[str, Any]], Dict[str, Any]],
        batch_size: int = 1000
    ) -> List[Dict[str, Any]]:
        """Process items in optimized batches."""
        results = []
        
        for i in range(0, len(items), batch_size):
            batch = items[i:i + batch_size]
            
            # Process batch
            batch_results = [update_func(item) for item in batch]
            results.extend(batch_results)
            
            # Yield control periodically for web applications
            if i % (batch_size * 10) == 0:
                import asyncio
                if asyncio.iscoroutinefunction(update_func):
                    asyncio.sleep(0)  # Yield control
        
        return results
    
    @staticmethod
    def group_by_optimized(
        items: List[Dict[str, Any]], 
        key_func: Callable[[Dict[str, Any]], str]
    ) -> Dict[str, List[Dict[str, Any]]]:
        """Optimized grouping operation."""
        groups = defaultdict(list)
        
        for item in items:
            key = key_func(item)
            groups[key].append(item)
        
        return dict(groups)
    
    @staticmethod
    def merge_sorted_lists(
        lists: List[List[Dict[str, Any]]], 
        key_func: Callable[[Dict[str, Any]], Any]
    ) -> List[Dict[str, Any]]:
        """Merge multiple sorted lists efficiently."""
        # Use heap for efficient merging
        heap = []
        result = []
        
        # Initialize heap with first element from each list
        for i, lst in enumerate(lists):
            if lst:
                heapq.heappush(heap, (key_func(lst[0]), i, 0, lst[0]))
        
        while heap:
            key_val, list_idx, item_idx, item = heapq.heappop(heap)
            result.append(item)
            
            # Add next item from same list
            next_idx = item_idx + 1
            if next_idx < len(lists[list_idx]):
                next_item = lists[list_idx][next_idx]
                heapq.heappush(heap, (key_func(next_item), list_idx, next_idx, next_item))
        
        return result
```

## FastAPI Performance Optimization

### Request/Response Optimization
```python
from fastapi import FastAPI, Response, Request, Depends
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import gzip
from typing import Any, Dict, List, Optional
import time

app = FastAPI()

# Add compression middleware
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Optimized JSON response class
class OptimizedJSONResponse(JSONResponse):
    """Optimized JSON response with custom encoding."""
    
    def render(self, content: Any) -> bytes:
        """Custom JSON rendering with optimizations."""
        return json.dumps(
            content,
            ensure_ascii=False,
            allow_nan=False,
            indent=None,
            separators=(',', ':'),  # Compact separators
            default=self._json_encoder
        ).encode('utf-8')
    
    def _json_encoder(self, obj):
        """Custom JSON encoder for common types."""
        if isinstance(obj, datetime):
            return obj.isoformat()
        elif isinstance(obj, set):
            return list(obj)
        elif hasattr(obj, 'dict'):
            return obj.dict()
        raise TypeError(f"Object of type {type(obj)} is not JSON serializable")

# Response caching middleware
class ResponseCacheMiddleware:
    """Middleware for response caching."""
    
    def __init__(self, app, cache_ttl: int = 300):
        self.app = app
        self.cache: Dict[str, Tuple[bytes, float]] = {}
        self.cache_ttl = cache_ttl
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        request = Request(scope, receive)
        cache_key = self._generate_cache_key(request)
        
        # Check cache
        cached_response = self._get_cached_response(cache_key)
        if cached_response:
            response = Response(
                content=cached_response,
                media_type="application/json"
            )
            await response(scope, receive, send)
            return
        
        # Capture response
        response_body = b""
        
        async def send_wrapper(message):
            nonlocal response_body
            if message["type"] == "http.response.body":
                response_body += message.get("body", b"")
            await send(message)
        
        await self.app(scope, receive, send_wrapper)
        
        # Cache response
        if response_body:
            self._cache_response(cache_key, response_body)
    
    def _generate_cache_key(self, request: Request) -> str:
        """Generate cache key for request."""
        return f"{request.method}:{request.url.path}:{hash(str(request.query_params))}"
    
    def _get_cached_response(self, cache_key: str) -> Optional[bytes]:
        """Get cached response if valid."""
        if cache_key in self.cache:
            response, timestamp = self.cache[cache_key]
            if time.time() - timestamp < self.cache_ttl:
                return response
            else:
                del self.cache[cache_key]
        return None
    
    def _cache_response(self, cache_key: str, response: bytes):
        """Cache response with timestamp."""
        self.cache[cache_key] = (response, time.time())

# Add cache middleware
app.add_middleware(ResponseCacheMiddleware, cache_ttl=300)

# Optimized dependency injection
class FastDependencies:
    """Optimized dependency injection."""
    
    def __init__(self):
        self._connection_pool = None
        self._cache_pool = None
    
    async def get_db_connection(self):
        """Get database connection from pool."""
        if not self._connection_pool:
            # Initialize connection pool lazily
            import asyncpg
            self._connection_pool = await asyncpg.create_pool(
                "postgresql://user:pass@localhost/db",
                min_size=5,
                max_size=20
            )
        
        async with self._connection_pool.acquire() as conn:
            yield conn
    
    async def get_cache_connection(self):
        """Get cache connection from pool."""
        if not self._cache_pool:
            import aioredis
            self._cache_pool = await aioredis.create_redis_pool(
                "redis://localhost",
                minsize=5,
                maxsize=20
            )
        
        return self._cache_pool

fast_deps = FastDependencies()

# Optimized endpoints
@app.get("/users/{user_id}", response_class=OptimizedJSONResponse)
async def get_user_optimized(
    user_id: int,
    db=Depends(fast_deps.get_db_connection),
    cache=Depends(fast_deps.get_cache_connection)
):
    """Optimized user retrieval with caching."""
    # Check cache first
    cache_key = f"user:{user_id}"
    cached_user = await cache.get(cache_key)
    
    if cached_user:
        return json.loads(cached_user)
    
    # Query database
    user = await db.fetchrow(
        "SELECT id, name, email, created_at FROM users WHERE id = $1",
        user_id
    )
    
    if not user:
        return {"error": "User not found"}
    
    user_data = dict(user)
    
    # Cache result
    await cache.setex(cache_key, 300, json.dumps(user_data, default=str))
    
    return user_data

# Streaming response for large datasets
@app.get("/users/export")
async def export_users_stream(
    db=Depends(fast_deps.get_db_connection)
):
    """Stream large user export."""
    
    async def generate_user_csv():
        """Generate CSV data on-the-fly."""
        yield "id,name,email,created_at\n"
        
        async for record in db.cursor("SELECT id, name, email, created_at FROM users"):
            csv_line = f"{record['id']},{record['name']},{record['email']},{record['created_at']}\n"
            yield csv_line.encode('utf-8')
    
    return StreamingResponse(
        generate_user_csv(),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users.csv"}
    )

# Batch operations endpoint
@app.post("/users/batch")
async def create_users_batch(
    users: List[Dict[str, Any]],
    db=Depends(fast_deps.get_db_connection)
):
    """Optimized batch user creation."""
    if len(users) > 1000:
        return {"error": "Batch size too large"}
    
    # Validate all users first
    valid_users = []
    errors = []
    
    for i, user_data in enumerate(users):
        try:
            # Quick validation
            if not user_data.get("name") or not user_data.get("email"):
                errors.append(f"User {i}: Missing required fields")
                continue
            valid_users.append(user_data)
        except Exception as e:
            errors.append(f"User {i}: {str(e)}")
    
    if errors:
        return {"errors": errors}
    
    # Batch insert
    try:
        query = """
            INSERT INTO users (name, email, created_at)
            VALUES ($1, $2, NOW())
            RETURNING id
        """
        
        user_ids = []
        async with db.transaction():
            for user_data in valid_users:
                user_id = await db.fetchval(
                    query,
                    user_data["name"],
                    user_data["email"]
                )
                user_ids.append(user_id)
        
        return {
            "created": len(user_ids),
            "user_ids": user_ids
        }
    
    except Exception as e:
        return {"error": f"Batch insert failed: {str(e)}"}

# Background task optimization
from fastapi import BackgroundTasks
import asyncio

class OptimizedBackgroundTasks:
    """Optimized background task processor."""
    
    def __init__(self, max_concurrent: int = 10):
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.task_queue = asyncio.Queue()
        self.workers_started = False
    
    async def add_task(self, coro):
        """Add task to background processing."""
        await self.task_queue.put(coro)
        
        if not self.workers_started:
            # Start workers lazily
            for _ in range(3):
                asyncio.create_task(self._worker())
            self.workers_started = True
    
    async def _worker(self):
        """Background task worker."""
        while True:
            try:
                task = await self.task_queue.get()
                async with self.semaphore:
                    await task
                self.task_queue.task_done()
            except Exception as e:
                print(f"Background task error: {e}")

optimized_bg_tasks = OptimizedBackgroundTasks()

@app.post("/users/{user_id}/send-email")
async def send_email_background(user_id: int):
    """Send email in background with optimization."""
    
    async def email_task():
        # Simulate email sending
        await asyncio.sleep(2)
        print(f"Email sent to user {user_id}")
    
    await optimized_bg_tasks.add_task(email_task())
    
    return {"message": "Email queued for sending"}
```

## Database Performance

### Query Optimization
```python
import asyncio
import asyncpg
from typing import List, Dict, Any, Optional, Tuple
import time

class OptimizedDatabase:
    """Optimized database operations for web applications."""
    
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.pool: Optional[asyncpg.Pool] = None
        self.query_cache: Dict[str, str] = {}
    
    async def initialize(self):
        """Initialize connection pool."""
        self.pool = await asyncpg.create_pool(
            self.connection_string,
            min_size=5,
            max_size=20,
            max_queries=50000,
            max_inactive_connection_lifetime=300,
            command_timeout=60
        )
    
    async def execute_optimized_query(
        self,
        query: str,
        *args,
        prepare: bool = True
    ) -> List[Dict[str, Any]]:
        """Execute query with optimization."""
        async with self.pool.acquire() as conn:
            if prepare:
                # Use prepared statements for better performance
                stmt = await conn.prepare(query)
                rows = await stmt.fetch(*args)
            else:
                rows = await conn.fetch(query, *args)
            
            return [dict(row) for row in rows]
    
    async def batch_insert_optimized(
        self,
        table: str,
        columns: List[str],
        data: List[Tuple],
        batch_size: int = 1000
    ) -> int:
        """Optimized batch insert."""
        if not data:
            return 0
        
        placeholders = ", ".join(f"${i+1}" for i in range(len(columns)))
        query = f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})"
        
        total_inserted = 0
        
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                # Process in batches
                for i in range(0, len(data), batch_size):
                    batch = data[i:i + batch_size]
                    
                    # Use executemany for batch operations
                    await conn.executemany(query, batch)
                    total_inserted += len(batch)
        
        return total_inserted
    
    async def paginated_query(
        self,
        base_query: str,
        page: int,
        per_page: int,
        *args
    ) -> Tuple[List[Dict[str, Any]], int]:
        """Optimized paginated query."""
        # Calculate offset
        offset = (page - 1) * per_page
        
        # Count query (without LIMIT/OFFSET)
        count_query = f"SELECT COUNT(*) FROM ({base_query}) AS count_subquery"
        
        # Data query with pagination
        data_query = f"{base_query} LIMIT {per_page} OFFSET {offset}"
        
        async with self.pool.acquire() as conn:
            # Execute both queries concurrently
            count_task = conn.fetchval(count_query, *args)
            data_task = conn.fetch(data_query, *args)
            
            total_count, rows = await asyncio.gather(count_task, data_task)
        
        return [dict(row) for row in rows], total_count
    
    async def bulk_update_optimized(
        self,
        table: str,
        updates: List[Dict[str, Any]],
        key_column: str = "id"
    ) -> int:
        """Optimized bulk update."""
        if not updates:
            return 0
        
        # Build update query using VALUES clause
        columns = list(updates[0].keys())
        columns.remove(key_column)  # Remove key column from updates
        
        # Create temporary table approach for bulk updates
        temp_table = f"temp_update_{table}_{int(time.time() * 1000)}"
        
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                # Create temporary table
                create_temp = f"""
                    CREATE TEMP TABLE {temp_table} (
                        {key_column} INTEGER,
                        {', '.join(f"{col} TEXT" for col in columns)}
                    )
                """
                await conn.execute(create_temp)
                
                # Insert update data into temp table
                insert_query = f"""
                    INSERT INTO {temp_table} 
                    VALUES ($1, {', '.join(f'${i+2}' for i in range(len(columns)))})
                """
                
                update_data = [
                    tuple([update[key_column]] + [str(update[col]) for col in columns])
                    for update in updates
                ]
                
                await conn.executemany(insert_query, update_data)
                
                # Perform bulk update
                set_clauses = [
                    f"{col} = {temp_table}.{col}::TEXT"
                    for col in columns
                ]
                
                update_query = f"""
                    UPDATE {table}
                    SET {', '.join(set_clauses)}
                    FROM {temp_table}
                    WHERE {table}.{key_column} = {temp_table}.{key_column}
                """
                
                result = await conn.execute(update_query)
                
                # Extract number of updated rows
                return int(result.split()[-1])
    
    async def complex_aggregation_optimized(
        self,
        filters: Dict[str, Any],
        group_by: List[str],
        aggregations: Dict[str, str]
    ) -> List[Dict[str, Any]]:
        """Optimized complex aggregation query."""
        # Build WHERE clause
        where_conditions = []
        params = []
        param_count = 1
        
        for column, value in filters.items():
            if isinstance(value, list):
                placeholders = ', '.join(f'${param_count + i}' for i in range(len(value)))
                where_conditions.append(f"{column} IN ({placeholders})")
                params.extend(value)
                param_count += len(value)
            else:
                where_conditions.append(f"{column} = ${param_count}")
                params.append(value)
                param_count += 1
        
        where_clause = " AND ".join(where_conditions) if where_conditions else "TRUE"
        
        # Build aggregation clause
        agg_clauses = [
            f"{func}({column}) AS {alias}"
            for alias, (func, column) in aggregations.items()
        ]
        
        # Build final query
        query = f"""
            SELECT 
                {', '.join(group_by)},
                {', '.join(agg_clauses)}
            FROM users
            WHERE {where_clause}
            GROUP BY {', '.join(group_by)}
            ORDER BY {group_by[0] if group_by else '1'}
        """
        
        return await self.execute_optimized_query(query, *params)

# Connection pooling best practices
class DatabaseManager:
    """Database manager with optimized connection handling."""
    
    def __init__(self):
        self.pools: Dict[str, asyncpg.Pool] = {}
        self.connection_stats: Dict[str, Dict[str, int]] = {}
    
    async def get_pool(self, connection_string: str, pool_name: str = "default") -> asyncpg.Pool:
        """Get or create connection pool."""
        if pool_name not in self.pools:
            self.pools[pool_name] = await asyncpg.create_pool(
                connection_string,
                min_size=5,
                max_size=20,
                max_queries=50000,
                max_inactive_connection_lifetime=300,
                setup=self._setup_connection
            )
            self.connection_stats[pool_name] = {
                "queries_executed": 0,
                "connections_created": 0,
                "errors": 0
            }
        
        return self.pools[pool_name]
    
    async def _setup_connection(self, conn):
        """Setup connection with optimizations."""
        # Set connection-level optimizations
        await conn.execute("SET statement_timeout = '30s'")
        await conn.execute("SET lock_timeout = '10s'")
        await conn.execute("SET idle_in_transaction_session_timeout = '5min'")
        
        self.connection_stats.get("default", {})["connections_created"] += 1
    
    async def execute_with_retry(
        self,
        pool: asyncpg.Pool,
        query: str,
        *args,
        max_retries: int = 3
    ) -> List[Dict[str, Any]]:
        """Execute query with retry logic."""
        last_exception = None
        
        for attempt in range(max_retries):
            try:
                async with pool.acquire() as conn:
                    rows = await conn.fetch(query, *args)
                    self.connection_stats.get("default", {})["queries_executed"] += 1
                    return [dict(row) for row in rows]
            
            except (asyncpg.PostgresError, asyncio.TimeoutError) as e:
                last_exception = e
                self.connection_stats.get("default", {})["errors"] += 1
                
                if attempt < max_retries - 1:
                    # Exponential backoff
                    await asyncio.sleep(2 ** attempt)
                else:
                    raise last_exception
        
        raise last_exception
    
    async def close_all_pools(self):
        """Close all connection pools."""
        for pool in self.pools.values():
            await pool.close()
        self.pools.clear()
    
    def get_stats(self) -> Dict[str, Dict[str, int]]:
        """Get connection statistics."""
        return self.connection_stats.copy()
```

## Best Practices Summary

### Performance Optimization Checklist
1. **Profile before optimizing** - Use profiling tools to identify bottlenecks
2. **Optimize algorithms first** - Choose appropriate data structures and algorithms
3. **Use connection pooling** - For database and external service connections
4. **Implement caching strategically** - Cache expensive operations and frequently accessed data
5. **Optimize database queries** - Use indexes, prepared statements, and batch operations
6. **Use async/await properly** - For I/O-bound operations in web applications
7. **Monitor memory usage** - Prevent memory leaks and optimize memory allocation
8. **Implement proper error handling** - With retry logic and circuit breakers
9. **Use streaming for large responses** - Avoid loading large datasets into memory
10. **Optimize serialization** - Use efficient JSON encoding and compression

### FastAPI Specific Optimizations
1. **Use dependency injection caching** - Cache expensive dependencies
2. **Implement response compression** - Use GZip middleware for large responses
3. **Optimize JSON serialization** - Custom JSON encoders for better performance
4. **Use background tasks** - For non-critical operations
5. **Implement request/response caching** - For cacheable endpoints
6. **Use streaming responses** - For large data exports
7. **Optimize database connections** - Use connection pooling and prepared statements
8. **Monitor endpoint performance** - Track response times and error rates

---

**Last Updated:** Based on Python 3.10+ performance features and FastAPI optimization techniques
**References:**
- [Python Performance Documentation](https://docs.python.org/3/tutorial/brief_tour.html#performance-measurement)
- [FastAPI Performance](https://fastapi.tiangolo.com/advanced/async-tests/)
- [asyncpg Performance](https://magicstack.github.io/asyncpg/current/performance.html)
- [Python Profiling Guide](https://docs.python.org/3/library/profile.html)
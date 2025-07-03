# Pydantic v2 Production Patterns and Best Practices

## Overview

This guide covers production-ready patterns for Pydantic v2 applications, focusing on performance optimization, monitoring, deployment strategies, and best practices for high-scale applications. Learn how to leverage v2's performance improvements and new features for production environments.

## 🚀 Performance Optimization

### 1. Schema Build Optimization

**Pre-building Schemas**
```python
# utils/schema_cache.py
from pydantic import BaseModel
from typing import Dict, Type, Any
from functools import lru_cache
import json

class SchemaCache:
    """Centralized schema cache for production performance"""
    _schemas: Dict[str, Dict[str, Any]] = {}
    _models: Dict[str, Type[BaseModel]] = {}
    
    @classmethod
    def register_model(cls, name: str, model_class: Type[BaseModel]):
        """Register and pre-build model schema"""
        cls._models[name] = model_class
        
        # Pre-build schema (expensive operation done once)
        schema = model_class.model_json_schema()
        cls._schemas[name] = schema
        
        # Trigger any other expensive model operations
        try:
            # Pre-build validation core
            model_class.model_validate({})
        except:
            pass  # Expected to fail, but builds internal structures
    
    @classmethod
    def get_schema(cls, name: str) -> Dict[str, Any]:
        """Get cached schema"""
        return cls._schemas.get(name, {})
    
    @classmethod
    def get_model(cls, name: str) -> Type[BaseModel]:
        """Get registered model"""
        return cls._models.get(name)
    
    @classmethod
    def warmup_all(cls):
        """Warm up all registered models"""
        for name, model_class in cls._models.items():
            # Pre-validate with sample data to build caches
            try:
                sample_data = cls._generate_sample_data(model_class)
                model_class.model_validate(sample_data)
            except:
                pass
    
    @classmethod
    def _generate_sample_data(cls, model_class: Type[BaseModel]) -> Dict[str, Any]:
        """Generate sample data for warmup"""
        schema = model_class.model_json_schema()
        return cls._extract_defaults_from_schema(schema)
    
    @classmethod
    def _extract_defaults_from_schema(cls, schema: Dict[str, Any]) -> Dict[str, Any]:
        """Extract default values from schema"""
        defaults = {}
        properties = schema.get('properties', {})
        
        for field_name, field_schema in properties.items():
            if 'default' in field_schema:
                defaults[field_name] = field_schema['default']
            elif field_schema.get('type') == 'string':
                defaults[field_name] = "sample"
            elif field_schema.get('type') == 'integer':
                defaults[field_name] = 0
            elif field_schema.get('type') == 'boolean':
                defaults[field_name] = False
        
        return defaults

# Register models at startup
from models.user import UserResponse, UserCreateRequest
from models.product import ProductResponse, ProductCreateRequest

# Pre-register all models
SchemaCache.register_model('user_response', UserResponse)
SchemaCache.register_model('user_create', UserCreateRequest)
SchemaCache.register_model('product_response', ProductResponse)
SchemaCache.register_model('product_create', ProductCreateRequest)
```

### 2. Memory Optimization Patterns

**Model Factory Pattern**
```python
# utils/model_factory.py
from typing import TypeVar, Type, Dict, Any, Optional
from pydantic import BaseModel
from functools import lru_cache
import weakref

T = TypeVar('T', bound=BaseModel)

class ModelFactory:
    """Factory for creating optimized model instances"""
    
    # Weak reference cache to avoid memory leaks
    _instance_cache = weakref.WeakValueDictionary()
    _validation_cache = {}
    
    @classmethod
    @lru_cache(maxsize=1000)
    def create_validated(
        cls,
        model_class: Type[T],
        data_hash: str,
        **kwargs
    ) -> T:
        """Create model with caching for identical data"""
        # Use hash of data for cache key
        cache_key = f"{model_class.__name__}:{data_hash}"
        
        if cache_key in cls._instance_cache:
            return cls._instance_cache[cache_key]
        
        # Create new instance
        instance = model_class.model_validate(kwargs)
        cls._instance_cache[cache_key] = instance
        
        return instance
    
    @classmethod
    def create_batch(
        cls,
        model_class: Type[T],
        data_list: list[Dict[str, Any]]
    ) -> list[T]:
        """Optimized batch creation"""
        results = []
        
        # Pre-validate schema once
        schema = model_class.model_json_schema()
        
        for data in data_list:
            try:
                # Fast path for valid data
                instance = model_class.model_validate(data)
                results.append(instance)
            except Exception as e:
                # Handle validation errors
                print(f"Validation error for {data}: {e}")
                continue
        
        return results
    
    @classmethod
    def clear_cache(cls):
        """Clear caches for testing or memory management"""
        cls.create_validated.cache_clear()
        cls._validation_cache.clear()

# Usage example
def create_user_batch(users_data: list[Dict[str, Any]]) -> list[UserResponse]:
    """Create users efficiently"""
    return ModelFactory.create_batch(UserResponse, users_data)

# Hash utility for caching
import hashlib
import json

def hash_dict(data: Dict[str, Any]) -> str:
    """Create consistent hash for dictionary data"""
    json_str = json.dumps(data, sort_keys=True, default=str)
    return hashlib.md5(json_str.encode()).hexdigest()
```

### 3. Serialization Optimization

**High-Performance Serialization**
```python
# utils/serialization.py
from pydantic import BaseModel
from typing import Any, Dict, List, Union, Optional
import orjson  # Fast JSON library
from functools import lru_cache

class FastSerializer:
    """Optimized serialization utilities"""
    
    @staticmethod
    @lru_cache(maxsize=100)
    def get_serialization_schema(model_class: type[BaseModel]) -> Dict[str, Any]:
        """Cache serialization schemas"""
        return model_class.model_json_schema()
    
    @staticmethod
    def serialize_fast(
        obj: Union[BaseModel, List[BaseModel], Dict[str, Any]],
        exclude_none: bool = True,
        by_alias: bool = False
    ) -> bytes:
        """Fast JSON serialization using orjson"""
        
        if isinstance(obj, BaseModel):
            data = obj.model_dump(exclude_none=exclude_none, by_alias=by_alias)
        elif isinstance(obj, list) and obj and isinstance(obj[0], BaseModel):
            data = [item.model_dump(exclude_none=exclude_none, by_alias=by_alias) for item in obj]
        else:
            data = obj
        
        return orjson.dumps(
            data,
            option=orjson.OPT_UTC_Z | orjson.OPT_OMIT_MICROSECONDS
        )
    
    @staticmethod
    def serialize_bulk(
        objects: List[BaseModel],
        chunk_size: int = 1000
    ) -> List[bytes]:
        """Serialize large lists in chunks"""
        results = []
        
        for i in range(0, len(objects), chunk_size):
            chunk = objects[i:i + chunk_size]
            chunk_data = [obj.model_dump(exclude_none=True) for obj in chunk]
            results.append(orjson.dumps(chunk_data))
        
        return results

# Custom serialization context for different environments
class SerializationContext:
    """Context-aware serialization"""
    
    CONTEXTS = {
        'api_response': {
            'exclude_none': True,
            'by_alias': True,
            'exclude': {'password', 'internal_id'}
        },
        'database': {
            'exclude_none': False,
            'by_alias': False,
            'include': None
        },
        'cache': {
            'exclude_none': True,
            'by_alias': False,
            'exclude': {'computed_fields'}
        }
    }
    
    @classmethod
    def serialize(
        cls,
        obj: BaseModel,
        context: str = 'api_response'
    ) -> Dict[str, Any]:
        """Serialize with context-specific rules"""
        config = cls.CONTEXTS.get(context, cls.CONTEXTS['api_response'])
        return obj.model_dump(**config)

# Usage in FastAPI
from fastapi import Response

@app.get("/users/fast")
async def get_users_optimized():
    users = get_users_from_db()  # List[UserResponse]
    
    # Fast serialization
    json_bytes = FastSerializer.serialize_fast(users)
    
    return Response(
        content=json_bytes,
        media_type="application/json"
    )
```

## 📊 Monitoring and Observability

### 1. Pydantic Logfire Integration

**Structured Logging with Logfire**
```python
# utils/monitoring.py
import logfire
from pydantic import BaseModel
from typing import Any, Dict, Optional
from contextlib import contextmanager
from datetime import datetime
import time

# Configure Logfire
logfire.configure(
    service_name="pydantic-api",
    environment="production"
)

class ValidationMetrics(BaseModel):
    """Metrics for validation operations"""
    model_name: str
    validation_time_ms: float
    success: bool
    error_type: Optional[str] = None
    error_message: Optional[str] = None
    input_size_bytes: Optional[int] = None
    timestamp: datetime

class ModelMonitor:
    """Monitor Pydantic model performance"""
    
    @staticmethod
    @contextmanager
    def track_validation(model_class: type[BaseModel], input_data: Any):
        """Context manager to track validation performance"""
        start_time = time.time()
        success = True
        error_type = None
        error_message = None
        
        try:
            yield
        except Exception as e:
            success = False
            error_type = type(e).__name__
            error_message = str(e)
            raise
        finally:
            end_time = time.time()
            validation_time = (end_time - start_time) * 1000
            
            # Calculate input size
            input_size = len(str(input_data).encode('utf-8')) if input_data else 0
            
            # Create metrics
            metrics = ValidationMetrics(
                model_name=model_class.__name__,
                validation_time_ms=validation_time,
                success=success,
                error_type=error_type,
                error_message=error_message,
                input_size_bytes=input_size,
                timestamp=datetime.utcnow()
            )
            
            # Log to Logfire
            logfire.info(
                "Model validation",
                model=model_class.__name__,
                success=success,
                time_ms=validation_time,
                input_size=input_size,
                error=error_message
            )

# Instrumented model validation
def monitored_validate(model_class: type[BaseModel], data: Any):
    """Validate with monitoring"""
    with ModelMonitor.track_validation(model_class, data):
        return model_class.model_validate(data)

# Performance decorator
from functools import wraps

def monitor_model_operation(operation_name: str):
    """Decorator to monitor model operations"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            
            try:
                result = func(*args, **kwargs)
                
                logfire.info(
                    f"Model operation: {operation_name}",
                    operation=operation_name,
                    success=True,
                    duration_ms=(time.time() - start_time) * 1000
                )
                
                return result
                
            except Exception as e:
                logfire.error(
                    f"Model operation failed: {operation_name}",
                    operation=operation_name,
                    error=str(e),
                    duration_ms=(time.time() - start_time) * 1000
                )
                raise
        
        return wrapper
    return decorator

# Usage examples
@monitor_model_operation("user_creation")
def create_user(user_data: dict) -> UserResponse:
    return monitored_validate(UserResponse, user_data)

@monitor_model_operation("bulk_user_creation")
def create_users_bulk(users_data: list[dict]) -> list[UserResponse]:
    return [monitored_validate(UserResponse, data) for data in users_data]
```

### 2. Performance Metrics Collection

**Application Metrics**
```python
# utils/metrics.py
from prometheus_client import Counter, Histogram, Gauge, start_http_server
from pydantic import BaseModel
from typing import Dict, Any
import time

# Prometheus metrics
VALIDATION_COUNTER = Counter(
    'pydantic_validations_total',
    'Total number of Pydantic validations',
    ['model_name', 'status']
)

VALIDATION_DURATION = Histogram(
    'pydantic_validation_duration_seconds',
    'Time spent validating Pydantic models',
    ['model_name']
)

VALIDATION_ERRORS = Counter(
    'pydantic_validation_errors_total',
    'Total validation errors',
    ['model_name', 'error_type']
)

ACTIVE_MODELS = Gauge(
    'pydantic_active_models',
    'Number of active model instances',
    ['model_name']
)

class MetricsCollector:
    """Collect and export Pydantic metrics"""
    
    model_counters: Dict[str, int] = {}
    
    @classmethod
    def track_validation(
        cls,
        model_class: type[BaseModel],
        success: bool,
        duration: float,
        error_type: str = None
    ):
        """Track validation metrics"""
        model_name = model_class.__name__
        status = 'success' if success else 'error'
        
        # Increment counters
        VALIDATION_COUNTER.labels(model_name=model_name, status=status).inc()
        VALIDATION_DURATION.labels(model_name=model_name).observe(duration)
        
        if not success and error_type:
            VALIDATION_ERRORS.labels(
                model_name=model_name,
                error_type=error_type
            ).inc()
    
    @classmethod
    def track_model_creation(cls, model_class: type[BaseModel]):
        """Track model instance creation"""
        model_name = model_class.__name__
        cls.model_counters[model_name] = cls.model_counters.get(model_name, 0) + 1
        ACTIVE_MODELS.labels(model_name=model_name).set(cls.model_counters[model_name])
    
    @classmethod
    def track_model_destruction(cls, model_class: type[BaseModel]):
        """Track model instance destruction"""
        model_name = model_class.__name__
        if model_name in cls.model_counters and cls.model_counters[model_name] > 0:
            cls.model_counters[model_name] -= 1
            ACTIVE_MODELS.labels(model_name=model_name).set(cls.model_counters[model_name])

# Instrumented model base class
class MonitoredBaseModel(BaseModel):
    """Base model with automatic monitoring"""
    
    def __init__(self, **data):
        start_time = time.time()
        success = True
        error_type = None
        
        try:
            super().__init__(**data)
            MetricsCollector.track_model_creation(self.__class__)
        except Exception as e:
            success = False
            error_type = type(e).__name__
            raise
        finally:
            duration = time.time() - start_time
            MetricsCollector.track_validation(
                self.__class__,
                success,
                duration,
                error_type
            )
    
    def __del__(self):
        """Track model destruction"""
        MetricsCollector.track_model_destruction(self.__class__)

# Start metrics server
def start_metrics_server(port: int = 8001):
    """Start Prometheus metrics server"""
    start_http_server(port)
    print(f"Metrics server started on port {port}")
```

## 🏗️ Deployment Patterns

### 1. Docker Optimization

**Multi-stage Dockerfile**
```dockerfile
# Dockerfile
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim

# Copy installed packages
COPY --from=builder /root/.local /root/.local

# Set environment variables
ENV PYTHONPATH=/app
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PYDANTIC_CACHE_DIR=/tmp/pydantic_cache

# Create cache directory
RUN mkdir -p /tmp/pydantic_cache

# Copy application
WORKDIR /app
COPY . .

# Pre-warm Pydantic schemas
RUN python -c "from utils.schema_cache import SchemaCache; SchemaCache.warmup_all()"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

**Docker Compose for Production**
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - SECRET_KEY=${SECRET_KEY}
      - PYDANTIC_CACHE_ENABLED=true
      - PYDANTIC_METRICS_ENABLED=true
    volumes:
      - /tmp/pydantic_cache:/tmp/pydantic_cache
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

  metrics:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: unless-stopped

volumes:
  redis_data:
```

### 2. Kubernetes Deployment

**Kubernetes Manifests**
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pydantic-api
  labels:
    app: pydantic-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: pydantic-api
  template:
    metadata:
      labels:
        app: pydantic-api
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8001"
    spec:
      containers:
      - name: api
        image: pydantic-api:latest
        ports:
        - containerPort: 8000
        - containerPort: 8001  # Metrics port
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: secret-key
        - name: PYDANTIC_CACHE_ENABLED
          value: "true"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
        volumeMounts:
        - name: cache-volume
          mountPath: /tmp/pydantic_cache
      volumes:
      - name: cache-volume
        emptyDir:
          sizeLimit: 100Mi

---
apiVersion: v1
kind: Service
metadata:
  name: pydantic-api-service
spec:
  selector:
    app: pydantic-api
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8000
  - name: metrics
    protocol: TCP
    port: 8001
    targetPort: 8001
  type: ClusterIP
```

## 🔧 Configuration Management

### 1. Production Configuration

**Environment-Specific Settings**
```python
# config/production.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List, Optional
from functools import lru_cache

class ProductionSettings(BaseSettings):
    """Production-optimized configuration"""
    
    model_config = SettingsConfigDict(
        env_file='.env.production',
        env_file_encoding='utf-8',
        case_sensitive=False,
        extra='ignore'  # Ignore unknown env vars
    )
    
    # Application
    app_name: str = "Pydantic API"
    environment: str = "production"
    debug: bool = False
    
    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 4
    
    # Database
    database_url: str
    database_pool_size: int = 20
    database_max_overflow: int = 30
    database_pool_timeout: int = 30
    
    # Cache
    redis_url: Optional[str] = None
    cache_ttl: int = 3600
    
    # Security
    secret_key: str
    cors_origins: List[str] = ["https://yourdomain.com"]
    allowed_hosts: List[str] = ["yourdomain.com", "api.yourdomain.com"]
    
    # Pydantic Optimization
    pydantic_cache_enabled: bool = True
    pydantic_warmup_enabled: bool = True
    pydantic_metrics_enabled: bool = True
    
    # Rate Limiting
    rate_limit_requests: int = 1000
    rate_limit_window: int = 3600
    
    # Monitoring
    metrics_enabled: bool = True
    metrics_port: int = 8001
    log_level: str = "INFO"
    
    # Performance
    max_request_size: int = 10 * 1024 * 1024  # 10MB
    request_timeout: int = 30
    keepalive_timeout: int = 5

@lru_cache()
def get_production_settings() -> ProductionSettings:
    """Get cached production settings"""
    return ProductionSettings()

# Configuration validation
def validate_production_config():
    """Validate production configuration"""
    settings = get_production_settings()
    
    # Check required settings
    assert settings.secret_key, "SECRET_KEY is required"
    assert settings.database_url, "DATABASE_URL is required"
    assert len(settings.secret_key) >= 32, "SECRET_KEY must be at least 32 characters"
    
    # Validate database URL
    from urllib.parse import urlparse
    db_url = urlparse(settings.database_url)
    assert db_url.scheme in ['postgresql', 'mysql', 'sqlite'], "Unsupported database"
    
    # Validate CORS origins
    for origin in settings.cors_origins:
        assert origin.startswith(('http://', 'https://')), f"Invalid CORS origin: {origin}"
    
    print("✅ Production configuration validated")

# Initialize configuration
if __name__ == "__main__":
    validate_production_config()
```

### 2. Feature Flags and A/B Testing

**Feature Flag Management**
```python
# utils/feature_flags.py
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
from enum import Enum
import json
import redis

class FeatureFlag(BaseModel):
    """Feature flag configuration"""
    name: str
    enabled: bool = False
    rollout_percentage: float = Field(default=0.0, ge=0.0, le=100.0)
    user_groups: list[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)

class FeatureFlagManager:
    """Manage feature flags in production"""
    
    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self.redis = redis_client
        self._local_cache: Dict[str, FeatureFlag] = {}
        self._cache_ttl = 300  # 5 minutes
    
    def get_flag(self, flag_name: str, user_id: str = None) -> bool:
        """Check if feature is enabled for user"""
        flag = self._get_flag_config(flag_name)
        
        if not flag:
            return False
        
        if not flag.enabled:
            return False
        
        # Check rollout percentage
        if flag.rollout_percentage == 100.0:
            return True
        
        if flag.rollout_percentage == 0.0:
            return False
        
        # User-based rollout
        if user_id:
            user_hash = hash(f"{flag_name}:{user_id}") % 100
            return user_hash < flag.rollout_percentage
        
        return False
    
    def _get_flag_config(self, flag_name: str) -> Optional[FeatureFlag]:
        """Get flag configuration from cache or Redis"""
        
        # Check local cache
        if flag_name in self._local_cache:
            return self._local_cache[flag_name]
        
        # Check Redis
        if self.redis:
            flag_data = self.redis.get(f"feature_flag:{flag_name}")
            if flag_data:
                flag_dict = json.loads(flag_data)
                flag = FeatureFlag.model_validate(flag_dict)
                self._local_cache[flag_name] = flag
                return flag
        
        return None
    
    def set_flag(self, flag: FeatureFlag):
        """Set feature flag configuration"""
        self._local_cache[flag.name] = flag
        
        if self.redis:
            flag_data = flag.model_dump_json()
            self.redis.setex(
                f"feature_flag:{flag.name}",
                self._cache_ttl,
                flag_data
            )

# Feature flag decorator
from functools import wraps

def feature_flag(flag_name: str, default: bool = False):
    """Decorator to enable/disable features"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Get feature flag manager from context
            flag_manager = getattr(wrapper, '_flag_manager', None)
            
            if not flag_manager:
                return func(*args, **kwargs) if default else None
            
            # Check feature flag
            user_id = kwargs.get('user_id') or getattr(args[0], 'user_id', None) if args else None
            
            if flag_manager.get_flag(flag_name, user_id):
                return func(*args, **kwargs)
            else:
                return None if not default else func(*args, **kwargs)
        
        return wrapper
    return decorator

# Usage in FastAPI
from fastapi import Depends

def get_feature_flag_manager() -> FeatureFlagManager:
    redis_client = redis.Redis.from_url("redis://localhost:6379")
    return FeatureFlagManager(redis_client)

@app.get("/users/new-feature")
@feature_flag("new_user_feature", default=False)
async def new_user_feature(
    user_id: str,
    flag_manager: FeatureFlagManager = Depends(get_feature_flag_manager)
):
    # Attach flag manager to decorator
    new_user_feature._flag_manager = flag_manager
    
    return {"message": "New feature enabled!"}
```

## 🧪 Testing in Production

### 1. Load Testing

**Load Test Configuration**
```python
# tests/load_test.py
import asyncio
import aiohttp
import time
from pydantic import BaseModel
from typing import List, Dict, Any
import statistics

class LoadTestConfig(BaseModel):
    """Load test configuration"""
    target_url: str = "http://localhost:8000"
    concurrent_users: int = 100
    requests_per_user: int = 10
    ramp_up_time: int = 30
    test_duration: int = 300

class LoadTestResult(BaseModel):
    """Load test results"""
    total_requests: int
    successful_requests: int
    failed_requests: int
    average_response_time: float
    p95_response_time: float
    p99_response_time: float
    requests_per_second: float
    error_rate: float

class LoadTester:
    """Production load testing"""
    
    def __init__(self, config: LoadTestConfig):
        self.config = config
        self.response_times: List[float] = []
        self.success_count = 0
        self.error_count = 0
        
    async def run_user_session(self, session: aiohttp.ClientSession, user_id: int):
        """Simulate user session"""
        for request_num in range(self.config.requests_per_user):
            start_time = time.time()
            
            try:
                # Test different endpoints
                endpoints = [
                    "/health",
                    "/users/",
                    f"/users/{user_id}",
                ]
                
                endpoint = endpoints[request_num % len(endpoints)]
                
                async with session.get(f"{self.config.target_url}{endpoint}") as response:
                    await response.text()
                    
                    response_time = time.time() - start_time
                    self.response_times.append(response_time)
                    
                    if response.status < 400:
                        self.success_count += 1
                    else:
                        self.error_count += 1
                        
            except Exception as e:
                self.error_count += 1
                response_time = time.time() - start_time
                self.response_times.append(response_time)
                
            # Small delay between requests
            await asyncio.sleep(0.1)
    
    async def run_load_test(self) -> LoadTestResult:
        """Execute load test"""
        print(f"Starting load test with {self.config.concurrent_users} users...")
        
        connector = aiohttp.TCPConnector(limit=200)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(
            connector=connector,
            timeout=timeout
        ) as session:
            
            # Create user tasks
            tasks = []
            for user_id in range(self.config.concurrent_users):
                task = asyncio.create_task(
                    self.run_user_session(session, user_id)
                )
                tasks.append(task)
                
                # Ramp up gradually
                if user_id % 10 == 0:
                    await asyncio.sleep(self.config.ramp_up_time / (self.config.concurrent_users / 10))
            
            # Wait for all users to complete
            await asyncio.gather(*tasks)
        
        # Calculate results
        total_requests = self.success_count + self.error_count
        avg_response_time = statistics.mean(self.response_times) if self.response_times else 0
        
        sorted_times = sorted(self.response_times)
        p95_idx = int(len(sorted_times) * 0.95)
        p99_idx = int(len(sorted_times) * 0.99)
        
        p95_time = sorted_times[p95_idx] if sorted_times else 0
        p99_time = sorted_times[p99_idx] if sorted_times else 0
        
        rps = total_requests / self.config.test_duration if total_requests > 0 else 0
        error_rate = (self.error_count / total_requests * 100) if total_requests > 0 else 0
        
        return LoadTestResult(
            total_requests=total_requests,
            successful_requests=self.success_count,
            failed_requests=self.error_count,
            average_response_time=avg_response_time,
            p95_response_time=p95_time,
            p99_response_time=p99_time,
            requests_per_second=rps,
            error_rate=error_rate
        )

# Run load test
async def main():
    config = LoadTestConfig(
        concurrent_users=50,
        requests_per_user=20,
        test_duration=60
    )
    
    tester = LoadTester(config)
    results = await tester.run_load_test()
    
    print("Load Test Results:")
    print(f"Total Requests: {results.total_requests}")
    print(f"Success Rate: {100 - results.error_rate:.1f}%")
    print(f"Avg Response Time: {results.average_response_time:.3f}s")
    print(f"P95 Response Time: {results.p95_response_time:.3f}s")
    print(f"Requests/Second: {results.requests_per_second:.1f}")

if __name__ == "__main__":
    asyncio.run(main())
```

### 2. Production Testing Strategy

**Canary Deployment Testing**
```python
# utils/canary_testing.py
from pydantic import BaseModel
from typing import Dict, Any, Optional
import random
import logging

class CanaryConfig(BaseModel):
    """Canary deployment configuration"""
    canary_percentage: float = 5.0
    canary_endpoint: str
    production_endpoint: str
    success_threshold: float = 95.0
    error_threshold: float = 5.0

class CanaryRouter:
    """Route traffic between canary and production"""
    
    def __init__(self, config: CanaryConfig):
        self.config = config
        self.metrics = {
            'canary_requests': 0,
            'canary_errors': 0,
            'production_requests': 0,
            'production_errors': 0
        }
    
    def should_use_canary(self, user_id: str = None) -> bool:
        """Determine if request should go to canary"""
        
        # Consistent routing for specific users
        if user_id:
            user_hash = hash(user_id) % 100
            return user_hash < self.config.canary_percentage
        
        # Random routing
        return random.random() * 100 < self.config.canary_percentage
    
    def route_request(self, user_id: str = None) -> str:
        """Route request to appropriate endpoint"""
        if self.should_use_canary(user_id):
            self.metrics['canary_requests'] += 1
            return self.config.canary_endpoint
        else:
            self.metrics['production_requests'] += 1
            return self.config.production_endpoint
    
    def record_error(self, endpoint: str):
        """Record error for metrics"""
        if endpoint == self.config.canary_endpoint:
            self.metrics['canary_errors'] += 1
        else:
            self.metrics['production_errors'] += 1
    
    def get_canary_health(self) -> Dict[str, float]:
        """Get canary deployment health metrics"""
        canary_total = self.metrics['canary_requests']
        canary_errors = self.metrics['canary_errors']
        
        production_total = self.metrics['production_requests']
        production_errors = self.metrics['production_errors']
        
        canary_error_rate = (canary_errors / canary_total * 100) if canary_total > 0 else 0
        production_error_rate = (production_errors / production_total * 100) if production_total > 0 else 0
        
        return {
            'canary_error_rate': canary_error_rate,
            'production_error_rate': production_error_rate,
            'canary_requests': canary_total,
            'production_requests': production_total,
            'healthy': canary_error_rate <= self.config.error_threshold
        }

# Integration with FastAPI
from fastapi import Request, HTTPException

canary_router = CanaryRouter(CanaryConfig(
    canary_percentage=10.0,
    canary_endpoint="/v2",
    production_endpoint="/v1"
))

@app.middleware("http")
async def canary_routing_middleware(request: Request, call_next):
    """Middleware for canary routing"""
    
    # Extract user ID from request
    user_id = request.headers.get("X-User-ID")
    
    # Route to appropriate version
    if request.url.path.startswith("/api/"):
        endpoint = canary_router.route_request(user_id)
        
        # Modify request path
        if endpoint == "/v2":
            request.scope["path"] = request.url.path.replace("/api/", "/api/v2/")
    
    try:
        response = await call_next(request)
        return response
    except Exception as e:
        # Record error
        canary_router.record_error(endpoint)
        raise

@app.get("/canary/health")
async def canary_health():
    """Get canary deployment health"""
    return canary_router.get_canary_health()
```

## 🔒 Security Best Practices

### 1. Input Validation Security

**Security-Focused Validation**
```python
# utils/security_validation.py
from pydantic import BaseModel, field_validator, ValidationInfo
from typing import Any, Optional
import re
import bleach

class SecureBaseModel(BaseModel):
    """Base model with security-focused validation"""
    
    @field_validator('*', mode='before')
    @classmethod
    def sanitize_strings(cls, v: Any, info: ValidationInfo) -> Any:
        """Sanitize string inputs"""
        if isinstance(v, str):
            # Remove potential XSS
            v = bleach.clean(v, tags=[], attributes={}, protocols=[], strip=True)
            
            # Limit string length
            max_length = 10000
            if len(v) > max_length:
                raise ValueError(f"String too long (max {max_length} characters)")
            
            # Check for SQL injection patterns
            sql_patterns = [
                r"(union|select|insert|update|delete|drop|create|alter)\s",
                r"(\-\-|\;|\|)",
                r"(script|javascript|vbscript)",
            ]
            
            for pattern in sql_patterns:
                if re.search(pattern, v.lower()):
                    raise ValueError("Potentially malicious input detected")
        
        return v

class SecureUserInput(SecureBaseModel):
    """Secure user input model"""
    
    name: str
    email: str
    bio: Optional[str] = None
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate name field"""
        if not re.match(r'^[a-zA-Z\s\-\'\.]+$', v):
            raise ValueError("Name contains invalid characters")
        return v.strip()
    
    @field_validator('bio')
    @classmethod
    def validate_bio(cls, v: Optional[str]) -> Optional[str]:
        """Validate bio with additional security"""
        if v is None:
            return v
        
        # Remove HTML tags
        v = bleach.clean(v, tags=[], attributes={})
        
        # Check for excessive repetition (spam indicator)
        words = v.split()
        if len(words) > 10:
            word_freq = {}
            for word in words:
                word_freq[word] = word_freq.get(word, 0) + 1
            
            # Flag if any word appears more than 30% of the time
            max_freq = max(word_freq.values())
            if max_freq / len(words) > 0.3:
                raise ValueError("Bio contains excessive repetition")
        
        return v
```

### 2. Rate Limiting and Protection

**Advanced Rate Limiting**
```python
# utils/rate_limiting.py
from pydantic import BaseModel
from typing import Dict, Optional
import time
import redis
from fastapi import HTTPException, Request
import hashlib

class RateLimitRule(BaseModel):
    """Rate limiting rule configuration"""
    requests: int
    window_seconds: int
    burst_allowance: int = 0

class RateLimiter:
    """Advanced rate limiter with multiple rules"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.rules: Dict[str, RateLimitRule] = {
            'global': RateLimitRule(requests=1000, window_seconds=3600),
            'per_user': RateLimitRule(requests=100, window_seconds=3600),
            'per_ip': RateLimitRule(requests=200, window_seconds=3600),
            'login': RateLimitRule(requests=5, window_seconds=900),  # 15 minutes
        }
    
    def check_rate_limit(
        self,
        key: str,
        rule_name: str,
        user_id: Optional[str] = None,
        ip_address: Optional[str] = None
    ) -> bool:
        """Check if request is within rate limits"""
        
        rule = self.rules.get(rule_name)
        if not rule:
            return True
        
        current_time = int(time.time())
        window_start = current_time - rule.window_seconds
        
        # Create unique key for this rate limit
        rate_key = f"rate_limit:{rule_name}:{key}"
        
        # Get current count
        pipe = self.redis.pipeline()
        pipe.zremrangebyscore(rate_key, 0, window_start)  # Remove old entries
        pipe.zcard(rate_key)  # Count current entries
        pipe.expire(rate_key, rule.window_seconds)
        
        results = pipe.execute()
        current_count = results[1]
        
        # Check if limit exceeded
        if current_count >= rule.requests:
            return False
        
        # Add current request
        self.redis.zadd(rate_key, {str(current_time): current_time})
        
        return True
    
    def rate_limit_decorator(self, rule_name: str):
        """Decorator for rate limiting endpoints"""
        def decorator(func):
            async def wrapper(request: Request, *args, **kwargs):
                # Extract rate limiting key
                ip_address = request.client.host if request.client else "unknown"
                user_id = request.headers.get("X-User-ID", "anonymous")
                
                # Create composite key
                key_components = [ip_address, user_id]
                key = hashlib.md5(":".join(key_components).encode()).hexdigest()
                
                # Check rate limit
                if not self.check_rate_limit(key, rule_name, user_id, ip_address):
                    raise HTTPException(
                        status_code=429,
                        detail="Rate limit exceeded"
                    )
                
                return await func(request, *args, **kwargs)
            return wrapper
        return decorator

# Usage with FastAPI
rate_limiter = RateLimiter(redis.Redis.from_url("redis://localhost:6379"))

@app.post("/auth/login")
@rate_limiter.rate_limit_decorator("login")
async def login(request: Request, credentials: LoginRequest):
    # Login logic
    pass
```

---

This comprehensive Pydantic v2 production guide covers performance optimization, monitoring, deployment, and security best practices for high-scale applications. The patterns and examples provide a solid foundation for production-ready Pydantic v2 applications.

*Part of the [Pydantic v2 Modern Guide](./README.md) documentation resource*
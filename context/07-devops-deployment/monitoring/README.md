# Application Monitoring & Observability

Comprehensive guide to monitoring, logging, and observability for modern applications, covering metrics, tracing, alerting, and performance monitoring.

## 🎯 What is Observability?

Observability is the ability to understand the internal state of your system by examining its outputs:

**Three Pillars of Observability:**
- **Metrics** - Numerical measurements over time (CPU, memory, response times)
- **Logs** - Discrete events with timestamps and context
- **Traces** - Request flow through distributed systems

**Additional Pillars:**
- **Events** - State changes and business events
- **Profiling** - Code-level performance analysis
- **Real User Monitoring (RUM)** - Actual user experience data

## 📊 Application Metrics

### Prometheus Setup
```python
# app/metrics.py
from prometheus_client import Counter, Histogram, Gauge, Info, start_http_server
import time
import psutil
import threading

# Application metrics
REQUEST_COUNT = Counter(
    'app_requests_total', 
    'Total application requests',
    ['method', 'endpoint', 'status_code']
)

REQUEST_DURATION = Histogram(
    'app_request_duration_seconds',
    'Request duration in seconds',
    ['method', 'endpoint']
)

ACTIVE_CONNECTIONS = Gauge(
    'app_active_connections',
    'Number of active connections'
)

ERROR_RATE = Counter(
    'app_errors_total',
    'Total application errors',
    ['error_type', 'endpoint']
)

# Business metrics
USER_REGISTRATIONS = Counter(
    'app_user_registrations_total',
    'Total user registrations'
)

ORDER_VALUE = Histogram(
    'app_order_value_dollars',
    'Order values in dollars',
    buckets=[5, 10, 25, 50, 100, 250, 500, 1000, float('inf')]
)

# System metrics
MEMORY_USAGE = Gauge('app_memory_usage_bytes', 'Memory usage in bytes')
CPU_USAGE = Gauge('app_cpu_usage_percent', 'CPU usage percentage')
DISK_USAGE = Gauge('app_disk_usage_percent', 'Disk usage percentage')

# Application info
APP_INFO = Info('app_info', 'Application information')

class MetricsCollector:
    def __init__(self):
        self.is_running = False
        self.thread = None

    def start(self, port=8000):
        """Start metrics collection and HTTP server."""
        # Set application info
        APP_INFO.info({
            'version': '1.0.0',
            'environment': 'production',
            'build_date': '2023-12-01'
        })
        
        # Start Prometheus metrics server
        start_http_server(port)
        
        # Start system metrics collection
        self.is_running = True
        self.thread = threading.Thread(target=self._collect_system_metrics, daemon=True)
        self.thread.start()

    def stop(self):
        """Stop metrics collection."""
        self.is_running = False
        if self.thread:
            self.thread.join()

    def _collect_system_metrics(self):
        """Collect system metrics periodically."""
        while self.is_running:
            try:
                # Memory usage
                memory = psutil.virtual_memory()
                MEMORY_USAGE.set(memory.used)
                
                # CPU usage
                cpu_percent = psutil.cpu_percent(interval=1)
                CPU_USAGE.set(cpu_percent)
                
                # Disk usage
                disk = psutil.disk_usage('/')
                DISK_USAGE.set((disk.used / disk.total) * 100)
                
                time.sleep(30)  # Collect every 30 seconds
                
            except Exception as e:
                print(f"Error collecting system metrics: {e}")
                time.sleep(60)  # Wait longer on error

# Global metrics collector
metrics_collector = MetricsCollector()

def track_request(method: str, endpoint: str, status_code: int, duration: float):
    """Track request metrics."""
    REQUEST_COUNT.labels(method=method, endpoint=endpoint, status_code=status_code).inc()
    REQUEST_DURATION.labels(method=method, endpoint=endpoint).observe(duration)

def track_error(error_type: str, endpoint: str):
    """Track error metrics."""
    ERROR_RATE.labels(error_type=error_type, endpoint=endpoint).inc()

def track_business_event(event_type: str, value: float = None):
    """Track business metrics."""
    if event_type == 'user_registration':
        USER_REGISTRATIONS.inc()
    elif event_type == 'order_placed' and value:
        ORDER_VALUE.observe(value)
```

### FastAPI Integration
```python
# app/middleware.py
from fastapi import FastAPI, Request, Response
import time
from metrics import track_request, track_error, ACTIVE_CONNECTIONS

def add_metrics_middleware(app: FastAPI):
    @app.middleware("http")
    async def metrics_middleware(request: Request, call_next):
        start_time = time.time()
        
        # Track active connections
        ACTIVE_CONNECTIONS.inc()
        
        try:
            response = await call_next(request)
            
            # Calculate duration
            duration = time.time() - start_time
            
            # Track metrics
            track_request(
                method=request.method,
                endpoint=request.url.path,
                status_code=response.status_code,
                duration=duration
            )
            
            return response
            
        except Exception as e:
            # Track errors
            track_error(
                error_type=type(e).__name__,
                endpoint=request.url.path
            )
            raise
        finally:
            ACTIVE_CONNECTIONS.dec()

    @app.get("/metrics")
    async def get_metrics():
        """Prometheus metrics endpoint."""
        from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

    @app.get("/health")
    async def health_check():
        """Health check endpoint."""
        return {
            "status": "healthy",
            "timestamp": time.time(),
            "uptime": time.time() - start_time
        }
```

## 📝 Structured Logging

### Python Logging Setup
```python
# app/logging_config.py
import logging
import json
import sys
from datetime import datetime
from typing import Dict, Any
import traceback

class JSONFormatter(logging.Formatter):
    """Custom JSON formatter for structured logging."""
    
    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        # Add extra fields
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
        
        if hasattr(record, 'request_id'):
            log_entry['request_id'] = record.request_id
        
        if hasattr(record, 'duration'):
            log_entry['duration'] = record.duration
        
        # Add exception info
        if record.exc_info:
            log_entry['exception'] = {
                'type': record.exc_info[0].__name__,
                'message': str(record.exc_info[1]),
                'traceback': traceback.format_exception(*record.exc_info)
            }
        
        return json.dumps(log_entry)

class ContextFilter(logging.Filter):
    """Add context information to log records."""
    
    def filter(self, record):
        # Add correlation ID if available (from request context)
        if hasattr(record, 'request'):
            record.correlation_id = getattr(record.request, 'correlation_id', None)
        
        return True

def setup_logging(log_level: str = "INFO", environment: str = "development"):
    """Setup application logging."""
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove default handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # Create console handler
    console_handler = logging.StreamHandler(sys.stdout)
    
    if environment == "production":
        # Use JSON formatter for production
        formatter = JSONFormatter()
    else:
        # Use human-readable format for development
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    console_handler.setFormatter(formatter)
    console_handler.addFilter(ContextFilter())
    
    root_logger.addHandler(console_handler)
    
    # Configure specific loggers
    logging.getLogger("uvicorn").setLevel(logging.WARNING)
    logging.getLogger("fastapi").setLevel(logging.INFO)
    
    return root_logger

# Application logger
logger = logging.getLogger(__name__)

class AppLogger:
    """Application-specific logging utilities."""
    
    @staticmethod
    def log_request(method: str, path: str, status_code: int, duration: float, user_id: str = None):
        """Log HTTP request."""
        logger.info(
            f"{method} {path} {status_code}",
            extra={
                'event_type': 'http_request',
                'method': method,
                'path': path,
                'status_code': status_code,
                'duration': duration,
                'user_id': user_id
            }
        )
    
    @staticmethod
    def log_business_event(event: str, user_id: str = None, **kwargs):
        """Log business events."""
        logger.info(
            f"Business event: {event}",
            extra={
                'event_type': 'business_event',
                'event': event,
                'user_id': user_id,
                **kwargs
            }
        )
    
    @staticmethod
    def log_error(error: Exception, context: Dict[str, Any] = None):
        """Log application errors."""
        logger.error(
            f"Application error: {str(error)}",
            exc_info=True,
            extra={
                'event_type': 'application_error',
                'error_type': type(error).__name__,
                'context': context or {}
            }
        )
    
    @staticmethod
    def log_security_event(event: str, user_id: str = None, ip_address: str = None, **kwargs):
        """Log security-related events."""
        logger.warning(
            f"Security event: {event}",
            extra={
                'event_type': 'security_event',
                'event': event,
                'user_id': user_id,
                'ip_address': ip_address,
                **kwargs
            }
        )
```

### Request Logging Middleware
```python
# app/request_logging.py
import uuid
import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from logging_config import AppLogger
import logging

logger = logging.getLogger(__name__)

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware for logging HTTP requests."""
    
    async def dispatch(self, request: Request, call_next):
        # Generate correlation ID
        correlation_id = str(uuid.uuid4())
        request.state.correlation_id = correlation_id
        
        # Start timing
        start_time = time.time()
        
        # Extract user info (if authenticated)
        user_id = getattr(request.state, 'user_id', None)
        
        # Log request start
        logger.info(
            f"Request started: {request.method} {request.url.path}",
            extra={
                'correlation_id': correlation_id,
                'method': request.method,
                'path': request.url.path,
                'query_params': dict(request.query_params),
                'user_agent': request.headers.get('user-agent'),
                'ip_address': request.client.host,
                'user_id': user_id
            }
        )
        
        try:
            response = await call_next(request)
            duration = time.time() - start_time
            
            # Log successful request
            AppLogger.log_request(
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                duration=duration,
                user_id=user_id
            )
            
            # Add correlation ID to response headers
            response.headers["X-Correlation-ID"] = correlation_id
            
            return response
            
        except Exception as e:
            duration = time.time() - start_time
            
            # Log error
            AppLogger.log_error(e, context={
                'correlation_id': correlation_id,
                'method': request.method,
                'path': request.url.path,
                'duration': duration,
                'user_id': user_id
            })
            
            raise
```

## 🔍 Distributed Tracing

### OpenTelemetry Setup
```python
# app/tracing.py
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
import logging

logger = logging.getLogger(__name__)

def setup_tracing(service_name: str, jaeger_endpoint: str = None):
    """Setup distributed tracing with OpenTelemetry."""
    
    # Create resource
    resource = Resource.create({
        "service.name": service_name,
        "service.version": "1.0.0",
        "deployment.environment": "production"
    })
    
    # Set tracer provider
    trace.set_tracer_provider(TracerProvider(resource=resource))
    tracer_provider = trace.get_tracer_provider()
    
    # Setup Jaeger exporter if endpoint provided
    if jaeger_endpoint:
        jaeger_exporter = JaegerExporter(
            agent_host_name="jaeger",
            agent_port=6831,
        )
        
        span_processor = BatchSpanProcessor(jaeger_exporter)
        tracer_provider.add_span_processor(span_processor)
    
    # Get tracer
    tracer = trace.get_tracer(__name__)
    
    logger.info(f"Tracing setup complete for service: {service_name}")
    
    return tracer

def instrument_app(app):
    """Instrument FastAPI application with OpenTelemetry."""
    
    # Instrument FastAPI
    FastAPIInstrumentor.instrument_app(app)
    
    # Instrument requests
    RequestsInstrumentor().instrument()
    
    # Instrument SQLAlchemy
    SQLAlchemyInstrumentor().instrument()
    
    # Instrument Redis
    RedisInstrumentor().instrument()
    
    logger.info("Application instrumentation complete")

# Custom tracing decorator
def trace_function(operation_name: str = None):
    """Decorator to trace function calls."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            tracer = trace.get_tracer(__name__)
            span_name = operation_name or f"{func.__module__}.{func.__name__}"
            
            with tracer.start_as_current_span(span_name) as span:
                # Add function parameters as attributes
                span.set_attribute("function.name", func.__name__)
                span.set_attribute("function.module", func.__module__)
                
                try:
                    result = func(*args, **kwargs)
                    span.set_attribute("function.result", "success")
                    return result
                except Exception as e:
                    span.set_attribute("function.result", "error")
                    span.set_attribute("error.type", type(e).__name__)
                    span.set_attribute("error.message", str(e))
                    span.record_exception(e)
                    raise
        
        return wrapper
    return decorator

# Business operation tracing
@trace_function("user.registration")
def register_user(user_data: dict):
    """Example traced business operation."""
    current_span = trace.get_current_span()
    current_span.set_attribute("user.email", user_data.get("email"))
    current_span.set_attribute("user.registration_method", "email")
    
    # Simulate user registration logic
    # ... business logic here ...
    
    current_span.add_event("User validation completed")
    current_span.add_event("User created in database")
    
    return {"user_id": "12345", "status": "created"}
```

## 📈 Performance Monitoring

### Application Performance Monitoring
```python
# app/performance.py
import time
import asyncio
from typing import Dict, Any, List
from dataclasses import dataclass
from collections import defaultdict, deque
import threading
import statistics

@dataclass
class PerformanceMetric:
    """Performance metric data structure."""
    name: str
    value: float
    timestamp: float
    tags: Dict[str, str] = None

class PerformanceMonitor:
    """Application performance monitoring."""
    
    def __init__(self, max_samples: int = 1000):
        self.max_samples = max_samples
        self.metrics = defaultdict(lambda: deque(maxlen=max_samples))
        self.lock = threading.Lock()
    
    def record_metric(self, name: str, value: float, tags: Dict[str, str] = None):
        """Record a performance metric."""
        metric = PerformanceMetric(
            name=name,
            value=value,
            timestamp=time.time(),
            tags=tags or {}
        )
        
        with self.lock:
            self.metrics[name].append(metric)
    
    def get_statistics(self, name: str, window_seconds: int = 300) -> Dict[str, Any]:
        """Get statistics for a metric within time window."""
        current_time = time.time()
        cutoff_time = current_time - window_seconds
        
        with self.lock:
            recent_metrics = [
                m for m in self.metrics[name] 
                if m.timestamp >= cutoff_time
            ]
        
        if not recent_metrics:
            return {}
        
        values = [m.value for m in recent_metrics]
        
        return {
            'count': len(values),
            'min': min(values),
            'max': max(values),
            'mean': statistics.mean(values),
            'median': statistics.median(values),
            'p95': self._percentile(values, 95),
            'p99': self._percentile(values, 99),
            'std_dev': statistics.stdev(values) if len(values) > 1 else 0
        }
    
    def _percentile(self, values: List[float], percentile: int) -> float:
        """Calculate percentile."""
        sorted_values = sorted(values)
        k = (len(sorted_values) - 1) * percentile / 100
        f = int(k)
        c = k - f
        
        if f == len(sorted_values) - 1:
            return sorted_values[f]
        
        return sorted_values[f] * (1 - c) + sorted_values[f + 1] * c
    
    def get_all_statistics(self, window_seconds: int = 300) -> Dict[str, Dict[str, Any]]:
        """Get statistics for all metrics."""
        return {
            name: self.get_statistics(name, window_seconds)
            for name in self.metrics.keys()
        }

# Global performance monitor
perf_monitor = PerformanceMonitor()

class TimingContext:
    """Context manager for timing operations."""
    
    def __init__(self, operation_name: str, tags: Dict[str, str] = None):
        self.operation_name = operation_name
        self.tags = tags or {}
        self.start_time = None
    
    def __enter__(self):
        self.start_time = time.time()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        perf_monitor.record_metric(
            f"operation_duration.{self.operation_name}",
            duration,
            self.tags
        )

# Timing decorator
def time_operation(operation_name: str = None, tags: Dict[str, str] = None):
    """Decorator to time function execution."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            name = operation_name or f"{func.__module__}.{func.__name__}"
            with TimingContext(name, tags):
                return func(*args, **kwargs)
        return wrapper
    return decorator

# Database query monitoring
class DatabaseMonitor:
    """Monitor database query performance."""
    
    @staticmethod
    def log_query(query: str, duration: float, rows_affected: int = None):
        """Log database query performance."""
        perf_monitor.record_metric("db_query_duration", duration, {
            "query_type": query.split()[0].upper()  # SELECT, INSERT, etc.
        })
        
        if rows_affected is not None:
            perf_monitor.record_metric("db_rows_affected", rows_affected)

# Usage examples
@time_operation("user_service.get_profile")
def get_user_profile(user_id: str):
    # Simulate database query
    with TimingContext("db_query", {"table": "users"}):
        time.sleep(0.05)  # Simulate query time
    
    return {"user_id": user_id, "name": "John Doe"}
```

### Real User Monitoring (RUM)
```javascript
// frontend/src/utils/rum.js
class RealUserMonitoring {
  constructor(config = {}) {
    this.endpoint = config.endpoint || '/api/rum';
    this.sessionId = this.generateSessionId();
    this.pageLoadTime = null;
    this.metrics = [];
    
    this.init();
  }
  
  init() {
    // Track page load performance
    window.addEventListener('load', () => {
      this.trackPageLoad();
    });
    
    // Track unhandled errors
    window.addEventListener('error', (event) => {
      this.trackError(event.error, event.filename, event.lineno);
    });
    
    // Track promise rejections
    window.addEventListener('unhandledrejection', (event) => {
      this.trackError(event.reason, 'Promise rejection');
    });
    
    // Track user interactions
    this.trackUserInteractions();
    
    // Send metrics periodically
    setInterval(() => this.sendMetrics(), 30000); // Every 30 seconds
  }
  
  trackPageLoad() {
    const navigation = performance.getEntriesByType('navigation')[0];
    
    if (navigation) {
      this.addMetric('page_load', {
        type: 'performance',
        loadTime: navigation.loadEventEnd - navigation.fetchStart,
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.fetchStart,
        firstByte: navigation.responseStart - navigation.fetchStart,
        domInteractive: navigation.domInteractive - navigation.fetchStart
      });
    }
    
    // Core Web Vitals
    this.trackCoreWebVitals();
  }
  
  trackCoreWebVitals() {
    // Largest Contentful Paint
    new PerformanceObserver((entryList) => {
      const entries = entryList.getEntries();
      const lastEntry = entries[entries.length - 1];
      
      this.addMetric('lcp', {
        type: 'web_vital',
        value: lastEntry.startTime,
        element: lastEntry.element?.tagName
      });
    }).observe({ type: 'largest-contentful-paint', buffered: true });
    
    // First Input Delay
    new PerformanceObserver((entryList) => {
      const entries = entryList.getEntries();
      entries.forEach(entry => {
        this.addMetric('fid', {
          type: 'web_vital',
          value: entry.processingStart - entry.startTime,
          eventType: entry.name
        });
      });
    }).observe({ type: 'first-input', buffered: true });
    
    // Cumulative Layout Shift
    let clsValue = 0;
    new PerformanceObserver((entryList) => {
      for (const entry of entryList.getEntries()) {
        if (!entry.hadRecentInput) {
          clsValue += entry.value;
        }
      }
      
      this.addMetric('cls', {
        type: 'web_vital',
        value: clsValue
      });
    }).observe({ type: 'layout-shift', buffered: true });
  }
  
  trackUserInteractions() {
    // Click tracking
    document.addEventListener('click', (event) => {
      this.addMetric('user_interaction', {
        type: 'click',
        element: event.target.tagName,
        className: event.target.className,
        id: event.target.id
      });
    });
    
    // Form submissions
    document.addEventListener('submit', (event) => {
      this.addMetric('user_interaction', {
        type: 'form_submit',
        formId: event.target.id,
        formAction: event.target.action
      });
    });
  }
  
  trackError(error, filename = '', lineno = 0) {
    this.addMetric('javascript_error', {
      type: 'error',
      message: error.message || error.toString(),
      filename: filename,
      lineno: lineno,
      stack: error.stack,
      userAgent: navigator.userAgent,
      url: window.location.href
    });
  }
  
  trackApiCall(url, method, duration, status) {
    this.addMetric('api_call', {
      type: 'api',
      url: url,
      method: method,
      duration: duration,
      status: status
    });
  }
  
  addMetric(name, data) {
    this.metrics.push({
      name: name,
      timestamp: Date.now(),
      sessionId: this.sessionId,
      url: window.location.href,
      ...data
    });
  }
  
  async sendMetrics() {
    if (this.metrics.length === 0) return;
    
    const payload = {
      sessionId: this.sessionId,
      userAgent: navigator.userAgent,
      metrics: [...this.metrics]
    };
    
    this.metrics = []; // Clear sent metrics
    
    try {
      await fetch(this.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
    } catch (error) {
      console.warn('Failed to send RUM metrics:', error);
    }
  }
  
  generateSessionId() {
    return 'session_' + Math.random().toString(36).substr(2, 9);
  }
}

// Initialize RUM
const rum = new RealUserMonitoring({
  endpoint: '/api/rum'
});

// API call interceptor for fetch
const originalFetch = window.fetch;
window.fetch = function(...args) {
  const start = performance.now();
  const url = args[0];
  const options = args[1] || {};
  
  return originalFetch.apply(this, args)
    .then(response => {
      const duration = performance.now() - start;
      rum.trackApiCall(url, options.method || 'GET', duration, response.status);
      return response;
    })
    .catch(error => {
      const duration = performance.now() - start;
      rum.trackApiCall(url, options.method || 'GET', duration, 'error');
      throw error;
    });
};

export default rum;
```

## 🚨 Alerting & Incident Management

### Alert Configuration
```python
# app/alerting.py
import asyncio
import json
from typing import Dict, List, Any, Callable
from dataclasses import dataclass, asdict
from enum import Enum
import httpx
import logging

logger = logging.getLogger(__name__)

class AlertSeverity(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class Alert:
    name: str
    message: str
    severity: AlertSeverity
    source: str
    timestamp: float
    tags: Dict[str, str] = None
    metrics: Dict[str, Any] = None

class AlertManager:
    """Manage application alerts and notifications."""
    
    def __init__(self):
        self.handlers: List[Callable] = []
        self.alert_rules: List[Dict] = []
        self.active_alerts: Dict[str, Alert] = {}
    
    def add_handler(self, handler: Callable[[Alert], None]):
        """Add alert handler."""
        self.handlers.append(handler)
    
    def add_rule(self, rule: Dict[str, Any]):
        """Add alert rule."""
        self.alert_rules.append(rule)
    
    async def trigger_alert(self, alert: Alert):
        """Trigger an alert."""
        alert_key = f"{alert.source}:{alert.name}"
        
        # Check if this is a new alert or update
        if alert_key in self.active_alerts:
            logger.info(f"Updating existing alert: {alert_key}")
        else:
            logger.warning(f"New alert triggered: {alert_key}")
            self.active_alerts[alert_key] = alert
        
        # Send to all handlers
        for handler in self.handlers:
            try:
                if asyncio.iscoroutinefunction(handler):
                    await handler(alert)
                else:
                    handler(alert)
            except Exception as e:
                logger.error(f"Alert handler failed: {e}")
    
    def resolve_alert(self, source: str, name: str):
        """Resolve an active alert."""
        alert_key = f"{source}:{name}"
        if alert_key in self.active_alerts:
            del self.active_alerts[alert_key]
            logger.info(f"Alert resolved: {alert_key}")
    
    def check_metrics(self, metrics: Dict[str, Any]):
        """Check metrics against alert rules."""
        for rule in self.alert_rules:
            self._evaluate_rule(rule, metrics)
    
    def _evaluate_rule(self, rule: Dict[str, Any], metrics: Dict[str, Any]):
        """Evaluate a single alert rule."""
        metric_name = rule['metric']
        threshold = rule['threshold']
        condition = rule['condition']  # 'gt', 'lt', 'eq'
        
        if metric_name not in metrics:
            return
        
        value = metrics[metric_name]
        
        # Evaluate condition
        triggered = False
        if condition == 'gt' and value > threshold:
            triggered = True
        elif condition == 'lt' and value < threshold:
            triggered = True
        elif condition == 'eq' and value == threshold:
            triggered = True
        
        if triggered:
            alert = Alert(
                name=rule['name'],
                message=rule['message'].format(value=value, threshold=threshold),
                severity=AlertSeverity(rule['severity']),
                source='metric_monitor',
                timestamp=time.time(),
                metrics={'current_value': value, 'threshold': threshold}
            )
            
            asyncio.create_task(self.trigger_alert(alert))

# Alert handlers
class SlackAlertHandler:
    """Send alerts to Slack."""
    
    def __init__(self, webhook_url: str):
        self.webhook_url = webhook_url
    
    async def __call__(self, alert: Alert):
        """Send alert to Slack."""
        color_map = {
            AlertSeverity.LOW: "good",
            AlertSeverity.MEDIUM: "warning", 
            AlertSeverity.HIGH: "danger",
            AlertSeverity.CRITICAL: "danger"
        }
        
        payload = {
            "attachments": [
                {
                    "color": color_map.get(alert.severity, "danger"),
                    "title": f"🚨 {alert.severity.value.upper()} Alert",
                    "text": alert.message,
                    "fields": [
                        {"title": "Source", "value": alert.source, "short": True},
                        {"title": "Severity", "value": alert.severity.value, "short": True},
                    ],
                    "timestamp": int(alert.timestamp)
                }
            ]
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(self.webhook_url, json=payload)
                response.raise_for_status()
                logger.info("Alert sent to Slack successfully")
            except Exception as e:
                logger.error(f"Failed to send alert to Slack: {e}")

class EmailAlertHandler:
    """Send alerts via email."""
    
    def __init__(self, smtp_config: Dict[str, str]):
        self.smtp_config = smtp_config
    
    async def __call__(self, alert: Alert):
        """Send alert via email."""
        # Implementation would use aiosmtplib or similar
        logger.info(f"Email alert sent: {alert.name}")

class PagerDutyAlertHandler:
    """Send alerts to PagerDuty."""
    
    def __init__(self, integration_key: str):
        self.integration_key = integration_key
    
    async def __call__(self, alert: Alert):
        """Send alert to PagerDuty."""
        payload = {
            "routing_key": self.integration_key,
            "event_action": "trigger",
            "payload": {
                "summary": alert.message,
                "source": alert.source,
                "severity": alert.severity.value,
                "timestamp": alert.timestamp,
                "custom_details": alert.metrics or {}
            }
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    "https://events.pagerduty.com/v2/enqueue",
                    json=payload
                )
                response.raise_for_status()
                logger.info("Alert sent to PagerDuty successfully")
            except Exception as e:
                logger.error(f"Failed to send alert to PagerDuty: {e}")

# Global alert manager
alert_manager = AlertManager()

# Setup default alert rules
DEFAULT_ALERT_RULES = [
    {
        "name": "high_memory_usage",
        "metric": "memory_usage_percent",
        "condition": "gt",
        "threshold": 85,
        "severity": "high",
        "message": "Memory usage is {value}%, exceeding threshold of {threshold}%"
    },
    {
        "name": "high_cpu_usage", 
        "metric": "cpu_usage_percent",
        "condition": "gt",
        "threshold": 80,
        "severity": "high",
        "message": "CPU usage is {value}%, exceeding threshold of {threshold}%"
    },
    {
        "name": "high_error_rate",
        "metric": "error_rate_percent",
        "condition": "gt", 
        "threshold": 5,
        "severity": "critical",
        "message": "Error rate is {value}%, exceeding threshold of {threshold}%"
    },
    {
        "name": "slow_response_time",
        "metric": "avg_response_time_ms",
        "condition": "gt",
        "threshold": 2000,
        "severity": "medium",
        "message": "Average response time is {value}ms, exceeding threshold of {threshold}ms"
    }
]

for rule in DEFAULT_ALERT_RULES:
    alert_manager.add_rule(rule)
```

## 📊 Monitoring Dashboard

### Dashboard Configuration
```python
# app/dashboard.py
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import json
from typing import Dict, Any

templates = Jinja2Templates(directory="templates")

def add_monitoring_dashboard(app: FastAPI):
    """Add monitoring dashboard endpoints."""
    
    @app.get("/dashboard", response_class=HTMLResponse)
    async def monitoring_dashboard(request: Request):
        """Main monitoring dashboard."""
        return templates.TemplateResponse("dashboard.html", {
            "request": request,
            "title": "Application Monitoring"
        })
    
    @app.get("/api/dashboard/metrics")
    async def get_dashboard_metrics():
        """Get current metrics for dashboard."""
        from metrics import metrics_collector
        from performance import perf_monitor
        
        # System metrics
        system_metrics = {
            "memory_usage": psutil.virtual_memory().percent,
            "cpu_usage": psutil.cpu_percent(),
            "disk_usage": psutil.disk_usage('/').percent
        }
        
        # Performance metrics
        perf_stats = perf_monitor.get_all_statistics(window_seconds=300)
        
        # Application metrics (would query Prometheus in real implementation)
        app_metrics = {
            "request_rate": 150,  # requests per minute
            "error_rate": 0.5,    # error percentage
            "avg_response_time": 245,  # milliseconds
            "active_users": 1250
        }
        
        return {
            "timestamp": time.time(),
            "system": system_metrics,
            "performance": perf_stats,
            "application": app_metrics
        }
    
    @app.get("/api/dashboard/alerts")
    async def get_active_alerts():
        """Get active alerts."""
        from alerting import alert_manager
        
        return {
            "alerts": [
                {
                    "name": alert.name,
                    "message": alert.message,
                    "severity": alert.severity.value,
                    "source": alert.source,
                    "timestamp": alert.timestamp,
                    "tags": alert.tags or {},
                    "metrics": alert.metrics or {}
                }
                for alert in alert_manager.active_alerts.values()
            ]
        }
    
    @app.get("/api/dashboard/health")
    async def system_health_check():
        """Comprehensive system health check."""
        health_status = {
            "overall": "healthy",
            "checks": {}
        }
        
        # Database check
        try:
            # Check database connection
            health_status["checks"]["database"] = "healthy"
        except Exception as e:
            health_status["checks"]["database"] = f"unhealthy: {e}"
            health_status["overall"] = "unhealthy"
        
        # Redis check
        try:
            # Check Redis connection
            health_status["checks"]["redis"] = "healthy"
        except Exception as e:
            health_status["checks"]["redis"] = f"unhealthy: {e}"
            health_status["overall"] = "degraded"
        
        # External services check
        health_status["checks"]["external_api"] = "healthy"
        
        return health_status
```

### Dashboard Template
```html
<!-- templates/dashboard.html -->
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { border: 1px solid #ddd; border-radius: 8px; padding: 20px; background: white; }
        .metric { font-size: 24px; font-weight: bold; color: #333; }
        .alert { padding: 10px; margin: 5px 0; border-radius: 4px; }
        .alert.critical { background: #ffebee; border-left: 4px solid #f44336; }
        .alert.high { background: #fff3e0; border-left: 4px solid #ff9800; }
        .alert.medium { background: #f3e5f5; border-left: 4px solid #9c27b0; }
        .alert.low { background: #e8f5e8; border-left: 4px solid #4caf50; }
        .status.healthy { color: #4caf50; }
        .status.unhealthy { color: #f44336; }
        .status.degraded { color: #ff9800; }
    </style>
</head>
<body>
    <h1>{{ title }}</h1>
    
    <div class="grid">
        <!-- System Metrics -->
        <div class="card">
            <h3>System Metrics</h3>
            <div>CPU Usage: <span id="cpu-usage" class="metric">-</span>%</div>
            <div>Memory Usage: <span id="memory-usage" class="metric">-</span>%</div>
            <div>Disk Usage: <span id="disk-usage" class="metric">-</span>%</div>
        </div>
        
        <!-- Application Metrics -->
        <div class="card">
            <h3>Application Metrics</h3>
            <div>Request Rate: <span id="request-rate" class="metric">-</span>/min</div>
            <div>Error Rate: <span id="error-rate" class="metric">-</span>%</div>
            <div>Avg Response Time: <span id="response-time" class="metric">-</span>ms</div>
            <div>Active Users: <span id="active-users" class="metric">-</span></div>
        </div>
        
        <!-- System Health -->
        <div class="card">
            <h3>System Health</h3>
            <div>Overall: <span id="health-overall" class="status">-</span></div>
            <div>Database: <span id="health-database" class="status">-</span></div>
            <div>Redis: <span id="health-redis" class="status">-</span></div>
            <div>External API: <span id="health-external" class="status">-</span></div>
        </div>
        
        <!-- Active Alerts -->
        <div class="card">
            <h3>Active Alerts</h3>
            <div id="alerts-container">No active alerts</div>
        </div>
        
        <!-- Response Time Chart -->
        <div class="card">
            <h3>Response Time Trend</h3>
            <canvas id="responseTimeChart" width="400" height="200"></canvas>
        </div>
        
        <!-- Request Rate Chart -->
        <div class="card">
            <h3>Request Rate</h3>
            <canvas id="requestRateChart" width="400" height="200"></canvas>
        </div>
    </div>

    <script>
        let responseTimeChart, requestRateChart;
        
        // Initialize charts
        function initCharts() {
            const ctx1 = document.getElementById('responseTimeChart').getContext('2d');
            responseTimeChart = new Chart(ctx1, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Response Time (ms)',
                        data: [],
                        borderColor: 'rgb(75, 192, 192)',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
            
            const ctx2 = document.getElementById('requestRateChart').getContext('2d');
            requestRateChart = new Chart(ctx2, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Requests/min',
                        data: [],
                        borderColor: 'rgb(255, 99, 132)',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
        }
        
        // Update dashboard data
        async function updateDashboard() {
            try {
                // Fetch metrics
                const metricsResponse = await fetch('/api/dashboard/metrics');
                const metrics = await metricsResponse.json();
                
                // Update system metrics
                document.getElementById('cpu-usage').textContent = metrics.system.cpu_usage.toFixed(1);
                document.getElementById('memory-usage').textContent = metrics.system.memory_usage.toFixed(1);
                document.getElementById('disk-usage').textContent = metrics.system.disk_usage.toFixed(1);
                
                // Update application metrics
                document.getElementById('request-rate').textContent = metrics.application.request_rate;
                document.getElementById('error-rate').textContent = metrics.application.error_rate;
                document.getElementById('response-time').textContent = metrics.application.avg_response_time;
                document.getElementById('active-users').textContent = metrics.application.active_users;
                
                // Update charts
                const now = new Date().toLocaleTimeString();
                
                // Response time chart
                responseTimeChart.data.labels.push(now);
                responseTimeChart.data.datasets[0].data.push(metrics.application.avg_response_time);
                if (responseTimeChart.data.labels.length > 20) {
                    responseTimeChart.data.labels.shift();
                    responseTimeChart.data.datasets[0].data.shift();
                }
                responseTimeChart.update();
                
                // Request rate chart
                requestRateChart.data.labels.push(now);
                requestRateChart.data.datasets[0].data.push(metrics.application.request_rate);
                if (requestRateChart.data.labels.length > 20) {
                    requestRateChart.data.labels.shift();
                    requestRateChart.data.datasets[0].data.shift();
                }
                requestRateChart.update();
                
                // Fetch health status
                const healthResponse = await fetch('/api/dashboard/health');
                const health = await healthResponse.json();
                
                document.getElementById('health-overall').textContent = health.overall;
                document.getElementById('health-overall').className = `status ${health.overall}`;
                document.getElementById('health-database').textContent = health.checks.database;
                document.getElementById('health-database').className = `status ${health.checks.database}`;
                document.getElementById('health-redis').textContent = health.checks.redis;
                document.getElementById('health-redis').className = `status ${health.checks.redis}`;
                document.getElementById('health-external').textContent = health.checks.external_api;
                document.getElementById('health-external').className = `status ${health.checks.external_api}`;
                
                // Fetch alerts
                const alertsResponse = await fetch('/api/dashboard/alerts');
                const alertsData = await alertsResponse.json();
                
                const alertsContainer = document.getElementById('alerts-container');
                if (alertsData.alerts.length === 0) {
                    alertsContainer.innerHTML = 'No active alerts';
                } else {
                    alertsContainer.innerHTML = alertsData.alerts.map(alert => 
                        `<div class="alert ${alert.severity}">
                            <strong>${alert.name}</strong>: ${alert.message}
                            <small>(${new Date(alert.timestamp * 1000).toLocaleString()})</small>
                        </div>`
                    ).join('');
                }
                
            } catch (error) {
                console.error('Failed to update dashboard:', error);
            }
        }
        
        // Initialize
        initCharts();
        updateDashboard();
        
        // Update every 30 seconds
        setInterval(updateDashboard, 30000);
    </script>
</body>
</html>
```

## 🛠️ Best Practices Summary

### 1. Metrics Strategy
- **Golden Signals**: Latency, Traffic, Errors, Saturation
- **Business Metrics**: User actions, conversion rates, revenue
- **System Metrics**: CPU, memory, disk, network
- **Application Metrics**: Response times, throughput, error rates

### 2. Logging Best Practices
- **Structured Logging**: Use JSON format for machine parsing
- **Correlation IDs**: Track requests across services
- **Log Levels**: Use appropriate levels (DEBUG, INFO, WARN, ERROR)
- **Sensitive Data**: Never log passwords, tokens, or PII

### 3. Alerting Strategy
- **Alert Fatigue**: Avoid too many low-priority alerts
- **Actionable Alerts**: Every alert should require action
- **Escalation**: Different severity levels with escalation paths
- **Documentation**: Clear runbooks for each alert

### 4. Performance Monitoring
- **Real User Monitoring**: Track actual user experience
- **Synthetic Monitoring**: Proactive testing of critical paths
- **Performance Budgets**: Set and monitor performance targets
- **Core Web Vitals**: Focus on user-centric metrics

### 5. Observability Culture
- **Monitoring as Code**: Version control monitoring configs
- **Collaborative Debugging**: Share dashboards and findings
- **Post-Incident Reviews**: Learn from incidents
- **Continuous Improvement**: Regular review of monitoring effectiveness

---

*Effective monitoring and observability are essential for maintaining reliable, performant applications. Implement comprehensive monitoring early and iterate based on operational experience.*
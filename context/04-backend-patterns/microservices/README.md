# Microservices Patterns

Comprehensive guide to implementing microservices architecture including service discovery, API gateways, circuit breakers, saga patterns, and distributed system best practices.

## 🎯 Microservices Overview

Microservices architecture principles:
- **Service Discovery** - Dynamic service location
- **API Gateway** - Unified entry point
- **Circuit Breakers** - Fault tolerance
- **Saga Pattern** - Distributed transactions
- **Service Mesh** - Infrastructure layer
- **Distributed Tracing** - Observability

## 🔍 Service Discovery

### Service Registry Implementation

```python
# Service registry with Consul
import consul
import asyncio
from typing import List, Dict, Optional
from dataclasses import dataclass
import socket
import uuid

@dataclass
class ServiceInstance:
    """Service instance information"""
    id: str
    name: str
    address: str
    port: int
    tags: List[str]
    meta: Dict[str, str]
    health_check_url: Optional[str] = None

class ConsulServiceRegistry:
    """Consul-based service registry"""
    
    def __init__(self, consul_host: str = "localhost", consul_port: int = 8500):
        self.consul = consul.Consul(host=consul_host, port=consul_port)
        self._registered_services: Dict[str, ServiceInstance] = {}
    
    async def register(self, service: ServiceInstance):
        """Register service with Consul"""
        # Health check configuration
        check = None
        if service.health_check_url:
            check = consul.Check.http(
                service.health_check_url,
                interval="10s",
                timeout="5s",
                deregister="1m"
            )
        
        # Register service
        self.consul.agent.service.register(
            name=service.name,
            service_id=service.id,
            address=service.address,
            port=service.port,
            tags=service.tags,
            meta=service.meta,
            check=check
        )
        
        self._registered_services[service.id] = service
        
    async def deregister(self, service_id: str):
        """Deregister service"""
        self.consul.agent.service.deregister(service_id)
        self._registered_services.pop(service_id, None)
    
    async def discover(
        self,
        service_name: str,
        tags: Optional[List[str]] = None,
        passing_only: bool = True
    ) -> List[ServiceInstance]:
        """Discover service instances"""
        # Query Consul
        _, services = self.consul.health.service(
            service_name,
            passing=passing_only,
            tags=tags
        )
        
        # Convert to ServiceInstance objects
        instances = []
        for service in services:
            svc = service['Service']
            instances.append(ServiceInstance(
                id=svc['ID'],
                name=svc['Service'],
                address=svc['Address'] or service['Node']['Address'],
                port=svc['Port'],
                tags=svc['Tags'],
                meta=svc['Meta']
            ))
        
        return instances
    
    async def watch_service(
        self,
        service_name: str,
        callback: Callable[[List[ServiceInstance]], None]
    ):
        """Watch for service changes"""
        index = None
        
        while True:
            try:
                # Long polling with blocking query
                index, services = self.consul.health.service(
                    service_name,
                    index=index,
                    wait='30s'
                )
                
                # Convert and notify
                instances = []
                for service in services:
                    svc = service['Service']
                    instances.append(ServiceInstance(
                        id=svc['ID'],
                        name=svc['Service'],
                        address=svc['Address'] or service['Node']['Address'],
                        port=svc['Port'],
                        tags=svc['Tags'],
                        meta=svc['Meta']
                    ))
                
                await callback(instances)
                
            except Exception as e:
                logger.error(f"Error watching service {service_name}: {e}")
                await asyncio.sleep(5)

# Kubernetes service discovery
from kubernetes import client, config, watch

class KubernetesServiceDiscovery:
    """Kubernetes-based service discovery"""
    
    def __init__(self, namespace: str = "default"):
        try:
            # Try in-cluster config first
            config.load_incluster_config()
        except:
            # Fall back to kubeconfig
            config.load_kube_config()
        
        self.v1 = client.CoreV1Api()
        self.namespace = namespace
    
    async def discover_service(self, service_name: str) -> List[Dict[str, Any]]:
        """Discover service endpoints"""
        try:
            # Get service
            service = self.v1.read_namespaced_service(
                name=service_name,
                namespace=self.namespace
            )
            
            # Get endpoints
            endpoints = self.v1.read_namespaced_endpoints(
                name=service_name,
                namespace=self.namespace
            )
            
            instances = []
            for subset in endpoints.subsets:
                for address in subset.addresses:
                    for port in subset.ports:
                        instances.append({
                            "address": address.ip,
                            "port": port.port,
                            "protocol": port.protocol,
                            "ready": True
                        })
            
            return instances
            
        except client.exceptions.ApiException as e:
            logger.error(f"Error discovering service {service_name}: {e}")
            return []
    
    async def watch_services(self, callback: Callable):
        """Watch for service changes"""
        w = watch.Watch()
        
        try:
            for event in w.stream(
                self.v1.list_namespaced_service,
                namespace=self.namespace
            ):
                event_type = event['type']
                service = event['object']
                
                await callback({
                    "type": event_type,
                    "service": service.metadata.name,
                    "namespace": service.metadata.namespace,
                    "labels": service.metadata.labels,
                    "spec": service.spec
                })
                
        except Exception as e:
            logger.error(f"Error watching services: {e}")
            w.stop()

# Client-side load balancing
import random
from typing import Protocol

class LoadBalancer(Protocol):
    """Load balancer interface"""
    
    def select(self, instances: List[ServiceInstance]) -> Optional[ServiceInstance]:
        pass

class RoundRobinLoadBalancer:
    """Round-robin load balancer"""
    
    def __init__(self):
        self._current = 0
    
    def select(self, instances: List[ServiceInstance]) -> Optional[ServiceInstance]:
        if not instances:
            return None
        
        instance = instances[self._current % len(instances)]
        self._current += 1
        return instance

class RandomLoadBalancer:
    """Random load balancer"""
    
    def select(self, instances: List[ServiceInstance]) -> Optional[ServiceInstance]:
        if not instances:
            return None
        return random.choice(instances)

class WeightedRoundRobinLoadBalancer:
    """Weighted round-robin load balancer"""
    
    def __init__(self):
        self._current_weights: Dict[str, int] = {}
    
    def select(self, instances: List[ServiceInstance]) -> Optional[ServiceInstance]:
        if not instances:
            return None
        
        # Initialize weights if needed
        for instance in instances:
            if instance.id not in self._current_weights:
                weight = int(instance.meta.get("weight", "1"))
                self._current_weights[instance.id] = weight
        
        # Find instance with highest current weight
        selected = None
        max_weight = -1
        
        for instance in instances:
            current_weight = self._current_weights[instance.id]
            if current_weight > max_weight:
                max_weight = current_weight
                selected = instance
        
        # Update weights
        if selected:
            self._current_weights[selected.id] -= 1
            
            # Reset if all weights are 0
            if all(w <= 0 for w in self._current_weights.values()):
                for instance in instances:
                    weight = int(instance.meta.get("weight", "1"))
                    self._current_weights[instance.id] = weight
        
        return selected

# Service discovery client
class ServiceDiscoveryClient:
    """High-level service discovery client"""
    
    def __init__(
        self,
        registry: ConsulServiceRegistry,
        load_balancer: LoadBalancer = None
    ):
        self.registry = registry
        self.load_balancer = load_balancer or RoundRobinLoadBalancer()
        self._service_cache: Dict[str, List[ServiceInstance]] = {}
        self._watch_tasks: Dict[str, asyncio.Task] = {}
    
    async def get_service_instance(
        self,
        service_name: str,
        tags: Optional[List[str]] = None
    ) -> Optional[ServiceInstance]:
        """Get single service instance with load balancing"""
        instances = await self.get_service_instances(service_name, tags)
        return self.load_balancer.select(instances)
    
    async def get_service_instances(
        self,
        service_name: str,
        tags: Optional[List[str]] = None
    ) -> List[ServiceInstance]:
        """Get all service instances"""
        # Check cache first
        cache_key = f"{service_name}:{','.join(tags or [])}"
        if cache_key in self._service_cache:
            return self._service_cache[cache_key]
        
        # Discover services
        instances = await self.registry.discover(service_name, tags)
        self._service_cache[cache_key] = instances
        
        # Start watching if not already
        if cache_key not in self._watch_tasks:
            task = asyncio.create_task(
                self._watch_service(service_name, tags, cache_key)
            )
            self._watch_tasks[cache_key] = task
        
        return instances
    
    async def _watch_service(
        self,
        service_name: str,
        tags: Optional[List[str]],
        cache_key: str
    ):
        """Watch service for changes"""
        async def update_cache(instances: List[ServiceInstance]):
            self._service_cache[cache_key] = instances
        
        await self.registry.watch_service(service_name, update_cache)
```

## 🚪 API Gateway Pattern

### Gateway Implementation

```python
# API Gateway with routing and middleware
from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.responses import StreamingResponse
import httpx
from typing import Dict, List, Optional, Callable
import re

class Route:
    """API Gateway route"""
    
    def __init__(
        self,
        path_pattern: str,
        service_name: str,
        methods: List[str] = None,
        strip_prefix: bool = True,
        rewrite_path: Optional[str] = None
    ):
        self.path_pattern = re.compile(path_pattern)
        self.service_name = service_name
        self.methods = methods or ["GET", "POST", "PUT", "DELETE", "PATCH"]
        self.strip_prefix = strip_prefix
        self.rewrite_path = rewrite_path

class APIGateway:
    """API Gateway implementation"""
    
    def __init__(
        self,
        discovery_client: ServiceDiscoveryClient,
        timeout: float = 30.0
    ):
        self.discovery = discovery_client
        self.routes: List[Route] = []
        self.middlewares: List[Callable] = []
        self.timeout = timeout
        self.http_client = httpx.AsyncClient(timeout=timeout)
    
    def add_route(self, route: Route):
        """Add route to gateway"""
        self.routes.append(route)
    
    def add_middleware(self, middleware: Callable):
        """Add middleware to gateway"""
        self.middlewares.append(middleware)
    
    async def handle_request(self, request: Request) -> Response:
        """Handle incoming request"""
        # Find matching route
        route = self._match_route(request.url.path, request.method)
        if not route:
            raise HTTPException(status_code=404, detail="Route not found")
        
        # Apply middlewares
        for middleware in self.middlewares:
            request = await middleware(request)
        
        # Get service instance
        instance = await self.discovery.get_service_instance(
            route.service_name
        )
        if not instance:
            raise HTTPException(
                status_code=503,
                detail=f"Service {route.service_name} unavailable"
            )
        
        # Build target URL
        target_url = self._build_target_url(
            instance,
            request.url.path,
            route
        )
        
        # Forward request
        return await self._forward_request(
            request,
            target_url,
            instance
        )
    
    def _match_route(self, path: str, method: str) -> Optional[Route]:
        """Match request to route"""
        for route in self.routes:
            if route.path_pattern.match(path) and method in route.methods:
                return route
        return None
    
    def _build_target_url(
        self,
        instance: ServiceInstance,
        request_path: str,
        route: Route
    ) -> str:
        """Build target service URL"""
        # Base URL
        base_url = f"http://{instance.address}:{instance.port}"
        
        # Handle path rewriting
        if route.rewrite_path:
            path = route.rewrite_path
        elif route.strip_prefix:
            # Remove matched prefix
            match = route.path_pattern.match(request_path)
            if match:
                prefix = match.group(0)
                path = request_path[len(prefix):]
            else:
                path = request_path
        else:
            path = request_path
        
        return base_url + path
    
    async def _forward_request(
        self,
        request: Request,
        target_url: str,
        instance: ServiceInstance
    ) -> Response:
        """Forward request to service"""
        # Prepare headers
        headers = dict(request.headers)
        headers.pop("host", None)
        headers["x-forwarded-for"] = request.client.host
        headers["x-forwarded-proto"] = request.url.scheme
        headers["x-original-uri"] = str(request.url)
        
        # Stream request body
        body = await request.body()
        
        try:
            # Make request
            response = await self.http_client.request(
                method=request.method,
                url=target_url,
                headers=headers,
                content=body,
                params=dict(request.query_params)
            )
            
            # Stream response
            return StreamingResponse(
                response.aiter_bytes(),
                status_code=response.status_code,
                headers=dict(response.headers)
            )
            
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=504,
                detail="Gateway timeout"
            )
        except Exception as e:
            logger.error(f"Error forwarding request: {e}")
            raise HTTPException(
                status_code=502,
                detail="Bad gateway"
            )

# Gateway middleware examples
class RateLimitMiddleware:
    """Rate limiting middleware"""
    
    def __init__(self, redis_client, requests_per_minute: int = 60):
        self.redis = redis_client
        self.limit = requests_per_minute
    
    async def __call__(self, request: Request) -> Request:
        # Get client identifier
        client_id = request.headers.get("x-api-key", request.client.host)
        key = f"rate_limit:{client_id}"
        
        # Check rate limit
        current = await self.redis.incr(key)
        if current == 1:
            await self.redis.expire(key, 60)
        
        if current > self.limit:
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded"
            )
        
        return request

class AuthenticationMiddleware:
    """Authentication middleware"""
    
    def __init__(self, auth_service_url: str):
        self.auth_service_url = auth_service_url
    
    async def __call__(self, request: Request) -> Request:
        # Skip auth for public endpoints
        if request.url.path.startswith("/public"):
            return request
        
        # Get token
        auth_header = request.headers.get("authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            raise HTTPException(
                status_code=401,
                detail="Missing authentication"
            )
        
        token = auth_header.split(" ")[1]
        
        # Validate token
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.auth_service_url}/validate",
                json={"token": token}
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid token"
                )
            
            # Add user info to request
            user_info = response.json()
            request.state.user = user_info
        
        return request

# Request aggregation
class AggregationGateway:
    """Gateway with request aggregation"""
    
    def __init__(self, discovery_client: ServiceDiscoveryClient):
        self.discovery = discovery_client
    
    async def aggregate_requests(
        self,
        requests: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Execute multiple requests in parallel"""
        tasks = []
        
        for req in requests:
            task = self._execute_request(
                service=req["service"],
                method=req.get("method", "GET"),
                path=req["path"],
                data=req.get("data"),
                headers=req.get("headers", {})
            )
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Format results
        responses = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                responses.append({
                    "id": requests[i].get("id", i),
                    "error": str(result),
                    "status": 500
                })
            else:
                responses.append({
                    "id": requests[i].get("id", i),
                    "data": result.get("data"),
                    "status": result.get("status", 200)
                })
        
        return responses
    
    async def _execute_request(
        self,
        service: str,
        method: str,
        path: str,
        data: Optional[Dict] = None,
        headers: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Execute single request"""
        # Get service instance
        instance = await self.discovery.get_service_instance(service)
        if not instance:
            raise ServiceUnavailableError(f"Service {service} not found")
        
        # Build URL
        url = f"http://{instance.address}:{instance.port}{path}"
        
        # Make request
        async with httpx.AsyncClient() as client:
            response = await client.request(
                method=method,
                url=url,
                json=data,
                headers=headers
            )
            
            return {
                "data": response.json() if response.content else None,
                "status": response.status_code
            }
```

## 🔌 Circuit Breaker Pattern

### Circuit Breaker Implementation

```python
# Circuit breaker with states
from enum import Enum
from datetime import datetime, timedelta
import asyncio
from typing import Callable, Optional, Any

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    """Circuit breaker implementation"""
    
    def __init__(
        self,
        failure_threshold: int = 5,
        success_threshold: int = 2,
        timeout: float = 60.0,
        half_open_max_calls: int = 3
    ):
        self.failure_threshold = failure_threshold
        self.success_threshold = success_threshold
        self.timeout = timeout
        self.half_open_max_calls = half_open_max_calls
        
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.half_open_calls = 0
        
        self._lock = asyncio.Lock()
    
    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """Execute function with circuit breaker"""
        async with self._lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                    self.half_open_calls = 0
                else:
                    raise CircuitOpenError("Circuit breaker is open")
            
            if self.state == CircuitState.HALF_OPEN:
                if self.half_open_calls >= self.half_open_max_calls:
                    raise CircuitOpenError("Half-open call limit reached")
                self.half_open_calls += 1
        
        try:
            # Execute function
            result = await func(*args, **kwargs)
            
            # Record success
            await self._on_success()
            
            return result
            
        except Exception as e:
            # Record failure
            await self._on_failure()
            raise e
    
    async def _on_success(self):
        """Handle successful call"""
        async with self._lock:
            if self.state == CircuitState.HALF_OPEN:
                self.success_count += 1
                
                if self.success_count >= self.success_threshold:
                    self.state = CircuitState.CLOSED
                    self.failure_count = 0
                    self.success_count = 0
            
            elif self.state == CircuitState.CLOSED:
                self.failure_count = 0
    
    async def _on_failure(self):
        """Handle failed call"""
        async with self._lock:
            self.failure_count += 1
            self.last_failure_time = datetime.utcnow()
            
            if self.state == CircuitState.CLOSED:
                if self.failure_count >= self.failure_threshold:
                    self.state = CircuitState.OPEN
            
            elif self.state == CircuitState.HALF_OPEN:
                self.state = CircuitState.OPEN
                self.success_count = 0
    
    def _should_attempt_reset(self) -> bool:
        """Check if should transition to half-open"""
        return (
            self.last_failure_time and
            datetime.utcnow() - self.last_failure_time > timedelta(seconds=self.timeout)
        )
    
    def get_state(self) -> Dict[str, Any]:
        """Get circuit breaker state"""
        return {
            "state": self.state.value,
            "failure_count": self.failure_count,
            "success_count": self.success_count,
            "last_failure_time": self.last_failure_time
        }

# Circuit breaker registry
class CircuitBreakerRegistry:
    """Manage multiple circuit breakers"""
    
    def __init__(self):
        self._breakers: Dict[str, CircuitBreaker] = {}
        self._default_config = {
            "failure_threshold": 5,
            "success_threshold": 2,
            "timeout": 60.0,
            "half_open_max_calls": 3
        }
    
    def get_breaker(self, name: str, **config) -> CircuitBreaker:
        """Get or create circuit breaker"""
        if name not in self._breakers:
            breaker_config = {**self._default_config, **config}
            self._breakers[name] = CircuitBreaker(**breaker_config)
        
        return self._breakers[name]
    
    def get_all_states(self) -> Dict[str, Dict[str, Any]]:
        """Get all circuit breaker states"""
        return {
            name: breaker.get_state()
            for name, breaker in self._breakers.items()
        }

# Decorator for circuit breaker
def circuit_breaker(
    name: str,
    registry: CircuitBreakerRegistry,
    **config
):
    """Circuit breaker decorator"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            breaker = registry.get_breaker(name, **config)
            return await breaker.call(func, *args, **kwargs)
        return wrapper
    return decorator

# Resilient HTTP client
class ResilientHTTPClient:
    """HTTP client with circuit breaker and retries"""
    
    def __init__(
        self,
        circuit_registry: CircuitBreakerRegistry,
        timeout: float = 30.0,
        max_retries: int = 3
    ):
        self.circuit_registry = circuit_registry
        self.timeout = timeout
        self.max_retries = max_retries
        self.http_client = httpx.AsyncClient(timeout=timeout)
    
    async def request(
        self,
        method: str,
        url: str,
        service_name: str,
        **kwargs
    ) -> httpx.Response:
        """Make resilient HTTP request"""
        breaker = self.circuit_registry.get_breaker(service_name)
        
        async def make_request():
            retries = 0
            last_error = None
            
            while retries < self.max_retries:
                try:
                    response = await self.http_client.request(
                        method=method,
                        url=url,
                        **kwargs
                    )
                    
                    # Check for server errors
                    if response.status_code >= 500:
                        raise HTTPException(
                            status_code=response.status_code,
                            detail=response.text
                        )
                    
                    return response
                    
                except httpx.TimeoutException as e:
                    last_error = e
                    retries += 1
                    
                    if retries < self.max_retries:
                        # Exponential backoff
                        await asyncio.sleep(2 ** retries)
                    
                except Exception as e:
                    last_error = e
                    raise
            
            raise last_error
        
        return await breaker.call(make_request)
```

## 📊 Saga Pattern

### Distributed Transaction Management

```python
# Saga orchestrator
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional
import uuid

class SagaStep(ABC):
    """Base saga step"""
    
    @abstractmethod
    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute step"""
        pass
    
    @abstractmethod
    async def compensate(self, context: Dict[str, Any]) -> None:
        """Compensate step"""
        pass

class SagaOrchestrator:
    """Orchestrate saga execution"""
    
    def __init__(self, saga_id: Optional[str] = None):
        self.saga_id = saga_id or str(uuid.uuid4())
        self.steps: List[SagaStep] = []
        self.executed_steps: List[int] = []
        self.context: Dict[str, Any] = {"saga_id": self.saga_id}
        self.status = "pending"
    
    def add_step(self, step: SagaStep):
        """Add step to saga"""
        self.steps.append(step)
    
    async def execute(self) -> Dict[str, Any]:
        """Execute saga"""
        self.status = "running"
        
        try:
            # Execute steps in order
            for i, step in enumerate(self.steps):
                logger.info(f"Executing step {i} of saga {self.saga_id}")
                
                result = await step.execute(self.context)
                self.context.update(result)
                self.executed_steps.append(i)
                
                # Persist saga state
                await self._save_state()
            
            self.status = "completed"
            await self._save_state()
            
            return self.context
            
        except Exception as e:
            logger.error(f"Saga {self.saga_id} failed: {e}")
            self.status = "failed"
            
            # Compensate in reverse order
            await self._compensate()
            
            raise SagaFailedException(f"Saga failed: {e}")
    
    async def _compensate(self):
        """Compensate executed steps"""
        logger.info(f"Compensating saga {self.saga_id}")
        
        # Compensate in reverse order
        for step_index in reversed(self.executed_steps):
            try:
                step = self.steps[step_index]
                await step.compensate(self.context)
            except Exception as e:
                logger.error(
                    f"Failed to compensate step {step_index}: {e}"
                )
        
        self.status = "compensated"
        await self._save_state()
    
    async def _save_state(self):
        """Persist saga state"""
        # Implementation depends on storage
        pass

# Example: Order processing saga
class CreateOrderStep(SagaStep):
    """Create order step"""
    
    def __init__(self, order_service: Any):
        self.order_service = order_service
    
    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        order = await self.order_service.create_order(
            customer_id=context["customer_id"],
            items=context["items"]
        )
        return {"order_id": order.id}
    
    async def compensate(self, context: Dict[str, Any]) -> None:
        if "order_id" in context:
            await self.order_service.cancel_order(context["order_id"])

class ReserveInventoryStep(SagaStep):
    """Reserve inventory step"""
    
    def __init__(self, inventory_service: Any):
        self.inventory_service = inventory_service
    
    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        reservation_id = await self.inventory_service.reserve_items(
            items=context["items"],
            order_id=context["order_id"]
        )
        return {"reservation_id": reservation_id}
    
    async def compensate(self, context: Dict[str, Any]) -> None:
        if "reservation_id" in context:
            await self.inventory_service.release_reservation(
                context["reservation_id"]
            )

class ProcessPaymentStep(SagaStep):
    """Process payment step"""
    
    def __init__(self, payment_service: Any):
        self.payment_service = payment_service
    
    async def execute(self, context: Dict[str, Any]) -> Dict[str, Any]:
        payment = await self.payment_service.process_payment(
            customer_id=context["customer_id"],
            amount=context["total_amount"],
            order_id=context["order_id"]
        )
        return {"payment_id": payment.id}
    
    async def compensate(self, context: Dict[str, Any]) -> None:
        if "payment_id" in context:
            await self.payment_service.refund_payment(
                context["payment_id"]
            )

# Choreography-based saga
class EventBasedSaga:
    """Event-driven saga implementation"""
    
    def __init__(self, event_bus: EventBus):
        self.event_bus = event_bus
        self.saga_states: Dict[str, Dict] = {}
    
    async def start_saga(self, saga_type: str, initial_data: Dict[str, Any]):
        """Start new saga"""
        saga_id = str(uuid.uuid4())
        
        # Initialize saga state
        self.saga_states[saga_id] = {
            "type": saga_type,
            "status": "started",
            "data": initial_data,
            "completed_steps": []
        }
        
        # Publish initial event
        await self.event_bus.publish(
            f"{saga_type}.started",
            {
                "saga_id": saga_id,
                **initial_data
            }
        )
        
        return saga_id
    
    async def handle_event(self, event_type: str, event_data: Dict[str, Any]):
        """Handle saga event"""
        saga_id = event_data.get("saga_id")
        if not saga_id or saga_id not in self.saga_states:
            return
        
        saga_state = self.saga_states[saga_id]
        
        # Update saga state based on event
        if event_type.endswith(".completed"):
            step_name = event_type.split(".")[1]
            saga_state["completed_steps"].append(step_name)
            
            # Check if saga is complete
            if self._is_saga_complete(saga_state):
                saga_state["status"] = "completed"
                await self.event_bus.publish(
                    f"{saga_state['type']}.completed",
                    {"saga_id": saga_id}
                )
        
        elif event_type.endswith(".failed"):
            saga_state["status"] = "failed"
            
            # Start compensation
            await self._start_compensation(saga_id, saga_state)
    
    async def _start_compensation(self, saga_id: str, saga_state: Dict):
        """Start compensation process"""
        for step in reversed(saga_state["completed_steps"]):
            await self.event_bus.publish(
                f"{saga_state['type']}.{step}.compensate",
                {
                    "saga_id": saga_id,
                    **saga_state["data"]
                }
            )
```

## 🕸️ Service Mesh

### Service Mesh Integration

```python
# Envoy proxy configuration
import yaml
from typing import Dict, List, Any

class EnvoyConfigGenerator:
    """Generate Envoy proxy configuration"""
    
    def __init__(self, service_name: str, service_port: int):
        self.service_name = service_name
        self.service_port = service_port
    
    def generate_config(
        self,
        upstream_services: List[Dict[str, Any]]
    ) -> str:
        """Generate Envoy configuration"""
        config = {
            "admin": {
                "address": {
                    "socket_address": {
                        "address": "0.0.0.0",
                        "port_value": 9901
                    }
                }
            },
            "static_resources": {
                "listeners": self._generate_listeners(),
                "clusters": self._generate_clusters(upstream_services)
            }
        }
        
        return yaml.dump(config)
    
    def _generate_listeners(self) -> List[Dict[str, Any]]:
        """Generate listener configuration"""
        return [{
            "name": "listener_0",
            "address": {
                "socket_address": {
                    "address": "0.0.0.0",
                    "port_value": 10000
                }
            },
            "filter_chains": [{
                "filters": [{
                    "name": "envoy.filters.network.http_connection_manager",
                    "typed_config": {
                        "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager",
                        "stat_prefix": "ingress_http",
                        "codec_type": "AUTO",
                        "route_config": {
                            "name": "local_route",
                            "virtual_hosts": [{
                                "name": "backend",
                                "domains": ["*"],
                                "routes": [{
                                    "match": {"prefix": "/"},
                                    "route": {
                                        "cluster": "local_service",
                                        "timeout": "30s"
                                    }
                                }]
                            }]
                        },
                        "http_filters": [
                            {
                                "name": "envoy.filters.http.router",
                                "typed_config": {
                                    "@type": "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router"
                                }
                            }
                        ]
                    }
                }]
            }]
        }]
    
    def _generate_clusters(
        self,
        upstream_services: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Generate cluster configuration"""
        clusters = [{
            "name": "local_service",
            "connect_timeout": "30s",
            "type": "STATIC",
            "lb_policy": "ROUND_ROBIN",
            "load_assignment": {
                "cluster_name": "local_service",
                "endpoints": [{
                    "lb_endpoints": [{
                        "endpoint": {
                            "address": {
                                "socket_address": {
                                    "address": "127.0.0.1",
                                    "port_value": self.service_port
                                }
                            }
                        }
                    }]
                }]
            }
        }]
        
        # Add upstream clusters
        for service in upstream_services:
            clusters.append({
                "name": service["name"],
                "connect_timeout": "30s",
                "type": "EDS",
                "eds_cluster_config": {
                    "eds_config": {
                        "resource_api_version": "V3",
                        "api_config_source": {
                            "api_type": "GRPC",
                            "transport_api_version": "V3",
                            "grpc_services": [{
                                "envoy_grpc": {
                                    "cluster_name": "xds-grpc"
                                }
                            }]
                        }
                    }
                }
            })
        
        return clusters

# Istio integration
class IstioServiceMesh:
    """Istio service mesh integration"""
    
    def __init__(self, kubernetes_client):
        self.k8s = kubernetes_client
    
    async def create_virtual_service(
        self,
        name: str,
        namespace: str,
        hosts: List[str],
        routes: List[Dict[str, Any]]
    ):
        """Create Istio VirtualService"""
        virtual_service = {
            "apiVersion": "networking.istio.io/v1beta1",
            "kind": "VirtualService",
            "metadata": {
                "name": name,
                "namespace": namespace
            },
            "spec": {
                "hosts": hosts,
                "http": routes
            }
        }
        
        # Apply to Kubernetes
        await self.k8s.create_custom_object(
            group="networking.istio.io",
            version="v1beta1",
            namespace=namespace,
            plural="virtualservices",
            body=virtual_service
        )
    
    async def create_destination_rule(
        self,
        name: str,
        namespace: str,
        host: str,
        subsets: List[Dict[str, Any]]
    ):
        """Create Istio DestinationRule"""
        destination_rule = {
            "apiVersion": "networking.istio.io/v1beta1",
            "kind": "DestinationRule",
            "metadata": {
                "name": name,
                "namespace": namespace
            },
            "spec": {
                "host": host,
                "trafficPolicy": {
                    "connectionPool": {
                        "tcp": {
                            "maxConnections": 100
                        },
                        "http": {
                            "http1MaxPendingRequests": 100,
                            "http2MaxRequests": 100
                        }
                    },
                    "loadBalancer": {
                        "simple": "ROUND_ROBIN"
                    },
                    "outlierDetection": {
                        "consecutiveErrors": 5,
                        "interval": "30s",
                        "baseEjectionTime": "30s",
                        "maxEjectionPercent": 50
                    }
                },
                "subsets": subsets
            }
        }
        
        await self.k8s.create_custom_object(
            group="networking.istio.io",
            version="v1beta1",
            namespace=namespace,
            plural="destinationrules",
            body=destination_rule
        )
```

## 📊 Distributed Tracing

### OpenTelemetry Implementation

```python
# Distributed tracing with OpenTelemetry
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.propagate import inject, extract
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

# Configure tracing
def configure_tracing(service_name: str, otlp_endpoint: str):
    """Configure OpenTelemetry tracing"""
    # Set up tracer provider
    provider = TracerProvider()
    trace.set_tracer_provider(provider)
    
    # Configure OTLP exporter
    otlp_exporter = OTLPSpanExporter(
        endpoint=otlp_endpoint,
        insecure=True
    )
    
    # Add span processor
    span_processor = BatchSpanProcessor(otlp_exporter)
    provider.add_span_processor(span_processor)
    
    # Instrument libraries
    FastAPIInstrumentor.instrument(
        tracer_provider=provider,
        excluded_urls="health,metrics"
    )
    HTTPXClientInstrumentor.instrument(
        tracer_provider=provider
    )
    
    return trace.get_tracer(service_name)

# Tracing middleware
class TracingMiddleware:
    """Add tracing to requests"""
    
    def __init__(self, app, tracer):
        self.app = app
        self.tracer = tracer
        self.propagator = TraceContextTextMapPropagator()
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        # Extract trace context
        headers = dict(scope["headers"])
        context = extract(headers)
        
        # Start span
        with self.tracer.start_as_current_span(
            f"{scope['method']} {scope['path']}",
            context=context,
            kind=trace.SpanKind.SERVER
        ) as span:
            # Add attributes
            span.set_attribute("http.method", scope["method"])
            span.set_attribute("http.url", scope["path"])
            span.set_attribute("http.scheme", scope["scheme"])
            
            # Handle request
            await self.app(scope, receive, send)

# Distributed context propagation
class DistributedContext:
    """Manage distributed context"""
    
    def __init__(self):
        self.propagator = TraceContextTextMapPropagator()
    
    def inject_context(self, headers: Dict[str, str]) -> Dict[str, str]:
        """Inject trace context into headers"""
        inject(headers)
        return headers
    
    def extract_context(self, headers: Dict[str, str]):
        """Extract trace context from headers"""
        return extract(headers)

# Custom instrumentation
def trace_function(tracer, name: str):
    """Decorator for tracing functions"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(name) as span:
                try:
                    # Add function arguments as attributes
                    span.set_attribute("function.name", func.__name__)
                    
                    result = await func(*args, **kwargs)
                    
                    span.set_status(trace.StatusCode.OK)
                    return result
                    
                except Exception as e:
                    span.set_status(
                        trace.StatusCode.ERROR,
                        str(e)
                    )
                    span.record_exception(e)
                    raise
        
        return wrapper
    return decorator

# Metrics collection
from prometheus_client import Counter, Histogram, Gauge

class ServiceMetrics:
    """Service-level metrics"""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        
        # Request metrics
        self.request_count = Counter(
            f'{service_name}_requests_total',
            'Total requests',
            ['method', 'endpoint', 'status']
        )
        
        self.request_duration = Histogram(
            f'{service_name}_request_duration_seconds',
            'Request duration',
            ['method', 'endpoint']
        )
        
        # Service metrics
        self.active_connections = Gauge(
            f'{service_name}_active_connections',
            'Active connections'
        )
        
        self.error_count = Counter(
            f'{service_name}_errors_total',
            'Total errors',
            ['type']
        )
    
    def record_request(
        self,
        method: str,
        endpoint: str,
        status: int,
        duration: float
    ):
        """Record request metrics"""
        self.request_count.labels(
            method=method,
            endpoint=endpoint,
            status=str(status)
        ).inc()
        
        self.request_duration.labels(
            method=method,
            endpoint=endpoint
        ).observe(duration)
    
    def record_error(self, error_type: str):
        """Record error"""
        self.error_count.labels(type=error_type).inc()
```

## 🚀 Best Practices

### 1. **Service Design**
- Keep services small and focused
- Design for failure
- Use async communication where possible
- Implement health checks
- Version your APIs

### 2. **Communication**
- Use circuit breakers for resilience
- Implement timeouts appropriately
- Handle partial failures gracefully
- Use idempotent operations
- Implement retry with backoff

### 3. **Data Management**
- Each service owns its data
- Use event sourcing for audit trails
- Implement saga pattern for transactions
- Handle eventual consistency
- Use CQRS where appropriate

### 4. **Observability**
- Implement distributed tracing
- Collect metrics at service level
- Centralize logging
- Create meaningful dashboards
- Set up alerting

### 5. **Deployment**
- Use container orchestration
- Implement blue-green deployments
- Use feature flags
- Automate rollbacks
- Monitor deployment health

### 6. **Security**
- Implement service-to-service authentication
- Use mTLS for internal communication
- Implement API gateway security
- Use service mesh for policy enforcement
- Regular security audits

## 📖 Resources & References

### Books & Articles
- "Building Microservices" by Sam Newman
- "Microservices Patterns" by Chris Richardson
- "Release It!" by Michael Nygard
- [Martin Fowler's Microservices Articles](https://martinfowler.com/microservices/)

### Frameworks & Tools
- **Service Mesh** - Istio, Linkerd, Consul Connect
- **API Gateway** - Kong, Zuul, Envoy
- **Service Discovery** - Consul, Eureka, etcd
- **Orchestration** - Kubernetes, Docker Swarm, Nomad
- **Monitoring** - Prometheus, Grafana, Jaeger, ELK Stack

### Patterns References
- [Microservices.io](https://microservices.io/patterns/)
- [Azure Microservices Architecture](https://docs.microsoft.com/en-us/azure/architecture/microservices/)
- [AWS Microservices](https://aws.amazon.com/microservices/)
- [Google Cloud Microservices](https://cloud.google.com/architecture/microservices-architecture)

---

*This guide covers essential microservices patterns for building distributed systems. Remember that microservices add complexity - ensure the benefits outweigh the costs for your use case.*
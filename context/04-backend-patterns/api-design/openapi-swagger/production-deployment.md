# Production Deployment Patterns for OpenAPI Documentation

## Overview

Deploying OpenAPI documentation in production requires careful consideration of performance, security, scalability, and maintenance. This guide covers modern deployment patterns, infrastructure setup, and operational best practices for enterprise-grade API documentation in 2025.

## 🏗️ Architecture Patterns

### Microservices Documentation Architecture

```yaml
# Distributed documentation architecture
version: "3.8"
services:
  # API Gateway with documentation aggregation
  api-gateway:
    image: kong:3.4
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: "/kong/kong.yml"
      KONG_PROXY_ACCESS_LOG: "/dev/stdout"
      KONG_ADMIN_ACCESS_LOG: "/dev/stdout"
      KONG_PROXY_ERROR_LOG: "/dev/stderr"
      KONG_ADMIN_ERROR_LOG: "/dev/stderr"
      KONG_ADMIN_LISTEN: "0.0.0.0:8001"
    volumes:
      - ./kong.yml:/kong/kong.yml
    ports:
      - "8000:8000"
      - "8001:8001"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.example.com`)"

  # Documentation aggregator service
  docs-aggregator:
    build: ./docs-aggregator
    environment:
      - SERVICES_CONFIG=/config/services.yml
      - CACHE_REDIS_URL=redis://redis:6379
      - STORAGE_TYPE=s3
      - AWS_BUCKET=api-docs-storage
    volumes:
      - ./config:/config
    depends_on:
      - redis
      - api-gateway
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.docs.rule=Host(`docs.example.com`)"

  # Redis for caching
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    environment:
      - REDIS_PASSWORD=your_redis_password

  # Individual service documentation
  user-service-docs:
    build: ./services/user-service/docs
    environment:
      - SERVICE_NAME=user-service
      - SERVICE_VERSION=v1
      - OPENAPI_URL=http://user-service:8080/openapi.json
      - MCP_ENABLED=true
    depends_on:
      - user-service

  product-service-docs:
    build: ./services/product-service/docs
    environment:
      - SERVICE_NAME=product-service
      - SERVICE_VERSION=v1
      - OPENAPI_URL=http://product-service:8080/openapi.json
      - MCP_ENABLED=true
    depends_on:
      - product-service

  # Service mesh sidecar for documentation
  envoy-docs:
    image: envoyproxy/envoy:v1.28-latest
    volumes:
      - ./envoy-docs.yaml:/etc/envoy/envoy.yaml
    ports:
      - "9000:9000"
    environment:
      - ENVOY_UID=0

volumes:
  redis_data:

networks:
  default:
    external:
      name: api-network
```

### Documentation Aggregation Service

```python
# docs-aggregator/app.py
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, HttpUrl
from typing import List, Dict, Optional
import asyncio
import aiohttp
import redis.asyncio as redis
import json
import yaml
from datetime import datetime, timedelta
import logging

app = FastAPI(
    title="API Documentation Aggregator",
    description="Centralized documentation for all microservices",
    version="1.0.0"
)

# Configuration
class ServiceConfig(BaseModel):
    name: str
    version: str
    openapi_url: HttpUrl
    health_url: HttpUrl
    documentation_url: Optional[HttpUrl] = None
    mcp_enabled: bool = False
    cache_ttl: int = 300  # 5 minutes

class AggregatorConfig(BaseModel):
    services: List[ServiceConfig]
    cache_ttl: int = 300
    refresh_interval: int = 60
    max_retries: int = 3

# Global configuration
config: AggregatorConfig = None
redis_client: redis.Redis = None

async def startup():
    """Initialize the aggregator service"""
    global config, redis_client
    
    # Load configuration
    with open('/config/services.yml', 'r') as f:
        config_data = yaml.safe_load(f)
    config = AggregatorConfig(**config_data)
    
    # Initialize Redis
    redis_client = redis.from_url("redis://redis:6379")
    
    # Start background refresh task
    asyncio.create_task(refresh_documentation_loop())

@app.on_event("startup")
async def startup_event():
    await startup()

class DocumentationAggregator:
    """Service for aggregating OpenAPI documentation"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    async def fetch_service_documentation(self, service: ServiceConfig) -> Optional[Dict]:
        """Fetch OpenAPI documentation from a service"""
        try:
            async with aiohttp.ClientSession() as session:
                # Check service health
                async with session.get(str(service.health_url), timeout=10) as health_response:
                    if health_response.status != 200:
                        self.logger.warning(f"Service {service.name} is unhealthy")
                        return None
                
                # Fetch OpenAPI specification
                async with session.get(str(service.openapi_url), timeout=30) as response:
                    if response.status == 200:
                        spec = await response.json()
                        
                        # Add service metadata
                        spec['x-service-metadata'] = {
                            'service_name': service.name,
                            'service_version': service.version,
                            'last_updated': datetime.utcnow().isoformat(),
                            'mcp_enabled': service.mcp_enabled,
                            'health_url': str(service.health_url),
                            'documentation_url': str(service.documentation_url) if service.documentation_url else None
                        }
                        
                        return spec
                    else:
                        self.logger.error(f"Failed to fetch docs for {service.name}: {response.status}")
                        return None
                        
        except Exception as e:
            self.logger.error(f"Error fetching documentation for {service.name}: {e}")
            return None
    
    async def aggregate_documentation(self) -> Dict:
        """Aggregate documentation from all services"""
        aggregated_spec = {
            "openapi": "3.1.0",
            "info": {
                "title": "Aggregated API Documentation",
                "description": "Combined documentation for all microservices",
                "version": "1.0.0",
                "contact": {
                    "name": "API Team",
                    "email": "api-team@example.com"
                }
            },
            "servers": [
                {
                    "url": "https://api.example.com",
                    "description": "Production API Gateway"
                }
            ],
            "paths": {},
            "components": {
                "schemas": {},
                "securitySchemes": {},
                "responses": {},
                "parameters": {}
            },
            "tags": [],
            "x-aggregation-metadata": {
                "aggregated_at": datetime.utcnow().isoformat(),
                "services": [],
                "total_endpoints": 0
            }
        }
        
        # Fetch documentation from all services
        tasks = [
            self.fetch_service_documentation(service)
            for service in config.services
        ]
        
        service_docs = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Merge service documentation
        for i, doc in enumerate(service_docs):
            if isinstance(doc, Exception) or doc is None:
                continue
                
            service = config.services[i]
            service_prefix = f"/{service.name}"
            
            # Add service metadata
            aggregated_spec["x-aggregation-metadata"]["services"].append({
                "name": service.name,
                "version": service.version,
                "endpoint_count": len(doc.get("paths", {})),
                "last_updated": doc.get("x-service-metadata", {}).get("last_updated"),
                "mcp_enabled": service.mcp_enabled
            })
            
            # Merge paths with service prefix
            for path, path_item in doc.get("paths", {}).items():
                prefixed_path = f"{service_prefix}{path}"
                
                # Add service tags to operations
                for method, operation in path_item.items():
                    if isinstance(operation, dict) and "tags" in operation:
                        operation["tags"] = [f"{service.name}-{tag}" for tag in operation["tags"]]
                        
                        # Add service context
                        operation["x-service-context"] = {
                            "service_name": service.name,
                            "service_version": service.version,
                            "original_path": path
                        }
                
                aggregated_spec["paths"][prefixed_path] = path_item
            
            # Merge components with service prefix
            for component_type in ["schemas", "responses", "parameters"]:
                if component_type in doc.get("components", {}):
                    for name, component in doc["components"][component_type].items():
                        prefixed_name = f"{service.name}_{name}"
                        aggregated_spec["components"][component_type][prefixed_name] = component
            
            # Merge security schemes
            if "securitySchemes" in doc.get("components", {}):
                aggregated_spec["components"]["securitySchemes"].update(
                    doc["components"]["securitySchemes"]
                )
            
            # Add service-specific tags
            service_tag = {
                "name": service.name,
                "description": f"Operations for {service.name} service",
                "externalDocs": {
                    "description": f"{service.name} documentation",
                    "url": str(service.documentation_url) if service.documentation_url else "#"
                }
            }
            aggregated_spec["tags"].append(service_tag)
        
        # Update total endpoint count
        aggregated_spec["x-aggregation-metadata"]["total_endpoints"] = len(aggregated_spec["paths"])
        
        return aggregated_spec
    
    async def cache_documentation(self, spec: Dict) -> None:
        """Cache the aggregated documentation"""
        try:
            await redis_client.setex(
                "aggregated_docs",
                config.cache_ttl,
                json.dumps(spec)
            )
            self.logger.info("Documentation cached successfully")
        except Exception as e:
            self.logger.error(f"Failed to cache documentation: {e}")
    
    async def get_cached_documentation(self) -> Optional[Dict]:
        """Get cached documentation"""
        try:
            cached = await redis_client.get("aggregated_docs")
            if cached:
                return json.loads(cached)
        except Exception as e:
            self.logger.error(f"Failed to get cached documentation: {e}")
        
        return None

aggregator = DocumentationAggregator()

async def refresh_documentation_loop():
    """Background task to refresh documentation periodically"""
    while True:
        try:
            logging.info("Refreshing aggregated documentation")
            spec = await aggregator.aggregate_documentation()
            await aggregator.cache_documentation(spec)
            logging.info("Documentation refresh completed")
        except Exception as e:
            logging.error(f"Error in documentation refresh: {e}")
        
        await asyncio.sleep(config.refresh_interval)

@app.get("/openapi.json")
async def get_aggregated_openapi():
    """Get the aggregated OpenAPI specification"""
    # Try to get from cache first
    cached_spec = await aggregator.get_cached_documentation()
    if cached_spec:
        return cached_spec
    
    # Generate fresh if not cached
    spec = await aggregator.aggregate_documentation()
    await aggregator.cache_documentation(spec)
    return spec

@app.get("/docs", response_class=HTMLResponse)
async def get_swagger_ui():
    """Serve Swagger UI for aggregated documentation"""
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>API Documentation</title>
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
        <style>
            .swagger-ui .topbar {{ display: none; }}
            .swagger-ui .info {{ margin: 20px 0; }}
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
        <script>
            SwaggerUIBundle({{
                url: '/openapi.json',
                dom_id: '#swagger-ui',
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.presets.standalone
                ],
                layout: "BaseLayout",
                deepLinking: true,
                showExtensions: true,
                showCommonExtensions: true,
                tryItOutEnabled: true,
                requestSnippetsEnabled: true,
                supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch'],
                validatorUrl: null,
                plugins: [
                    SwaggerUIBundle.plugins.DownloadUrl
                ]
            }});
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check Redis connection
        await redis_client.ping()
        
        # Check if we have cached documentation
        cached = await redis_client.get("aggregated_docs")
        
        return {
            "status": "healthy",
            "redis_connected": True,
            "documentation_cached": cached is not None,
            "services_configured": len(config.services),
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {e}")

@app.post("/refresh")
async def trigger_refresh(background_tasks: BackgroundTasks):
    """Manually trigger documentation refresh"""
    async def refresh_task():
        spec = await aggregator.aggregate_documentation()
        await aggregator.cache_documentation(spec)
    
    background_tasks.add_task(refresh_task)
    return {"message": "Documentation refresh triggered"}

@app.get("/services")
async def list_services():
    """List all configured services and their status"""
    services_status = []
    
    for service in config.services:
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(str(service.health_url), timeout=5) as response:
                    healthy = response.status == 200
        except:
            healthy = False
        
        services_status.append({
            "name": service.name,
            "version": service.version,
            "healthy": healthy,
            "mcp_enabled": service.mcp_enabled,
            "openapi_url": str(service.openapi_url),
            "documentation_url": str(service.documentation_url) if service.documentation_url else None
        })
    
    return {"services": services_status}
```

## 🚀 Kubernetes Deployment

### Kubernetes Manifests

```yaml
# kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: api-docs
  labels:
    name: api-docs
    environment: production

---
# kubernetes/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: docs-config
  namespace: api-docs
data:
  services.yml: |
    services:
      - name: user-service
        version: v1
        openapi_url: http://user-service.default.svc.cluster.local:8080/openapi.json
        health_url: http://user-service.default.svc.cluster.local:8080/health
        documentation_url: https://docs.example.com/user-service
        mcp_enabled: true
        cache_ttl: 300
      
      - name: product-service
        version: v1
        openapi_url: http://product-service.default.svc.cluster.local:8080/openapi.json
        health_url: http://product-service.default.svc.cluster.local:8080/health
        documentation_url: https://docs.example.com/product-service
        mcp_enabled: true
        cache_ttl: 300
    
    cache_ttl: 300
    refresh_interval: 60
    max_retries: 3

---
# kubernetes/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: docs-secrets
  namespace: api-docs
type: Opaque
stringData:
  redis-password: "your-secure-redis-password"
  aws-access-key-id: "your-aws-access-key"
  aws-secret-access-key: "your-aws-secret-key"

---
# kubernetes/redis-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: api-docs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command:
          - redis-server
          - --requirepass
          - $(REDIS_PASSWORD)
          - --appendonly
          - "yes"
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: docs-secrets
              key: redis-password
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-pvc

---
# kubernetes/redis-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-pvc
  namespace: api-docs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd

---
# kubernetes/redis-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: api-docs
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379

---
# kubernetes/docs-aggregator-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docs-aggregator
  namespace: api-docs
  labels:
    app: docs-aggregator
spec:
  replicas: 3
  selector:
    matchLabels:
      app: docs-aggregator
  template:
    metadata:
      labels:
        app: docs-aggregator
    spec:
      containers:
      - name: docs-aggregator
        image: your-registry/docs-aggregator:latest
        ports:
        - containerPort: 8000
        env:
        - name: SERVICES_CONFIG
          value: "/config/services.yml"
        - name: CACHE_REDIS_URL
          value: "redis://:$(REDIS_PASSWORD)@redis:6379"
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: docs-secrets
              key: redis-password
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: docs-secrets
              key: aws-access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: docs-secrets
              key: aws-secret-access-key
        - name: AWS_BUCKET
          value: "api-docs-storage"
        volumeMounts:
        - name: config-volume
          mountPath: /config
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: config-volume
        configMap:
          name: docs-config

---
# kubernetes/docs-aggregator-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: docs-aggregator
  namespace: api-docs
spec:
  selector:
    app: docs-aggregator
  ports:
  - port: 80
    targetPort: 8000
  type: ClusterIP

---
# kubernetes/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: docs-ingress
  namespace: api-docs
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  tls:
  - hosts:
    - docs.example.com
    secretName: docs-tls
  rules:
  - host: docs.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: docs-aggregator
            port:
              number: 80

---
# kubernetes/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: docs-aggregator-hpa
  namespace: api-docs
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: docs-aggregator
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Helm Chart

```yaml
# helm/docs-aggregator/Chart.yaml
apiVersion: v2
name: docs-aggregator
description: API Documentation Aggregator
version: 1.0.0
appVersion: "1.0.0"
dependencies:
  - name: redis
    version: "17.3.7"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled

---
# helm/docs-aggregator/values.yaml
# Default values for docs-aggregator
replicaCount: 3

image:
  repository: your-registry/docs-aggregator
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
  hosts:
    - host: docs.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: docs-tls
      hosts:
        - docs.example.com

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# Redis configuration
redis:
  enabled: true
  auth:
    enabled: true
    password: "your-secure-redis-password"
  architecture: standalone
  master:
    persistence:
      enabled: true
      size: 10Gi
      storageClass: "fast-ssd"

# Services configuration
services:
  - name: user-service
    version: v1
    openapi_url: http://user-service.default.svc.cluster.local:8080/openapi.json
    health_url: http://user-service.default.svc.cluster.local:8080/health
    documentation_url: https://docs.example.com/user-service
    mcp_enabled: true
    cache_ttl: 300

  - name: product-service
    version: v1
    openapi_url: http://product-service.default.svc.cluster.local:8080/openapi.json
    health_url: http://product-service.default.svc.cluster.local:8080/health
    documentation_url: https://docs.example.com/product-service
    mcp_enabled: true
    cache_ttl: 300

# Global configuration
config:
  cache_ttl: 300
  refresh_interval: 60
  max_retries: 3

# Monitoring
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    labels: {}
    interval: 30s

# Security
security:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1001
    fsGroup: 1001
  
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL

---
# helm/docs-aggregator/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "docs-aggregator.fullname" . }}
  labels:
    {{- include "docs-aggregator.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "docs-aggregator.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      labels:
        {{- include "docs-aggregator.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.security.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          {{- with .Values.security.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          env:
            - name: SERVICES_CONFIG
              value: "/config/services.yml"
            - name: CACHE_REDIS_URL
              value: "redis://:$(REDIS_PASSWORD)@{{ include "docs-aggregator.redis.fullname" . }}:6379"
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "docs-aggregator.fullname" . }}-secrets
                  key: redis-password
          volumeMounts:
            - name: config-volume
              mountPath: /config
            - name: tmp-volume
              mountPath: /tmp
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      volumes:
        - name: config-volume
          configMap:
            name: {{ include "docs-aggregator.fullname" . }}-config
        - name: tmp-volume
          emptyDir: {}
```

## 🔒 Security and Access Control

### Authentication and Authorization

```yaml
# Authentication configuration
x-security-config:
  # Multi-tier authentication
  authentication:
    public_access:
      enabled: true
      rate_limiting:
        requests_per_minute: 100
        burst_capacity: 20
      allowed_operations:
        - read_documentation
        - view_examples
        - test_endpoints
    
    authenticated_access:
      enabled: true
      methods: ["jwt", "api_key", "oauth2"]
      rate_limiting:
        requests_per_minute: 1000
        burst_capacity: 100
      allowed_operations:
        - all_public_operations
        - advanced_testing
        - code_generation
        - export_documentation
    
    admin_access:
      enabled: true
      methods: ["jwt_admin", "oauth2_admin"]
      rate_limiting:
        requests_per_minute: 5000
        burst_capacity: 500
      allowed_operations:
        - all_authenticated_operations
        - modify_documentation
        - manage_users
        - view_analytics
        - system_configuration
  
  # Role-based access control
  rbac:
    roles:
      - name: "documentation_viewer"
        description: "Can view and test documentation"
        permissions:
          - "docs:read"
          - "examples:execute"
          - "schema:explore"
      
      - name: "developer"
        description: "Full access to development features"
        permissions:
          - "documentation_viewer:*"
          - "code:generate"
          - "docs:export"
          - "testing:advanced"
      
      - name: "api_manager"
        description: "Can manage API documentation"
        permissions:
          - "developer:*"
          - "docs:modify"
          - "users:manage"
          - "analytics:view"
      
      - name: "system_admin"
        description: "Full system administration"
        permissions:
          - "api_manager:*"
          - "system:configure"
          - "monitoring:admin"
          - "security:manage"
  
  # API key management
  api_keys:
    generation:
      key_length: 32
      encoding: "base64"
      prefix: "sk_docs_"
    
    scoping:
      service_specific: true
      time_limited: true
      ip_restricted: true
      usage_limited: true
    
    rotation:
      automatic: true
      rotation_interval: "90d"
      grace_period: "7d"
      notification_period: "14d"

# Security middleware configuration
x-security-middleware:
  # Request validation
  request_validation:
    max_request_size: "10MB"
    allowed_content_types:
      - "application/json"
      - "application/x-www-form-urlencoded"
      - "multipart/form-data"
    
    header_validation:
      required_headers: ["User-Agent"]
      blocked_headers: ["X-Forwarded-For"]
      max_header_count: 50
      max_header_size: "8KB"
    
    query_parameter_validation:
      max_parameters: 50
      max_parameter_length: 1000
      blocked_parameters: ["__proto__", "constructor"]
  
  # Rate limiting
  rate_limiting:
    algorithms: ["token_bucket", "sliding_window"]
    storage: "redis"
    
    default_limits:
      requests_per_minute: 100
      requests_per_hour: 5000
      requests_per_day: 50000
    
    custom_limits:
      by_endpoint: true
      by_user_type: true
      by_ip_range: true
    
    abuse_prevention:
      ip_blocking: true
      pattern_detection: true
      progressive_penalties: true
  
  # Content security
  content_security:
    csp_policy: |
      default-src 'self';
      script-src 'self' 'unsafe-inline' https://unpkg.com;
      style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
      font-src 'self' https://fonts.gstatic.com;
      img-src 'self' data: https:;
      connect-src 'self' https://api.example.com;
    
    cors_policy:
      allowed_origins: ["https://docs.example.com"]
      allowed_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
      allowed_headers: ["Content-Type", "Authorization", "X-API-Key"]
      credentials_allowed: true
      max_age: 86400
    
    security_headers:
      x_content_type_options: "nosniff"
      x_frame_options: "DENY"
      x_xss_protection: "1; mode=block"
      strict_transport_security: "max-age=31536000; includeSubDomains"
```

### Infrastructure Security

```python
# security/security_middleware.py
from fastapi import Request, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.base import BaseHTTPMiddleware
from typing import Optional, List, Dict
import redis.asyncio as redis
import jwt
import time
import hashlib
import ipaddress
from datetime import datetime, timedelta
import logging

class SecurityMiddleware(BaseHTTPMiddleware):
    """Comprehensive security middleware for documentation service"""
    
    def __init__(self, app, config: Dict):
        super().__init__(app)
        self.config = config
        self.redis_client = redis.from_url(config['redis_url'])
        self.logger = logging.getLogger(__name__)
        
        # Initialize security components
        self.rate_limiter = RateLimiter(self.redis_client, config['rate_limiting'])
        self.auth_manager = AuthManager(config['authentication'])
        self.access_control = AccessControl(config['rbac'])
    
    async def dispatch(self, request: Request, call_next):
        """Security middleware pipeline"""
        
        # 1. Request validation
        await self.validate_request(request)
        
        # 2. Rate limiting
        await self.rate_limiter.check_rate_limit(request)
        
        # 3. Authentication
        user = await self.auth_manager.authenticate(request)
        
        # 4. Authorization
        await self.access_control.authorize(request, user)
        
        # 5. Security headers
        response = await call_next(request)
        self.add_security_headers(response)
        
        # 6. Audit logging
        await self.audit_log(request, response, user)
        
        return response
    
    async def validate_request(self, request: Request):
        """Validate incoming request for security"""
        
        # Check request size
        content_length = request.headers.get('content-length')
        if content_length and int(content_length) > self.config['max_request_size']:
            raise HTTPException(400, "Request too large")
        
        # Validate headers
        if len(request.headers) > self.config['max_header_count']:
            raise HTTPException(400, "Too many headers")
        
        # Check for malicious patterns
        for header_name, header_value in request.headers.items():
            if len(header_value) > self.config['max_header_size']:
                raise HTTPException(400, f"Header {header_name} too large")
            
            # Check for injection attempts
            if self.contains_malicious_pattern(header_value):
                self.logger.warning(f"Malicious pattern detected in header: {header_name}")
                raise HTTPException(400, "Invalid header content")
    
    def contains_malicious_pattern(self, value: str) -> bool:
        """Check for common malicious patterns"""
        malicious_patterns = [
            '<script', 'javascript:', 'data:text/html',
            'eval(', 'expression(', 'vbscript:',
            'onload=', 'onerror=', 'onclick=',
            '../', '..\\', '/etc/passwd', 'cmd.exe'
        ]
        
        value_lower = value.lower()
        return any(pattern in value_lower for pattern in malicious_patterns)
    
    def add_security_headers(self, response):
        """Add security headers to response"""
        security_headers = {
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'X-XSS-Protection': '1; mode=block',
            'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
            'Content-Security-Policy': self.config['csp_policy'],
            'Referrer-Policy': 'strict-origin-when-cross-origin',
            'Permissions-Policy': 'camera=(), microphone=(), geolocation=()'
        }
        
        for header, value in security_headers.items():
            response.headers[header] = value
    
    async def audit_log(self, request: Request, response, user: Optional[Dict]):
        """Log security events for audit"""
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'request_id': getattr(request.state, 'request_id', 'unknown'),
            'method': request.method,
            'path': str(request.url.path),
            'user_id': user.get('id') if user else None,
            'user_role': user.get('role') if user else None,
            'client_ip': self.get_client_ip(request),
            'user_agent': request.headers.get('user-agent'),
            'status_code': response.status_code,
            'response_size': response.headers.get('content-length', 0)
        }
        
        # Store in audit log
        await self.redis_client.lpush(
            'audit_log',
            json.dumps(log_entry)
        )
        
        # Keep only last 10000 entries
        await self.redis_client.ltrim('audit_log', 0, 9999)

class RateLimiter:
    """Redis-based rate limiter with multiple algorithms"""
    
    def __init__(self, redis_client, config: Dict):
        self.redis = redis_client
        self.config = config
    
    async def check_rate_limit(self, request: Request) -> bool:
        """Check if request should be rate limited"""
        
        # Generate rate limit key
        client_ip = self.get_client_ip(request)
        user_id = getattr(request.state, 'user_id', None)
        endpoint = f"{request.method}:{request.url.path}"
        
        # Check multiple rate limit tiers
        checks = [
            ('ip', client_ip, self.config['ip_limits']),
            ('user', user_id, self.config['user_limits']) if user_id else None,
            ('endpoint', f"{client_ip}:{endpoint}", self.config['endpoint_limits'])
        ]
        
        for limit_type, key, limits in filter(None, checks):
            if not await self.check_limit(limit_type, key, limits):
                raise HTTPException(
                    429,
                    detail={
                        "error": "RATE_LIMIT_EXCEEDED",
                        "message": f"Rate limit exceeded for {limit_type}",
                        "retry_after": limits['window_seconds']
                    },
                    headers={"Retry-After": str(limits['window_seconds'])}
                )
        
        return True
    
    async def check_limit(self, limit_type: str, key: str, limits: Dict) -> bool:
        """Check individual rate limit using sliding window"""
        
        cache_key = f"rate_limit:{limit_type}:{key}"
        window_seconds = limits['window_seconds']
        max_requests = limits['max_requests']
        
        # Current time
        now = time.time()
        window_start = now - window_seconds
        
        # Use Redis sorted set for sliding window
        pipe = self.redis.pipeline()
        
        # Remove old entries
        pipe.zremrangebyscore(cache_key, 0, window_start)
        
        # Count current requests
        pipe.zcard(cache_key)
        
        # Add current request
        pipe.zadd(cache_key, {str(now): now})
        
        # Set expiry
        pipe.expire(cache_key, window_seconds + 1)
        
        results = await pipe.execute()
        current_count = results[1]
        
        return current_count < max_requests
    
    def get_client_ip(self, request: Request) -> str:
        """Get client IP address"""
        # Check X-Forwarded-For header (behind proxy)
        forwarded_for = request.headers.get('x-forwarded-for')
        if forwarded_for:
            return forwarded_for.split(',')[0].strip()
        
        # Check X-Real-IP header
        real_ip = request.headers.get('x-real-ip')
        if real_ip:
            return real_ip
        
        # Fall back to direct connection
        return request.client.host if request.client else 'unknown'

class AuthManager:
    """Authentication manager supporting multiple auth methods"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.jwt_secret = config['jwt_secret']
        self.jwt_algorithm = config.get('jwt_algorithm', 'HS256')
    
    async def authenticate(self, request: Request) -> Optional[Dict]:
        """Authenticate request and return user info"""
        
        # Check for API key
        api_key = request.headers.get('x-api-key')
        if api_key:
            return await self.authenticate_api_key(api_key)
        
        # Check for JWT token
        auth_header = request.headers.get('authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header[7:]
            return await self.authenticate_jwt(token)
        
        # Check for OAuth token
        if auth_header and auth_header.startswith('OAuth '):
            token = auth_header[6:]
            return await self.authenticate_oauth(token)
        
        # Anonymous access allowed for public endpoints
        return None
    
    async def authenticate_jwt(self, token: str) -> Optional[Dict]:
        """Authenticate JWT token"""
        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
            )
            
            # Check expiration
            if payload.get('exp', 0) < time.time():
                return None
            
            return {
                'id': payload.get('sub'),
                'role': payload.get('role', 'user'),
                'permissions': payload.get('permissions', []),
                'auth_method': 'jwt'
            }
            
        except jwt.InvalidTokenError:
            return None
    
    async def authenticate_api_key(self, api_key: str) -> Optional[Dict]:
        """Authenticate API key"""
        # Hash the API key for lookup
        key_hash = hashlib.sha256(api_key.encode()).hexdigest()
        
        # Look up in database/cache
        # This is a simplified example - implement your key storage
        cached_key_info = await self.redis_client.get(f"api_key:{key_hash}")
        
        if cached_key_info:
            key_info = json.loads(cached_key_info)
            
            # Check if key is active and not expired
            if key_info.get('active') and key_info.get('expires_at', float('inf')) > time.time():
                return {
                    'id': key_info.get('user_id'),
                    'role': key_info.get('role', 'api_user'),
                    'permissions': key_info.get('permissions', []),
                    'auth_method': 'api_key',
                    'key_id': key_info.get('key_id')
                }
        
        return None
```

## 📊 Monitoring and Analytics

### Comprehensive Monitoring Setup

```yaml
# monitoring/prometheus-config.yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "docs_rules.yml"

scrape_configs:
  # Documentation service metrics
  - job_name: 'docs-aggregator'
    static_configs:
      - targets: ['docs-aggregator:8000']
    metrics_path: '/metrics'
    scrape_interval: 15s
    
  # Redis metrics
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    
  # Kubernetes metrics
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['api-docs']
    
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

---
# monitoring/docs_rules.yml
groups:
  - name: documentation.rules
    rules:
      # Documentation service availability
      - alert: DocumentationServiceDown
        expr: up{job="docs-aggregator"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Documentation service is down"
          description: "Documentation aggregator has been down for more than 1 minute"
      
      # High error rate
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High error rate in documentation service"
          description: "Error rate is {{ $value }} errors per second"
      
      # Response time alert
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time"
          description: "95th percentile response time is {{ $value }} seconds"
      
      # Cache hit rate
      - alert: LowCacheHitRate
        expr: rate(cache_hits_total[5m]) / (rate(cache_hits_total[5m]) + rate(cache_misses_total[5m])) < 0.8
        for: 10m
        labels:
          severity: info
        annotations:
          summary: "Low cache hit rate"
          description: "Cache hit rate is {{ $value | humanizePercentage }}"
      
      # Documentation staleness
      - alert: StaleDocumentation
        expr: time() - documentation_last_updated_timestamp > 3600
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "Documentation is stale"
          description: "Documentation hasn't been updated for over an hour"

---
# monitoring/grafana-dashboard.json
{
  "dashboard": {
    "id": null,
    "title": "API Documentation Monitoring",
    "tags": ["api", "documentation"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ],
        "yAxes": [
          {
            "label": "Requests/sec"
          }
        ]
      },
      {
        "id": 2,
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          },
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "99th percentile"
          }
        ]
      },
      {
        "id": 3,
        "title": "Error Rate by Status Code",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"4..\"}[5m])",
            "legendFormat": "4xx errors"
          },
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "5xx errors"
          }
        ]
      },
      {
        "id": 4,
        "title": "Cache Performance",
        "type": "singlestat",
        "targets": [
          {
            "expr": "rate(cache_hits_total[5m]) / (rate(cache_hits_total[5m]) + rate(cache_misses_total[5m]))",
            "legendFormat": "Hit Rate"
          }
        ],
        "valueName": "current",
        "format": "percentunit"
      },
      {
        "id": 5,
        "title": "Documentation Freshness",
        "type": "table",
        "targets": [
          {
            "expr": "documentation_last_updated_timestamp",
            "legendFormat": "{{service_name}}"
          }
        ]
      },
      {
        "id": 6,
        "title": "Active Users",
        "type": "graph",
        "targets": [
          {
            "expr": "active_users_total",
            "legendFormat": "Total Active Users"
          },
          {
            "expr": "active_users_total{user_type=\"authenticated\"}",
            "legendFormat": "Authenticated Users"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

### Application Metrics

```python
# monitoring/metrics.py
from prometheus_client import Counter, Histogram, Gauge, Summary, generate_latest
from prometheus_client import CollectorRegistry, multiprocess, CONTENT_TYPE_LATEST
from fastapi import Request, Response
from typing import Dict
import time
import psutil
import asyncio

# Create metrics registry
registry = CollectorRegistry()

# Request metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status'],
    registry=registry
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    registry=registry
)

# Cache metrics
CACHE_HITS = Counter(
    'cache_hits_total',
    'Total cache hits',
    ['cache_type'],
    registry=registry
)

CACHE_MISSES = Counter(
    'cache_misses_total',
    'Total cache misses',
    ['cache_type'],
    registry=registry
)

# Documentation metrics
DOCUMENTATION_LAST_UPDATED = Gauge(
    'documentation_last_updated_timestamp',
    'Timestamp of last documentation update',
    ['service_name'],
    registry=registry
)

DOCUMENTATION_SIZE = Gauge(
    'documentation_size_bytes',
    'Size of documentation in bytes',
    ['service_name'],
    registry=registry
)

# Service health metrics
SERVICE_HEALTH = Gauge(
    'service_health_status',
    'Health status of services (1=healthy, 0=unhealthy)',
    ['service_name'],
    registry=registry
)

# User activity metrics
ACTIVE_USERS = Gauge(
    'active_users_total',
    'Number of active users',
    ['user_type'],
    registry=registry
)

# System metrics
MEMORY_USAGE = Gauge(
    'memory_usage_bytes',
    'Memory usage in bytes',
    registry=registry
)

CPU_USAGE = Gauge(
    'cpu_usage_percent',
    'CPU usage percentage',
    registry=registry
)

class MetricsMiddleware:
    """Middleware to collect HTTP metrics"""
    
    def __init__(self):
        pass
    
    async def __call__(self, request: Request, call_next):
        # Start timer
        start_time = time.time()
        
        # Process request
        response = await call_next(request)
        
        # Calculate duration
        duration = time.time() - start_time
        
        # Extract labels
        method = request.method
        endpoint = self.normalize_endpoint(request.url.path)
        status = str(response.status_code)
        
        # Record metrics
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status).inc()
        REQUEST_DURATION.labels(method=method, endpoint=endpoint).observe(duration)
        
        return response
    
    def normalize_endpoint(self, path: str) -> str:
        """Normalize endpoint path for metrics"""
        # Replace UUIDs and IDs with placeholders
        import re
        
        # Replace UUIDs
        path = re.sub(
            r'/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
            '/{uuid}',
            path
        )
        
        # Replace numeric IDs
        path = re.sub(r'/\d+', '/{id}', path)
        
        return path

class MetricsCollector:
    """Collect various application metrics"""
    
    def __init__(self):
        self.start_system_metrics_collection()
    
    def record_cache_hit(self, cache_type: str):
        """Record a cache hit"""
        CACHE_HITS.labels(cache_type=cache_type).inc()
    
    def record_cache_miss(self, cache_type: str):
        """Record a cache miss"""
        CACHE_MISSES.labels(cache_type=cache_type).inc()
    
    def update_documentation_metrics(self, service_name: str, size_bytes: int):
        """Update documentation metrics"""
        DOCUMENTATION_LAST_UPDATED.labels(service_name=service_name).set_to_current_time()
        DOCUMENTATION_SIZE.labels(service_name=service_name).set(size_bytes)
    
    def update_service_health(self, service_name: str, is_healthy: bool):
        """Update service health status"""
        SERVICE_HEALTH.labels(service_name=service_name).set(1 if is_healthy else 0)
    
    def update_active_users(self, authenticated_count: int, anonymous_count: int):
        """Update active user counts"""
        ACTIVE_USERS.labels(user_type="authenticated").set(authenticated_count)
        ACTIVE_USERS.labels(user_type="anonymous").set(anonymous_count)
        ACTIVE_USERS.labels(user_type="total").set(authenticated_count + anonymous_count)
    
    def start_system_metrics_collection(self):
        """Start collecting system metrics"""
        async def collect_system_metrics():
            while True:
                # Memory usage
                memory = psutil.virtual_memory()
                MEMORY_USAGE.set(memory.used)
                
                # CPU usage
                cpu_percent = psutil.cpu_percent(interval=1)
                CPU_USAGE.set(cpu_percent)
                
                await asyncio.sleep(30)  # Collect every 30 seconds
        
        asyncio.create_task(collect_system_metrics())

# Global metrics collector instance
metrics_collector = MetricsCollector()

@app.get("/metrics")
async def get_metrics():
    """Endpoint to expose Prometheus metrics"""
    return Response(
        content=generate_latest(registry),
        media_type=CONTENT_TYPE_LATEST
    )
```

---

*This completes our comprehensive guide to OpenAPI/Swagger documentation best practices for 2025. The guide covers everything from fundamental concepts to production deployment patterns, ensuring your API documentation serves both human developers and AI agents effectively.*
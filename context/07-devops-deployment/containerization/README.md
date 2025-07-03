# Docker Containerization Guide

Comprehensive guide to containerizing applications with Docker, from development to production deployment patterns.

## 🐳 What is Docker?

Docker is a containerization platform that packages applications and their dependencies into lightweight, portable containers:
- **Consistent Environments** - Same behavior across dev, staging, production
- **Isolation** - Applications run in isolated environments
- **Portability** - Containers run anywhere Docker is supported
- **Scalability** - Easy horizontal scaling with orchestration
- **Resource Efficiency** - Lightweight compared to virtual machines

## 🚀 Quick Start

### Installation
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# macOS (using Homebrew)
brew install --cask docker

# Windows
# Download Docker Desktop from https://www.docker.com/products/docker-desktop
```

### Basic Commands
```bash
# Check installation
docker --version
docker info

# Run a container
docker run hello-world

# List running containers
docker ps

# List all containers
docker ps -a

# List images
docker images

# Remove container
docker rm <container_id>

# Remove image
docker rmi <image_id>
```

## 📁 Project Structure for Containerization

```
project/
├── docker/
│   ├── development/
│   │   └── Dockerfile
│   ├── production/
│   │   └── Dockerfile
│   └── nginx/
│       ├── Dockerfile
│       └── nginx.conf
├── docker-compose.yml
├── docker-compose.prod.yml
├── .dockerignore
├── Dockerfile
└── src/
    ├── app/
    └── requirements.txt
```

## 🐍 Python Application Containerization

### Basic Python Dockerfile
```dockerfile
# Dockerfile
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy requirements first (for better caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Multi-stage Production Dockerfile
```dockerfile
# docker/production/Dockerfile
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim as production

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PATH=/home/appuser/.local/bin:$PATH

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy Python dependencies from builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application with production server
CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

### FastAPI Application Example
```python
# app/main.py
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
import os
import uvicorn

app = FastAPI(
    title="Containerized FastAPI App",
    version="1.0.0",
    docs_url="/docs" if os.getenv("ENVIRONMENT") != "production" else None
)

# Security middleware for production
if os.getenv("ENVIRONMENT") == "production":
    app.add_middleware(
        TrustedHostMiddleware, 
        allowed_hosts=["*.yourdomain.com", "yourdomain.com"]
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint for Docker."""
    return {
        "status": "healthy",
        "environment": os.getenv("ENVIRONMENT", "development")
    }

@app.get("/")
async def root():
    return {"message": "Hello from containerized FastAPI!"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=os.getenv("ENVIRONMENT") == "development"
    )
```

### Requirements Management
```python
# requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
gunicorn==21.2.0
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
requests==2.31.0
pydantic==2.5.0
python-dotenv==1.0.0

# requirements-dev.txt (for development)
-r requirements.txt
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2
black==23.11.0
isort==5.12.0
flake8==6.1.0
mypy==1.7.1
```

## 🌐 Node.js Application Containerization

### Node.js Dockerfile
```dockerfile
# Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY --chown=nextjs:nodejs . .

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["npm", "start"]
```

### Multi-stage Node.js Build
```dockerfile
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

# Start application
CMD ["node", "dist/server.js"]
```

## 🚀 React/Frontend Containerization

### React with Nginx
```dockerfile
# Multi-stage build for React app
FROM node:18-alpine as builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build production bundle
RUN npm run build

# Production stage with Nginx
FROM nginx:alpine

# Copy built files from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Nginx Configuration
```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;
    
    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate max-age=0;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
    
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
        
        # Handle client-side routing
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        # API proxy (if needed)
        location /api/ {
            proxy_pass http://backend:8000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Static assets caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

## 🐳 Docker Compose for Development

### Basic Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=development
      - DATABASE_URL=postgresql://user:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - .:/app
      - /app/node_modules  # Prevent overwriting node_modules
    depends_on:
      - db
      - redis
    networks:
      - app-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend
    networks:
      - app-network

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Production Docker Compose
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: docker/production/Dockerfile
    restart: unless-stopped
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - db
      - redis
    networks:
      - app-network
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"

  frontend:
    build:
      context: ./frontend
      dockerfile: docker/production/Dockerfile
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network
    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "3"

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - app-network

  nginx:
    build:
      context: ./docker/nginx
      dockerfile: Dockerfile
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

## 🔧 Docker Optimization

### .dockerignore
```gitignore
# .dockerignore
# Version control
.git
.gitignore

# Dependencies
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env
pip-log.txt
pip-delete-this-directory.txt
.tox
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.mypy_cache
.pytest_cache
.hypothesis

# Development files
.env
.env.local
.env.development
.env.test
.vscode
.idea
*.swp
*.swo
*~

# Documentation
README.md
docs/
*.md

# Testing
tests/
test/
spec/

# Build artifacts
dist/
build/
*.tar.gz

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Docker
Dockerfile*
docker-compose*
.dockerignore

# CI/CD
.github/
.gitlab-ci.yml
Jenkinsfile
```

### Multi-stage Optimization
```dockerfile
# Optimized multi-stage build
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies in a single layer
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Development stage
FROM base as development

# Install development dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and install Python dependencies
COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements-dev.txt

# Copy source code
COPY . .

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app

USER appuser

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Production stage
FROM base as production

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy and install production dependencies only
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

## 🛡️ Security Best Practices

### Secure Dockerfile Patterns
```dockerfile
# Security-focused Dockerfile
FROM python:3.11-slim

# Security: Update packages and remove package manager
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove \
    && apt-get clean

# Security: Create non-root user with specific UID/GID
RUN groupadd -r -g 1001 appgroup \
    && useradd -r -u 1001 -g appgroup appuser

# Security: Set proper working directory
WORKDIR /app

# Security: Copy requirements first (layer caching)
COPY requirements.txt .

# Security: Install dependencies as root, then switch to non-root
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip check

# Security: Copy application code with proper ownership
COPY --chown=appuser:appgroup . .

# Security: Remove sensitive files and set permissions
RUN find /app -name "*.pyc" -delete \
    && find /app -name "__pycache__" -delete \
    && chmod -R 755 /app \
    && chmod -R 644 /app/*.py

# Security: Switch to non-root user
USER appuser

# Security: Use specific port
EXPOSE 8000

# Security: Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Security: Use exec form for CMD
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Environment Security
```bash
# .env.example
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/myapp
POSTGRES_DB=myapp
POSTGRES_USER=user
POSTGRES_PASSWORD=change_this_password

# Redis
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=change_this_password

# Application
SECRET_KEY=your_super_secret_key_here
ENVIRONMENT=development
DEBUG=false

# External Services
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password

# Security
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ORIGINS=http://localhost:3000
```

```yaml
# docker-compose.security.yml
version: '3.8'

services:
  app:
    build: .
    user: "1001:1001"  # Run as non-root user
    read_only: true    # Read-only file system
    tmpfs:
      - /tmp:noexec,nosuid,size=512m
    cap_drop:
      - ALL           # Drop all capabilities
    cap_add:
      - CHOWN         # Add only required capabilities
      - SETGID
      - SETUID
    security_opt:
      - no-new-privileges:true  # Prevent privilege escalation
    networks:
      - app-network
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

networks:
  app-network:
    driver: bridge
    internal: true  # Internal network only
```

## 📊 Monitoring & Logging

### Application Metrics
```python
# app/monitoring.py
import time
import psutil
from fastapi import FastAPI, Request
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import logging

# Metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration')
ACTIVE_CONNECTIONS = Gauge('app_active_connections', 'Active connections')
MEMORY_USAGE = Gauge('app_memory_usage_bytes', 'Memory usage in bytes')
CPU_USAGE = Gauge('app_cpu_usage_percent', 'CPU usage percentage')

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/app/logs/app.log')
    ]
)

logger = logging.getLogger(__name__)

async def monitor_system_metrics():
    """Update system metrics periodically."""
    while True:
        # Memory usage
        memory_info = psutil.virtual_memory()
        MEMORY_USAGE.set(memory_info.used)
        
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        CPU_USAGE.set(cpu_percent)
        
        await asyncio.sleep(30)  # Update every 30 seconds

def add_monitoring_middleware(app: FastAPI):
    """Add monitoring middleware to FastAPI app."""
    
    @app.middleware("http")
    async def monitor_requests(request: Request, call_next):
        start_time = time.time()
        
        # Count active connections
        ACTIVE_CONNECTIONS.inc()
        
        try:
            response = await call_next(request)
            
            # Record metrics
            duration = time.time() - start_time
            REQUEST_DURATION.observe(duration)
            REQUEST_COUNT.labels(
                method=request.method,
                endpoint=request.url.path,
                status=response.status_code
            ).inc()
            
            # Log request
            logger.info(
                f"{request.method} {request.url.path} "
                f"{response.status_code} {duration:.3f}s"
            )
            
            return response
            
        except Exception as e:
            REQUEST_COUNT.labels(
                method=request.method,
                endpoint=request.url.path,
                status=500
            ).inc()
            logger.error(f"Request failed: {e}")
            raise
        finally:
            ACTIVE_CONNECTIONS.dec()

    @app.get("/metrics")
    async def get_metrics():
        """Prometheus metrics endpoint."""
        return Response(generate_latest(), media_type="text/plain")
```

### Docker Health Checks
```dockerfile
# Advanced health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "
import requests
import sys
try:
    response = requests.get('http://localhost:8000/health', timeout=5)
    if response.status_code == 200:
        health_data = response.json()
        if health_data.get('database') == 'connected' and health_data.get('redis') == 'connected':
            sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
"
```

```python
# app/health.py
from fastapi import HTTPException
import asyncio
import aioredis
import asyncpg

async def check_database_health():
    """Check database connectivity."""
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        await conn.execute("SELECT 1")
        await conn.close()
        return "connected"
    except Exception:
        return "disconnected"

async def check_redis_health():
    """Check Redis connectivity."""
    try:
        redis = aioredis.from_url(REDIS_URL)
        await redis.ping()
        await redis.close()
        return "connected"
    except Exception:
        return "disconnected"

@app.get("/health")
async def health_check():
    """Comprehensive health check."""
    checks = await asyncio.gather(
        check_database_health(),
        check_redis_health(),
        return_exceptions=True
    )
    
    health_status = {
        "status": "healthy",
        "database": checks[0],
        "redis": checks[1],
        "timestamp": time.time()
    }
    
    # If any check failed, mark as unhealthy
    if "disconnected" in checks or any(isinstance(check, Exception) for check in checks):
        health_status["status"] = "unhealthy"
        raise HTTPException(status_code=503, detail=health_status)
    
    return health_status
```

## 🚀 Container Orchestration Preparation

### Docker Swarm Ready
```yaml
# docker-stack.yml
version: '3.8'

services:
  backend:
    image: myapp/backend:latest
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    networks:
      - app-network
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  frontend:
    image: myapp/frontend:latest
    ports:
      - "80:80"
    networks:
      - app-network
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

networks:
  app-network:
    driver: overlay
    attachable: true
```

### Kubernetes Ready Deployment
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: myapp/backend:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: redis-url
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## 🛠️ Development Workflow

### Makefile for Docker Operations
```makefile
# Makefile
.PHONY: build up down logs shell test clean

# Default environment
ENV ?= development

# Build images
build:
	docker-compose -f docker-compose.yml build

# Build for production
build-prod:
	docker-compose -f docker-compose.prod.yml build

# Start services
up:
	docker-compose -f docker-compose.yml up -d

# Start production services
up-prod:
	docker-compose -f docker-compose.prod.yml up -d

# Stop services
down:
	docker-compose -f docker-compose.yml down

# View logs
logs:
	docker-compose -f docker-compose.yml logs -f

# Open shell in backend container
shell:
	docker-compose -f docker-compose.yml exec backend bash

# Run tests
test:
	docker-compose -f docker-compose.yml exec backend pytest

# Clean up
clean:
	docker system prune -f
	docker volume prune -f

# Database migrations
migrate:
	docker-compose -f docker-compose.yml exec backend alembic upgrade head

# Database reset (development only)
reset-db:
	docker-compose -f docker-compose.yml down -v
	docker-compose -f docker-compose.yml up -d db
	sleep 10
	make migrate

# Security scan
security-scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image myapp/backend:latest

# Performance test
perf-test:
	docker run --rm --network host \
		peterevans/vegeta sh -c "echo 'GET http://localhost:8000/health' | vegeta attack -duration=30s -rate=100 | vegeta report"
```

### CI/CD Integration Script
```bash
#!/bin/bash
# scripts/docker-ci.sh

set -e

# Configuration
IMAGE_NAME="myapp"
REGISTRY="your-registry.com"
TAG=${1:-latest}

echo "🐳 Starting Docker CI/CD Pipeline"

# Build images
echo "📦 Building Docker images..."
docker build -t ${IMAGE_NAME}/backend:${TAG} -f docker/production/Dockerfile .
docker build -t ${IMAGE_NAME}/frontend:${TAG} -f frontend/docker/production/Dockerfile ./frontend

# Run security scans
echo "🔒 Running security scans..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}/backend:${TAG}

# Run tests
echo "🧪 Running tests..."
docker run --rm ${IMAGE_NAME}/backend:${TAG} pytest

# Push to registry
if [ "$CI" = "true" ]; then
    echo "🚀 Pushing to registry..."
    docker tag ${IMAGE_NAME}/backend:${TAG} ${REGISTRY}/${IMAGE_NAME}/backend:${TAG}
    docker tag ${IMAGE_NAME}/frontend:${TAG} ${REGISTRY}/${IMAGE_NAME}/frontend:${TAG}
    
    docker push ${REGISTRY}/${IMAGE_NAME}/backend:${TAG}
    docker push ${REGISTRY}/${IMAGE_NAME}/frontend:${TAG}
fi

echo "✅ Docker CI/CD Pipeline completed successfully"
```

## 🛠️ Best Practices Summary

### 1. Image Optimization
- Use multi-stage builds to reduce image size
- Use specific base image tags, not `latest`
- Minimize layers by combining RUN commands
- Use .dockerignore to exclude unnecessary files
- Clean up package caches in the same RUN command

### 2. Security
- Run containers as non-root users
- Use read-only file systems when possible
- Scan images for vulnerabilities
- Keep base images updated
- Use secrets management for sensitive data

### 3. Performance
- Use appropriate base images (alpine for smaller size)
- Optimize Dockerfile layer caching
- Set resource limits for containers
- Use health checks for reliable deployments
- Monitor container metrics

### 4. Development
- Use Docker Compose for local development
- Hot reload for development containers
- Separate development and production configurations
- Use consistent environment variables
- Implement proper logging and monitoring

### 5. Production
- Use orchestration platforms (Docker Swarm, Kubernetes)
- Implement rolling updates and rollback strategies
- Use load balancers and reverse proxies
- Set up automated backups for persistent data
- Monitor and alert on container health

---

*Docker containerization provides consistency, portability, and scalability for modern applications. Proper implementation ensures reliable deployments from development to production.*
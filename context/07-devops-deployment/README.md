# 07 - DevOps & Deployment 🚀

Infrastructure, deployment, and operational practices for modern web applications. From containerization to CI/CD and monitoring.

## 📁 Contents

### [Containerization](./containerization/)
Docker and container best practices
- Docker fundamentals
- Multi-stage builds
- Docker Compose for development
- Security and optimization

### [CI/CD](./ci-cd/)
Continuous Integration and Deployment
- GitHub Actions workflows
- Automated testing pipelines
- Deployment automation
- Environment management

### [Cloud Platforms](./cloud-platforms/)
Platform-specific deployment guides
- **[Cloudflare](./cloud-platforms/cloudflare/)** - Edge computing and AI services
- *Coming Soon: Vercel, Railway, AWS, Google Cloud*

### [Monitoring](./monitoring/)
Observability and performance monitoring *(Coming Soon)*
- Application metrics
- Log aggregation
- Error tracking
- Performance monitoring

## 🎯 Deployment Patterns

### Development → Production Pipeline
```
Local Dev → Feature Branch → CI/CD → Staging → Production
    ↓           ↓              ↓        ↓         ↓
 Docker    Unit Tests    Integration  Manual    Monitoring
 Compose                    Tests     Testing
```

### Container-First Approach
- **Development**: Docker Compose for local services
- **CI/CD**: Containerized testing and builds
- **Production**: Container orchestration (Docker, Kubernetes)

## 🐳 Quick Start with Docker

### Basic Dockerfile
```dockerfile
# Multi-stage build for Python FastAPI
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim as runtime

WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose for Development
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    env_file:
      - .env
    depends_on:
      - db
      - redis
    
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

## 🔄 CI/CD with GitHub Actions

### Basic Workflow
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v3
      with:
        python-version: '3.11'
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Run tests
      run: |
        pytest --cov=src --cov-report=xml
        
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: |
        docker build -t myapp:${{ github.sha }} .
        
    - name: Deploy to staging
      run: |
        # Add deployment commands here
        echo "Deploying to staging..."
```

## 🌐 Platform-Specific Deployment

### Vercel (Next.js/React)
```json
{
  "name": "my-app",
  "version": 2,
  "builds": [
    { "src": "package.json", "use": "@vercel/node" }
  ],
  "routes": [
    { "src": "/api/(.*)", "dest": "/api/$1" },
    { "src": "/(.*)", "dest": "/index.html" }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

### Railway (Python/FastAPI)
```toml
# railway.toml
[build]
builder = "NIXPACKS"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[environments.production]
variables = { PYTHON_VERSION = "3.11" }
```

## 🔍 Environment Management

### Environment-Specific Configs
```bash
# Development
.env
.env.development

# Testing
.env.test

# Staging
.env.staging

# Production (use secret management)
# Never commit .env.production
```

### Secret Management
```yaml
# GitHub Secrets in Actions
- name: Deploy
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    API_KEY: ${{ secrets.API_KEY }}
  run: |
    ./deploy.sh
```

## 📊 Health Checks

### Application Health Endpoint
```python
from fastapi import FastAPI, status
from sqlalchemy.orm import Session

app = FastAPI()

@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint for load balancers."""
    try:
        # Check database connection
        db.execute("SELECT 1")
        
        # Check external dependencies
        # redis_client.ping()
        
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow(),
            "version": "1.0.0"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Health check failed: {str(e)}"
        )
```

### Docker Health Check
```dockerfile
# Add to Dockerfile
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
```

## 🚨 Error Handling & Monitoring

### Structured Logging
```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
            
        if hasattr(record, 'request_id'):
            log_entry['request_id'] = record.request_id
            
        return json.dumps(log_entry)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    handlers=[logging.StreamHandler()],
    format='%(message)s'
)
logger = logging.getLogger(__name__)
logger.handlers[0].setFormatter(JSONFormatter())
```

### Error Tracking
```python
# Sentry integration
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn="YOUR_SENTRY_DSN",
    integrations=[FastApiIntegration()],
    traces_sample_rate=0.1,
    environment="production"
)

# Custom error context
@app.middleware("http")
async def add_error_context(request: Request, call_next):
    with sentry_sdk.configure_scope() as scope:
        scope.set_tag("endpoint", request.url.path)
        scope.set_context("request", {
            "method": request.method,
            "url": str(request.url),
            "headers": dict(request.headers)
        })
    
    response = await call_next(request)
    return response
```

## 🔧 Performance Optimization

### Caching Headers
```python
from fastapi import Response

@app.get("/api/data")
async def get_data(response: Response):
    data = fetch_data()
    
    # Cache for 1 hour
    response.headers["Cache-Control"] = "public, max-age=3600"
    response.headers["ETag"] = generate_etag(data)
    
    return data
```

### Compression
```python
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

## 🛡️ Security Best Practices

### HTTPS and Security Headers
```python
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.cors import CORSMiddleware

# HTTPS redirect in production
@app.middleware("http")
async def force_https(request: Request, call_next):
    if not request.url.scheme == "https" and not request.client.host in ["127.0.0.1", "localhost"]:
        url = request.url.replace(scheme="https")
        return RedirectResponse(url, status_code=301)
    return await call_next(request)

# Security headers
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

## 📈 Scaling Considerations

### Horizontal Scaling
- **Stateless applications** - Store state in databases/cache
- **Load balancing** - Distribute traffic across instances
- **Session management** - Use Redis or database sessions
- **File storage** - Use object storage (S3, Cloudflare R2)

### Database Scaling
- **Read replicas** - Separate read/write databases
- **Connection pooling** - Efficient database connections
- **Query optimization** - Proper indexing and query design
- **Caching layers** - Redis for frequently accessed data

## 🚦 Quick Navigation

**New to Docker?** → [Containerization](./containerization/)

**Setting up CI/CD?** → [CI/CD](./ci-cd/)

**Using Cloudflare?** → [Cloud Platforms/Cloudflare](./cloud-platforms/cloudflare/)

**Need Monitoring?** → [Monitoring](./monitoring/) *(Coming Soon)*

---

*DevOps is about creating reliable, scalable systems that allow developers to focus on building features rather than managing infrastructure.*
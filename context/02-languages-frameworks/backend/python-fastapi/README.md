# Python FastAPI Framework Guide

Comprehensive guide to building modern, high-performance APIs with FastAPI, including async patterns, type safety, automatic documentation, and production best practices.

## 🎯 FastAPI Overview

FastAPI is a modern Python web framework that provides:
- **High Performance** - Built on Starlette and Pydantic
- **Type Safety** - Full Python type hints support
- **Auto Documentation** - OpenAPI and JSON Schema
- **Async Support** - Native async/await capabilities
- **Data Validation** - Automatic request/response validation
- **Developer Experience** - Excellent IDE support and debugging

## 🚀 Getting Started

### Installation and Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install FastAPI with all dependencies
pip install "fastapi[all]"

# Or minimal installation
pip install fastapi uvicorn[standard]

# Additional common dependencies
pip install python-dotenv sqlalchemy alembic python-jose[cryptography] passlib[bcrypt] python-multipart httpx
```

### Basic Application

```python
# main.py
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

app = FastAPI(
    title="My API",
    description="Production-ready API with FastAPI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Pydantic models
class ItemBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    tax: Optional[float] = None

class ItemCreate(ItemBase):
    pass

class ItemResponse(ItemBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Routes
@app.get("/")
async def root():
    return {"message": "Welcome to FastAPI"}

@app.post("/items/", response_model=ItemResponse)
async def create_item(item: ItemCreate):
    # Process item
    return ItemResponse(
        id=1,
        **item.dict(),
        created_at=datetime.now()
    )

# Run with: uvicorn main:app --reload
```

## 📁 Project Structure

### Scalable Application Layout

```
fastapi-app/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application instance
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py          # Dependencies (auth, db, etc.)
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── api.py       # API router aggregation
│   │       └── endpoints/
│   │           ├── __init__.py
│   │           ├── users.py
│   │           ├── items.py
│   │           └── auth.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py        # Settings management
│   │   ├── security.py      # Security utilities
│   │   └── exceptions.py    # Custom exceptions
│   ├── models/              # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── user.py
│   │   └── item.py
│   ├── schemas/             # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── item.py
│   │   └── common.py
│   ├── services/            # Business logic
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   ├── db/
│   │   ├── __init__.py
│   │   ├── base.py          # Base class
│   │   ├── session.py       # Database session
│   │   └── init_db.py       # Initial data
│   └── utils/
│       ├── __init__.py
│       └── validators.py
├── alembic/                 # Database migrations
├── tests/
├── scripts/
├── .env
├── .env.example
├── requirements.txt
├── docker-compose.yml
└── Dockerfile
```

## ⚙️ Configuration Management

### Settings with Pydantic

```python
# app/core/config.py
from pydantic_settings import BaseSettings
from typing import List, Optional
from functools import lru_cache

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "FastAPI App"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 1
    
    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 5
    DATABASE_POOL_MAX_OVERFLOW: int = 10
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = []
    
    # Redis
    REDIS_URL: Optional[str] = None
    
    # Email
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: Optional[int] = None
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    
    # External Services
    SENTRY_DSN: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
```

## 🗄️ Database Integration

### SQLAlchemy Setup

```python
# app/db/base.py
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import MetaData

# Naming convention for constraints
convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s"
}

metadata = MetaData(naming_convention=convention)
Base = declarative_base(metadata=metadata)

# app/db/session.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import NullPool
from app.core.config import settings

# Create engine with connection pooling
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_POOL_MAX_OVERFLOW,
    # Use NullPool for SQLite
    poolclass=NullPool if settings.DATABASE_URL.startswith("sqlite") else None
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency
def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### Models Example

```python
# app/models/user.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    items = relationship("Item", back_populates="owner")
```

## 🔐 Authentication & Security

### JWT Authentication

```python
# app/core/security.py
from datetime import datetime, timedelta, timezone
from typing import Optional, Union
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(
    subject: Union[str, int], 
    expires_delta: Optional[timedelta] = None
) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "type": "access"
    }
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.SECRET_KEY, 
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# app/api/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

async def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Inactive user"
        )
    return current_user
```

## 🎯 Advanced Patterns

### Dependency Injection

```python
# app/services/email.py
from typing import Optional
from fastapi import Depends
from app.core.config import get_settings, Settings

class EmailService:
    def __init__(self, settings: Settings):
        self.settings = settings
        self._client = None
    
    @property
    def client(self):
        if not self._client and self.settings.SMTP_HOST:
            # Initialize email client
            pass
        return self._client
    
    async def send_email(
        self, 
        to: str, 
        subject: str, 
        body: str
    ) -> bool:
        if not self.client:
            return False
        # Send email logic
        return True

# Dependency
def get_email_service(
    settings: Settings = Depends(get_settings)
) -> EmailService:
    return EmailService(settings)

# Usage in endpoint
@app.post("/send-notification/")
async def send_notification(
    email: str,
    email_service: EmailService = Depends(get_email_service)
):
    sent = await email_service.send_email(
        to=email,
        subject="Notification",
        body="Your notification content"
    )
    return {"sent": sent}
```

### Background Tasks

```python
from fastapi import BackgroundTasks
import asyncio

async def process_heavy_task(item_id: int):
    """Simulate heavy processing"""
    await asyncio.sleep(10)
    print(f"Processed item {item_id}")

@app.post("/items/{item_id}/process")
async def process_item(
    item_id: int,
    background_tasks: BackgroundTasks
):
    background_tasks.add_task(process_heavy_task, item_id)
    return {"message": "Processing started"}

# With Celery integration
from celery import Celery

celery_app = Celery(
    "tasks",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL
)

@celery_app.task
def process_item_async(item_id: int):
    # Long running task
    return f"Processed {item_id}"

@app.post("/items/{item_id}/process-celery")
async def process_item_celery(item_id: int):
    task = process_item_async.delay(item_id)
    return {"task_id": task.id}
```

### WebSocket Support

```python
from fastapi import WebSocket, WebSocketDisconnect
from typing import List

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def send_personal_message(
        self, 
        message: str, 
        websocket: WebSocket
    ):
        await websocket.send_text(message)
    
    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(
    websocket: WebSocket, 
    client_id: int
):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(
                f"Client {client_id}: {data}"
            )
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        await manager.broadcast(
            f"Client {client_id} disconnected"
        )
```

## 🧪 Testing

### Test Setup

```python
# tests/conftest.py
import pytest
from typing import Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.main import app
from app.db.base import Base
from app.db.session import get_db
from app.core.config import settings

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, 
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine
)

@pytest.fixture(scope="session")
def db() -> Generator:
    Base.metadata.create_all(bind=engine)
    yield TestingSessionLocal()
    Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="module")
def client(db: Session) -> Generator:
    def override_get_db():
        try:
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c

# tests/test_users.py
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

def test_create_user(client: TestClient, db: Session):
    response = client.post(
        "/api/v1/users/",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data
```

## 🚀 Production Deployment

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY ./app ./app
COPY alembic.ini .
COPY ./alembic ./alembic

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Production Configuration

```python
# gunicorn_conf.py
import multiprocessing
import os

workers = int(os.environ.get('GUNICORN_WORKERS', multiprocessing.cpu_count() * 2))
worker_class = "uvicorn.workers.UvicornWorker"
bind = f"0.0.0.0:{os.environ.get('PORT', '8000')}"
keepalive = 120
errorlog = "-"
accesslog = "-"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Run with: gunicorn app.main:app -c gunicorn_conf.py
```

## 📊 Monitoring & Logging

### Structured Logging

```python
# app/core/logging.py
import logging
import sys
from pydantic import BaseModel
from pythonjsonlogger import jsonlogger

class LogConfig(BaseModel):
    """Logging configuration"""
    LOGGER_NAME: str = "app"
    LOG_FORMAT: str = "%(asctime)s | %(levelname)s | %(message)s"
    LOG_LEVEL: str = "DEBUG"
    
    # Logging config
    version: int = 1
    disable_existing_loggers: bool = False
    formatters: dict = {
        "default": {
            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "format": LOG_FORMAT
        },
    }
    handlers: dict = {
        "default": {
            "formatter": "default",
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stdout",
        },
    }
    root: dict = {
        "level": LOG_LEVEL,
        "handlers": ["default"],
    }

# Usage
from app.core.logging import LogConfig
import logging.config

logging.config.dictConfig(LogConfig().dict())
logger = logging.getLogger("app")

# In endpoints
@app.post("/items/")
async def create_item(item: Item):
    logger.info(
        "Creating item",
        extra={
            "item_name": item.name,
            "price": item.price,
            "user_id": current_user.id
        }
    )
```

## 🎯 Best Practices

### API Versioning

```python
# app/api/v1/api.py
from fastapi import APIRouter
from app.api.v1.endpoints import users, items, auth

api_router = APIRouter()
api_router.include_router(
    auth.router, 
    prefix="/auth", 
    tags=["authentication"]
)
api_router.include_router(
    users.router, 
    prefix="/users", 
    tags=["users"]
)
api_router.include_router(
    items.router, 
    prefix="/items", 
    tags=["items"]
)

# app/main.py
app.include_router(
    api_router, 
    prefix=settings.API_V1_STR
)
```

### Error Handling

```python
# app/core/exceptions.py
from fastapi import Request, status
from fastapi.responses import JSONResponse

class AppException(Exception):
    def __init__(
        self, 
        status_code: int, 
        detail: str, 
        headers: dict = None
    ):
        self.status_code = status_code
        self.detail = detail
        self.headers = headers

@app.exception_handler(AppException)
async def app_exception_handler(
    request: Request, 
    exc: AppException
):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers=exc.headers
    )

# Usage
raise AppException(
    status_code=400,
    detail="Invalid input provided"
)
```

### Rate Limiting

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(
    RateLimitExceeded, 
    _rate_limit_exceeded_handler
)

@app.get("/limited/")
@limiter.limit("5/minute")
async def limited_endpoint(request: Request):
    return {"message": "This endpoint is rate limited"}
```

---

*FastAPI provides a modern, fast, and feature-rich framework for building APIs with Python. Focus on type safety, async patterns, and automatic documentation for the best developer experience.*
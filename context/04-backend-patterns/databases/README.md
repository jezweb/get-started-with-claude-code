# Database Patterns 🗄️

Comprehensive database documentation covering development to production patterns, with emphasis on Python/SQLAlchemy and modern database practices.

## 📁 Contents

### [SQLite Patterns](./sqlite/)
Development database and simple deployments
- Local development setup
- SQLite best practices
- Performance optimization
- Migration patterns

### [PostgreSQL Patterns](./postgresql/)
Production-ready relational database
- Connection pooling
- Advanced queries
- Performance tuning
- Backup strategies

### [Redis Patterns](./redis/)
Caching and session management
- Caching strategies
- Session storage
- Rate limiting
- Real-time features

### [ORM Patterns](./orm/)
Object-relational mapping with SQLAlchemy
- Modern SQLAlchemy 2.0
- Async patterns
- Relationship modeling
- Query optimization

## 🎯 Database Selection Guide

### Development
```python
# SQLite for development
DATABASE_URL = "sqlite:///./dev.db"
```
**When to use:** Local development, testing, prototyping
**Pros:** Zero setup, file-based, fast for small data
**Cons:** Single writer, limited concurrency

### Production
```python
# PostgreSQL for production
DATABASE_URL = "postgresql://user:pass@localhost:5432/myapp"
```
**When to use:** Production applications, complex queries
**Pros:** ACID compliance, concurrent writes, rich features
**Cons:** More complex setup, resource overhead

### Caching
```python
# Redis for caching
REDIS_URL = "redis://localhost:6379/0"
```
**When to use:** Session storage, caching, real-time features
**Pros:** In-memory speed, pub/sub, data structures
**Cons:** Memory-bound, persistence limitations

## 🚀 Quick Start

### SQLite Development Setup
```python
# database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# SQLite with WAL mode for better concurrency
engine = create_engine(
    "sqlite:///./app.db",
    connect_args={"check_same_thread": False},
    echo=True  # Log SQL queries in development
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### PostgreSQL Production Setup
```python
# database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

# Async PostgreSQL connection
engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost:5432/myapp",
    echo=False,
    pool_size=20,
    max_overflow=0,
    pool_pre_ping=True
)

AsyncSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

## 📊 Model Patterns

### Basic Model
```python
from sqlalchemy import Column, Integer, String, DateTime, Text, Boolean
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    bio = Column(Text, nullable=True)
    
    # Automatic timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}')>"
```

### Relationships
```python
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Relationships
    author = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")

# Add to User model
User.posts = relationship("Post", back_populates="author")
```

## 🔄 Migration Patterns

### Alembic Setup
```bash
# Install Alembic
pip install alembic

# Initialize migrations
alembic init migrations

# Create migration
alembic revision --autogenerate -m "Create users table"

# Apply migrations
alembic upgrade head
```

### Migration Best Practices
```python
# Always check for existing data
def upgrade():
    # Create new column as nullable first
    op.add_column('users', sa.Column('phone', sa.String(20), nullable=True))
    
    # Update existing records
    op.execute("UPDATE users SET phone = '' WHERE phone IS NULL")
    
    # Make non-nullable after data migration
    op.alter_column('users', 'phone', nullable=False)

def downgrade():
    op.drop_column('users', 'phone')
```

## ⚡ Performance Patterns

### Efficient Queries
```python
# Bad - N+1 query problem
users = session.query(User).all()
for user in users:
    print(user.posts)  # Triggers query for each user

# Good - Eager loading
users = session.query(User).options(
    joinedload(User.posts)
).all()

# Good - Select specific columns
users = session.query(User.id, User.name).all()
```

### Bulk Operations
```python
# Bulk insert
users = [
    {"name": "User 1", "email": "user1@example.com"},
    {"name": "User 2", "email": "user2@example.com"},
]
session.bulk_insert_mappings(User, users)

# Bulk update
session.bulk_update_mappings(User, [
    {"id": 1, "name": "Updated Name 1"},
    {"id": 2, "name": "Updated Name 2"},
])
```

### Indexing Strategy
```python
# Composite index for common queries
class Post(Base):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True)
    author_id = Column(Integer, ForeignKey("users.id"), index=True)
    status = Column(String(20), index=True)
    created_at = Column(DateTime, index=True)
    
    # Composite index for common query pattern
    __table_args__ = (
        Index("idx_author_status", "author_id", "status"),
        Index("idx_status_created", "status", "created_at"),
    )
```

## 💾 Caching Strategies

### Redis Integration
```python
import redis
import json
from typing import Optional

class CacheService:
    def __init__(self, redis_url: str):
        self.redis = redis.from_url(redis_url)
    
    def get(self, key: str) -> Optional[dict]:
        """Get cached data."""
        data = self.redis.get(key)
        return json.loads(data) if data else None
    
    def set(self, key: str, value: dict, expire: int = 3600):
        """Cache data with expiration."""
        self.redis.setex(key, expire, json.dumps(value))
    
    def delete(self, key: str):
        """Remove from cache."""
        self.redis.delete(key)
    
    def get_or_set(self, key: str, func, expire: int = 3600):
        """Get from cache or compute and cache."""
        data = self.get(key)
        if data is None:
            data = func()
            self.set(key, data, expire)
        return data
```

### Caching Decorator
```python
from functools import wraps

def cached(expire: int = 3600, key_prefix: str = ""):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            cache_key = f"{key_prefix}:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # Try cache first
            result = cache.get(cache_key)
            if result is None:
                result = func(*args, **kwargs)
                cache.set(cache_key, result, expire)
            
            return result
        return wrapper
    return decorator

# Usage
@cached(expire=1800, key_prefix="user")
def get_user_profile(user_id: int):
    return session.query(User).filter(User.id == user_id).first()
```

## 🔒 Security Patterns

### SQL Injection Prevention
```python
# Bad - Never do this
query = f"SELECT * FROM users WHERE email = '{email}'"

# Good - Use parameterized queries
user = session.query(User).filter(User.email == email).first()

# Good - Raw SQL with parameters
result = session.execute(
    text("SELECT * FROM users WHERE email = :email"),
    {"email": email}
)
```

### Data Validation
```python
from pydantic import BaseModel, EmailStr, validator

class UserCreate(BaseModel):
    email: EmailStr
    name: str
    password: str
    
    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip()
    
    @validator('password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v
```

## 🛠️ Testing Patterns

### Test Database Setup
```python
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database import Base, get_db
from main import app

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db_session():
    """Create a fresh database for each test."""
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_client(db_session):
    """Create test client with test database."""
    def override_get_db():
        yield db_session
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as client:
        yield client
```

## 🚦 Quick Navigation

**Starting with SQLite?** → [SQLite Patterns](./sqlite/)

**Ready for Production?** → [PostgreSQL Patterns](./postgresql/)

**Need Caching?** → [Redis Patterns](./redis/)

**Using SQLAlchemy?** → [ORM Patterns](./orm/)

---

*Database choice and patterns are foundational decisions that affect your entire application. Choose based on your specific needs and scale accordingly.*
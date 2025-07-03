# SQLite Patterns & Best Practices

Comprehensive guide to using SQLite effectively, from development prototyping to production deployments in specific use cases.

## 🎯 When to Use SQLite

### ✅ Perfect For:
- **Local development** - Zero configuration database
- **Small to medium applications** - < 1TB data, < 100 concurrent writers
- **Embedded applications** - Desktop apps, mobile apps, IoT devices
- **Prototyping & MVPs** - Quick setup and iteration
- **Edge computing** - Serverless functions, edge workers
- **Read-heavy workloads** - Multiple readers, single writer
- **File-based storage** - Configuration, logs, caches

### ❌ Avoid For:
- **High-write concurrency** - Many simultaneous writers
- **Network databases** - Client-server architecture needed
- **Very large datasets** - > 1TB (though SQLite can handle it)
- **Complex user permissions** - Built-in user management needed

## 🚀 Setup & Configuration

### Python with SQLAlchemy
```python
# database.py
import os
from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")

# SQLite-specific optimizations
def _configure_sqlite(dbapi_connection, connection_record):
    """Configure SQLite for better performance and reliability."""
    cursor = dbapi_connection.cursor()
    
    # Enable WAL mode for better concurrency
    cursor.execute("PRAGMA journal_mode=WAL")
    
    # Enable foreign key constraints
    cursor.execute("PRAGMA foreign_keys=ON")
    
    # Optimize for speed
    cursor.execute("PRAGMA synchronous=NORMAL")
    cursor.execute("PRAGMA cache_size=10000")
    cursor.execute("PRAGMA temp_store=MEMORY")
    
    # Set busy timeout (5 seconds)
    cursor.execute("PRAGMA busy_timeout=5000")
    
    cursor.close()

# Create engine with SQLite optimizations
engine = create_engine(
    DATABASE_URL,
    echo=False,  # Set to True for SQL debugging
    connect_args={
        "check_same_thread": False,  # Allow multiple threads
        "timeout": 10  # Connection timeout
    },
    poolclass=StaticPool,  # Use static pool for SQLite
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=300  # Recycle connections every 5 minutes
)

# Configure SQLite-specific settings
event.listen(engine, "connect", _configure_sqlite)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    """Dependency to get database session."""
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

# Database initialization
def init_db():
    """Initialize database tables."""
    Base.metadata.create_all(bind=engine)

def reset_db():
    """Reset database (development only)."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
```

### FastAPI Integration
```python
# main.py
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db, init_db
from models import User, Post
from schemas import UserCreate, UserResponse

app = FastAPI(title="SQLite App")

# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    init_db()

# Example endpoints
@app.post("/users/", response_model=UserResponse)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Check if user exists
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create user
    db_user = User(**user.dict())
    db.add(db_user)
    
    try:
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to create user")

@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/users/", response_model=list[UserResponse])
def list_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return users
```

### Node.js with Better-SQLite3
```javascript
// database.js
const Database = require('better-sqlite3')
const path = require('path')

class DatabaseManager {
  constructor(dbPath = './app.db') {
    this.db = new Database(dbPath, {
      verbose: process.env.NODE_ENV === 'development' ? console.log : null
    })
    
    this.initializePragmas()
    this.initializeTables()
  }

  initializePragmas() {
    // Enable WAL mode for better concurrency
    this.db.pragma('journal_mode = WAL')
    
    // Enable foreign key constraints
    this.db.pragma('foreign_keys = ON')
    
    // Performance optimizations
    this.db.pragma('synchronous = NORMAL')
    this.db.pragma('cache_size = 10000')
    this.db.pragma('temp_store = MEMORY')
    
    // Set busy timeout
    this.db.pragma('busy_timeout = 5000')
  }

  initializeTables() {
    // Create tables if they don't exist
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        author_id INTEGER NOT NULL,
        published BOOLEAN DEFAULT FALSE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE
      );

      CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
      CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts (author_id);
      CREATE INDEX IF NOT EXISTS idx_posts_published ON posts (published);
    `)
  }

  // User operations
  createUser(userData) {
    const stmt = this.db.prepare(`
      INSERT INTO users (email, name)
      VALUES (?, ?)
    `)
    
    try {
      const result = stmt.run(userData.email, userData.name)
      return this.getUserById(result.lastInsertRowid)
    } catch (error) {
      if (error.code === 'SQLITE_CONSTRAINT_UNIQUE') {
        throw new Error('Email already exists')
      }
      throw error
    }
  }

  getUserById(id) {
    const stmt = this.db.prepare('SELECT * FROM users WHERE id = ?')
    return stmt.get(id)
  }

  getUserByEmail(email) {
    const stmt = this.db.prepare('SELECT * FROM users WHERE email = ?')
    return stmt.get(email)
  }

  getAllUsers(limit = 100, offset = 0) {
    const stmt = this.db.prepare(`
      SELECT * FROM users 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `)
    return stmt.all(limit, offset)
  }

  updateUser(id, updates) {
    const fields = Object.keys(updates).map(key => `${key} = ?`).join(', ')
    const values = Object.values(updates)
    
    const stmt = this.db.prepare(`
      UPDATE users 
      SET ${fields}, updated_at = CURRENT_TIMESTAMP 
      WHERE id = ?
    `)
    
    const result = stmt.run(...values, id)
    return result.changes > 0 ? this.getUserById(id) : null
  }

  deleteUser(id) {
    const stmt = this.db.prepare('DELETE FROM users WHERE id = ?')
    const result = stmt.run(id)
    return result.changes > 0
  }

  // Transaction example
  createUserWithPost(userData, postData) {
    const transaction = this.db.transaction(() => {
      // Create user
      const userStmt = this.db.prepare(`
        INSERT INTO users (email, name)
        VALUES (?, ?)
      `)
      const userResult = userStmt.run(userData.email, userData.name)
      
      // Create post
      const postStmt = this.db.prepare(`
        INSERT INTO posts (title, content, author_id)
        VALUES (?, ?, ?)
      `)
      const postResult = postStmt.run(
        postData.title, 
        postData.content, 
        userResult.lastInsertRowid
      )
      
      return {
        user: this.getUserById(userResult.lastInsertRowid),
        post: this.getPostById(postResult.lastInsertRowid)
      }
    })
    
    return transaction()
  }

  close() {
    this.db.close()
  }
}

module.exports = { DatabaseManager }
```

## 📊 Data Modeling Patterns

### SQLAlchemy Models
```python
# models.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class TimestampMixin:
    """Mixin for automatic timestamps."""
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class User(Base, TimestampMixin):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    bio = Column(Text, nullable=True)
    
    # Relationships
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="author", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}')>"

class Post(Base, TimestampMixin):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    published = Column(Boolean, default=False)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Relationships
    author = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    
    # Indexes for common queries
    __table_args__ = (
        Index("idx_author_published", "author_id", "published"),
        Index("idx_published_created", "published", "created_at"),
    )

class Comment(Base, TimestampMixin):
    __tablename__ = "comments"
    
    id = Column(Integer, primary_key=True, index=True)
    content = Column(Text, nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Relationships
    post = relationship("Post", back_populates="comments")
    author = relationship("User", back_populates="comments")

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text)
    
    # Self-referential relationship for hierarchical categories
    parent_id = Column(Integer, ForeignKey("categories.id"))
    parent = relationship("Category", remote_side=[id], backref="children")
```

### JSON Storage Patterns
```python
# For storing structured data in SQLite
from sqlalchemy import Column, Integer, JSON
from sqlalchemy.types import TypeDecorator, String
import json

class JSONEncodedDict(TypeDecorator):
    """Store JSON data in SQLite TEXT column."""
    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            value = json.dumps(value)
        return value

    def process_result_value(self, value, dialect):
        if value is not None:
            value = json.loads(value)
        return value

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Store complex data as JSON
    preferences = Column(JSONEncodedDict)
    settings = Column(JSONEncodedDict)
    metadata = Column(JSONEncodedDict)

# Usage
profile = UserProfile(
    user_id=1,
    preferences={
        "theme": "dark",
        "language": "en",
        "notifications": {
            "email": True,
            "push": False
        }
    },
    settings={
        "privacy": "public",
        "timezone": "UTC"
    }
)
```

## ⚡ Performance Optimization

### Indexing Strategies
```sql
-- Common indexing patterns for SQLite

-- Single column indexes
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_posts_published ON posts (published);
CREATE INDEX idx_posts_created_at ON posts (created_at);

-- Composite indexes for common query patterns
CREATE INDEX idx_posts_author_published ON posts (author_id, published);
CREATE INDEX idx_posts_published_created ON posts (published, created_at DESC);

-- Partial indexes for specific conditions
CREATE INDEX idx_active_users ON users (email) WHERE is_active = 1;
CREATE INDEX idx_published_posts ON posts (created_at) WHERE published = 1;

-- Covering indexes to avoid table lookups
CREATE INDEX idx_post_summary ON posts (author_id, published, title, created_at);

-- Full-text search indexes
CREATE VIRTUAL TABLE posts_fts USING fts5(title, content, content='posts', content_rowid='id');

-- Triggers to maintain FTS index
CREATE TRIGGER posts_fts_insert AFTER INSERT ON posts BEGIN
  INSERT INTO posts_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
END;

CREATE TRIGGER posts_fts_delete AFTER DELETE ON posts BEGIN
  INSERT INTO posts_fts(posts_fts, rowid, title, content) VALUES('delete', old.id, old.title, old.content);
END;

CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts BEGIN
  INSERT INTO posts_fts(posts_fts, rowid, title, content) VALUES('delete', old.id, old.title, old.content);
  INSERT INTO posts_fts(posts_fts, rowid, title, content) VALUES(new.id, new.title, new.content);
END;
```

### Query Optimization
```python
# Repository patterns with optimized queries
class PostRepository:
    def __init__(self, db: Session):
        self.db = db

    def find_published_posts(self, limit: int = 10, offset: int = 0):
        """Get published posts with eager loading."""
        return (
            self.db.query(Post)
            .options(joinedload(Post.author))  # Avoid N+1 queries
            .filter(Post.published == True)
            .order_by(Post.created_at.desc())
            .limit(limit)
            .offset(offset)
            .all()
        )

    def find_posts_by_author(self, author_id: int):
        """Use index on author_id."""
        return (
            self.db.query(Post)
            .filter(Post.author_id == author_id)
            .order_by(Post.created_at.desc())
            .all()
        )

    def search_posts(self, query: str):
        """Full-text search using SQLite FTS."""
        return (
            self.db.execute(
                text("""
                SELECT p.* FROM posts p
                JOIN posts_fts fts ON p.id = fts.rowid
                WHERE posts_fts MATCH :query
                ORDER BY bm25(posts_fts)
                """),
                {"query": query}
            )
            .fetchall()
        )

    def get_post_statistics(self):
        """Aggregate queries with proper indexing."""
        return (
            self.db.query(
                User.name,
                func.count(Post.id).label('post_count'),
                func.count(case([(Post.published == True, 1)])).label('published_count')
            )
            .join(Post)
            .group_by(User.id, User.name)
            .order_by(func.count(Post.id).desc())
            .all()
        )

    def bulk_update_published_status(self, post_ids: list[int], published: bool):
        """Efficient bulk operations."""
        self.db.query(Post).filter(
            Post.id.in_(post_ids)
        ).update(
            {Post.published: published},
            synchronize_session=False
        )
        self.db.commit()
```

### Connection Pool & Concurrency
```python
# Advanced SQLite configuration for high-concurrency scenarios
from sqlalchemy import create_engine, event
from sqlalchemy.pool import QueuePool
import threading
import time

class SQLiteQueuePool(QueuePool):
    """Custom queue pool for SQLite with retry logic."""
    
    def _create_connection(self):
        for attempt in range(3):
            try:
                return super()._create_connection()
            except Exception as e:
                if "database is locked" in str(e) and attempt < 2:
                    time.sleep(0.1 * (attempt + 1))  # Exponential backoff
                    continue
                raise

# High-concurrency SQLite setup
def create_sqlite_engine(database_url: str, max_connections: int = 20):
    engine = create_engine(
        database_url,
        poolclass=SQLiteQueuePool,
        pool_size=max_connections,
        max_overflow=0,
        pool_pre_ping=True,
        pool_recycle=300,
        connect_args={
            "check_same_thread": False,
            "timeout": 30
        }
    )
    
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        
        # WAL mode for better concurrency
        cursor.execute("PRAGMA journal_mode=WAL")
        
        # Increase WAL checkpoint threshold
        cursor.execute("PRAGMA wal_autocheckpoint=1000")
        
        # Enable foreign keys
        cursor.execute("PRAGMA foreign_keys=ON")
        
        # Performance settings
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA cache_size=10000")
        cursor.execute("PRAGMA temp_store=MEMORY")
        cursor.execute("PRAGMA mmap_size=268435456")  # 256MB
        
        # Longer busy timeout for high concurrency
        cursor.execute("PRAGMA busy_timeout=30000")
        
        cursor.close()
    
    return engine
```

## 🔄 Migration Patterns

### Alembic Setup for SQLite
```python
# alembic.ini adjustments for SQLite
[alembic]
script_location = migrations
sqlalchemy.url = sqlite:///./app.db

# migrations/env.py
from alembic import context
from sqlalchemy import engine_from_config, pool
from logging.config import fileConfig
from database import Base

config = context.config
fileConfig(config.config_file_name)
target_metadata = Base.metadata

def run_migrations_offline():
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=True  # Important for SQLite
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, 
            target_metadata=target_metadata,
            render_as_batch=True  # Important for SQLite
        )

        with context.begin_transaction():
            context.run_migrations()
```

### Safe Migration Patterns
```python
# migrations/versions/001_add_user_bio.py
"""add user bio

Revision ID: 001
Revises: 
Create Date: 2023-01-01 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # SQLite doesn't support ALTER COLUMN, use batch mode
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('bio', sa.Text(), nullable=True))

def downgrade():
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('bio')

# migrations/versions/002_add_indexes.py
def upgrade():
    # Create indexes
    op.create_index('idx_users_email', 'users', ['email'], unique=True)
    op.create_index('idx_posts_author_id', 'posts', ['author_id'])
    op.create_index('idx_posts_published', 'posts', ['published'])

def downgrade():
    op.drop_index('idx_posts_published', 'posts')
    op.drop_index('idx_posts_author_id', 'posts')
    op.drop_index('idx_users_email', 'users')
```

## 🛠️ Development Utilities

### Database Inspection Tools
```python
# utils/db_inspector.py
from sqlalchemy import inspect, text
from database import engine

class DatabaseInspector:
    def __init__(self, engine):
        self.engine = engine
        self.inspector = inspect(engine)

    def get_table_info(self, table_name: str):
        """Get detailed table information."""
        return {
            'columns': self.inspector.get_columns(table_name),
            'indexes': self.inspector.get_indexes(table_name),
            'foreign_keys': self.inspector.get_foreign_keys(table_name),
            'check_constraints': self.inspector.get_check_constraints(table_name)
        }

    def analyze_query_plan(self, query: str):
        """Analyze SQLite query execution plan."""
        with self.engine.connect() as conn:
            result = conn.execute(text(f"EXPLAIN QUERY PLAN {query}"))
            return result.fetchall()

    def get_database_stats(self):
        """Get database statistics."""
        with self.engine.connect() as conn:
            stats = {}
            
            # Database size
            result = conn.execute(text("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()"))
            stats['database_size'] = result.scalar()
            
            # Table sizes
            tables = self.inspector.get_table_names()
            stats['tables'] = {}
            
            for table in tables:
                result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
                stats['tables'][table] = result.scalar()
            
            # Index usage
            result = conn.execute(text("SELECT name, tbl_name FROM sqlite_master WHERE type='index'"))
            stats['indexes'] = result.fetchall()
            
            return stats

    def vacuum_analyze(self):
        """Optimize database."""
        with self.engine.connect() as conn:
            conn.execute(text("VACUUM"))
            conn.execute(text("ANALYZE"))
            conn.commit()

# CLI tool
if __name__ == "__main__":
    inspector = DatabaseInspector(engine)
    
    # Print database stats
    stats = inspector.get_database_stats()
    print(f"Database size: {stats['database_size'] / 1024 / 1024:.2f} MB")
    
    for table, count in stats['tables'].items():
        print(f"{table}: {count} rows")
```

### Backup & Restore
```python
# utils/backup.py
import sqlite3
import os
from datetime import datetime

class SQLiteBackup:
    def __init__(self, db_path: str, backup_dir: str = "backups"):
        self.db_path = db_path
        self.backup_dir = backup_dir
        os.makedirs(backup_dir, exist_ok=True)

    def create_backup(self, name: str = None):
        """Create a backup of the database."""
        if not name:
            name = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.db"
        
        backup_path = os.path.join(self.backup_dir, name)
        
        # Use SQLite's backup API
        source = sqlite3.connect(self.db_path)
        backup = sqlite3.connect(backup_path)
        
        try:
            source.backup(backup)
            print(f"Backup created: {backup_path}")
            return backup_path
        finally:
            source.close()
            backup.close()

    def restore_backup(self, backup_path: str):
        """Restore database from backup."""
        if not os.path.exists(backup_path):
            raise FileNotFoundError(f"Backup file not found: {backup_path}")
        
        # Create backup of current database
        current_backup = self.create_backup("before_restore")
        
        try:
            # Replace current database with backup
            backup = sqlite3.connect(backup_path)
            current = sqlite3.connect(self.db_path)
            
            backup.backup(current)
            
            backup.close()
            current.close()
            
            print(f"Database restored from: {backup_path}")
            print(f"Previous version backed up as: {current_backup}")
            
        except Exception as e:
            print(f"Restore failed: {e}")
            # Could implement rollback here
            raise

    def list_backups(self):
        """List available backups."""
        backups = [f for f in os.listdir(self.backup_dir) if f.endswith('.db')]
        return sorted(backups, reverse=True)

# Automated backup script
if __name__ == "__main__":
    backup_manager = SQLiteBackup("./app.db")
    
    # Daily backup
    backup_manager.create_backup()
    
    # Clean old backups (keep last 7 days)
    backups = backup_manager.list_backups()
    if len(backups) > 7:
        for old_backup in backups[7:]:
            os.remove(os.path.join(backup_manager.backup_dir, old_backup))
```

## 🧪 Testing Patterns

### Test Database Setup
```python
# tests/conftest.py
import pytest
import tempfile
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from database import Base, get_db
from main import app

@pytest.fixture
def test_db():
    """Create a temporary test database."""
    # Create temporary database file
    db_fd, db_path = tempfile.mkstemp(suffix='.db')
    
    # Create test engine
    test_engine = create_engine(f"sqlite:///{db_path}")
    Base.metadata.create_all(test_engine)
    
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    
    yield TestingSessionLocal
    
    # Cleanup
    os.close(db_fd)
    os.unlink(db_path)

@pytest.fixture
def test_client(test_db):
    """Create test client with test database."""
    def override_get_db():
        try:
            db = test_db()
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as client:
        yield client

# Example tests
def test_user_creation(test_client):
    response = test_client.post("/users/", json={
        "email": "test@example.com",
        "name": "Test User"
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data

def test_database_constraints(test_db):
    db = test_db()
    
    # Test unique constraint
    user1 = User(email="same@example.com", name="User 1")
    user2 = User(email="same@example.com", name="User 2")
    
    db.add(user1)
    db.commit()
    
    db.add(user2)
    with pytest.raises(Exception):  # IntegrityError
        db.commit()
```

## 📊 Monitoring & Maintenance

### Performance Monitoring
```python
# utils/monitor.py
import time
import sqlite3
from functools import wraps
from database import engine

class SQLiteMonitor:
    def __init__(self):
        self.query_stats = {}

    def track_query(self, func):
        """Decorator to track query performance."""
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            result = func(*args, **kwargs)
            end_time = time.time()
            
            duration = end_time - start_time
            func_name = func.__name__
            
            if func_name not in self.query_stats:
                self.query_stats[func_name] = {
                    'count': 0,
                    'total_time': 0,
                    'avg_time': 0,
                    'max_time': 0
                }
            
            stats = self.query_stats[func_name]
            stats['count'] += 1
            stats['total_time'] += duration
            stats['avg_time'] = stats['total_time'] / stats['count']
            stats['max_time'] = max(stats['max_time'], duration)
            
            return result
        return wrapper

    def get_stats_report(self):
        """Generate performance report."""
        report = []
        for func_name, stats in self.query_stats.items():
            report.append(f"{func_name}:")
            report.append(f"  Calls: {stats['count']}")
            report.append(f"  Total time: {stats['total_time']:.4f}s")
            report.append(f"  Average time: {stats['avg_time']:.4f}s")
            report.append(f"  Max time: {stats['max_time']:.4f}s")
            report.append("")
        
        return "\n".join(report)

# Health check utilities
def check_database_health():
    """Perform database health checks."""
    checks = {
        'connection': False,
        'wal_mode': False,
        'foreign_keys': False,
        'integrity': False
    }
    
    try:
        with engine.connect() as conn:
            # Test basic connection
            conn.execute("SELECT 1")
            checks['connection'] = True
            
            # Check WAL mode
            result = conn.execute("PRAGMA journal_mode").scalar()
            checks['wal_mode'] = result.lower() == 'wal'
            
            # Check foreign keys
            result = conn.execute("PRAGMA foreign_keys").scalar()
            checks['foreign_keys'] = result == 1
            
            # Run integrity check
            result = conn.execute("PRAGMA integrity_check").scalar()
            checks['integrity'] = result == 'ok'
            
    except Exception as e:
        print(f"Health check failed: {e}")
    
    return checks
```

## 🚦 Best Practices Summary

### 1. Configuration
- Always enable WAL mode for better concurrency
- Set appropriate PRAGMA settings
- Use connection pooling even for SQLite
- Enable foreign key constraints

### 2. Schema Design
- Use appropriate data types
- Create indexes for common queries
- Consider JSON columns for flexible data
- Plan for migrations from the start

### 3. Query Optimization
- Use query analysis tools
- Implement proper indexing strategies
- Avoid N+1 query problems
- Use transactions for multiple operations

### 4. Deployment
- Regular backups with VACUUM
- Monitor database size and performance
- Plan for migration to PostgreSQL if needed
- Use WAL mode in production

### 5. Testing
- Use separate test databases
- Test constraint violations
- Test concurrent access scenarios
- Verify backup/restore procedures

---

*SQLite is an excellent choice for development, prototyping, and many production use cases. Understanding its strengths and limitations helps you use it effectively.*
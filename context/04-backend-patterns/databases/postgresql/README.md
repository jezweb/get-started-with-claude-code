# PostgreSQL Production Patterns

Comprehensive guide to using PostgreSQL for production applications, covering advanced features, performance optimization, and scalability patterns.

## 🎯 When to Use PostgreSQL

### ✅ Perfect For:
- **Production applications** - High concurrency, ACID compliance
- **Complex queries** - Advanced SQL features, JSON support
- **Multi-user systems** - Concurrent read/write operations
- **Data integrity** - Foreign keys, constraints, transactions
- **Scalable applications** - Connection pooling, replication
- **Analytics workloads** - Window functions, CTEs, aggregations
- **Geographic data** - PostGIS extension for spatial queries

### ❌ Consider Alternatives For:
- **Simple prototypes** - SQLite might be easier for development
- **Embedded applications** - SQLite is more suitable
- **Very high-write loads** - Consider NoSQL for extreme scale
- **Simple key-value storage** - Redis might be more appropriate

## 🚀 Setup & Configuration

### Docker Development Setup
```yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: devpass123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    command: >
      postgres
      -c shared_preload_libraries=pg_stat_statements
      -c pg_stat_statements.track=all
      -c max_connections=200
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c work_mem=4MB
      -c maintenance_work_mem=64MB

volumes:
  postgres_data:
```

### Python SQLAlchemy Setup
```python
# database.py
import os
from sqlalchemy import create_engine, event, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import QueuePool
import logging

# Configure logging
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# Database configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://developer:devpass123@localhost:5432/myapp"
)

# Production-optimized engine
engine = create_engine(
    DATABASE_URL,
    echo=False,  # Set to True for SQL debugging
    pool_size=20,  # Number of connections to maintain
    max_overflow=30,  # Additional connections when pool is full
    pool_pre_ping=True,  # Validate connections before use
    pool_recycle=3600,  # Recycle connections every hour
    poolclass=QueuePool,
    connect_args={
        "connect_timeout": 10,
        "application_name": "myapp",
        "options": "-c timezone=UTC"
    }
)

# Configure PostgreSQL-specific settings
@event.listens_for(engine, "connect")
def set_postgresql_pragmas(dbapi_connection, connection_record):
    with dbapi_connection.cursor() as cursor:
        # Set session-level optimizations
        cursor.execute("SET statement_timeout = '30s'")
        cursor.execute("SET lock_timeout = '10s'")
        cursor.execute("SET idle_in_transaction_session_timeout = '5min'")

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

# Health check
def check_database_health():
    """Check database connectivity and performance."""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1")).scalar()
            return {"status": "healthy", "connection": "ok"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

### Async SQLAlchemy Setup
```python
# async_database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
import asyncio

# Async engine for high-performance applications
async_engine = create_async_engine(
    "postgresql+asyncpg://developer:devpass123@localhost:5432/myapp",
    echo=False,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True,
    pool_recycle=3600,
    connect_args={
        "server_settings": {
            "application_name": "myapp_async",
            "timezone": "UTC",
        }
    }
)

AsyncSessionLocal = sessionmaker(
    async_engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

async def get_async_db():
    """Async database session dependency."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

# Async health check
async def check_async_database_health():
    """Async database health check."""
    try:
        async with async_engine.connect() as conn:
            result = await conn.execute(text("SELECT 1"))
            await result.scalar()
            return {"status": "healthy", "connection": "ok"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

## 📊 Advanced Data Modeling

### Enhanced Models with PostgreSQL Features
```python
# models.py
from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Text, 
    ForeignKey, Index, JSON, ARRAY, Numeric, UUID
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import JSONB, ENUM, TSVECTOR
from database import Base
import uuid

# Custom ENUM type
user_role_enum = ENUM('user', 'admin', 'moderator', name='user_role')

class TimestampMixin:
    """Mixin for automatic timestamps."""
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class User(Base, TimestampMixin):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    role = Column(user_role_enum, default='user')
    is_active = Column(Boolean, default=True)
    
    # PostgreSQL-specific features
    preferences = Column(JSONB, default=dict)  # Structured preferences
    tags = Column(ARRAY(String), default=list)  # Array of tags
    search_vector = Column(TSVECTOR)  # Full-text search
    
    # Relationships
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_users_email_active', 'email', 'is_active'),
        Index('idx_users_role_created', 'role', 'created_at'),
        Index('idx_users_search', 'search_vector', postgresql_using='gin'),
        Index('idx_users_tags', 'tags', postgresql_using='gin'),
    )

class UserProfile(Base, TimestampMixin):
    __tablename__ = "user_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True)
    bio = Column(Text)
    avatar_url = Column(String(500))
    
    # JSON data for flexible storage
    social_links = Column(JSONB, default=dict)
    settings = Column(JSONB, default=dict)
    analytics = Column(JSONB, default=dict)
    
    # Relationships
    user = relationship("User", back_populates="profile")

class Post(Base, TimestampMixin):
    __tablename__ = "posts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    published = Column(Boolean, default=False)
    view_count = Column(Integer, default=0)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Content metadata
    metadata = Column(JSONB, default=dict)
    tags = Column(ARRAY(String), default=list)
    search_vector = Column(TSVECTOR)
    
    # Relationships
    author = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    
    # Advanced indexing
    __table_args__ = (
        Index('idx_posts_author_published', 'author_id', 'published'),
        Index('idx_posts_published_created', 'published', 'created_at'),
        Index('idx_posts_search', 'search_vector', postgresql_using='gin'),
        Index('idx_posts_tags', 'tags', postgresql_using='gin'),
        Index('idx_posts_metadata', 'metadata', postgresql_using='gin'),
    )

class Comment(Base, TimestampMixin):
    __tablename__ = "comments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    content = Column(Text, nullable=False)
    post_id = Column(UUID(as_uuid=True), ForeignKey("posts.id"), nullable=False)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("comments.id"))  # For threading
    
    # Moderation
    is_approved = Column(Boolean, default=True)
    flagged_count = Column(Integer, default=0)
    
    # Relationships
    post = relationship("Post", back_populates="comments")
    author = relationship("User")
    parent = relationship("Comment", remote_side=[id], backref="replies")
```

### Database Functions and Triggers
```sql
-- migrations/sql/functions.sql

-- Update search vector function
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', 
    COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.content, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for posts search vector
CREATE TRIGGER posts_search_vector_update
  BEFORE INSERT OR UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_search_vector();

-- Update user search vector
CREATE OR REPLACE FUNCTION update_user_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', 
    COALESCE(NEW.name, '') || ' ' || COALESCE(NEW.email, ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for users search vector
CREATE TRIGGER users_search_vector_update
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_user_search_vector();

-- Updated timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## ⚡ Advanced Query Patterns

### Repository with Complex Queries
```python
# repositories.py
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session, joinedload, selectinload
from sqlalchemy import and_, or_, func, text, desc
from sqlalchemy.dialects.postgresql import aggregate_order_by
from models import User, Post, Comment
from datetime import datetime, timedelta

class PostRepository:
    def __init__(self, db: Session):
        self.db = db

    def find_published_with_stats(self, limit: int = 10, offset: int = 0) -> List[Dict]:
        """Get published posts with engagement statistics."""
        return (
            self.db.query(
                Post.id,
                Post.title,
                Post.content,
                Post.created_at,
                User.name.label('author_name'),
                func.count(Comment.id).label('comment_count'),
                func.avg(Comment.created_at).label('last_activity')
            )
            .join(User)
            .outerjoin(Comment)
            .filter(Post.published == True)
            .group_by(Post.id, User.name)
            .order_by(desc(Post.created_at))
            .limit(limit)
            .offset(offset)
            .all()
        )

    def search_posts(self, query: str, limit: int = 20) -> List[Post]:
        """Full-text search with ranking."""
        return (
            self.db.query(Post)
            .filter(
                Post.search_vector.match(query),
                Post.published == True
            )
            .order_by(
                func.ts_rank(Post.search_vector, func.plainto_tsquery(query)).desc()
            )
            .limit(limit)
            .all()
        )

    def find_trending_posts(self, days: int = 7) -> List[Dict]:
        """Find trending posts based on recent activity."""
        since_date = datetime.utcnow() - timedelta(days=days)
        
        return (
            self.db.query(
                Post.id,
                Post.title,
                func.count(Comment.id).label('recent_comments'),
                func.sum(Post.view_count).label('total_views'),
                # Trending score calculation
                (func.count(Comment.id) * 2 + func.sum(Post.view_count) * 0.1).label('trending_score')
            )
            .outerjoin(Comment, and_(
                Comment.post_id == Post.id,
                Comment.created_at >= since_date
            ))
            .filter(Post.published == True)
            .group_by(Post.id, Post.title)
            .order_by(desc('trending_score'))
            .limit(10)
            .all()
        )

    def get_user_feed(self, user_id: str, limit: int = 20) -> List[Post]:
        """Personalized feed based on user's interests."""
        # Get user's tags from their previous interactions
        user_tags_subquery = (
            self.db.query(func.unnest(Post.tags).label('tag'))
            .join(Comment, Comment.post_id == Post.id)
            .filter(Comment.author_id == user_id)
            .distinct()
            .subquery()
        )
        
        return (
            self.db.query(Post)
            .options(joinedload(Post.author))
            .filter(
                Post.published == True,
                Post.tags.op('&&')(  # PostgreSQL array overlap operator
                    self.db.query(func.array_agg(user_tags_subquery.c.tag))
                    .scalar_subquery()
                )
            )
            .order_by(desc(Post.created_at))
            .limit(limit)
            .all()
        )

    def get_analytics_summary(self, start_date: datetime, end_date: datetime) -> Dict:
        """Get comprehensive analytics for date range."""
        result = (
            self.db.query(
                func.count(Post.id).label('total_posts'),
                func.count(func.nullif(Post.published, False)).label('published_posts'),
                func.avg(Post.view_count).label('avg_views'),
                func.percentile_cont(0.5).within_group(Post.view_count).label('median_views'),
                func.array_agg(
                    aggregate_order_by(
                        func.unnest(Post.tags), 
                        func.count().desc()
                    )
                ).label('popular_tags')
            )
            .filter(
                Post.created_at >= start_date,
                Post.created_at <= end_date
            )
            .first()
        )
        
        return {
            'total_posts': result.total_posts,
            'published_posts': result.published_posts,
            'avg_views': float(result.avg_views or 0),
            'median_views': float(result.median_views or 0),
            'popular_tags': result.popular_tags[:10] if result.popular_tags else []
        }

class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def find_with_activity_stats(self, user_id: str) -> Optional[Dict]:
        """Get user with comprehensive activity statistics."""
        result = (
            self.db.query(
                User.id,
                User.name,
                User.email,
                User.created_at,
                func.count(Post.id).label('post_count'),
                func.count(Comment.id).label('comment_count'),
                func.max(func.greatest(Post.created_at, Comment.created_at)).label('last_activity'),
                func.avg(Post.view_count).label('avg_post_views')
            )
            .outerjoin(Post, Post.author_id == User.id)
            .outerjoin(Comment, Comment.author_id == User.id)
            .filter(User.id == user_id)
            .group_by(User.id, User.name, User.email, User.created_at)
            .first()
        )
        
        if not result:
            return None
            
        return {
            'id': result.id,
            'name': result.name,
            'email': result.email,
            'created_at': result.created_at,
            'stats': {
                'post_count': result.post_count,
                'comment_count': result.comment_count,
                'last_activity': result.last_activity,
                'avg_post_views': float(result.avg_post_views or 0)
            }
        }

    def find_similar_users(self, user_id: str, limit: int = 10) -> List[User]:
        """Find users with similar interests based on tags."""
        # Get current user's tag preferences
        user_tags = (
            self.db.query(func.array_agg(func.unnest(Post.tags)).label('tags'))
            .filter(Post.author_id == user_id)
            .scalar()
        )
        
        if not user_tags:
            return []
        
        return (
            self.db.query(User)
            .join(Post, Post.author_id == User.id)
            .filter(
                User.id != user_id,
                Post.tags.op('&&')(user_tags)  # Array overlap
            )
            .group_by(User.id)
            .order_by(
                func.count(Post.id).desc(),  # Users with more overlapping content
                desc(User.created_at)
            )
            .limit(limit)
            .all()
        )
```

### Advanced JSON Queries
```python
# json_queries.py
from sqlalchemy import func, and_
from sqlalchemy.dialects.postgresql import JSONB

class UserPreferencesRepository:
    def __init__(self, db: Session):
        self.db = db

    def find_users_by_preference(self, preference_path: str, value: Any) -> List[User]:
        """Find users by nested JSON preference."""
        return (
            self.db.query(User)
            .filter(
                User.preferences[preference_path].astext == str(value)
            )
            .all()
        )

    def update_preference(self, user_id: str, preference_path: str, value: Any):
        """Update nested preference using JSON path."""
        self.db.query(User).filter(User.id == user_id).update({
            User.preferences: func.jsonb_set(
                User.preferences,
                f'{{{preference_path}}}',
                f'"{value}"'
            )
        }, synchronize_session=False)

    def find_users_with_notification_enabled(self) -> List[User]:
        """Find users with specific notification settings."""
        return (
            self.db.query(User)
            .filter(
                User.preferences['notifications']['email'].astext == 'true'
            )
            .all()
        )

    def aggregate_preferences(self) -> Dict:
        """Aggregate user preferences for analytics."""
        result = (
            self.db.query(
                func.jsonb_object_agg(
                    func.jsonb_each_text(User.preferences).key,
                    func.count()
                ).label('preference_counts')
            )
            .first()
        )
        
        return result.preference_counts if result else {}
```

## 🚀 Performance Optimization

### Connection Pooling with PgBouncer
```ini
# pgbouncer.ini
[databases]
myapp = host=localhost port=5432 dbname=myapp user=developer password=devpass123

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0
auth_type = plain
auth_file = userlist.txt
pool_mode = transaction
default_pool_size = 20
max_client_conn = 100
server_reset_query = DISCARD ALL
```

### Query Optimization Strategies
```python
# optimization.py
from sqlalchemy import event, text
from sqlalchemy.engine import Engine
import time
import logging

logger = logging.getLogger(__name__)

# Query performance monitoring
@event.listens_for(Engine, "before_cursor_execute")
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    context._query_start_time = time.time()

@event.listens_for(Engine, "after_cursor_execute")
def receive_after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - context._query_start_time
    if total > 1.0:  # Log slow queries (>1 second)
        logger.warning(f"Slow query: {total:.2f}s - {statement[:100]}...")

class QueryOptimizer:
    def __init__(self, db: Session):
        self.db = db

    def analyze_query_plan(self, query: str) -> Dict:
        """Analyze query execution plan."""
        result = self.db.execute(text(f"EXPLAIN ANALYZE {query}")).fetchall()
        return {
            'plan': [dict(row) for row in result],
            'recommendations': self._get_recommendations(result)
        }

    def get_slow_queries(self, min_duration_ms: int = 1000) -> List[Dict]:
        """Get slow queries from pg_stat_statements."""
        return self.db.execute(text("""
            SELECT 
                query,
                calls,
                total_time,
                mean_time,
                rows,
                100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
            FROM pg_stat_statements 
            WHERE mean_time > :min_duration
            ORDER BY total_time DESC
            LIMIT 20
        """), {"min_duration": min_duration_ms}).fetchall()

    def get_table_statistics(self, table_name: str) -> Dict:
        """Get comprehensive table statistics."""
        stats = self.db.execute(text("""
            SELECT 
                schemaname,
                tablename,
                n_tup_ins as inserts,
                n_tup_upd as updates,
                n_tup_del as deletes,
                n_live_tup as live_tuples,
                n_dead_tup as dead_tuples,
                last_vacuum,
                last_autovacuum,
                last_analyze,
                last_autoanalyze
            FROM pg_stat_user_tables 
            WHERE tablename = :table_name
        """), {"table_name": table_name}).first()

        size_info = self.db.execute(text("""
            SELECT 
                pg_size_pretty(pg_total_relation_size(:table_name)) as total_size,
                pg_size_pretty(pg_relation_size(:table_name)) as table_size,
                pg_size_pretty(pg_indexes_size(:table_name)) as index_size
        """), {"table_name": table_name}).first()

        return {
            'statistics': dict(stats) if stats else {},
            'size_info': dict(size_info) if size_info else {}
        }

    def optimize_table(self, table_name: str):
        """Run maintenance operations on table."""
        # Analyze table for query planner
        self.db.execute(text(f"ANALYZE {table_name}"))
        
        # Vacuum if needed (based on dead tuple ratio)
        stats = self.get_table_statistics(table_name)
        if stats['statistics']:
            dead_ratio = stats['statistics']['dead_tuples'] / max(stats['statistics']['live_tuples'], 1)
            if dead_ratio > 0.1:  # More than 10% dead tuples
                self.db.execute(text(f"VACUUM {table_name}"))
```

### Indexing Best Practices
```sql
-- Advanced indexing strategies

-- Partial indexes for common filters
CREATE INDEX idx_posts_published_recent 
ON posts (created_at DESC) 
WHERE published = true AND created_at > NOW() - INTERVAL '30 days';

-- Expression indexes
CREATE INDEX idx_users_email_lower 
ON users (LOWER(email));

-- Covering indexes to avoid table lookups
CREATE INDEX idx_posts_author_covering 
ON posts (author_id, published) 
INCLUDE (title, created_at);

-- GIN indexes for array and JSON operations
CREATE INDEX idx_posts_tags_gin 
ON posts USING GIN (tags);

CREATE INDEX idx_user_preferences_gin 
ON users USING GIN (preferences);

-- Composite indexes for common query patterns
CREATE INDEX idx_comments_post_author_created 
ON comments (post_id, author_id, created_at DESC);

-- Hash indexes for equality comparisons
CREATE INDEX idx_users_uuid_hash 
ON users USING HASH (id);
```

## 🔄 Migration & Maintenance

### Advanced Migration Patterns
```python
# migrations/versions/001_advanced_features.py
"""Add advanced PostgreSQL features

Revision ID: 001
Revises: base
Create Date: 2023-01-01 10:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '001'
down_revision = 'base'
branch_labels = None
depends_on = None

def upgrade():
    # Add ENUM type
    user_role_enum = postgresql.ENUM('user', 'admin', 'moderator', name='user_role')
    user_role_enum.create(op.get_bind())
    
    # Create extension for UUID generation
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pg_trgm"')
    op.execute('CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"')
    
    # Add columns with default values for existing data
    op.add_column('users', sa.Column('role', user_role_enum, nullable=True))
    op.execute("UPDATE users SET role = 'user' WHERE role IS NULL")
    op.alter_column('users', 'role', nullable=False)
    
    # Add JSONB columns
    op.add_column('users', sa.Column('preferences', postgresql.JSONB(), nullable=True))
    op.execute("UPDATE users SET preferences = '{}' WHERE preferences IS NULL")
    
    # Add array columns
    op.add_column('posts', sa.Column('tags', postgresql.ARRAY(sa.String()), nullable=True))
    op.execute("UPDATE posts SET tags = '{}' WHERE tags IS NULL")
    
    # Add full-text search columns
    op.add_column('posts', sa.Column('search_vector', postgresql.TSVECTOR(), nullable=True))
    op.add_column('users', sa.Column('search_vector', postgresql.TSVECTOR(), nullable=True))
    
    # Create functions and triggers
    op.execute("""
        CREATE OR REPLACE FUNCTION update_search_vector()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.search_vector := to_tsvector('english', 
            COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.content, ''));
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    
    op.execute("""
        CREATE TRIGGER posts_search_vector_update
          BEFORE INSERT OR UPDATE ON posts
          FOR EACH ROW EXECUTE FUNCTION update_search_vector();
    """)
    
    # Update existing records
    op.execute("""
        UPDATE posts SET search_vector = to_tsvector('english', 
          COALESCE(title, '') || ' ' || COALESCE(content, ''))
    """)

def downgrade():
    # Remove triggers and functions
    op.execute("DROP TRIGGER IF EXISTS posts_search_vector_update ON posts")
    op.execute("DROP FUNCTION IF EXISTS update_search_vector()")
    
    # Remove columns
    op.drop_column('users', 'search_vector')
    op.drop_column('posts', 'search_vector')
    op.drop_column('posts', 'tags')
    op.drop_column('users', 'preferences')
    op.drop_column('users', 'role')
    
    # Remove ENUM type
    op.execute("DROP TYPE user_role")
```

### Database Maintenance
```python
# maintenance.py
from sqlalchemy import text
import logging

logger = logging.getLogger(__name__)

class DatabaseMaintenance:
    def __init__(self, db: Session):
        self.db = db

    def run_maintenance(self):
        """Run comprehensive database maintenance."""
        logger.info("Starting database maintenance...")
        
        # Update statistics
        self.update_statistics()
        
        # Vacuum and analyze tables
        self.vacuum_analyze()
        
        # Reindex if needed
        self.reindex_if_needed()
        
        # Clean up old data
        self.cleanup_old_data()
        
        logger.info("Database maintenance completed")

    def update_statistics(self):
        """Update table statistics for query planner."""
        self.db.execute(text("ANALYZE"))
        self.db.commit()

    def vacuum_analyze(self):
        """Run VACUUM and ANALYZE on tables that need it."""
        # Get tables with high dead tuple ratio
        tables_needing_vacuum = self.db.execute(text("""
            SELECT tablename 
            FROM pg_stat_user_tables 
            WHERE n_dead_tup > 1000 
            AND n_dead_tup > n_live_tup * 0.1
        """)).fetchall()
        
        for table in tables_needing_vacuum:
            logger.info(f"Vacuuming table: {table.tablename}")
            self.db.execute(text(f"VACUUM ANALYZE {table.tablename}"))

    def reindex_if_needed(self):
        """Reindex tables with high bloat."""
        bloated_indexes = self.db.execute(text("""
            SELECT schemaname, tablename, indexname, bloat_ratio
            FROM (
                SELECT 
                    schemaname,
                    tablename,
                    indexname,
                    ROUND((CASE WHEN otta=0 THEN 0.0 ELSE sml.relpages/otta::numeric END)::numeric,1) AS bloat_ratio
                FROM (
                    SELECT 
                        schemaname, tablename, indexname,
                        bs, relpages, 
                        CASE WHEN relpages < otta THEN 0 ELSE otta END AS otta
                    FROM pg_stat_user_indexes
                    JOIN pg_indexes USING (schemaname, tablename, indexname)
                ) AS sml
            ) AS bloat
            WHERE bloat_ratio > 2.0
        """)).fetchall()
        
        for index in bloated_indexes:
            logger.info(f"Reindexing: {index.indexname}")
            self.db.execute(text(f"REINDEX INDEX CONCURRENTLY {index.indexname}"))

    def cleanup_old_data(self):
        """Clean up old or unnecessary data."""
        # Remove old audit logs
        deleted_logs = self.db.execute(text("""
            DELETE FROM audit_logs 
            WHERE created_at < NOW() - INTERVAL '90 days'
        """)).rowcount
        
        # Remove expired sessions
        deleted_sessions = self.db.execute(text("""
            DELETE FROM user_sessions 
            WHERE expires_at < NOW()
        """)).rowcount
        
        logger.info(f"Cleaned up {deleted_logs} old audit logs, {deleted_sessions} expired sessions")
        self.db.commit()

    def get_database_metrics(self) -> Dict:
        """Get comprehensive database metrics."""
        # Database size
        db_size = self.db.execute(text("""
            SELECT pg_size_pretty(pg_database_size(current_database()))
        """)).scalar()
        
        # Connection stats
        connection_stats = self.db.execute(text("""
            SELECT 
                count(*) as total_connections,
                count(*) FILTER (WHERE state = 'active') as active_connections,
                count(*) FILTER (WHERE state = 'idle') as idle_connections
            FROM pg_stat_activity
        """)).first()
        
        # Table sizes
        table_sizes = self.db.execute(text("""
            SELECT 
                tablename,
                pg_size_pretty(pg_total_relation_size(tablename::regclass)) as size
            FROM pg_tables 
            WHERE schemaname = 'public'
            ORDER BY pg_total_relation_size(tablename::regclass) DESC
            LIMIT 10
        """)).fetchall()
        
        return {
            'database_size': db_size,
            'connections': dict(connection_stats),
            'largest_tables': [dict(row) for row in table_sizes]
        }
```

## 🔒 Security & Backup

### Security Configuration
```python
# security.py
from sqlalchemy import event, text
from sqlalchemy.engine import Engine
import logging

logger = logging.getLogger(__name__)

# Row Level Security (RLS) setup
def setup_row_level_security(db: Session):
    """Setup row-level security policies."""
    
    # Enable RLS on sensitive tables
    db.execute(text("ALTER TABLE users ENABLE ROW LEVEL SECURITY"))
    db.execute(text("ALTER TABLE posts ENABLE ROW LEVEL SECURITY"))
    
    # Policy: Users can only see their own data
    db.execute(text("""
        CREATE POLICY user_isolation ON users 
        FOR ALL TO app_user
        USING (id = current_setting('app.current_user_id')::uuid)
    """))
    
    # Policy: Users can see published posts or their own posts
    db.execute(text("""
        CREATE POLICY post_visibility ON posts
        FOR SELECT TO app_user
        USING (
            published = true OR 
            author_id = current_setting('app.current_user_id')::uuid
        )
    """))

# Audit logging
@event.listens_for(Engine, "before_cursor_execute")
def log_sensitive_queries(conn, cursor, statement, parameters, context, executemany):
    """Log sensitive database operations."""
    sensitive_operations = ['INSERT', 'UPDATE', 'DELETE']
    if any(op in statement.upper() for op in sensitive_operations):
        logger.info(f"Database operation: {statement[:100]}...")

class DatabaseSecurity:
    def __init__(self, db: Session):
        self.db = db

    def create_audit_table(self):
        """Create audit table for tracking changes."""
        self.db.execute(text("""
            CREATE TABLE IF NOT EXISTS audit_logs (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                table_name VARCHAR(100) NOT NULL,
                operation VARCHAR(10) NOT NULL,
                old_values JSONB,
                new_values JSONB,
                user_id UUID,
                ip_address INET,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
        """))

    def setup_audit_triggers(self):
        """Setup audit triggers for all tables."""
        # Create audit function
        self.db.execute(text("""
            CREATE OR REPLACE FUNCTION audit_trigger()
            RETURNS TRIGGER AS $$
            BEGIN
                INSERT INTO audit_logs (
                    table_name, operation, old_values, new_values, 
                    user_id, ip_address
                ) VALUES (
                    TG_TABLE_NAME,
                    TG_OP,
                    CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
                    CASE WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW) 
                         WHEN TG_OP = 'UPDATE' THEN to_jsonb(NEW) 
                         ELSE NULL END,
                    current_setting('app.current_user_id', true)::uuid,
                    current_setting('app.client_ip', true)::inet
                );
                RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
            END;
            $$ LANGUAGE plpgsql;
        """))

        # Apply to important tables
        for table in ['users', 'posts', 'user_profiles']:
            self.db.execute(text(f"""
                CREATE TRIGGER {table}_audit_trigger
                AFTER INSERT OR UPDATE OR DELETE ON {table}
                FOR EACH ROW EXECUTE FUNCTION audit_trigger()
            """))
```

### Backup Strategies
```python
# backup.py
import subprocess
import os
from datetime import datetime
import boto3
from typing import Optional

class PostgreSQLBackup:
    def __init__(self, 
                 host: str, 
                 database: str, 
                 username: str, 
                 password: str,
                 s3_bucket: Optional[str] = None):
        self.host = host
        self.database = database
        self.username = username
        self.password = password
        self.s3_bucket = s3_bucket
        self.s3_client = boto3.client('s3') if s3_bucket else None

    def create_dump(self, output_path: Optional[str] = None) -> str:
        """Create PostgreSQL dump."""
        if not output_path:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            output_path = f"/backups/{self.database}_{timestamp}.sql"
        
        # Ensure backup directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Set password environment variable
        env = os.environ.copy()
        env['PGPASSWORD'] = self.password
        
        # Run pg_dump
        cmd = [
            'pg_dump',
            '-h', self.host,
            '-U', self.username,
            '-d', self.database,
            '--verbose',
            '--clean',
            '--if-exists',
            '--format=custom',
            '--file', output_path
        ]
        
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Backup failed: {result.stderr}")
        
        return output_path

    def restore_dump(self, dump_path: str):
        """Restore from PostgreSQL dump."""
        env = os.environ.copy()
        env['PGPASSWORD'] = self.password
        
        cmd = [
            'pg_restore',
            '-h', self.host,
            '-U', self.username,
            '-d', self.database,
            '--verbose',
            '--clean',
            '--if-exists',
            dump_path
        ]
        
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        
        if result.returncode != 0:
            raise Exception(f"Restore failed: {result.stderr}")

    def upload_to_s3(self, file_path: str) -> str:
        """Upload backup to S3."""
        if not self.s3_client:
            raise Exception("S3 client not configured")
        
        key = f"database-backups/{os.path.basename(file_path)}"
        
        self.s3_client.upload_file(file_path, self.s3_bucket, key)
        return f"s3://{self.s3_bucket}/{key}"

    def automated_backup(self, retention_days: int = 30) -> Dict:
        """Perform automated backup with S3 upload and cleanup."""
        # Create backup
        backup_path = self.create_dump()
        
        # Compress backup
        compressed_path = f"{backup_path}.gz"
        subprocess.run(['gzip', backup_path])
        
        # Upload to S3 if configured
        s3_url = None
        if self.s3_client:
            s3_url = self.upload_to_s3(compressed_path)
        
        # Clean up old local backups
        self._cleanup_old_backups(retention_days)
        
        return {
            'backup_path': compressed_path,
            's3_url': s3_url,
            'size': os.path.getsize(compressed_path),
            'created_at': datetime.now().isoformat()
        }

    def _cleanup_old_backups(self, retention_days: int):
        """Remove old backup files."""
        backup_dir = "/backups"
        cutoff_time = datetime.now().timestamp() - (retention_days * 24 * 3600)
        
        for filename in os.listdir(backup_dir):
            file_path = os.path.join(backup_dir, filename)
            if os.path.getmtime(file_path) < cutoff_time:
                os.remove(file_path)
```

## 📊 Monitoring & Metrics

### Performance Monitoring
```python
# monitoring.py
from sqlalchemy import text
from typing import Dict, List
import psutil
import time

class PostgreSQLMonitor:
    def __init__(self, db: Session):
        self.db = db

    def get_database_metrics(self) -> Dict:
        """Get comprehensive database metrics."""
        return {
            'connections': self._get_connection_metrics(),
            'performance': self._get_performance_metrics(),
            'storage': self._get_storage_metrics(),
            'replication': self._get_replication_metrics(),
            'locks': self._get_lock_metrics()
        }

    def _get_connection_metrics(self) -> Dict:
        """Get connection statistics."""
        result = self.db.execute(text("""
            SELECT 
                count(*) as total,
                count(*) FILTER (WHERE state = 'active') as active,
                count(*) FILTER (WHERE state = 'idle') as idle,
                count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
                max(EXTRACT(EPOCH FROM (now() - state_change))) as longest_running_seconds
            FROM pg_stat_activity
            WHERE pid != pg_backend_pid()
        """)).first()
        
        return dict(result) if result else {}

    def _get_performance_metrics(self) -> Dict:
        """Get performance statistics."""
        # Cache hit ratio
        cache_hit = self.db.execute(text("""
            SELECT 
                round(
                    100.0 * sum(blks_hit) / nullif(sum(blks_hit + blks_read), 0), 2
                ) as cache_hit_ratio
            FROM pg_stat_database
        """)).scalar()

        # Transaction statistics
        txn_stats = self.db.execute(text("""
            SELECT 
                xact_commit,
                xact_rollback,
                round(100.0 * xact_rollback / nullif(xact_commit + xact_rollback, 0), 2) as rollback_ratio
            FROM pg_stat_database 
            WHERE datname = current_database()
        """)).first()

        return {
            'cache_hit_ratio': cache_hit,
            'transactions': dict(txn_stats) if txn_stats else {}
        }

    def _get_storage_metrics(self) -> Dict:
        """Get storage usage statistics."""
        # Database size
        db_size = self.db.execute(text("""
            SELECT pg_size_pretty(pg_database_size(current_database())) as size
        """)).scalar()

        # Table sizes
        table_sizes = self.db.execute(text("""
            SELECT 
                schemaname,
                tablename,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
                pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
            FROM pg_tables 
            WHERE schemaname = 'public'
            ORDER BY size_bytes DESC
            LIMIT 10
        """)).fetchall()

        return {
            'database_size': db_size,
            'largest_tables': [dict(row) for row in table_sizes]
        }

    def _get_replication_metrics(self) -> Dict:
        """Get replication status (if applicable)."""
        try:
            replication_stats = self.db.execute(text("""
                SELECT 
                    client_addr,
                    state,
                    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)) as sending_lag,
                    pg_size_pretty(pg_wal_lsn_diff(sent_lsn, flush_lsn)) as receiving_lag
                FROM pg_stat_replication
            """)).fetchall()
            
            return {'replicas': [dict(row) for row in replication_stats]}
        except Exception:
            return {'replicas': []}

    def _get_lock_metrics(self) -> Dict:
        """Get lock information."""
        locks = self.db.execute(text("""
            SELECT 
                mode,
                count(*) as count
            FROM pg_locks 
            GROUP BY mode
            ORDER BY count DESC
        """)).fetchall()

        blocking_queries = self.db.execute(text("""
            SELECT 
                blocked_locks.pid AS blocked_pid,
                blocked_activity.usename AS blocked_user,
                blocking_locks.pid AS blocking_pid,
                blocking_activity.usename AS blocking_user,
                blocked_activity.query AS blocked_statement,
                blocking_activity.query AS current_statement_in_blocking_process
            FROM pg_catalog.pg_locks blocked_locks
            JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
            JOIN pg_catalog.pg_locks blocking_locks 
                ON blocking_locks.locktype = blocked_locks.locktype
                AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
                AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
                AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
                AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
                AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
                AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
                AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
                AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
                AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
                AND blocking_locks.pid != blocked_locks.pid
            JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
            WHERE NOT blocked_locks.GRANTED
        """)).fetchall()

        return {
            'lock_counts': [dict(row) for row in locks],
            'blocking_queries': [dict(row) for row in blocking_queries]
        }

    def get_slow_queries(self, limit: int = 10) -> List[Dict]:
        """Get slowest queries from pg_stat_statements."""
        return self.db.execute(text("""
            SELECT 
                query,
                calls,
                total_time,
                mean_time,
                stddev_time,
                rows,
                100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
            FROM pg_stat_statements 
            ORDER BY total_time DESC
            LIMIT :limit
        """), {"limit": limit}).fetchall()

    def reset_statistics(self):
        """Reset pg_stat_statements statistics."""
        self.db.execute(text("SELECT pg_stat_statements_reset()"))
        self.db.commit()
```

## 🛠️ Best Practices Summary

### 1. Connection Management
- Use connection pooling (PgBouncer recommended)
- Set appropriate pool sizes based on workload
- Monitor connection usage and tune accordingly
- Use async drivers for high-concurrency applications

### 2. Query Optimization
- Use EXPLAIN ANALYZE for query performance analysis
- Create appropriate indexes for common query patterns
- Avoid N+1 query problems with eager loading
- Use bulk operations for large data sets

### 3. Schema Design
- Use appropriate data types (UUID, JSONB, arrays)
- Implement proper foreign key constraints
- Use partial indexes for filtered queries
- Consider table partitioning for large datasets

### 4. Security
- Implement Row Level Security (RLS) for multi-tenant apps
- Use parameterized queries to prevent SQL injection
- Set up audit logging for sensitive operations
- Regular security updates and monitoring

### 5. Maintenance
- Regular VACUUM and ANALYZE operations
- Monitor and reindex bloated indexes
- Clean up old data with retention policies
- Automated backups with point-in-time recovery

---

*PostgreSQL provides enterprise-grade features and performance for production applications. Proper configuration and maintenance are key to getting the most out of this powerful database.*
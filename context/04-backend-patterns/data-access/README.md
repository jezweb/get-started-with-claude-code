# Data Access Patterns

Comprehensive guide to implementing efficient, scalable, and maintainable data access patterns including repository pattern, unit of work, query optimization, and database design best practices.

## 🎯 Data Access Overview

Modern data access patterns focus on:
- **Repository Pattern** - Abstraction over data persistence
- **Unit of Work** - Transaction management and consistency
- **Query Optimization** - Efficient data retrieval strategies
- **Connection Management** - Pooling and resource optimization
- **ORM vs Raw SQL** - Choosing the right approach
- **Database Migrations** - Schema evolution and versioning

## 📚 Repository Pattern

### Basic Repository Implementation

```python
# Generic repository interface
from abc import ABC, abstractmethod
from typing import Generic, TypeVar, List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()
T = TypeVar('T', bound=Base)

class IRepository(ABC, Generic[T]):
    """Repository interface"""
    
    @abstractmethod
    async def get_by_id(self, id: Any) -> Optional[T]:
        pass
    
    @abstractmethod
    async def get_all(self) -> List[T]:
        pass
    
    @abstractmethod
    async def add(self, entity: T) -> T:
        pass
    
    @abstractmethod
    async def update(self, entity: T) -> T:
        pass
    
    @abstractmethod
    async def delete(self, id: Any) -> bool:
        pass
    
    @abstractmethod
    async def find(self, **filters) -> List[T]:
        pass

# SQLAlchemy repository implementation
class SQLAlchemyRepository(IRepository[T]):
    """Generic SQLAlchemy repository"""
    
    def __init__(self, session: Session, model: type[T]):
        self._session = session
        self._model = model
    
    async def get_by_id(self, id: Any) -> Optional[T]:
        return self._session.query(self._model).filter(
            self._model.id == id
        ).first()
    
    async def get_all(self) -> List[T]:
        return self._session.query(self._model).all()
    
    async def add(self, entity: T) -> T:
        self._session.add(entity)
        self._session.flush()
        return entity
    
    async def update(self, entity: T) -> T:
        self._session.merge(entity)
        self._session.flush()
        return entity
    
    async def delete(self, id: Any) -> bool:
        entity = await self.get_by_id(id)
        if entity:
            self._session.delete(entity)
            self._session.flush()
            return True
        return False
    
    async def find(self, **filters) -> List[T]:
        query = self._session.query(self._model)
        for key, value in filters.items():
            if hasattr(self._model, key):
                query = query.filter(getattr(self._model, key) == value)
        return query.all()

# Specific repository with custom methods
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class UserRepository(SQLAlchemyRepository[User]):
    """User-specific repository"""
    
    def __init__(self, session: Session):
        super().__init__(session, User)
    
    async def get_by_email(self, email: str) -> Optional[User]:
        return self._session.query(User).filter(
            User.email == email
        ).first()
    
    async def get_by_username(self, username: str) -> Optional[User]:
        return self._session.query(User).filter(
            User.username == username
        ).first()
    
    async def get_active_users(self) -> List[User]:
        return self._session.query(User).filter(
            User.is_active == True
        ).all()
    
    async def search(self, query: str) -> List[User]:
        return self._session.query(User).filter(
            (User.email.contains(query)) |
            (User.username.contains(query))
        ).all()
```

### Advanced Repository Features

```python
# Repository with pagination and sorting
from typing import Tuple
from sqlalchemy import desc, asc
from enum import Enum

class SortOrder(str, Enum):
    ASC = "asc"
    DESC = "desc"

class PagedResult(Generic[T]):
    def __init__(self, items: List[T], total: int, page: int, per_page: int):
        self.items = items
        self.total = total
        self.page = page
        self.per_page = per_page
        self.pages = (total + per_page - 1) // per_page

class AdvancedRepository(SQLAlchemyRepository[T]):
    """Repository with advanced features"""
    
    async def get_paged(
        self,
        page: int = 1,
        per_page: int = 20,
        sort_by: Optional[str] = None,
        sort_order: SortOrder = SortOrder.ASC,
        **filters
    ) -> PagedResult[T]:
        query = self._session.query(self._model)
        
        # Apply filters
        for key, value in filters.items():
            if hasattr(self._model, key) and value is not None:
                query = query.filter(getattr(self._model, key) == value)
        
        # Get total count
        total = query.count()
        
        # Apply sorting
        if sort_by and hasattr(self._model, sort_by):
            order_func = asc if sort_order == SortOrder.ASC else desc
            query = query.order_by(order_func(getattr(self._model, sort_by)))
        
        # Apply pagination
        offset = (page - 1) * per_page
        items = query.offset(offset).limit(per_page).all()
        
        return PagedResult(items, total, page, per_page)
    
    async def bulk_insert(self, entities: List[T]) -> List[T]:
        """Efficient bulk insert"""
        self._session.bulk_insert_mappings(
            self._model,
            [entity.__dict__ for entity in entities]
        )
        self._session.flush()
        return entities
    
    async def bulk_update(self, updates: List[Dict[str, Any]]) -> int:
        """Bulk update with mappings"""
        self._session.bulk_update_mappings(self._model, updates)
        self._session.flush()
        return len(updates)
    
    async def exists(self, **filters) -> bool:
        """Check if entity exists"""
        query = self._session.query(self._model.id)
        for key, value in filters.items():
            if hasattr(self._model, key):
                query = query.filter(getattr(self._model, key) == value)
        return query.first() is not None

# Specification pattern for complex queries
class Specification(ABC):
    """Base specification for query criteria"""
    
    @abstractmethod
    def is_satisfied_by(self, query):
        pass
    
    def and_(self, other: 'Specification') -> 'AndSpecification':
        return AndSpecification(self, other)
    
    def or_(self, other: 'Specification') -> 'OrSpecification':
        return OrSpecification(self, other)
    
    def not_(self) -> 'NotSpecification':
        return NotSpecification(self)

class AndSpecification(Specification):
    def __init__(self, left: Specification, right: Specification):
        self.left = left
        self.right = right
    
    def is_satisfied_by(self, query):
        return self.left.is_satisfied_by(
            self.right.is_satisfied_by(query)
        )

class ActiveUserSpecification(Specification):
    def is_satisfied_by(self, query):
        return query.filter(User.is_active == True)

class EmailVerifiedSpecification(Specification):
    def is_satisfied_by(self, query):
        return query.filter(User.email_verified == True)

# Usage
active_and_verified = ActiveUserSpecification().and_(
    EmailVerifiedSpecification()
)
```

## 🔄 Unit of Work Pattern

### Basic Unit of Work

```python
# Unit of Work implementation
from contextlib import contextmanager
from typing import Dict, Type

class UnitOfWork:
    """Unit of Work pattern for transaction management"""
    
    def __init__(self, session_factory):
        self._session_factory = session_factory
        self._repositories: Dict[Type, IRepository] = {}
    
    def __enter__(self):
        self._session = self._session_factory()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        else:
            self.commit()
        self._session.close()
    
    def commit(self):
        """Commit the transaction"""
        try:
            self._session.commit()
        except Exception:
            self.rollback()
            raise
    
    def rollback(self):
        """Rollback the transaction"""
        self._session.rollback()
    
    def repository(self, model: Type[T]) -> IRepository[T]:
        """Get or create repository for model"""
        if model not in self._repositories:
            self._repositories[model] = SQLAlchemyRepository(
                self._session, model
            )
        return self._repositories[model]
    
    @property
    def users(self) -> UserRepository:
        """Convenience property for user repository"""
        if User not in self._repositories:
            self._repositories[User] = UserRepository(self._session)
        return self._repositories[User]

# Usage example
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine("postgresql://user:pass@localhost/db")
SessionLocal = sessionmaker(bind=engine)

async def create_user_with_profile(user_data: dict, profile_data: dict):
    """Create user and profile in a single transaction"""
    with UnitOfWork(SessionLocal) as uow:
        # Create user
        user = User(**user_data)
        user = await uow.users.add(user)
        
        # Create profile
        profile = UserProfile(user_id=user.id, **profile_data)
        await uow.repository(UserProfile).add(profile)
        
        # Transaction commits automatically
        return user
```

### Advanced Unit of Work Features

```python
# Unit of Work with event handling and audit
from typing import List, Callable, Any
from datetime import datetime
import json

class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True)
    entity_type = Column(String)
    entity_id = Column(String)
    action = Column(String)  # create, update, delete
    changes = Column(JSON)
    user_id = Column(Integer)
    timestamp = Column(DateTime, default=datetime.utcnow)

class EventType(Enum):
    BEFORE_COMMIT = "before_commit"
    AFTER_COMMIT = "after_commit"
    BEFORE_ROLLBACK = "before_rollback"
    AFTER_ROLLBACK = "after_rollback"

class AdvancedUnitOfWork(UnitOfWork):
    """Unit of Work with events and auditing"""
    
    def __init__(self, session_factory, current_user_id: Optional[int] = None):
        super().__init__(session_factory)
        self._events: Dict[EventType, List[Callable]] = {
            event: [] for event in EventType
        }
        self._current_user_id = current_user_id
        self._changes: List[Dict[str, Any]] = []
    
    def register_event(self, event_type: EventType, handler: Callable):
        """Register event handler"""
        self._events[event_type].append(handler)
    
    def _trigger_event(self, event_type: EventType):
        """Trigger all handlers for event"""
        for handler in self._events[event_type]:
            handler(self)
    
    def _track_changes(self):
        """Track entity changes for audit"""
        for entity in self._session.new:
            self._changes.append({
                "entity": entity,
                "action": "create",
                "changes": self._entity_to_dict(entity)
            })
        
        for entity in self._session.dirty:
            # Get original values
            history = {}
            for prop in entity.__mapper__.iterate_properties:
                hist = self._session.get_history(entity, prop.key)
                if hist.has_changes():
                    history[prop.key] = {
                        "old": hist.deleted[0] if hist.deleted else None,
                        "new": hist.added[0] if hist.added else None
                    }
            
            if history:
                self._changes.append({
                    "entity": entity,
                    "action": "update",
                    "changes": history
                })
        
        for entity in self._session.deleted:
            self._changes.append({
                "entity": entity,
                "action": "delete",
                "changes": self._entity_to_dict(entity)
            })
    
    def _entity_to_dict(self, entity) -> dict:
        """Convert entity to dictionary"""
        return {
            c.key: getattr(entity, c.key)
            for c in entity.__table__.columns
        }
    
    def _create_audit_logs(self):
        """Create audit log entries"""
        for change in self._changes:
            entity = change["entity"]
            audit = AuditLog(
                entity_type=entity.__class__.__name__,
                entity_id=str(entity.id) if hasattr(entity, 'id') else None,
                action=change["action"],
                changes=change["changes"],
                user_id=self._current_user_id
            )
            self._session.add(audit)
    
    def commit(self):
        """Commit with event handling and audit"""
        try:
            # Track changes before commit
            self._track_changes()
            
            # Trigger before commit events
            self._trigger_event(EventType.BEFORE_COMMIT)
            
            # Create audit logs
            if self._changes:
                self._create_audit_logs()
            
            # Commit transaction
            self._session.commit()
            
            # Trigger after commit events
            self._trigger_event(EventType.AFTER_COMMIT)
            
        except Exception as e:
            self.rollback()
            raise
    
    def rollback(self):
        """Rollback with event handling"""
        self._trigger_event(EventType.BEFORE_ROLLBACK)
        self._session.rollback()
        self._trigger_event(EventType.AFTER_ROLLBACK)

# Domain events
class DomainEvent:
    """Base domain event"""
    def __init__(self, aggregate_id: Any):
        self.aggregate_id = aggregate_id
        self.occurred_at = datetime.utcnow()

class UserCreatedEvent(DomainEvent):
    def __init__(self, user_id: int, email: str):
        super().__init__(user_id)
        self.email = email

class EventDispatcher:
    """Dispatch domain events"""
    
    def __init__(self):
        self._handlers: Dict[Type[DomainEvent], List[Callable]] = {}
    
    def register(self, event_type: Type[DomainEvent], handler: Callable):
        if event_type not in self._handlers:
            self._handlers[event_type] = []
        self._handlers[event_type].append(handler)
    
    async def dispatch(self, event: DomainEvent):
        handlers = self._handlers.get(type(event), [])
        for handler in handlers:
            await handler(event)

# Usage with events
event_dispatcher = EventDispatcher()

async def send_welcome_email(event: UserCreatedEvent):
    # Send email logic
    pass

event_dispatcher.register(UserCreatedEvent, send_welcome_email)

async def create_user_with_events(user_data: dict):
    with AdvancedUnitOfWork(SessionLocal, current_user_id=1) as uow:
        # Register event handler
        events = []
        
        def collect_events(uow):
            # Collect domain events from entities
            for entity in uow._session.new:
                if isinstance(entity, User):
                    events.append(
                        UserCreatedEvent(entity.id, entity.email)
                    )
        
        uow.register_event(EventType.AFTER_COMMIT, collect_events)
        
        # Create user
        user = await uow.users.add(User(**user_data))
        
        # Commit (triggers events)
        uow.commit()
        
        # Dispatch collected events
        for event in events:
            await event_dispatcher.dispatch(event)
        
        return user
```

## ⚡ Query Optimization

### N+1 Query Prevention

```python
# Eager loading strategies
from sqlalchemy.orm import joinedload, selectinload, subqueryload, contains_eager
from sqlalchemy import select

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(Integer, primary_key=True)
    title = Column(String)
    content = Column(Text)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Relationships
    user = relationship("User", back_populates="posts")
    comments = relationship("Comment", back_populates="post")
    tags = relationship("Tag", secondary="post_tags", back_populates="posts")

class OptimizedPostRepository:
    """Repository with query optimization"""
    
    def __init__(self, session: Session):
        self._session = session
    
    async def get_posts_with_users(self) -> List[Post]:
        """Get posts with users using joinedload"""
        return self._session.query(Post)\
            .options(joinedload(Post.user))\
            .all()
    
    async def get_posts_with_comments(self) -> List[Post]:
        """Get posts with comments using selectinload"""
        return self._session.query(Post)\
            .options(selectinload(Post.comments))\
            .all()
    
    async def get_posts_full(self) -> List[Post]:
        """Get posts with all related data"""
        return self._session.query(Post)\
            .options(
                joinedload(Post.user),
                selectinload(Post.comments).joinedload(Comment.user),
                selectinload(Post.tags)
            )\
            .all()
    
    async def get_user_posts_optimized(self, user_id: int) -> List[Post]:
        """Get user posts with optimized query"""
        return self._session.query(Post)\
            .join(Post.user)\
            .filter(User.id == user_id)\
            .options(contains_eager(Post.user))\
            .all()

# Query result caching
from functools import lru_cache
import hashlib
import pickle

class CachedRepository:
    """Repository with query caching"""
    
    def __init__(self, session: Session, cache_backend):
        self._session = session
        self._cache = cache_backend
    
    def _cache_key(self, query_str: str, params: dict) -> str:
        """Generate cache key for query"""
        key_data = f"{query_str}:{sorted(params.items())}"
        return hashlib.md5(key_data.encode()).hexdigest()
    
    async def cached_query(
        self,
        query,
        params: dict = None,
        ttl: int = 300
    ) -> List[Any]:
        """Execute cached query"""
        # Generate cache key
        query_str = str(query.statement.compile(compile_kwargs={"literal_binds": True}))
        cache_key = self._cache_key(query_str, params or {})
        
        # Check cache
        cached = await self._cache.get(cache_key)
        if cached:
            return pickle.loads(cached)
        
        # Execute query
        if params:
            result = query.params(**params).all()
        else:
            result = query.all()
        
        # Cache result
        await self._cache.set(
            cache_key,
            pickle.dumps(result),
            ttl=ttl
        )
        
        return result
    
    async def invalidate_cache(self, pattern: str):
        """Invalidate cache entries matching pattern"""
        keys = await self._cache.scan(pattern)
        for key in keys:
            await self._cache.delete(key)
```

### Database Query Performance

```python
# Query performance monitoring
import time
from sqlalchemy import event
from sqlalchemy.engine import Engine
import logging

logger = logging.getLogger(__name__)

@event.listens_for(Engine, "before_cursor_execute")
def before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    context._query_start_time = time.time()
    logger.debug("Start Query: %s", statement)

@event.listens_for(Engine, "after_cursor_execute")
def after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    total = time.time() - context._query_start_time
    logger.debug("Query Complete in %.4f seconds", total)
    
    # Log slow queries
    if total > 1.0:  # 1 second threshold
        logger.warning(
            "Slow query detected (%.4f seconds): %s",
            total,
            statement[:200]
        )

# Query optimization helpers
class QueryOptimizer:
    """Database query optimization utilities"""
    
    @staticmethod
    def explain_query(session: Session, query) -> str:
        """Get query execution plan"""
        # For PostgreSQL
        explained = session.execute(
            f"EXPLAIN ANALYZE {query.statement.compile(compile_kwargs={'literal_binds': True})}"
        ).fetchall()
        return "\n".join(row[0] for row in explained)
    
    @staticmethod
    async def analyze_table_stats(session: Session, table_name: str) -> dict:
        """Get table statistics"""
        # PostgreSQL specific
        stats = session.execute(f"""
            SELECT 
                schemaname,
                tablename,
                n_live_tup as row_count,
                n_dead_tup as dead_rows,
                last_vacuum,
                last_autovacuum,
                last_analyze,
                last_autoanalyze
            FROM pg_stat_user_tables
            WHERE tablename = '{table_name}'
        """).first()
        
        return dict(stats) if stats else {}
    
    @staticmethod
    async def find_missing_indexes(session: Session) -> List[dict]:
        """Find potentially missing indexes"""
        # PostgreSQL query to find missing indexes
        missing = session.execute("""
            SELECT 
                schemaname,
                tablename,
                attname,
                n_distinct,
                correlation
            FROM pg_stats
            WHERE schemaname = 'public'
            AND n_distinct > 100
            AND correlation < 0.1
            ORDER BY n_distinct DESC
        """).fetchall()
        
        return [
            {
                "table": row.tablename,
                "column": row.attname,
                "distinct_values": row.n_distinct,
                "correlation": row.correlation
            }
            for row in missing
        ]

# Batch operations for performance
class BatchOperations:
    """Efficient batch database operations"""
    
    @staticmethod
    async def batch_insert_optimized(
        session: Session,
        model: Type[Base],
        records: List[dict],
        batch_size: int = 1000
    ):
        """Optimized batch insert with chunking"""
        for i in range(0, len(records), batch_size):
            batch = records[i:i + batch_size]
            
            # Use core insert for performance
            stmt = model.__table__.insert()
            session.execute(stmt, batch)
            
            # Commit after each batch to avoid memory issues
            session.commit()
    
    @staticmethod
    async def batch_update_optimized(
        session: Session,
        model: Type[Base],
        updates: List[dict],
        batch_size: int = 500
    ):
        """Optimized batch update"""
        for i in range(0, len(updates), batch_size):
            batch = updates[i:i + batch_size]
            
            # Group updates by value
            update_groups = {}
            for update in batch:
                key = tuple(
                    (k, v) for k, v in update.items() 
                    if k != 'id'
                )
                if key not in update_groups:
                    update_groups[key] = []
                update_groups[key].append(update['id'])
            
            # Execute grouped updates
            for values, ids in update_groups.items():
                stmt = model.__table__.update()\
                    .where(model.id.in_(ids))\
                    .values(dict(values))
                session.execute(stmt)
            
            session.commit()
```

## 🔌 Connection Pool Management

### Connection Pool Configuration

```python
# Advanced connection pool setup
from sqlalchemy.pool import QueuePool, NullPool, StaticPool
from sqlalchemy import create_engine, pool
import asyncpg
from contextvars import ContextVar

# Database configuration
class DatabaseConfig:
    """Database connection configuration"""
    
    def __init__(
        self,
        database_url: str,
        pool_size: int = 10,
        max_overflow: int = 20,
        pool_timeout: int = 30,
        pool_recycle: int = 3600,
        echo: bool = False
    ):
        self.database_url = database_url
        self.pool_size = pool_size
        self.max_overflow = max_overflow
        self.pool_timeout = pool_timeout
        self.pool_recycle = pool_recycle
        self.echo = echo
    
    def create_engine(self):
        """Create SQLAlchemy engine with optimized pool"""
        return create_engine(
            self.database_url,
            poolclass=QueuePool,
            pool_size=self.pool_size,
            max_overflow=self.max_overflow,
            pool_timeout=self.pool_timeout,
            pool_recycle=self.pool_recycle,
            echo=self.echo,
            # Performance optimizations
            connect_args={
                "server_settings": {
                    "application_name": "myapp",
                    "jit": "off"
                },
                "command_timeout": 60,
                "prepared_statement_cache_size": 0,  # Disable if using PgBouncer
            }
        )

# Async connection pool with asyncpg
class AsyncDatabasePool:
    """Async database connection pool"""
    
    def __init__(self, database_url: str, min_size: int = 10, max_size: int = 20):
        self.database_url = database_url
        self.min_size = min_size
        self.max_size = max_size
        self._pool = None
    
    async def initialize(self):
        """Initialize connection pool"""
        self._pool = await asyncpg.create_pool(
            self.database_url,
            min_size=self.min_size,
            max_size=self.max_size,
            max_queries=50000,
            max_inactive_connection_lifetime=300.0,
            timeout=60.0,
            command_timeout=60.0,
            # Connection initialization
            init=self._init_connection
        )
    
    async def _init_connection(self, conn):
        """Initialize each connection"""
        # Set connection parameters
        await conn.set_type_codec(
            'json',
            encoder=json.dumps,
            decoder=json.loads,
            schema='pg_catalog'
        )
        
        # Prepare common statements
        await conn.prepare('SELECT * FROM users WHERE id = $1')
        await conn.prepare('SELECT * FROM users WHERE email = $1')
    
    async def close(self):
        """Close connection pool"""
        if self._pool:
            await self._pool.close()
    
    @contextmanager
    async def acquire(self):
        """Acquire connection from pool"""
        async with self._pool.acquire() as conn:
            yield conn
    
    async def execute(self, query: str, *args):
        """Execute query with automatic connection management"""
        async with self.acquire() as conn:
            return await conn.execute(query, *args)
    
    async def fetch(self, query: str, *args):
        """Fetch results with automatic connection management"""
        async with self.acquire() as conn:
            return await conn.fetch(query, *args)

# Connection pool monitoring
class PoolMonitor:
    """Monitor connection pool health"""
    
    def __init__(self, engine: Engine):
        self.engine = engine
    
    def get_pool_status(self) -> dict:
        """Get current pool status"""
        pool = self.engine.pool
        return {
            "size": pool.size(),
            "checked_in": pool.checkedin(),
            "checked_out": pool.checkedout(),
            "overflow": pool.overflow(),
            "total": pool.size() + pool.overflow()
        }
    
    def log_pool_status(self):
        """Log pool status"""
        status = self.get_pool_status()
        logger.info(
            "Pool Status - Size: %d, In: %d, Out: %d, Overflow: %d",
            status["size"],
            status["checked_in"],
            status["checked_out"],
            status["overflow"]
        )
    
    async def health_check(self) -> bool:
        """Check database connectivity"""
        try:
            with self.engine.connect() as conn:
                result = conn.execute("SELECT 1")
                return result.scalar() == 1
        except Exception as e:
            logger.error("Database health check failed: %s", e)
            return False

# Per-request connection management
db_session: ContextVar[Session] = ContextVar('db_session')

async def get_db_session() -> Session:
    """Get database session for current context"""
    try:
        return db_session.get()
    except LookupError:
        # Create new session
        session = SessionLocal()
        db_session.set(session)
        return session

@app.middleware("http")
async def db_session_middleware(request: Request, call_next):
    """Manage database session per request"""
    session = SessionLocal()
    db_session.set(session)
    
    try:
        response = await call_next(request)
        session.commit()
        return response
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
```

## 🔄 Database Migrations

### Migration Management with Alembic

```python
# Alembic configuration and utilities
from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.runtime.migration import MigrationContext
from sqlalchemy import inspect

class MigrationManager:
    """Database migration management"""
    
    def __init__(self, database_url: str, script_location: str = "alembic"):
        self.database_url = database_url
        self.config = Config()
        self.config.set_main_option("script_location", script_location)
        self.config.set_main_option("sqlalchemy.url", database_url)
    
    def create_migration(self, message: str):
        """Create new migration"""
        command.revision(self.config, message=message, autogenerate=True)
    
    def upgrade(self, revision: str = "head"):
        """Upgrade database to revision"""
        command.upgrade(self.config, revision)
    
    def downgrade(self, revision: str):
        """Downgrade database to revision"""
        command.downgrade(self.config, revision)
    
    def get_current_revision(self) -> Optional[str]:
        """Get current database revision"""
        engine = create_engine(self.database_url)
        with engine.connect() as conn:
            context = MigrationContext.configure(conn)
            return context.get_current_revision()
    
    def get_pending_migrations(self) -> List[str]:
        """Get list of pending migrations"""
        script = ScriptDirectory.from_config(self.config)
        current = self.get_current_revision()
        
        pending = []
        for revision in script.walk_revisions():
            if revision.revision != current:
                pending.append(revision.revision)
            else:
                break
        
        return list(reversed(pending))
    
    def validate_schema(self) -> bool:
        """Validate database schema matches models"""
        engine = create_engine(self.database_url)
        inspector = inspect(engine)
        
        # Get database tables
        db_tables = set(inspector.get_table_names())
        
        # Get model tables
        model_tables = set(Base.metadata.tables.keys())
        
        # Check for missing tables
        missing = model_tables - db_tables
        if missing:
            logger.warning("Missing tables: %s", missing)
            return False
        
        # Check columns
        for table_name in model_tables:
            if table_name not in db_tables:
                continue
            
            db_columns = {
                col['name'] for col in inspector.get_columns(table_name)
            }
            model_columns = {
                col.name for col in Base.metadata.tables[table_name].columns
            }
            
            missing_columns = model_columns - db_columns
            if missing_columns:
                logger.warning(
                    "Missing columns in %s: %s",
                    table_name,
                    missing_columns
                )
                return False
        
        return True

# Safe migration execution
class SafeMigrationExecutor:
    """Execute migrations safely with rollback support"""
    
    def __init__(self, migration_manager: MigrationManager):
        self.manager = migration_manager
    
    async def execute_with_backup(self, revision: str = "head"):
        """Execute migration with backup"""
        current_revision = self.manager.get_current_revision()
        
        try:
            # Create backup (PostgreSQL specific)
            await self._create_backup()
            
            # Execute migration
            logger.info("Executing migration to %s", revision)
            self.manager.upgrade(revision)
            
            # Validate schema
            if not self.manager.validate_schema():
                raise Exception("Schema validation failed")
            
            logger.info("Migration completed successfully")
            
        except Exception as e:
            logger.error("Migration failed: %s", e)
            
            # Rollback migration
            if current_revision:
                logger.info("Rolling back to %s", current_revision)
                self.manager.downgrade(current_revision)
            
            # Restore from backup if needed
            await self._restore_backup()
            
            raise
    
    async def _create_backup(self):
        """Create database backup"""
        # Implementation depends on database
        pass
    
    async def _restore_backup(self):
        """Restore database from backup"""
        # Implementation depends on database
        pass

# Custom migration operations
from alembic.operations import Operations, MigrateOperation

@Operations.register_operation("create_index_concurrently")
class CreateIndexConcurrentlyOp(MigrateOperation):
    """Create index concurrently (PostgreSQL)"""
    
    def __init__(self, index_name: str, table_name: str, columns: List[str]):
        self.index_name = index_name
        self.table_name = table_name
        self.columns = columns
    
    @classmethod
    def create_index_concurrently(
        cls,
        operations,
        index_name: str,
        table_name: str,
        columns: List[str]
    ):
        op = cls(index_name, table_name, columns)
        return operations.invoke(op)
    
    def reverse(self):
        return DropIndexOp(self.index_name)

@Operations.implementation_for(CreateIndexConcurrentlyOp)
def create_index_concurrently(operations, operation):
    """Implementation for concurrent index creation"""
    columns_str = ", ".join(operation.columns)
    operations.execute(
        f"CREATE INDEX CONCURRENTLY {operation.index_name} "
        f"ON {operation.table_name} ({columns_str})"
    )
```

## 🎯 ORM vs Raw SQL

### When to Use Each Approach

```python
# Hybrid approach combining ORM and raw SQL
class HybridRepository:
    """Repository using both ORM and raw SQL"""
    
    def __init__(self, session: Session):
        self._session = session
    
    # ORM for simple CRUD
    async def create_user(self, user_data: dict) -> User:
        """Create user using ORM"""
        user = User(**user_data)
        self._session.add(user)
        self._session.flush()
        return user
    
    # Raw SQL for complex queries
    async def get_user_statistics(self, user_id: int) -> dict:
        """Get user statistics using raw SQL"""
        result = self._session.execute(text("""
            WITH user_stats AS (
                SELECT 
                    u.id,
                    u.email,
                    COUNT(DISTINCT p.id) as post_count,
                    COUNT(DISTINCT c.id) as comment_count,
                    COALESCE(AVG(p.view_count), 0) as avg_post_views,
                    MAX(p.created_at) as last_post_date
                FROM users u
                LEFT JOIN posts p ON u.id = p.user_id
                LEFT JOIN comments c ON u.id = c.user_id
                WHERE u.id = :user_id
                GROUP BY u.id, u.email
            ),
            user_engagement AS (
                SELECT 
                    user_id,
                    COUNT(*) as total_interactions,
                    COUNT(CASE WHEN action = 'like' THEN 1 END) as likes_given,
                    COUNT(CASE WHEN action = 'share' THEN 1 END) as shares_made
                FROM user_actions
                WHERE user_id = :user_id
                GROUP BY user_id
            )
            SELECT 
                us.*,
                COALESCE(ue.total_interactions, 0) as total_interactions,
                COALESCE(ue.likes_given, 0) as likes_given,
                COALESCE(ue.shares_made, 0) as shares_made
            FROM user_stats us
            LEFT JOIN user_engagement ue ON us.id = ue.user_id
        """), {"user_id": user_id}).first()
        
        return dict(result) if result else None
    
    # Hybrid for performance-critical operations
    async def bulk_update_user_scores(self, score_updates: List[dict]):
        """Bulk update using raw SQL for performance"""
        # Prepare data for bulk update
        data = [
            {"id": update["user_id"], "score": update["score"]}
            for update in score_updates
        ]
        
        # Use raw SQL for efficient bulk update
        self._session.execute(text("""
            UPDATE users 
            SET score = data.score
            FROM (VALUES :data) AS data(id, score)
            WHERE users.id = data.id
        """), {"data": data})
    
    # Dynamic query building
    async def search_users_dynamic(
        self,
        filters: dict,
        sort_by: Optional[str] = None,
        limit: int = 100
    ) -> List[dict]:
        """Dynamic query building with SQL"""
        # Build WHERE clause
        where_conditions = []
        params = {}
        
        if filters.get("email"):
            where_conditions.append("email ILIKE :email")
            params["email"] = f"%{filters['email']}%"
        
        if filters.get("is_active") is not None:
            where_conditions.append("is_active = :is_active")
            params["is_active"] = filters["is_active"]
        
        if filters.get("created_after"):
            where_conditions.append("created_at >= :created_after")
            params["created_after"] = filters["created_after"]
        
        # Build query
        query = "SELECT * FROM users"
        if where_conditions:
            query += " WHERE " + " AND ".join(where_conditions)
        
        # Add sorting
        if sort_by:
            query += f" ORDER BY {sort_by}"
        
        # Add limit
        query += f" LIMIT {limit}"
        
        # Execute
        result = self._session.execute(text(query), params)
        return [dict(row) for row in result]

# Query builder for complex dynamic queries
class QueryBuilder:
    """SQL query builder for complex queries"""
    
    def __init__(self, table: str):
        self.table = table
        self.select_fields = []
        self.joins = []
        self.where_conditions = []
        self.group_by_fields = []
        self.having_conditions = []
        self.order_by_fields = []
        self.limit_value = None
        self.offset_value = None
        self.params = {}
    
    def select(self, *fields):
        self.select_fields.extend(fields)
        return self
    
    def join(self, table: str, on: str):
        self.joins.append(f"JOIN {table} ON {on}")
        return self
    
    def left_join(self, table: str, on: str):
        self.joins.append(f"LEFT JOIN {table} ON {on}")
        return self
    
    def where(self, condition: str, **params):
        self.where_conditions.append(condition)
        self.params.update(params)
        return self
    
    def group_by(self, *fields):
        self.group_by_fields.extend(fields)
        return self
    
    def having(self, condition: str):
        self.having_conditions.append(condition)
        return self
    
    def order_by(self, field: str, direction: str = "ASC"):
        self.order_by_fields.append(f"{field} {direction}")
        return self
    
    def limit(self, value: int):
        self.limit_value = value
        return self
    
    def offset(self, value: int):
        self.offset_value = value
        return self
    
    def build(self) -> tuple[str, dict]:
        """Build SQL query and return with parameters"""
        # SELECT clause
        select_clause = ", ".join(self.select_fields) if self.select_fields else "*"
        query = f"SELECT {select_clause} FROM {self.table}"
        
        # JOIN clauses
        for join in self.joins:
            query += f" {join}"
        
        # WHERE clause
        if self.where_conditions:
            query += " WHERE " + " AND ".join(self.where_conditions)
        
        # GROUP BY clause
        if self.group_by_fields:
            query += " GROUP BY " + ", ".join(self.group_by_fields)
        
        # HAVING clause
        if self.having_conditions:
            query += " HAVING " + " AND ".join(self.having_conditions)
        
        # ORDER BY clause
        if self.order_by_fields:
            query += " ORDER BY " + ", ".join(self.order_by_fields)
        
        # LIMIT/OFFSET
        if self.limit_value:
            query += f" LIMIT {self.limit_value}"
        
        if self.offset_value:
            query += f" OFFSET {self.offset_value}"
        
        return query, self.params

# Usage example
query, params = QueryBuilder("users")\
    .select("u.id", "u.email", "COUNT(p.id) as post_count")\
    .left_join("posts p", "u.id = p.user_id")\
    .where("u.is_active = :active", active=True)\
    .where("u.created_at >= :date", date=datetime(2024, 1, 1))\
    .group_by("u.id", "u.email")\
    .having("COUNT(p.id) > 5")\
    .order_by("post_count", "DESC")\
    .limit(10)\
    .build()
```

## 🚀 Best Practices

### 1. **Repository Pattern**
- Keep repositories focused on data access
- Use interfaces for testability
- Implement specific methods for complex queries
- Don't leak database concerns to business logic
- Consider using specification pattern for complex queries

### 2. **Unit of Work**
- Use for transaction boundaries
- Implement event handling for domain events
- Add audit logging at UoW level
- Handle rollbacks gracefully
- Keep transactions as short as possible

### 3. **Query Optimization**
- Use eager loading to prevent N+1 queries
- Implement query result caching
- Monitor slow queries
- Use database-specific features when needed
- Profile queries in development

### 4. **Connection Management**
- Configure connection pools appropriately
- Monitor pool health
- Use connection recycling
- Implement health checks
- Handle connection failures gracefully

### 5. **Migration Strategy**
- Always test migrations in staging
- Implement rollback procedures
- Use concurrent operations when possible
- Version control all migrations
- Document breaking changes

### 6. **ORM vs Raw SQL**
- Use ORM for simple CRUD operations
- Use raw SQL for complex queries
- Consider hybrid approaches
- Document why raw SQL is used
- Keep SQL injection prevention in mind

## 📖 Resources & References

### Documentation
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [PostgreSQL Performance](https://www.postgresql.org/docs/current/performance-tips.html)
- [MySQL Optimization](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

### Books & Articles
- "Patterns of Enterprise Application Architecture" by Martin Fowler
- "Database Design for Mere Mortals" by Michael J. Hernandez
- "High Performance MySQL" by Baron Schwartz
- "SQL Antipatterns" by Bill Karwin

### Tools
- **ORMs** - SQLAlchemy, Tortoise-ORM, Django ORM
- **Migration Tools** - Alembic, Flyway, Liquibase
- **Monitoring** - pgAdmin, MySQL Workbench, DataGrip
- **Performance** - pg_stat_statements, slow query log

---

*This guide covers essential data access patterns for building scalable, maintainable applications. Focus on choosing the right pattern for your use case and monitoring performance in production.*
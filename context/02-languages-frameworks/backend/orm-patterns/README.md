# ORM Patterns and Database Integration

Comprehensive guide to Object-Relational Mapping (ORM) patterns, covering SQLAlchemy for Python and Prisma for Node.js, with best practices for database design and query optimization.

## 🎯 ORM Overview

Object-Relational Mapping provides:
- **Abstraction** - Work with objects instead of SQL
- **Type Safety** - Compile-time checks and IDE support
- **Migrations** - Version control for database schemas
- **Relationships** - Easy handling of foreign keys and joins
- **Query Building** - Programmatic query construction
- **Performance** - Lazy loading and query optimization

## 🐍 SQLAlchemy (Python)

### Installation and Setup

```bash
# Install SQLAlchemy and database drivers
pip install sqlalchemy alembic
pip install psycopg2-binary  # PostgreSQL
pip install PyMySQL          # MySQL
pip install aiosqlite        # Async SQLite

# For async support
pip install sqlalchemy[asyncio] asyncpg
```

### Basic Configuration

```python
# database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import NullPool, QueuePool
import os

# Database URL
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://user:password@localhost/dbname"
)

# Create engine with connection pooling
engine = create_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,  # Verify connections before using
    echo=True if os.getenv("DEBUG") else False
)

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base class for models
Base = declarative_base()

# Dependency for FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Async configuration
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.asyncio import async_sessionmaker

async_engine = create_async_engine(
    DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    echo=True,
    pool_size=5,
    max_overflow=10
)

AsyncSessionLocal = async_sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_async_db():
    async with AsyncSessionLocal() as session:
        yield session
```

### Model Definition

```python
# models/user.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship, backref
from sqlalchemy.sql import func
from sqlalchemy.ext.hybrid import hybrid_property
from database import Base
import bcrypt

# Association table for many-to-many
user_roles = Table(
    'user_roles',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id', ondelete='CASCADE')),
    Column('role_id', Integer, ForeignKey('roles.id', ondelete='CASCADE')),
    UniqueConstraint('user_id', 'role_id')
)

class User(Base):
    __tablename__ = 'users'
    __table_args__ = (
        Index('idx_user_email', 'email'),
        Index('idx_user_created', 'created_at'),
        {'schema': 'public'}  # PostgreSQL schema
    )
    
    # Columns
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False)
    username = Column(String(50), unique=True, nullable=False)
    _password = Column('password', String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    profile = relationship("Profile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    roles = relationship("Role", secondary=user_roles, back_populates="users")
    
    # Hybrid property for password
    @hybrid_property
    def password(self):
        return self._password
    
    @password.setter
    def password(self, plaintext):
        self._password = bcrypt.hashpw(
            plaintext.encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')
    
    def verify_password(self, plaintext):
        return bcrypt.checkpw(
            plaintext.encode('utf-8'),
            self._password.encode('utf-8')
        )
    
    # Methods
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}')>"
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'username': self.username,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class Profile(Base):
    __tablename__ = 'profiles'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), unique=True)
    first_name = Column(String(50))
    last_name = Column(String(50))
    bio = Column(Text)
    avatar_url = Column(String(255))
    
    # Relationship
    user = relationship("User", back_populates="profile")

class Role(Base):
    __tablename__ = 'roles'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(50), unique=True, nullable=False)
    permissions = Column(JSON, default=list)
    
    # Relationship
    users = relationship("User", secondary=user_roles, back_populates="roles")
```

### Query Patterns

```python
# repositories/user_repository.py
from typing import Optional, List
from sqlalchemy.orm import Session, joinedload, selectinload
from sqlalchemy import func, and_, or_
from models import User, Role

class UserRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()
    
    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(
            func.lower(User.email) == func.lower(email)
        ).first()
    
    def get_all(
        self,
        skip: int = 0,
        limit: int = 100,
        is_active: Optional[bool] = None
    ) -> List[User]:
        query = self.db.query(User)
        
        if is_active is not None:
            query = query.filter(User.is_active == is_active)
        
        return query.offset(skip).limit(limit).all()
    
    def get_with_profile(self, user_id: int) -> Optional[User]:
        # Eager loading with join
        return self.db.query(User).options(
            joinedload(User.profile)
        ).filter(User.id == user_id).first()
    
    def get_with_posts(self, user_id: int) -> Optional[User]:
        # Eager loading with subquery
        return self.db.query(User).options(
            selectinload(User.posts)
        ).filter(User.id == user_id).first()
    
    def search(self, query: str) -> List[User]:
        # Full-text search or pattern matching
        search_filter = or_(
            User.email.ilike(f"%{query}%"),
            User.username.ilike(f"%{query}%")
        )
        return self.db.query(User).filter(search_filter).all()
    
    def get_by_role(self, role_name: str) -> List[User]:
        # Query with join
        return self.db.query(User).join(User.roles).filter(
            Role.name == role_name
        ).all()
    
    def count_active(self) -> int:
        # Aggregation
        return self.db.query(func.count(User.id)).filter(
            User.is_active == True
        ).scalar()
    
    def create(self, **kwargs) -> User:
        user = User(**kwargs)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def update(self, user_id: int, **kwargs) -> Optional[User]:
        user = self.get_by_id(user_id)
        if user:
            for key, value in kwargs.items():
                setattr(user, key, value)
            self.db.commit()
            self.db.refresh(user)
        return user
    
    def delete(self, user_id: int) -> bool:
        user = self.get_by_id(user_id)
        if user:
            self.db.delete(user)
            self.db.commit()
            return True
        return False
```

### Migrations with Alembic

```bash
# Initialize Alembic
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Add user table"

# Run migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

```python
# alembic/env.py
from alembic import context
from sqlalchemy import engine_from_config, pool
from logging.config import fileConfig
from database import Base
from models import *  # Import all models

config = context.config
fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()
```

## 🔷 Prisma (Node.js/TypeScript)

### Installation and Setup

```bash
# Install Prisma
npm install prisma @prisma/client
npm install -D @types/node

# Initialize Prisma
npx prisma init

# Install database drivers automatically handled by Prisma
```

### Schema Definition

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "fullTextIndex"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// User model
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique @db.VarChar(255)
  username  String   @unique @db.VarChar(50)
  password  String   @db.VarChar(255)
  isActive  Boolean  @default(true)
  isVerified Boolean @default(false)
  createdAt DateTime @default(now()) @db.Timestamptz
  updatedAt DateTime @updatedAt @db.Timestamptz
  
  // Relations
  profile   Profile?
  posts     Post[]
  roles     Role[]
  sessions  Session[]
  
  // Indexes
  @@index([email])
  @@index([createdAt])
  @@map("users")
}

model Profile {
  id        Int     @id @default(autoincrement())
  userId    Int     @unique
  firstName String? @db.VarChar(50)
  lastName  String? @db.VarChar(50)
  bio       String? @db.Text
  avatarUrl String? @db.VarChar(255)
  
  // Relations
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@map("profiles")
}

model Role {
  id          Int    @id @default(autoincrement())
  name        String @unique @db.VarChar(50)
  permissions Json   @default("[]")
  
  // Relations
  users User[]
  
  @@map("roles")
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String   @db.VarChar(255)
  content   String   @db.Text
  published Boolean  @default(false)
  authorId  Int
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  // Relations
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
  tags      Tag[]
  
  // Full-text search
  @@fulltext([title, content])
  @@map("posts")
}

model Tag {
  id    Int    @id @default(autoincrement())
  name  String @unique @db.VarChar(50)
  posts Post[]
  
  @@map("tags")
}

model Session {
  id        String   @id @default(cuid())
  userId    Int
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
  
  // Relations
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@index([token])
  @@map("sessions")
}

// Enums
enum UserRole {
  USER
  ADMIN
  MODERATOR
}
```

### Client Usage

```typescript
// src/lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' 
      ? ['query', 'error', 'warn'] 
      : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

// Middleware for soft deletes
prisma.$use(async (params, next) => {
  if (params.model === 'User') {
    if (params.action === 'delete') {
      params.action = 'update';
      params.args['data'] = { deletedAt: new Date() };
    }
    if (params.action === 'deleteMany') {
      params.action = 'updateMany';
      if (params.args.data !== undefined) {
        params.args.data['deletedAt'] = new Date();
      } else {
        params.args['data'] = { deletedAt: new Date() };
      }
    }
  }
  return next(params);
});
```

### Repository Pattern

```typescript
// src/repositories/userRepository.ts
import { PrismaClient, User, Prisma } from '@prisma/client';
import bcrypt from 'bcryptjs';

export class UserRepository {
  constructor(private prisma: PrismaClient) {}
  
  async findById(id: number): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }
  
  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });
  }
  
  async findMany(params: {
    skip?: number;
    take?: number;
    cursor?: Prisma.UserWhereUniqueInput;
    where?: Prisma.UserWhereInput;
    orderBy?: Prisma.UserOrderByWithRelationInput;
  }): Promise<User[]> {
    const { skip, take, cursor, where, orderBy } = params;
    return this.prisma.user.findMany({
      skip,
      take,
      cursor,
      where,
      orderBy,
    });
  }
  
  async findWithProfile(id: number) {
    return this.prisma.user.findUnique({
      where: { id },
      include: {
        profile: true,
      },
    });
  }
  
  async findWithPosts(id: number) {
    return this.prisma.user.findUnique({
      where: { id },
      include: {
        posts: {
          where: { published: true },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });
  }
  
  async search(query: string): Promise<User[]> {
    return this.prisma.user.findMany({
      where: {
        OR: [
          { email: { contains: query, mode: 'insensitive' } },
          { username: { contains: query, mode: 'insensitive' } },
        ],
      },
    });
  }
  
  async create(data: Prisma.UserCreateInput): Promise<User> {
    const hashedPassword = await bcrypt.hash(data.password, 10);
    return this.prisma.user.create({
      data: {
        ...data,
        password: hashedPassword,
      },
    });
  }
  
  async update(
    id: number,
    data: Prisma.UserUpdateInput
  ): Promise<User | null> {
    if (data.password && typeof data.password === 'string') {
      data.password = await bcrypt.hash(data.password, 10);
    }
    return this.prisma.user.update({
      where: { id },
      data,
    });
  }
  
  async delete(id: number): Promise<User> {
    return this.prisma.user.delete({
      where: { id },
    });
  }
  
  // Transaction example
  async createWithProfile(
    userData: Prisma.UserCreateInput,
    profileData: Omit<Prisma.ProfileCreateInput, 'user'>
  ) {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: userData,
      });
      
      const profile = await tx.profile.create({
        data: {
          ...profileData,
          userId: user.id,
        },
      });
      
      return { user, profile };
    });
  }
  
  // Advanced queries
  async getActiveUsersWithPostCount() {
    return this.prisma.user.findMany({
      where: { isActive: true },
      include: {
        _count: {
          select: { posts: true },
        },
      },
    });
  }
  
  // Raw SQL when needed
  async customQuery() {
    const result = await this.prisma.$queryRaw`
      SELECT u.*, COUNT(p.id) as post_count
      FROM users u
      LEFT JOIN posts p ON u.id = p."authorId"
      WHERE u."isActive" = true
      GROUP BY u.id
      ORDER BY post_count DESC
      LIMIT 10
    `;
    return result;
  }
}
```

### Migrations

```bash
# Create migration from schema
npx prisma migrate dev --name init

# Apply migrations in production
npx prisma migrate deploy

# Generate Prisma Client
npx prisma generate

# Reset database
npx prisma migrate reset

# Introspect existing database
npx prisma db pull
```

## 🎯 Advanced Patterns

### Unit of Work Pattern

```python
# Python/SQLAlchemy
class UnitOfWork:
    def __init__(self, session_factory):
        self.session_factory = session_factory
    
    def __enter__(self):
        self.session = self.session_factory()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        else:
            self.commit()
        self.session.close()
    
    def commit(self):
        self.session.commit()
    
    def rollback(self):
        self.session.rollback()

# Usage
with UnitOfWork(SessionLocal) as uow:
    user_repo = UserRepository(uow.session)
    user = user_repo.create(email="test@example.com")
    # Automatically commits or rolls back
```

```typescript
// TypeScript/Prisma
class UnitOfWork {
  private prisma: PrismaClient;
  
  constructor() {
    this.prisma = new PrismaClient();
  }
  
  async execute<T>(
    work: (prisma: Prisma.TransactionClient) => Promise<T>
  ): Promise<T> {
    return this.prisma.$transaction(work);
  }
}

// Usage
const uow = new UnitOfWork();
const result = await uow.execute(async (prisma) => {
  const user = await prisma.user.create({
    data: { email: "test@example.com", username: "test" }
  });
  const profile = await prisma.profile.create({
    data: { userId: user.id, firstName: "Test" }
  });
  return { user, profile };
});
```

### Query Optimization

```python
# SQLAlchemy - N+1 query prevention
from sqlalchemy.orm import joinedload, selectinload, subqueryload

# Bad: N+1 queries
users = session.query(User).all()
for user in users:
    print(user.posts)  # Each access triggers a query

# Good: Eager loading
users = session.query(User).options(
    selectinload(User.posts)  # One additional query
).all()

# Join loading (single query)
users = session.query(User).options(
    joinedload(User.profile)  # LEFT JOIN
).all()

# Subquery loading
users = session.query(User).options(
    subqueryload(User.posts).selectinload(Post.tags)
).all()
```

```typescript
// Prisma - Query optimization
// Bad: N+1 queries
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({
    where: { authorId: user.id }
  });
}

// Good: Include related data
const users = await prisma.user.findMany({
  include: {
    posts: {
      include: {
        tags: true
      }
    },
    profile: true
  }
});

// Select specific fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    posts: {
      select: {
        title: true,
        published: true
      }
    }
  }
});
```

## 🔍 Database Design Best Practices

### Indexing Strategy

```sql
-- Composite indexes for common queries
CREATE INDEX idx_users_email_active ON users(email, is_active);
CREATE INDEX idx_posts_author_published ON posts(author_id, published);

-- Partial indexes
CREATE INDEX idx_users_active ON users(email) WHERE is_active = true;

-- Full-text search indexes
CREATE INDEX idx_posts_search ON posts USING gin(to_tsvector('english', title || ' ' || content));
```

### Soft Deletes

```python
# SQLAlchemy
class SoftDeleteMixin:
    deleted_at = Column(DateTime, nullable=True)
    
    @hybrid_property
    def is_deleted(self):
        return self.deleted_at is not None
    
    def soft_delete(self):
        self.deleted_at = datetime.utcnow()

# Query filter
def exclude_deleted(query):
    return query.filter(Model.deleted_at.is_(None))
```

```typescript
// Prisma
model User {
  // ... other fields
  deletedAt DateTime?
  
  @@index([deletedAt])
}

// Repository with soft delete
async findMany(includeDeleted = false) {
  return this.prisma.user.findMany({
    where: includeDeleted ? {} : { deletedAt: null }
  });
}
```

## 🚀 Performance Tips

### Connection Pooling

```python
# SQLAlchemy
engine = create_engine(
    DATABASE_URL,
    pool_size=20,          # Number of connections to maintain
    max_overflow=40,       # Maximum overflow connections
    pool_timeout=30,       # Timeout for getting connection
    pool_recycle=1800,     # Recycle connections after 30 minutes
    pool_pre_ping=True     # Test connections before using
)
```

```typescript
// Prisma
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
  // Connection pool is managed automatically
  // Configure in connection string:
  // postgresql://user:password@localhost:5432/db?connection_limit=10
});
```

### Batch Operations

```python
# SQLAlchemy bulk operations
from sqlalchemy import insert

# Bulk insert
stmt = insert(User).values([
    {"email": "user1@example.com", "username": "user1"},
    {"email": "user2@example.com", "username": "user2"},
])
session.execute(stmt)
session.commit()

# Bulk update
session.bulk_update_mappings(User, [
    {"id": 1, "is_active": False},
    {"id": 2, "is_active": False},
])
```

```typescript
// Prisma batch operations
// Create many
await prisma.user.createMany({
  data: [
    { email: "user1@example.com", username: "user1" },
    { email: "user2@example.com", username: "user2" },
  ],
  skipDuplicates: true,
});

// Update many
await prisma.user.updateMany({
  where: { isActive: true },
  data: { isVerified: true },
});
```

---

*ORMs provide powerful abstractions for database operations. Choose SQLAlchemy for Python projects requiring fine-grained control, or Prisma for TypeScript projects prioritizing type safety and developer experience.*
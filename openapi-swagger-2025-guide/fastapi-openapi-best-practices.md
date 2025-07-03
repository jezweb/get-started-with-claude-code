# FastAPI OpenAPI Best Practices for 2025

## Overview

FastAPI has become the de facto standard for building AI-ready APIs in 2025, with built-in OpenAPI support and seamless integration with MCP (Model Context Protocol) servers. This guide covers FastAPI-specific patterns for creating documentation that serves both human developers and AI agents effectively.

## 🚀 FastAPI + OpenAPI + AI Integration Stack

### Core Technologies
- **FastAPI**: Modern Python framework with automatic OpenAPI generation
- **FastAPI-MCP**: Zero-configuration AI agent integration
- **Pydantic v2**: Advanced data validation and serialization
- **Swagger UI & ReDoc**: Interactive documentation interfaces
- **Uvicorn**: High-performance ASGI server

### Key Benefits for 2025:
- **Automatic Schema Generation**: FastAPI generates OpenAPI specs from Python code
- **Type Safety**: Python type hints ensure consistent documentation
- **AI-Ready**: Built-in support for MCP server generation
- **Performance**: Rust-powered Pydantic v2 for high-performance validation
- **Interactive**: Real-time API testing and exploration

## 🏗️ Project Structure for AI-Ready APIs

### Recommended Directory Layout

```
my-api/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application
│   ├── config.py              # Settings with pydantic-settings
│   ├── dependencies.py        # Dependency injection
│   ├── middleware.py          # Custom middleware
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py           # User Pydantic models
│   │   ├── product.py        # Product Pydantic models
│   │   └── common.py         # Shared models (pagination, errors)
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── users.py          # User endpoints
│   │   ├── products.py       # Product endpoints
│   │   └── health.py         # Health check endpoints
│   ├── services/
│   │   ├── __init__.py
│   │   ├── user_service.py   # Business logic
│   │   └── database.py       # Database operations
│   └── utils/
│       ├── __init__.py
│       ├── validators.py     # Custom validators
│       └── exceptions.py     # Custom exceptions
├── mcp/
│   ├── __init__.py
│   ├── server.py             # MCP server configuration
│   └── tools.py              # Custom MCP tools
├── docs/
│   ├── openapi.yaml          # Custom OpenAPI extensions
│   └── examples/             # API usage examples
├── tests/
│   ├── __init__.py
│   ├── test_users.py
│   └── test_mcp.py           # MCP integration tests
├── requirements.txt
├── pyproject.toml
└── README.md
```

## 🔧 FastAPI Application Setup

### Main Application with AI-Ready Configuration

```python
# app/main.py
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi_mcp import MCPServer, mount_mcp_server
from pydantic import ValidationError
import uvicorn

from app.config import get_settings
from app.routers import users, products, health
from app.middleware import request_logging_middleware
from app.utils.exceptions import APIException

# Get settings
settings = get_settings()

# Create FastAPI app with comprehensive metadata
app = FastAPI(
    title="AI-Ready User Management API",
    description="""
    Modern user management API designed for both human developers and AI agents.
    
    ## Features
    - 🤖 **AI Agent Ready**: Automatic MCP server generation
    - 📊 **Interactive Docs**: Real-time API testing
    - 🔒 **Secure**: JWT authentication with role-based access
    - ⚡ **High Performance**: Rust-powered Pydantic v2 validation
    - 📦 **Batch Operations**: Efficient bulk operations for AI systems
    
    ## AI Integration
    This API automatically generates MCP tools for AI agents:
    - User management operations
    - Batch processing capabilities
    - Comprehensive error handling
    - Rate limiting and monitoring
    
    ## Authentication
    Use JWT Bearer tokens for authentication:
    ```
    Authorization: Bearer <your-jwt-token>
    ```
    
    ## Rate Limits
    - Standard users: 100 requests/minute
    - Premium users: 1000 requests/minute
    - AI agents: 500 requests/minute
    """,
    version="1.0.0",
    contact={
        "name": "API Support Team",
        "email": "api-support@example.com",
        "url": "https://example.com/support"
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
    },
    terms_of_service="https://example.com/terms",
    
    # AI-specific metadata
    servers=[
        {
            "url": "https://api.example.com/v1",
            "description": "Production server"
        },
        {
            "url": "https://staging-api.example.com/v1", 
            "description": "Staging server"
        },
        {
            "url": "http://localhost:8000",
            "description": "Local development"
        }
    ],
    
    # OpenAPI customization
    openapi_tags=[
        {
            "name": "Users",
            "description": "User management operations",
            "externalDocs": {
                "description": "User management guide",
                "url": "https://docs.example.com/users"
            }
        },
        {
            "name": "Products", 
            "description": "Product catalog operations"
        },
        {
            "name": "Health",
            "description": "System health and monitoring"
        },
        {
            "name": "AI Operations",
            "description": "AI-optimized batch operations"
        }
    ],
    
    # Documentation URLs
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom middleware
app.middleware("http")(request_logging_middleware)

# Exception handlers
@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    """Handle Pydantic validation errors with AI-friendly responses"""
    return JSONResponse(
        status_code=422,
        content={
            "error": "VALIDATION_ERROR",
            "message": "Request validation failed",
            "ai_guidance": "Fix the validation errors in the specified fields and retry",
            "recovery_action": "correct_fields_and_retry",
            "field_errors": {
                str(error["loc"][-1]): error["msg"] 
                for error in exc.errors()
            },
            "request_id": getattr(request.state, "request_id", "unknown"),
            "timestamp": "2025-01-15T10:30:00Z"
        }
    )

@app.exception_handler(APIException)
async def api_exception_handler(request: Request, exc: APIException):
    """Handle custom API exceptions"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.error_code,
            "message": exc.message,
            "ai_guidance": exc.ai_guidance,
            "recovery_action": exc.recovery_action,
            "request_id": getattr(request.state, "request_id", "unknown"),
            "timestamp": "2025-01-15T10:30:00Z"
        }
    )

# Include routers
app.include_router(health.router, prefix="/health", tags=["Health"])
app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(products.router, prefix="/products", tags=["Products"])

# MCP Server Integration
if settings.enable_mcp:
    mcp_server = MCPServer(
        name="user_management_api",
        description="User management operations for AI agents",
        version="1.0.0"
    )
    
    # Mount MCP server
    mount_mcp_server(app, mcp_server, path="/mcp")

# Custom OpenAPI schema modification
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # Add custom extensions for AI systems
    openapi_schema["x-ai-metadata"] = {
        "mcp_compatible": True,
        "ai_agent_friendly": True,
        "batch_operations": True,
        "rate_limits": {
            "standard": "100/minute",
            "premium": "1000/minute",
            "ai_agents": "500/minute"
        }
    }
    
    # Add security schemes
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "JWT Bearer token for authentication"
        }
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        access_log=True
    )
```

### Configuration with Pydantic Settings

```python
# app/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )
    
    # Application settings
    app_name: str = "AI-Ready User Management API"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000
    
    # API settings
    api_version: str = "v1"
    max_request_size: int = 10 * 1024 * 1024  # 10MB
    
    # AI/MCP settings
    enable_mcp: bool = True
    mcp_port: int = 8001
    ai_rate_limit: int = 500  # requests per minute
    
    # Security settings
    jwt_secret_key: str = "your-secret-key"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60
    
    # Database settings
    database_url: str = "sqlite:///./test.db"
    
    # CORS settings
    cors_origins: List[str] = ["*"]
    
    # Rate limiting
    rate_limit_requests: int = 100
    rate_limit_period: int = 60  # seconds
    
    # Monitoring
    enable_metrics: bool = True
    log_level: str = "INFO"

# Singleton pattern for settings
settings_instance = None

def get_settings() -> Settings:
    global settings_instance
    if settings_instance is None:
        settings_instance = Settings()
    return settings_instance
```

## 📊 Advanced Pydantic Models for AI

### Base Models with AI Metadata

```python
# app/models/common.py
from pydantic import BaseModel, Field, ConfigDict, computed_field
from typing import Optional, Dict, Any, Generic, TypeVar, List
from datetime import datetime
from enum import Enum
import uuid

T = TypeVar('T')

class AIMetadata(BaseModel):
    """Metadata for AI agent consumption"""
    model_config = ConfigDict(extra='allow')
    
    machine_readable: bool = True
    ai_friendly: bool = True
    cache_duration: Optional[str] = None
    batch_capable: bool = False
    rate_limit_friendly: bool = True

class BaseAPIModel(BaseModel):
    """Base model for all API models with AI enhancements"""
    model_config = ConfigDict(
        # Performance optimizations
        validate_assignment=True,
        use_enum_values=True,
        str_strip_whitespace=True,
        
        # JSON schema enhancements
        title=None,
        description=None,
        
        # AI-friendly serialization
        populate_by_name=True,
        json_encoders={
            datetime: lambda v: v.isoformat(),
            uuid.UUID: str
        }
    )

class PaginationParams(BaseModel):
    """Standardized pagination parameters"""
    page: int = Field(
        default=1,
        ge=1,
        description="Page number (1-based)",
        example=1
    )
    limit: int = Field(
        default=20,
        ge=1,
        le=100,
        description="Items per page (max 100)",
        example=20
    )
    
    @computed_field
    @property
    def offset(self) -> int:
        """Calculate offset for database queries"""
        return (self.page - 1) * self.limit

class PaginationMeta(BaseModel):
    """Pagination metadata for responses"""
    page: int = Field(description="Current page number")
    limit: int = Field(description="Items per page")
    total: int = Field(description="Total number of items")
    total_pages: int = Field(description="Total number of pages")
    has_next: bool = Field(description="Whether there are more pages")
    has_previous: bool = Field(description="Whether there are previous pages")
    
    @computed_field
    @property
    def next_page(self) -> Optional[int]:
        """Next page number if available"""
        return self.page + 1 if self.has_next else None
    
    @computed_field
    @property
    def previous_page(self) -> Optional[int]:
        """Previous page number if available"""
        return self.page - 1 if self.has_previous else None

class APIResponse(BaseModel, Generic[T]):
    """Standardized API response wrapper"""
    success: bool = Field(default=True, description="Operation success status")
    message: str = Field(default="Success", description="Response message")
    data: Optional[T] = Field(default=None, description="Response data")
    pagination: Optional[PaginationMeta] = Field(default=None, description="Pagination info")
    meta: Optional[Dict[str, Any]] = Field(default=None, description="Additional metadata")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Response timestamp")
    
    @classmethod
    def success_response(
        cls, 
        data: T, 
        message: str = "Success",
        pagination: Optional[PaginationMeta] = None,
        meta: Optional[Dict[str, Any]] = None
    ) -> "APIResponse[T]":
        """Create a success response"""
        return cls(
            success=True,
            message=message,
            data=data,
            pagination=pagination,
            meta=meta
        )
    
    @classmethod
    def error_response(
        cls,
        message: str,
        error_code: str = "ERROR",
        meta: Optional[Dict[str, Any]] = None
    ) -> "APIResponse[None]":
        """Create an error response"""
        return cls(
            success=False,
            message=message,
            data=None,
            meta={
                "error_code": error_code,
                **(meta or {})
            }
        )

class AIError(BaseModel):
    """AI-friendly error response"""
    error: str = Field(description="Machine-readable error code")
    message: str = Field(description="Human-readable error message")
    ai_guidance: str = Field(description="Guidance for AI agents")
    recovery_action: str = Field(description="Recommended recovery action")
    details: Optional[Dict[str, Any]] = Field(default=None, description="Additional error details")
    request_id: str = Field(description="Unique request identifier")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
```

### User Models with Rich Metadata

```python
# app/models/user.py
from pydantic import BaseModel, Field, EmailStr, field_validator, computed_field
from typing import Optional, List, Literal
from datetime import datetime, date
from enum import Enum
import uuid
from app.models.common import BaseAPIModel, AIMetadata

class UserRole(str, Enum):
    ADMIN = "admin"
    USER = "user"
    MODERATOR = "moderator"

class UserStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING = "pending"

class UserCreateRequest(BaseAPIModel):
    """Request model for creating users with AI validation"""
    
    # Required fields
    username: str = Field(
        min_length=3,
        max_length=30,
        pattern=r'^[a-zA-Z0-9_]+$',
        description="Unique username (alphanumeric and underscore only)",
        example="johndoe"
    )
    email: EmailStr = Field(
        description="User's email address",
        example="john@example.com"
    )
    password: str = Field(
        min_length=8,
        description="User's password (minimum 8 characters)",
        example="securePassword123"
    )
    
    # Optional fields
    first_name: Optional[str] = Field(
        default=None,
        max_length=50,
        description="User's first name",
        example="John"
    )
    last_name: Optional[str] = Field(
        default=None,
        max_length=50,
        description="User's last name",
        example="Doe"
    )
    role: UserRole = Field(
        default=UserRole.USER,
        description="User's role in the system",
        example="user"
    )
    birth_date: Optional[date] = Field(
        default=None,
        description="User's birth date",
        example="1990-01-15"
    )
    
    # AI-specific metadata
    class Config:
        schema_extra = {
            "x-ai-metadata": {
                "validation_required": True,
                "unique_fields": ["username", "email"],
                "sensitive_fields": ["password"],
                "batch_capable": True,
                "max_batch_size": 100
            }
        }
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        """Validate username format and restrictions"""
        if v.lower() in ['admin', 'root', 'system', 'api']:
            raise ValueError('Username is reserved')
        return v.lower()
    
    @field_validator('birth_date')
    @classmethod
    def validate_birth_date(cls, v: Optional[date]) -> Optional[date]:
        """Validate birth date for reasonable age limits"""
        if v is None:
            return v
        
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        
        if age < 13:
            raise ValueError('User must be at least 13 years old')
        if age > 120:
            raise ValueError('Invalid birth date - age cannot exceed 120 years')
        
        return v

class UserUpdateRequest(BaseAPIModel):
    """Request model for updating users (partial updates)"""
    
    first_name: Optional[str] = Field(
        default=None,
        max_length=50,
        description="User's first name"
    )
    last_name: Optional[str] = Field(
        default=None,
        max_length=50,
        description="User's last name"
    )
    role: Optional[UserRole] = Field(
        default=None,
        description="User's role (admin only)"
    )
    status: Optional[UserStatus] = Field(
        default=None,
        description="User's account status (admin only)"
    )
    
    class Config:
        schema_extra = {
            "x-ai-metadata": {
                "partial_update": True,
                "authorization_required": {
                    "role": ["admin"],
                    "status": ["admin"]
                },
                "batch_capable": True
            }
        }

class UserResponse(BaseAPIModel):
    """Response model for user data with computed fields"""
    
    # Core fields
    id: uuid.UUID = Field(description="Unique user identifier")
    username: str = Field(description="User's username")
    email: str = Field(description="User's email address")
    role: UserRole = Field(description="User's role")
    status: UserStatus = Field(description="User's account status")
    
    # Personal information
    first_name: Optional[str] = Field(description="User's first name")
    last_name: Optional[str] = Field(description="User's last name")
    birth_date: Optional[date] = Field(description="User's birth date")
    
    # Timestamps
    created_at: datetime = Field(description="Account creation timestamp")
    updated_at: datetime = Field(description="Last update timestamp")
    last_login: Optional[datetime] = Field(description="Last login timestamp")
    
    # Computed fields
    @computed_field
    @property
    def full_name(self) -> Optional[str]:
        """User's full name"""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.first_name or self.last_name
    
    @computed_field
    @property
    def age(self) -> Optional[int]:
        """User's age calculated from birth date"""
        if not self.birth_date:
            return None
        
        today = date.today()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )
    
    @computed_field
    @property
    def profile_url(self) -> str:
        """User's profile URL"""
        return f"/users/{self.username}"
    
    @computed_field
    @property
    def is_active(self) -> bool:
        """Whether the user account is active"""
        return self.status == UserStatus.ACTIVE
    
    class Config:
        schema_extra = {
            "x-ai-metadata": {
                "cacheable": True,
                "cache_duration": "5m",
                "includes_computed_fields": True,
                "privacy_level": "public"
            }
        }

class UserQueryParams(BaseAPIModel):
    """Query parameters for user filtering and searching"""
    
    # Pagination
    page: int = Field(default=1, ge=1, description="Page number")
    limit: int = Field(default=20, ge=1, le=100, description="Items per page")
    
    # Filtering
    role: Optional[UserRole] = Field(default=None, description="Filter by role")
    status: Optional[UserStatus] = Field(default=None, description="Filter by status")
    search: Optional[str] = Field(
        default=None,
        max_length=100,
        description="Search in username, email, or name"
    )
    
    # Sorting
    sort_by: Literal["username", "email", "created_at", "last_login"] = Field(
        default="created_at",
        description="Field to sort by"
    )
    sort_order: Literal["asc", "desc"] = Field(
        default="desc",
        description="Sort order"
    )
    
    # Date filtering
    created_after: Optional[datetime] = Field(
        default=None,
        description="Filter users created after this date"
    )
    created_before: Optional[datetime] = Field(
        default=None,
        description="Filter users created before this date"
    )
    
    @computed_field
    @property
    def offset(self) -> int:
        """Calculate offset for database queries"""
        return (self.page - 1) * self.limit
    
    class Config:
        schema_extra = {
            "x-ai-metadata": {
                "filter_parameters": True,
                "supports_search": True,
                "sortable_fields": ["username", "email", "created_at", "last_login"],
                "date_range_filtering": True
            }
        }

class BatchUserCreateRequest(BaseAPIModel):
    """Request model for batch user creation"""
    
    users: List[UserCreateRequest] = Field(
        min_items=1,
        max_items=100,
        description="List of users to create (max 100)"
    )
    
    options: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Batch operation options"
    )
    
    class Config:
        schema_extra = {
            "x-ai-metadata": {
                "batch_operation": True,
                "max_batch_size": 100,
                "atomic_transaction": False,
                "partial_success_supported": True
            }
        }

class BatchOperationResult(BaseAPIModel):
    """Result model for batch operations"""
    
    total_requested: int = Field(description="Total items requested")
    successful: int = Field(description="Successfully processed items")
    failed: int = Field(description="Failed items")
    errors: List[Dict[str, Any]] = Field(description="Error details for failed items")
    
    @computed_field
    @property
    def success_rate(self) -> float:
        """Success rate as percentage"""
        if self.total_requested == 0:
            return 0.0
        return round((self.successful / self.total_requested) * 100, 2)
    
    class Config:
        schema_extra = {
            "x-ai-metadata": {
                "batch_result": True,
                "includes_error_details": True,
                "success_rate_computed": True
            }
        }
```

## 🛣️ Router Implementation with AI Optimization

### User Management Router

```python
# app/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status, Query, Background Tasks
from fastapi.security import HTTPBearer
from typing import List, Optional
from app.models.user import (
    UserCreateRequest, UserUpdateRequest, UserResponse, 
    UserQueryParams, BatchUserCreateRequest, BatchOperationResult
)
from app.models.common import APIResponse, PaginationMeta, AIError
from app.services.user_service import UserService
from app.dependencies import get_current_user, get_user_service
import uuid

router = APIRouter()
security = HTTPBearer()

@router.post(
    "/",
    response_model=APIResponse[UserResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new user",
    description="""
    Create a new user account with comprehensive validation.
    
    **AI Usage Guidelines:**
    - Validate username and email uniqueness before calling
    - Use batch endpoint for multiple users (more efficient)
    - Handle validation errors gracefully with retry logic
    - Check for 409 conflicts and adapt accordingly
    
    **Authentication Required:** Yes  
    **Rate Limit:** Standard user limits apply
    **MCP Tool Name:** `create_user`
    """,
    responses={
        201: {
            "description": "User created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "User created successfully",
                        "data": {
                            "id": "123e4567-e89b-12d3-a456-426614174000",
                            "username": "johndoe",
                            "email": "john@example.com",
                            "role": "user",
                            "status": "active",
                            "created_at": "2025-01-15T10:30:00Z"
                        }
                    }
                }
            }
        },
        409: {
            "description": "Username or email already exists",
            "model": AIError
        },
        422: {
            "description": "Validation error",
            "model": AIError
        }
    },
    tags=["Users"],
    operation_id="createUser"
)
async def create_user(
    user_data: UserCreateRequest,
    current_user: dict = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service)
):
    """Create a new user with AI-friendly error handling"""
    try:
        # Check permissions for role assignment
        if user_data.role != "user" and current_user["role"] != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error": "INSUFFICIENT_PERMISSIONS",
                    "message": "Only admins can assign non-user roles",
                    "ai_guidance": "Use role='user' or authenticate as admin",
                    "recovery_action": "retry_with_user_role",
                    "request_id": "req_123456"
                }
            )
        
        # Create user
        user = await user_service.create_user(user_data)
        
        return APIResponse.success_response(
            data=user,
            message="User created successfully",
            meta={
                "operation": "create_user",
                "created_by": current_user["id"]
            }
        )
        
    except ValueError as e:
        # Handle business logic errors
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error": "CONFLICT",
                "message": str(e),
                "ai_guidance": "Check if user already exists or use different values",
                "recovery_action": "check_existing_user_or_modify_data",
                "request_id": "req_123456"
            }
        )

@router.get(
    "/",
    response_model=APIResponse[List[UserResponse]],
    summary="List users with filtering and pagination",
    description="""
    Retrieve a paginated list of users with comprehensive filtering options.
    
    **AI Optimization Tips:**
    - Use limit=50 for optimal performance
    - Cache results for 5 minutes to reduce API calls
    - Combine filters for efficient data retrieval
    - Use search parameter for fuzzy matching
    
    **Performance Characteristics:**
    - Typical response time: 100-300ms
    - Cached responses: < 50ms
    - Maximum page size: 100 items
    
    **MCP Tool Name:** `list_users`
    """,
    responses={
        200: {
            "description": "Users retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Users retrieved successfully",
                        "data": [
                            {
                                "id": "123e4567-e89b-12d3-a456-426614174000",
                                "username": "johndoe",
                                "email": "john@example.com",
                                "role": "user",
                                "full_name": "John Doe"
                            }
                        ],
                        "pagination": {
                            "page": 1,
                            "limit": 20,
                            "total": 150,
                            "total_pages": 8,
                            "has_next": True
                        }
                    }
                }
            }
        }
    },
    tags=["Users"],
    operation_id="listUsers"
)
async def list_users(
    params: UserQueryParams = Depends(),
    current_user: dict = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service)
):
    """List users with AI-optimized pagination and filtering"""
    
    # Get users and total count
    users, total = await user_service.list_users(params)
    
    # Calculate pagination metadata
    total_pages = (total + params.limit - 1) // params.limit
    pagination = PaginationMeta(
        page=params.page,
        limit=params.limit,
        total=total,
        total_pages=total_pages,
        has_next=params.page < total_pages,
        has_previous=params.page > 1
    )
    
    return APIResponse.success_response(
        data=users,
        message=f"Retrieved {len(users)} users",
        pagination=pagination,
        meta={
            "operation": "list_users",
            "filters_applied": {
                "role": params.role,
                "status": params.status,
                "search": params.search
            },
            "performance": {
                "cache_hit": False,  # Would be determined by cache layer
                "query_time_ms": 150
            }
        }
    )

@router.get(
    "/{user_id}",
    response_model=APIResponse[UserResponse],
    summary="Get user by ID",
    description="""
    Retrieve a specific user by their unique identifier.
    
    **AI Usage:**
    - Cache user data for 5 minutes
    - Use username in URL for user-friendly access
    - Handle 404 errors gracefully
    
    **MCP Tool Name:** `get_user`
    """,
    responses={
        200: {"description": "User retrieved successfully"},
        404: {
            "description": "User not found",
            "model": AIError
        }
    },
    tags=["Users"],
    operation_id="getUser"
)
async def get_user(
    user_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service)
):
    """Get a specific user by ID"""
    
    user = await user_service.get_user(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "error": "NOT_FOUND",
                "message": "User not found",
                "ai_guidance": "Verify the user ID exists or search by username",
                "recovery_action": "search_by_username_or_list_users",
                "request_id": "req_123456"
            }
        )
    
    return APIResponse.success_response(
        data=user,
        message="User retrieved successfully",
        meta={
            "operation": "get_user",
            "user_id": str(user_id)
        }
    )

@router.patch(
    "/{user_id}",
    response_model=APIResponse[UserResponse],
    summary="Update user",
    description="""
    Update a user's information with partial data.
    
    **AI Guidelines:**
    - Only include fields that need updating
    - Check permissions for role/status changes
    - Handle conflicts gracefully
    
    **MCP Tool Name:** `update_user`
    """,
    tags=["Users"],
    operation_id="updateUser"
)
async def update_user(
    user_id: uuid.UUID,
    update_data: UserUpdateRequest,
    current_user: dict = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service)
):
    """Update user with partial data"""
    
    # Permission checks
    if update_data.role and current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "INSUFFICIENT_PERMISSIONS",
                "message": "Only admins can change user roles",
                "ai_guidance": "Remove role field or authenticate as admin",
                "recovery_action": "remove_role_field_or_get_admin_access",
                "request_id": "req_123456"
            }
        )
    
    # Only allow users to update their own profile (unless admin)
    if current_user["role"] != "admin" and str(user_id) != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "INSUFFICIENT_PERMISSIONS",
                "message": "Can only update your own profile",
                "ai_guidance": "Use current user's ID or authenticate as admin",
                "recovery_action": "use_current_user_id_or_get_admin_access",
                "request_id": "req_123456"
            }
        )
    
    user = await user_service.update_user(user_id, update_data)
    
    return APIResponse.success_response(
        data=user,
        message="User updated successfully",
        meta={
            "operation": "update_user",
            "updated_by": current_user["id"],
            "fields_updated": [
                field for field, value in update_data.model_dump(exclude_none=True).items()
            ]
        }
    )

@router.post(
    "/batch",
    response_model=APIResponse[BatchOperationResult],
    status_code=status.HTTP_207_MULTI_STATUS,
    summary="Create multiple users in batch",
    description="""
    Create multiple users efficiently in a single API call.
    
    **AI Benefits:**
    - Reduce API calls for bulk operations
    - Atomic transaction handling available
    - Partial success with detailed error reporting
    - Optimized for high-throughput scenarios
    
    **Limitations:**
    - Maximum 100 users per batch
    - Rate limits apply to total operation
    - Memory usage scales with batch size
    
    **MCP Tool Name:** `create_users_batch`
    """,
    responses={
        207: {
            "description": "Multi-status response with partial success",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Batch operation completed",
                        "data": {
                            "total_requested": 3,
                            "successful": 2,
                            "failed": 1,
                            "success_rate": 66.67,
                            "errors": [
                                {
                                    "index": 1,
                                    "error": "Username already exists",
                                    "username": "existing_user"
                                }
                            ]
                        }
                    }
                }
            }
        }
    },
    tags=["Users", "AI Operations"],
    operation_id="createUsersBatch"
)
async def create_users_batch(
    batch_request: BatchUserCreateRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service)
):
    """Create multiple users in batch for AI efficiency"""
    
    # Validate batch size
    if len(batch_request.users) > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "BATCH_TOO_LARGE",
                "message": "Maximum 100 users per batch",
                "ai_guidance": "Split large batches into smaller chunks of 100 or fewer",
                "recovery_action": "split_batch_into_smaller_chunks",
                "max_batch_size": 100,
                "request_id": "req_123456"
            }
        )
    
    # Process batch
    result = await user_service.create_users_batch(
        batch_request.users,
        options=batch_request.options
    )
    
    # Schedule background tasks if needed
    if len(batch_request.users) > 50:
        background_tasks.add_task(
            user_service.send_welcome_emails_batch,
            [user for user in result.successful_users]
        )
    
    return APIResponse.success_response(
        data=result,
        message=f"Batch operation completed: {result.successful}/{result.total_requested} successful",
        meta={
            "operation": "create_users_batch",
            "batch_size": len(batch_request.users),
            "processing_time_ms": result.processing_time_ms,
            "created_by": current_user["id"]
        }
    )

@router.delete(
    "/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete user",
    description="""
    Delete a user account (soft delete).
    
    **AI Guidelines:**
    - Soft delete preserves data integrity
    - Admin permissions required
    - Cannot delete self
    
    **MCP Tool Name:** `delete_user`
    """,
    tags=["Users"],
    operation_id="deleteUser"
)
async def delete_user(
    user_id: uuid.UUID,
    current_user: dict = Depends(get_current_user),
    user_service: UserService = Depends(get_user_service)
):
    """Delete user (soft delete)"""
    
    # Only admins can delete users
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error": "INSUFFICIENT_PERMISSIONS",
                "message": "Only admins can delete users",
                "ai_guidance": "Authenticate as admin to perform this operation",
                "recovery_action": "get_admin_authentication",
                "request_id": "req_123456"
            }
        )
    
    # Cannot delete self
    if str(user_id) == current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "INVALID_OPERATION",
                "message": "Cannot delete your own account",
                "ai_guidance": "Use a different admin account to delete this user",
                "recovery_action": "use_different_admin_account",
                "request_id": "req_123456"
            }
        )
    
    await user_service.delete_user(user_id)
    return None
```

## 📱 Interactive Documentation Customization

### Enhanced Swagger UI Configuration

```python
# app/main.py (additional configuration)
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.openapi.utils import get_openapi

@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=app.title + " - Interactive Documentation",
        oauth2_redirect_url=app.swagger_ui_oauth2_redirect_url,
        swagger_js_url="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js",
        swagger_css_url="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css",
        swagger_ui_parameters={
            "deepLinking": True,
            "displayRequestDuration": True,
            "docExpansion": "none",
            "operationsSorter": "method",
            "filter": True,
            "showExtensions": True,
            "showCommonExtensions": True,
            "tryItOutEnabled": True,
            "requestSnippetsEnabled": True,
            "supportedSubmitMethods": ["get", "post", "put", "delete", "patch"],
            "validatorUrl": None
        }
    )

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # Add AI-specific metadata
    openapi_schema["x-ai-metadata"] = {
        "mcp_compatible": True,
        "ai_agent_friendly": True,
        "batch_operations_available": True,
        "interactive_documentation": True,
        "rate_limits": {
            "standard_users": "100/minute",
            "premium_users": "1000/minute", 
            "ai_agents": "500/minute"
        },
        "authentication": {
            "type": "JWT Bearer",
            "refresh_endpoint": "/auth/refresh",
            "token_expiry": "1 hour"
        }
    }
    
    # Add custom examples for AI testing
    openapi_schema["x-code-samples"] = [
        {
            "lang": "Python",
            "source": """
import requests

# Authenticate
auth_response = requests.post('https://api.example.com/auth/login', json={
    'username': 'your_username',
    'password': 'your_password'
})
token = auth_response.json()['access_token']

# List users
users_response = requests.get(
    'https://api.example.com/users',
    headers={'Authorization': f'Bearer {token}'},
    params={'limit': 50, 'role': 'user'}
)
users = users_response.json()['data']
"""
        },
        {
            "lang": "JavaScript",
            "source": """
// Using fetch API
const token = 'your-jwt-token';

const response = await fetch('https://api.example.com/users', {
    headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
    }
});

const result = await response.json();
console.log(result.data); // Array of users
"""
        }
    ]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

---

*Next: [Machine-Readable Documentation](./machine-readable-documentation.md) - Learn how to optimize OpenAPI specs for AI consumption and automated processing*
# Pydantic v2 Web Applications and FastAPI Integration

## Overview

This guide covers modern patterns for building web applications with Pydantic v2 and FastAPI. Learn how to leverage v2's performance improvements, enhanced validation, and new features to create robust, high-performance APIs with excellent developer experience.

## 🚀 FastAPI + Pydantic v2 Setup

### 1. Project Setup

**Requirements and Installation**
```bash
# Core dependencies
pip install fastapi uvicorn pydantic

# Optional but recommended
pip install pydantic-settings python-multipart

# For validation extras
pip install pydantic[email]

# Development dependencies
pip install pytest httpx
```

**Project Structure**
```
app/
├── main.py              # FastAPI application
├── config.py            # Pydantic settings
├── models/
│   ├── __init__.py
│   ├── user.py          # User models
│   ├── product.py       # Product models
│   └── response.py      # Response models
├── routers/
│   ├── __init__.py
│   ├── users.py         # User endpoints
│   └── products.py      # Product endpoints
└── utils/
    ├── __init__.py
    └── validation.py    # Custom validators
```

### 2. FastAPI Application with Pydantic v2

```python
# main.py
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import ValidationError
from config import get_settings, Settings
import uvicorn

# Create FastAPI app with Pydantic v2 integration
app = FastAPI(
    title="Modern API with Pydantic v2",
    description="High-performance API using Pydantic v2 features",
    version="1.0.0",
    # OpenAPI 3.1.0 support (automatic with Pydantic v2)
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler for validation errors
@app.exception_handler(ValidationError)
async def validation_exception_handler(request, exc: ValidationError):
    return HTTPException(
        status_code=422,
        detail={
            "message": "Validation failed",
            "errors": exc.errors(),
            "input": exc.input
        }
    )

# Health check endpoint
@app.get("/health")
async def health_check(settings: Settings = Depends(get_settings)):
    return {
        "status": "healthy",
        "app_name": settings.app_name,
        "environment": settings.environment
    }

if __name__ == "__main__":
    settings = get_settings()
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )
```

## 📊 Request and Response Models

### 1. Modern Request Models

```python
# models/user.py
from pydantic import BaseModel, Field, EmailStr, field_validator, computed_field
from typing import Optional, List, Annotated
from datetime import datetime, date
from enum import Enum
import uuid

class UserRole(str, Enum):
    ADMIN = "admin"
    USER = "user"
    MODERATOR = "moderator"

class UserCreateRequest(BaseModel):
    """Request model for creating a new user"""
    
    # Required fields with validation
    email: EmailStr = Field(..., description="User's email address")
    username: Annotated[str, Field(
        min_length=3, 
        max_length=30,
        pattern=r'^[a-zA-Z0-9_]+$',
        description="Username (alphanumeric and underscore only)"
    )]
    
    # Personal information
    first_name: Annotated[str, Field(min_length=1, max_length=50)]
    last_name: Annotated[str, Field(min_length=1, max_length=50)]
    birth_date: Optional[date] = Field(None, description="Date of birth")
    
    # Optional fields
    role: UserRole = Field(default=UserRole.USER)
    tags: List[str] = Field(default_factory=list, max_items=10)
    bio: Optional[str] = Field(None, max_length=500)
    
    @field_validator('birth_date')
    @classmethod
    def validate_birth_date(cls, v: Optional[date]) -> Optional[date]:
        if v is None:
            return v
        
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        
        if age < 13:
            raise ValueError('User must be at least 13 years old')
        if age > 120:
            raise ValueError('Invalid birth date')
        
        return v
    
    @field_validator('tags')
    @classmethod
    def validate_tags(cls, v: List[str]) -> List[str]:
        # Remove duplicates and empty tags
        cleaned = list(set(tag.strip().lower() for tag in v if tag.strip()))
        return cleaned[:10]  # Limit to 10 tags

class UserUpdateRequest(BaseModel):
    """Request model for updating an existing user"""
    
    # All fields optional for partial updates
    first_name: Optional[str] = Field(None, min_length=1, max_length=50)
    last_name: Optional[str] = Field(None, min_length=1, max_length=50)
    bio: Optional[str] = Field(None, max_length=500)
    tags: Optional[List[str]] = Field(None, max_items=10)
    
    # Role updates might be restricted
    role: Optional[UserRole] = None
    
    @field_validator('tags')
    @classmethod
    def validate_tags(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is None:
            return v
        cleaned = list(set(tag.strip().lower() for tag in v if tag.strip()))
        return cleaned[:10]

class UserQueryParams(BaseModel):
    """Query parameters for user search/filtering"""
    
    # Pagination
    page: int = Field(default=1, ge=1, description="Page number")
    size: int = Field(default=20, ge=1, le=100, description="Page size")
    
    # Filtering
    role: Optional[UserRole] = None
    search: Optional[str] = Field(None, max_length=100, description="Search in name or email")
    tags: Optional[List[str]] = Field(None, description="Filter by tags")
    
    # Sorting
    sort_by: str = Field(default="created_at", pattern=r'^(created_at|username|email)$')
    sort_order: str = Field(default="desc", pattern=r'^(asc|desc)$')
    
    @computed_field
    @property
    def offset(self) -> int:
        """Calculate offset for database queries"""
        return (self.page - 1) * self.size
```

### 2. Response Models with Computed Fields

```python
# models/response.py
from pydantic import BaseModel, computed_field, Field
from typing import Optional, List, Dict, Any, Generic, TypeVar
from datetime import datetime
import uuid

T = TypeVar('T')

class PaginatedResponse(BaseModel, Generic[T]):
    """Generic paginated response model"""
    
    items: List[T]
    total: int = Field(..., description="Total number of items")
    page: int = Field(..., description="Current page number")
    size: int = Field(..., description="Items per page")
    
    @computed_field
    @property
    def total_pages(self) -> int:
        """Calculate total number of pages"""
        return (self.total + self.size - 1) // self.size
    
    @computed_field
    @property
    def has_next(self) -> bool:
        """Check if there's a next page"""
        return self.page < self.total_pages
    
    @computed_field
    @property
    def has_previous(self) -> bool:
        """Check if there's a previous page"""
        return self.page > 1

class UserResponse(BaseModel):
    """Response model for user data"""
    
    # Core fields
    id: uuid.UUID
    email: str
    username: str
    first_name: str
    last_name: str
    role: UserRole
    
    # Optional fields
    birth_date: Optional[date] = None
    bio: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    
    # Metadata
    created_at: datetime
    updated_at: datetime
    is_active: bool = True
    
    @computed_field
    @property
    def full_name(self) -> str:
        """Computed full name"""
        return f"{self.first_name} {self.last_name}"
    
    @computed_field
    @property
    def age(self) -> Optional[int]:
        """Computed age from birth date"""
        if not self.birth_date:
            return None
        
        today = date.today()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )
    
    @computed_field
    @property
    def profile_url(self) -> str:
        """Computed profile URL"""
        return f"/users/{self.username}"

class APIResponse(BaseModel, Generic[T]):
    """Standard API response wrapper"""
    
    success: bool = True
    message: str = "Success"
    data: Optional[T] = None
    errors: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    @classmethod
    def success_response(cls, data: T, message: str = "Success") -> "APIResponse[T]":
        """Create a success response"""
        return cls(success=True, message=message, data=data)
    
    @classmethod
    def error_response(cls, errors: List[str], message: str = "Error") -> "APIResponse[None]":
        """Create an error response"""
        return cls(success=False, message=message, errors=errors, data=None)
```

## 🛣️ Advanced Routing Patterns

### 1. User Management Router

```python
# routers/users.py
from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from models.user import UserCreateRequest, UserUpdateRequest, UserQueryParams
from models.response import UserResponse, PaginatedResponse, APIResponse
from utils.validation import validate_user_permissions
import uuid

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=APIResponse[UserResponse], status_code=status.HTTP_201_CREATED)
async def create_user(user_data: UserCreateRequest):
    """Create a new user with comprehensive validation"""
    
    try:
        # Simulate user creation logic
        new_user = UserResponse(
            id=uuid.uuid4(),
            email=user_data.email,
            username=user_data.username,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            role=user_data.role,
            birth_date=user_data.birth_date,
            bio=user_data.bio,
            tags=user_data.tags,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        
        return APIResponse.success_response(
            data=new_user,
            message="User created successfully"
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get("/", response_model=APIResponse[PaginatedResponse[UserResponse]])
async def list_users(params: UserQueryParams = Depends()):
    """List users with filtering, sorting, and pagination"""
    
    # Simulate database query with params
    total_users = 150  # From database count
    
    # Mock user data
    users = [
        UserResponse(
            id=uuid.uuid4(),
            email=f"user{i}@example.com",
            username=f"user{i}",
            first_name=f"User",
            last_name=f"{i}",
            role=UserRole.USER,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        for i in range(params.size)
    ]
    
    paginated_response = PaginatedResponse[UserResponse](
        items=users,
        total=total_users,
        page=params.page,
        size=params.size
    )
    
    return APIResponse.success_response(
        data=paginated_response,
        message=f"Retrieved {len(users)} users"
    )

@router.get("/{user_id}", response_model=APIResponse[UserResponse])
async def get_user(user_id: uuid.UUID):
    """Get a specific user by ID"""
    
    # Simulate database lookup
    user = UserResponse(
        id=user_id,
        email="john@example.com",
        username="john_doe",
        first_name="John",
        last_name="Doe",
        role=UserRole.USER,
        birth_date=date(1990, 5, 15),
        bio="Software developer",
        tags=["python", "fastapi"],
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    return APIResponse.success_response(
        data=user,
        message="User retrieved successfully"
    )

@router.patch("/{user_id}", response_model=APIResponse[UserResponse])
async def update_user(
    user_id: uuid.UUID,
    update_data: UserUpdateRequest,
    current_user: dict = Depends(validate_user_permissions)
):
    """Update user with partial data and permission checking"""
    
    # Only include fields that were actually provided
    update_dict = update_data.model_dump(exclude_none=True)
    
    if not update_dict:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields provided for update"
        )
    
    # Permission checking
    if "role" in update_dict and current_user["role"] != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can change user roles"
        )
    
    # Simulate database update
    updated_user = UserResponse(
        id=user_id,
        email="john@example.com",
        username="john_doe",
        first_name=update_dict.get("first_name", "John"),
        last_name=update_dict.get("last_name", "Doe"),
        role=update_dict.get("role", UserRole.USER),
        bio=update_dict.get("bio", "Updated bio"),
        tags=update_dict.get("tags", ["python", "fastapi"]),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    return APIResponse.success_response(
        data=updated_user,
        message="User updated successfully"
    )

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: uuid.UUID,
    current_user: dict = Depends(validate_user_permissions)
):
    """Delete a user (soft delete)"""
    
    # Permission check
    if current_user["role"] != UserRole.ADMIN and current_user["id"] != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Can only delete your own account or admin required"
        )
    
    # Simulate soft delete
    return None
```

### 2. File Upload with Validation

```python
# routers/files.py
from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from pydantic import BaseModel, field_validator, Field
from typing import List, Optional
import mimetypes
import uuid

router = APIRouter(prefix="/files", tags=["files"])

class FileUploadResponse(BaseModel):
    file_id: uuid.UUID
    filename: str
    content_type: str
    size_bytes: int
    url: str
    
    @computed_field
    @property
    def size_mb(self) -> float:
        """File size in megabytes"""
        return round(self.size_bytes / (1024 * 1024), 2)

class FileMetadata(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    tags: List[str] = Field(default_factory=list, max_items=10)
    is_public: bool = Field(default=False)
    
    @field_validator('tags')
    @classmethod
    def validate_tags(cls, v: List[str]) -> List[str]:
        return [tag.strip().lower() for tag in v if tag.strip()][:10]

@router.post("/upload", response_model=APIResponse[FileUploadResponse])
async def upload_file(
    file: UploadFile = File(...),
    metadata: str = Form(None)  # JSON string
):
    """Upload file with metadata validation"""
    
    # Validate file
    if not file.filename:
        raise HTTPException(400, "Filename is required")
    
    # Size limit (10MB)
    max_size = 10 * 1024 * 1024
    file_content = await file.read()
    if len(file_content) > max_size:
        raise HTTPException(400, f"File too large. Max size: {max_size/1024/1024}MB")
    
    # Content type validation
    allowed_types = {
        'image/jpeg', 'image/png', 'image/gif',
        'application/pdf', 'text/plain', 'text/csv'
    }
    if file.content_type not in allowed_types:
        raise HTTPException(400, f"File type not allowed: {file.content_type}")
    
    # Parse metadata if provided
    file_metadata = None
    if metadata:
        try:
            import json
            metadata_dict = json.loads(metadata)
            file_metadata = FileMetadata.model_validate(metadata_dict)
        except Exception as e:
            raise HTTPException(400, f"Invalid metadata: {e}")
    
    # Simulate file storage
    file_id = uuid.uuid4()
    response_data = FileUploadResponse(
        file_id=file_id,
        filename=file.filename,
        content_type=file.content_type,
        size_bytes=len(file_content),
        url=f"/files/{file_id}/download"
    )
    
    return APIResponse.success_response(
        data=response_data,
        message="File uploaded successfully"
    )

@router.post("/upload-multiple", response_model=APIResponse[List[FileUploadResponse]])
async def upload_multiple_files(
    files: List[UploadFile] = File(...),
    max_files: int = Query(5, ge=1, le=10)
):
    """Upload multiple files with batch validation"""
    
    if len(files) > max_files:
        raise HTTPException(400, f"Too many files. Maximum: {max_files}")
    
    results = []
    total_size = 0
    max_total_size = 50 * 1024 * 1024  # 50MB total
    
    for file in files:
        file_content = await file.read()
        total_size += len(file_content)
        
        if total_size > max_total_size:
            raise HTTPException(400, "Total file size exceeds limit")
        
        # Individual file validation
        if len(file_content) > 10 * 1024 * 1024:
            raise HTTPException(400, f"File {file.filename} too large")
        
        file_id = uuid.uuid4()
        results.append(FileUploadResponse(
            file_id=file_id,
            filename=file.filename,
            content_type=file.content_type,
            size_bytes=len(file_content),
            url=f"/files/{file_id}/download"
        ))
    
    return APIResponse.success_response(
        data=results,
        message=f"Uploaded {len(results)} files successfully"
    )
```

## 🔒 Authentication and Security Models

### 1. Authentication Models

```python
# models/auth.py
from pydantic import BaseModel, Field, EmailStr, field_validator, SecretStr
from typing import Optional, List
from datetime import datetime, timedelta
import re

class LoginRequest(BaseModel):
    """User login request"""
    
    email: EmailStr = Field(..., description="User email")
    password: SecretStr = Field(..., min_length=8, description="User password")
    remember_me: bool = Field(default=False)
    
class TokenResponse(BaseModel):
    """JWT token response"""
    
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Seconds until token expires")
    
    @computed_field
    @property
    def expires_at(self) -> datetime:
        """Token expiration timestamp"""
        return datetime.utcnow() + timedelta(seconds=self.expires_in)

class PasswordResetRequest(BaseModel):
    """Password reset request"""
    
    email: EmailStr = Field(..., description="User email")

class PasswordResetConfirm(BaseModel):
    """Password reset confirmation"""
    
    token: str = Field(..., min_length=1)
    new_password: SecretStr = Field(..., min_length=8)
    confirm_password: SecretStr = Field(..., min_length=8)
    
    @field_validator('new_password')
    @classmethod
    def validate_password_strength(cls, v: SecretStr) -> SecretStr:
        """Validate password complexity"""
        password = v.get_secret_value()
        
        if len(password) < 8:
            raise ValueError('Password must be at least 8 characters')
        
        # Check for uppercase, lowercase, digit, special char
        if not re.search(r'[A-Z]', password):
            raise ValueError('Password must contain uppercase letter')
        if not re.search(r'[a-z]', password):
            raise ValueError('Password must contain lowercase letter')
        if not re.search(r'\d', password):
            raise ValueError('Password must contain digit')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            raise ValueError('Password must contain special character')
        
        return v
    
    @model_validator(mode='after')
    def validate_passwords_match(self) -> 'PasswordResetConfirm':
        """Ensure passwords match"""
        if self.new_password.get_secret_value() != self.confirm_password.get_secret_value():
            raise ValueError('Passwords do not match')
        return self

class CurrentUser(BaseModel):
    """Current authenticated user"""
    
    id: uuid.UUID
    email: str
    username: str
    role: UserRole
    permissions: List[str]
    is_active: bool
    last_login: Optional[datetime] = None
    
    @computed_field
    @property
    def is_admin(self) -> bool:
        """Check if user is admin"""
        return self.role == UserRole.ADMIN
```

### 2. Authentication Router

```python
# routers/auth.py
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from models.auth import LoginRequest, TokenResponse, PasswordResetRequest, CurrentUser
from models.response import APIResponse
import jwt

router = APIRouter(prefix="/auth", tags=["authentication"])
security = HTTPBearer()

@router.post("/login", response_model=APIResponse[TokenResponse])
async def login(credentials: LoginRequest):
    """Authenticate user and return JWT tokens"""
    
    # Validate credentials (simulate database check)
    email = credentials.email
    password = credentials.password.get_secret_value()
    
    # Simulate user lookup and password verification
    if email != "user@example.com" or password != "password123":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    # Generate tokens (simulate JWT creation)
    access_token = "fake_access_token"
    refresh_token = "fake_refresh_token"
    expires_in = 3600 if not credentials.remember_me else 86400
    
    token_response = TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in
    )
    
    return APIResponse.success_response(
        data=token_response,
        message="Login successful"
    )

@router.post("/refresh", response_model=APIResponse[TokenResponse])
async def refresh_token(refresh_token: str):
    """Refresh access token using refresh token"""
    
    # Validate refresh token
    if refresh_token != "fake_refresh_token":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    # Generate new tokens
    new_token_response = TokenResponse(
        access_token="new_fake_access_token",
        refresh_token="new_fake_refresh_token",
        expires_in=3600
    )
    
    return APIResponse.success_response(
        data=new_token_response,
        message="Token refreshed successfully"
    )

@router.get("/me", response_model=APIResponse[CurrentUser])
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """Get current user information"""
    
    # Validate token and extract user info
    token = credentials.credentials
    
    if token != "fake_access_token":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    # Return user info
    current_user = CurrentUser(
        id=uuid.uuid4(),
        email="user@example.com",
        username="testuser",
        role=UserRole.USER,
        permissions=["read", "write"],
        is_active=True,
        last_login=datetime.utcnow()
    )
    
    return APIResponse.success_response(
        data=current_user,
        message="User information retrieved"
    )

@router.post("/password-reset", response_model=APIResponse[None])
async def request_password_reset(request: PasswordResetRequest):
    """Request password reset"""
    
    # Simulate sending reset email
    return APIResponse.success_response(
        data=None,
        message="Password reset email sent"
    )
```

## ⚡ Performance Optimization

### 1. Response Model Optimization

```python
# models/optimized.py
from pydantic import BaseModel, ConfigDict, Field, computed_field
from typing import List, Optional, Dict, Any
from functools import lru_cache

class OptimizedUserResponse(BaseModel):
    """Optimized user response with minimal overhead"""
    
    model_config = ConfigDict(
        # Performance optimizations
        validate_assignment=False,  # Skip validation on assignment
        use_enum_values=True,       # Use enum values directly
        extra='ignore',             # Ignore extra fields
        
        # JSON serialization optimization
        json_encoders={
            datetime: lambda v: v.isoformat(),
            date: lambda v: v.isoformat()
        }
    )
    
    id: uuid.UUID
    email: str
    username: str
    full_name: str  # Pre-computed instead of computed field
    role: str       # String instead of enum for faster serialization
    created_at: datetime
    
    @classmethod
    @lru_cache(maxsize=128)
    def get_cached_schema(cls):
        """Cache the JSON schema for reuse"""
        return cls.model_json_schema()

class BulkResponse(BaseModel):
    """Optimized response for bulk operations"""
    
    model_config = ConfigDict(
        # Minimize validation overhead
        validate_default=False,
        extra='ignore'
    )
    
    success_count: int
    error_count: int
    total_processed: int
    errors: Optional[List[str]] = None
    
    @computed_field
    @property
    def success_rate(self) -> float:
        """Success rate percentage"""
        if self.total_processed == 0:
            return 0.0
        return round((self.success_count / self.total_processed) * 100, 2)
```

### 2. Batch Processing Endpoints

```python
# routers/batch.py
from fastapi import APIRouter, HTTPException, BackgroundTasks
from typing import List
from models.user import UserCreateRequest
from models.optimized import BulkResponse
from models.response import APIResponse

router = APIRouter(prefix="/batch", tags=["batch-operations"])

@router.post("/users", response_model=APIResponse[BulkResponse])
async def create_users_batch(
    users: List[UserCreateRequest],
    background_tasks: BackgroundTasks
):
    """Create multiple users efficiently"""
    
    if len(users) > 100:
        raise HTTPException(400, "Maximum 100 users per batch")
    
    success_count = 0
    error_count = 0
    errors = []
    
    for i, user_data in enumerate(users):
        try:
            # Validate user data
            user_data.model_validate(user_data.model_dump())
            success_count += 1
        except Exception as e:
            error_count += 1
            errors.append(f"User {i}: {str(e)}")
    
    # Process in background for large batches
    if len(users) > 50:
        background_tasks.add_task(process_users_background, users)
    
    bulk_response = BulkResponse(
        success_count=success_count,
        error_count=error_count,
        total_processed=len(users),
        errors=errors if errors else None
    )
    
    return APIResponse.success_response(
        data=bulk_response,
        message=f"Processed {len(users)} users"
    )

async def process_users_background(users: List[UserCreateRequest]):
    """Background task for processing users"""
    # Implement actual user creation logic
    pass
```

## 🧪 Testing Patterns

### 1. Model Testing

```python
# tests/test_models.py
import pytest
from pydantic import ValidationError
from models.user import UserCreateRequest, UserUpdateRequest
from datetime import date

class TestUserModels:
    
    def test_user_create_valid_data(self):
        """Test user creation with valid data"""
        user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "first_name": "Test",
            "last_name": "User",
            "birth_date": "1990-01-01"
        }
        
        user = UserCreateRequest.model_validate(user_data)
        assert user.email == "test@example.com"
        assert user.username == "testuser"
        assert user.birth_date == date(1990, 1, 1)
    
    def test_user_create_invalid_email(self):
        """Test user creation with invalid email"""
        user_data = {
            "email": "invalid-email",
            "username": "testuser",
            "first_name": "Test",
            "last_name": "User"
        }
        
        with pytest.raises(ValidationError) as exc_info:
            UserCreateRequest.model_validate(user_data)
        
        errors = exc_info.value.errors()
        assert any(error['type'] == 'value_error' for error in errors)
    
    def test_user_create_age_validation(self):
        """Test age validation"""
        user_data = {
            "email": "test@example.com",
            "username": "testuser",
            "first_name": "Test",
            "last_name": "User",
            "birth_date": "2020-01-01"  # Too young
        }
        
        with pytest.raises(ValidationError) as exc_info:
            UserCreateRequest.model_validate(user_data)
        
        assert "at least 13 years old" in str(exc_info.value)
    
    def test_user_update_partial(self):
        """Test partial user updates"""
        update_data = {
            "first_name": "Updated",
            "bio": "New bio"
        }
        
        update = UserUpdateRequest.model_validate(update_data)
        assert update.first_name == "Updated"
        assert update.bio == "New bio"
        assert update.last_name is None  # Not provided
```

### 2. API Testing

```python
# tests/test_api.py
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

class TestUserAPI:
    
    def test_create_user_success(self):
        """Test successful user creation"""
        user_data = {
            "email": "newuser@example.com",
            "username": "newuser",
            "first_name": "New",
            "last_name": "User"
        }
        
        response = client.post("/users/", json=user_data)
        assert response.status_code == 201
        
        data = response.json()
        assert data["success"] is True
        assert data["data"]["email"] == user_data["email"]
    
    def test_create_user_validation_error(self):
        """Test user creation with validation errors"""
        user_data = {
            "email": "invalid-email",
            "username": "a",  # Too short
            "first_name": "",  # Empty
            "last_name": "User"
        }
        
        response = client.post("/users/", json=user_data)
        assert response.status_code == 422
        
        data = response.json()
        assert "errors" in data["detail"]
    
    def test_list_users_pagination(self):
        """Test user listing with pagination"""
        response = client.get("/users/?page=1&size=10")
        assert response.status_code == 200
        
        data = response.json()
        assert data["success"] is True
        assert "total_pages" in data["data"]
        assert "has_next" in data["data"]
    
    def test_get_user_not_found(self):
        """Test getting non-existent user"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        response = client.get(f"/users/{fake_id}")
        assert response.status_code == 404
```

## 🔍 Error Handling and Validation

### 1. Custom Exception Handlers

```python
# utils/exceptions.py
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import ValidationError
from typing import List, Dict, Any

class BusinessLogicError(Exception):
    """Custom exception for business logic errors"""
    def __init__(self, message: str, error_code: str = "BUSINESS_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(self.message)

async def business_logic_exception_handler(request: Request, exc: BusinessLogicError):
    """Handle business logic exceptions"""
    return JSONResponse(
        status_code=400,
        content={
            "success": False,
            "message": exc.message,
            "error_code": exc.error_code,
            "errors": [exc.message]
        }
    )

async def validation_exception_handler(request: Request, exc: ValidationError):
    """Enhanced validation error handler"""
    formatted_errors = []
    
    for error in exc.errors():
        field_name = " -> ".join(str(loc) for loc in error["loc"])
        formatted_errors.append({
            "field": field_name,
            "message": error["msg"],
            "type": error["type"],
            "input": error.get("input")
        })
    
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "message": "Validation failed",
            "errors": formatted_errors,
            "error_count": len(formatted_errors)
        }
    )

# Register handlers in main.py
app.add_exception_handler(BusinessLogicError, business_logic_exception_handler)
app.add_exception_handler(ValidationError, validation_exception_handler)
```

### 2. Request Validation Middleware

```python
# middleware/validation.py
from fastapi import Request, HTTPException
from typing import Callable
import time

async def request_validation_middleware(request: Request, call_next: Callable):
    """Middleware for request validation and timing"""
    
    start_time = time.time()
    
    # Check request size
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > 10 * 1024 * 1024:  # 10MB
        raise HTTPException(413, "Request too large")
    
    # Check content type for POST/PUT requests
    if request.method in ["POST", "PUT", "PATCH"]:
        content_type = request.headers.get("content-type", "")
        if not content_type.startswith(("application/json", "multipart/form-data")):
            raise HTTPException(415, "Unsupported media type")
    
    try:
        response = await call_next(request)
        
        # Add timing header
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        
        return response
        
    except Exception as e:
        # Log the error
        print(f"Request error: {e}")
        raise

# Register middleware in main.py
app.middleware("http")(request_validation_middleware)
```

---

*Next: [Production Patterns](./pydantic-v2-production-patterns.md) - Performance optimization, monitoring, and deployment best practices*
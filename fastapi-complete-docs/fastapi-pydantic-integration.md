# FastAPI Pydantic Integration and Validation

## Overview
This guide covers advanced Pydantic integration with FastAPI, including custom validators, serialization patterns, error handling, and performance optimization for robust API data validation and serialization.

## Advanced Pydantic Models

### Custom Validators and Serializers
```python
from fastapi import FastAPI, HTTPException, Query, Body
from pydantic import BaseModel, Field, validator, root_validator, EmailStr
from pydantic.types import constr, conint, confloat
from typing import List, Dict, Optional, Union, Any, Literal
from datetime import datetime, date
from enum import Enum
import re
from decimal import Decimal

app = FastAPI()

# Enums for validation
class UserRole(str, Enum):
    ADMIN = "admin"
    MODERATOR = "moderator"
    USER = "user"
    GUEST = "guest"

class Priority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class Status(str, Enum):
    DRAFT = "draft"
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    ARCHIVED = "archived"

# Advanced User model with comprehensive validation
class UserCreate(BaseModel):
    """User creation model with advanced validation."""
    
    username: constr(min_length=3, max_length=20, regex=r'^[a-zA-Z0-9_]+$') = Field(
        ..., 
        description="Username must be 3-20 characters, alphanumeric and underscores only"
    )
    
    email: EmailStr = Field(..., description="Valid email address")
    
    password: constr(min_length=8, max_length=128) = Field(
        ..., 
        description="Password must be 8-128 characters"
    )
    
    confirm_password: str = Field(..., description="Password confirmation")
    
    full_name: constr(min_length=2, max_length=100) = Field(
        ..., 
        description="Full name 2-100 characters"
    )
    
    age: conint(ge=13, le=120) = Field(..., description="Age must be between 13 and 120")
    
    phone: Optional[constr(regex=r'^\+?1?\d{9,15}$')] = Field(
        None, 
        description="Valid phone number"
    )
    
    website: Optional[str] = Field(None, max_length=200, description="Personal website URL")
    
    bio: Optional[constr(max_length=500)] = Field(
        None, 
        description="Biography up to 500 characters"
    )
    
    role: UserRole = Field(default=UserRole.USER, description="User role")
    
    tags: List[constr(min_length=1, max_length=20)] = Field(
        default_factory=list,
        max_items=10,
        description="User tags, max 10 items"
    )
    
    settings: Dict[str, Union[str, int, bool]] = Field(
        default_factory=dict,
        description="User settings"
    )
    
    birth_date: Optional[date] = Field(None, description="Birth date")
    
    salary: Optional[confloat(ge=0, le=1000000)] = Field(
        None, 
        description="Salary if applicable"
    )
    
    class Config:
        """Pydantic configuration."""
        schema_extra = {
            "example": {
                "username": "johndoe",
                "email": "john.doe@example.com",
                "password": "SecurePass123!",
                "confirm_password": "SecurePass123!",
                "full_name": "John Doe",
                "age": 30,
                "phone": "+1234567890",
                "website": "https://johndoe.com",
                "bio": "Software developer with 10 years experience",
                "role": "user",
                "tags": ["developer", "python", "fastapi"],
                "settings": {"theme": "dark", "notifications": True},
                "birth_date": "1993-01-15"
            }
        }
    
    @validator('username')
    def validate_username(cls, v):
        """Custom username validation."""
        # Check for reserved usernames
        reserved = ['admin', 'root', 'system', 'api', 'www', 'mail']
        if v.lower() in reserved:
            raise ValueError('Username is reserved')
        
        # Check for consecutive underscores
        if '__' in v:
            raise ValueError('Username cannot contain consecutive underscores')
        
        # Cannot start or end with underscore
        if v.startswith('_') or v.endswith('_'):
            raise ValueError('Username cannot start or end with underscore')
        
        return v
    
    @validator('email')
    def validate_email_domain(cls, v):
        """Validate email domain."""
        # Example: only allow certain domains
        allowed_domains = ['example.com', 'company.com', 'gmail.com', 'outlook.com']
        domain = v.split('@')[1].lower()
        
        # This is just an example - remove in production for open registration
        # if domain not in allowed_domains:
        #     raise ValueError(f'Email domain must be one of: {", ".join(allowed_domains)}')
        
        return v.lower()
    
    @validator('password')
    def validate_password_strength(cls, v):
        """Validate password strength."""
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain at least one special character')
        
        # Check for common weak passwords
        weak_passwords = ['password', '12345678', 'qwerty', 'admin123']
        if v.lower() in weak_passwords:
            raise ValueError('Password is too common')
        
        return v
    
    @validator('full_name')
    def validate_full_name(cls, v):
        """Validate full name format."""
        # Remove extra spaces and title case
        v = ' '.join(v.split()).title()
        
        # Check for valid characters (letters, spaces, hyphens, apostrophes)
        if not re.match(r"^[a-zA-Z\s\-']+$", v):
            raise ValueError('Full name can only contain letters, spaces, hyphens, and apostrophes')
        
        # Must contain at least one space (first and last name)
        if ' ' not in v:
            raise ValueError('Full name must include both first and last name')
        
        return v
    
    @validator('website')
    def validate_website_url(cls, v):
        """Validate website URL."""
        if v is None:
            return v
        
        # Add protocol if missing
        if not v.startswith(('http://', 'https://')):
            v = f'https://{v}'
        
        # Validate URL format
        url_pattern = re.compile(
            r'^https?://'  # http:// or https://
            r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain
            r'localhost|'  # localhost
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # IP
            r'(?::\d+)?'  # optional port
            r'(?:/?|[/?]\S+)$', re.IGNORECASE)
        
        if not url_pattern.match(v):
            raise ValueError('Invalid website URL format')
        
        return v
    
    @validator('bio')
    def validate_bio_content(cls, v):
        """Validate and sanitize bio content."""
        if v is None:
            return v
        
        # Remove HTML tags
        v = re.sub(r'<[^>]+>', '', v)
        
        # Remove excessive whitespace
        v = ' '.join(v.split())
        
        # Check for inappropriate content (basic example)
        inappropriate_words = ['spam', 'promotion', 'buy now']
        v_lower = v.lower()
        for word in inappropriate_words:
            if word in v_lower:
                raise ValueError(f'Bio contains inappropriate content: {word}')
        
        return v
    
    @validator('tags', each_item=True)
    def validate_tag_format(cls, v):
        """Validate each tag."""
        # Convert to lowercase and remove spaces
        v = v.lower().strip()
        
        # Check for valid characters
        if not re.match(r'^[a-z0-9\-]+$', v):
            raise ValueError('Tags can only contain lowercase letters, numbers, and hyphens')
        
        return v
    
    @validator('tags')
    def validate_tags_uniqueness(cls, v):
        """Ensure tags are unique."""
        if len(v) != len(set(v)):
            raise ValueError('Tags must be unique')
        return v
    
    @validator('birth_date')
    def validate_birth_date(cls, v, values):
        """Validate birth date consistency with age."""
        if v is None:
            return v
        
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        
        # Check if birth date matches provided age
        provided_age = values.get('age')
        if provided_age and abs(age - provided_age) > 1:
            raise ValueError('Birth date does not match provided age')
        
        # Cannot be in the future
        if v > today:
            raise ValueError('Birth date cannot be in the future')
        
        return v
    
    @root_validator
    def validate_password_confirmation(cls, values):
        """Validate password confirmation matches."""
        password = values.get('password')
        confirm_password = values.get('confirm_password')
        
        if password and confirm_password and password != confirm_password:
            raise ValueError('Password confirmation does not match')
        
        return values
    
    @root_validator
    def validate_admin_requirements(cls, values):
        """Validate admin role requirements."""
        role = values.get('role')
        age = values.get('age')
        
        if role == UserRole.ADMIN:
            if age and age < 21:
                raise ValueError('Admin users must be at least 21 years old')
        
        return values

# Response models with custom serialization
class UserResponse(BaseModel):
    """User response model with custom serialization."""
    
    id: int
    username: str
    email: EmailStr
    full_name: str
    age: int
    phone: Optional[str] = None
    website: Optional[str] = None
    bio: Optional[str] = None
    role: UserRole
    tags: List[str] = []
    is_active: bool = True
    created_at: datetime
    updated_at: datetime
    last_login: Optional[datetime] = None
    profile_views: int = 0
    
    class Config:
        """Pydantic configuration for response."""
        from_attributes = True  # Enable ORM mode
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None
        }
        schema_extra = {
            "example": {
                "id": 1,
                "username": "johndoe",
                "email": "john.doe@example.com",
                "full_name": "John Doe",
                "age": 30,
                "role": "user",
                "tags": ["developer", "python"],
                "is_active": True,
                "created_at": "2023-01-15T10:30:00",
                "profile_views": 42
            }
        }
    
    @validator('email', pre=False)
    def mask_email_for_privacy(cls, v):
        """Mask email for privacy in public responses."""
        # This is optional - you might want full email in some contexts
        local, domain = v.split('@')
        if len(local) > 2:
            masked_local = local[0] + '*' * (len(local) - 2) + local[-1]
        else:
            masked_local = '*' * len(local)
        return f"{masked_local}@{domain}"

# Complex nested models
class Address(BaseModel):
    """Address model with validation."""
    
    street: constr(min_length=5, max_length=100) = Field(..., description="Street address")
    city: constr(min_length=2, max_length=50) = Field(..., description="City name")
    state: constr(min_length=2, max_length=50) = Field(..., description="State/Province")
    postal_code: constr(regex=r'^\d{5}(-\d{4})?$') = Field(..., description="Postal/ZIP code")
    country: constr(min_length=2, max_length=2) = Field(..., description="Country code (ISO 3166-1 alpha-2)")
    
    @validator('country')
    def validate_country_code(cls, v):
        """Validate country code."""
        # ISO 3166-1 alpha-2 codes (sample)
        valid_countries = ['US', 'CA', 'GB', 'AU', 'DE', 'FR', 'JP', 'CN', 'IN', 'BR']
        if v.upper() not in valid_countries:
            raise ValueError(f'Invalid country code. Valid codes: {", ".join(valid_countries)}')
        return v.upper()

class ContactInfo(BaseModel):
    """Contact information model."""
    
    primary_phone: constr(regex=r'^\+?1?\d{9,15}$') = Field(..., description="Primary phone number")
    secondary_phone: Optional[constr(regex=r'^\+?1?\d{9,15}$')] = Field(None, description="Secondary phone")
    emergency_contact: constr(min_length=5, max_length=100) = Field(..., description="Emergency contact name")
    emergency_phone: constr(regex=r'^\+?1?\d{9,15}$') = Field(..., description="Emergency contact phone")

class UserProfile(BaseModel):
    """Complete user profile with nested models."""
    
    user: UserResponse
    address: Optional[Address] = None
    contact_info: Optional[ContactInfo] = None
    preferences: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Union[str, int, float, bool]] = Field(default_factory=dict)
    
    class Config:
        schema_extra = {
            "example": {
                "user": {
                    "id": 1,
                    "username": "johndoe",
                    "email": "john.doe@example.com",
                    "full_name": "John Doe",
                    "age": 30,
                    "role": "user"
                },
                "address": {
                    "street": "123 Main Street",
                    "city": "Anytown",
                    "state": "CA",
                    "postal_code": "12345",
                    "country": "US"
                },
                "preferences": {
                    "theme": "dark",
                    "language": "en",
                    "notifications": True
                }
            }
        }
```

### Dynamic Model Creation and Validation
```python
from pydantic import create_model
from typing import Type, get_args, get_origin
import inspect

class DynamicModelFactory:
    """Factory for creating dynamic Pydantic models."""
    
    @staticmethod
    def create_partial_model(base_model: Type[BaseModel], fields: List[str]) -> Type[BaseModel]:
        """Create a model with only specified fields from base model."""
        base_fields = base_model.__fields__
        
        # Extract only requested fields
        new_fields = {}
        for field_name in fields:
            if field_name in base_fields:
                field = base_fields[field_name]
                new_fields[field_name] = (field.type_, field.field_info)
        
        return create_model(
            f'Partial{base_model.__name__}',
            **new_fields
        )
    
    @staticmethod
    def create_update_model(base_model: Type[BaseModel]) -> Type[BaseModel]:
        """Create an update model where all fields are optional."""
        base_fields = base_model.__fields__
        
        # Make all fields optional
        new_fields = {}
        for field_name, field in base_fields.items():
            # Skip fields that shouldn't be updatable
            if field_name in ['id', 'created_at']:
                continue
            
            # Make field optional
            field_type = field.type_
            if get_origin(field_type) is not Union or type(None) not in get_args(field_type):
                field_type = Optional[field_type]
            
            new_fields[field_name] = (field_type, Field(None, **field.field_info.extra))
        
        return create_model(
            f'Update{base_model.__name__}',
            **new_fields
        )
    
    @staticmethod
    def create_search_model(base_model: Type[BaseModel]) -> Type[BaseModel]:
        """Create a search model with string fields for filtering."""
        base_fields = base_model.__fields__
        
        # Create search fields
        search_fields = {}
        for field_name, field in base_fields.items():
            # Add exact match field
            search_fields[field_name] = (Optional[str], Field(None, description=f"Exact match for {field_name}"))
            
            # Add pattern matching for string fields
            if field.type_ == str:
                search_fields[f'{field_name}_contains'] = (Optional[str], Field(None, description=f"Contains substring in {field_name}"))
                search_fields[f'{field_name}_starts_with'] = (Optional[str], Field(None, description=f"Starts with in {field_name}"))
        
        # Add common search fields
        search_fields.update({
            'limit': (Optional[int], Field(10, ge=1, le=100, description="Number of results to return")),
            'offset': (Optional[int], Field(0, ge=0, description="Number of results to skip")),
            'sort_by': (Optional[str], Field(None, description="Field to sort by")),
            'sort_order': (Optional[Literal['asc', 'desc']], Field('asc', description="Sort order"))
        })
        
        return create_model(
            f'Search{base_model.__name__}',
            **search_fields
        )

# Example usage of dynamic models
UserUpdate = DynamicModelFactory.create_update_model(UserCreate)
UserSearch = DynamicModelFactory.create_search_model(UserResponse)
UserPartial = DynamicModelFactory.create_partial_model(UserResponse, ['id', 'username', 'email', 'role'])

# Conditional validation based on role
class ConditionalUserModel(BaseModel):
    """User model with conditional validation based on role."""
    
    username: str
    email: EmailStr
    role: UserRole
    department: Optional[str] = None
    employee_id: Optional[str] = None
    security_clearance: Optional[str] = None
    manager_id: Optional[int] = None
    
    @root_validator
    def validate_role_requirements(cls, values):
        """Validate requirements based on user role."""
        role = values.get('role')
        
        if role == UserRole.ADMIN:
            # Admin requirements
            if not values.get('security_clearance'):
                raise ValueError('Admin users must have security clearance')
            if not values.get('employee_id'):
                raise ValueError('Admin users must have employee ID')
        
        elif role == UserRole.MODERATOR:
            # Moderator requirements
            if not values.get('department'):
                raise ValueError('Moderators must specify department')
            if not values.get('manager_id'):
                raise ValueError('Moderators must have assigned manager')
        
        elif role == UserRole.USER:
            # Regular user requirements
            if values.get('security_clearance'):
                raise ValueError('Regular users cannot have security clearance')
        
        return values

# Polymorphic models using discriminated unions
class NotificationBase(BaseModel):
    """Base notification model."""
    id: int
    user_id: int
    created_at: datetime
    read: bool = False

class EmailNotification(NotificationBase):
    """Email notification model."""
    type: Literal['email'] = 'email'
    subject: str
    body: str
    sender_email: EmailStr

class SMSNotification(NotificationBase):
    """SMS notification model."""
    type: Literal['sms'] = 'sms'
    message: constr(max_length=160)
    sender_phone: str

class PushNotification(NotificationBase):
    """Push notification model."""
    type: Literal['push'] = 'push'
    title: str
    body: str
    action_url: Optional[str] = None

# Discriminated union for polymorphic notifications
Notification = Union[EmailNotification, SMSNotification, PushNotification]

class NotificationList(BaseModel):
    """List of notifications with polymorphic types."""
    notifications: List[Notification] = Field(..., discriminator='type')
    total: int
    unread_count: int
```

### Advanced Validation Patterns
```python
from functools import wraps
from typing import Callable, Any
import asyncio

# Custom validator decorators
def async_validator(func: Callable) -> Callable:
    """Decorator for async validators."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        return asyncio.create_task(func(*args, **kwargs))
    return wrapper

class DatabaseValidator:
    """Validators that check against database."""
    
    @staticmethod
    async def unique_username(username: str) -> str:
        """Validate username uniqueness."""
        # Simulate database check
        await asyncio.sleep(0.01)
        
        existing_usernames = ['admin', 'test', 'user123']  # Mock existing usernames
        if username.lower() in existing_usernames:
            raise ValueError('Username already exists')
        return username
    
    @staticmethod
    async def unique_email(email: str) -> str:
        """Validate email uniqueness."""
        # Simulate database check
        await asyncio.sleep(0.01)
        
        existing_emails = ['admin@example.com', 'test@example.com']  # Mock existing emails
        if email.lower() in existing_emails:
            raise ValueError('Email already registered')
        return email

# Business logic validators
class BusinessValidator:
    """Business logic validation."""
    
    @staticmethod
    def validate_project_dates(start_date: date, end_date: date) -> tuple[date, date]:
        """Validate project date logic."""
        if start_date >= end_date:
            raise ValueError('End date must be after start date')
        
        # Cannot start in the past (except for today)
        if start_date < date.today():
            raise ValueError('Start date cannot be in the past')
        
        # Project cannot be longer than 2 years
        max_duration = timedelta(days=730)
        if end_date - start_date > max_duration:
            raise ValueError('Project duration cannot exceed 2 years')
        
        return start_date, end_date
    
    @staticmethod
    def validate_budget_allocation(total_budget: float, allocations: Dict[str, float]) -> Dict[str, float]:
        """Validate budget allocation adds up correctly."""
        allocation_sum = sum(allocations.values())
        
        if abs(allocation_sum - total_budget) > 0.01:  # Allow for floating point precision
            raise ValueError(f'Budget allocations ({allocation_sum}) do not match total budget ({total_budget})')
        
        # Check for negative allocations
        for category, amount in allocations.items():
            if amount < 0:
                raise ValueError(f'Budget allocation for {category} cannot be negative')
        
        return allocations

# Complex business model with multiple validations
class ProjectModel(BaseModel):
    """Project model with complex business validation."""
    
    name: constr(min_length=3, max_length=100) = Field(..., description="Project name")
    description: constr(min_length=10, max_length=1000) = Field(..., description="Project description")
    start_date: date = Field(..., description="Project start date")
    end_date: date = Field(..., description="Project end date")
    total_budget: confloat(gt=0, le=10000000) = Field(..., description="Total project budget")
    budget_allocations: Dict[str, confloat(ge=0)] = Field(..., description="Budget allocations by category")
    priority: Priority = Field(..., description="Project priority")
    status: Status = Field(default=Status.DRAFT, description="Project status")
    team_size: conint(ge=1, le=50) = Field(..., description="Team size")
    required_skills: List[constr(min_length=2, max_length=30)] = Field(..., min_items=1, max_items=20)
    
    @validator('name')
    def validate_project_name(cls, v):
        """Validate project name."""
        # Cannot be all numbers
        if v.isdigit():
            raise ValueError('Project name cannot be all numbers')
        
        # Check for inappropriate words
        inappropriate = ['test', 'temp', 'delete', 'remove']
        if any(word in v.lower() for word in inappropriate):
            raise ValueError('Project name contains inappropriate words')
        
        return v.title()
    
    @validator('required_skills', each_item=True)
    def validate_skill_format(cls, v):
        """Validate skill format."""
        # Convert to title case and remove extra spaces
        v = ' '.join(v.split()).title()
        
        # Must contain only letters, spaces, and common programming chars
        if not re.match(r'^[a-zA-Z0-9\s\+\#\.\-]+$', v):
            raise ValueError('Skill contains invalid characters')
        
        return v
    
    @root_validator
    def validate_project_logic(cls, values):
        """Validate project business logic."""
        start_date = values.get('start_date')
        end_date = values.get('end_date')
        total_budget = values.get('total_budget')
        budget_allocations = values.get('budget_allocations')
        priority = values.get('priority')
        team_size = values.get('team_size')
        
        # Validate dates
        if start_date and end_date:
            try:
                BusinessValidator.validate_project_dates(start_date, end_date)
            except ValueError as e:
                raise ValueError(f"Date validation failed: {str(e)}")
        
        # Validate budget
        if total_budget and budget_allocations:
            try:
                BusinessValidator.validate_budget_allocation(total_budget, budget_allocations)
            except ValueError as e:
                raise ValueError(f"Budget validation failed: {str(e)}")
        
        # Business rules based on priority
        if priority == Priority.CRITICAL:
            if team_size and team_size < 3:
                raise ValueError('Critical projects must have at least 3 team members')
            
            # Critical projects need larger budget
            if total_budget and total_budget < 50000:
                raise ValueError('Critical projects must have budget of at least $50,000')
        
        # High priority projects constraints
        if priority == Priority.HIGH:
            duration = (end_date - start_date).days if start_date and end_date else 0
            if duration > 180:  # 6 months
                raise ValueError('High priority projects should not exceed 6 months duration')
        
        return values

# Model with custom JSON serialization
class CustomSerializationModel(BaseModel):
    """Model with custom JSON serialization."""
    
    id: int
    name: str
    amount: Decimal
    tags: List[str]
    metadata: Dict[str, Any]
    created_at: datetime
    
    class Config:
        json_encoders = {
            Decimal: lambda v: float(v),
            datetime: lambda v: v.isoformat(),
            set: lambda v: list(v)
        }
    
    def dict(self, **kwargs) -> Dict[str, Any]:
        """Custom dict conversion."""
        data = super().dict(**kwargs)
        
        # Add computed fields
        data['display_name'] = f"{self.name} (#{self.id})"
        data['tag_count'] = len(self.tags)
        data['has_metadata'] = bool(self.metadata)
        
        return data
    
    def json(self, **kwargs) -> str:
        """Custom JSON serialization."""
        # Add custom fields before serialization
        data = self.dict(**kwargs)
        data['serialized_at'] = datetime.now().isoformat()
        
        import json
        return json.dumps(data, default=str, **kwargs)
```

## Error Handling and Custom Responses

### Comprehensive Error Models
```python
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError
from typing import List, Dict, Any

class ValidationErrorDetail(BaseModel):
    """Detailed validation error information."""
    field: str
    message: str
    invalid_value: Any
    error_type: str

class ValidationErrorResponse(BaseModel):
    """Structured validation error response."""
    error: str = "Validation Error"
    message: str
    details: List[ValidationErrorDetail]
    timestamp: datetime = Field(default_factory=datetime.now)
    request_id: Optional[str] = None
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class BusinessErrorResponse(BaseModel):
    """Business logic error response."""
    error: str = "Business Logic Error"
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime = Field(default_factory=datetime.now)
    suggestion: Optional[str] = None

def format_validation_error(exc: RequestValidationError) -> ValidationErrorResponse:
    """Format Pydantic validation errors into structured response."""
    details = []
    
    for error in exc.errors():
        field_path = ' -> '.join(str(x) for x in error['loc'][1:])  # Skip 'body'
        
        details.append(ValidationErrorDetail(
            field=field_path,
            message=error['msg'],
            invalid_value=error.get('input', 'N/A'),
            error_type=error['type']
        ))
    
    return ValidationErrorResponse(
        message=f"Validation failed for {len(details)} field(s)",
        details=details
    )

# Custom exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc: RequestValidationError):
    """Handle Pydantic validation errors."""
    error_response = format_validation_error(exc)
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=error_response.dict()
    )

@app.exception_handler(ValueError)
async def value_error_handler(request, exc: ValueError):
    """Handle business logic value errors."""
    error_response = BusinessErrorResponse(
        code="BUSINESS_LOGIC_ERROR",
        message=str(exc),
        suggestion="Please check your input values and try again"
    )
    
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content=error_response.dict()
    )

# Custom validation with detailed error reporting
class DetailedValidationModel(BaseModel):
    """Model that provides detailed validation feedback."""
    
    email: EmailStr
    password: str
    age: int
    
    @validator('password')
    def validate_password_with_details(cls, v):
        """Validate password with detailed error messages."""
        errors = []
        
        if len(v) < 8:
            errors.append("Password must be at least 8 characters long")
        
        if not re.search(r'[A-Z]', v):
            errors.append("Password must contain at least one uppercase letter")
        
        if not re.search(r'[a-z]', v):
            errors.append("Password must contain at least one lowercase letter")
        
        if not re.search(r'\d', v):
            errors.append("Password must contain at least one digit")
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            errors.append("Password must contain at least one special character")
        
        if errors:
            error_msg = "Password validation failed: " + "; ".join(errors)
            raise ValueError(error_msg)
        
        return v
    
    @validator('age')
    def validate_age_with_context(cls, v, values):
        """Validate age with contextual information."""
        if v < 13:
            raise ValueError("Age must be at least 13 years old for account creation")
        
        if v > 120:
            raise ValueError("Age must be realistic (under 120 years)")
        
        # Contextual validation based on email domain
        email = values.get('email')
        if email and '@student.' in email and v > 25:
            raise ValueError("Student email addresses are typically for users under 25")
        
        return v
```

## Performance Optimization

### Model Optimization Patterns
```python
from functools import lru_cache
from typing import ClassVar
import pickle

class OptimizedModel(BaseModel):
    """Model with performance optimizations."""
    
    # Class-level cache for validation
    _validation_cache: ClassVar[Dict[str, Any]] = {}
    
    id: int
    name: str
    data: Dict[str, Any]
    
    class Config:
        # Performance optimizations
        allow_reuse = True
        validate_assignment = False  # Skip validation on assignment
        extra = "ignore"  # Ignore extra fields instead of raising errors
        
        # Custom JSON encoders for performance
        json_encoders = {
            datetime: lambda v: v.isoformat() if v else None,
            Decimal: lambda v: float(v),
            set: lambda v: list(v)
        }
    
    @classmethod
    @lru_cache(maxsize=1000)
    def get_validation_schema(cls) -> Dict[str, Any]:
        """Cache validation schema for better performance."""
        return cls.schema()
    
    def dict_optimized(
        self, 
        include_computed: bool = False,
        exclude_none: bool = True
    ) -> Dict[str, Any]:
        """Optimized dict conversion with options."""
        data = self.dict(exclude_unset=True, exclude_none=exclude_none)
        
        if include_computed:
            data['computed_hash'] = hash(str(data))
            data['field_count'] = len(data)
        
        return data
    
    @classmethod
    def parse_cached(cls, data: Dict[str, Any]) -> 'OptimizedModel':
        """Parse with caching for repeated data structures."""
        data_key = str(sorted(data.items()))
        
        if data_key in cls._validation_cache:
            return cls._validation_cache[data_key]
        
        instance = cls.parse_obj(data)
        cls._validation_cache[data_key] = instance
        
        # Limit cache size
        if len(cls._validation_cache) > 1000:
            # Remove oldest entries (simple FIFO)
            oldest_keys = list(cls._validation_cache.keys())[:100]
            for key in oldest_keys:
                del cls._validation_cache[key]
        
        return instance

# Batch processing model
class BatchProcessor:
    """Efficient batch processing for Pydantic models."""
    
    @staticmethod
    def validate_batch(
        model_class: Type[BaseModel], 
        data_list: List[Dict[str, Any]],
        fail_fast: bool = False
    ) -> tuple[List[BaseModel], List[Dict[str, Any]]]:
        """Validate a batch of data efficiently."""
        valid_instances = []
        errors = []
        
        for i, data in enumerate(data_list):
            try:
                instance = model_class.parse_obj(data)
                valid_instances.append(instance)
            except ValidationError as e:
                error_info = {
                    "index": i,
                    "data": data,
                    "errors": e.errors()
                }
                errors.append(error_info)
                
                if fail_fast:
                    break
        
        return valid_instances, errors
    
    @staticmethod
    def serialize_batch(
        instances: List[BaseModel],
        format_type: str = "dict"
    ) -> List[Union[Dict[str, Any], str]]:
        """Efficiently serialize a batch of model instances."""
        if format_type == "dict":
            return [instance.dict() for instance in instances]
        elif format_type == "json":
            return [instance.json() for instance in instances]
        else:
            raise ValueError("Unsupported format type")

# Memory-efficient streaming model
class StreamingModel(BaseModel):
    """Model designed for streaming/memory-efficient processing."""
    
    __slots__ = ('id', 'name', 'value', '_processed')
    
    id: int
    name: str
    value: float
    
    def __init__(self, **data):
        super().__init__(**data)
        self._processed = False
    
    def process_and_clear(self) -> Dict[str, Any]:
        """Process data and clear from memory."""
        if self._processed:
            return {"error": "Already processed"}
        
        # Simulate processing
        result = {
            "id": self.id,
            "processed_name": self.name.upper(),
            "computed_value": self.value * 2,
            "timestamp": datetime.now().isoformat()
        }
        
        # Clear data to free memory
        self._processed = True
        return result
    
    def __del__(self):
        """Cleanup when object is destroyed."""
        if hasattr(self, '_processed'):
            del self._processed
```

## API Endpoints with Advanced Validation

### Complete CRUD with Validation
```python
from fastapi import Depends, Query, Path, Body
from typing import List, Optional

# Mock database
users_db: Dict[int, UserResponse] = {}
next_user_id = 1

@app.post("/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(user_data: UserCreate) -> UserResponse:
    """Create a new user with comprehensive validation."""
    global next_user_id
    
    try:
        # Simulate async validation (in real app, check database)
        await DatabaseValidator.unique_username(user_data.username)
        await DatabaseValidator.unique_email(user_data.email)
        
        # Create user response (excluding password)
        user_response = UserResponse(
            id=next_user_id,
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            age=user_data.age,
            phone=user_data.phone,
            website=user_data.website,
            bio=user_data.bio,
            role=user_data.role,
            tags=user_data.tags,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        users_db[next_user_id] = user_response
        next_user_id += 1
        
        return user_response
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int = Path(..., gt=0, description="User ID must be positive")
) -> UserResponse:
    """Get user by ID with path validation."""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    
    return users_db[user_id]

@app.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int = Path(..., gt=0),
    user_updates: UserUpdate = Body(...)
) -> UserResponse:
    """Update user with partial validation."""
    if user_id not in users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with ID {user_id} not found"
        )
    
    current_user = users_db[user_id]
    update_data = user_updates.dict(exclude_unset=True)
    
    # Validate unique constraints for updated fields
    if "username" in update_data:
        for uid, user in users_db.items():
            if uid != user_id and user.username == update_data["username"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already exists"
                )
    
    if "email" in update_data:
        for uid, user in users_db.items():
            if uid != user_id and user.email == update_data["email"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )
    
    # Update fields
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    current_user.updated_at = datetime.now()
    return current_user

@app.get("/users", response_model=List[UserResponse])
async def list_users(
    search: UserSearch = Depends()
) -> List[UserResponse]:
    """List users with advanced search and filtering."""
    results = list(users_db.values())
    
    # Apply filters based on search model
    search_dict = search.dict(exclude_unset=True)
    
    for field, value in search_dict.items():
        if value is None:
            continue
        
        if field == 'username' and value:
            results = [u for u in results if u.username == value]
        elif field == 'username_contains' and value:
            results = [u for u in results if value.lower() in u.username.lower()]
        elif field == 'role' and value:
            results = [u for u in results if u.role == value]
        elif field == 'age' and value:
            results = [u for u in results if u.age == int(value)]
    
    # Apply sorting
    sort_by = search_dict.get('sort_by', 'id')
    sort_order = search_dict.get('sort_order', 'asc')
    
    if hasattr(UserResponse, sort_by):
        reverse = sort_order == 'desc'
        results.sort(key=lambda x: getattr(x, sort_by), reverse=reverse)
    
    # Apply pagination
    offset = search_dict.get('offset', 0)
    limit = search_dict.get('limit', 10)
    
    return results[offset:offset + limit]

@app.post("/users/batch", response_model=Dict[str, Any])
async def create_users_batch(
    users_data: List[UserCreate] = Body(..., min_items=1, max_items=100)
) -> Dict[str, Any]:
    """Create multiple users with batch validation."""
    
    # Use batch processor for efficient validation
    valid_users, validation_errors = BatchProcessor.validate_batch(
        UserCreate, 
        [user.dict() for user in users_data],
        fail_fast=False
    )
    
    created_users = []
    creation_errors = []
    
    # Process valid users
    for user_data in valid_users:
        try:
            # Check uniqueness constraints
            for existing_user in users_db.values():
                if existing_user.username == user_data.username:
                    raise ValueError(f"Username '{user_data.username}' already exists")
                if existing_user.email == user_data.email:
                    raise ValueError(f"Email '{user_data.email}' already registered")
            
            # Create user
            global next_user_id
            user_response = UserResponse(
                id=next_user_id,
                username=user_data.username,
                email=user_data.email,
                full_name=user_data.full_name,
                age=user_data.age,
                phone=user_data.phone,
                website=user_data.website,
                bio=user_data.bio,
                role=user_data.role,
                tags=user_data.tags,
                created_at=datetime.now(),
                updated_at=datetime.now()
            )
            
            users_db[next_user_id] = user_response
            created_users.append(user_response)
            next_user_id += 1
            
        except ValueError as e:
            creation_errors.append({
                "user_data": user_data.dict(),
                "error": str(e)
            })
    
    return {
        "total_requested": len(users_data),
        "validation_errors": len(validation_errors),
        "creation_errors": len(creation_errors),
        "successfully_created": len(created_users),
        "created_users": created_users,
        "errors": {
            "validation": validation_errors,
            "creation": creation_errors
        }
    }

# Advanced query endpoint with complex validation
@app.post("/users/query", response_model=List[UserResponse])
async def query_users(
    query: Dict[str, Any] = Body(..., description="Complex query object"),
    include_inactive: bool = Query(False, description="Include inactive users"),
    format_response: bool = Query(True, description="Apply response formatting")
) -> List[UserResponse]:
    """Advanced user querying with complex validation."""
    
    # Validate query structure
    allowed_fields = ['username', 'email', 'role', 'age_min', 'age_max', 'tags_any', 'tags_all']
    
    for field in query.keys():
        if field not in allowed_fields:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid query field: {field}. Allowed fields: {allowed_fields}"
            )
    
    results = list(users_db.values())
    
    # Apply filters
    if not include_inactive:
        results = [u for u in results if u.is_active]
    
    # Apply query filters
    if 'username' in query:
        results = [u for u in results if query['username'].lower() in u.username.lower()]
    
    if 'role' in query:
        results = [u for u in results if u.role == query['role']]
    
    if 'age_min' in query:
        results = [u for u in results if u.age >= query['age_min']]
    
    if 'age_max' in query:
        results = [u for u in results if u.age <= query['age_max']]
    
    if 'tags_any' in query:
        tag_list = query['tags_any']
        results = [u for u in results if any(tag in u.tags for tag in tag_list)]
    
    if 'tags_all' in query:
        tag_list = query['tags_all']
        results = [u for u in results if all(tag in u.tags for tag in tag_list)]
    
    return results[:100]  # Limit results
```

---

**Last Updated:** Based on FastAPI 0.100+ and Pydantic v2 features
**References:**
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [FastAPI Request Body](https://fastapi.tiangolo.com/tutorial/body/)
- [Pydantic Validators](https://docs.pydantic.dev/usage/validators/)
- [FastAPI Response Models](https://fastapi.tiangolo.com/tutorial/response-model/)
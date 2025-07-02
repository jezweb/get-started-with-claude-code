# Python Dataclasses and Pydantic Integration

## Overview
This guide covers modern Python dataclass patterns and Pydantic integration for web development, focusing on data validation, serialization, and type-safe API development.

## Python Dataclasses

### Basic Dataclass Patterns
```python
from dataclasses import dataclass, field, asdict, astuple
from typing import Any, ClassVar
from datetime import datetime
from enum import Enum

@dataclass
class User:
    """Basic user dataclass with type hints."""
    id: int
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    is_active: bool = True
    metadata: dict[str, Any] = field(default_factory=dict)
    
    # Class variable (not included in instance)
    table_name: ClassVar[str] = "users"
    
    def __post_init__(self):
        """Post-initialization processing."""
        if not self.email or "@" not in self.email:
            raise ValueError("Invalid email address")
        
        # Normalize email
        self.email = self.email.lower().strip()

# Usage
user = User(
    id=1,
    name="John Doe",
    email="JOHN@EXAMPLE.COM",
    metadata={"role": "admin", "department": "IT"}
)

# Convert to dictionary
user_dict = asdict(user)
print(user_dict)

# Convert to tuple
user_tuple = astuple(user)
print(user_tuple)
```

### Advanced Dataclass Features
```python
from dataclasses import dataclass, field, InitVar
from typing import Optional, Union
import json

class UserRole(Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

@dataclass(frozen=True, order=True)
class ImmutableUser:
    """Immutable, orderable user dataclass."""
    id: int
    name: str
    email: str
    role: UserRole = UserRole.USER
    
    def __str__(self) -> str:
        return f"{self.name} <{self.email}> ({self.role.value})"

@dataclass
class UserWithValidation:
    """User with custom validation and computed fields."""
    first_name: str
    last_name: str
    email: str
    age: int
    password: InitVar[str]  # Not stored in instance
    
    # Computed field
    full_name: str = field(init=False)
    password_hash: str = field(init=False, repr=False)
    
    def __post_init__(self, password: str):
        """Initialize computed fields and validate data."""
        # Validate age
        if self.age < 0 or self.age > 150:
            raise ValueError("Age must be between 0 and 150")
        
        # Validate email
        if "@" not in self.email:
            raise ValueError("Invalid email format")
        
        # Set computed fields
        self.full_name = f"{self.first_name} {self.last_name}"
        self.password_hash = self._hash_password(password)
    
    def _hash_password(self, password: str) -> str:
        """Hash password (simplified for example)."""
        import hashlib
        return hashlib.sha256(password.encode()).hexdigest()

# Dataclass with custom field configurations
@dataclass
class Product:
    """Product with various field configurations."""
    id: int
    name: str
    price: float = field(metadata={"unit": "USD"})
    tags: list[str] = field(default_factory=list)
    inventory: int = field(default=0, compare=False)  # Exclude from comparison
    internal_code: str = field(repr=False)  # Exclude from repr
    
    # Custom field with validation
    discount_percent: float = field(default=0.0)
    
    def __post_init__(self):
        if self.discount_percent < 0 or self.discount_percent > 100:
            raise ValueError("Discount must be between 0 and 100")
        
        if self.price < 0:
            raise ValueError("Price cannot be negative")

# Factory functions for complex defaults
def create_default_settings() -> dict[str, Any]:
    """Create default user settings."""
    return {
        "theme": "light",
        "notifications": True,
        "language": "en"
    }

@dataclass
class UserProfile:
    """User profile with complex default factory."""
    user_id: int
    settings: dict[str, Any] = field(default_factory=create_default_settings)
    preferences: dict[str, str] = field(default_factory=dict)
    last_login: Optional[datetime] = None
    
    def update_setting(self, key: str, value: Any) -> None:
        """Update a user setting."""
        self.settings[key] = value
    
    def to_json(self) -> str:
        """Convert to JSON string."""
        data = asdict(self)
        # Handle datetime serialization
        if self.last_login:
            data["last_login"] = self.last_login.isoformat()
        return json.dumps(data)
    
    @classmethod
    def from_json(cls, json_str: str) -> "UserProfile":
        """Create instance from JSON string."""
        data = json.loads(json_str)
        if data.get("last_login"):
            data["last_login"] = datetime.fromisoformat(data["last_login"])
        return cls(**data)
```

### Dataclass Inheritance and Composition
```python
@dataclass
class BaseEntity:
    """Base entity with common fields."""
    id: int
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    
    def update_timestamp(self) -> None:
        """Update the last modified timestamp."""
        self.updated_at = datetime.now()

@dataclass
class Person(BaseEntity):
    """Person extending base entity."""
    first_name: str
    last_name: str
    email: str
    
    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"

@dataclass
class Employee(Person):
    """Employee extending person."""
    employee_id: str
    department: str
    salary: float
    manager_id: Optional[int] = None
    
    def give_raise(self, percentage: float) -> None:
        """Give employee a raise."""
        if percentage <= 0:
            raise ValueError("Raise percentage must be positive")
        
        self.salary *= (1 + percentage / 100)
        self.update_timestamp()

# Composition pattern with dataclasses
@dataclass
class Address:
    """Address dataclass for composition."""
    street: str
    city: str
    state: str
    zip_code: str
    country: str = "USA"
    
    def __str__(self) -> str:
        return f"{self.street}, {self.city}, {self.state} {self.zip_code}"

@dataclass
class Company:
    """Company with address composition."""
    name: str
    address: Address
    phone: str
    employees: list[Employee] = field(default_factory=list)
    
    def add_employee(self, employee: Employee) -> None:
        """Add employee to company."""
        self.employees.append(employee)
    
    def get_employees_by_department(self, department: str) -> list[Employee]:
        """Get employees by department."""
        return [emp for emp in self.employees if emp.department == department]
    
    def calculate_total_payroll(self) -> float:
        """Calculate total company payroll."""
        return sum(emp.salary for emp in self.employees)
```

## Pydantic Models

### Basic Pydantic Patterns
```python
from pydantic import BaseModel, Field, validator, root_validator
from typing import Optional, List, Dict, Union
from datetime import datetime
from enum import Enum

class UserRole(str, Enum):
    """User role enumeration."""
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

class UserModel(BaseModel):
    """Basic Pydantic user model."""
    id: int = Field(..., gt=0, description="User ID")
    name: str = Field(..., min_length=1, max_length=100, description="User name")
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$', description="Email address")
    age: Optional[int] = Field(None, ge=0, le=150, description="User age")
    role: UserRole = Field(default=UserRole.USER, description="User role")
    is_active: bool = Field(default=True, description="Whether user is active")
    created_at: datetime = Field(default_factory=datetime.now)
    metadata: Dict[str, Union[str, int, bool]] = Field(default_factory=dict)
    
    class Config:
        """Pydantic configuration."""
        use_enum_values = True  # Use enum values in serialization
        validate_assignment = True  # Validate on assignment
        extra = "forbid"  # Forbid extra fields
        schema_extra = {
            "example": {
                "id": 1,
                "name": "John Doe",
                "email": "john@example.com",
                "age": 30,
                "role": "user",
                "metadata": {"department": "Engineering"}
            }
        }
    
    @validator('email')
    def validate_email_domain(cls, v):
        """Custom email domain validation."""
        allowed_domains = ["example.com", "company.com"]
        domain = v.split("@")[1].lower()
        if domain not in allowed_domains:
            raise ValueError(f"Email domain must be one of: {allowed_domains}")
        return v.lower()
    
    @validator('name')
    def validate_name_format(cls, v):
        """Validate name format."""
        if not v.replace(" ", "").isalpha():
            raise ValueError("Name must contain only letters and spaces")
        return v.title()  # Capitalize properly
    
    @root_validator
    def validate_admin_requirements(cls, values):
        """Root validator for cross-field validation."""
        role = values.get('role')
        age = values.get('age')
        
        if role == UserRole.ADMIN and (age is None or age < 18):
            raise ValueError("Admin users must be at least 18 years old")
        
        return values

# Usage
user_data = {
    "id": 1,
    "name": "john doe",
    "email": "JOHN@EXAMPLE.COM",
    "age": 25,
    "role": "admin"
}

user = UserModel(**user_data)
print(user.json(indent=2))
print(user.dict())
```

### Advanced Pydantic Features
```python
from pydantic import (
    BaseModel, Field, validator, root_validator, 
    create_model, parse_obj_as, ValidationError
)
from typing import Any, Type, ForwardRef
import json

class ProductModel(BaseModel):
    """Product model with advanced features."""
    id: int = Field(..., description="Product ID")
    name: str = Field(..., min_length=1, max_length=200)
    price: float = Field(..., gt=0, description="Price in USD")
    category: str = Field(..., min_length=1)
    tags: List[str] = Field(default_factory=list)
    specifications: Dict[str, Any] = Field(default_factory=dict)
    discount_percentage: float = Field(0, ge=0, le=100)
    
    # Computed field
    discounted_price: Optional[float] = None
    
    @validator('tags', each_item=True)
    def validate_tags(cls, v):
        """Validate each tag."""
        if not v.strip():
            raise ValueError("Tags cannot be empty")
        return v.lower().strip()
    
    @validator('discounted_price', always=True)
    def calculate_discounted_price(cls, v, values):
        """Calculate discounted price."""
        price = values.get('price')
        discount = values.get('discount_percentage', 0)
        
        if price is not None:
            return price * (1 - discount / 100)
        return None
    
    def apply_discount(self, percentage: float) -> "ProductModel":
        """Apply discount and return new instance."""
        return self.copy(update={"discount_percentage": percentage})

# Dynamic model creation
def create_user_model(additional_fields: Dict[str, Any]) -> Type[BaseModel]:
    """Dynamically create user model with additional fields."""
    base_fields = {
        'id': (int, Field(..., gt=0)),
        'name': (str, Field(..., min_length=1)),
        'email': (str, Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')),
    }
    
    # Merge with additional fields
    all_fields = {**base_fields, **additional_fields}
    
    return create_model('DynamicUserModel', **all_fields)

# Usage of dynamic model
CustomUserModel = create_user_model({
    'department': (str, Field(..., min_length=1)),
    'salary': (Optional[float], Field(None, gt=0)),
    'start_date': (datetime, Field(default_factory=datetime.now))
})

# Nested models with forward references
class OrderItemModel(BaseModel):
    """Order item model."""
    product_id: int = Field(..., gt=0)
    quantity: int = Field(..., gt=0)
    unit_price: float = Field(..., gt=0)
    
    @property
    def total_price(self) -> float:
        return self.quantity * self.unit_price

class OrderModel(BaseModel):
    """Order model with nested items."""
    id: int = Field(..., gt=0)
    customer_id: int = Field(..., gt=0)
    items: List[OrderItemModel] = Field(..., min_items=1)
    order_date: datetime = Field(default_factory=datetime.now)
    status: str = Field(default="pending")
    shipping_address: Optional["AddressModel"] = None  # Forward reference
    
    @property
    def total_amount(self) -> float:
        return sum(item.total_price for item in self.items)
    
    @validator('status')
    def validate_status(cls, v):
        allowed_statuses = ["pending", "confirmed", "shipped", "delivered", "cancelled"]
        if v not in allowed_statuses:
            raise ValueError(f"Status must be one of: {allowed_statuses}")
        return v

class AddressModel(BaseModel):
    """Address model for forward reference resolution."""
    street: str = Field(..., min_length=1)
    city: str = Field(..., min_length=1)
    state: str = Field(..., min_length=2, max_length=2)
    zip_code: str = Field(..., regex=r'^\d{5}(-\d{4})?$')
    country: str = Field(default="USA")

# Update forward references
OrderModel.model_rebuild()
```

### Pydantic with FastAPI Integration
```python
from fastapi import FastAPI, HTTPException, Query, Path, Body
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

app = FastAPI()

# Request/Response models
class UserCreateRequest(BaseModel):
    """User creation request model."""
    name: str = Field(..., min_length=1, max_length=100, example="John Doe")
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$', example="john@example.com")
    age: Optional[int] = Field(None, ge=0, le=150, example=30)
    department: Optional[str] = Field(None, max_length=50, example="Engineering")

class UserUpdateRequest(BaseModel):
    """User update request model."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[str] = Field(None, regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    age: Optional[int] = Field(None, ge=0, le=150)
    department: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    """User response model."""
    id: int
    name: str
    email: str
    age: Optional[int]
    department: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True  # Enable ORM mode

class PaginatedResponse(BaseModel):
    """Generic paginated response."""
    items: List[UserResponse]
    total: int
    page: int
    per_page: int
    pages: int

class ErrorResponse(BaseModel):
    """Error response model."""
    error: str
    details: Optional[Dict[str, Any]] = None
    timestamp: datetime = Field(default_factory=datetime.now)

# FastAPI endpoints with Pydantic validation
@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(user_data: UserCreateRequest) -> UserResponse:
    """Create a new user with validation."""
    try:
        # Simulate user creation
        new_user = await create_user_in_database(user_data.dict())
        return UserResponse(**new_user)
    except Exception as e:
        raise HTTPException(500, f"Failed to create user: {str(e)}")

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int = Path(..., gt=0, description="User ID")
) -> UserResponse:
    """Get user by ID with path validation."""
    user = await fetch_user_from_database(user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return UserResponse(**user)

@app.patch("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int = Path(..., gt=0),
    updates: UserUpdateRequest = Body(...)
) -> UserResponse:
    """Update user with partial data validation."""
    # Only update fields that were provided
    update_data = updates.dict(exclude_unset=True)
    
    if not update_data:
        raise HTTPException(400, "No update data provided")
    
    updated_user = await update_user_in_database(user_id, update_data)
    if not updated_user:
        raise HTTPException(404, "User not found")
    
    return UserResponse(**updated_user)

@app.get("/users", response_model=PaginatedResponse)
async def list_users(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    department: Optional[str] = Query(None, max_length=50, description="Filter by department"),
    is_active: Optional[bool] = Query(None, description="Filter by active status")
) -> PaginatedResponse:
    """List users with query parameter validation."""
    filters = {}
    if department:
        filters["department"] = department
    if is_active is not None:
        filters["is_active"] = is_active
    
    users, total = await fetch_users_with_pagination(
        page=page,
        per_page=per_page,
        filters=filters
    )
    
    return PaginatedResponse(
        items=[UserResponse(**user) for user in users],
        total=total,
        page=page,
        per_page=per_page,
        pages=(total + per_page - 1) // per_page
    )

# Bulk operations with validation
class BulkUserOperation(BaseModel):
    """Bulk user operation model."""
    operation: str = Field(..., regex=r'^(create|update|delete)$')
    users: List[Union[UserCreateRequest, UserUpdateRequest]] = Field(..., min_items=1, max_items=100)

class BulkOperationResult(BaseModel):
    """Bulk operation result model."""
    successful: int
    failed: int
    errors: List[str] = Field(default_factory=list)

@app.post("/users/bulk", response_model=BulkOperationResult)
async def bulk_user_operations(operation: BulkUserOperation) -> BulkOperationResult:
    """Perform bulk user operations with validation."""
    successful = 0
    failed = 0
    errors = []
    
    for i, user_data in enumerate(operation.users):
        try:
            if operation.operation == "create":
                await create_user_in_database(user_data.dict())
            elif operation.operation == "update":
                await update_user_in_database(user_data.id, user_data.dict(exclude_unset=True))
            elif operation.operation == "delete":
                await delete_user_from_database(user_data.id)
            
            successful += 1
        except Exception as e:
            failed += 1
            errors.append(f"Item {i}: {str(e)}")
    
    return BulkOperationResult(
        successful=successful,
        failed=failed,
        errors=errors
    )
```

## Dataclass and Pydantic Conversion

### Converting Between Dataclasses and Pydantic
```python
from dataclasses import dataclass, asdict
from pydantic import BaseModel
from typing import Type, TypeVar, Dict, Any

T = TypeVar('T')

@dataclass
class UserDataclass:
    """User as a dataclass."""
    id: int
    name: str
    email: str
    is_active: bool = True

class UserPydantic(BaseModel):
    """User as a Pydantic model."""
    id: int
    name: str
    email: str
    is_active: bool = True

def dataclass_to_pydantic(
    dataclass_instance: Any, 
    pydantic_model: Type[BaseModel]
) -> BaseModel:
    """Convert dataclass instance to Pydantic model."""
    data = asdict(dataclass_instance)
    return pydantic_model(**data)

def pydantic_to_dataclass(
    pydantic_instance: BaseModel, 
    dataclass_type: Type[T]
) -> T:
    """Convert Pydantic model to dataclass."""
    data = pydantic_instance.dict()
    return dataclass_type(**data)

# Usage
dc_user = UserDataclass(id=1, name="John", email="john@example.com")
pydantic_user = dataclass_to_pydantic(dc_user, UserPydantic)

# Convert back
converted_dc_user = pydantic_to_dataclass(pydantic_user, UserDataclass)

# Generic converter class
class ModelConverter:
    """Convert between different model types."""
    
    @staticmethod
    def to_dict(model: Union[BaseModel, Any]) -> Dict[str, Any]:
        """Convert model to dictionary."""
        if isinstance(model, BaseModel):
            return model.dict()
        elif hasattr(model, '__dataclass_fields__'):
            return asdict(model)
        else:
            return model.__dict__
    
    @staticmethod
    def from_dict(data: Dict[str, Any], target_type: Type[T]) -> T:
        """Create model from dictionary."""
        if issubclass(target_type, BaseModel):
            return target_type(**data)
        else:
            return target_type(**data)
    
    @classmethod
    def convert(cls, source_model: Any, target_type: Type[T]) -> T:
        """Convert between model types."""
        data = cls.to_dict(source_model)
        return cls.from_dict(data, target_type)

# Usage with converter
converter = ModelConverter()
converted_user = converter.convert(dc_user, UserPydantic)
```

### Hybrid Approach for Web Applications
```python
from dataclasses import dataclass, field
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any, Union
from datetime import datetime

# Domain models as dataclasses (business logic)
@dataclass
class UserDomain:
    """Domain user model with business logic."""
    id: int
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
    is_active: bool = True
    _password_hash: str = field(repr=False, default="")
    
    def set_password(self, password: str) -> None:
        """Set user password with hashing."""
        import hashlib
        self._password_hash = hashlib.sha256(password.encode()).hexdigest()
    
    def verify_password(self, password: str) -> bool:
        """Verify user password."""
        import hashlib
        return self._password_hash == hashlib.sha256(password.encode()).hexdigest()
    
    def deactivate(self) -> None:
        """Deactivate user account."""
        self.is_active = False
    
    def activate(self) -> None:
        """Activate user account."""
        self.is_active = True

# API models as Pydantic (validation and serialization)
class UserCreateAPI(BaseModel):
    """API model for user creation."""
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    password: str = Field(..., min_length=8, max_length=128)
    
    @validator('password')
    def validate_password_strength(cls, v):
        """Validate password strength."""
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v

class UserResponseAPI(BaseModel):
    """API model for user responses."""
    id: int
    name: str
    email: str
    created_at: datetime
    is_active: bool
    
    class Config:
        from_attributes = True

class UserUpdateAPI(BaseModel):
    """API model for user updates."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[str] = Field(None, regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')

# Service layer that bridges domain and API models
class UserService:
    """User service with model conversion."""
    
    def __init__(self):
        self.users: Dict[int, UserDomain] = {}
        self.next_id = 1
    
    def create_user(self, user_data: UserCreateAPI) -> UserDomain:
        """Create user from API model."""
        # Convert API model to domain model
        domain_user = UserDomain(
            id=self.next_id,
            name=user_data.name,
            email=user_data.email
        )
        
        # Set password using domain logic
        domain_user.set_password(user_data.password)
        
        self.users[self.next_id] = domain_user
        self.next_id += 1
        
        return domain_user
    
    def get_user(self, user_id: int) -> Optional[UserDomain]:
        """Get user by ID."""
        return self.users.get(user_id)
    
    def update_user(self, user_id: int, updates: UserUpdateAPI) -> Optional[UserDomain]:
        """Update user with API model."""
        user = self.users.get(user_id)
        if not user:
            return None
        
        # Apply updates from API model
        update_data = updates.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(user, field, value)
        
        return user
    
    def list_users(self) -> List[UserDomain]:
        """List all users."""
        return list(self.users.values())

# FastAPI endpoints using hybrid approach
user_service = UserService()

@app.post("/users", response_model=UserResponseAPI, status_code=201)
async def create_user_hybrid(user_data: UserCreateAPI) -> UserResponseAPI:
    """Create user using hybrid approach."""
    try:
        domain_user = user_service.create_user(user_data)
        
        # Convert domain model to API response model
        return UserResponseAPI(
            id=domain_user.id,
            name=domain_user.name,
            email=domain_user.email,
            created_at=domain_user.created_at,
            is_active=domain_user.is_active
        )
    except ValueError as e:
        raise HTTPException(400, str(e))

@app.get("/users/{user_id}", response_model=UserResponseAPI)
async def get_user_hybrid(user_id: int) -> UserResponseAPI:
    """Get user using hybrid approach."""
    domain_user = user_service.get_user(user_id)
    if not domain_user:
        raise HTTPException(404, "User not found")
    
    return UserResponseAPI(
        id=domain_user.id,
        name=domain_user.name,
        email=domain_user.email,
        created_at=domain_user.created_at,
        is_active=domain_user.is_active
    )

@app.patch("/users/{user_id}", response_model=UserResponseAPI)
async def update_user_hybrid(
    user_id: int, 
    updates: UserUpdateAPI
) -> UserResponseAPI:
    """Update user using hybrid approach."""
    domain_user = user_service.update_user(user_id, updates)
    if not domain_user:
        raise HTTPException(404, "User not found")
    
    return UserResponseAPI(
        id=domain_user.id,
        name=domain_user.name,
        email=domain_user.email,
        created_at=domain_user.created_at,
        is_active=domain_user.is_active
    )

# Password change endpoint using domain logic
class PasswordChangeAPI(BaseModel):
    """API model for password changes."""
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8, max_length=128)
    
    @validator('new_password')
    def validate_password_strength(cls, v):
        """Validate new password strength."""
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v

@app.put("/users/{user_id}/password")
async def change_password(
    user_id: int,
    password_data: PasswordChangeAPI
) -> Dict[str, str]:
    """Change user password using domain logic."""
    domain_user = user_service.get_user(user_id)
    if not domain_user:
        raise HTTPException(404, "User not found")
    
    # Use domain logic for password verification
    if not domain_user.verify_password(password_data.current_password):
        raise HTTPException(400, "Current password is incorrect")
    
    # Use domain logic for setting new password
    domain_user.set_password(password_data.new_password)
    
    return {"message": "Password changed successfully"}
```

## Performance and Best Practices

### Optimization Techniques
```python
from pydantic import BaseModel, Field, validator
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
import json
from functools import lru_cache

# Efficient serialization patterns
class OptimizedUserModel(BaseModel):
    """Optimized user model with custom serialization."""
    id: int
    name: str
    email: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
    
    class Config:
        # Optimization settings
        allow_reuse=True  # Reuse validators for better performance
        validate_assignment=False  # Skip validation on assignment for performance
        extra="ignore"  # Ignore extra fields instead of raising errors
        
        # Custom JSON encoders
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            set: lambda v: list(v)
        }
    
    def json_optimized(self, **kwargs) -> str:
        """Optimized JSON serialization."""
        return self.json(exclude_unset=True, by_alias=True, **kwargs)
    
    @classmethod
    @lru_cache(maxsize=1000)
    def cached_parse(cls, json_str: str) -> "OptimizedUserModel":
        """Cached parsing for frequently accessed data."""
        return cls.parse_raw(json_str)

# Batch processing optimization
class BatchProcessor:
    """Optimized batch processing for models."""
    
    @staticmethod
    def process_users_batch(user_data_list: List[Dict[str, Any]]) -> List[UserModel]:
        """Process multiple users efficiently."""
        # Pre-validate common patterns
        validated_users = []
        errors = []
        
        for i, user_data in enumerate(user_data_list):
            try:
                user = UserModel(**user_data)
                validated_users.append(user)
            except ValidationError as e:
                errors.append(f"User {i}: {e}")
        
        if errors:
            raise ValueError(f"Validation errors: {'; '.join(errors)}")
        
        return validated_users
    
    @staticmethod
    def serialize_batch(users: List[UserModel]) -> str:
        """Efficient batch serialization."""
        # Use direct dict conversion for better performance
        user_dicts = [user.dict() for user in users]
        return json.dumps(user_dicts, default=str)

# Memory-efficient patterns
@dataclass
class MemoryEfficientUser:
    """Memory-efficient user representation."""
    __slots__ = ('id', 'name', 'email', 'is_active')
    
    id: int
    name: str
    email: str
    is_active: bool = True

# Lazy loading pattern
class LazyLoadingModel(BaseModel):
    """Model with lazy loading capabilities."""
    id: int
    name: str
    _detailed_data: Optional[Dict[str, Any]] = None
    
    class Config:
        underscore_attrs_are_private = True
    
    def load_detailed_data(self) -> Dict[str, Any]:
        """Load detailed data on demand."""
        if self._detailed_data is None:
            # Simulate expensive data loading
            self._detailed_data = fetch_detailed_user_data(self.id)
        return self._detailed_data
    
    @property
    def detailed_info(self) -> Dict[str, Any]:
        """Get detailed info with lazy loading."""
        return self.load_detailed_data()

# Custom validators for performance
class FastValidationModel(BaseModel):
    """Model with optimized validators."""
    email: str
    tags: List[str] = Field(default_factory=list)
    
    @validator('email', pre=True)
    def fast_email_validation(cls, v):
        """Fast email validation."""
        if isinstance(v, str) and '@' in v and '.' in v.split('@')[1]:
            return v.lower().strip()
        raise ValueError("Invalid email format")
    
    @validator('tags', pre=True, each_item=False)
    def optimize_tags(cls, v):
        """Optimize tags list processing."""
        if not v:
            return []
        
        # Efficient list processing
        return [tag.lower().strip() for tag in v if tag.strip()]

# Model inheritance for code reuse
class BaseAPIModel(BaseModel):
    """Base model with common configuration."""
    
    class Config:
        allow_reuse = True
        validate_assignment = False
        extra = "forbid"
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def to_dict_optimized(self) -> Dict[str, Any]:
        """Optimized dictionary conversion."""
        return self.dict(exclude_unset=True, by_alias=True)

class UserModelOptimized(BaseAPIModel):
    """User model inheriting optimized base."""
    id: int = Field(..., gt=0)
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')

class ProductModelOptimized(BaseAPIModel):
    """Product model inheriting optimized base."""
    id: int = Field(..., gt=0)
    name: str = Field(..., min_length=1, max_length=200)
    price: float = Field(..., gt=0)
```

### Best Practices Summary

#### Dataclass Best Practices
1. **Use `field()` for complex defaults** to avoid mutable default arguments
2. **Implement `__post_init__`** for validation and computed fields
3. **Use `frozen=True`** for immutable data structures
4. **Consider `slots=True`** for memory efficiency (Python 3.10+)
5. **Use inheritance judiciously** - composition often better than inheritance

#### Pydantic Best Practices
1. **Use specific field types** with appropriate constraints
2. **Implement custom validators** for business logic validation
3. **Configure models appropriately** for your use case
4. **Use aliases** for API field name mapping
5. **Optimize serialization** with `exclude_unset=True` and custom encoders

#### Integration Best Practices
1. **Separate concerns** - use dataclasses for domain logic, Pydantic for API
2. **Cache expensive operations** like parsing and validation
3. **Batch process** when dealing with large datasets
4. **Use appropriate inheritance** to avoid code duplication
5. **Consider memory usage** for high-throughput applications

---

**Last Updated:** Based on Python 3.10+ dataclasses and Pydantic v2 features
**References:**
- [Python Dataclasses Documentation](https://docs.python.org/3/library/dataclasses.html)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [FastAPI with Pydantic](https://fastapi.tiangolo.com/tutorial/body/)
- [Python Data Classes vs Pydantic](https://pydantic-docs.helpmanual.io/usage/dataclasses/)
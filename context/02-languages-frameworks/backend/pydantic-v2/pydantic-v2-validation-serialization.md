# Pydantic v2 Validation and Serialization

## Overview

Pydantic v2 introduces powerful new validation decorators, computed fields, and advanced serialization features. This guide covers the latest validation patterns, custom validators, and serialization capabilities including duck-typing and context support introduced in v2.7+.

## 🔍 New Validation Decorators

### 1. Field Validators (@field_validator)

The `@field_validator` decorator replaces the v1 `@validator` decorator with improved functionality.

```python
from pydantic import BaseModel, field_validator, ValidationInfo
from typing import List
import re

class User(BaseModel):
    name: str
    email: str
    age: int
    tags: List[str]
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Basic field validation"""
        if not v.strip():
            raise ValueError('Name cannot be empty')
        if len(v) < 2:
            raise ValueError('Name must be at least 2 characters')
        return v.title()  # Normalize to title case
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Email validation with regex"""
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, v):
            raise ValueError('Invalid email format')
        return v.lower()
    
    @field_validator('age')
    @classmethod
    def validate_age(cls, v: int) -> int:
        """Numeric validation with constraints"""
        if v < 0:
            raise ValueError('Age cannot be negative')
        if v > 150:
            raise ValueError('Age seems unrealistic')
        return v
    
    @field_validator('tags')
    @classmethod
    def validate_tags(cls, v: List[str]) -> List[str]:
        """List validation with processing"""
        if not v:
            return v
        
        # Remove duplicates and empty tags
        cleaned_tags = list(set(tag.strip().lower() for tag in v if tag.strip()))
        
        if len(cleaned_tags) > 10:
            raise ValueError('Too many tags (max 10)')
        
        return cleaned_tags

# Usage
user_data = {
    "name": "john doe",
    "email": "JOHN@EXAMPLE.COM",
    "age": 30,
    "tags": ["Python", "FastAPI", "python", "", "Web Development"]
}

user = User.model_validate(user_data)
print(user.name)   # "John Doe"
print(user.email)  # "john@example.com" 
print(user.tags)   # ["python", "fastapi", "web development"]
```

### 2. Model Validators (@model_validator)

Model validators allow validation across multiple fields and have access to the entire model.

```python
from pydantic import BaseModel, model_validator, Field
from datetime import datetime, date
from typing import Optional

class Event(BaseModel):
    title: str
    start_date: date
    end_date: date
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    is_all_day: bool = False
    max_attendees: int = Field(gt=0)
    registered_attendees: int = Field(default=0, ge=0)
    
    @model_validator(mode='before')
    @classmethod
    def validate_before_parsing(cls, data):
        """Pre-processing validation (receives raw data)"""
        if isinstance(data, dict):
            # Convert string dates to proper format
            for date_field in ['start_date', 'end_date']:
                if isinstance(data.get(date_field), str):
                    try:
                        data[date_field] = datetime.strptime(data[date_field], '%Y-%m-%d').date()
                    except ValueError:
                        raise ValueError(f'Invalid date format for {date_field}')
        return data
    
    @model_validator(mode='after')
    @classmethod
    def validate_after_parsing(cls, model: 'Event') -> 'Event':
        """Post-processing validation (receives parsed model)"""
        
        # Date logic validation
        if model.end_date < model.start_date:
            raise ValueError('End date cannot be before start date')
        
        # Time validation for single-day events
        if model.start_date == model.end_date and not model.is_all_day:
            if not (model.start_time and model.end_time):
                raise ValueError('Single-day events must have start and end times')
            
            # Parse and compare times
            try:
                start_dt = datetime.strptime(model.start_time, '%H:%M')
                end_dt = datetime.strptime(model.end_time, '%H:%M')
                if end_dt <= start_dt:
                    raise ValueError('End time must be after start time')
            except ValueError as e:
                raise ValueError(f'Invalid time format: {e}')
        
        # Attendee validation
        if model.registered_attendees > model.max_attendees:
            raise ValueError('Registered attendees cannot exceed maximum capacity')
        
        # Auto-set all-day for multi-day events
        if model.start_date != model.end_date:
            model.is_all_day = True
            model.start_time = None
            model.end_time = None
        
        return model

# Usage
event_data = {
    "title": "Python Conference",
    "start_date": "2024-06-15",
    "end_date": "2024-06-15", 
    "start_time": "09:00",
    "end_time": "17:00",
    "max_attendees": 100,
    "registered_attendees": 75
}

event = Event.model_validate(event_data)
print(event.title)  # "Python Conference"
print(event.is_all_day)  # False (single day with times)
```

### 3. Validation with Context

Pydantic v2 supports passing context during validation for dynamic behavior.

```python
from pydantic import BaseModel, field_validator, ValidationInfo

class UserAccount(BaseModel):
    username: str
    password: str
    role: str
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str, info: ValidationInfo) -> str:
        """Username validation with context"""
        context = info.context or {}
        
        # Different validation rules based on context
        is_admin_creation = context.get('is_admin_creation', False)
        existing_usernames = context.get('existing_usernames', set())
        
        # Basic validation
        if len(v) < 3:
            raise ValueError('Username must be at least 3 characters')
        
        # Check for existing usernames
        if v.lower() in existing_usernames:
            raise ValueError('Username already exists')
        
        # Reserved usernames (skip check for admin creation)
        reserved = {'admin', 'root', 'system', 'api'}
        if not is_admin_creation and v.lower() in reserved:
            raise ValueError('Username is reserved')
        
        return v.lower()
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str, info: ValidationInfo) -> str:
        """Password validation with context"""
        context = info.context or {}
        min_length = context.get('password_min_length', 8)
        require_special = context.get('require_special_chars', True)
        
        if len(v) < min_length:
            raise ValueError(f'Password must be at least {min_length} characters')
        
        if require_special and not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain special characters')
        
        return v
    
    @field_validator('role')
    @classmethod
    def validate_role(cls, v: str, info: ValidationInfo) -> str:
        """Role validation with context"""
        context = info.context or {}
        allowed_roles = context.get('allowed_roles', ['user'])
        
        if v not in allowed_roles:
            raise ValueError(f'Role must be one of: {allowed_roles}')
        
        return v

# Usage with different contexts
user_context = {
    'existing_usernames': {'john', 'jane', 'bob'},
    'password_min_length': 12,
    'require_special_chars': True,
    'allowed_roles': ['user', 'moderator']
}

admin_context = {
    'is_admin_creation': True,
    'existing_usernames': {'john', 'jane', 'bob'},
    'password_min_length': 8,
    'require_special_chars': False,
    'allowed_roles': ['user', 'moderator', 'admin']
}

# Regular user creation
user_data = {
    "username": "newuser",
    "password": "MySecurePass123!",
    "role": "user"
}

user = UserAccount.model_validate(user_data, context=user_context)

# Admin creation (can use reserved names)
admin_data = {
    "username": "admin",
    "password": "simplepass",
    "role": "admin"
}

admin = UserAccount.model_validate(admin_data, context=admin_context)
```

## 🧮 Computed Fields

Computed fields are a powerful v2 feature that allows you to define fields calculated from other fields.

### 1. Basic Computed Fields

```python
from pydantic import BaseModel, computed_field
from datetime import datetime, date
from typing import List

class Person(BaseModel):
    first_name: str
    last_name: str
    birth_date: date
    skills: List[str]
    hourly_rate: float
    
    @computed_field
    @property
    def full_name(self) -> str:
        """Computed from first and last name"""
        return f"{self.first_name} {self.last_name}"
    
    @computed_field
    @property
    def age(self) -> int:
        """Computed from birth date"""
        today = date.today()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )
    
    @computed_field
    @property
    def skill_count(self) -> int:
        """Computed from skills list"""
        return len(self.skills)
    
    @computed_field
    @property
    def annual_salary_estimate(self) -> float:
        """Computed from hourly rate (assuming 40h/week, 52 weeks/year)"""
        return self.hourly_rate * 40 * 52

# Usage
person_data = {
    "first_name": "John",
    "last_name": "Doe",
    "birth_date": date(1990, 5, 15),
    "skills": ["Python", "FastAPI", "PostgreSQL"],
    "hourly_rate": 75.0
}

person = Person.model_validate(person_data)
print(person.full_name)  # "John Doe"
print(person.age)        # Calculated age
print(person.skill_count)  # 3
print(person.annual_salary_estimate)  # 156000.0

# Computed fields are included in serialization
print(person.model_dump())
# {
#     'first_name': 'John',
#     'last_name': 'Doe', 
#     'birth_date': datetime.date(1990, 5, 15),
#     'skills': ['Python', 'FastAPI', 'PostgreSQL'],
#     'hourly_rate': 75.0,
#     'full_name': 'John Doe',
#     'age': 34,
#     'skill_count': 3,
#     'annual_salary_estimate': 156000.0
# }
```

### 2. Computed Fields with Complex Logic

```python
from pydantic import BaseModel, computed_field, Field
from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum

class TaskStatus(str, Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    BLOCKED = "blocked"

class Task(BaseModel):
    id: str
    title: str
    description: str
    status: TaskStatus
    priority: int = Field(ge=1, le=5)  # 1 = lowest, 5 = highest
    estimated_hours: float
    actual_hours: float = 0.0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    due_date: Optional[datetime] = None
    dependencies: List[str] = Field(default_factory=list)  # Task IDs
    tags: List[str] = Field(default_factory=list)

class Project(BaseModel):
    name: str
    tasks: List[Task]
    
    @computed_field
    @property
    def total_tasks(self) -> int:
        """Total number of tasks"""
        return len(self.tasks)
    
    @computed_field
    @property
    def task_status_summary(self) -> Dict[str, int]:
        """Count of tasks by status"""
        summary = {status.value: 0 for status in TaskStatus}
        for task in self.tasks:
            summary[task.status.value] += 1
        return summary
    
    @computed_field
    @property
    def completion_percentage(self) -> float:
        """Percentage of completed tasks"""
        if not self.tasks:
            return 0.0
        done_count = sum(1 for task in self.tasks if task.status == TaskStatus.DONE)
        return round((done_count / len(self.tasks)) * 100, 2)
    
    @computed_field
    @property
    def estimated_total_hours(self) -> float:
        """Total estimated hours for all tasks"""
        return sum(task.estimated_hours for task in self.tasks)
    
    @computed_field
    @property
    def actual_total_hours(self) -> float:
        """Total actual hours spent on all tasks"""
        return sum(task.actual_hours for task in self.tasks)
    
    @computed_field
    @property
    def hour_variance(self) -> float:
        """Difference between actual and estimated hours"""
        return self.actual_total_hours - self.estimated_total_hours
    
    @computed_field
    @property
    def high_priority_tasks(self) -> List[str]:
        """IDs of high priority tasks (priority 4 or 5)"""
        return [task.id for task in self.tasks if task.priority >= 4]
    
    @computed_field
    @property
    def overdue_tasks(self) -> List[str]:
        """IDs of overdue tasks"""
        now = datetime.utcnow()
        return [
            task.id for task in self.tasks 
            if task.due_date and task.due_date < now and task.status != TaskStatus.DONE
        ]
    
    @computed_field
    @property
    def blocked_tasks(self) -> List[str]:
        """IDs of blocked tasks"""
        return [task.id for task in self.tasks if task.status == TaskStatus.BLOCKED]

# Usage
project_data = {
    "name": "Website Redesign",
    "tasks": [
        {
            "id": "task-1",
            "title": "Design mockups",
            "description": "Create initial design mockups",
            "status": "done",
            "priority": 4,
            "estimated_hours": 20.0,
            "actual_hours": 22.5,
            "due_date": "2024-01-15T10:00:00Z"
        },
        {
            "id": "task-2", 
            "title": "Frontend implementation",
            "description": "Implement the frontend based on designs",
            "status": "in_progress",
            "priority": 5,
            "estimated_hours": 40.0,
            "actual_hours": 15.0,
            "due_date": "2024-02-01T17:00:00Z"
        },
        {
            "id": "task-3",
            "title": "Backend API",
            "description": "Develop backend API endpoints",
            "status": "todo", 
            "priority": 3,
            "estimated_hours": 30.0,
            "actual_hours": 0.0
        }
    ]
}

project = Project.model_validate(project_data)
print(f"Project: {project.name}")
print(f"Total tasks: {project.total_tasks}")
print(f"Status summary: {project.task_status_summary}")
print(f"Completion: {project.completion_percentage}%")
print(f"Estimated hours: {project.estimated_total_hours}")
print(f"Actual hours: {project.actual_total_hours}")
print(f"Hour variance: {project.hour_variance}")
print(f"High priority tasks: {project.high_priority_tasks}")
```

## 📤 Advanced Serialization

### 1. Duck-Typing Serialization (v2.7+)

Duck-typing serialization allows more flexible serialization behavior.

```python
from pydantic import BaseModel, ConfigDict
from typing import Union, Any, Dict

class FlexibleModel(BaseModel):
    model_config = ConfigDict(
        # Enable duck-typing serialization
        ser_json_inf_nan='constants'  # Handle inf/nan in JSON
    )
    
    name: str
    data: Any  # Can be any type

class Document(BaseModel):
    title: str
    content: str
    
    def custom_serialization(self) -> Dict[str, Any]:
        """Custom serialization method"""
        return {
            "title": self.title.upper(),
            "content_length": len(self.content),
            "preview": self.content[:100] + "..." if len(self.content) > 100 else self.content
        }

class Container(BaseModel):
    model_config = ConfigDict(
        # Enable duck-typing for all fields
        arbitrary_types_allowed=True
    )
    
    items: list[Union[FlexibleModel, Document, Dict, str]]
    
    def model_dump_custom(self, **kwargs) -> Dict[str, Any]:
        """Custom serialization with duck-typing"""
        result = {"items": []}
        
        for item in self.items:
            if hasattr(item, 'custom_serialization'):
                # Use custom serialization if available
                result["items"].append(item.custom_serialization())
            elif hasattr(item, 'model_dump'):
                # Use Pydantic model serialization
                result["items"].append(item.model_dump())
            else:
                # Fallback to default representation
                result["items"].append(item)
        
        return result

# Usage
container_data = {
    "items": [
        {"name": "Flexible Item", "data": {"nested": "data"}},
        {"title": "Sample Document", "content": "This is a long document with lots of content that will be truncated in the preview"},
        {"arbitrary": "dictionary"},
        "plain string item"
    ]
}

container = Container.model_validate(container_data)
serialized = container.model_dump_custom()
print(serialized)
```

### 2. Serialization with Context (v2.7+)

```python
from pydantic import BaseModel, field_serializer, model_serializer
from typing import Any, Dict

class User(BaseModel):
    id: int
    username: str
    email: str
    password_hash: str
    is_admin: bool
    
    @field_serializer('password_hash')
    def serialize_password(self, value: str, _info) -> str:
        """Never serialize actual password hash"""
        return "[REDACTED]"
    
    @field_serializer('email')
    def serialize_email(self, value: str, _info) -> str:
        """Conditionally hide email based on context"""
        context = _info.context if _info and hasattr(_info, 'context') else {}
        hide_email = context.get('hide_email', False)
        
        if hide_email:
            local, domain = value.split('@')
            return f"{local[0]}***@{domain}"
        return value
    
    @model_serializer(mode='wrap')
    def serialize_model(self, serializer, info) -> Dict[str, Any]:
        """Custom model-level serialization with context"""
        context = info.context if info and hasattr(info, 'context') else {}
        
        # Get base serialization
        data = serializer(self)
        
        # Add computed fields based on context
        if context.get('include_permissions', False):
            data['permissions'] = ['read', 'write'] if self.is_admin else ['read']
        
        if context.get('include_profile_url', False):
            data['profile_url'] = f"/users/{self.username}"
        
        # Remove sensitive fields based on context
        if context.get('public_view', False):
            data.pop('password_hash', None)
            data.pop('is_admin', None)
        
        return data

# Usage with different contexts
user_data = {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com", 
    "password_hash": "hashed_password_here",
    "is_admin": True
}

user = User.model_validate(user_data)

# Internal/admin view
admin_context = {
    'include_permissions': True,
    'include_profile_url': True,
    'hide_email': False,
    'public_view': False
}

admin_data = user.model_dump(context=admin_context)
print("Admin view:", admin_data)

# Public view
public_context = {
    'include_permissions': False,
    'include_profile_url': True,
    'hide_email': True,
    'public_view': True
}

public_data = user.model_dump(context=public_context)
print("Public view:", public_data)
```

### 3. Custom Serializers

```python
from pydantic import BaseModel, field_serializer
from datetime import datetime, date
from decimal import Decimal
from typing import Optional

class Product(BaseModel):
    name: str
    price: Decimal
    created_at: datetime
    sale_date: Optional[date] = None
    tags: list[str]
    
    @field_serializer('price')
    def serialize_price(self, value: Decimal) -> str:
        """Serialize price as formatted string"""
        return f"${value:.2f}"
    
    @field_serializer('created_at')
    def serialize_created_at(self, value: datetime) -> str:
        """Serialize datetime in ISO format"""
        return value.isoformat()
    
    @field_serializer('sale_date')
    def serialize_sale_date(self, value: Optional[date]) -> Optional[str]:
        """Serialize date as string if present"""
        return value.isoformat() if value else None
    
    @field_serializer('tags')
    def serialize_tags(self, value: list[str]) -> str:
        """Serialize tags as comma-separated string"""
        return ", ".join(value)

# Usage
product_data = {
    "name": "Laptop",
    "price": Decimal("999.99"),
    "created_at": datetime(2024, 1, 15, 10, 30, 0),
    "sale_date": date(2024, 2, 1),
    "tags": ["electronics", "computers", "portable"]
}

product = Product.model_validate(product_data)
serialized = product.model_dump()
print(serialized)
# {
#     'name': 'Laptop',
#     'price': '$999.99',
#     'created_at': '2024-01-15T10:30:00',
#     'sale_date': '2024-02-01',
#     'tags': 'electronics, computers, portable'
# }
```

## 🎯 Advanced Validation Patterns

### 1. Cross-Field Validation

```python
from pydantic import BaseModel, model_validator, Field
from typing import Optional
from datetime import datetime

class BookingRequest(BaseModel):
    customer_email: str
    check_in: datetime
    check_out: datetime
    room_type: str = Field(..., pattern=r'^(standard|deluxe|suite)$')
    guests: int = Field(ge=1, le=10)
    special_requests: Optional[str] = None
    
    @model_validator(mode='after')
    @classmethod
    def validate_booking_logic(cls, model: 'BookingRequest') -> 'BookingRequest':
        """Complex cross-field validation"""
        
        # Check date logic
        if model.check_out <= model.check_in:
            raise ValueError('Check-out must be after check-in')
        
        # Validate booking duration
        duration = (model.check_out - model.check_in).days
        if duration > 30:
            raise ValueError('Bookings cannot exceed 30 days')
        
        # Room capacity validation
        room_capacity = {
            'standard': 2,
            'deluxe': 4, 
            'suite': 6
        }
        
        max_guests = room_capacity[model.room_type]
        if model.guests > max_guests:
            raise ValueError(f'{model.room_type} rooms can accommodate maximum {max_guests} guests')
        
        # Advance booking validation
        now = datetime.now()
        if model.check_in < now:
            raise ValueError('Cannot book dates in the past')
        
        advance_days = (model.check_in - now).days
        if advance_days > 365:
            raise ValueError('Cannot book more than 1 year in advance')
        
        return model
```

### 2. Conditional Validation

```python
from pydantic import BaseModel, field_validator, model_validator, ValidationInfo
from typing import Optional, Literal

class PaymentDetails(BaseModel):
    payment_method: Literal['credit_card', 'paypal', 'bank_transfer']
    
    # Credit card fields
    card_number: Optional[str] = None
    card_expiry: Optional[str] = None
    card_cvv: Optional[str] = None
    
    # PayPal fields
    paypal_email: Optional[str] = None
    
    # Bank transfer fields
    bank_account: Optional[str] = None
    routing_number: Optional[str] = None
    
    @model_validator(mode='after')
    @classmethod
    def validate_payment_method(cls, model: 'PaymentDetails') -> 'PaymentDetails':
        """Conditional validation based on payment method"""
        
        if model.payment_method == 'credit_card':
            required_fields = ['card_number', 'card_expiry', 'card_cvv']
            for field in required_fields:
                if not getattr(model, field):
                    raise ValueError(f'{field} is required for credit card payments')
            
            # Validate card number (basic Luhn algorithm check)
            card_num = model.card_number.replace(' ', '').replace('-', '')
            if not card_num.isdigit() or len(card_num) not in [13, 14, 15, 16, 17, 18, 19]:
                raise ValueError('Invalid card number format')
            
            # Validate expiry format (MM/YY)
            if not re.match(r'^\d{2}/\d{2}$', model.card_expiry):
                raise ValueError('Card expiry must be in MM/YY format')
            
            # Validate CVV
            if not (model.card_cvv.isdigit() and len(model.card_cvv) in [3, 4]):
                raise ValueError('CVV must be 3 or 4 digits')
        
        elif model.payment_method == 'paypal':
            if not model.paypal_email:
                raise ValueError('PayPal email is required for PayPal payments')
            
            # Validate email format
            email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            if not re.match(email_pattern, model.paypal_email):
                raise ValueError('Invalid PayPal email format')
        
        elif model.payment_method == 'bank_transfer':
            if not model.bank_account:
                raise ValueError('Bank account is required for bank transfers')
            if not model.routing_number:
                raise ValueError('Routing number is required for bank transfers')
            
            # Validate routing number (9 digits for US)
            if not (model.routing_number.isdigit() and len(model.routing_number) == 9):
                raise ValueError('Routing number must be 9 digits')
        
        return model
```

### 3. Async Validation Context

```python
from pydantic import BaseModel, field_validator, ValidationInfo
from typing import Optional, Set
import asyncio

class AsyncValidatedUser(BaseModel):
    username: str
    email: str
    
    @field_validator('username')
    @classmethod
    def validate_username_sync(cls, v: str, info: ValidationInfo) -> str:
        """Synchronous validation that can use async context"""
        context = info.context or {}
        
        # Get async validation results from context
        existing_usernames = context.get('existing_usernames', set())
        
        if v.lower() in existing_usernames:
            raise ValueError('Username already exists')
        
        return v.lower()
    
    @field_validator('email')
    @classmethod 
    def validate_email_sync(cls, v: str, info: ValidationInfo) -> str:
        """Email validation using async context"""
        context = info.context or {}
        
        # Get async validation results from context
        existing_emails = context.get('existing_emails', set())
        
        if v.lower() in existing_emails:
            raise ValueError('Email already registered')
        
        return v.lower()

# Async validation helper
async def validate_user_with_db_check(user_data: dict) -> AsyncValidatedUser:
    """Validate user with async database checks"""
    
    async def get_existing_usernames() -> Set[str]:
        """Simulate async database query"""
        await asyncio.sleep(0.1)  # Simulate DB query
        return {'admin', 'root', 'test', 'user1'}
    
    async def get_existing_emails() -> Set[str]:
        """Simulate async database query"""
        await asyncio.sleep(0.1)  # Simulate DB query
        return {'admin@example.com', 'test@example.com'}
    
    # Perform async validations
    existing_usernames, existing_emails = await asyncio.gather(
        get_existing_usernames(),
        get_existing_emails()
    )
    
    # Create validation context
    context = {
        'existing_usernames': existing_usernames,
        'existing_emails': existing_emails
    }
    
    # Validate with context
    return AsyncValidatedUser.model_validate(user_data, context=context)

# Usage
async def main():
    user_data = {
        "username": "newuser",
        "email": "newuser@example.com"
    }
    
    try:
        user = await validate_user_with_db_check(user_data)
        print(f"User validated: {user}")
    except ValueError as e:
        print(f"Validation error: {e}")

# Run async validation
# asyncio.run(main())
```

---

*Next: [Web Applications](./pydantic-v2-web-applications.md) - FastAPI integration and API patterns with Pydantic v2*
# Pydantic v2 Fundamentals and Migration Guide

## Overview

Pydantic v2 represents a major evolution in Python data validation, with the core rewritten in Rust for dramatically improved performance. This guide covers the fundamental concepts, key changes from v1, and practical migration strategies for modern web applications.

## 🚀 What's New in Pydantic v2

### Performance Revolution

**Rust-Powered Core**
- Core validation logic rewritten in Rust
- Among the fastest data validation libraries for Python
- 2x improvement in schema build times (v2.11)
- 2-5x reduction in memory usage for complex models

**Real-World Impact**
```python
# v2.11 Performance Improvements
# - 67% improvement for FastAPI startup with parametrized generics
# - 5-15% schema build time improvements
# - Up to 7x reduction in total allocations
# - 2-4x reduction in resident memory size
```

### Modern Python Support

**Python 3.12+ Features**
- PEP 695 generic syntax support
- Python 3.13 compatibility
- Enhanced type parameter syntax for models

```python
# New PEP 695 Syntax (Python 3.12+)
from typing import Generic

# Old way
class Response(BaseModel, Generic[T]):
    data: T

# New PEP 695 way  
class Response[T](BaseModel):
    data: T
```

## 📦 Installation and Setup

### Package Structure Changes

**Pydantic Core**
```bash
# Main package
pip install pydantic

# For settings management (now separate)
pip install pydantic-settings
```

**Import Changes**
```python
# v1 imports
from pydantic import BaseSettings  # ❌ Deprecated

# v2 imports
from pydantic import BaseModel     # ✅ Core functionality
from pydantic_settings import BaseSettings  # ✅ Settings functionality
```

### Version Compatibility

```python
# Check your Pydantic version
import pydantic
print(pydantic.__version__)  # Should be 2.11+ for latest features

# Version-specific features
if pydantic.VERSION >= (2, 11):
    # Use latest performance optimizations
    pass
```

## 🔄 Key Differences from v1

### 1. Method Name Changes

**Validation Methods**
```python
# v1 methods (deprecated)
User.parse_obj(data)           # ❌
User.parse_raw(json_str)       # ❌
user.json()                    # ❌

# v2 methods
User.model_validate(data)      # ✅
User.model_validate_json(json_str)  # ✅
user.model_dump_json()         # ✅
```

**Complete Method Mapping**
```python
# v1 → v2 Migration
class UserV2(BaseModel):
    name: str
    age: int

# Validation
data = {"name": "John", "age": 30}
user = UserV2.model_validate(data)  # was: parse_obj()

# JSON validation
json_data = '{"name": "John", "age": 30}'
user = UserV2.model_validate_json(json_data)  # was: parse_raw()

# Serialization
user_dict = user.model_dump()  # was: .dict()
user_json = user.model_dump_json()  # was: .json()

# Schema generation
schema = UserV2.model_json_schema()  # was: .schema()
```

### 2. Configuration Changes

**v1 Config Class (Deprecated)**
```python
# v1 approach ❌
class User(BaseModel):
    name: str
    
    class Config:
        str_strip_whitespace = True
        validate_assignment = True
```

**v2 ConfigDict (Current)**
```python
from pydantic import BaseModel, ConfigDict

# v2 approach ✅
class User(BaseModel):
    model_config = ConfigDict(
        str_strip_whitespace=True,
        validate_assignment=True,
        # New v2 options
        extra='forbid',
        frozen=True
    )
    
    name: str
```

**Common Configuration Options**
```python
from pydantic import BaseModel, ConfigDict

class APIModel(BaseModel):
    model_config = ConfigDict(
        # Validation behavior
        extra='forbid',           # Reject extra fields
        validate_assignment=True, # Validate on assignment
        str_strip_whitespace=True,# Auto-strip strings
        
        # Performance options
        validate_default=True,    # Validate default values
        use_enum_values=True,     # Use enum values in serialization
        
        # JSON schema
        title='API Model',
        description='Base model for API endpoints'
    )
```

### 3. Validator Decorator Changes

**v1 Validators (Deprecated)**
```python
# v1 approach ❌
from pydantic import validator

class User(BaseModel):
    name: str
    age: int
    
    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.title()
    
    @validator('age')
    def validate_age(cls, v, values):
        if v < 0:
            raise ValueError('Age must be positive')
        return v
```

**v2 Validators (Current)**
```python
from pydantic import BaseModel, field_validator, model_validator
from pydantic_core import ValidationInfo

class User(BaseModel):
    name: str
    age: int
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.title()
    
    @field_validator('age')
    @classmethod
    def validate_age(cls, v: int) -> int:
        if v < 0:
            raise ValueError('Age must be positive')
        return v
    
    @model_validator(mode='after')
    @classmethod
    def validate_model(cls, model: 'User') -> 'User':
        # Access to the entire model
        if model.age > 100 and 'senior' not in model.name.lower():
            model.name = f"Senior {model.name}"
        return model
```

## 🏗️ Modern Model Patterns

### 1. Basic Model Structure

```python
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import datetime
import uuid

class User(BaseModel):
    model_config = ConfigDict(
        extra='forbid',
        validate_assignment=True,
        str_strip_whitespace=True
    )
    
    # Required fields
    id: uuid.UUID = Field(default_factory=uuid.uuid4)
    email: str = Field(..., pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    name: str = Field(..., min_length=1, max_length=100)
    
    # Optional fields with defaults
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Optional fields
    last_login: Optional[datetime] = None
    profile_picture_url: Optional[str] = Field(None, regex=r'^https?://.+')
```

### 2. Computed Fields (New in v2)

```python
from pydantic import computed_field

class User(BaseModel):
    first_name: str
    last_name: str
    birth_date: datetime
    
    @computed_field
    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"
    
    @computed_field
    @property
    def age(self) -> int:
        today = datetime.now().date()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )

# Usage
user = User(
    first_name="John",
    last_name="Doe", 
    birth_date=datetime(1990, 5, 15)
)
print(user.full_name)  # "John Doe"
print(user.age)        # Calculated age
print(user.model_dump())  # Includes computed fields
```

### 3. Enhanced Field Types

```python
from pydantic import BaseModel, Field, EmailStr, HttpUrl
from typing import Annotated
from decimal import Decimal

class Product(BaseModel):
    # String constraints
    name: Annotated[str, Field(min_length=1, max_length=200)]
    description: Annotated[str, Field(max_length=1000)]
    
    # Numeric constraints
    price: Annotated[Decimal, Field(gt=0, decimal_places=2)]
    quantity: Annotated[int, Field(ge=0)]
    
    # Specialized types
    contact_email: EmailStr
    website: HttpUrl
    
    # Complex validation
    sku: Annotated[str, Field(pattern=r'^[A-Z]{3}-\d{4}$')]
```

## 🔧 Migration Strategies

### 1. Gradual Migration Approach

**Step 1: Update Imports**
```python
# Replace old imports
# from pydantic import BaseSettings  # Remove
from pydantic_settings import BaseSettings  # Add

# Update method calls in existing code
# user.dict() → user.model_dump()
# User.parse_obj() → User.model_validate()
```

**Step 2: Replace Deprecated Methods**
```python
# Create migration helper
def migrate_model_methods(model_class):
    """Helper to support both v1 and v2 patterns during migration"""
    
    # Add v1-style methods that delegate to v2
    if not hasattr(model_class, 'parse_obj'):
        model_class.parse_obj = classmethod(
            lambda cls, obj: cls.model_validate(obj)
        )
    
    if not hasattr(model_class, 'parse_raw'):
        model_class.parse_raw = classmethod(
            lambda cls, data: cls.model_validate_json(data)
        )
    
    return model_class

# Apply to existing models during migration
@migrate_model_methods
class LegacyUser(BaseModel):
    name: str
```

**Step 3: Update Configuration**
```python
# Convert v1 Config to v2 ConfigDict
from pydantic import BaseModel, ConfigDict

# Before (v1)
class OldModel(BaseModel):
    class Config:
        allow_population_by_field_name = True
        extra = 'forbid'

# After (v2)
class NewModel(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,  # New name
        extra='forbid'
    )
```

### 2. Automated Migration Tools

**Using Pydantic's Migration Tool**
```bash
# Install migration tools
pip install pydantic[migration]

# Run automated migration
python -m pydantic.v1_migration path/to/your/code
```

**Custom Migration Script**
```python
import ast
import re

def migrate_pydantic_file(file_path):
    """Migrate a single Python file from v1 to v2"""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace common patterns
    replacements = {
        r'\.dict\(\)': '.model_dump()',
        r'\.json\(\)': '.model_dump_json()',
        r'\.parse_obj\(': '.model_validate(',
        r'\.parse_raw\(': '.model_validate_json(',
        r'@validator\(': '@field_validator(',
        r'from pydantic import BaseSettings': 'from pydantic_settings import BaseSettings'
    }
    
    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content)
    
    with open(file_path, 'w') as f:
        f.write(content)
```

### 3. Testing Migration

```python
import pytest
from pydantic import ValidationError

def test_model_migration():
    """Test that v2 models work with existing data"""
    
    # Test data that worked in v1
    test_data = {
        "name": "John Doe",
        "email": "john@example.com",
        "age": 30
    }
    
    # Should work in v2
    user = User.model_validate(test_data)
    assert user.name == "John Doe"
    
    # Test serialization compatibility
    serialized = user.model_dump()
    restored = User.model_validate(serialized)
    assert restored == user
    
    # Test JSON compatibility
    json_str = user.model_dump_json()
    from_json = User.model_validate_json(json_str)
    assert from_json == user

def test_validation_behavior():
    """Ensure validation behavior is consistent"""
    
    # Invalid data should still raise ValidationError
    with pytest.raises(ValidationError):
        User.model_validate({"name": "", "email": "invalid"})
```

## ⚡ Performance Optimization

### 1. Model Reuse Patterns

```python
from functools import lru_cache
from pydantic import BaseModel

class OptimizedModel(BaseModel):
    name: str
    value: int

# Cache model creation for repeated use
@lru_cache(maxsize=128)
def create_cached_model(name: str, value: int):
    return OptimizedModel(name=name, value=value)

# Reuse schemas for better performance
cached_schema = OptimizedModel.model_json_schema()
```

### 2. Build Time Optimization

```python
# Pre-build models when possible
from typing import Dict, Type
from pydantic import BaseModel

class ModelRegistry:
    """Registry for pre-built models"""
    _models: Dict[str, Type[BaseModel]] = {}
    
    @classmethod
    def register(cls, name: str, model_class: Type[BaseModel]):
        # Pre-build the model schema
        model_class.model_json_schema()
        cls._models[name] = model_class
    
    @classmethod
    def get(cls, name: str) -> Type[BaseModel]:
        return cls._models[name]

# Register commonly used models
ModelRegistry.register('user', User)
ModelRegistry.register('product', Product)
```

### 3. Memory Optimization

```python
# Use __slots__ for memory efficiency in data classes
from pydantic import BaseModel
from pydantic.dataclasses import dataclass

# For models that don't need full BaseModel features
@dataclass
class LightweightData:
    __slots__ = ('name', 'value')
    name: str
    value: int

# Use model_validate instead of creating instances directly
def efficient_validation(data_list):
    """Validate many objects efficiently"""
    model_class = User
    
    # Batch validation is more efficient
    return [model_class.model_validate(item) for item in data_list]
```

## 📊 Monitoring and Debugging

### 1. Validation Context

```python
from pydantic import BaseModel, ValidationInfo, field_validator

class ContextAwareModel(BaseModel):
    value: str
    
    @field_validator('value')
    @classmethod
    def validate_value(cls, v: str, info: ValidationInfo) -> str:
        # Access validation context
        if info.context:
            max_length = info.context.get('max_length', 100)
            if len(v) > max_length:
                raise ValueError(f'Value too long (max: {max_length})')
        
        return v

# Usage with context
data = {"value": "some long text"}
model = ContextAwareModel.model_validate(
    data, 
    context={'max_length': 10}
)
```

### 2. Error Handling

```python
from pydantic import ValidationError

def handle_validation_errors(data):
    """Comprehensive error handling"""
    try:
        return User.model_validate(data)
    except ValidationError as e:
        # v2 provides detailed error information
        for error in e.errors():
            print(f"Field: {error['loc']}")
            print(f"Error: {error['msg']}")
            print(f"Input: {error['input']}")
            print(f"Type: {error['type']}")
        raise
```

## 🔮 Future-Proofing

### 1. Using Latest Features

```python
# Stay current with latest Pydantic releases
from pydantic import BaseModel, ConfigDict, computed_field
from typing import Self

class FutureProofModel(BaseModel):
    model_config = ConfigDict(
        # Enable latest features
        extra='forbid',
        validate_assignment=True,
        use_enum_values=True,
        # Performance optimizations
        validate_default=True
    )
    
    name: str
    
    @computed_field
    @property 
    def display_name(self) -> str:
        return self.name.title()
    
    def clone_with_updates(self, **updates) -> Self:
        """Type-safe cloning with updates"""
        current_data = self.model_dump()
        current_data.update(updates)
        return self.__class__.model_validate(current_data)
```

### 2. Integration Patterns

```python
# Design for framework integration
class APIBaseModel(BaseModel):
    """Base model for API endpoints"""
    model_config = ConfigDict(
        # API-friendly configuration
        extra='forbid',
        str_strip_whitespace=True,
        validate_assignment=True,
        # JSON schema optimization
        title=None,  # Will be set by subclasses
        description=None
    )
    
    def to_api_response(self) -> dict:
        """Convert to API response format"""
        return self.model_dump(exclude_none=True)
```

---

*Next: [Settings and Configuration](./pydantic-v2-settings-configuration.md) - Modern environment variable management with pydantic-settings*
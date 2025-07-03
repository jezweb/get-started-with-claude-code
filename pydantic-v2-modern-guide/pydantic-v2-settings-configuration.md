# Pydantic v2 Settings and Configuration

## Overview

Pydantic v2 introduces a dedicated `pydantic-settings` package for robust configuration management. This guide covers modern patterns for environment variables, settings validation, and configuration best practices for web applications in 2025.

## 📦 Installation and Setup

### Package Installation

```bash
# Core Pydantic (required)
pip install pydantic

# Settings package (separate as of v2)
pip install pydantic-settings

# For advanced features
pip install pydantic[email,dotenv]  # Optional extras
```

### Import Changes from v1

```python
# v1 (deprecated)
from pydantic import BaseSettings  # ❌ No longer available

# v2 (current)
from pydantic_settings import BaseSettings  # ✅ Correct import
from pydantic import BaseModel, Field
```

## 🔧 Basic Settings Patterns

### 1. Simple Configuration

```python
from pydantic_settings import BaseSettings
from pydantic import Field

class AppSettings(BaseSettings):
    # Basic configuration
    app_name: str = "My Application"
    debug: bool = False
    port: int = 8000
    
    # Required environment variables
    database_url: str = Field(..., description="Database connection string")
    secret_key: str = Field(..., min_length=32, description="Secret key for sessions")
    
    # Optional with defaults
    log_level: str = Field(default="INFO", description="Logging level")
    max_connections: int = Field(default=100, ge=1, le=1000)

# Usage
settings = AppSettings()
print(settings.app_name)  # From default or environment
print(settings.database_url)  # Must be set in environment or will raise error
```

### 2. Environment Variable Mapping

```python
# Environment variables are automatically mapped:
# APP_NAME -> app_name
# DATABASE_URL -> database_url
# SECRET_KEY -> secret_key

# Set in your environment or .env file:
# APP_NAME=Production App
# DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
# SECRET_KEY=your-super-secret-key-here-32-chars-min
```

## 🏗️ Advanced Configuration Patterns

### 1. Modern SettingsConfigDict

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
from typing import List, Optional

class AdvancedSettings(BaseSettings):
    model_config = SettingsConfigDict(
        # Environment file configuration
        env_file='.env',
        env_file_encoding='utf-8',
        
        # Environment variable behavior
        case_sensitive=False,           # APP_NAME and app_name both work
        env_nested_delimiter='__',      # Support nested: DB__HOST -> db.host
        env_ignore_empty=True,          # Ignore empty env vars
        
        # Source priority
        env_prefix='APP_',              # Only read APP_* variables
        
        # Validation behavior
        validate_default=True,          # Validate default values
        extra='forbid',                 # Reject unknown fields
        
        # Documentation
        title="Application Settings",
        description="Configuration for the application"
    )
    
    # Application settings
    name: str = Field(default="MyApp", description="Application name")
    version: str = Field(default="1.0.0", pattern=r'^\d+\.\d+\.\d+$')
    debug: bool = Field(default=False, description="Debug mode")
    
    # Server configuration
    host: str = Field(default="0.0.0.0", description="Host to bind to")
    port: int = Field(default=8000, ge=1, le=65535, description="Port to bind to")
    
    # Database configuration
    database_url: str = Field(..., description="Database connection string")
    database_pool_size: int = Field(default=10, ge=1, le=100)
    
    # Security
    secret_key: str = Field(..., min_length=32, description="Secret key")
    allowed_hosts: List[str] = Field(default_factory=list, description="Allowed host names")
    
    # Optional features
    redis_url: Optional[str] = Field(default=None, description="Redis connection string")
    
# Environment variables with prefix:
# APP_NAME=Production App
# APP_DEBUG=true
# APP_DATABASE_URL=postgresql://...
# APP_SECRET_KEY=your-secret-key
```

### 2. Nested Configuration

```python
from pydantic import BaseModel

class DatabaseConfig(BaseModel):
    host: str = "localhost"
    port: int = 5432
    username: str = "postgres"
    password: str = Field(..., min_length=8)
    database: str = "myapp"
    pool_size: int = Field(default=10, ge=1, le=100)
    
    @property
    def url(self) -> str:
        return f"postgresql://{self.username}:{self.password}@{self.host}:{self.port}/{self.database}"

class RedisConfig(BaseModel):
    host: str = "localhost"
    port: int = 6379
    password: Optional[str] = None
    db: int = 0
    
    @property
    def url(self) -> str:
        auth = f":{self.password}@" if self.password else ""
        return f"redis://{auth}{self.host}:{self.port}/{self.db}"

class ApplicationSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        env_nested_delimiter='__',  # Enable nested configuration
        case_sensitive=False
    )
    
    # Top-level settings
    app_name: str = "MyApp"
    debug: bool = False
    
    # Nested configuration
    database: DatabaseConfig = Field(default_factory=DatabaseConfig)
    redis: RedisConfig = Field(default_factory=RedisConfig)

# Environment variables for nested config:
# DATABASE__HOST=db.example.com
# DATABASE__PORT=5432
# DATABASE__PASSWORD=secretpassword
# REDIS__HOST=redis.example.com
# REDIS__PASSWORD=redispassword

settings = ApplicationSettings()
print(settings.database.url)  # Built from nested config
print(settings.redis.url)     # Built from nested config
```

### 3. Multiple Environment Files

```python
import os
from pathlib import Path

class EnvironmentSettings(BaseSettings):
    model_config = SettingsConfigDict(
        # Multiple environment files (later files override earlier ones)
        env_file=[
            '.env',                    # Base configuration
            f'.env.{os.getenv("ENV", "development")}',  # Environment-specific
            '.env.local'               # Local overrides (git-ignored)
        ],
        env_file_encoding='utf-8'
    )
    
    # Configuration
    environment: str = Field(default="development", description="Environment name")
    app_name: str = "MyApp"
    debug: bool = True
    
    @property
    def is_production(self) -> bool:
        return self.environment == "production"
    
    @property
    def is_development(self) -> bool:
        return self.environment == "development"

# File structure:
# .env                 # Base settings
# .env.development     # Development overrides
# .env.production      # Production overrides  
# .env.local          # Local developer overrides (git-ignored)
```

## 🔐 Security and Validation

### 1. Sensitive Data Handling

```python
from pydantic import Field, SecretStr, validator
from typing import Optional

class SecureSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        case_sensitive=False
    )
    
    # Regular settings
    app_name: str = "Secure App"
    
    # Sensitive data (won't be printed/logged)
    database_password: SecretStr = Field(..., description="Database password")
    api_key: SecretStr = Field(..., description="External API key")
    jwt_secret: SecretStr = Field(..., min_length=32, description="JWT signing secret")
    
    # Optional sensitive data
    redis_password: Optional[SecretStr] = Field(default=None, description="Redis password")
    
    def get_database_url(self) -> str:
        """Build database URL with secret password"""
        return f"postgresql://user:{self.database_password.get_secret_value()}@localhost:5432/mydb"

# Usage
settings = SecureSettings()
print(settings.app_name)  # "Secure App"
print(settings.database_password)  # SecretStr('**********')
print(settings.get_database_url())  # Full URL with actual password
```

### 2. Custom Validation

```python
from pydantic import field_validator, model_validator
import re

class ValidatedSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    # Basic fields
    app_name: str
    email: str
    port: int
    allowed_hosts: List[str] = Field(default_factory=list)
    
    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        """Validate email format"""
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, v):
            raise ValueError('Invalid email format')
        return v.lower()
    
    @field_validator('port')
    @classmethod
    def validate_port(cls, v: int) -> int:
        """Validate port range"""
        if not 1 <= v <= 65535:
            raise ValueError('Port must be between 1 and 65535')
        return v
    
    @field_validator('allowed_hosts')
    @classmethod
    def validate_hosts(cls, v: List[str]) -> List[str]:
        """Validate host formats"""
        validated_hosts = []
        for host in v:
            # Simple hostname validation
            if not re.match(r'^[a-zA-Z0-9.-]+$', host):
                raise ValueError(f'Invalid hostname format: {host}')
            validated_hosts.append(host.lower())
        return validated_hosts
    
    @model_validator(mode='after')
    @classmethod
    def validate_production_requirements(cls, model: 'ValidatedSettings') -> 'ValidatedSettings':
        """Cross-field validation"""
        if 'production' in model.app_name.lower():
            if model.port == 8000:
                raise ValueError('Production apps should not use default port 8000')
            if not model.allowed_hosts:
                raise ValueError('Production apps must specify allowed hosts')
        return model
```

## ⚡ Performance Optimization

### 1. Cached Settings

```python
from functools import lru_cache
from pydantic_settings import BaseSettings

class OptimizedSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    app_name: str = "MyApp"
    database_url: str
    redis_url: str
    debug: bool = False

@lru_cache()
def get_settings() -> OptimizedSettings:
    """
    Cache settings to avoid re-reading environment/files.
    Use lru_cache to ensure settings are only loaded once.
    """
    return OptimizedSettings()

# Usage in FastAPI or other frameworks
def get_database_connection():
    settings = get_settings()  # Cached after first call
    return create_connection(settings.database_url)

# For testing, you can clear the cache
def override_settings_for_testing():
    get_settings.cache_clear()  # Clear cache
    # Set test environment variables
    os.environ['DATABASE_URL'] = 'sqlite:///test.db'
    return get_settings()
```

### 2. Lazy Loading

```python
from typing import Optional, Any

class LazySettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    # Basic settings loaded immediately
    app_name: str = "MyApp"
    debug: bool = False
    
    # Expensive settings loaded on demand
    _database_connection: Optional[Any] = None
    _redis_client: Optional[Any] = None
    
    database_url: str
    redis_url: str
    
    @property
    def database_connection(self):
        """Lazy-load database connection"""
        if self._database_connection is None:
            import database_library
            self._database_connection = database_library.connect(self.database_url)
        return self._database_connection
    
    @property
    def redis_client(self):
        """Lazy-load Redis client"""
        if self._redis_client is None:
            import redis
            self._redis_client = redis.from_url(self.redis_url)
        return self._redis_client
```

## 🧪 Testing Patterns

### 1. Test Configuration

```python
import pytest
from pydantic_settings import BaseSettings
import tempfile
import os

class TestSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env.test',
        case_sensitive=False
    )
    
    # Test-specific defaults
    database_url: str = "sqlite:///test.db"
    redis_url: str = "redis://localhost:6379/1"  # Different DB for tests
    debug: bool = True
    secret_key: str = "test-secret-key-32-characters-long"

@pytest.fixture
def test_settings():
    """Provide test settings for tests"""
    return TestSettings()

@pytest.fixture
def temp_env_file():
    """Create temporary .env file for testing"""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.env', delete=False) as f:
        f.write("""
        APP_NAME=Test App
        DEBUG=true
        DATABASE_URL=sqlite:///test.db
        SECRET_KEY=test-secret-key-32-characters-long
        """)
        temp_path = f.name
    
    yield temp_path
    
    # Cleanup
    os.unlink(temp_path)

def test_settings_validation(temp_env_file):
    """Test settings validation with temporary file"""
    
    class TempSettings(BaseSettings):
        model_config = SettingsConfigDict(env_file=temp_env_file)
        
        app_name: str
        debug: bool
        database_url: str
        secret_key: str
    
    settings = TempSettings()
    assert settings.app_name == "Test App"
    assert settings.debug is True
    assert "test.db" in settings.database_url

def test_settings_override():
    """Test environment variable override"""
    
    # Override environment for test
    test_env = {
        'APP_NAME': 'Override App',
        'DEBUG': 'false',
        'DATABASE_URL': 'postgresql://test',
        'SECRET_KEY': 'test-secret-key-32-characters-long'
    }
    
    with pytest.MonkeyPatch().context() as m:
        for key, value in test_env.items():
            m.setenv(key, value)
        
        settings = TestSettings()
        assert settings.app_name == 'Override App'
        assert settings.debug is False
```

### 2. Environment Mocking

```python
import os
from unittest.mock import patch

class MockableSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    api_endpoint: str = "https://api.example.com"
    api_key: str
    timeout: int = 30

def test_with_mocked_environment():
    """Test with completely mocked environment"""
    
    mock_env = {
        'API_ENDPOINT': 'https://test-api.example.com',
        'API_KEY': 'test-api-key',
        'TIMEOUT': '10'
    }
    
    with patch.dict(os.environ, mock_env, clear=True):
        settings = MockableSettings()
        assert settings.api_endpoint == 'https://test-api.example.com'
        assert settings.api_key == 'test-api-key'
        assert settings.timeout == 10

def test_partial_environment_override():
    """Test overriding only specific settings"""
    
    with patch.dict(os.environ, {'TIMEOUT': '5'}):
        settings = MockableSettings()
        assert settings.timeout == 5
        # Other settings use defaults or .env file
```

## 🔧 Integration with Web Frameworks

### 1. FastAPI Integration

```python
from fastapi import FastAPI, Depends
from functools import lru_cache

class APISettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    app_name: str = "FastAPI App"
    debug: bool = False
    database_url: str
    secret_key: str
    cors_origins: List[str] = Field(default_factory=list)

@lru_cache()
def get_settings() -> APISettings:
    return APISettings()

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    settings = get_settings()
    # Initialize database, Redis, etc.
    print(f"Starting {settings.app_name}")

@app.get("/info")
async def get_app_info(settings: APISettings = Depends(get_settings)):
    return {
        "app_name": settings.app_name,
        "debug": settings.debug,
        "version": "1.0.0"
    }
```

### 2. Django-Style Settings Module

```python
# settings/__init__.py
from .base import BaseSettings
from .development import DevelopmentSettings
from .production import ProductionSettings
import os

def get_settings():
    """Get settings based on environment"""
    env = os.getenv('ENVIRONMENT', 'development')
    
    if env == 'production':
        return ProductionSettings()
    elif env == 'staging':
        return StagingSettings()
    else:
        return DevelopmentSettings()

# settings/base.py
class BaseSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        case_sensitive=False
    )
    
    # Common settings
    app_name: str = "MyApp"
    secret_key: str
    database_url: str

# settings/development.py
class DevelopmentSettings(BaseSettings):
    debug: bool = True
    log_level: str = "DEBUG"
    
    # Development-specific defaults
    database_url: str = "sqlite:///dev.db"

# settings/production.py
class ProductionSettings(BaseSettings):
    debug: bool = False
    log_level: str = "WARNING"
    
    # Production requirements
    allowed_hosts: List[str] = Field(..., min_items=1)
```

## 📚 Advanced Patterns

### 1. Dynamic Configuration

```python
from typing import Dict, Any
import json

class DynamicSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    # Standard settings
    app_name: str = "Dynamic App"
    
    # JSON configuration from environment
    feature_flags: Dict[str, bool] = Field(default_factory=dict)
    api_limits: Dict[str, int] = Field(default_factory=dict)
    
    @field_validator('feature_flags', mode='before')
    @classmethod
    def parse_feature_flags(cls, v):
        if isinstance(v, str):
            return json.loads(v)
        return v
    
    @field_validator('api_limits', mode='before')
    @classmethod
    def parse_api_limits(cls, v):
        if isinstance(v, str):
            return json.loads(v)
        return v

# Environment variables:
# FEATURE_FLAGS={"new_ui": true, "beta_features": false}
# API_LIMITS={"requests_per_minute": 1000, "requests_per_hour": 10000}
```

### 2. Configuration Validation

```python
from pydantic import model_validator
from urllib.parse import urlparse

class ValidatedWebSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env')
    
    database_url: str
    redis_url: str
    allowed_hosts: List[str]
    cors_origins: List[str]
    
    @model_validator(mode='after')
    @classmethod
    def validate_urls(cls, model: 'ValidatedWebSettings') -> 'ValidatedWebSettings':
        """Validate URL formats"""
        
        # Validate database URL
        db_parsed = urlparse(model.database_url)
        if db_parsed.scheme not in ['postgresql', 'sqlite', 'mysql']:
            raise ValueError('Unsupported database scheme')
        
        # Validate Redis URL
        redis_parsed = urlparse(model.redis_url)
        if redis_parsed.scheme != 'redis':
            raise ValueError('Invalid Redis URL scheme')
        
        return model
    
    @model_validator(mode='after')
    @classmethod
    def validate_security(cls, model: 'ValidatedWebSettings') -> 'ValidatedWebSettings':
        """Validate security configuration"""
        
        # Ensure CORS origins don't include wildcards in production
        if any('*' in origin for origin in model.cors_origins):
            if not any(host in ['localhost', '127.0.0.1'] for host in model.allowed_hosts):
                raise ValueError('Wildcard CORS origins not allowed in production')
        
        return model
```

---

*Next: [Validation and Serialization](./pydantic-v2-validation-serialization.md) - Advanced validation patterns and serialization features*
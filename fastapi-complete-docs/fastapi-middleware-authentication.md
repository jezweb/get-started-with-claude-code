# FastAPI Middleware and Authentication

## Overview
This guide covers FastAPI middleware patterns, authentication systems, authorization mechanisms, and security best practices for building secure web applications.

## Middleware Fundamentals

### Basic Middleware Patterns
```python
from fastapi import FastAPI, Request, Response
from fastapi.middleware.base import BaseHTTPMiddleware
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.sessions import SessionMiddleware
import time
import uuid
from typing import Callable

app = FastAPI()

# Request logging middleware
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Log all incoming requests."""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Generate request ID
        request_id = str(uuid.uuid4())
        
        # Log request start
        start_time = time.time()
        print(f"[{request_id}] {request.method} {request.url} - Started")
        
        # Add request ID to request state
        request.state.request_id = request_id
        
        try:
            # Process request
            response = await call_next(request)
            
            # Log successful response
            duration = time.time() - start_time
            print(f"[{request_id}] Completed in {duration:.3f}s - Status: {response.status_code}")
            
            # Add custom headers
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Response-Time"] = f"{duration:.3f}s"
            
            return response
            
        except Exception as e:
            # Log error
            duration = time.time() - start_time
            print(f"[{request_id}] Error after {duration:.3f}s: {str(e)}")
            raise

# Rate limiting middleware
from collections import defaultdict
from datetime import datetime, timedelta

class RateLimitMiddleware(BaseHTTPMiddleware):
    """Simple rate limiting middleware."""
    
    def __init__(self, app, max_requests: int = 100, window_minutes: int = 1):
        super().__init__(app)
        self.max_requests = max_requests
        self.window = timedelta(minutes=window_minutes)
        self.requests = defaultdict(list)
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Get client IP
        client_ip = request.client.host
        now = datetime.now()
        
        # Clean old requests
        self.requests[client_ip] = [
            req_time for req_time in self.requests[client_ip]
            if now - req_time < self.window
        ]
        
        # Check rate limit
        if len(self.requests[client_ip]) >= self.max_requests:
            from fastapi import HTTPException
            raise HTTPException(
                status_code=429,
                detail=f"Rate limit exceeded. Max {self.max_requests} requests per {self.window.total_seconds() / 60} minutes"
            )
        
        # Add current request
        self.requests[client_ip].append(now)
        
        # Process request
        response = await call_next(request)
        
        # Add rate limit headers
        remaining = max(0, self.max_requests - len(self.requests[client_ip]))
        response.headers["X-RateLimit-Limit"] = str(self.max_requests)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(int((now + self.window).timestamp()))
        
        return response

# Security headers middleware
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to responses."""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)
        
        # Add security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        
        return response

# Error handling middleware
class ErrorHandlingMiddleware(BaseHTTPMiddleware):
    """Global error handling middleware."""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        try:
            return await call_next(request)
        except Exception as e:
            import traceback
            from fastapi.responses import JSONResponse
            
            # Log the error
            print(f"Unhandled error: {traceback.format_exc()}")
            
            # Return standardized error response
            return JSONResponse(
                status_code=500,
                content={
                    "error": "Internal Server Error",
                    "message": "An unexpected error occurred",
                    "request_id": getattr(request.state, "request_id", "unknown"),
                    "timestamp": datetime.now().isoformat()
                }
            )

# Add middleware to app
app.add_middleware(ErrorHandlingMiddleware)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RateLimitMiddleware, max_requests=100, window_minutes=1)
app.add_middleware(RequestLoggingMiddleware)

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://myapp.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# GZip compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Session middleware
app.add_middleware(
    SessionMiddleware,
    secret_key="your-secret-key-change-in-production",
    max_age=3600,  # 1 hour
    same_site="lax",
    https_only=False  # Set to True in production with HTTPS
)
```

### Advanced Middleware Patterns
```python
from contextlib import asynccontextmanager
import aioredis
import json
from typing import Optional, Dict, Any

# Database connection middleware
class DatabaseMiddleware(BaseHTTPMiddleware):
    """Provide database connection per request."""
    
    def __init__(self, app, database_url: str):
        super().__init__(app)
        self.database_url = database_url
        self.pool = None
    
    async def setup(self):
        """Setup database connection pool."""
        import asyncpg
        self.pool = await asyncpg.create_pool(self.database_url)
    
    async def cleanup(self):
        """Cleanup database connection pool."""
        if self.pool:
            await self.pool.close()
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        if not self.pool:
            await self.setup()
        
        async with self.pool.acquire() as connection:
            request.state.db = connection
            response = await call_next(request)
            return response

# Cache middleware
class CacheMiddleware(BaseHTTPMiddleware):
    """Simple HTTP response caching."""
    
    def __init__(self, app, redis_url: str = "redis://localhost:6379"):
        super().__init__(app)
        self.redis_url = redis_url
        self.redis = None
    
    async def setup(self):
        """Setup Redis connection."""
        self.redis = await aioredis.create_redis_pool(self.redis_url)
    
    async def cleanup(self):
        """Cleanup Redis connection."""
        if self.redis:
            self.redis.close()
            await self.redis.wait_closed()
    
    def _get_cache_key(self, request: Request) -> str:
        """Generate cache key for request."""
        return f"cache:{request.method}:{request.url}"
    
    def _should_cache(self, request: Request, response: Response) -> bool:
        """Determine if response should be cached."""
        return (
            request.method == "GET" and
            response.status_code == 200 and
            "no-cache" not in response.headers.get("cache-control", "")
        )
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        if not self.redis:
            await self.setup()
        
        # Check cache for GET requests
        if request.method == "GET":
            cache_key = self._get_cache_key(request)
            cached_response = await self.redis.get(cache_key)
            
            if cached_response:
                data = json.loads(cached_response)
                from fastapi.responses import JSONResponse
                response = JSONResponse(content=data["content"])
                response.headers.update(data["headers"])
                response.headers["X-Cache"] = "HIT"
                return response
        
        # Process request
        response = await call_next(request)
        
        # Cache response if appropriate
        if self._should_cache(request, response):
            cache_key = self._get_cache_key(request)
            
            # Read response body
            response_body = b""
            async for chunk in response.body_iterator:
                response_body += chunk
            
            # Create new response with cached body
            from fastapi.responses import Response as FastAPIResponse
            cached_response_data = {
                "content": response_body.decode() if response_body else "",
                "headers": dict(response.headers)
            }
            
            # Store in cache for 5 minutes
            await self.redis.setex(
                cache_key,
                300,
                json.dumps(cached_response_data)
            )
            
            response = FastAPIResponse(
                content=response_body,
                status_code=response.status_code,
                headers=response.headers,
                media_type=response.media_type
            )
            response.headers["X-Cache"] = "MISS"
        
        return response

# Compression middleware
class CompressionMiddleware(BaseHTTPMiddleware):
    """Custom compression middleware with options."""
    
    def __init__(self, app, minimum_size: int = 500, compression_level: int = 6):
        super().__init__(app)
        self.minimum_size = minimum_size
        self.compression_level = compression_level
    
    def _should_compress(self, request: Request, response: Response) -> bool:
        """Determine if response should be compressed."""
        # Check if client accepts gzip
        accept_encoding = request.headers.get("accept-encoding", "")
        if "gzip" not in accept_encoding:
            return False
        
        # Check content type
        content_type = response.headers.get("content-type", "")
        compressible_types = [
            "text/", "application/json", "application/javascript",
            "application/xml", "image/svg+xml"
        ]
        
        return any(content_type.startswith(ct) for ct in compressible_types)
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)
        
        if not self._should_compress(request, response):
            return response
        
        # Read response body
        response_body = b""
        async for chunk in response.body_iterator:
            response_body += chunk
        
        # Check minimum size
        if len(response_body) < self.minimum_size:
            return response
        
        # Compress response
        import gzip
        compressed_body = gzip.compress(response_body, compresslevel=self.compression_level)
        
        # Create compressed response
        from fastapi.responses import Response as FastAPIResponse
        compressed_response = FastAPIResponse(
            content=compressed_body,
            status_code=response.status_code,
            headers=response.headers,
            media_type=response.media_type
        )
        
        compressed_response.headers["content-encoding"] = "gzip"
        compressed_response.headers["content-length"] = str(len(compressed_body))
        
        return compressed_response
```

## Authentication Systems

### JWT Authentication
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional
from pydantic import BaseModel

# Configuration
SECRET_KEY = "your-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Models
class User(BaseModel):
    id: int
    username: str
    email: str
    is_active: bool = True
    roles: list[str] = []

class UserInDB(User):
    hashed_password: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    username: Optional[str] = None
    scopes: list[str] = []

class LoginRequest(BaseModel):
    username: str
    password: str

# Mock user database
fake_users_db = {
    "admin": UserInDB(
        id=1,
        username="admin",
        email="admin@example.com",
        hashed_password=pwd_context.hash("admin123"),
        roles=["admin", "user"]
    ),
    "user": UserInDB(
        id=2,
        username="user",
        email="user@example.com",
        hashed_password=pwd_context.hash("user123"),
        roles=["user"]
    )
}

# Authentication functions
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash password."""
    return pwd_context.hash(password)

def get_user(username: str) -> Optional[UserInDB]:
    """Get user from database."""
    return fake_users_db.get(username)

def authenticate_user(username: str, password: str) -> Optional[UserInDB]:
    """Authenticate user credentials."""
    user = get_user(username)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT refresh token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(days=7))
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str, token_type: str = "access") -> Optional[dict]:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != token_type:
            return None
        return payload
    except JWTError:
        return None

# Dependencies
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """Get current authenticated user."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token = credentials.credentials
    payload = verify_token(token, "access")
    
    if payload is None:
        raise credentials_exception
    
    username = payload.get("sub")
    if username is None:
        raise credentials_exception
    
    user = get_user(username)
    if user is None:
        raise credentials_exception
    
    return User(**user.dict())

async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Get current active user."""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

def require_roles(*required_roles: str):
    """Dependency factory for role-based access control."""
    
    def role_checker(current_user: User = Depends(get_current_active_user)) -> User:
        if not any(role in current_user.roles for role in required_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {', '.join(required_roles)}"
            )
        return current_user
    
    return role_checker

# Authentication endpoints
@app.post("/auth/login", response_model=Token)
async def login(login_data: LoginRequest):
    """Authenticate user and return tokens."""
    user = authenticate_user(login_data.username, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_token_expires = timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    
    access_token = create_access_token(
        data={"sub": user.username, "roles": user.roles},
        expires_delta=access_token_expires
    )
    
    refresh_token = create_refresh_token(
        data={"sub": user.username},
        expires_delta=refresh_token_expires
    )
    
    return Token(
        access_token=access_token,
        refresh_token=refresh_token
    )

@app.post("/auth/refresh", response_model=Token)
async def refresh_access_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Refresh access token using refresh token."""
    token = credentials.credentials
    payload = verify_token(token, "refresh")
    
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    username = payload.get("sub")
    user = get_user(username)
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    # Create new access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "roles": user.roles},
        expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        refresh_token=token  # Keep the same refresh token
    )

@app.get("/auth/me", response_model=User)
async def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    """Get current user information."""
    return current_user

@app.post("/auth/logout")
async def logout():
    """Logout user (token blacklisting would be implemented here)."""
    # In a real application, you would add the token to a blacklist
    return {"message": "Successfully logged out"}

# Protected endpoints
@app.get("/protected")
async def protected_route(current_user: User = Depends(get_current_active_user)):
    """Protected route requiring authentication."""
    return {"message": f"Hello {current_user.username}, you are authenticated!"}

@app.get("/admin")
async def admin_route(current_user: User = Depends(require_roles("admin"))):
    """Admin-only route."""
    return {"message": f"Hello admin {current_user.username}!"}

@app.get("/user-or-admin")
async def user_or_admin_route(current_user: User = Depends(require_roles("user", "admin"))):
    """Route accessible by users or admins."""
    return {"message": f"Hello {current_user.username}, you have access!"}
```

### Session-Based Authentication
```python
from fastapi import Request, HTTPException, Depends
from starlette.middleware.sessions import SessionMiddleware
import secrets
from typing import Optional

# Add session middleware
app.add_middleware(
    SessionMiddleware,
    secret_key="your-secret-key-change-in-production",
    max_age=3600,  # 1 hour
    same_site="lax",
    https_only=False  # Set to True in production
)

# Session-based authentication
class SessionAuth:
    """Session-based authentication manager."""
    
    def __init__(self):
        self.active_sessions: dict[str, dict] = {}
    
    def create_session(self, user: UserInDB) -> str:
        """Create new session for user."""
        session_id = secrets.token_urlsafe(32)
        self.active_sessions[session_id] = {
            "user_id": user.id,
            "username": user.username,
            "roles": user.roles,
            "created_at": datetime.utcnow(),
            "last_activity": datetime.utcnow()
        }
        return session_id
    
    def get_session(self, session_id: str) -> Optional[dict]:
        """Get session data."""
        session = self.active_sessions.get(session_id)
        if session:
            # Update last activity
            session["last_activity"] = datetime.utcnow()
        return session
    
    def destroy_session(self, session_id: str) -> bool:
        """Destroy session."""
        return self.active_sessions.pop(session_id, None) is not None
    
    def cleanup_expired_sessions(self, max_age_hours: int = 24):
        """Remove expired sessions."""
        cutoff = datetime.utcnow() - timedelta(hours=max_age_hours)
        expired = [
            sid for sid, session in self.active_sessions.items()
            if session["last_activity"] < cutoff
        ]
        
        for sid in expired:
            del self.active_sessions[sid]
        
        return len(expired)

session_auth = SessionAuth()

# Session dependencies
def get_current_user_session(request: Request) -> User:
    """Get current user from session."""
    session_id = request.session.get("session_id")
    if not session_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    session_data = session_auth.get_session(session_id)
    if not session_data:
        # Clear invalid session
        request.session.clear()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session expired"
        )
    
    user = get_user(session_data["username"])
    if not user:
        session_auth.destroy_session(session_id)
        request.session.clear()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return User(**user.dict())

# Session-based endpoints
@app.post("/session/login")
async def session_login(request: Request, login_data: LoginRequest):
    """Login with session-based authentication."""
    user = authenticate_user(login_data.username, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    
    # Create session
    session_id = session_auth.create_session(user)
    request.session["session_id"] = session_id
    
    return {
        "message": "Login successful",
        "user": User(**user.dict())
    }

@app.post("/session/logout")
async def session_logout(request: Request):
    """Logout and destroy session."""
    session_id = request.session.get("session_id")
    if session_id:
        session_auth.destroy_session(session_id)
    
    request.session.clear()
    return {"message": "Logout successful"}

@app.get("/session/me")
async def session_user_info(current_user: User = Depends(get_current_user_session)):
    """Get current user info from session."""
    return current_user

@app.get("/session/protected")
async def session_protected(current_user: User = Depends(get_current_user_session)):
    """Protected route using session authentication."""
    return {"message": f"Hello {current_user.username} from session!"}
```

### API Key Authentication
```python
from fastapi.security import HTTPBearer, APIKeyHeader, APIKeyQuery
from typing import List
import hashlib
import hmac

# API Key models
class APIKey(BaseModel):
    key_id: str
    key_hash: str
    user_id: int
    name: str
    permissions: List[str]
    is_active: bool = True
    created_at: datetime
    last_used: Optional[datetime] = None

# Mock API key database
api_keys_db = {
    "sk_test_123": APIKey(
        key_id="sk_test_123",
        key_hash=hashlib.sha256("secret123".encode()).hexdigest(),
        user_id=1,
        name="Development Key",
        permissions=["read", "write"],
        created_at=datetime.utcnow()
    )
}

# Security schemes
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
api_key_query = APIKeyQuery(name="api_key", auto_error=False)

class APIKeyAuth:
    """API Key authentication manager."""
    
    def __init__(self):
        self.keys = api_keys_db
    
    def verify_api_key(self, api_key: str) -> Optional[APIKey]:
        """Verify API key."""
        # In production, hash the provided key and compare
        for key_id, key_data in self.keys.items():
            if key_id == api_key and key_data.is_active:
                # Update last used timestamp
                key_data.last_used = datetime.utcnow()
                return key_data
        return None
    
    def has_permission(self, api_key: APIKey, permission: str) -> bool:
        """Check if API key has specific permission."""
        return permission in api_key.permissions

api_key_auth = APIKeyAuth()

# API Key dependencies
async def get_api_key(
    api_key_header: Optional[str] = Depends(api_key_header),
    api_key_query: Optional[str] = Depends(api_key_query)
) -> APIKey:
    """Get and validate API key from header or query parameter."""
    api_key = api_key_header or api_key_query
    
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required"
        )
    
    key_data = api_key_auth.verify_api_key(api_key)
    if not key_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )
    
    return key_data

def require_api_permission(permission: str):
    """Dependency factory for API key permission checking."""
    
    def permission_checker(api_key: APIKey = Depends(get_api_key)) -> APIKey:
        if not api_key_auth.has_permission(api_key, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"API key lacks required permission: {permission}"
            )
        return api_key
    
    return permission_checker

# API Key protected endpoints
@app.get("/api/data")
async def get_data(api_key: APIKey = Depends(require_api_permission("read"))):
    """API endpoint requiring read permission."""
    return {
        "data": "This is protected data",
        "api_key_name": api_key.name,
        "permissions": api_key.permissions
    }

@app.post("/api/data")
async def create_data(
    data: dict,
    api_key: APIKey = Depends(require_api_permission("write"))
):
    """API endpoint requiring write permission."""
    return {
        "message": "Data created successfully",
        "data": data,
        "created_by": api_key.name
    }

@app.get("/api/keys")
async def list_api_keys(current_user: User = Depends(get_current_active_user)):
    """List API keys for current user."""
    user_keys = [
        {
            "key_id": key.key_id,
            "name": key.name,
            "permissions": key.permissions,
            "is_active": key.is_active,
            "created_at": key.created_at,
            "last_used": key.last_used
        }
        for key in api_keys_db.values()
        if key.user_id == current_user.id
    ]
    return {"api_keys": user_keys}
```

## Advanced Security Patterns

### OAuth2 with PKCE
```python
from fastapi.security import OAuth2AuthorizationCodeBearer
import secrets
import base64
import hashlib
from urllib.parse import urlencode

# OAuth2 configuration
oauth2_scheme = OAuth2AuthorizationCodeBearer(
    authorizationUrl="https://auth.example.com/oauth/authorize",
    tokenUrl="https://auth.example.com/oauth/token"
)

class OAuth2Manager:
    """OAuth2 with PKCE support."""
    
    def __init__(self):
        self.pending_authorizations = {}
    
    def generate_pkce_challenge(self) -> tuple[str, str]:
        """Generate PKCE code verifier and challenge."""
        # Generate code verifier
        code_verifier = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8')
        code_verifier = code_verifier.rstrip('=')
        
        # Generate code challenge
        code_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode('utf-8')).digest()
        ).decode('utf-8')
        code_challenge = code_challenge.rstrip('=')
        
        return code_verifier, code_challenge
    
    def create_authorization_url(
        self,
        client_id: str,
        redirect_uri: str,
        scopes: List[str] = None
    ) -> tuple[str, str]:
        """Create OAuth2 authorization URL with PKCE."""
        state = secrets.token_urlsafe(32)
        code_verifier, code_challenge = self.generate_pkce_challenge()
        
        # Store PKCE data
        self.pending_authorizations[state] = {
            "code_verifier": code_verifier,
            "redirect_uri": redirect_uri,
            "created_at": datetime.utcnow()
        }
        
        # Build authorization URL
        params = {
            "response_type": "code",
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256"
        }
        
        if scopes:
            params["scope"] = " ".join(scopes)
        
        auth_url = f"https://auth.example.com/oauth/authorize?{urlencode(params)}"
        return auth_url, state
    
    async def exchange_code_for_token(
        self,
        code: str,
        state: str,
        client_id: str,
        client_secret: str
    ) -> dict:
        """Exchange authorization code for access token."""
        auth_data = self.pending_authorizations.get(state)
        if not auth_data:
            raise HTTPException(400, "Invalid state parameter")
        
        # Prepare token exchange request
        token_data = {
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": auth_data["redirect_uri"],
            "client_id": client_id,
            "client_secret": client_secret,
            "code_verifier": auth_data["code_verifier"]
        }
        
        # Make token request (simplified - use aiohttp in real implementation)
        # This would make an HTTP POST to the token endpoint
        # For now, return mock token
        access_token = secrets.token_urlsafe(32)
        
        # Clean up pending authorization
        del self.pending_authorizations[state]
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": 3600,
            "scope": "read write"
        }

oauth2_manager = OAuth2Manager()

@app.get("/oauth/authorize")
async def oauth_authorize(
    client_id: str,
    redirect_uri: str,
    scopes: str = "read"
):
    """Initiate OAuth2 authorization flow."""
    scope_list = scopes.split(" ") if scopes else []
    auth_url, state = oauth2_manager.create_authorization_url(
        client_id, redirect_uri, scope_list
    )
    
    return {
        "authorization_url": auth_url,
        "state": state
    }

@app.post("/oauth/token")
async def oauth_token(
    code: str,
    state: str,
    client_id: str,
    client_secret: str
):
    """Exchange authorization code for access token."""
    token_data = await oauth2_manager.exchange_code_for_token(
        code, state, client_id, client_secret
    )
    return token_data
```

### Multi-Factor Authentication
```python
import pyotp
import qrcode
from io import BytesIO
import base64

class MFAManager:
    """Multi-Factor Authentication manager."""
    
    def __init__(self):
        self.user_mfa_secrets = {}  # In production, store in database
    
    def generate_secret(self, username: str) -> str:
        """Generate TOTP secret for user."""
        secret = pyotp.random_base32()
        self.user_mfa_secrets[username] = secret
        return secret
    
    def generate_qr_code(self, username: str, secret: str, issuer: str = "MyApp") -> str:
        """Generate QR code for TOTP setup."""
        totp = pyotp.TOTP(secret)
        provisioning_uri = totp.provisioning_uri(
            name=username,
            issuer_name=issuer
        )
        
        # Generate QR code
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(provisioning_uri)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to base64
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        img_base64 = base64.b64encode(buffer.getvalue()).decode()
        
        return f"data:image/png;base64,{img_base64}"
    
    def verify_totp(self, username: str, token: str) -> bool:
        """Verify TOTP token."""
        secret = self.user_mfa_secrets.get(username)
        if not secret:
            return False
        
        totp = pyotp.TOTP(secret)
        return totp.verify(token, valid_window=1)
    
    def generate_backup_codes(self, username: str) -> List[str]:
        """Generate backup codes for user."""
        codes = [secrets.token_hex(4).upper() for _ in range(10)]
        # In production, hash and store these codes
        return codes

mfa_manager = MFAManager()

class MFASetupResponse(BaseModel):
    secret: str
    qr_code: str
    backup_codes: List[str]

class MFAVerifyRequest(BaseModel):
    token: str

@app.post("/auth/mfa/setup", response_model=MFASetupResponse)
async def setup_mfa(current_user: User = Depends(get_current_active_user)):
    """Setup MFA for current user."""
    secret = mfa_manager.generate_secret(current_user.username)
    qr_code = mfa_manager.generate_qr_code(current_user.username, secret)
    backup_codes = mfa_manager.generate_backup_codes(current_user.username)
    
    return MFASetupResponse(
        secret=secret,
        qr_code=qr_code,
        backup_codes=backup_codes
    )

@app.post("/auth/mfa/verify")
async def verify_mfa(
    mfa_request: MFAVerifyRequest,
    current_user: User = Depends(get_current_active_user)
):
    """Verify MFA token."""
    if mfa_manager.verify_totp(current_user.username, mfa_request.token):
        return {"message": "MFA token verified successfully"}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid MFA token"
        )

# Enhanced JWT with MFA
def create_mfa_required_token(username: str) -> str:
    """Create token that requires MFA completion."""
    return create_access_token(
        data={"sub": username, "mfa_required": True},
        expires_delta=timedelta(minutes=5)
    )

@app.post("/auth/login-mfa")
async def login_with_mfa(login_data: LoginRequest):
    """Login that requires MFA completion."""
    user = authenticate_user(login_data.username, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    
    # Check if user has MFA enabled
    if user.username in mfa_manager.user_mfa_secrets:
        # Return token that requires MFA
        mfa_token = create_mfa_required_token(user.username)
        return {
            "mfa_required": True,
            "mfa_token": mfa_token,
            "message": "MFA token required"
        }
    else:
        # Regular login flow
        access_token = create_access_token(
            data={"sub": user.username, "roles": user.roles}
        )
        return Token(access_token=access_token, refresh_token="", token_type="bearer")

@app.post("/auth/complete-mfa")
async def complete_mfa_login(
    mfa_token: str,
    mfa_code: str
):
    """Complete MFA login process."""
    payload = verify_token(mfa_token, "access")
    if not payload or not payload.get("mfa_required"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid MFA token"
        )
    
    username = payload.get("sub")
    if not mfa_manager.verify_totp(username, mfa_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid MFA code"
        )
    
    # Create full access token
    user = get_user(username)
    access_token = create_access_token(
        data={"sub": user.username, "roles": user.roles}
    )
    
    return Token(access_token=access_token, refresh_token="", token_type="bearer")
```

## Security Best Practices

### Input Validation and Sanitization
```python
from pydantic import validator, Field
import re
from typing import Any

class SecureUserInput(BaseModel):
    """Secure user input model with validation."""
    
    username: str = Field(..., min_length=3, max_length=20, regex=r'^[a-zA-Z0-9_]+$')
    email: str = Field(..., regex=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    age: int = Field(..., ge=13, le=120)
    bio: str = Field("", max_length=500)
    website: Optional[str] = Field(None, max_length=200)
    
    @validator('username')
    def validate_username(cls, v):
        """Validate username format and blacklist."""
        blacklisted = ['admin', 'root', 'system', 'test']
        if v.lower() in blacklisted:
            raise ValueError('Username not allowed')
        return v
    
    @validator('bio')
    def sanitize_bio(cls, v):
        """Sanitize bio text."""
        # Remove HTML tags
        v = re.sub(r'<[^>]+>', '', v)
        # Remove potentially dangerous characters
        v = re.sub(r'[<>&"\']', '', v)
        return v.strip()
    
    @validator('website')
    def validate_website(cls, v):
        """Validate website URL."""
        if v is None:
            return v
        
        url_pattern = re.compile(
            r'^https?://'  # http:// or https://
            r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
            r'localhost|'  # localhost...
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
            r'(?::\d+)?'  # optional port
            r'(?:/?|[/?]\S+)$', re.IGNORECASE)
        
        if not url_pattern.match(v):
            raise ValueError('Invalid URL format')
        return v

# CSRF Protection
class CSRFProtection:
    """CSRF protection implementation."""
    
    def __init__(self):
        self.tokens = {}
    
    def generate_token(self, session_id: str) -> str:
        """Generate CSRF token for session."""
        token = secrets.token_urlsafe(32)
        self.tokens[session_id] = {
            "token": token,
            "created_at": datetime.utcnow()
        }
        return token
    
    def verify_token(self, session_id: str, token: str) -> bool:
        """Verify CSRF token."""
        stored_data = self.tokens.get(session_id)
        if not stored_data:
            return False
        
        # Check token match
        if stored_data["token"] != token:
            return False
        
        # Check expiration (5 minutes)
        if datetime.utcnow() - stored_data["created_at"] > timedelta(minutes=5):
            del self.tokens[session_id]
            return False
        
        return True

csrf_protection = CSRFProtection()

@app.get("/csrf-token")
async def get_csrf_token(request: Request):
    """Get CSRF token for session."""
    session_id = request.session.get("session_id")
    if not session_id:
        raise HTTPException(401, "Session required")
    
    token = csrf_protection.generate_token(session_id)
    return {"csrf_token": token}

def verify_csrf_token(request: Request, csrf_token: str = Form(...)):
    """Dependency to verify CSRF token."""
    session_id = request.session.get("session_id")
    if not session_id or not csrf_protection.verify_token(session_id, csrf_token):
        raise HTTPException(403, "Invalid CSRF token")
    return True

# Secure file upload
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.pdf', '.txt'}

def validate_file_upload(file: UploadFile) -> UploadFile:
    """Validate uploaded file."""
    # Check file size
    if file.size > MAX_FILE_SIZE:
        raise HTTPException(400, f"File too large. Max size: {MAX_FILE_SIZE // 1024 // 1024}MB")
    
    # Check file extension
    file_ext = Path(file.filename).suffix.lower()
    if file_ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"File type not allowed. Allowed: {', '.join(ALLOWED_EXTENSIONS)}")
    
    # Check content type
    allowed_content_types = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.pdf': 'application/pdf',
        '.txt': 'text/plain'
    }
    
    expected_content_type = allowed_content_types.get(file_ext)
    if file.content_type != expected_content_type:
        raise HTTPException(400, "File content type doesn't match extension")
    
    return file

@app.post("/upload")
async def upload_file(
    file: UploadFile = Depends(validate_file_upload),
    current_user: User = Depends(get_current_active_user)
):
    """Secure file upload endpoint."""
    # Generate secure filename
    secure_filename = f"{current_user.id}_{int(time.time())}_{secrets.token_hex(8)}{Path(file.filename).suffix}"
    file_path = Path(f"/secure/uploads/{secure_filename}")
    
    # Ensure upload directory exists
    file_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Save file
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    return {
        "message": "File uploaded successfully",
        "filename": secure_filename,
        "size": len(content)
    }
```

---

**Last Updated:** Based on FastAPI 0.100+ and modern security practices
**References:**
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
- [FastAPI Middleware](https://fastapi.tiangolo.com/tutorial/middleware/)
- [JWT Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)
- [OWASP Security Guidelines](https://owasp.org/www-project-top-ten/)
# Authentication Patterns

Comprehensive guide to implementing secure authentication systems, covering JWT, OAuth2, session management, and modern security practices.

## 🎯 Authentication Overview

Authentication is the foundation of application security:
- **JWT (JSON Web Tokens)** - Stateless token-based authentication
- **OAuth2/OIDC** - Delegated authorization and identity
- **Session-Based** - Traditional server-side sessions
- **API Keys** - Service-to-service authentication
- **Multi-Factor** - Enhanced security with 2FA/MFA
- **Passwordless** - Modern authentication without passwords

## 🔐 JWT Authentication

### JWT Implementation

```python
# JWT token generation and validation
import jwt
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
from fastapi import HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from passlib.context import CryptContext
import secrets

# Configuration
JWT_SECRET_KEY = secrets.token_urlsafe(32)
JWT_ALGORITHM = "HS256"
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 30
JWT_REFRESH_TOKEN_EXPIRE_DAYS = 7

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class TokenService:
    """JWT token management service"""
    
    @staticmethod
    def create_access_token(
        data: Dict[str, Any],
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(
                minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES
            )
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "type": "access"
        })
        
        return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    
    @staticmethod
    def create_refresh_token(
        data: Dict[str, Any],
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """Create JWT refresh token"""
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(
                days=JWT_REFRESH_TOKEN_EXPIRE_DAYS
            )
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "type": "refresh",
            "jti": secrets.token_urlsafe(16)  # JWT ID for revocation
        })
        
        return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    
    @staticmethod
    def decode_token(token: str) -> Dict[str, Any]:
        """Decode and validate JWT token"""
        try:
            payload = jwt.decode(
                token,
                JWT_SECRET_KEY,
                algorithms=[JWT_ALGORITHM]
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=401,
                detail="Token has expired"
            )
        except jwt.JWTError as e:
            raise HTTPException(
                status_code=401,
                detail=f"Invalid token: {str(e)}"
            )

# FastAPI security scheme
security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> Dict[str, Any]:
    """Dependency to get current user from JWT token"""
    token = credentials.credentials
    payload = TokenService.decode_token(token)
    
    # Verify token type
    if payload.get("type") != "access":
        raise HTTPException(
            status_code=401,
            detail="Invalid token type"
        )
    
    # Get user from database
    user_id = payload.get("sub")
    user = await get_user_by_id(user_id)
    
    if not user:
        raise HTTPException(
            status_code=401,
            detail="User not found"
        )
    
    return user

# Authentication endpoints
from pydantic import BaseModel, EmailStr

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

@app.post("/auth/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    """Authenticate user and return tokens"""
    # Verify credentials
    user = await get_user_by_email(request.email)
    
    if not user or not pwd_context.verify(request.password, user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )
    
    # Generate tokens
    access_token = TokenService.create_access_token(
        data={"sub": str(user.id), "email": user.email}
    )
    refresh_token = TokenService.create_refresh_token(
        data={"sub": str(user.id)}
    )
    
    # Store refresh token in database
    await store_refresh_token(user.id, refresh_token)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )

@app.post("/auth/refresh", response_model=TokenResponse)
async def refresh_token(refresh_token: str):
    """Refresh access token using refresh token"""
    payload = TokenService.decode_token(refresh_token)
    
    # Verify token type
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=401,
            detail="Invalid token type"
        )
    
    # Check if token is revoked
    if await is_token_revoked(payload.get("jti")):
        raise HTTPException(
            status_code=401,
            detail="Token has been revoked"
        )
    
    # Generate new access token
    user_id = payload.get("sub")
    user = await get_user_by_id(user_id)
    
    access_token = TokenService.create_access_token(
        data={"sub": str(user.id), "email": user.email}
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )

@app.post("/auth/logout")
async def logout(
    refresh_token: str,
    current_user: Dict = Depends(get_current_user)
):
    """Logout user and revoke tokens"""
    # Decode refresh token
    payload = TokenService.decode_token(refresh_token)
    jti = payload.get("jti")
    
    # Revoke refresh token
    await revoke_token(jti)
    
    return {"message": "Successfully logged out"}
```

### Advanced JWT Features

```python
# JWT with role-based access control (RBAC)
from enum import Enum
from typing import List

class Role(str, Enum):
    USER = "user"
    ADMIN = "admin"
    MODERATOR = "moderator"

class Permission(str, Enum):
    READ_USERS = "read:users"
    WRITE_USERS = "write:users"
    DELETE_USERS = "delete:users"
    READ_POSTS = "read:posts"
    WRITE_POSTS = "write:posts"
    DELETE_POSTS = "delete:posts"

# Role-permission mapping
ROLE_PERMISSIONS = {
    Role.USER: [Permission.READ_POSTS, Permission.WRITE_POSTS],
    Role.MODERATOR: [
        Permission.READ_POSTS, Permission.WRITE_POSTS,
        Permission.DELETE_POSTS, Permission.READ_USERS
    ],
    Role.ADMIN: list(Permission)  # All permissions
}

def create_access_token_with_permissions(
    user_id: str,
    email: str,
    roles: List[Role]
) -> str:
    """Create JWT with roles and permissions"""
    # Collect all permissions from roles
    permissions = set()
    for role in roles:
        permissions.update(ROLE_PERMISSIONS.get(role, []))
    
    return TokenService.create_access_token(
        data={
            "sub": user_id,
            "email": email,
            "roles": roles,
            "permissions": list(permissions)
        }
    )

# Permission checking decorator
def require_permission(permission: Permission):
    """Decorator to check if user has required permission"""
    async def permission_checker(
        current_user: Dict = Depends(get_current_user)
    ):
        user_permissions = current_user.get("permissions", [])
        
        if permission not in user_permissions:
            raise HTTPException(
                status_code=403,
                detail=f"Permission denied: {permission} required"
            )
        
        return current_user
    
    return permission_checker

# Usage
@app.delete("/api/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: Dict = Depends(require_permission(Permission.DELETE_USERS))
):
    """Delete user - requires DELETE_USERS permission"""
    # Implementation
    pass

# JWT with custom claims
class TokenClaims(BaseModel):
    """Custom JWT claims"""
    sub: str  # Subject (user ID)
    email: str
    roles: List[str]
    permissions: List[str]
    organization_id: Optional[str] = None
    tenant_id: Optional[str] = None
    
    # Security claims
    auth_time: datetime  # Time of authentication
    amr: List[str]  # Authentication methods used
    acr: str  # Authentication context class
    
    # Standard claims
    exp: datetime  # Expiration time
    iat: datetime  # Issued at
    nbf: Optional[datetime] = None  # Not before
    jti: Optional[str] = None  # JWT ID
```

## 🔑 OAuth2/OIDC Implementation

### OAuth2 Authorization Code Flow with PKCE

```python
# OAuth2 with PKCE (Proof Key for Code Exchange)
import hashlib
import base64
from urllib.parse import urlencode
from fastapi import Request
from fastapi.responses import RedirectResponse

class OAuth2Service:
    """OAuth2 implementation with PKCE"""
    
    def __init__(
        self,
        client_id: str,
        client_secret: str,
        authorize_url: str,
        token_url: str,
        redirect_uri: str
    ):
        self.client_id = client_id
        self.client_secret = client_secret
        self.authorize_url = authorize_url
        self.token_url = token_url
        self.redirect_uri = redirect_uri
    
    @staticmethod
    def generate_pkce_pair() -> tuple[str, str]:
        """Generate PKCE code verifier and challenge"""
        # Generate code verifier
        code_verifier = base64.urlsafe_b64encode(
            secrets.token_bytes(32)
        ).decode('utf-8').rstrip('=')
        
        # Generate code challenge
        code_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode('utf-8')).digest()
        ).decode('utf-8').rstrip('=')
        
        return code_verifier, code_challenge
    
    async def get_authorization_url(
        self,
        state: str,
        scope: List[str] = None
    ) -> tuple[str, str]:
        """Get OAuth2 authorization URL with PKCE"""
        code_verifier, code_challenge = self.generate_pkce_pair()
        
        # Store code verifier for later use
        await store_pkce_verifier(state, code_verifier)
        
        params = {
            "client_id": self.client_id,
            "response_type": "code",
            "redirect_uri": self.redirect_uri,
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256"
        }
        
        if scope:
            params["scope"] = " ".join(scope)
        
        auth_url = f"{self.authorize_url}?{urlencode(params)}"
        return auth_url, code_verifier
    
    async def exchange_code_for_token(
        self,
        code: str,
        state: str
    ) -> Dict[str, Any]:
        """Exchange authorization code for tokens"""
        # Retrieve stored code verifier
        code_verifier = await get_pkce_verifier(state)
        
        if not code_verifier:
            raise HTTPException(
                status_code=400,
                detail="Invalid state parameter"
            )
        
        # Exchange code for tokens
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.token_url,
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "redirect_uri": self.redirect_uri,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "code_verifier": code_verifier
                }
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Token exchange failed: {response.text}"
                )
            
            return response.json()

# OAuth2 endpoints
oauth2_service = OAuth2Service(
    client_id=settings.OAUTH_CLIENT_ID,
    client_secret=settings.OAUTH_CLIENT_SECRET,
    authorize_url="https://oauth.provider.com/authorize",
    token_url="https://oauth.provider.com/token",
    redirect_uri="https://api.example.com/auth/callback"
)

@app.get("/auth/login/oauth")
async def oauth_login(request: Request):
    """Initiate OAuth2 login flow"""
    # Generate state for CSRF protection
    state = secrets.token_urlsafe(32)
    
    # Store state in session
    request.session["oauth_state"] = state
    
    # Get authorization URL
    auth_url, _ = await oauth2_service.get_authorization_url(
        state=state,
        scope=["openid", "profile", "email"]
    )
    
    return RedirectResponse(url=auth_url)

@app.get("/auth/callback")
async def oauth_callback(
    request: Request,
    code: str,
    state: str
):
    """Handle OAuth2 callback"""
    # Verify state
    stored_state = request.session.get("oauth_state")
    if not stored_state or stored_state != state:
        raise HTTPException(
            status_code=400,
            detail="Invalid state parameter"
        )
    
    # Exchange code for tokens
    token_response = await oauth2_service.exchange_code_for_token(
        code=code,
        state=state
    )
    
    # Decode ID token (if OIDC)
    id_token = token_response.get("id_token")
    if id_token:
        # Verify and decode ID token
        user_info = await verify_id_token(id_token)
    else:
        # Get user info from userinfo endpoint
        user_info = await get_user_info(token_response["access_token"])
    
    # Create or update user
    user = await create_or_update_oauth_user(user_info)
    
    # Generate application tokens
    access_token = TokenService.create_access_token(
        data={"sub": str(user.id), "email": user.email}
    )
    refresh_token = TokenService.create_refresh_token(
        data={"sub": str(user.id)}
    )
    
    # Clear session
    request.session.clear()
    
    # Redirect to frontend with tokens
    redirect_url = f"{settings.FRONTEND_URL}/auth/success"
    redirect_url += f"?access_token={access_token}&refresh_token={refresh_token}"
    
    return RedirectResponse(url=redirect_url)
```

### OpenID Connect (OIDC) Implementation

```python
# OIDC token validation
import httpx
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from jose import jwt, jwk

class OIDCService:
    """OpenID Connect service"""
    
    def __init__(self, issuer: str, client_id: str):
        self.issuer = issuer
        self.client_id = client_id
        self._discovery_doc = None
        self._jwks = None
    
    async def get_discovery_document(self) -> Dict[str, Any]:
        """Get OIDC discovery document"""
        if self._discovery_doc:
            return self._discovery_doc
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.issuer}/.well-known/openid-configuration"
            )
            self._discovery_doc = response.json()
            
        return self._discovery_doc
    
    async def get_jwks(self) -> Dict[str, Any]:
        """Get JSON Web Key Set"""
        if self._jwks:
            return self._jwks
        
        discovery = await self.get_discovery_document()
        jwks_uri = discovery["jwks_uri"]
        
        async with httpx.AsyncClient() as client:
            response = await client.get(jwks_uri)
            self._jwks = response.json()
            
        return self._jwks
    
    async def verify_id_token(
        self,
        id_token: str,
        nonce: Optional[str] = None
    ) -> Dict[str, Any]:
        """Verify and decode OIDC ID token"""
        # Get JWKS
        jwks = await self.get_jwks()
        
        # Decode header to get key ID
        unverified_header = jwt.get_unverified_header(id_token)
        kid = unverified_header.get("kid")
        
        # Find matching key
        key = None
        for jwk_key in jwks["keys"]:
            if jwk_key["kid"] == kid:
                key = jwk_key
                break
        
        if not key:
            raise ValueError("Unable to find matching key")
        
        # Verify token
        try:
            payload = jwt.decode(
                id_token,
                key,
                algorithms=["RS256"],
                audience=self.client_id,
                issuer=self.issuer,
                options={
                    "verify_exp": True,
                    "verify_aud": True,
                    "verify_iss": True
                }
            )
        except jwt.JWTError as e:
            raise HTTPException(
                status_code=401,
                detail=f"Invalid ID token: {str(e)}"
            )
        
        # Verify nonce if provided
        if nonce and payload.get("nonce") != nonce:
            raise HTTPException(
                status_code=401,
                detail="Invalid nonce"
            )
        
        return payload

# Social login implementations
class SocialAuthProvider(Enum):
    GOOGLE = "google"
    GITHUB = "github"
    MICROSOFT = "microsoft"
    APPLE = "apple"

SOCIAL_AUTH_CONFIGS = {
    SocialAuthProvider.GOOGLE: {
        "authorize_url": "https://accounts.google.com/o/oauth2/v2/auth",
        "token_url": "https://oauth2.googleapis.com/token",
        "userinfo_url": "https://www.googleapis.com/oauth2/v2/userinfo",
        "scope": ["openid", "email", "profile"]
    },
    SocialAuthProvider.GITHUB: {
        "authorize_url": "https://github.com/login/oauth/authorize",
        "token_url": "https://github.com/login/oauth/access_token",
        "userinfo_url": "https://api.github.com/user",
        "scope": ["user:email"]
    }
}

@app.get("/auth/login/{provider}")
async def social_login(
    provider: SocialAuthProvider,
    request: Request
):
    """Initiate social login"""
    config = SOCIAL_AUTH_CONFIGS.get(provider)
    if not config:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported provider: {provider}"
        )
    
    # Create OAuth2 service for provider
    oauth_service = OAuth2Service(
        client_id=settings.SOCIAL_AUTH[provider]["client_id"],
        client_secret=settings.SOCIAL_AUTH[provider]["client_secret"],
        authorize_url=config["authorize_url"],
        token_url=config["token_url"],
        redirect_uri=f"{settings.API_URL}/auth/callback/{provider}"
    )
    
    # Generate state
    state = secrets.token_urlsafe(32)
    request.session["oauth_state"] = state
    request.session["oauth_provider"] = provider
    
    # Get authorization URL
    auth_url, _ = await oauth_service.get_authorization_url(
        state=state,
        scope=config["scope"]
    )
    
    return RedirectResponse(url=auth_url)
```

## 🍪 Session-Based Authentication

### Server-Side Sessions

```python
# Session management with Redis
from fastapi_sessions import SessionCookie, SessionVerifier
from fastapi_sessions.backends.implementations import RedisBackend
import redis.asyncio as redis
from uuid import uuid4

# Session configuration
SESSION_SECRET_KEY = secrets.token_urlsafe(32)
SESSION_COOKIE_NAME = "session_id"
SESSION_EXPIRE_SECONDS = 3600  # 1 hour

# Redis session backend
redis_client = redis.from_url("redis://localhost", encoding="utf-8", decode_responses=True)
session_backend = RedisBackend(redis_client)

# Session cookie
session_cookie = SessionCookie(
    cookie_name=SESSION_COOKIE_NAME,
    identifier="session_verifier",
    auto_error=False,
    secret_key=SESSION_SECRET_KEY,
    cookie_params={
        "httponly": True,
        "secure": True,  # HTTPS only
        "samesite": "lax",
        "max_age": SESSION_EXPIRE_SECONDS
    }
)

class SessionData(BaseModel):
    """Session data model"""
    user_id: Optional[int] = None
    email: Optional[str] = None
    roles: List[str] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_activity: datetime = Field(default_factory=datetime.utcnow)
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class SessionVerifier(SessionVerifier[str, SessionData]):
    def __init__(
        self,
        *,
        identifier: str,
        auto_error: bool,
        backend: RedisBackend,
        auth_http_exception: HTTPException,
    ):
        self._identifier = identifier
        self._auto_error = auto_error
        self._backend = backend
        self._auth_http_exception = auth_http_exception

    @property
    def identifier(self):
        return self._identifier

    @property
    def backend(self):
        return self._backend

    @property
    def auto_error(self):
        return self._auto_error

    @property
    def auth_http_exception(self):
        return self._auth_http_exception

    def verify_session(self, model: SessionData) -> bool:
        """Verify if session is valid"""
        # Check session expiry
        if datetime.utcnow() - model.last_activity > timedelta(seconds=SESSION_EXPIRE_SECONDS):
            return False
        
        # Check if user exists
        if not model.user_id:
            return False
        
        return True

# Session management endpoints
@app.post("/auth/login/session")
async def session_login(
    request: Request,
    credentials: LoginRequest,
    response: Response
):
    """Login with session-based authentication"""
    # Verify credentials
    user = await authenticate_user(credentials.email, credentials.password)
    
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )
    
    # Create session
    session_id = str(uuid4())
    session_data = SessionData(
        user_id=user.id,
        email=user.email,
        roles=user.roles,
        ip_address=request.client.host,
        user_agent=request.headers.get("User-Agent")
    )
    
    # Store session
    await session_backend.create(session_id, session_data)
    
    # Set session cookie
    session_cookie.attach_to_response(response, session_id)
    
    return {
        "message": "Login successful",
        "user": {
            "id": user.id,
            "email": user.email,
            "roles": user.roles
        }
    }

@app.post("/auth/logout/session")
async def session_logout(
    response: Response,
    session_id: str = Depends(session_cookie)
):
    """Logout and destroy session"""
    if session_id:
        # Delete session from backend
        await session_backend.delete(session_id)
        
        # Remove session cookie
        session_cookie.delete_from_response(response)
    
    return {"message": "Logout successful"}

# Session-based authorization
async def get_current_session(
    session_id: str = Depends(session_cookie)
) -> SessionData:
    """Get current session data"""
    if not session_id:
        raise HTTPException(
            status_code=401,
            detail="Not authenticated"
        )
    
    # Get session from backend
    session_data = await session_backend.read(session_id)
    
    if not session_data:
        raise HTTPException(
            status_code=401,
            detail="Invalid session"
        )
    
    # Update last activity
    session_data.last_activity = datetime.utcnow()
    await session_backend.update(session_id, session_data)
    
    return session_data

# Secure session management
class SecureSessionManager:
    """Enhanced session security"""
    
    @staticmethod
    async def regenerate_session_id(
        old_session_id: str,
        backend: RedisBackend
    ) -> str:
        """Regenerate session ID to prevent fixation"""
        # Get existing session data
        session_data = await backend.read(old_session_id)
        
        if not session_data:
            raise ValueError("Session not found")
        
        # Create new session ID
        new_session_id = str(uuid4())
        
        # Copy session data to new ID
        await backend.create(new_session_id, session_data)
        
        # Delete old session
        await backend.delete(old_session_id)
        
        return new_session_id
    
    @staticmethod
    async def concurrent_session_check(
        user_id: int,
        current_session_id: str,
        backend: RedisBackend,
        max_sessions: int = 3
    ):
        """Check and limit concurrent sessions"""
        # Get all sessions for user
        pattern = f"session:user:{user_id}:*"
        user_sessions = await redis_client.keys(pattern)
        
        if len(user_sessions) >= max_sessions:
            # Remove oldest session
            oldest_session = min(
                user_sessions,
                key=lambda s: backend.read(s).created_at
            )
            await backend.delete(oldest_session)
```

## 🔐 API Key Authentication

### API Key Management

```python
# API key generation and validation
import hashlib
from sqlalchemy import Column, String, Integer, DateTime, Boolean, JSON

class APIKeyModel(Base):
    __tablename__ = "api_keys"
    
    id = Column(Integer, primary_key=True)
    key_hash = Column(String, unique=True, index=True)
    prefix = Column(String, index=True)  # For display: "sk_live_..."
    name = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    # Permissions
    scopes = Column(JSON)  # List of allowed scopes
    ip_whitelist = Column(JSON)  # List of allowed IPs
    
    # Usage tracking
    last_used_at = Column(DateTime)
    usage_count = Column(Integer, default=0)
    
    # Lifecycle
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)
    revoked_at = Column(DateTime)
    is_active = Column(Boolean, default=True)

class APIKeyService:
    """API key management service"""
    
    @staticmethod
    def generate_api_key(prefix: str = "sk") -> tuple[str, str]:
        """Generate API key and hash"""
        # Generate random key
        key_bytes = secrets.token_bytes(32)
        key_suffix = base64.urlsafe_b64encode(key_bytes).decode('utf-8').rstrip('=')
        
        # Create full key with prefix
        environment = "test" if settings.DEBUG else "live"
        full_key = f"{prefix}_{environment}_{key_suffix}"
        
        # Hash for storage
        key_hash = hashlib.sha256(full_key.encode()).hexdigest()
        
        return full_key, key_hash
    
    @staticmethod
    async def create_api_key(
        user_id: int,
        name: str,
        scopes: List[str],
        expires_in_days: Optional[int] = None,
        ip_whitelist: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Create new API key"""
        # Generate key
        full_key, key_hash = APIKeyService.generate_api_key()
        
        # Extract prefix for display
        prefix = "_".join(full_key.split("_")[:2])
        
        # Calculate expiration
        expires_at = None
        if expires_in_days:
            expires_at = datetime.utcnow() + timedelta(days=expires_in_days)
        
        # Create database record
        api_key = APIKeyModel(
            key_hash=key_hash,
            prefix=prefix,
            name=name,
            user_id=user_id,
            scopes=scopes,
            ip_whitelist=ip_whitelist,
            expires_at=expires_at
        )
        
        db.add(api_key)
        db.commit()
        
        return {
            "id": api_key.id,
            "key": full_key,  # Only returned once
            "prefix": prefix,
            "name": name,
            "scopes": scopes,
            "expires_at": expires_at
        }
    
    @staticmethod
    async def validate_api_key(
        key: str,
        required_scope: Optional[str] = None,
        ip_address: Optional[str] = None
    ) -> Optional[APIKeyModel]:
        """Validate API key and check permissions"""
        # Hash the key
        key_hash = hashlib.sha256(key.encode()).hexdigest()
        
        # Find key in database
        api_key = db.query(APIKeyModel).filter(
            APIKeyModel.key_hash == key_hash,
            APIKeyModel.is_active == True
        ).first()
        
        if not api_key:
            return None
        
        # Check expiration
        if api_key.expires_at and api_key.expires_at < datetime.utcnow():
            return None
        
        # Check IP whitelist
        if api_key.ip_whitelist and ip_address not in api_key.ip_whitelist:
            return None
        
        # Check scope
        if required_scope and required_scope not in api_key.scopes:
            return None
        
        # Update usage stats
        api_key.last_used_at = datetime.utcnow()
        api_key.usage_count += 1
        db.commit()
        
        return api_key

# FastAPI dependency
async def get_api_key(
    api_key: str = Header(..., alias="X-API-Key"),
    request: Request = None
) -> APIKeyModel:
    """Validate API key from header"""
    # Get client IP
    ip_address = request.client.host if request else None
    
    # Validate key
    key_model = await APIKeyService.validate_api_key(
        key=api_key,
        ip_address=ip_address
    )
    
    if not key_model:
        raise HTTPException(
            status_code=401,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "ApiKey"}
        )
    
    return key_model

# Scoped API key dependency
def require_api_scope(scope: str):
    """Require specific API key scope"""
    async def scope_checker(
        api_key: str = Header(..., alias="X-API-Key"),
        request: Request = None
    ) -> APIKeyModel:
        ip_address = request.client.host if request else None
        
        key_model = await APIKeyService.validate_api_key(
            key=api_key,
            required_scope=scope,
            ip_address=ip_address
        )
        
        if not key_model:
            raise HTTPException(
                status_code=403,
                detail=f"API key missing required scope: {scope}"
            )
        
        return key_model
    
    return scope_checker

# API key management endpoints
@app.post("/api/keys", response_model=APIKeyResponse)
async def create_api_key(
    request: CreateAPIKeyRequest,
    current_user: User = Depends(get_current_user)
):
    """Create new API key"""
    # Check user's key limit
    existing_keys = db.query(APIKeyModel).filter(
        APIKeyModel.user_id == current_user.id,
        APIKeyModel.is_active == True
    ).count()
    
    if existing_keys >= settings.MAX_API_KEYS_PER_USER:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum number of API keys ({settings.MAX_API_KEYS_PER_USER}) reached"
        )
    
    # Create key
    result = await APIKeyService.create_api_key(
        user_id=current_user.id,
        name=request.name,
        scopes=request.scopes,
        expires_in_days=request.expires_in_days,
        ip_whitelist=request.ip_whitelist
    )
    
    return APIKeyResponse(**result)

@app.get("/api/keys")
async def list_api_keys(
    current_user: User = Depends(get_current_user)
):
    """List user's API keys"""
    keys = db.query(APIKeyModel).filter(
        APIKeyModel.user_id == current_user.id,
        APIKeyModel.is_active == True
    ).all()
    
    return [
        {
            "id": key.id,
            "prefix": key.prefix,
            "name": key.name,
            "scopes": key.scopes,
            "last_used_at": key.last_used_at,
            "expires_at": key.expires_at,
            "created_at": key.created_at
        }
        for key in keys
    ]

@app.delete("/api/keys/{key_id}")
async def revoke_api_key(
    key_id: int,
    current_user: User = Depends(get_current_user)
):
    """Revoke API key"""
    api_key = db.query(APIKeyModel).filter(
        APIKeyModel.id == key_id,
        APIKeyModel.user_id == current_user.id
    ).first()
    
    if not api_key:
        raise HTTPException(
            status_code=404,
            detail="API key not found"
        )
    
    api_key.is_active = False
    api_key.revoked_at = datetime.utcnow()
    db.commit()
    
    return {"message": "API key revoked"}
```

## 🔐 Multi-Factor Authentication (MFA)

### TOTP Implementation

```python
# Time-based One-Time Password (TOTP)
import pyotp
import qrcode
from io import BytesIO
import base64

class MFAService:
    """Multi-factor authentication service"""
    
    @staticmethod
    def generate_secret() -> str:
        """Generate TOTP secret"""
        return pyotp.random_base32()
    
    @staticmethod
    def generate_qr_code(
        email: str,
        secret: str,
        issuer: str = "MyApp"
    ) -> str:
        """Generate QR code for authenticator app"""
        # Create TOTP URI
        totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(
            name=email,
            issuer_name=issuer
        )
        
        # Generate QR code
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(totp_uri)
        qr.make(fit=True)
        
        # Convert to base64
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        
        return base64.b64encode(buffer.getvalue()).decode()
    
    @staticmethod
    def verify_totp(secret: str, token: str) -> bool:
        """Verify TOTP token"""
        totp = pyotp.TOTP(secret)
        return totp.verify(token, valid_window=1)  # Allow 30 second window
    
    @staticmethod
    def generate_backup_codes(count: int = 10) -> List[str]:
        """Generate backup codes"""
        return [
            ''.join(secrets.choice('0123456789') for _ in range(8))
            for _ in range(count)
        ]

# MFA endpoints
@app.post("/auth/mfa/enable")
async def enable_mfa(
    current_user: User = Depends(get_current_user)
):
    """Enable MFA for user"""
    # Check if already enabled
    if current_user.mfa_enabled:
        raise HTTPException(
            status_code=400,
            detail="MFA is already enabled"
        )
    
    # Generate secret
    secret = MFAService.generate_secret()
    
    # Generate backup codes
    backup_codes = MFAService.generate_backup_codes()
    
    # Store temporarily (user needs to confirm)
    await cache.set(
        f"mfa_setup:{current_user.id}",
        {
            "secret": secret,
            "backup_codes": backup_codes
        },
        expire=600  # 10 minutes
    )
    
    # Generate QR code
    qr_code = MFAService.generate_qr_code(
        email=current_user.email,
        secret=secret
    )
    
    return {
        "qr_code": f"data:image/png;base64,{qr_code}",
        "secret": secret,
        "backup_codes": backup_codes
    }

@app.post("/auth/mfa/confirm")
async def confirm_mfa(
    token: str,
    current_user: User = Depends(get_current_user)
):
    """Confirm MFA setup with TOTP token"""
    # Get setup data
    setup_data = await cache.get(f"mfa_setup:{current_user.id}")
    
    if not setup_data:
        raise HTTPException(
            status_code=400,
            detail="MFA setup expired or not found"
        )
    
    # Verify token
    if not MFAService.verify_totp(setup_data["secret"], token):
        raise HTTPException(
            status_code=400,
            detail="Invalid verification code"
        )
    
    # Save MFA settings
    current_user.mfa_secret = setup_data["secret"]
    current_user.mfa_enabled = True
    
    # Hash and save backup codes
    hashed_codes = [
        pwd_context.hash(code)
        for code in setup_data["backup_codes"]
    ]
    current_user.mfa_backup_codes = hashed_codes
    
    db.commit()
    
    # Clear setup data
    await cache.delete(f"mfa_setup:{current_user.id}")
    
    return {"message": "MFA enabled successfully"}

@app.post("/auth/login/mfa")
async def login_with_mfa(
    credentials: LoginRequest,
    mfa_token: Optional[str] = None
):
    """Login with MFA verification"""
    # First step: verify credentials
    user = await authenticate_user(credentials.email, credentials.password)
    
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )
    
    # Check if MFA is enabled
    if not user.mfa_enabled:
        # Regular login
        return create_token_response(user)
    
    # If MFA token not provided, return challenge
    if not mfa_token:
        # Create temporary token for MFA verification
        temp_token = create_temp_token(user.id)
        
        return {
            "mfa_required": True,
            "temp_token": temp_token,
            "mfa_types": ["totp", "backup_code"]
        }
    
    # Verify MFA token
    valid = False
    
    # Try TOTP first
    if len(mfa_token) == 6 and mfa_token.isdigit():
        valid = MFAService.verify_totp(user.mfa_secret, mfa_token)
    
    # Try backup code
    if not valid and len(mfa_token) == 8:
        for hashed_code in user.mfa_backup_codes:
            if pwd_context.verify(mfa_token, hashed_code):
                valid = True
                # Remove used backup code
                user.mfa_backup_codes.remove(hashed_code)
                db.commit()
                break
    
    if not valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid MFA code"
        )
    
    # Generate tokens
    return create_token_response(user)

# WebAuthn/Passkeys implementation
from webauthn import generate_registration_options, verify_registration_response
from webauthn import generate_authentication_options, verify_authentication_response

class WebAuthnService:
    """WebAuthn/Passkeys service"""
    
    @staticmethod
    async def generate_registration_options(user_id: int) -> dict:
        """Generate WebAuthn registration options"""
        user = await get_user_by_id(user_id)
        
        # Get user's existing credentials
        credentials = db.query(WebAuthnCredential).filter(
            WebAuthnCredential.user_id == user_id
        ).all()
        
        options = generate_registration_options(
            rp_id=settings.WEBAUTHN_RP_ID,
            rp_name=settings.WEBAUTHN_RP_NAME,
            user_id=str(user_id).encode(),
            user_name=user.email,
            user_display_name=user.name,
            exclude_credentials=[
                {"id": cred.credential_id, "type": "public-key"}
                for cred in credentials
            ],
            authenticator_selection={
                "authenticator_attachment": "platform",
                "user_verification": "preferred"
            },
            attestation="none"
        )
        
        # Store challenge
        await cache.set(
            f"webauthn_challenge:{user_id}",
            options.challenge,
            expire=300
        )
        
        return options
    
    @staticmethod
    async def verify_registration(
        user_id: int,
        credential: dict
    ) -> bool:
        """Verify WebAuthn registration"""
        # Get stored challenge
        expected_challenge = await cache.get(f"webauthn_challenge:{user_id}")
        
        if not expected_challenge:
            raise ValueError("Challenge not found or expired")
        
        verification = verify_registration_response(
            credential=credential,
            expected_challenge=expected_challenge,
            expected_origin=settings.FRONTEND_URL,
            expected_rp_id=settings.WEBAUTHN_RP_ID
        )
        
        if verification.verified:
            # Store credential
            db_credential = WebAuthnCredential(
                user_id=user_id,
                credential_id=verification.credential_id,
                public_key=verification.credential_public_key,
                sign_count=verification.sign_count,
                aaguid=verification.aaguid,
                fmt=verification.fmt,
                credential_type=verification.credential_type,
                user_verified=verification.user_verified
            )
            db.add(db_credential)
            db.commit()
        
        return verification.verified
```

## 🔑 Passwordless Authentication

### Magic Link Implementation

```python
# Email-based magic link authentication
class MagicLinkService:
    """Passwordless authentication via email"""
    
    @staticmethod
    def generate_magic_token() -> tuple[str, str]:
        """Generate magic link token and hash"""
        token = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        return token, token_hash
    
    @staticmethod
    async def send_magic_link(
        email: str,
        redirect_url: Optional[str] = None
    ):
        """Send magic link to user"""
        # Check if user exists
        user = await get_user_by_email(email)
        
        if not user:
            # Don't reveal if user exists
            return {"message": "If an account exists, a magic link has been sent"}
        
        # Generate token
        token, token_hash = MagicLinkService.generate_magic_token()
        
        # Store token with expiry
        await cache.set(
            f"magic_link:{token_hash}",
            {
                "user_id": user.id,
                "email": email,
                "redirect_url": redirect_url
            },
            expire=900  # 15 minutes
        )
        
        # Create magic link
        magic_link = f"{settings.FRONTEND_URL}/auth/magic?token={token}"
        if redirect_url:
            magic_link += f"&redirect={redirect_url}"
        
        # Send email
        await send_email(
            to=email,
            subject="Your login link",
            body=f"""
            Click the link below to log in to your account:
            
            {magic_link}
            
            This link will expire in 15 minutes.
            
            If you didn't request this, please ignore this email.
            """
        )
        
        return {"message": "Magic link sent to your email"}
    
    @staticmethod
    async def verify_magic_link(token: str) -> Optional[User]:
        """Verify magic link token"""
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        
        # Get token data
        token_data = await cache.get(f"magic_link:{token_hash}")
        
        if not token_data:
            return None
        
        # Get user
        user = await get_user_by_id(token_data["user_id"])
        
        # Delete token (one-time use)
        await cache.delete(f"magic_link:{token_hash}")
        
        # Log security event
        await log_security_event(
            user_id=user.id,
            event_type="magic_link_used",
            ip_address=request.client.host
        )
        
        return user

# Magic link endpoints
@app.post("/auth/magic/send")
async def send_magic_link(
    email: EmailStr,
    redirect_url: Optional[str] = None
):
    """Send magic link for passwordless login"""
    # Rate limiting
    rate_limit_key = f"magic_link_send:{email}"
    attempts = await cache.incr(rate_limit_key)
    
    if attempts == 1:
        await cache.expire(rate_limit_key, 3600)  # 1 hour
    
    if attempts > 3:
        raise HTTPException(
            status_code=429,
            detail="Too many magic link requests"
        )
    
    # Send magic link
    result = await MagicLinkService.send_magic_link(
        email=email,
        redirect_url=redirect_url
    )
    
    return result

@app.post("/auth/magic/verify")
async def verify_magic_link(
    token: str,
    request: Request
):
    """Verify magic link and create session"""
    # Verify token
    user = await MagicLinkService.verify_magic_link(token)
    
    if not user:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired magic link"
        )
    
    # Create tokens
    access_token = TokenService.create_access_token(
        data={"sub": str(user.id), "email": user.email}
    )
    refresh_token = TokenService.create_refresh_token(
        data={"sub": str(user.id)}
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name
        }
    }

# SMS/Phone-based authentication
class SMSAuthService:
    """SMS-based authentication"""
    
    @staticmethod
    async def send_otp(phone_number: str) -> bool:
        """Send OTP via SMS"""
        # Generate OTP
        otp = ''.join(secrets.choice('0123456789') for _ in range(6))
        
        # Store OTP with expiry
        await cache.set(
            f"sms_otp:{phone_number}",
            {
                "otp": otp,
                "attempts": 0
            },
            expire=300  # 5 minutes
        )
        
        # Send SMS (using Twilio/AWS SNS/etc)
        try:
            await sms_client.send_message(
                to=phone_number,
                body=f"Your verification code is: {otp}"
            )
            return True
        except Exception as e:
            logger.error(f"Failed to send SMS: {e}")
            return False
    
    @staticmethod
    async def verify_otp(
        phone_number: str,
        otp: str
    ) -> bool:
        """Verify SMS OTP"""
        # Get stored OTP
        otp_data = await cache.get(f"sms_otp:{phone_number}")
        
        if not otp_data:
            return False
        
        # Check attempts
        if otp_data["attempts"] >= 3:
            await cache.delete(f"sms_otp:{phone_number}")
            return False
        
        # Verify OTP
        if otp_data["otp"] != otp:
            otp_data["attempts"] += 1
            await cache.set(
                f"sms_otp:{phone_number}",
                otp_data,
                expire=300
            )
            return False
        
        # Clear OTP
        await cache.delete(f"sms_otp:{phone_number}")
        return True
```

## 🛡️ Security Best Practices

### Password Security

```python
# Enhanced password security
from zxcvbn import zxcvbn

class PasswordPolicy:
    """Password security policy"""
    
    MIN_LENGTH = 12
    REQUIRE_UPPERCASE = True
    REQUIRE_LOWERCASE = True
    REQUIRE_NUMBERS = True
    REQUIRE_SPECIAL = True
    MIN_STRENGTH_SCORE = 3  # zxcvbn score (0-4)
    
    @classmethod
    def validate_password(
        cls,
        password: str,
        user_inputs: List[str] = None
    ) -> tuple[bool, List[str]]:
        """Validate password against policy"""
        errors = []
        
        # Length check
        if len(password) < cls.MIN_LENGTH:
            errors.append(f"Password must be at least {cls.MIN_LENGTH} characters")
        
        # Character requirements
        if cls.REQUIRE_UPPERCASE and not any(c.isupper() for c in password):
            errors.append("Password must contain uppercase letters")
        
        if cls.REQUIRE_LOWERCASE and not any(c.islower() for c in password):
            errors.append("Password must contain lowercase letters")
        
        if cls.REQUIRE_NUMBERS and not any(c.isdigit() for c in password):
            errors.append("Password must contain numbers")
        
        if cls.REQUIRE_SPECIAL and not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
            errors.append("Password must contain special characters")
        
        # Strength check
        result = zxcvbn(password, user_inputs=user_inputs or [])
        if result["score"] < cls.MIN_STRENGTH_SCORE:
            errors.append(f"Password is too weak: {result['feedback']['warning']}")
            if result["feedback"]["suggestions"]:
                errors.extend(result["feedback"]["suggestions"])
        
        return len(errors) == 0, errors

# Account security
class AccountSecurityService:
    """Account security management"""
    
    @staticmethod
    async def check_breach_password(password: str) -> bool:
        """Check if password has been in a breach (using HaveIBeenPwned)"""
        # SHA-1 hash the password
        sha1_hash = hashlib.sha1(password.encode()).hexdigest().upper()
        prefix = sha1_hash[:5]
        suffix = sha1_hash[5:]
        
        # Query HIBP API
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.pwnedpasswords.com/range/{prefix}"
            )
            
            if response.status_code != 200:
                return False  # Assume safe if API fails
            
            # Check if suffix appears in response
            for line in response.text.splitlines():
                hash_suffix, count = line.split(":")
                if hash_suffix == suffix:
                    return True  # Password found in breach
        
        return False
    
    @staticmethod
    async def detect_suspicious_login(
        user_id: int,
        ip_address: str,
        user_agent: str
    ) -> bool:
        """Detect suspicious login attempts"""
        # Get user's login history
        recent_logins = await get_recent_logins(user_id, limit=10)
        
        # Check for new location
        if not any(login.ip_address == ip_address for login in recent_logins):
            # New IP address - could be suspicious
            location = await get_ip_location(ip_address)
            
            # Check if location is far from usual locations
            usual_locations = [
                await get_ip_location(login.ip_address)
                for login in recent_logins[:3]
            ]
            
            for usual_loc in usual_locations:
                distance = calculate_distance(location, usual_loc)
                if distance > 1000:  # 1000 km
                    return True
        
        # Check for rapid location changes
        last_login = recent_logins[0] if recent_logins else None
        if last_login:
            time_diff = datetime.utcnow() - last_login.timestamp
            location_diff = calculate_distance(
                await get_ip_location(ip_address),
                await get_ip_location(last_login.ip_address)
            )
            
            # Impossible travel detection
            max_speed = 1000  # km/h (approximate flight speed)
            max_distance = (time_diff.total_seconds() / 3600) * max_speed
            
            if location_diff > max_distance:
                return True
        
        return False

# Security headers middleware
@app.middleware("http")
async def security_headers(request: Request, call_next):
    """Add security headers to responses"""
    response = await call_next(request)
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    
    return response

# Brute force protection
class BruteForceProtection:
    """Protect against brute force attacks"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def check_rate_limit(
        self,
        key: str,
        max_attempts: int = 5,
        window_seconds: int = 300
    ) -> tuple[bool, int]:
        """Check if rate limit exceeded"""
        current = await self.redis.incr(key)
        
        if current == 1:
            await self.redis.expire(key, window_seconds)
        
        return current <= max_attempts, current
    
    async def check_login_attempts(
        self,
        email: str,
        ip_address: str
    ) -> tuple[bool, str]:
        """Check login attempt limits"""
        # Check by email
        email_key = f"login_attempts:email:{email}"
        email_allowed, email_attempts = await self.check_rate_limit(
            email_key,
            max_attempts=5,
            window_seconds=300
        )
        
        if not email_allowed:
            return False, f"Too many login attempts for {email}"
        
        # Check by IP
        ip_key = f"login_attempts:ip:{ip_address}"
        ip_allowed, ip_attempts = await self.check_rate_limit(
            ip_key,
            max_attempts=10,
            window_seconds=300
        )
        
        if not ip_allowed:
            return False, "Too many login attempts from this IP"
        
        return True, ""
    
    async def record_failed_attempt(
        self,
        email: str,
        ip_address: str
    ):
        """Record failed login attempt"""
        # Increment counters
        await self.redis.incr(f"login_attempts:email:{email}")
        await self.redis.incr(f"login_attempts:ip:{ip_address}")
        
        # Track pattern for anomaly detection
        await self.redis.lpush(
            f"failed_logins:{email}",
            json.dumps({
                "ip": ip_address,
                "timestamp": datetime.utcnow().isoformat()
            })
        )
        await self.redis.ltrim(f"failed_logins:{email}", 0, 99)
```

## 🚀 Best Practices

### 1. **Token Security**
- Use short-lived access tokens (15-30 minutes)
- Implement refresh token rotation
- Store tokens securely (httpOnly cookies, secure storage)
- Include token validation middleware
- Implement token revocation

### 2. **Password Management**
- Enforce strong password policies
- Use secure hashing (bcrypt, argon2)
- Implement password breach checking
- Support password reset flows
- Never store plain text passwords

### 3. **Session Security**
- Regenerate session IDs on login
- Implement session timeout
- Secure session cookies (httpOnly, secure, sameSite)
- Monitor concurrent sessions
- Clear sessions on logout

### 4. **Multi-Factor Authentication**
- Support multiple MFA methods
- Provide backup codes
- Implement rate limiting on MFA attempts
- Allow users to manage devices
- Log MFA events

### 5. **OAuth2/OIDC**
- Use PKCE for public clients
- Validate all tokens properly
- Implement proper scopes
- Handle token refresh gracefully
- Support multiple providers

### 6. **Security Monitoring**
- Log all authentication events
- Detect suspicious patterns
- Implement account lockout
- Send security alerts
- Regular security audits

## 📖 Resources & References

### Standards & Specifications
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn/)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)

### Libraries & Tools
- **Python** - PyJWT, python-jose, authlib, passlib
- **Node.js** - jsonwebtoken, passport, node-jose
- **Testing** - OWASP ZAP, Burp Suite
- **MFA** - pyotp, speakeasy, authenticator

---

*This guide covers essential authentication patterns for building secure applications. Always follow security best practices and stay updated with the latest vulnerabilities and patches.*
# Session-Based Authentication

Traditional server-side session management for stateful authentication.

## Server-Side Sessions

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

## Enhanced Session Security

```python
# Advanced session security features
class SessionSecurityMiddleware:
    """Middleware for session security"""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            # Session fixation protection
            headers = dict(scope["headers"])
            session_id = self.extract_session_id(headers)
            
            if session_id:
                # Validate session fingerprint
                if not await self.validate_fingerprint(session_id, headers):
                    # Possible session hijack attempt
                    await self.invalidate_session(session_id)
                    scope["session_invalid"] = True
        
        await self.app(scope, receive, send)
    
    async def validate_fingerprint(
        self,
        session_id: str,
        headers: dict
    ) -> bool:
        """Validate session fingerprint"""
        session_data = await session_backend.read(session_id)
        
        if not session_data:
            return False
        
        # Compare fingerprints
        current_fingerprint = self.generate_fingerprint(headers)
        stored_fingerprint = session_data.get("fingerprint")
        
        return secrets.compare_digest(
            current_fingerprint,
            stored_fingerprint
        )
    
    def generate_fingerprint(self, headers: dict) -> str:
        """Generate session fingerprint"""
        # Combine stable browser characteristics
        user_agent = headers.get(b"user-agent", b"").decode()
        accept_language = headers.get(b"accept-language", b"").decode()
        accept_encoding = headers.get(b"accept-encoding", b"").decode()
        
        fingerprint_data = f"{user_agent}|{accept_language}|{accept_encoding}"
        
        return hashlib.sha256(fingerprint_data.encode()).hexdigest()

# Session storage strategies
class SessionStorage:
    """Multiple session storage backends"""
    
    def __init__(self):
        self.backends = {
            "redis": RedisSessionBackend(),
            "database": DatabaseSessionBackend(),
            "memory": MemorySessionBackend()
        }
    
    async def create_session(
        self,
        user_id: int,
        data: dict,
        backend: str = "redis"
    ) -> str:
        """Create session in specified backend"""
        backend_instance = self.backends.get(backend)
        
        if not backend_instance:
            raise ValueError(f"Unknown backend: {backend}")
        
        return await backend_instance.create(user_id, data)

class DatabaseSessionBackend:
    """Database-backed sessions"""
    
    async def create(self, user_id: int, data: dict) -> str:
        """Create session in database"""
        session_id = str(uuid4())
        
        session = await Session.create(
            session_id=session_id,
            user_id=user_id,
            data=json.dumps(data),
            expires_at=datetime.utcnow() + timedelta(
                seconds=SESSION_EXPIRE_SECONDS
            )
        )
        
        return session_id
    
    async def read(self, session_id: str) -> Optional[dict]:
        """Read session from database"""
        session = await Session.get(session_id=session_id)
        
        if not session:
            return None
        
        # Check expiry
        if session.expires_at <= datetime.utcnow():
            await session.delete()
            return None
        
        return json.loads(session.data)
    
    async def update(self, session_id: str, data: dict):
        """Update session in database"""
        await Session.filter(session_id=session_id).update(
            data=json.dumps(data),
            updated_at=datetime.utcnow()
        )
    
    async def delete(self, session_id: str):
        """Delete session from database"""
        await Session.filter(session_id=session_id).delete()
```

## Session Management Best Practices

### Cookie Security
```python
# Secure cookie configuration
SECURE_COOKIE_PARAMS = {
    "httponly": True,       # Prevent JavaScript access
    "secure": True,         # HTTPS only
    "samesite": "strict",   # CSRF protection
    "max_age": 3600,       # 1 hour expiry
    "path": "/",           # Cookie path
    "domain": None         # Current domain only
}

# Session cookie with encryption
from cryptography.fernet import Fernet

class EncryptedSessionCookie:
    """Encrypted session cookie handler"""
    
    def __init__(self, secret_key: str):
        self.cipher = Fernet(secret_key.encode())
    
    def create_cookie_value(self, session_id: str) -> str:
        """Create encrypted cookie value"""
        # Add timestamp for additional validation
        data = {
            "session_id": session_id,
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Encrypt data
        encrypted = self.cipher.encrypt(
            json.dumps(data).encode()
        )
        
        return base64.urlsafe_b64encode(encrypted).decode()
    
    def parse_cookie_value(self, cookie_value: str) -> Optional[str]:
        """Parse and validate encrypted cookie"""
        try:
            # Decode and decrypt
            encrypted = base64.urlsafe_b64decode(cookie_value)
            decrypted = self.cipher.decrypt(encrypted)
            data = json.loads(decrypted)
            
            # Validate timestamp
            created_at = datetime.fromisoformat(data["created_at"])
            if datetime.utcnow() - created_at > timedelta(hours=24):
                return None
            
            return data["session_id"]
        
        except Exception:
            return None
```

### Session Lifecycle Management
```python
class SessionLifecycleManager:
    """Manage session lifecycle events"""
    
    async def on_session_create(self, session_id: str, user_id: int):
        """Handle session creation"""
        # Log session creation
        await audit_log.create(
            event_type="session_created",
            user_id=user_id,
            session_id=session_id,
            timestamp=datetime.utcnow()
        )
        
        # Send notification if configured
        if await should_notify_new_session(user_id):
            await send_new_session_notification(user_id)
    
    async def on_session_destroy(self, session_id: str):
        """Handle session destruction"""
        # Get session data before deletion
        session_data = await session_backend.read(session_id)
        
        if session_data:
            # Log session destruction
            await audit_log.create(
                event_type="session_destroyed",
                user_id=session_data.user_id,
                session_id=session_id,
                timestamp=datetime.utcnow()
            )
    
    async def cleanup_expired_sessions(self):
        """Periodic cleanup of expired sessions"""
        # Run as background task
        while True:
            # Clean Redis sessions
            expired_keys = await redis_client.keys("session:*")
            
            for key in expired_keys:
                ttl = await redis_client.ttl(key)
                if ttl == -1:  # No expiry set
                    await redis_client.expire(
                        key,
                        SESSION_EXPIRE_SECONDS
                    )
            
            # Clean database sessions
            await Session.filter(
                expires_at__lt=datetime.utcnow()
            ).delete()
            
            # Sleep for cleanup interval
            await asyncio.sleep(3600)  # Run hourly
```

### Session-Based CSRF Protection
```python
class CSRFProtection:
    """CSRF protection for session-based auth"""
    
    @staticmethod
    def generate_csrf_token() -> str:
        """Generate CSRF token"""
        return secrets.token_urlsafe(32)
    
    @staticmethod
    async def validate_csrf_token(
        request: Request,
        session_data: SessionData
    ) -> bool:
        """Validate CSRF token"""
        # Get token from header or form
        token_from_request = (
            request.headers.get("X-CSRF-Token") or
            (await request.form()).get("csrf_token")
        )
        
        if not token_from_request:
            return False
        
        # Get token from session
        token_from_session = session_data.get("csrf_token")
        
        if not token_from_session:
            return False
        
        # Constant-time comparison
        return secrets.compare_digest(
            token_from_request,
            token_from_session
        )
    
    @staticmethod
    def csrf_protect(methods: List[str] = ["POST", "PUT", "DELETE"]):
        """Decorator for CSRF protection"""
        def decorator(func):
            @wraps(func)
            async def wrapper(
                request: Request,
                session_data: SessionData = Depends(get_current_session),
                *args,
                **kwargs
            ):
                if request.method in methods:
                    if not await CSRFProtection.validate_csrf_token(
                        request,
                        session_data
                    ):
                        raise HTTPException(
                            status_code=403,
                            detail="CSRF validation failed"
                        )
                
                return await func(request, session_data, *args, **kwargs)
            
            return wrapper
        return decorator

# Usage
@app.post("/api/transfer")
@CSRFProtection.csrf_protect()
async def transfer_funds(
    request: Request,
    session_data: SessionData,
    transfer_data: TransferRequest
):
    """Protected endpoint requiring CSRF token"""
    # Process transfer
    return {"status": "success"}
```

### Remember Me Functionality
```python
class RememberMeService:
    """Persistent authentication tokens"""
    
    async def create_remember_token(
        self,
        user_id: int,
        device_info: dict
    ) -> str:
        """Create remember me token"""
        # Generate secure token
        selector = secrets.token_urlsafe(16)
        validator = secrets.token_urlsafe(32)
        
        # Hash validator for storage
        validator_hash = hashlib.sha256(
            validator.encode()
        ).hexdigest()
        
        # Store in database
        await RememberToken.create(
            user_id=user_id,
            selector=selector,
            validator_hash=validator_hash,
            device_info=device_info,
            expires_at=datetime.utcnow() + timedelta(days=30),
            created_at=datetime.utcnow()
        )
        
        # Return combined token
        return f"{selector}:{validator}"
    
    async def validate_remember_token(
        self,
        token: str
    ) -> Optional[int]:
        """Validate remember me token"""
        try:
            selector, validator = token.split(":")
        except ValueError:
            return None
        
        # Find token by selector
        token_record = await RememberToken.get(selector=selector)
        
        if not token_record:
            return None
        
        # Check expiry
        if token_record.expires_at <= datetime.utcnow():
            await token_record.delete()
            return None
        
        # Verify validator
        validator_hash = hashlib.sha256(
            validator.encode()
        ).hexdigest()
        
        if not secrets.compare_digest(
            validator_hash,
            token_record.validator_hash
        ):
            # Possible token theft - invalidate all tokens
            await RememberToken.filter(
                user_id=token_record.user_id
            ).delete()
            return None
        
        # Update last used
        token_record.last_used = datetime.utcnow()
        await token_record.save()
        
        return token_record.user_id
```
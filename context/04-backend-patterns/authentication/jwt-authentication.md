# JWT Authentication

JSON Web Tokens (JWT) provide stateless, scalable authentication for modern applications.

## JWT Implementation

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
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=401,
                detail="Invalid token"
            )
```

## FastAPI JWT Authentication

```python
# FastAPI JWT authentication implementation
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

app = FastAPI()

# Security
security = HTTPBearer()

# Request/Response models
class UserLogin(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class User(BaseModel):
    id: int
    email: str
    is_active: bool

# Authentication endpoints
@app.post("/auth/login", response_model=TokenResponse)
async def login(
    credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """User login endpoint"""
    # Verify user credentials
    user = authenticate_user(db, credentials.email, credentials.password)
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid credentials"
        )
    
    # Create tokens
    access_token = TokenService.create_access_token(
        data={"sub": str(user.id), "email": user.email}
    )
    refresh_token = TokenService.create_refresh_token(
        data={"sub": str(user.id)}
    )
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token
    )

@app.post("/auth/refresh", response_model=TokenResponse)
async def refresh_token(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db)
):
    """Refresh access token"""
    token = credentials.credentials
    
    # Decode and validate refresh token
    try:
        payload = TokenService.decode_token(token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        user_id = payload.get("sub")
        user = get_user(db, user_id)
        
        if not user or not user.is_active:
            raise HTTPException(status_code=401, detail="User not found or inactive")
        
        # Create new tokens
        access_token = TokenService.create_access_token(
            data={"sub": str(user.id), "email": user.email}
        )
        new_refresh_token = TokenService.create_refresh_token(
            data={"sub": str(user.id)}
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=new_refresh_token
        )
    
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

# Dependency for protected routes
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    token = credentials.credentials
    
    try:
        payload = TokenService.decode_token(token)
        if payload.get("type") != "access":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        user_id = payload.get("sub")
        user = get_user(db, user_id)
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return user
    
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authentication")

# Protected endpoint example
@app.get("/users/me", response_model=User)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    return current_user
```

## Enhanced JWT Security

```python
# Advanced JWT security features
from typing import Set
import redis

# Redis for token blacklist
redis_client = redis.Redis(decode_responses=True)

class EnhancedTokenService(TokenService):
    """Enhanced JWT service with additional security"""
    
    @staticmethod
    def create_access_token(
        data: Dict[str, Any],
        expires_delta: Optional[timedelta] = None,
        scopes: Optional[List[str]] = None
    ) -> str:
        """Create access token with scopes"""
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
            "type": "access",
            "scopes": scopes or []
        })
        
        return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    
    @staticmethod
    def revoke_token(token: str):
        """Add token to blacklist"""
        try:
            payload = jwt.decode(
                token,
                JWT_SECRET_KEY,
                algorithms=[JWT_ALGORITHM]
            )
            
            # Add to blacklist with TTL matching token expiry
            exp = payload.get("exp")
            ttl = exp - datetime.now(timezone.utc).timestamp()
            
            if ttl > 0:
                redis_client.setex(
                    f"blacklist:{token}",
                    int(ttl),
                    "revoked"
                )
        except Exception:
            pass
    
    @staticmethod
    def is_token_revoked(token: str) -> bool:
        """Check if token is blacklisted"""
        return redis_client.exists(f"blacklist:{token}")

# Scope-based authorization
def require_scopes(*required_scopes: str):
    """Decorator for scope-based authorization"""
    async def scope_checker(
        current_user: User = Depends(get_current_user),
        token: str = Depends(get_token)
    ):
        payload = TokenService.decode_token(token)
        token_scopes = set(payload.get("scopes", []))
        
        for scope in required_scopes:
            if scope not in token_scopes:
                raise HTTPException(
                    status_code=403,
                    detail=f"Missing required scope: {scope}"
                )
        
        return current_user
    
    return scope_checker

# Usage with scopes
@app.get("/admin/users")
async def get_all_users(
    current_user: User = Depends(require_scopes("admin:read"))
):
    """Admin endpoint requiring specific scope"""
    return {"users": []}
```

## JWT Best Practices

### Token Configuration
```python
# Secure JWT configuration
import os
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

class JWTConfig:
    """Production JWT configuration"""
    
    # Use RS256 for production
    ALGORITHM = "RS256"
    
    # Short-lived access tokens
    ACCESS_TOKEN_EXPIRE_MINUTES = 15
    
    # Longer refresh tokens
    REFRESH_TOKEN_EXPIRE_DAYS = 30
    
    # Separate keys for signing and verification
    @staticmethod
    def generate_rsa_keys():
        """Generate RSA key pair for JWT"""
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048
        )
        
        private_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )
        
        public_key = private_key.public_key()
        public_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )
        
        return private_pem, public_pem
```

### Security Considerations

1. **Token Storage**:
   - Never store tokens in localStorage (XSS vulnerable)
   - Use httpOnly cookies or memory storage
   - Consider token binding to prevent token theft

2. **Token Rotation**:
   - Implement automatic token rotation
   - Use refresh token rotation
   - Invalidate old tokens after rotation

3. **Payload Security**:
   - Minimize sensitive data in tokens
   - Don't include passwords or secrets
   - Use user IDs instead of emails

4. **Algorithm Security**:
   - Use RS256 or ES256 for production
   - Never use "none" algorithm
   - Validate algorithm in decode

5. **Token Validation**:
   - Always validate expiration
   - Check issuer and audience
   - Verify token hasn't been revoked

## Common Issues & Solutions

### Issue: Token Size
```python
# Problem: JWT too large for headers
# Solution: Use reference tokens
class ReferenceTokenService:
    """Store tokens in backend, return references"""
    
    @staticmethod
    def create_reference_token(user_id: str) -> str:
        """Create reference token"""
        reference = secrets.token_urlsafe(32)
        
        # Store actual JWT in Redis
        jwt_token = TokenService.create_access_token(
            data={"sub": user_id}
        )
        
        redis_client.setex(
            f"ref_token:{reference}",
            JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            jwt_token
        )
        
        return reference
```

### Issue: Clock Skew
```python
# Problem: Token rejected due to time differences
# Solution: Add leeway to validation
def decode_token_with_leeway(token: str) -> Dict[str, Any]:
    """Decode token with clock skew tolerance"""
    return jwt.decode(
        token,
        JWT_SECRET_KEY,
        algorithms=[JWT_ALGORITHM],
        options={"leeway": 10}  # 10 seconds tolerance
    )
```

### Issue: Concurrent Refresh
```python
# Problem: Multiple refresh requests cause issues
# Solution: Implement refresh token family
class RefreshTokenFamily:
    """Handle refresh token families"""
    
    @staticmethod
    def create_family(user_id: str) -> str:
        """Create new token family"""
        family_id = secrets.token_urlsafe(16)
        
        # Store family in database
        store_token_family(user_id, family_id)
        
        return TokenService.create_refresh_token(
            data={
                "sub": user_id,
                "family": family_id,
                "version": 1
            }
        )
    
    @staticmethod
    def rotate_refresh_token(old_token: str) -> tuple[str, str]:
        """Rotate refresh token maintaining family"""
        payload = TokenService.decode_token(old_token)
        
        # Invalidate entire family if reuse detected
        if is_token_used(old_token):
            invalidate_token_family(payload["family"])
            raise HTTPException(
                status_code=401,
                detail="Token reuse detected"
            )
        
        # Mark old token as used
        mark_token_used(old_token)
        
        # Create new tokens
        access_token = TokenService.create_access_token(
            data={"sub": payload["sub"]}
        )
        
        refresh_token = TokenService.create_refresh_token(
            data={
                "sub": payload["sub"],
                "family": payload["family"],
                "version": payload["version"] + 1
            }
        )
        
        return access_token, refresh_token
```
# API Key Authentication

Service-to-service authentication using API keys with comprehensive security features.

## API Key Management

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

## Advanced API Key Features

### Rate Limiting
```python
class APIKeyRateLimiter:
    """Rate limiting for API keys"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def check_rate_limit(
        self,
        api_key_id: int,
        limits: Dict[str, int]
    ) -> bool:
        """Check if API key has exceeded rate limits"""
        current_time = datetime.utcnow()
        
        for window, limit in limits.items():
            # Calculate window key
            if window == "minute":
                window_key = current_time.strftime("%Y%m%d%H%M")
            elif window == "hour":
                window_key = current_time.strftime("%Y%m%d%H")
            elif window == "day":
                window_key = current_time.strftime("%Y%m%d")
            else:
                continue
            
            # Check current count
            key = f"rate_limit:{api_key_id}:{window}:{window_key}"
            count = await self.redis.incr(key)
            
            # Set expiry on first increment
            if count == 1:
                if window == "minute":
                    await self.redis.expire(key, 60)
                elif window == "hour":
                    await self.redis.expire(key, 3600)
                elif window == "day":
                    await self.redis.expire(key, 86400)
            
            # Check limit
            if count > limit:
                return False
        
        return True

# Rate limiting middleware
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """Apply rate limiting to API key requests"""
    # Check if request has API key
    api_key_header = request.headers.get("X-API-Key")
    
    if api_key_header:
        # Validate key
        api_key = await APIKeyService.validate_api_key(api_key_header)
        
        if api_key:
            # Get rate limits for key
            rate_limits = {
                "minute": 60,
                "hour": 1000,
                "day": 10000
            }
            
            # Check rate limit
            rate_limiter = APIKeyRateLimiter(redis_client)
            allowed = await rate_limiter.check_rate_limit(
                api_key.id,
                rate_limits
            )
            
            if not allowed:
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Rate limit exceeded"}
                )
    
    response = await call_next(request)
    return response
```

### API Key Rotation
```python
class APIKeyRotation:
    """API key rotation management"""
    
    @staticmethod
    async def rotate_api_key(
        old_key_id: int,
        user_id: int,
        grace_period_hours: int = 24
    ) -> Dict[str, Any]:
        """Rotate API key with grace period"""
        # Get old key
        old_key = db.query(APIKeyModel).filter(
            APIKeyModel.id == old_key_id,
            APIKeyModel.user_id == user_id
        ).first()
        
        if not old_key:
            raise ValueError("API key not found")
        
        # Create new key with same settings
        new_key_result = await APIKeyService.create_api_key(
            user_id=user_id,
            name=f"{old_key.name} (rotated)",
            scopes=old_key.scopes,
            ip_whitelist=old_key.ip_whitelist
        )
        
        # Set expiration on old key
        old_key.expires_at = datetime.utcnow() + timedelta(
            hours=grace_period_hours
        )
        db.commit()
        
        # Notify user
        await send_api_key_rotation_notification(
            user_id,
            old_key_prefix=old_key.prefix,
            new_key_prefix=new_key_result["prefix"],
            grace_period_hours=grace_period_hours
        )
        
        return new_key_result

# Automatic rotation
class AutomaticKeyRotation:
    """Automatic API key rotation policy"""
    
    @staticmethod
    async def check_keys_for_rotation():
        """Check and rotate old API keys"""
        # Find keys older than rotation period
        rotation_period = timedelta(days=90)
        cutoff_date = datetime.utcnow() - rotation_period
        
        old_keys = db.query(APIKeyModel).filter(
            APIKeyModel.created_at < cutoff_date,
            APIKeyModel.is_active == True,
            APIKeyModel.expires_at == None  # Don't rotate expiring keys
        ).all()
        
        for key in old_keys:
            try:
                await APIKeyRotation.rotate_api_key(
                    old_key_id=key.id,
                    user_id=key.user_id,
                    grace_period_hours=168  # 1 week
                )
            except Exception as e:
                logger.error(f"Failed to rotate key {key.id}: {e}")
```

### API Key Analytics
```python
class APIKeyAnalytics:
    """Track API key usage patterns"""
    
    def __init__(self, db, redis_client):
        self.db = db
        self.redis = redis_client
    
    async def track_request(
        self,
        api_key_id: int,
        endpoint: str,
        method: str,
        status_code: int,
        response_time_ms: float
    ):
        """Track API request metrics"""
        # Real-time metrics in Redis
        timestamp = datetime.utcnow()
        hour_bucket = timestamp.strftime("%Y%m%d%H")
        
        # Increment counters
        await self.redis.hincrby(
            f"api_metrics:{api_key_id}:{hour_bucket}",
            f"{method}:{endpoint}:{status_code}",
            1
        )
        
        # Track response time
        await self.redis.lpush(
            f"api_response_times:{api_key_id}:{hour_bucket}",
            response_time_ms
        )
        
        # Trim list to last 1000 requests
        await self.redis.ltrim(
            f"api_response_times:{api_key_id}:{hour_bucket}",
            0,
            999
        )
        
        # Set expiry
        await self.redis.expire(
            f"api_metrics:{api_key_id}:{hour_bucket}",
            86400  # 24 hours
        )
    
    async def get_usage_report(
        self,
        api_key_id: int,
        start_date: datetime,
        end_date: datetime
    ) -> Dict[str, Any]:
        """Generate usage report for API key"""
        # Aggregate metrics from Redis
        total_requests = 0
        endpoint_breakdown = {}
        status_breakdown = {}
        
        current = start_date
        while current <= end_date:
            hour_bucket = current.strftime("%Y%m%d%H")
            metrics = await self.redis.hgetall(
                f"api_metrics:{api_key_id}:{hour_bucket}"
            )
            
            for key, count in metrics.items():
                method, endpoint, status = key.split(":")
                total_requests += int(count)
                
                # Endpoint breakdown
                endpoint_key = f"{method} {endpoint}"
                endpoint_breakdown[endpoint_key] = \
                    endpoint_breakdown.get(endpoint_key, 0) + int(count)
                
                # Status breakdown
                status_breakdown[status] = \
                    status_breakdown.get(status, 0) + int(count)
            
            current += timedelta(hours=1)
        
        return {
            "total_requests": total_requests,
            "endpoint_breakdown": endpoint_breakdown,
            "status_breakdown": status_breakdown,
            "period": {
                "start": start_date.isoformat(),
                "end": end_date.isoformat()
            }
        }
```

### Webhook Authentication
```python
class WebhookSigner:
    """Sign and verify webhook payloads"""
    
    @staticmethod
    def sign_payload(
        payload: bytes,
        secret: str,
        algorithm: str = "sha256"
    ) -> str:
        """Sign webhook payload"""
        if algorithm == "sha256":
            signature = hmac.new(
                secret.encode(),
                payload,
                hashlib.sha256
            ).hexdigest()
            return f"sha256={signature}"
        else:
            raise ValueError(f"Unsupported algorithm: {algorithm}")
    
    @staticmethod
    def verify_signature(
        payload: bytes,
        signature: str,
        secret: str
    ) -> bool:
        """Verify webhook signature"""
        expected_signature = WebhookSigner.sign_payload(
            payload,
            secret
        )
        
        return secrets.compare_digest(
            signature,
            expected_signature
        )

# Webhook endpoint with signature verification
@app.post("/webhooks/github")
async def github_webhook(
    request: Request,
    x_hub_signature_256: str = Header(None)
):
    """Handle GitHub webhook with signature verification"""
    if not x_hub_signature_256:
        raise HTTPException(
            status_code=401,
            detail="Missing signature"
        )
    
    # Get raw body
    body = await request.body()
    
    # Verify signature
    if not WebhookSigner.verify_signature(
        body,
        x_hub_signature_256,
        settings.GITHUB_WEBHOOK_SECRET
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid signature"
        )
    
    # Process webhook
    data = await request.json()
    await process_github_webhook(data)
    
    return {"status": "accepted"}
```

### Service-to-Service Authentication
```python
class ServiceAuthenticator:
    """Service-to-service authentication"""
    
    @staticmethod
    async def authenticate_service(
        service_id: str,
        service_secret: str
    ) -> Optional[Dict[str, Any]]:
        """Authenticate service credentials"""
        # Hash secret for comparison
        secret_hash = hashlib.sha256(
            service_secret.encode()
        ).hexdigest()
        
        # Look up service
        service = db.query(ServiceModel).filter(
            ServiceModel.service_id == service_id,
            ServiceModel.secret_hash == secret_hash,
            ServiceModel.is_active == True
        ).first()
        
        if not service:
            return None
        
        # Generate short-lived token
        token_data = {
            "service_id": service_id,
            "scopes": service.scopes,
            "exp": datetime.utcnow() + timedelta(minutes=5)
        }
        
        token = jwt.encode(
            token_data,
            settings.SERVICE_TOKEN_SECRET,
            algorithm="HS256"
        )
        
        return {
            "token": token,
            "expires_in": 300  # 5 minutes
        }

# Service authentication endpoint
@app.post("/auth/service/token")
async def get_service_token(
    credentials: ServiceCredentials
):
    """Exchange service credentials for token"""
    result = await ServiceAuthenticator.authenticate_service(
        credentials.service_id,
        credentials.service_secret
    )
    
    if not result:
        raise HTTPException(
            status_code=401,
            detail="Invalid service credentials"
        )
    
    return result
```
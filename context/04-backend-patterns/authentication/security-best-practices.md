# Security Best Practices

Comprehensive security measures and best practices for authentication systems.

## Password Security

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

## Advanced Security Measures

### Account Lockout Protection
```python
class AccountLockoutService:
    """Progressive account lockout with backoff"""
    
    LOCKOUT_THRESHOLDS = [
        (3, 60),      # 3 attempts: 1 minute
        (5, 300),     # 5 attempts: 5 minutes
        (10, 1800),   # 10 attempts: 30 minutes
        (15, 7200),   # 15 attempts: 2 hours
        (20, 86400)   # 20 attempts: 24 hours
    ]
    
    async def check_lockout(self, user_id: int) -> tuple[bool, int]:
        """Check if account is locked out"""
        key = f"lockout:{user_id}"
        lockout_data = await cache.get(key)
        
        if lockout_data:
            remaining = lockout_data["expires_at"] - datetime.utcnow().timestamp()
            if remaining > 0:
                return True, int(remaining)
        
        return False, 0
    
    async def record_failed_attempt(self, user_id: int):
        """Record failed attempt and apply lockout if needed"""
        key = f"failed_attempts:{user_id}"
        attempts = await cache.incr(key)
        
        if attempts == 1:
            await cache.expire(key, 86400)  # Reset after 24 hours
        
        # Check lockout thresholds
        for threshold, duration in self.LOCKOUT_THRESHOLDS:
            if attempts == threshold:
                await cache.set(
                    f"lockout:{user_id}",
                    {
                        "locked_at": datetime.utcnow().timestamp(),
                        "expires_at": datetime.utcnow().timestamp() + duration,
                        "attempts": attempts
                    },
                    expire=duration
                )
                break
    
    async def clear_failed_attempts(self, user_id: int):
        """Clear failed attempts after successful login"""
        await cache.delete(f"failed_attempts:{user_id}")
        await cache.delete(f"lockout:{user_id}")
```

### Device Fingerprinting
```python
class DeviceFingerprint:
    """Device fingerprinting for anomaly detection"""
    
    @staticmethod
    def generate_fingerprint(request: Request) -> dict:
        """Generate device fingerprint from request"""
        headers = dict(request.headers)
        
        fingerprint = {
            "user_agent": headers.get("user-agent", ""),
            "accept_language": headers.get("accept-language", ""),
            "accept_encoding": headers.get("accept-encoding", ""),
            "accept": headers.get("accept", ""),
            "dnt": headers.get("dnt", ""),
            "connection": headers.get("connection", ""),
            "sec_fetch_site": headers.get("sec-fetch-site", ""),
            "sec_fetch_mode": headers.get("sec-fetch-mode", ""),
            "sec_fetch_dest": headers.get("sec-fetch-dest", ""),
        }
        
        # Create hash
        fingerprint_str = json.dumps(fingerprint, sort_keys=True)
        fingerprint_hash = hashlib.sha256(
            fingerprint_str.encode()
        ).hexdigest()
        
        return {
            "hash": fingerprint_hash,
            "components": fingerprint,
            "created_at": datetime.utcnow().isoformat()
        }
    
    @staticmethod
    async def verify_device(
        user_id: int,
        fingerprint_hash: str
    ) -> bool:
        """Verify if device is known"""
        known_devices = await get_user_devices(user_id)
        
        return any(
            device.fingerprint_hash == fingerprint_hash
            for device in known_devices
        )
    
    @staticmethod
    async def register_device(
        user_id: int,
        fingerprint: dict,
        name: Optional[str] = None
    ):
        """Register new device"""
        device = UserDevice(
            user_id=user_id,
            fingerprint_hash=fingerprint["hash"],
            fingerprint_data=fingerprint["components"],
            name=name or "Unknown Device",
            first_seen=datetime.utcnow(),
            last_seen=datetime.utcnow()
        )
        
        db.add(device)
        db.commit()
```

### Security Event Logging
```python
class SecurityAuditLog:
    """Comprehensive security event logging"""
    
    EVENT_TYPES = {
        "login_success": "info",
        "login_failed": "warning",
        "password_changed": "info",
        "mfa_enabled": "info",
        "mfa_disabled": "warning",
        "account_locked": "warning",
        "suspicious_activity": "critical",
        "api_key_created": "info",
        "api_key_revoked": "info",
        "permission_denied": "warning",
        "data_export": "info",
        "account_deleted": "critical"
    }
    
    @classmethod
    async def log_event(
        cls,
        event_type: str,
        user_id: Optional[int] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        metadata: Optional[dict] = None
    ):
        """Log security event"""
        event = SecurityEvent(
            event_type=event_type,
            severity=cls.EVENT_TYPES.get(event_type, "info"),
            user_id=user_id,
            ip_address=ip_address,
            user_agent=user_agent,
            metadata=metadata or {},
            timestamp=datetime.utcnow()
        )
        
        db.add(event)
        db.commit()
        
        # Alert on critical events
        if event.severity == "critical":
            await send_security_alert(event)
    
    @staticmethod
    async def get_suspicious_patterns(
        user_id: int,
        window_hours: int = 24
    ) -> List[dict]:
        """Detect suspicious patterns in user activity"""
        cutoff = datetime.utcnow() - timedelta(hours=window_hours)
        
        events = db.query(SecurityEvent).filter(
            SecurityEvent.user_id == user_id,
            SecurityEvent.timestamp >= cutoff
        ).all()
        
        patterns = []
        
        # Multiple failed logins
        failed_logins = [e for e in events if e.event_type == "login_failed"]
        if len(failed_logins) > 5:
            patterns.append({
                "type": "excessive_failed_logins",
                "count": len(failed_logins),
                "severity": "high"
            })
        
        # Rapid location changes
        login_locations = [
            (e.timestamp, e.ip_address)
            for e in events
            if e.event_type == "login_success"
        ]
        
        for i in range(1, len(login_locations)):
            time_diff = (login_locations[i][0] - login_locations[i-1][0]).total_seconds()
            if time_diff < 3600:  # Within 1 hour
                loc1 = await get_ip_location(login_locations[i-1][1])
                loc2 = await get_ip_location(login_locations[i][1])
                distance = calculate_distance(loc1, loc2)
                
                if distance > 1000:  # 1000 km
                    patterns.append({
                        "type": "impossible_travel",
                        "distance_km": distance,
                        "time_hours": time_diff / 3600,
                        "severity": "critical"
                    })
        
        return patterns
```

### CORS Security
```python
from fastapi.middleware.cors import CORSMiddleware

# Secure CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.FRONTEND_URL],  # Specific origins only
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
    expose_headers=["X-Total-Count"],
    max_age=86400  # 24 hours
)

# Dynamic CORS for multiple environments
class DynamicCORSMiddleware:
    """Dynamic CORS based on environment"""
    
    def __init__(self, app):
        self.app = app
        self.allowed_origins = self.get_allowed_origins()
    
    def get_allowed_origins(self) -> List[str]:
        """Get allowed origins based on environment"""
        origins = [settings.FRONTEND_URL]
        
        if settings.ENVIRONMENT == "development":
            origins.extend([
                "http://localhost:3000",
                "http://localhost:5173",
                "http://127.0.0.1:3000"
            ])
        
        return origins
    
    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            headers = dict(scope["headers"])
            origin = headers.get(b"origin", b"").decode()
            
            if origin in self.allowed_origins:
                async def send_wrapper(message):
                    if message["type"] == "http.response.start":
                        headers = dict(message.get("headers", []))
                        headers[b"access-control-allow-origin"] = origin.encode()
                        headers[b"access-control-allow-credentials"] = b"true"
                        message["headers"] = list(headers.items())
                    await send(message)
                
                await self.app(scope, receive, send_wrapper)
                return
        
        await self.app(scope, receive, send)
```

### Input Validation & Sanitization
```python
from bleach import clean
import re

class InputSanitizer:
    """Input validation and sanitization"""
    
    # Email regex pattern
    EMAIL_PATTERN = re.compile(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    )
    
    # Phone regex pattern (international)
    PHONE_PATTERN = re.compile(
        r'^\+?[1-9]\d{1,14}$'
    )
    
    @staticmethod
    def sanitize_html(html: str) -> str:
        """Sanitize HTML input"""
        return clean(
            html,
            tags=['p', 'br', 'strong', 'em', 'u', 'a'],
            attributes={'a': ['href', 'title']},
            strip=True
        )
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """Validate email format"""
        return bool(InputSanitizer.EMAIL_PATTERN.match(email))
    
    @staticmethod
    def validate_phone(phone: str) -> bool:
        """Validate phone number format"""
        return bool(InputSanitizer.PHONE_PATTERN.match(phone))
    
    @staticmethod
    def sanitize_filename(filename: str) -> str:
        """Sanitize filename for safe storage"""
        # Remove path separators
        filename = filename.replace('/', '').replace('\\', '')
        
        # Remove special characters
        filename = re.sub(r'[^a-zA-Z0-9._-]', '', filename)
        
        # Limit length
        name, ext = os.path.splitext(filename)
        if len(name) > 100:
            name = name[:100]
        
        return f"{name}{ext}"
    
    @staticmethod
    def validate_url(url: str) -> bool:
        """Validate URL format and protocol"""
        try:
            result = urlparse(url)
            return all([
                result.scheme in ['http', 'https'],
                result.netloc,
                '.' in result.netloc
            ])
        except Exception:
            return False
```

### Encryption at Rest
```python
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

class EncryptionService:
    """Encryption for sensitive data at rest"""
    
    @staticmethod
    def derive_key(password: str, salt: bytes) -> bytes:
        """Derive encryption key from password"""
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        return base64.urlsafe_b64encode(kdf.derive(password.encode()))
    
    @staticmethod
    def encrypt_field(data: str, key: bytes) -> str:
        """Encrypt sensitive field"""
        f = Fernet(key)
        encrypted = f.encrypt(data.encode())
        return base64.urlsafe_b64encode(encrypted).decode()
    
    @staticmethod
    def decrypt_field(encrypted_data: str, key: bytes) -> str:
        """Decrypt sensitive field"""
        f = Fernet(key)
        decoded = base64.urlsafe_b64decode(encrypted_data.encode())
        return f.decrypt(decoded).decode()

# Usage in models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, index=True)
    
    # Encrypted fields
    _ssn_encrypted = Column(String, name="ssn_encrypted")
    _ssn_salt = Column(String, name="ssn_salt")
    
    @property
    def ssn(self) -> Optional[str]:
        """Get decrypted SSN"""
        if not self._ssn_encrypted:
            return None
        
        key = EncryptionService.derive_key(
            settings.FIELD_ENCRYPTION_KEY,
            base64.urlsafe_b64decode(self._ssn_salt)
        )
        
        return EncryptionService.decrypt_field(
            self._ssn_encrypted,
            key
        )
    
    @ssn.setter
    def ssn(self, value: str):
        """Set encrypted SSN"""
        salt = os.urandom(16)
        self._ssn_salt = base64.urlsafe_b64encode(salt).decode()
        
        key = EncryptionService.derive_key(
            settings.FIELD_ENCRYPTION_KEY,
            salt
        )
        
        self._ssn_encrypted = EncryptionService.encrypt_field(
            value,
            key
        )
```
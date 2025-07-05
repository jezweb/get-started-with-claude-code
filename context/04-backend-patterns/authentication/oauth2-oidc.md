# OAuth2/OIDC Implementation

Comprehensive guide to implementing OAuth2 and OpenID Connect for delegated authorization and federated identity.

## OAuth2 Authorization Code Flow with PKCE

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

## OpenID Connect (OIDC) Implementation

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

## Advanced OAuth2 Patterns

### Dynamic Client Registration
```python
class DynamicClientRegistration:
    """OAuth2 Dynamic Client Registration"""
    
    async def register_client(
        self,
        registration_endpoint: str,
        client_metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Register OAuth2 client dynamically"""
        required_metadata = {
            "client_name": client_metadata.get("client_name"),
            "redirect_uris": client_metadata.get("redirect_uris"),
            "grant_types": ["authorization_code", "refresh_token"],
            "response_types": ["code"],
            "token_endpoint_auth_method": "client_secret_post"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                registration_endpoint,
                json={**required_metadata, **client_metadata}
            )
            
            if response.status_code != 201:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Client registration failed: {response.text}"
                )
            
            return response.json()
```

### Token Introspection
```python
class TokenIntrospection:
    """OAuth2 Token Introspection (RFC 7662)"""
    
    async def introspect_token(
        self,
        token: str,
        introspection_endpoint: str,
        client_credentials: tuple[str, str]
    ) -> Dict[str, Any]:
        """Introspect OAuth2 token"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                introspection_endpoint,
                data={"token": token},
                auth=client_credentials
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Token introspection failed"
                )
            
            introspection_result = response.json()
            
            if not introspection_result.get("active"):
                raise HTTPException(
                    status_code=401,
                    detail="Token is not active"
                )
            
            return introspection_result
```

### Device Authorization Grant
```python
class DeviceAuthorizationGrant:
    """OAuth2 Device Authorization Grant (RFC 8628)"""
    
    async def initiate_device_flow(
        self,
        device_endpoint: str,
        client_id: str,
        scope: List[str] = None
    ) -> Dict[str, Any]:
        """Initiate device authorization flow"""
        data = {"client_id": client_id}
        if scope:
            data["scope"] = " ".join(scope)
        
        async with httpx.AsyncClient() as client:
            response = await client.post(device_endpoint, data=data)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail="Device authorization failed"
                )
            
            return response.json()
    
    async def poll_for_token(
        self,
        token_endpoint: str,
        device_code: str,
        client_id: str,
        interval: int = 5
    ) -> Dict[str, Any]:
        """Poll for token approval"""
        while True:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    token_endpoint,
                    data={
                        "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                        "device_code": device_code,
                        "client_id": client_id
                    }
                )
                
                if response.status_code == 200:
                    return response.json()
                
                error_data = response.json()
                error = error_data.get("error")
                
                if error == "authorization_pending":
                    await asyncio.sleep(interval)
                    continue
                elif error == "slow_down":
                    interval += 5
                    await asyncio.sleep(interval)
                    continue
                else:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Device flow error: {error}"
                    )
```

## Security Best Practices

### PKCE Implementation
```python
def validate_pkce_challenge(
    code_verifier: str,
    code_challenge: str,
    method: str = "S256"
) -> bool:
    """Validate PKCE challenge"""
    if method == "S256":
        # SHA256 hash
        expected_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode()).digest()
        ).decode().rstrip("=")
    elif method == "plain":
        expected_challenge = code_verifier
    else:
        raise ValueError(f"Unsupported challenge method: {method}")
    
    return secrets.compare_digest(expected_challenge, code_challenge)
```

### State Parameter Validation
```python
class StateManager:
    """Secure state parameter management"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.state_ttl = 300  # 5 minutes
    
    async def create_state(
        self,
        user_session_id: str,
        additional_data: Dict[str, Any] = None
    ) -> str:
        """Create secure state parameter"""
        state = secrets.token_urlsafe(32)
        
        state_data = {
            "session_id": user_session_id,
            "created_at": datetime.now(timezone.utc).isoformat(),
            **(additional_data or {})
        }
        
        await self.redis.setex(
            f"oauth_state:{state}",
            self.state_ttl,
            json.dumps(state_data)
        )
        
        return state
    
    async def validate_state(
        self,
        state: str,
        user_session_id: str
    ) -> Dict[str, Any]:
        """Validate and consume state parameter"""
        state_key = f"oauth_state:{state}"
        state_data = await self.redis.get(state_key)
        
        if not state_data:
            raise HTTPException(
                status_code=400,
                detail="Invalid or expired state"
            )
        
        # Delete state after use (one-time use)
        await self.redis.delete(state_key)
        
        data = json.loads(state_data)
        
        if data["session_id"] != user_session_id:
            raise HTTPException(
                status_code=400,
                detail="State mismatch"
            )
        
        return data
```

### Token Storage & Encryption
```python
from cryptography.fernet import Fernet

class SecureTokenStorage:
    """Secure storage for OAuth tokens"""
    
    def __init__(self, encryption_key: bytes):
        self.cipher = Fernet(encryption_key)
    
    async def store_tokens(
        self,
        user_id: str,
        provider: str,
        tokens: Dict[str, str]
    ):
        """Store encrypted OAuth tokens"""
        # Encrypt sensitive tokens
        encrypted_access = self.cipher.encrypt(
            tokens["access_token"].encode()
        )
        encrypted_refresh = self.cipher.encrypt(
            tokens.get("refresh_token", "").encode()
        ) if tokens.get("refresh_token") else None
        
        # Store in database
        await OAuthToken.create(
            user_id=user_id,
            provider=provider,
            access_token=encrypted_access,
            refresh_token=encrypted_refresh,
            expires_at=datetime.now(timezone.utc) + timedelta(
                seconds=tokens.get("expires_in", 3600)
            )
        )
    
    async def get_valid_token(
        self,
        user_id: str,
        provider: str
    ) -> Optional[str]:
        """Get valid access token"""
        token_record = await OAuthToken.get(
            user_id=user_id,
            provider=provider
        )
        
        if not token_record:
            return None
        
        # Check expiration
        if token_record.expires_at <= datetime.now(timezone.utc):
            # Try to refresh
            if token_record.refresh_token:
                return await self.refresh_access_token(
                    user_id,
                    provider,
                    token_record
                )
            return None
        
        # Decrypt and return
        return self.cipher.decrypt(token_record.access_token).decode()
```
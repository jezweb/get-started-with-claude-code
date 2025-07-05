# Passwordless Authentication

Modern authentication methods that eliminate the need for passwords, improving both security and user experience.

## Magic Link Implementation

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
```

## SMS/Phone-Based Authentication

```python
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

## Biometric Authentication

```python
# Biometric authentication with WebAuthn
class BiometricAuth:
    """Biometric authentication using platform authenticators"""
    
    @staticmethod
    async def register_biometric(
        user_id: int,
        device_name: str = "Unknown Device"
    ):
        """Register biometric authenticator"""
        user = await get_user_by_id(user_id)
        
        # Generate registration options
        options = generate_registration_options(
            rp_id=settings.WEBAUTHN_RP_ID,
            rp_name=settings.WEBAUTHN_RP_NAME,
            user_id=str(user_id).encode(),
            user_name=user.email,
            user_display_name=user.name,
            authenticator_selection={
                "authenticator_attachment": "platform",
                "resident_key": "required",
                "user_verification": "required"
            },
            attestation="none"
        )
        
        # Store challenge
        await cache.set(
            f"biometric_challenge:{user_id}",
            {
                "challenge": options.challenge,
                "device_name": device_name
            },
            expire=300
        )
        
        return options
    
    @staticmethod
    async def authenticate_biometric(
        credential_id: str,
        client_data: dict
    ):
        """Authenticate using biometric"""
        # Find credential
        credential = await db.query(BiometricCredential).filter(
            BiometricCredential.credential_id == credential_id
        ).first()
        
        if not credential:
            raise HTTPException(
                status_code=404,
                detail="Credential not found"
            )
        
        # Generate authentication options
        options = generate_authentication_options(
            rp_id=settings.WEBAUTHN_RP_ID,
            allowed_credentials=[{
                "type": "public-key",
                "id": credential.credential_id
            }],
            user_verification="required"
        )
        
        # Verify authentication
        verification = verify_authentication_response(
            credential=client_data,
            expected_challenge=options.challenge,
            expected_origin=settings.FRONTEND_URL,
            expected_rp_id=settings.WEBAUTHN_RP_ID,
            credential_public_key=credential.public_key,
            credential_current_sign_count=credential.sign_count
        )
        
        if verification.verified:
            # Update sign count
            credential.sign_count = verification.new_sign_count
            credential.last_used = datetime.utcnow()
            db.commit()
            
            # Create session
            user = await get_user_by_id(credential.user_id)
            return create_token_response(user)
        
        raise HTTPException(
            status_code=401,
            detail="Authentication failed"
        )
```

## Social Login Integration

```python
# Unified social login implementation
class SocialAuthService:
    """Handle various social authentication providers"""
    
    PROVIDERS = {
        "google": {
            "client_id": settings.GOOGLE_CLIENT_ID,
            "client_secret": settings.GOOGLE_CLIENT_SECRET,
            "authorize_url": "https://accounts.google.com/o/oauth2/v2/auth",
            "token_url": "https://oauth2.googleapis.com/token",
            "userinfo_url": "https://www.googleapis.com/oauth2/v2/userinfo",
            "scope": ["openid", "email", "profile"]
        },
        "github": {
            "client_id": settings.GITHUB_CLIENT_ID,
            "client_secret": settings.GITHUB_CLIENT_SECRET,
            "authorize_url": "https://github.com/login/oauth/authorize",
            "token_url": "https://github.com/login/oauth/access_token",
            "userinfo_url": "https://api.github.com/user",
            "scope": ["user:email"]
        },
        "apple": {
            "client_id": settings.APPLE_CLIENT_ID,
            "team_id": settings.APPLE_TEAM_ID,
            "key_id": settings.APPLE_KEY_ID,
            "private_key": settings.APPLE_PRIVATE_KEY,
            "authorize_url": "https://appleid.apple.com/auth/authorize",
            "token_url": "https://appleid.apple.com/auth/token",
            "scope": ["name", "email"]
        }
    }
    
    @staticmethod
    async def create_or_update_social_user(
        provider: str,
        user_info: dict
    ) -> User:
        """Create or update user from social provider"""
        # Extract common fields
        email = user_info.get("email")
        name = user_info.get("name") or user_info.get("login")
        provider_id = str(user_info.get("id") or user_info.get("sub"))
        
        # Check if social account exists
        social_account = await db.query(SocialAccount).filter(
            SocialAccount.provider == provider,
            SocialAccount.provider_id == provider_id
        ).first()
        
        if social_account:
            # Update existing user
            user = await get_user_by_id(social_account.user_id)
            user.last_login = datetime.utcnow()
            db.commit()
            return user
        
        # Check if user with email exists
        if email:
            user = await get_user_by_email(email)
            if user:
                # Link social account
                social_account = SocialAccount(
                    user_id=user.id,
                    provider=provider,
                    provider_id=provider_id,
                    provider_data=user_info
                )
                db.add(social_account)
                db.commit()
                return user
        
        # Create new user
        user = User(
            email=email,
            name=name,
            is_verified=True,  # Social accounts are pre-verified
            created_via=f"social_{provider}"
        )
        db.add(user)
        db.commit()
        
        # Create social account link
        social_account = SocialAccount(
            user_id=user.id,
            provider=provider,
            provider_id=provider_id,
            provider_data=user_info
        )
        db.add(social_account)
        db.commit()
        
        return user
```

## QR Code Login

```python
# QR code-based login for mobile/desktop pairing
class QRCodeAuth:
    """QR code authentication for device pairing"""
    
    @staticmethod
    async def generate_qr_session() -> dict:
        """Generate QR code session for login"""
        # Generate session ID
        session_id = str(uuid4())
        
        # Generate QR data
        qr_data = {
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat(),
            "endpoint": f"{settings.API_URL}/auth/qr/verify"
        }
        
        # Store session
        await cache.set(
            f"qr_session:{session_id}",
            {
                "status": "pending",
                "created_at": datetime.utcnow().isoformat()
            },
            expire=300  # 5 minutes
        )
        
        # Generate QR code
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(json.dumps(qr_data))
        qr.make(fit=True)
        
        # Convert to base64
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        qr_image = base64.b64encode(buffer.getvalue()).decode()
        
        return {
            "session_id": session_id,
            "qr_code": f"data:image/png;base64,{qr_image}",
            "expires_in": 300
        }
    
    @staticmethod
    async def verify_qr_session(
        session_id: str,
        user_id: int
    ):
        """Verify QR session from mobile device"""
        # Get session
        session_data = await cache.get(f"qr_session:{session_id}")
        
        if not session_data or session_data["status"] != "pending":
            raise HTTPException(
                status_code=400,
                detail="Invalid or expired QR session"
            )
        
        # Update session with user
        session_data["status"] = "verified"
        session_data["user_id"] = user_id
        session_data["verified_at"] = datetime.utcnow().isoformat()
        
        await cache.set(
            f"qr_session:{session_id}",
            session_data,
            expire=60  # 1 minute to complete login
        )
        
        return {"status": "verified"}
    
    @staticmethod
    async def poll_qr_session(session_id: str):
        """Poll QR session status (for desktop)"""
        session_data = await cache.get(f"qr_session:{session_id}")
        
        if not session_data:
            return {"status": "expired"}
        
        if session_data["status"] == "verified":
            # Get user and create tokens
            user = await get_user_by_id(session_data["user_id"])
            
            # Clear session
            await cache.delete(f"qr_session:{session_id}")
            
            # Create tokens
            return {
                "status": "verified",
                "access_token": TokenService.create_access_token(
                    data={"sub": str(user.id), "email": user.email}
                ),
                "refresh_token": TokenService.create_refresh_token(
                    data={"sub": str(user.id)}
                )
            }
        
        return {"status": session_data["status"]}

# QR login endpoints
@app.post("/auth/qr/generate")
async def generate_qr_login():
    """Generate QR code for login"""
    return await QRCodeAuth.generate_qr_session()

@app.post("/auth/qr/verify")
async def verify_qr_login(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """Verify QR code from mobile device"""
    return await QRCodeAuth.verify_qr_session(
        session_id,
        current_user.id
    )

@app.get("/auth/qr/poll/{session_id}")
async def poll_qr_login(session_id: str):
    """Poll QR login status"""
    return await QRCodeAuth.poll_qr_session(session_id)
```

## One-Time Passwords (OTP)

```python
# Generic OTP implementation for various channels
class OTPService:
    """One-time password service"""
    
    @staticmethod
    async def generate_otp(
        identifier: str,
        channel: str,
        length: int = 6,
        expire_seconds: int = 300
    ) -> str:
        """Generate and store OTP"""
        # Generate OTP
        if channel == "numeric":
            otp = ''.join(secrets.choice('0123456789') for _ in range(length))
        else:
            otp = secrets.token_urlsafe(length)
        
        # Store with metadata
        await cache.set(
            f"otp:{channel}:{identifier}",
            {
                "otp": otp,
                "attempts": 0,
                "created_at": datetime.utcnow().isoformat()
            },
            expire=expire_seconds
        )
        
        return otp
    
    @staticmethod
    async def verify_otp(
        identifier: str,
        channel: str,
        otp: str,
        delete_on_success: bool = True
    ) -> bool:
        """Verify OTP with rate limiting"""
        key = f"otp:{channel}:{identifier}"
        otp_data = await cache.get(key)
        
        if not otp_data:
            return False
        
        # Check attempts
        if otp_data["attempts"] >= 3:
            await cache.delete(key)
            raise HTTPException(
                status_code=429,
                detail="Too many attempts. Please request a new code."
            )
        
        # Increment attempts
        otp_data["attempts"] += 1
        await cache.set(key, otp_data, expire=300)
        
        # Verify OTP
        if not secrets.compare_digest(otp_data["otp"], otp):
            return False
        
        # Success - delete if requested
        if delete_on_success:
            await cache.delete(key)
        
        return True
    
    @staticmethod
    async def send_otp_email(email: str, otp: str):
        """Send OTP via email"""
        await send_email(
            to=email,
            subject="Your verification code",
            body=f"""
            Your verification code is: {otp}
            
            This code will expire in 5 minutes.
            
            If you didn't request this code, please ignore this email.
            """
        )
    
    @staticmethod
    async def send_otp_sms(phone: str, otp: str):
        """Send OTP via SMS"""
        await sms_client.send_message(
            to=phone,
            body=f"Your verification code is: {otp}"
        )

# Unified OTP endpoint
@app.post("/auth/otp/send")
async def send_otp(
    channel: Literal["email", "sms"],
    identifier: str
):
    """Send OTP via specified channel"""
    # Rate limiting
    rate_limit_key = f"otp_send:{channel}:{identifier}"
    if not await check_rate_limit(rate_limit_key, max_attempts=3, window=3600):
        raise HTTPException(
            status_code=429,
            detail="Too many OTP requests"
        )
    
    # Generate OTP
    otp = await OTPService.generate_otp(identifier, channel)
    
    # Send OTP
    if channel == "email":
        await OTPService.send_otp_email(identifier, otp)
    elif channel == "sms":
        await OTPService.send_otp_sms(identifier, otp)
    
    return {"message": f"Verification code sent via {channel}"}

@app.post("/auth/otp/verify")
async def verify_otp(
    channel: Literal["email", "sms"],
    identifier: str,
    otp: str
):
    """Verify OTP and authenticate"""
    # Verify OTP
    valid = await OTPService.verify_otp(identifier, channel, otp)
    
    if not valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired verification code"
        )
    
    # Find or create user
    if channel == "email":
        user = await get_or_create_user_by_email(identifier)
    else:
        user = await get_or_create_user_by_phone(identifier)
    
    # Create tokens
    return create_token_response(user)
```
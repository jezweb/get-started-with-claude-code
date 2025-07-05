# Multi-Factor Authentication (MFA)

Comprehensive implementation of MFA including TOTP, backup codes, and WebAuthn/Passkeys.

## TOTP Implementation

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
```

## WebAuthn/Passkeys Implementation

```python
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

## SMS/Email MFA

```python
# SMS and Email-based MFA
import twilio
from twilio.rest import Client
from email.mime.text import MIMEText
import smtplib

class CommunicationMFA:
    """SMS and Email MFA implementation"""
    
    def __init__(self):
        # Twilio client for SMS
        self.twilio_client = Client(
            settings.TWILIO_ACCOUNT_SID,
            settings.TWILIO_AUTH_TOKEN
        )
        
        # SMTP for email
        self.smtp_server = settings.SMTP_SERVER
        self.smtp_port = settings.SMTP_PORT
        self.smtp_username = settings.SMTP_USERNAME
        self.smtp_password = settings.SMTP_PASSWORD
    
    async def send_sms_code(
        self,
        phone_number: str,
        code: str
    ):
        """Send MFA code via SMS"""
        message = self.twilio_client.messages.create(
            body=f"Your verification code is: {code}",
            from_=settings.TWILIO_PHONE_NUMBER,
            to=phone_number
        )
        
        return message.sid
    
    async def send_email_code(
        self,
        email: str,
        code: str
    ):
        """Send MFA code via email"""
        msg = MIMEText(
            f"Your verification code is: {code}\n\n"
            f"This code will expire in 5 minutes."
        )
        msg['Subject'] = 'Verification Code'
        msg['From'] = settings.SMTP_FROM_EMAIL
        msg['To'] = email
        
        with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
            server.starttls()
            server.login(self.smtp_username, self.smtp_password)
            server.send_message(msg)
    
    @staticmethod
    def generate_verification_code(length: int = 6) -> str:
        """Generate numeric verification code"""
        return ''.join(
            secrets.choice('0123456789')
            for _ in range(length)
        )
    
    @staticmethod
    async def store_verification_code(
        user_id: int,
        code: str,
        method: str,
        expire_seconds: int = 300
    ):
        """Store verification code in cache"""
        await cache.set(
            f"mfa_code:{user_id}:{method}",
            {
                "code": code,
                "attempts": 0,
                "created_at": datetime.utcnow().isoformat()
            },
            expire=expire_seconds
        )
    
    @staticmethod
    async def verify_code(
        user_id: int,
        code: str,
        method: str
    ) -> bool:
        """Verify MFA code"""
        stored_data = await cache.get(f"mfa_code:{user_id}:{method}")
        
        if not stored_data:
            return False
        
        # Check attempts
        if stored_data["attempts"] >= 3:
            await cache.delete(f"mfa_code:{user_id}:{method}")
            return False
        
        # Increment attempts
        stored_data["attempts"] += 1
        await cache.set(
            f"mfa_code:{user_id}:{method}",
            stored_data,
            expire=300
        )
        
        # Verify code
        if secrets.compare_digest(stored_data["code"], code):
            await cache.delete(f"mfa_code:{user_id}:{method}")
            return True
        
        return False

# SMS/Email MFA endpoints
@app.post("/auth/mfa/send-sms")
async def send_sms_mfa(
    phone_number: str,
    current_user: User = Depends(get_current_user)
):
    """Send MFA code via SMS"""
    # Generate code
    code = CommunicationMFA.generate_verification_code()
    
    # Store code
    await CommunicationMFA.store_verification_code(
        current_user.id,
        code,
        "sms"
    )
    
    # Send SMS
    comm_mfa = CommunicationMFA()
    await comm_mfa.send_sms_code(phone_number, code)
    
    return {"message": "Verification code sent via SMS"}

@app.post("/auth/mfa/verify-sms")
async def verify_sms_mfa(
    code: str,
    current_user: User = Depends(get_current_user)
):
    """Verify SMS MFA code"""
    valid = await CommunicationMFA.verify_code(
        current_user.id,
        code,
        "sms"
    )
    
    if not valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired code"
        )
    
    return {"verified": True}
```

## Hardware Token Support

```python
# Hardware token (FIDO U2F) support
from fido2.server import Fido2Server
from fido2.webauthn import PublicKeyCredentialRpEntity

class HardwareTokenService:
    """Hardware security key support"""
    
    def __init__(self):
        self.server = Fido2Server(
            PublicKeyCredentialRpEntity(
                id=settings.WEBAUTHN_RP_ID,
                name=settings.WEBAUTHN_RP_NAME
            )
        )
    
    async def register_security_key(
        self,
        user_id: int,
        client_data: dict
    ):
        """Register hardware security key"""
        # Get user
        user = await get_user_by_id(user_id)
        
        # Get existing credentials
        existing_credentials = await self.get_user_credentials(user_id)
        
        # Begin registration
        registration_data, state = self.server.register_begin(
            user={
                "id": str(user_id).encode(),
                "name": user.email,
                "displayName": user.name
            },
            credentials=existing_credentials,
            user_verification="discouraged",
            authenticator_attachment="cross-platform"
        )
        
        # Store state
        await cache.set(
            f"u2f_registration:{user_id}",
            state,
            expire=300
        )
        
        return registration_data
    
    async def complete_registration(
        self,
        user_id: int,
        credential_data: dict
    ):
        """Complete security key registration"""
        # Get stored state
        state = await cache.get(f"u2f_registration:{user_id}")
        
        if not state:
            raise ValueError("Registration state not found")
        
        # Complete registration
        auth_data = self.server.register_complete(
            state,
            credential_data
        )
        
        # Store credential
        await self.store_credential(user_id, auth_data)
        
        return True
```

## MFA Management & Recovery

```python
class MFAManager:
    """Comprehensive MFA management"""
    
    @staticmethod
    async def get_user_mfa_methods(user_id: int) -> List[Dict[str, Any]]:
        """Get all enabled MFA methods for user"""
        user = await get_user_by_id(user_id)
        methods = []
        
        # TOTP
        if user.mfa_enabled and user.mfa_secret:
            methods.append({
                "type": "totp",
                "name": "Authenticator App",
                "enabled": True,
                "last_used": user.mfa_last_used
            })
        
        # WebAuthn
        webauthn_creds = db.query(WebAuthnCredential).filter(
            WebAuthnCredential.user_id == user_id
        ).all()
        
        for cred in webauthn_creds:
            methods.append({
                "type": "webauthn",
                "name": cred.name or "Security Key",
                "enabled": True,
                "last_used": cred.last_used,
                "id": cred.id
            })
        
        # SMS
        if user.phone_number and user.phone_verified:
            methods.append({
                "type": "sms",
                "name": f"SMS to {user.phone_number[-4:]}",
                "enabled": user.sms_mfa_enabled,
                "last_used": user.sms_mfa_last_used
            })
        
        return methods
    
    @staticmethod
    async def disable_mfa_method(
        user_id: int,
        method_type: str,
        method_id: Optional[str] = None
    ):
        """Disable specific MFA method"""
        user = await get_user_by_id(user_id)
        
        if method_type == "totp":
            user.mfa_enabled = False
            user.mfa_secret = None
            user.mfa_backup_codes = []
        
        elif method_type == "webauthn" and method_id:
            await db.query(WebAuthnCredential).filter(
                WebAuthnCredential.id == method_id,
                WebAuthnCredential.user_id == user_id
            ).delete()
        
        elif method_type == "sms":
            user.sms_mfa_enabled = False
        
        db.commit()
    
    @staticmethod
    async def generate_recovery_codes(
        user_id: int,
        count: int = 10
    ) -> List[str]:
        """Generate new recovery codes"""
        user = await get_user_by_id(user_id)
        
        # Generate new codes
        codes = MFAService.generate_backup_codes(count)
        
        # Hash and store
        hashed_codes = [
            pwd_context.hash(code)
            for code in codes
        ]
        
        user.mfa_backup_codes = hashed_codes
        db.commit()
        
        return codes
    
    @staticmethod
    async def initiate_account_recovery(
        email: str
    ) -> str:
        """Initiate account recovery process"""
        user = await get_user_by_email(email)
        
        if not user:
            # Don't reveal if user exists
            return "Recovery email sent if account exists"
        
        # Generate recovery token
        recovery_token = secrets.token_urlsafe(32)
        
        # Store token
        await cache.set(
            f"recovery:{recovery_token}",
            {
                "user_id": user.id,
                "email": email,
                "created_at": datetime.utcnow().isoformat()
            },
            expire=3600  # 1 hour
        )
        
        # Send recovery email
        await send_recovery_email(email, recovery_token)
        
        return "Recovery email sent if account exists"

# Recovery endpoint
@app.post("/auth/recover/verify")
async def verify_recovery_token(
    token: str,
    new_password: str
):
    """Verify recovery token and reset password"""
    # Get recovery data
    recovery_data = await cache.get(f"recovery:{token}")
    
    if not recovery_data:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired recovery token"
        )
    
    # Update password
    user = await get_user_by_id(recovery_data["user_id"])
    user.password_hash = pwd_context.hash(new_password)
    
    # Disable MFA (security measure)
    user.mfa_enabled = False
    user.mfa_secret = None
    
    db.commit()
    
    # Clear recovery token
    await cache.delete(f"recovery:{token}")
    
    # Send notification
    await send_password_changed_notification(user.email)
    
    return {"message": "Password reset successfully"}
```

## MFA Enforcement Policies

```python
class MFAPolicy:
    """MFA enforcement policies"""
    
    @staticmethod
    def requires_mfa(
        user: User,
        resource: str,
        action: str
    ) -> bool:
        """Check if MFA is required for action"""
        # Admin users always require MFA
        if user.is_admin:
            return True
        
        # Sensitive operations
        sensitive_actions = [
            "delete_account",
            "change_password",
            "add_payment_method",
            "transfer_funds",
            "access_admin_panel"
        ]
        
        if action in sensitive_actions:
            return True
        
        # High-value resources
        if resource.startswith("/api/admin/"):
            return True
        
        # Organization policy
        if user.organization and user.organization.require_mfa:
            return True
        
        return False
    
    @staticmethod
    def enforce_mfa_middleware():
        """Middleware to enforce MFA policies"""
        async def middleware(request: Request, call_next):
            # Get current user
            user = await get_current_user_from_request(request)
            
            if user:
                # Check if MFA is required
                if MFAPolicy.requires_mfa(
                    user,
                    request.url.path,
                    request.method
                ):
                    # Check if MFA was verified in this session
                    mfa_verified = await cache.get(
                        f"mfa_verified:{user.id}:{request.session_id}"
                    )
                    
                    if not mfa_verified:
                        return JSONResponse(
                            status_code=403,
                            content={
                                "detail": "MFA verification required",
                                "mfa_required": True
                            }
                        )
            
            response = await call_next(request)
            return response
        
        return middleware
```
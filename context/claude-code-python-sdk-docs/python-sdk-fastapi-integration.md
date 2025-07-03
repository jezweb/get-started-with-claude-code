# Claude Code Python SDK FastAPI Integration

## Overview
This guide provides comprehensive patterns for integrating Claude Code Python SDK with FastAPI web applications, including endpoints, middleware, authentication, and production deployment strategies.

## Basic FastAPI Integration

### Project Structure
```
my-claude-fastapi-app/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── claude_models.py
│   ├── routers/
│   │   ├── __init__.py
│   │   └── claude_router.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── claude_service.py
│   └── middleware/
│       ├── __init__.py
│       └── claude_middleware.py
├── requirements.txt
├── .env
└── docker-compose.yml
```

### Basic FastAPI Application
```python
# app/main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.routers import claude_router
from app.middleware.claude_middleware import ClaudeRateLimitMiddleware
import os

app = FastAPI(
    title="Claude Code API",
    description="AI-powered coding assistant API",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add custom rate limiting middleware
app.add_middleware(ClaudeRateLimitMiddleware)

# Include Claude router
app.include_router(claude_router.router, prefix="/api/claude", tags=["claude"])

@app.get("/")
async def root():
    return {"message": "Claude Code FastAPI Integration"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}
```

## Data Models

### Pydantic Models
```python
# app/models/claude_models.py
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class PermissionMode(str, Enum):
    ASK_FOR_EDITS = "askForEdits"
    ACCEPT_EDITS = "acceptEdits"
    READ_ONLY = "readOnly"
    STRICT = "strict"

class ClaudeQueryRequest(BaseModel):
    prompt: str = Field(..., min_length=1, max_length=10000)
    max_turns: int = Field(default=3, ge=1, le=10)
    system_prompt: Optional[str] = Field(default=None, max_length=2000)
    project_path: Optional[str] = Field(default=None)
    permission_mode: PermissionMode = Field(default=PermissionMode.ASK_FOR_EDITS)
    allowed_tools: Optional[List[str]] = Field(default=["Read", "Grep", "LS"])
    timeout: int = Field(default=60, ge=10, le=300)

class ClaudeMessage(BaseModel):
    content: str
    role: str
    timestamp: Optional[datetime] = None
    tools_used: List[str] = Field(default_factory=list)
    error: Optional[str] = None

class ClaudeQueryResponse(BaseModel):
    success: bool
    messages: List[ClaudeMessage]
    error: Optional[str] = None
    execution_time: Optional[float] = None
    tokens_used: Optional[int] = None

class ClaudeStreamResponse(BaseModel):
    content: str
    role: str
    tools_used: List[str] = Field(default_factory=list)
    is_complete: bool = False
    error: Optional[str] = None

class ConversationRequest(BaseModel):
    session_id: str = Field(..., min_length=1, max_length=100)
    message: str = Field(..., min_length=1, max_length=5000)

class ConversationResponse(BaseModel):
    session_id: str
    messages: List[ClaudeMessage]
    total_messages: int
    created_at: datetime
```

## Service Layer

### Claude Service
```python
# app/services/claude_service.py
from claude_code_sdk import query, ClaudeCodeOptions, Message
from app.models.claude_models import (
    ClaudeQueryRequest, ClaudeQueryResponse, ClaudeMessage,
    ClaudeStreamResponse, PermissionMode
)
from typing import AsyncGenerator, List, Dict
from pathlib import Path
import time
import asyncio
import logging

logger = logging.getLogger(__name__)

class ClaudeService:
    """Service for managing Claude Code interactions"""
    
    def __init__(self):
        self.active_sessions: Dict[str, List[Message]] = {}
        self.session_configs: Dict[str, ClaudeCodeOptions] = {}
    
    async def query_claude(self, request: ClaudeQueryRequest) -> ClaudeQueryResponse:
        """Execute a Claude query and return complete response"""
        start_time = time.time()
        
        try:
            options = self._build_options(request)
            messages = []
            
            async for message in query(request.prompt, options):
                claude_message = ClaudeMessage(
                    content=message.content,
                    role=message.role,
                    timestamp=getattr(message, 'timestamp', None),
                    tools_used=getattr(message, 'tools_used', []),
                    error=getattr(message, 'error', None)
                )
                messages.append(claude_message)
                
                # Stop on error
                if claude_message.error:
                    break
            
            execution_time = time.time() - start_time
            
            return ClaudeQueryResponse(
                success=True,
                messages=messages,
                execution_time=execution_time
            )
            
        except Exception as e:
            logger.error(f"Claude query failed: {str(e)}")
            return ClaudeQueryResponse(
                success=False,
                messages=[],
                error=str(e),
                execution_time=time.time() - start_time
            )
    
    async def stream_claude_response(
        self, 
        request: ClaudeQueryRequest
    ) -> AsyncGenerator[ClaudeStreamResponse, None]:
        """Stream Claude responses in real-time"""
        try:
            options = self._build_options(request)
            
            async for message in query(request.prompt, options):
                yield ClaudeStreamResponse(
                    content=message.content,
                    role=message.role,
                    tools_used=getattr(message, 'tools_used', []),
                    is_complete=False,
                    error=getattr(message, 'error', None)
                )
                
                if hasattr(message, 'error') and message.error:
                    break
            
            # Send completion signal
            yield ClaudeStreamResponse(
                content="",
                role="system",
                is_complete=True
            )
            
        except Exception as e:
            logger.error(f"Claude streaming failed: {str(e)}")
            yield ClaudeStreamResponse(
                content="",
                role="system",
                is_complete=True,
                error=str(e)
            )
    
    def _build_options(self, request: ClaudeQueryRequest) -> ClaudeCodeOptions:
        """Build ClaudeCodeOptions from request"""
        return ClaudeCodeOptions(
            max_turns=request.max_turns,
            system_prompt=request.system_prompt,
            cwd=Path(request.project_path) if request.project_path else None,
            permission_mode=request.permission_mode.value,
            allowed_tools=request.allowed_tools or ["Read", "Grep", "LS"],
            timeout=request.timeout
        )
    
    async def start_conversation(
        self, 
        session_id: str, 
        initial_request: ClaudeQueryRequest
    ) -> ClaudeQueryResponse:
        """Start a new conversation session"""
        response = await self.query_claude(initial_request)
        
        if response.success:
            # Convert to internal message format and store
            self.active_sessions[session_id] = []
            self.session_configs[session_id] = self._build_options(initial_request)
            
            for msg in response.messages:
                self.active_sessions[session_id].append(msg)
        
        return response
    
    async def continue_conversation(
        self, 
        session_id: str, 
        follow_up_message: str
    ) -> ClaudeQueryResponse:
        """Continue an existing conversation"""
        if session_id not in self.active_sessions:
            return ClaudeQueryResponse(
                success=False,
                messages=[],
                error=f"Session {session_id} not found"
            )
        
        # Build context from conversation history
        context_prompt = self._build_conversation_context(session_id, follow_up_message)
        
        options = self.session_configs[session_id]
        messages = []
        
        try:
            async for message in query(context_prompt, options):
                claude_message = ClaudeMessage(
                    content=message.content,
                    role=message.role,
                    timestamp=getattr(message, 'timestamp', None),
                    tools_used=getattr(message, 'tools_used', []),
                    error=getattr(message, 'error', None)
                )
                messages.append(claude_message)
                self.active_sessions[session_id].append(claude_message)
                
                if claude_message.error:
                    break
            
            return ClaudeQueryResponse(
                success=True,
                messages=messages
            )
            
        except Exception as e:
            return ClaudeQueryResponse(
                success=False,
                messages=[],
                error=str(e)
            )
    
    def _build_conversation_context(self, session_id: str, new_message: str) -> str:
        """Build conversation context from session history"""
        history = self.active_sessions[session_id]
        
        # Include last 5 messages for context
        recent_messages = history[-5:] if len(history) > 5 else history
        
        context_lines = ["Previous conversation:"]
        for msg in recent_messages:
            role = "User" if msg.role == "user" else "Assistant"
            # Truncate long messages
            content = msg.content[:200] + "..." if len(msg.content) > 200 else msg.content
            context_lines.append(f"{role}: {content}")
        
        context_lines.append(f"\nUser: {new_message}")
        
        return "\n".join(context_lines)
    
    def get_session_info(self, session_id: str) -> Dict:
        """Get information about a conversation session"""
        if session_id not in self.active_sessions:
            return {"exists": False}
        
        messages = self.active_sessions[session_id]
        return {
            "exists": True,
            "message_count": len(messages),
            "last_message_time": messages[-1].timestamp if messages else None,
            "tools_used": list(set([
                tool for msg in messages 
                for tool in msg.tools_used
            ]))
        }
    
    def cleanup_session(self, session_id: str):
        """Clean up a conversation session"""
        if session_id in self.active_sessions:
            del self.active_sessions[session_id]
        if session_id in self.session_configs:
            del self.session_configs[session_id]

# Singleton service instance
claude_service = ClaudeService()
```

## API Router

### Claude Router
```python
# app/routers/claude_router.py
from fastapi import APIRouter, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse
from app.services.claude_service import claude_service
from app.models.claude_models import (
    ClaudeQueryRequest, ClaudeQueryResponse,
    ConversationRequest, ConversationResponse
)
import json
import asyncio
from typing import Dict

router = APIRouter()

@router.post("/query", response_model=ClaudeQueryResponse)
async def query_claude(request: ClaudeQueryRequest):
    """Execute a single Claude query"""
    try:
        response = await claude_service.query_claude(request)
        
        if not response.success:
            raise HTTPException(status_code=400, detail=response.error)
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/stream")
async def stream_claude_query(request: ClaudeQueryRequest):
    """Stream Claude responses in real-time"""
    
    async def generate_stream():
        """Generate streaming JSON responses"""
        try:
            async for response in claude_service.stream_claude_response(request):
                # Convert to JSON and send
                response_json = response.dict()
                yield f"data: {json.dumps(response_json)}\n\n"
                
                # Break on completion or error
                if response.is_complete or response.error:
                    break
            
        except Exception as e:
            error_response = {
                "content": "",
                "role": "system", 
                "is_complete": True,
                "error": str(e)
            }
            yield f"data: {json.dumps(error_response)}\n\n"
        
        finally:
            yield "data: [DONE]\n\n"
    
    return StreamingResponse(
        generate_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Access-Control-Allow-Origin": "*"
        }
    )

@router.post("/conversation/start")
async def start_conversation(
    session_id: str,
    request: ClaudeQueryRequest,
    background_tasks: BackgroundTasks
):
    """Start a new conversation session"""
    try:
        # Check if session already exists
        session_info = claude_service.get_session_info(session_id)
        if session_info["exists"]:
            raise HTTPException(
                status_code=409, 
                detail=f"Session {session_id} already exists"
            )
        
        response = await claude_service.start_conversation(session_id, request)
        
        if not response.success:
            raise HTTPException(status_code=400, detail=response.error)
        
        # Schedule cleanup after 1 hour
        background_tasks.add_task(
            cleanup_session_after_delay, 
            session_id, 
            3600  # 1 hour
        )
        
        return {
            "session_id": session_id,
            "success": True,
            "messages": response.messages,
            "message_count": len(response.messages)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/conversation/{session_id}/continue")
async def continue_conversation(session_id: str, request: ConversationRequest):
    """Continue an existing conversation"""
    try:
        if request.session_id != session_id:
            raise HTTPException(
                status_code=400,
                detail="Session ID mismatch"
            )
        
        response = await claude_service.continue_conversation(
            session_id, 
            request.message
        )
        
        if not response.success:
            raise HTTPException(status_code=400, detail=response.error)
        
        return {
            "session_id": session_id,
            "new_messages": response.messages,
            "total_messages": len(claude_service.active_sessions.get(session_id, []))
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/conversation/{session_id}/info")
async def get_conversation_info(session_id: str):
    """Get information about a conversation session"""
    session_info = claude_service.get_session_info(session_id)
    
    if not session_info["exists"]:
        raise HTTPException(
            status_code=404,
            detail=f"Session {session_id} not found"
        )
    
    return {
        "session_id": session_id,
        **session_info
    }

@router.delete("/conversation/{session_id}")
async def delete_conversation(session_id: str):
    """Delete a conversation session"""
    session_info = claude_service.get_session_info(session_id)
    
    if not session_info["exists"]:
        raise HTTPException(
            status_code=404,
            detail=f"Session {session_id} not found"
        )
    
    claude_service.cleanup_session(session_id)
    
    return {"message": f"Session {session_id} deleted successfully"}

@router.get("/health")
async def claude_health_check():
    """Health check for Claude service"""
    try:
        # Simple test query
        test_request = ClaudeQueryRequest(
            prompt="Hello",
            max_turns=1,
            timeout=10
        )
        
        response = await claude_service.query_claude(test_request)
        
        return {
            "status": "healthy" if response.success else "degraded",
            "claude_available": response.success,
            "error": response.error if not response.success else None
        }
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "claude_available": False,
            "error": str(e)
        }

async def cleanup_session_after_delay(session_id: str, delay_seconds: int):
    """Background task to cleanup session after delay"""
    await asyncio.sleep(delay_seconds)
    claude_service.cleanup_session(session_id)
```

## Middleware

### Rate Limiting Middleware
```python
# app/middleware/claude_middleware.py
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import time
from typing import Dict, List
from collections import defaultdict, deque
import asyncio

class ClaudeRateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limiting middleware for Claude API endpoints"""
    
    def __init__(
        self, 
        app,
        requests_per_minute: int = 30,
        requests_per_hour: int = 500,
        burst_size: int = 10
    ):
        super().__init__(app)
        self.requests_per_minute = requests_per_minute
        self.requests_per_hour = requests_per_hour
        self.burst_size = burst_size
        
        # Track requests by IP
        self.request_history: Dict[str, deque] = defaultdict(deque)
        self.burst_requests: Dict[str, List[float]] = defaultdict(list)
        
        # Cleanup task
        asyncio.create_task(self._cleanup_old_requests())
    
    async def dispatch(self, request: Request, call_next):
        # Only apply rate limiting to Claude endpoints
        if not request.url.path.startswith("/api/claude"):
            return await call_next(request)
        
        client_ip = self._get_client_ip(request)
        current_time = time.time()
        
        # Check rate limits
        if not self._check_rate_limits(client_ip, current_time):
            raise HTTPException(
                status_code=429,
                detail={
                    "error": "Rate limit exceeded",
                    "limits": {
                        "requests_per_minute": self.requests_per_minute,
                        "requests_per_hour": self.requests_per_hour,
                        "burst_size": self.burst_size
                    },
                    "retry_after": self._get_retry_after(client_ip, current_time)
                }
            )
        
        # Record request
        self._record_request(client_ip, current_time)
        
        # Add rate limit headers to response
        response = await call_next(request)
        self._add_rate_limit_headers(response, client_ip, current_time)
        
        return response
    
    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP from request"""
        # Check for forwarded headers first
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        return request.client.host if request.client else "unknown"
    
    def _check_rate_limits(self, client_ip: str, current_time: float) -> bool:
        """Check if request should be allowed based on rate limits"""
        request_times = self.request_history[client_ip]
        burst_times = self.burst_requests[client_ip]
        
        # Clean old requests
        minute_ago = current_time - 60
        hour_ago = current_time - 3600
        
        # Remove old minute requests
        while request_times and request_times[0] < minute_ago:
            request_times.popleft()
        
        # Remove old burst requests
        self.burst_requests[client_ip] = [
            t for t in burst_times if t > current_time - 10  # 10 second window
        ]
        
        # Check limits
        minute_requests = len([t for t in request_times if t > minute_ago])
        hour_requests = len([t for t in request_times if t > hour_ago])
        burst_requests = len(self.burst_requests[client_ip])
        
        return (
            minute_requests < self.requests_per_minute and
            hour_requests < self.requests_per_hour and
            burst_requests < self.burst_size
        )
    
    def _record_request(self, client_ip: str, current_time: float):
        """Record a new request"""
        self.request_history[client_ip].append(current_time)
        self.burst_requests[client_ip].append(current_time)
    
    def _get_retry_after(self, client_ip: str, current_time: float) -> int:
        """Calculate retry-after time in seconds"""
        request_times = self.request_history[client_ip]
        
        if not request_times:
            return 60
        
        # Find when the oldest request in the minute window will expire
        minute_ago = current_time - 60
        recent_requests = [t for t in request_times if t > minute_ago]
        
        if len(recent_requests) >= self.requests_per_minute:
            oldest_in_window = min(recent_requests)
            return int(60 - (current_time - oldest_in_window)) + 1
        
        return 60
    
    def _add_rate_limit_headers(
        self, 
        response: Response, 
        client_ip: str, 
        current_time: float
    ):
        """Add rate limit headers to response"""
        request_times = self.request_history[client_ip]
        
        minute_ago = current_time - 60
        hour_ago = current_time - 3600
        
        minute_requests = len([t for t in request_times if t > minute_ago])
        hour_requests = len([t for t in request_times if t > hour_ago])
        
        response.headers["X-RateLimit-Limit-Minute"] = str(self.requests_per_minute)
        response.headers["X-RateLimit-Remaining-Minute"] = str(
            max(0, self.requests_per_minute - minute_requests)
        )
        response.headers["X-RateLimit-Limit-Hour"] = str(self.requests_per_hour)
        response.headers["X-RateLimit-Remaining-Hour"] = str(
            max(0, self.requests_per_hour - hour_requests)
        )
        response.headers["X-RateLimit-Reset"] = str(int(current_time + 60))
    
    async def _cleanup_old_requests(self):
        """Periodic cleanup of old request records"""
        while True:
            await asyncio.sleep(300)  # Clean every 5 minutes
            current_time = time.time()
            hour_ago = current_time - 3600
            
            # Clean request history
            for client_ip in list(self.request_history.keys()):
                request_times = self.request_history[client_ip]
                while request_times and request_times[0] < hour_ago:
                    request_times.popleft()
                
                # Remove empty entries
                if not request_times:
                    del self.request_history[client_ip]
            
            # Clean burst requests
            for client_ip in list(self.burst_requests.keys()):
                self.burst_requests[client_ip] = [
                    t for t in self.burst_requests[client_ip]
                    if t > current_time - 10
                ]
                
                if not self.burst_requests[client_ip]:
                    del self.burst_requests[client_ip]
```

## Authentication & Security

### API Key Authentication
```python
# app/middleware/auth_middleware.py
from fastapi import HTTPException, Security, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import os
import hashlib
import hmac
from typing import Optional

security = HTTPBearer()

class APIKeyAuth:
    """API Key authentication for Claude endpoints"""
    
    def __init__(self):
        self.valid_api_keys = self._load_api_keys()
    
    def _load_api_keys(self) -> dict:
        """Load valid API keys from environment"""
        api_keys = {}
        
        # Load from environment variables
        master_key = os.getenv("CLAUDE_API_MASTER_KEY")
        if master_key:
            api_keys["master"] = master_key
        
        # Load additional keys (could be from database)
        for i in range(1, 6):  # Support up to 5 additional keys
            key = os.getenv(f"CLAUDE_API_KEY_{i}")
            if key:
                api_keys[f"key_{i}"] = key
        
        return api_keys
    
    def verify_api_key(
        self, 
        credentials: HTTPAuthorizationCredentials = Security(security)
    ) -> str:
        """Verify API key from Authorization header"""
        if not credentials:
            raise HTTPException(
                status_code=401,
                detail="Missing API key"
            )
        
        api_key = credentials.credentials
        
        # Check against valid keys
        for key_name, valid_key in self.valid_api_keys.items():
            if hmac.compare_digest(api_key, valid_key):
                return key_name
        
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )

api_key_auth = APIKeyAuth()

# Dependency for protected endpoints
def get_api_key(credentials: HTTPAuthorizationCredentials = Security(security)) -> str:
    return api_key_auth.verify_api_key(credentials)

# Usage in router
@router.post("/query", dependencies=[Depends(get_api_key)])
async def protected_query_claude(request: ClaudeQueryRequest):
    """Protected Claude query endpoint"""
    return await claude_service.query_claude(request)
```

## WebSocket Integration

### Real-time Claude Interaction
```python
# app/routers/claude_websocket.py
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.services.claude_service import claude_service
from app.models.claude_models import ClaudeQueryRequest
import json
import asyncio
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

class ConnectionManager:
    """Manage WebSocket connections for Claude interactions"""
    
    def __init__(self):
        self.active_connections: dict[str, WebSocket] = {}
        self.connection_sessions: dict[str, str] = {}  # connection_id -> session_id
    
    async def connect(self, websocket: WebSocket, connection_id: str):
        """Accept WebSocket connection"""
        await websocket.accept()
        self.active_connections[connection_id] = websocket
        logger.info(f"WebSocket connection established: {connection_id}")
    
    def disconnect(self, connection_id: str):
        """Remove WebSocket connection"""
        if connection_id in self.active_connections:
            del self.active_connections[connection_id]
        if connection_id in self.connection_sessions:
            # Cleanup Claude session
            session_id = self.connection_sessions[connection_id]
            claude_service.cleanup_session(session_id)
            del self.connection_sessions[connection_id]
        logger.info(f"WebSocket connection closed: {connection_id}")
    
    async def send_message(self, connection_id: str, message: dict):
        """Send message to specific connection"""
        if connection_id in self.active_connections:
            websocket = self.active_connections[connection_id]
            await websocket.send_text(json.dumps(message))
    
    async def send_error(self, connection_id: str, error: str):
        """Send error message to connection"""
        await self.send_message(connection_id, {
            "type": "error",
            "error": error
        })

manager = ConnectionManager()

@router.websocket("/ws/{connection_id}")
async def claude_websocket(websocket: WebSocket, connection_id: str):
    """WebSocket endpoint for real-time Claude interaction"""
    await manager.connect(websocket, connection_id)
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            await handle_websocket_message(connection_id, message_data)
            
    except WebSocketDisconnect:
        manager.disconnect(connection_id)
    except Exception as e:
        logger.error(f"WebSocket error for {connection_id}: {str(e)}")
        await manager.send_error(connection_id, str(e))
        manager.disconnect(connection_id)

async def handle_websocket_message(connection_id: str, message_data: dict):
    """Handle incoming WebSocket message"""
    message_type = message_data.get("type")
    
    if message_type == "start_conversation":
        await handle_start_conversation(connection_id, message_data)
    elif message_type == "send_message":
        await handle_send_message(connection_id, message_data)
    elif message_type == "end_conversation":
        await handle_end_conversation(connection_id)
    else:
        await manager.send_error(connection_id, f"Unknown message type: {message_type}")

async def handle_start_conversation(connection_id: str, message_data: dict):
    """Start a new Claude conversation"""
    try:
        # Create session ID
        session_id = f"ws_{connection_id}"
        manager.connection_sessions[connection_id] = session_id
        
        # Build Claude request
        claude_request = ClaudeQueryRequest(
            prompt=message_data.get("prompt", ""),
            max_turns=message_data.get("max_turns", 5),
            system_prompt=message_data.get("system_prompt"),
            permission_mode=message_data.get("permission_mode", "askForEdits")
        )
        
        # Send acknowledgment
        await manager.send_message(connection_id, {
            "type": "conversation_started",
            "session_id": session_id
        })
        
        # Stream Claude responses
        async for response in claude_service.stream_claude_response(claude_request):
            await manager.send_message(connection_id, {
                "type": "claude_response",
                "content": response.content,
                "role": response.role,
                "tools_used": response.tools_used,
                "is_complete": response.is_complete,
                "error": response.error
            })
            
            if response.is_complete or response.error:
                break
                
    except Exception as e:
        await manager.send_error(connection_id, f"Failed to start conversation: {str(e)}")

async def handle_send_message(connection_id: str, message_data: dict):
    """Send message in existing conversation"""
    try:
        session_id = manager.connection_sessions.get(connection_id)
        if not session_id:
            await manager.send_error(connection_id, "No active conversation")
            return
        
        user_message = message_data.get("message", "")
        
        # Continue conversation
        response = await claude_service.continue_conversation(session_id, user_message)
        
        if response.success:
            for message in response.messages:
                await manager.send_message(connection_id, {
                    "type": "claude_response",
                    "content": message.content,
                    "role": message.role,
                    "tools_used": message.tools_used,
                    "error": message.error
                })
        else:
            await manager.send_error(connection_id, response.error)
            
    except Exception as e:
        await manager.send_error(connection_id, f"Failed to send message: {str(e)}")

async def handle_end_conversation(connection_id: str):
    """End the current conversation"""
    session_id = manager.connection_sessions.get(connection_id)
    if session_id:
        claude_service.cleanup_session(session_id)
        del manager.connection_sessions[connection_id]
    
    await manager.send_message(connection_id, {
        "type": "conversation_ended"
    })
```

## Production Deployment

### Docker Configuration
```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install Node.js for Claude CLI
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude CLI
RUN npm install -g @anthropic-ai/claude-code

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  claude-api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - CLAUDE_API_MASTER_KEY=${CLAUDE_API_MASTER_KEY}
      - ENVIRONMENT=production
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - claude-api
    restart: unless-stopped

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    restart: unless-stopped
```

### Requirements File
```txt
# requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
claude-code-sdk==1.0.0
pydantic==2.5.0
python-dotenv==1.0.0
redis==5.0.1
aioredis==2.0.1
python-multipart==0.0.6
```

## Next Steps

Continue with:
1. [Async Programming Patterns](python-sdk-async-patterns.md)
2. [Configuration Management](python-sdk-configuration.md)
3. [Error Handling Strategies](python-sdk-error-handling.md)
4. [Production Best Practices](python-sdk-best-practices.md)

---

**Last Updated:** Based on Claude Code SDK documentation as of 2025
**Reference:** https://docs.anthropic.com/en/docs/claude-code/sdk
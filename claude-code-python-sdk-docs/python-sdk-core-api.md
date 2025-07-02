# Claude Code Python SDK Core API

## Overview
The Claude Code Python SDK provides a streamlined async interface for integrating AI-powered coding assistance into web applications. The core API consists of the `query()` function, configuration options, and message handling.

## Core Functions

### query() Function
The primary interface for communicating with Claude Code:

```python
from claude_code_sdk import query, ClaudeCodeOptions, Message
import asyncio

async def basic_query():
    """Basic usage of the query function"""
    messages = []
    
    async for message in query(
        prompt="Write a Python function to validate email addresses",
        options=ClaudeCodeOptions(max_turns=1)
    ):
        messages.append(message)
    
    return messages[0].content if messages else None
```

#### Function Signature
```python
async def query(
    prompt: str,
    options: ClaudeCodeOptions = None
) -> AsyncIterator[Message]:
    """
    Query Claude Code with a prompt and receive streaming responses.
    
    Args:
        prompt: The input prompt/question for Claude
        options: Configuration options for the query
        
    Yields:
        Message: Individual message objects from the conversation
    """
```

## ClaudeCodeOptions Configuration

### Basic Configuration
```python
from claude_code_sdk import ClaudeCodeOptions
from pathlib import Path

# Basic options
options = ClaudeCodeOptions(
    max_turns=3,
    system_prompt="You are a web development expert",
    cwd=Path("/path/to/project")
)
```

### Complete Configuration Options
```python
from claude_code_sdk import ClaudeCodeOptions
from pathlib import Path

# Full configuration example
options = ClaudeCodeOptions(
    # Conversation settings
    max_turns=5,                    # Maximum conversation turns
    system_prompt="Custom instructions for Claude",
    
    # Project context
    cwd=Path("/project/directory"), # Working directory for file operations
    
    # Tool permissions
    allowed_tools=[                 # List of allowed tools
        "Read", "Write", "Bash", "Grep", "LS"
    ],
    permission_mode="askForEdits",  # Permission handling mode
    
    # Model settings (if supported)
    model="claude-3-5-sonnet-20241022",  # Specific model version
    
    # Output formatting
    output_format="text",           # Output format preference
    
    # Advanced settings
    verbose=False,                  # Enable verbose logging
    timeout=300                     # Request timeout in seconds
)
```

### Permission Modes
```python
# Different permission handling strategies
permission_modes = {
    "askForEdits": "Ask user permission before making file changes",
    "acceptEdits": "Automatically accept file modifications", 
    "readOnly": "Only allow read operations",
    "strict": "Require explicit permission for all operations"
}

# Web application example - safe for production
web_safe_options = ClaudeCodeOptions(
    permission_mode="askForEdits",
    allowed_tools=["Read", "Grep", "LS"],  # Read-only tools
    max_turns=3
)
```

## Message Objects

### Message Structure
```python
from claude_code_sdk import Message
from typing import Any, Dict, Optional

class Message:
    """
    Represents a message in the Claude Code conversation.
    """
    content: str                    # Message content
    role: str                       # "user" or "assistant"
    timestamp: Optional[datetime]   # Message timestamp
    metadata: Dict[str, Any]        # Additional message metadata
    tools_used: List[str]          # Tools used in this message
    error: Optional[str]           # Error message if applicable
```

### Message Handling
```python
async def process_messages():
    """Example of processing message stream"""
    conversation_history = []
    
    async for message in query(
        prompt="Analyze this FastAPI application structure",
        options=ClaudeCodeOptions(max_turns=3)
    ):
        # Store message
        conversation_history.append(message)
        
        # Process different message types
        if message.role == "assistant":
            print(f"Claude: {message.content}")
            
            if message.tools_used:
                print(f"Tools used: {', '.join(message.tools_used)}")
                
        elif message.role == "user":
            print(f"User: {message.content}")
            
        # Handle errors
        if message.error:
            print(f"Error: {message.error}")
            break
    
    return conversation_history
```

## Web Application Integration Patterns

### FastAPI Endpoint Example
```python
from fastapi import FastAPI, HTTPException
from claude_code_sdk import query, ClaudeCodeOptions, Message
from typing import List
import asyncio

app = FastAPI()

class QueryRequest:
    prompt: str
    max_turns: int = 3
    system_prompt: str = "You are a helpful coding assistant"

class QueryResponse:
    messages: List[dict]
    success: bool
    error: str = None

@app.post("/api/claude/query", response_model=QueryResponse)
async def claude_query(request: QueryRequest):
    """Web endpoint for Claude Code queries"""
    try:
        messages = []
        options = ClaudeCodeOptions(
            max_turns=request.max_turns,
            system_prompt=request.system_prompt,
            permission_mode="askForEdits",
            allowed_tools=["Read", "Grep", "LS"]  # Safe for web
        )
        
        async for message in query(request.prompt, options):
            messages.append({
                "content": message.content,
                "role": message.role,
                "timestamp": message.timestamp,
                "tools_used": message.tools_used
            })
        
        return QueryResponse(
            messages=messages,
            success=True
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### Async Context Manager Pattern
```python
from contextlib import asynccontextmanager
from claude_code_sdk import query, ClaudeCodeOptions

@asynccontextmanager
async def claude_session(project_path: str, max_turns: int = 5):
    """Context manager for Claude Code sessions"""
    options = ClaudeCodeOptions(
        max_turns=max_turns,
        cwd=Path(project_path),
        permission_mode="askForEdits"
    )
    
    try:
        yield lambda prompt: query(prompt, options)
    except Exception as e:
        print(f"Claude session error: {e}")
        raise
    finally:
        # Cleanup if needed
        pass

# Usage in web application
async def analyze_codebase(project_path: str, user_question: str):
    async with claude_session(project_path) as claude:
        messages = []
        async for message in claude(user_question):
            messages.append(message)
        return messages
```

### Streaming Response Handler
```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from claude_code_sdk import query, ClaudeCodeOptions
import json

app = FastAPI()

@app.post("/api/claude/stream")
async def claude_stream(prompt: str):
    """Streaming endpoint for real-time responses"""
    
    async def generate_stream():
        """Generate streaming JSON responses"""
        options = ClaudeCodeOptions(
            max_turns=3,
            permission_mode="readOnly"
        )
        
        async for message in query(prompt, options):
            # Stream each message as JSON
            response_data = {
                "content": message.content,
                "role": message.role,
                "tools_used": message.tools_used,
                "error": message.error
            }
            yield f"data: {json.dumps(response_data)}\n\n"
        
        # End stream
        yield "data: [DONE]\n\n"
    
    return StreamingResponse(
        generate_stream(),
        media_type="text/plain",
        headers={"Cache-Control": "no-cache"}
    )
```

## Error Handling Patterns

### Basic Error Handling
```python
from claude_code_sdk import query, ClaudeCodeOptions

async def safe_claude_query(prompt: str):
    """Query with comprehensive error handling"""
    try:
        options = ClaudeCodeOptions(
            max_turns=3,
            permission_mode="readOnly",
            timeout=30  # 30 second timeout
        )
        
        messages = []
        async for message in query(prompt, options):
            # Check for message-level errors
            if message.error:
                return {
                    "success": False,
                    "error": f"Claude error: {message.error}",
                    "messages": messages
                }
            
            messages.append(message)
        
        return {
            "success": True,
            "messages": messages
        }
        
    except TimeoutError:
        return {
            "success": False,
            "error": "Query timeout - Claude took too long to respond"
        }
    except ConnectionError:
        return {
            "success": False,
            "error": "Connection error - Check internet connection and API key"
        }
    except PermissionError as e:
        return {
            "success": False,
            "error": f"Permission denied: {e}"
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Unexpected error: {str(e)}"
        }
```

### Retry Logic
```python
import asyncio
from typing import Optional

async def claude_query_with_retry(
    prompt: str, 
    max_retries: int = 3,
    backoff_seconds: float = 1.0
) -> Optional[List[Message]]:
    """Query with exponential backoff retry logic"""
    
    for attempt in range(max_retries):
        try:
            messages = []
            options = ClaudeCodeOptions(
                max_turns=3,
                permission_mode="readOnly"
            )
            
            async for message in query(prompt, options):
                messages.append(message)
            
            return messages
            
        except (ConnectionError, TimeoutError) as e:
            if attempt == max_retries - 1:
                raise e
                
            wait_time = backoff_seconds * (2 ** attempt)
            print(f"Attempt {attempt + 1} failed, retrying in {wait_time}s...")
            await asyncio.sleep(wait_time)
            
        except Exception as e:
            # Don't retry on non-transient errors
            raise e
    
    return None
```

## Advanced Usage Patterns

### Conversation State Management
```python
from typing import Dict, List
from datetime import datetime

class ClaudeConversationManager:
    """Manage multiple Claude conversations for web application"""
    
    def __init__(self):
        self.conversations: Dict[str, List[Message]] = {}
        self.last_activity: Dict[str, datetime] = {}
    
    async def start_conversation(
        self, 
        session_id: str, 
        initial_prompt: str,
        project_path: str = None
    ) -> List[Message]:
        """Start a new conversation session"""
        
        options = ClaudeCodeOptions(
            max_turns=10,
            cwd=Path(project_path) if project_path else None,
            permission_mode="askForEdits"
        )
        
        messages = []
        async for message in query(initial_prompt, options):
            messages.append(message)
        
        self.conversations[session_id] = messages
        self.last_activity[session_id] = datetime.now()
        
        return messages
    
    async def continue_conversation(
        self, 
        session_id: str, 
        follow_up_prompt: str
    ) -> List[Message]:
        """Continue an existing conversation"""
        
        if session_id not in self.conversations:
            raise ValueError(f"No conversation found for session {session_id}")
        
        # Build conversation context
        conversation_context = self._build_context(session_id)
        full_prompt = f"{conversation_context}\n\nUser: {follow_up_prompt}"
        
        options = ClaudeCodeOptions(max_turns=5)
        new_messages = []
        
        async for message in query(full_prompt, options):
            new_messages.append(message)
        
        # Update conversation history
        self.conversations[session_id].extend(new_messages)
        self.last_activity[session_id] = datetime.now()
        
        return new_messages
    
    def _build_context(self, session_id: str) -> str:
        """Build conversation context from message history"""
        messages = self.conversations[session_id]
        context_lines = []
        
        for message in messages[-5:]:  # Last 5 messages for context
            role = "Assistant" if message.role == "assistant" else "User"
            context_lines.append(f"{role}: {message.content[:200]}...")
        
        return "\n".join(context_lines)
    
    def cleanup_old_conversations(self, max_age_hours: int = 24):
        """Clean up old conversation sessions"""
        cutoff_time = datetime.now() - timedelta(hours=max_age_hours)
        
        expired_sessions = [
            session_id for session_id, last_time in self.last_activity.items()
            if last_time < cutoff_time
        ]
        
        for session_id in expired_sessions:
            del self.conversations[session_id]
            del self.last_activity[session_id]
```

## Performance Considerations

### Connection Pooling
```python
import asyncio
from typing import AsyncGenerator

class ClaudeConnectionPool:
    """Manage concurrent Claude queries efficiently"""
    
    def __init__(self, max_concurrent: int = 5):
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.active_queries = 0
    
    async def query_with_limit(
        self, 
        prompt: str, 
        options: ClaudeCodeOptions = None
    ) -> AsyncGenerator[Message, None]:
        """Execute query with concurrency limits"""
        
        async with self.semaphore:
            self.active_queries += 1
            try:
                async for message in query(prompt, options):
                    yield message
            finally:
                self.active_queries -= 1

# Usage in web application
pool = ClaudeConnectionPool(max_concurrent=3)

@app.post("/api/claude/query")
async def limited_claude_query(prompt: str):
    messages = []
    async for message in pool.query_with_limit(prompt):
        messages.append(message)
    return {"messages": messages}
```

### Response Caching
```python
import hashlib
from typing import Optional, Dict, Any
from datetime import datetime, timedelta

class ClaudeResponseCache:
    """Cache Claude responses for improved performance"""
    
    def __init__(self, ttl_minutes: int = 60):
        self.cache: Dict[str, Dict[str, Any]] = {}
        self.ttl = timedelta(minutes=ttl_minutes)
    
    def _get_cache_key(self, prompt: str, options: ClaudeCodeOptions) -> str:
        """Generate cache key from prompt and options"""
        options_str = f"{options.max_turns}_{options.system_prompt}_{options.permission_mode}"
        combined = f"{prompt}_{options_str}"
        return hashlib.md5(combined.encode()).hexdigest()
    
    def get_cached_response(
        self, 
        prompt: str, 
        options: ClaudeCodeOptions
    ) -> Optional[List[Message]]:
        """Get cached response if available and not expired"""
        
        cache_key = self._get_cache_key(prompt, options)
        
        if cache_key not in self.cache:
            return None
        
        cached_entry = self.cache[cache_key]
        
        # Check if expired
        if datetime.now() - cached_entry["timestamp"] > self.ttl:
            del self.cache[cache_key]
            return None
        
        return cached_entry["messages"]
    
    def cache_response(
        self, 
        prompt: str, 
        options: ClaudeCodeOptions, 
        messages: List[Message]
    ):
        """Cache a response"""
        cache_key = self._get_cache_key(prompt, options)
        
        self.cache[cache_key] = {
            "messages": messages,
            "timestamp": datetime.now()
        }
    
    def clear_expired(self):
        """Remove expired cache entries"""
        now = datetime.now()
        expired_keys = [
            key for key, entry in self.cache.items()
            if now - entry["timestamp"] > self.ttl
        ]
        
        for key in expired_keys:
            del self.cache[key]

# Usage with caching
cache = ClaudeResponseCache(ttl_minutes=30)

async def cached_claude_query(prompt: str, options: ClaudeCodeOptions):
    """Query with response caching"""
    
    # Check cache first
    cached_response = cache.get_cached_response(prompt, options)
    if cached_response:
        return cached_response
    
    # Execute query
    messages = []
    async for message in query(prompt, options):
        messages.append(message)
    
    # Cache the response
    cache.cache_response(prompt, options, messages)
    
    return messages
```

## Next Steps

After mastering the core API:
1. Explore [FastAPI Integration Patterns](python-sdk-fastapi-integration.md)
2. Learn [Async Programming Patterns](python-sdk-async-patterns.md)
3. Study [Configuration Options](python-sdk-configuration.md)
4. Implement [Error Handling](python-sdk-error-handling.md)

---

**Last Updated:** Based on Claude Code SDK documentation as of 2025
**Reference:** https://docs.anthropic.com/en/docs/claude-code/sdk
# FastAPI Async, Streaming, and WebSocket Patterns

## Overview
This guide covers FastAPI's advanced async capabilities including streaming responses, server-sent events (SSE), WebSocket connections, and concurrent processing patterns for building real-time and high-performance web applications.

## Async Request Handling

### Basic Async Patterns
```python
import asyncio
import aiohttp
import aiofiles
from fastapi import FastAPI, HTTPException, BackgroundTasks
from typing import List, Dict, Any, AsyncGenerator
from datetime import datetime
import json

app = FastAPI()

# Basic async endpoint
@app.get("/async-data")
async def get_async_data() -> Dict[str, Any]:
    """Basic async endpoint with concurrent operations."""
    
    # Simulate multiple async operations
    async def fetch_user_data() -> Dict[str, str]:
        await asyncio.sleep(0.1)  # Simulate DB query
        return {"user": "john_doe", "role": "admin"}
    
    async def fetch_permissions() -> List[str]:
        await asyncio.sleep(0.1)  # Simulate API call
        return ["read", "write", "delete"]
    
    async def fetch_preferences() -> Dict[str, Any]:
        await asyncio.sleep(0.1)  # Simulate cache lookup
        return {"theme": "dark", "notifications": True}
    
    # Run operations concurrently
    user_data, permissions, preferences = await asyncio.gather(
        fetch_user_data(),
        fetch_permissions(),
        fetch_preferences()
    )
    
    return {
        "user": user_data,
        "permissions": permissions,
        "preferences": preferences,
        "timestamp": datetime.now().isoformat()
    }

# Async with external API calls
@app.get("/external-data/{resource}")
async def fetch_external_data(resource: str) -> Dict[str, Any]:
    """Fetch data from external APIs asynchronously."""
    
    async with aiohttp.ClientSession() as session:
        urls = [
            f"https://jsonplaceholder.typicode.com/{resource}",
            f"https://httpbin.org/json",
            f"https://api.github.com/repos/tiangolo/fastapi"
        ]
        
        results = []
        for url in urls:
            try:
                async with session.get(url, timeout=5) as response:
                    if response.status == 200:
                        data = await response.json()
                        results.append({
                            "url": url,
                            "status": "success",
                            "data": data
                        })
                    else:
                        results.append({
                            "url": url,
                            "status": "error",
                            "error": f"HTTP {response.status}"
                        })
            except asyncio.TimeoutError:
                results.append({
                    "url": url,
                    "status": "timeout",
                    "error": "Request timeout"
                })
            except Exception as e:
                results.append({
                    "url": url,
                    "status": "error",
                    "error": str(e)
                })
        
        return {"results": results}

# Async file operations
@app.post("/upload-process")
async def upload_and_process_file(background_tasks: BackgroundTasks) -> Dict[str, str]:
    """Async file upload and processing."""
    
    async def process_file_async(filename: str):
        """Background task for file processing."""
        async with aiofiles.open(f"/tmp/{filename}", 'w') as f:
            await f.write("Processing started...\n")
            
            # Simulate long-running processing
            for i in range(5):
                await asyncio.sleep(1)
                await f.write(f"Processing step {i+1}/5...\n")
            
            await f.write("Processing completed!\n")
    
    filename = f"process_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
    
    # Start background processing
    background_tasks.add_task(process_file_async, filename)
    
    return {
        "message": "File processing started",
        "filename": filename,
        "status": "processing"
    }
```

## Streaming Responses

### Basic Streaming
```python
from fastapi.responses import StreamingResponse
from io import StringIO
import csv
import time

@app.get("/stream/numbers")
async def stream_numbers() -> StreamingResponse:
    """Stream a sequence of numbers."""
    
    async def generate_numbers():
        for i in range(100):
            yield f"Number: {i}\n"
            await asyncio.sleep(0.1)  # Simulate processing time
    
    return StreamingResponse(
        generate_numbers(),
        media_type="text/plain",
        headers={"Content-Disposition": "attachment; filename=numbers.txt"}
    )

@app.get("/stream/csv")
async def stream_csv_data() -> StreamingResponse:
    """Stream CSV data generation."""
    
    async def generate_csv():
        # Create CSV header
        output = StringIO()
        writer = csv.writer(output)
        writer.writerow(["ID", "Name", "Email", "Created"])
        csv_header = output.getvalue()
        output.close()
        yield csv_header
        
        # Generate data rows
        for i in range(1000):
            output = StringIO()
            writer = csv.writer(output)
            writer.writerow([
                i,
                f"User_{i}",
                f"user_{i}@example.com",
                datetime.now().isoformat()
            ])
            row_data = output.getvalue()
            output.close()
            yield row_data
            
            # Small delay to demonstrate streaming
            await asyncio.sleep(0.01)
    
    return StreamingResponse(
        generate_csv(),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=users.csv"}
    )

# Streaming large file downloads
@app.get("/download/large-file")
async def download_large_file() -> StreamingResponse:
    """Stream large file download."""
    
    async def generate_large_file():
        # Simulate large file content
        chunk_size = 1024 * 8  # 8KB chunks
        
        for chunk_num in range(1000):  # 8MB total
            chunk_data = f"Chunk {chunk_num:04d}: " + "x" * (chunk_size - 20) + "\n"
            yield chunk_data.encode()
            await asyncio.sleep(0.001)  # Small delay
    
    return StreamingResponse(
        generate_large_file(),
        media_type="application/octet-stream",
        headers={
            "Content-Disposition": "attachment; filename=large_file.txt",
            "Content-Length": str(1024 * 1024 * 8)  # 8MB
        }
    )

# Streaming JSON data
@app.get("/stream/json")
async def stream_json_data() -> StreamingResponse:
    """Stream JSON data as JSONL (JSON Lines)."""
    
    async def generate_json_lines():
        for i in range(100):
            data = {
                "id": i,
                "timestamp": datetime.now().isoformat(),
                "value": i * 2,
                "status": "active" if i % 2 == 0 else "inactive"
            }
            yield json.dumps(data) + "\n"
            await asyncio.sleep(0.05)
    
    return StreamingResponse(
        generate_json_lines(),
        media_type="application/x-ndjson",
        headers={"Content-Disposition": "attachment; filename=data.jsonl"}
    )
```

### Advanced Streaming Patterns
```python
from fastapi import Query
from typing import Optional
import gzip
import base64

@app.get("/stream/compressed")
async def stream_compressed_data() -> StreamingResponse:
    """Stream compressed data."""
    
    async def generate_compressed_data():
        # Create large text data and compress it
        data_chunks = []
        
        for i in range(1000):
            chunk = f"This is line {i} with some repetitive data that compresses well. " * 10 + "\n"
            data_chunks.append(chunk.encode())
        
        # Compress the data
        compressed_data = gzip.compress(b"".join(data_chunks))
        
        # Stream in chunks
        chunk_size = 1024
        for i in range(0, len(compressed_data), chunk_size):
            yield compressed_data[i:i + chunk_size]
            await asyncio.sleep(0.01)
    
    return StreamingResponse(
        generate_compressed_data(),
        media_type="application/gzip",
        headers={
            "Content-Encoding": "gzip",
            "Content-Disposition": "attachment; filename=data.txt.gz"
        }
    )

# Real-time data streaming
@app.get("/stream/realtime")
async def stream_realtime_data(
    duration: int = Query(60, description="Stream duration in seconds"),
    interval: float = Query(1.0, description="Update interval in seconds")
) -> StreamingResponse:
    """Stream real-time data updates."""
    
    async def generate_realtime_data():
        start_time = time.time()
        counter = 0
        
        while time.time() - start_time < duration:
            # Simulate real-time metrics
            data = {
                "timestamp": datetime.now().isoformat(),
                "counter": counter,
                "cpu_usage": 20 + (counter % 50),
                "memory_usage": 40 + (counter % 30),
                "active_connections": 100 + (counter % 20)
            }
            
            yield f"data: {json.dumps(data)}\n\n"
            counter += 1
            await asyncio.sleep(interval)
        
        # Send completion message
        yield f"data: {json.dumps({'status': 'completed', 'total_updates': counter})}\n\n"
    
    return StreamingResponse(
        generate_realtime_data(),
        media_type="text/plain"
    )

# Database streaming
@app.get("/stream/users")
async def stream_users_from_db() -> StreamingResponse:
    """Stream users from database."""
    
    async def generate_users():
        # Simulate database cursor/pagination
        batch_size = 100
        offset = 0
        
        while True:
            # Simulate database query
            await asyncio.sleep(0.1)  # DB query time
            
            # Generate batch of users
            users_batch = []
            for i in range(batch_size):
                user_id = offset + i + 1
                users_batch.append({
                    "id": user_id,
                    "name": f"User {user_id}",
                    "email": f"user{user_id}@example.com",
                    "created_at": datetime.now().isoformat()
                })
            
            # Stop if no more users (simulate end of data)
            if offset >= 1000:  # Simulate 1000 total users
                break
            
            # Yield batch as JSON lines
            for user in users_batch:
                yield json.dumps(user) + "\n"
            
            offset += batch_size
    
    return StreamingResponse(
        generate_users(),
        media_type="application/x-ndjson",
        headers={"Content-Disposition": "attachment; filename=users.jsonl"}
    )
```

## Server-Sent Events (SSE)

### Basic SSE Implementation
```python
from fastapi.responses import StreamingResponse
from fastapi import Request
import uuid
from typing import Dict, Set

# SSE connection manager
class SSEManager:
    def __init__(self):
        self.connections: Dict[str, AsyncGenerator] = {}
    
    async def connect(self, client_id: str) -> AsyncGenerator[str, None]:
        """Create SSE connection for client."""
        async def event_stream():
            try:
                while True:
                    # Send heartbeat every 30 seconds
                    yield f"data: {json.dumps({'type': 'heartbeat', 'timestamp': datetime.now().isoformat()})}\n\n"
                    await asyncio.sleep(30)
            except asyncio.CancelledError:
                # Client disconnected
                if client_id in self.connections:
                    del self.connections[client_id]
                raise
        
        generator = event_stream()
        self.connections[client_id] = generator
        return generator
    
    async def broadcast(self, event_type: str, data: Dict[str, Any]):
        """Broadcast event to all connected clients."""
        if not self.connections:
            return
        
        message = f"data: {json.dumps({'type': event_type, 'data': data, 'timestamp': datetime.now().isoformat()})}\n\n"
        
        # Remove disconnected clients
        disconnected = []
        for client_id, connection in self.connections.items():
            try:
                await connection.asend(message)
            except (StopAsyncIteration, GeneratorExit):
                disconnected.append(client_id)
        
        for client_id in disconnected:
            del self.connections[client_id]
    
    def get_connection_count(self) -> int:
        """Get number of active connections."""
        return len(self.connections)

sse_manager = SSEManager()

@app.get("/sse/connect")
async def sse_connect(request: Request) -> StreamingResponse:
    """Establish SSE connection."""
    client_id = str(uuid.uuid4())
    
    async def event_stream():
        try:
            # Send initial connection message
            yield f"data: {json.dumps({'type': 'connected', 'client_id': client_id})}\n\n"
            
            # Keep connection alive
            while True:
                # Check if client is still connected
                if await request.is_disconnected():
                    break
                
                # Send periodic updates
                data = {
                    "server_time": datetime.now().isoformat(),
                    "active_connections": sse_manager.get_connection_count(),
                    "random_value": hash(datetime.now()) % 1000
                }
                
                yield f"data: {json.dumps({'type': 'update', 'data': data})}\n\n"
                await asyncio.sleep(5)
                
        except asyncio.CancelledError:
            # Client disconnected
            pass
    
    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Cache-Control"
        }
    )

# Endpoint to trigger events
@app.post("/sse/broadcast")
async def broadcast_event(event_type: str, data: Dict[str, Any]) -> Dict[str, str]:
    """Broadcast event to all SSE clients."""
    await sse_manager.broadcast(event_type, data)
    return {
        "message": f"Event '{event_type}' broadcast to {sse_manager.get_connection_count()} clients"
    }

# Real-time notifications example
@app.get("/sse/notifications")
async def sse_notifications(request: Request) -> StreamingResponse:
    """SSE endpoint for real-time notifications."""
    
    async def notification_stream():
        try:
            # Send initial message
            yield f"data: {json.dumps({'type': 'connected', 'message': 'Notification stream connected'})}\n\n"
            
            notification_count = 0
            while True:
                if await request.is_disconnected():
                    break
                
                # Simulate random notifications
                if notification_count % 3 == 0:
                    notification = {
                        "id": notification_count,
                        "title": f"Notification {notification_count}",
                        "message": f"This is notification number {notification_count}",
                        "priority": "normal" if notification_count % 2 == 0 else "high",
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    yield f"data: {json.dumps({'type': 'notification', 'data': notification})}\n\n"
                
                notification_count += 1
                await asyncio.sleep(2)
                
        except asyncio.CancelledError:
            pass
    
    return StreamingResponse(
        notification_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )
```

## WebSocket Connections

### Basic WebSocket Implementation
```python
from fastapi import WebSocket, WebSocketDisconnect
from typing import List, Dict
import json

class WebSocketManager:
    """Manage WebSocket connections."""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.connection_data: Dict[WebSocket, Dict[str, Any]] = {}
    
    async def connect(self, websocket: WebSocket, client_info: Dict[str, Any] = None):
        """Accept WebSocket connection."""
        await websocket.accept()
        self.active_connections.append(websocket)
        self.connection_data[websocket] = client_info or {}
    
    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if websocket in self.connection_data:
            del self.connection_data[websocket]
    
    async def send_personal_message(self, message: str, websocket: WebSocket):
        """Send message to specific client."""
        try:
            await websocket.send_text(message)
        except:
            self.disconnect(websocket)
    
    async def broadcast(self, message: str):
        """Broadcast message to all connected clients."""
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except:
                disconnected.append(connection)
        
        # Remove disconnected clients
        for connection in disconnected:
            self.disconnect(connection)
    
    def get_connection_count(self) -> int:
        """Get number of active connections."""
        return len(self.active_connections)

websocket_manager = WebSocketManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    """Basic WebSocket endpoint."""
    await websocket_manager.connect(websocket, {"client_id": client_id})
    
    try:
        # Send welcome message
        await websocket.send_text(json.dumps({
            "type": "welcome",
            "message": f"Welcome client {client_id}",
            "timestamp": datetime.now().isoformat()
        }))
        
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                message_type = message.get("type", "unknown")
                
                if message_type == "ping":
                    # Respond to ping
                    await websocket.send_text(json.dumps({
                        "type": "pong",
                        "timestamp": datetime.now().isoformat()
                    }))
                
                elif message_type == "broadcast":
                    # Broadcast message to all clients
                    broadcast_message = json.dumps({
                        "type": "broadcast",
                        "from": client_id,
                        "message": message.get("message", ""),
                        "timestamp": datetime.now().isoformat()
                    })
                    await websocket_manager.broadcast(broadcast_message)
                
                elif message_type == "echo":
                    # Echo message back to sender
                    await websocket.send_text(json.dumps({
                        "type": "echo",
                        "original": message,
                        "timestamp": datetime.now().isoformat()
                    }))
                
                else:
                    # Unknown message type
                    await websocket.send_text(json.dumps({
                        "type": "error",
                        "message": f"Unknown message type: {message_type}"
                    }))
                    
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))
                
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket)
        
        # Notify other clients about disconnection
        await websocket_manager.broadcast(json.dumps({
            "type": "user_disconnected",
            "client_id": client_id,
            "timestamp": datetime.now().isoformat()
        }))

# WebSocket status endpoint
@app.get("/ws/status")
async def websocket_status():
    """Get WebSocket connection status."""
    return {
        "active_connections": websocket_manager.get_connection_count(),
        "timestamp": datetime.now().isoformat()
    }
```

### Advanced WebSocket Patterns
```python
from typing import Optional, Callable
import asyncio
from enum import Enum

class MessageType(str, Enum):
    CHAT = "chat"
    SYSTEM = "system"
    NOTIFICATION = "notification"
    ERROR = "error"
    STATUS = "status"

class ChatRoom:
    """Chat room with WebSocket support."""
    
    def __init__(self, room_id: str):
        self.room_id = room_id
        self.connections: Dict[str, WebSocket] = {}
        self.message_history: List[Dict[str, Any]] = []
        self.max_history = 100
    
    async def add_user(self, user_id: str, websocket: WebSocket):
        """Add user to chat room."""
        await websocket.accept()
        self.connections[user_id] = websocket
        
        # Send chat history
        for message in self.message_history[-20:]:  # Last 20 messages
            await websocket.send_text(json.dumps(message))
        
        # Notify other users
        await self.broadcast_system_message(f"{user_id} joined the room")
    
    def remove_user(self, user_id: str):
        """Remove user from chat room."""
        if user_id in self.connections:
            del self.connections[user_id]
    
    async def send_message(self, sender: str, message: str):
        """Send chat message to all users in room."""
        chat_message = {
            "type": MessageType.CHAT,
            "room_id": self.room_id,
            "sender": sender,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        
        # Add to history
        self.message_history.append(chat_message)
        if len(self.message_history) > self.max_history:
            self.message_history = self.message_history[-self.max_history:]
        
        # Broadcast to all users
        await self.broadcast(json.dumps(chat_message))
    
    async def broadcast_system_message(self, message: str):
        """Broadcast system message to all users."""
        system_message = {
            "type": MessageType.SYSTEM,
            "room_id": self.room_id,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        
        await self.broadcast(json.dumps(system_message))
    
    async def broadcast(self, message: str):
        """Broadcast message to all users in room."""
        disconnected = []
        
        for user_id, websocket in self.connections.items():
            try:
                await websocket.send_text(message)
            except:
                disconnected.append(user_id)
        
        # Remove disconnected users
        for user_id in disconnected:
            self.remove_user(user_id)
    
    def get_user_count(self) -> int:
        """Get number of users in room."""
        return len(self.connections)
    
    def get_users(self) -> List[str]:
        """Get list of users in room."""
        return list(self.connections.keys())

class ChatManager:
    """Manage multiple chat rooms."""
    
    def __init__(self):
        self.rooms: Dict[str, ChatRoom] = {}
    
    def get_room(self, room_id: str) -> ChatRoom:
        """Get or create chat room."""
        if room_id not in self.rooms:
            self.rooms[room_id] = ChatRoom(room_id)
        return self.rooms[room_id]
    
    def remove_empty_rooms(self):
        """Remove empty chat rooms."""
        empty_rooms = [
            room_id for room_id, room in self.rooms.items()
            if room.get_user_count() == 0
        ]
        
        for room_id in empty_rooms:
            del self.rooms[room_id]
    
    def get_room_stats(self) -> Dict[str, Any]:
        """Get statistics for all rooms."""
        return {
            "total_rooms": len(self.rooms),
            "rooms": {
                room_id: {
                    "user_count": room.get_user_count(),
                    "users": room.get_users()
                }
                for room_id, room in self.rooms.items()
            }
        }

chat_manager = ChatManager()

@app.websocket("/ws/chat/{room_id}/{user_id}")
async def chat_websocket(websocket: WebSocket, room_id: str, user_id: str):
    """WebSocket endpoint for chat functionality."""
    room = chat_manager.get_room(room_id)
    
    try:
        await room.add_user(user_id, websocket)
        
        while True:
            data = await websocket.receive_text()
            
            try:
                message_data = json.loads(data)
                message_type = message_data.get("type")
                
                if message_type == "chat":
                    await room.send_message(user_id, message_data.get("message", ""))
                
                elif message_type == "get_users":
                    await websocket.send_text(json.dumps({
                        "type": "users_list",
                        "users": room.get_users()
                    }))
                
                elif message_type == "typing":
                    # Broadcast typing indicator
                    typing_message = {
                        "type": "typing",
                        "user": user_id,
                        "is_typing": message_data.get("is_typing", False)
                    }
                    await room.broadcast(json.dumps(typing_message))
                
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))
                
    except WebSocketDisconnect:
        room.remove_user(user_id)
        await room.broadcast_system_message(f"{user_id} left the room")
        
        # Clean up empty rooms
        chat_manager.remove_empty_rooms()

# Chat room management endpoints
@app.get("/chat/rooms")
async def get_chat_rooms():
    """Get chat room statistics."""
    return chat_manager.get_room_stats()

@app.post("/chat/rooms/{room_id}/message")
async def send_system_message(room_id: str, message: str):
    """Send system message to chat room."""
    if room_id in chat_manager.rooms:
        room = chat_manager.rooms[room_id]
        await room.broadcast_system_message(message)
        return {"message": "System message sent"}
    else:
        raise HTTPException(404, "Room not found")
```

### Real-time Data Streaming with WebSockets
```python
import random
from typing import Dict, Any

class DataStreamer:
    """Stream real-time data to WebSocket clients."""
    
    def __init__(self):
        self.subscribers: Dict[str, Dict[str, Any]] = {}
        self.is_streaming = False
        self.stream_task: Optional[asyncio.Task] = None
    
    async def subscribe(self, client_id: str, websocket: WebSocket, data_types: List[str]):
        """Subscribe client to data streams."""
        await websocket.accept()
        
        self.subscribers[client_id] = {
            "websocket": websocket,
            "data_types": data_types,
            "last_update": datetime.now()
        }
        
        # Start streaming if not already started
        if not self.is_streaming:
            await self.start_streaming()
    
    def unsubscribe(self, client_id: str):
        """Unsubscribe client from data streams."""
        if client_id in self.subscribers:
            del self.subscribers[client_id]
        
        # Stop streaming if no subscribers
        if not self.subscribers and self.is_streaming:
            self.stop_streaming()
    
    async def start_streaming(self):
        """Start data streaming task."""
        if self.is_streaming:
            return
        
        self.is_streaming = True
        self.stream_task = asyncio.create_task(self._stream_data())
    
    def stop_streaming(self):
        """Stop data streaming task."""
        self.is_streaming = False
        if self.stream_task:
            self.stream_task.cancel()
    
    async def _stream_data(self):
        """Main data streaming loop."""
        try:
            while self.is_streaming and self.subscribers:
                # Generate sample data
                data = {
                    "stock_prices": {
                        "AAPL": round(150 + random.uniform(-5, 5), 2),
                        "GOOGL": round(2800 + random.uniform(-50, 50), 2),
                        "MSFT": round(300 + random.uniform(-10, 10), 2)
                    },
                    "metrics": {
                        "cpu_usage": round(random.uniform(10, 90), 1),
                        "memory_usage": round(random.uniform(30, 80), 1),
                        "network_traffic": random.randint(100, 1000)
                    },
                    "alerts": {
                        "count": random.randint(0, 5),
                        "severity": random.choice(["low", "medium", "high"])
                    },
                    "timestamp": datetime.now().isoformat()
                }
                
                # Send data to subscribers
                disconnected = []
                for client_id, client_info in self.subscribers.items():
                    try:
                        websocket = client_info["websocket"]
                        data_types = client_info["data_types"]
                        
                        # Filter data based on subscription
                        filtered_data = {
                            data_type: data[data_type]
                            for data_type in data_types
                            if data_type in data
                        }
                        
                        if filtered_data:
                            message = {
                                "type": "data_update",
                                "data": filtered_data,
                                "timestamp": data["timestamp"]
                            }
                            
                            await websocket.send_text(json.dumps(message))
                            client_info["last_update"] = datetime.now()
                    
                    except:
                        disconnected.append(client_id)
                
                # Remove disconnected clients
                for client_id in disconnected:
                    self.unsubscribe(client_id)
                
                await asyncio.sleep(1)  # Update every second
                
        except asyncio.CancelledError:
            pass
    
    def get_subscriber_count(self) -> int:
        """Get number of active subscribers."""
        return len(self.subscribers)

data_streamer = DataStreamer()

@app.websocket("/ws/data/{client_id}")
async def data_stream_websocket(websocket: WebSocket, client_id: str, data_types: str = "stock_prices,metrics"):
    """WebSocket endpoint for real-time data streaming."""
    
    # Parse data types
    subscription_types = [dtype.strip() for dtype in data_types.split(",")]
    
    try:
        await data_streamer.subscribe(client_id, websocket, subscription_types)
        
        # Send initial subscription confirmation
        await websocket.send_text(json.dumps({
            "type": "subscription_confirmed",
            "client_id": client_id,
            "data_types": subscription_types,
            "timestamp": datetime.now().isoformat()
        }))
        
        # Keep connection alive
        while True:
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                message_type = message.get("type")
                
                if message_type == "ping":
                    await websocket.send_text(json.dumps({
                        "type": "pong",
                        "timestamp": datetime.now().isoformat()
                    }))
                
                elif message_type == "update_subscription":
                    # Update subscription types
                    new_types = message.get("data_types", [])
                    if client_id in data_streamer.subscribers:
                        data_streamer.subscribers[client_id]["data_types"] = new_types
                    
                    await websocket.send_text(json.dumps({
                        "type": "subscription_updated",
                        "data_types": new_types
                    }))
                
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))
                
    except WebSocketDisconnect:
        data_streamer.unsubscribe(client_id)

@app.get("/data/subscribers")
async def get_data_subscribers():
    """Get data streaming statistics."""
    return {
        "subscriber_count": data_streamer.get_subscriber_count(),
        "is_streaming": data_streamer.is_streaming,
        "timestamp": datetime.now().isoformat()
    }
```

## Concurrent Processing Patterns

### Task Groups and Parallel Execution
```python
import asyncio
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
from typing import List, Callable, Any

# CPU-bound task example
def cpu_intensive_task(n: int) -> int:
    """Simulate CPU-intensive computation."""
    total = 0
    for i in range(n * 1000000):
        total += i % 1000
    return total

# I/O-bound task example
async def io_intensive_task(url: str) -> Dict[str, Any]:
    """Simulate I/O-intensive operation."""
    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(url, timeout=5) as response:
                return {
                    "url": url,
                    "status": response.status,
                    "content_length": len(await response.text())
                }
        except Exception as e:
            return {"url": url, "error": str(e)}

@app.post("/concurrent/mixed-workload")
async def mixed_workload_processing(
    cpu_tasks: List[int],
    io_urls: List[str]
) -> Dict[str, Any]:
    """Process mixed CPU and I/O bound tasks concurrently."""
    
    # Use thread pool for CPU-bound tasks
    with ThreadPoolExecutor(max_workers=4) as cpu_executor:
        # Use process pool for very CPU-intensive tasks
        with ProcessPoolExecutor(max_workers=2) as process_executor:
            
            # Create tasks
            loop = asyncio.get_event_loop()
            
            # CPU tasks in thread pool
            cpu_futures = [
                loop.run_in_executor(cpu_executor, cpu_intensive_task, task)
                for task in cpu_tasks
            ]
            
            # I/O tasks as coroutines
            io_futures = [
                io_intensive_task(url)
                for url in io_urls
            ]
            
            # Heavy CPU tasks in process pool
            heavy_cpu_futures = [
                loop.run_in_executor(process_executor, cpu_intensive_task, task * 10)
                for task in cpu_tasks[:2]  # Limit to first 2 tasks
            ]
            
            # Wait for all tasks to complete
            cpu_results = await asyncio.gather(*cpu_futures, return_exceptions=True)
            io_results = await asyncio.gather(*io_futures, return_exceptions=True)
            heavy_cpu_results = await asyncio.gather(*heavy_cpu_futures, return_exceptions=True)
            
            return {
                "cpu_results": cpu_results,
                "io_results": io_results,
                "heavy_cpu_results": heavy_cpu_results,
                "total_tasks": len(cpu_tasks) + len(io_urls) + len(heavy_cpu_futures),
                "processing_time": "varies"
            }

# Batch processing with concurrency control
@app.post("/concurrent/batch-process")
async def batch_process_with_concurrency(
    items: List[str],
    max_concurrency: int = 10
) -> Dict[str, Any]:
    """Process batch of items with controlled concurrency."""
    
    async def process_item(item: str) -> Dict[str, Any]:
        """Process individual item."""
        # Simulate processing
        await asyncio.sleep(random.uniform(0.1, 0.5))
        
        return {
            "item": item,
            "processed_at": datetime.now().isoformat(),
            "result": f"processed_{item}_{hash(item) % 1000}"
        }
    
    # Use semaphore to control concurrency
    semaphore = asyncio.Semaphore(max_concurrency)
    
    async def bounded_process_item(item: str) -> Dict[str, Any]:
        async with semaphore:
            return await process_item(item)
    
    # Process all items with controlled concurrency
    start_time = time.time()
    results = await asyncio.gather(*[
        bounded_process_item(item) for item in items
    ], return_exceptions=True)
    
    processing_time = time.time() - start_time
    
    # Separate successful results from errors
    successful = [r for r in results if not isinstance(r, Exception)]
    errors = [str(r) for r in results if isinstance(r, Exception)]
    
    return {
        "total_items": len(items),
        "successful": len(successful),
        "errors": len(errors),
        "results": successful,
        "error_details": errors,
        "processing_time": round(processing_time, 2),
        "max_concurrency": max_concurrency
    }

# Pipeline processing
@app.post("/concurrent/pipeline")
async def pipeline_processing(data: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Process data through a pipeline of async operations."""
    
    async def stage1_validate(item: Dict[str, Any]) -> Dict[str, Any]:
        """Pipeline stage 1: Validation."""
        await asyncio.sleep(0.01)
        if "name" not in item or "value" not in item:
            raise ValueError("Missing required fields")
        return {**item, "stage1_complete": True}
    
    async def stage2_enrich(item: Dict[str, Any]) -> Dict[str, Any]:
        """Pipeline stage 2: Data enrichment."""
        await asyncio.sleep(0.02)
        return {
            **item,
            "enriched_value": item["value"] * 2,
            "stage2_complete": True
        }
    
    async def stage3_transform(item: Dict[str, Any]) -> Dict[str, Any]:
        """Pipeline stage 3: Data transformation."""
        await asyncio.sleep(0.01)
        return {
            **item,
            "transformed": f"PROCESSED_{item['name'].upper()}",
            "stage3_complete": True,
            "processed_at": datetime.now().isoformat()
        }
    
    # Process through pipeline stages
    results = []
    errors = []
    
    for item in data:
        try:
            # Run stages sequentially for each item
            stage1_result = await stage1_validate(item)
            stage2_result = await stage2_enrich(stage1_result)
            stage3_result = await stage3_transform(stage2_result)
            
            results.append(stage3_result)
            
        except Exception as e:
            errors.append({
                "item": item,
                "error": str(e),
                "stage": "validation" if "required fields" in str(e) else "processing"
            })
    
    return {
        "total_items": len(data),
        "successful": len(results),
        "failed": len(errors),
        "results": results,
        "errors": errors
    }
```

## Best Practices

### Performance Optimization
```python
from functools import lru_cache
import aiofiles
from pathlib import Path

# Efficient file streaming
@app.get("/stream/file/{filename}")
async def stream_file_efficiently(filename: str) -> StreamingResponse:
    """Stream file with optimal chunk size."""
    
    file_path = Path(f"/tmp/{filename}")
    
    if not file_path.exists():
        raise HTTPException(404, "File not found")
    
    async def file_streamer():
        async with aiofiles.open(file_path, 'rb') as file:
            chunk_size = 64 * 1024  # 64KB chunks - optimal for most cases
            
            while True:
                chunk = await file.read(chunk_size)
                if not chunk:
                    break
                yield chunk
    
    file_size = file_path.stat().st_size
    
    return StreamingResponse(
        file_streamer(),
        media_type="application/octet-stream",
        headers={
            "Content-Length": str(file_size),
            "Content-Disposition": f"attachment; filename={filename}"
        }
    )

# Connection pooling for external APIs
class AsyncHTTPClient:
    """Singleton HTTP client with connection pooling."""
    
    _instance = None
    _session = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    async def get_session(self) -> aiohttp.ClientSession:
        """Get or create HTTP session with connection pooling."""
        if self._session is None or self._session.closed:
            connector = aiohttp.TCPConnector(
                limit=100,  # Total connection pool size
                limit_per_host=30,  # Per-host connection limit
                ttl_dns_cache=300,  # DNS cache TTL
                use_dns_cache=True,
                keepalive_timeout=60,
                enable_cleanup_closed=True
            )
            
            timeout = aiohttp.ClientTimeout(total=30)
            
            self._session = aiohttp.ClientSession(
                connector=connector,
                timeout=timeout
            )
        
        return self._session
    
    async def close(self):
        """Close HTTP session."""
        if self._session and not self._session.closed:
            await self._session.close()

http_client = AsyncHTTPClient()

# Cleanup on app shutdown
@app.on_event("shutdown")
async def cleanup():
    """Cleanup resources on app shutdown."""
    await http_client.close()

# Memory-efficient data processing
@app.get("/stream/process-large-dataset")
async def process_large_dataset() -> StreamingResponse:
    """Process large dataset with memory efficiency."""
    
    async def process_and_stream():
        # Simulate large dataset processing
        batch_size = 1000
        total_records = 100000
        
        for batch_start in range(0, total_records, batch_size):
            batch_end = min(batch_start + batch_size, total_records)
            
            # Process batch
            batch_results = []
            for i in range(batch_start, batch_end):
                # Simulate processing
                result = {
                    "id": i,
                    "value": i * 2,
                    "processed": True
                }
                batch_results.append(result)
            
            # Yield batch as JSON lines
            for result in batch_results:
                yield json.dumps(result) + "\n"
            
            # Small delay to prevent overwhelming
            await asyncio.sleep(0.01)
    
    return StreamingResponse(
        process_and_stream(),
        media_type="application/x-ndjson"
    )
```

---

**Last Updated:** Based on FastAPI 0.100+ and Python 3.11+ async features
**References:**
- [FastAPI WebSockets](https://fastapi.tiangolo.com/advanced/websockets/)
- [FastAPI Streaming](https://fastapi.tiangolo.com/advanced/custom-response/)
- [AsyncIO Documentation](https://docs.python.org/3/library/asyncio.html)
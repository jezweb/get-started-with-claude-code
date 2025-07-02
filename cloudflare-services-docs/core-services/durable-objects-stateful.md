# Cloudflare Durable Objects - Stateful Computing

## Overview

Durable Objects provide stateful serverless computing at the edge, offering strong consistency and coordination capabilities. Perfect for real-time applications, gaming, collaboration tools, and any use case requiring shared state across multiple connections or requests.

## Quick Start

### Basic Durable Object Setup
```javascript
// Durable Object class
export class Counter {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.value = 0;
  }
  
  async fetch(request) {
    const url = new URL(request.url);
    
    switch (url.pathname) {
      case '/increment':
        this.value++;
        await this.state.storage.put('value', this.value);
        return Response.json({ value: this.value });
        
      case '/get':
        this.value = await this.state.storage.get('value') || 0;
        return Response.json({ value: this.value });
        
      case '/reset':
        this.value = 0;
        await this.state.storage.put('value', 0);
        return Response.json({ value: this.value });
    }
    
    return new Response('Not found', { status: 404 });
  }
}

// Worker that uses the Durable Object
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const counterId = url.searchParams.get('id') || 'global';
    
    // Get Durable Object instance
    const id = env.COUNTER.idFromName(counterId);
    const counter = env.COUNTER.get(id);
    
    // Forward request to Durable Object
    return counter.fetch(request);
  }
};
```

### Configuration
```toml
# wrangler.toml
name = "durable-objects-app"
main = "src/index.js"

[[durable_objects.bindings]]
name = "COUNTER"
class_name = "Counter"

[[durable_objects.bindings]]
name = "CHAT_ROOM"
class_name = "ChatRoom"

[[durable_objects.bindings]]
name = "GAME_SESSION"
class_name = "GameSession"

[[migrations]]
tag = "v1"
new_classes = ["Counter", "ChatRoom", "GameSession"]
```

## Core Concepts

### State Management
Durable Objects provide persistent storage and in-memory state:

```javascript
export class UserSession {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map(); // In-memory state
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load persistent state
    const persistedSessions = await this.state.storage.get('sessions') || {};
    
    // Restore in-memory state
    for (const [key, value] of Object.entries(persistedSessions)) {
      this.sessions.set(key, value);
    }
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    const url = new URL(request.url);
    const method = request.method;
    
    if (method === 'POST' && url.pathname === '/session') {
      return this.createSession(request);
    }
    
    if (method === 'GET' && url.pathname.startsWith('/session/')) {
      const sessionId = url.pathname.split('/')[2];
      return this.getSession(sessionId);
    }
    
    if (method === 'DELETE' && url.pathname.startsWith('/session/')) {
      const sessionId = url.pathname.split('/')[2];
      return this.deleteSession(sessionId);
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async createSession(request) {
    const { userId, data } = await request.json();
    const sessionId = crypto.randomUUID();
    
    const sessionData = {
      id: sessionId,
      userId,
      data: data || {},
      createdAt: Date.now(),
      lastActivity: Date.now()
    };
    
    // Store in memory
    this.sessions.set(sessionId, sessionData);
    
    // Persist to storage
    await this.persistSessions();
    
    return Response.json(sessionData);
  }
  
  async getSession(sessionId) {
    const session = this.sessions.get(sessionId);
    
    if (!session) {
      return new Response('Session not found', { status: 404 });
    }
    
    // Update last activity
    session.lastActivity = Date.now();
    this.sessions.set(sessionId, session);
    
    // Persist updated activity
    await this.persistSessions();
    
    return Response.json(session);
  }
  
  async deleteSession(sessionId) {
    const deleted = this.sessions.delete(sessionId);
    
    if (deleted) {
      await this.persistSessions();
      return Response.json({ deleted: true });
    }
    
    return new Response('Session not found', { status: 404 });
  }
  
  async persistSessions() {
    const sessionsObject = Object.fromEntries(this.sessions);
    await this.state.storage.put('sessions', sessionsObject);
  }
  
  // Cleanup expired sessions
  async cleanup() {
    const now = Date.now();
    const expiry = 24 * 60 * 60 * 1000; // 24 hours
    let cleaned = false;
    
    for (const [sessionId, session] of this.sessions.entries()) {
      if (now - session.lastActivity > expiry) {
        this.sessions.delete(sessionId);
        cleaned = true;
      }
    }
    
    if (cleaned) {
      await this.persistSessions();
    }
  }
}
```

### WebSocket Handling
```javascript
export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Set();
    this.messages = [];
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load chat history
    this.messages = await this.state.storage.get('messages') || [];
    
    // Set up cleanup alarm
    await this.state.storage.setAlarm(Date.now() + 60000); // 1 minute
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    // Handle WebSocket upgrade
    if (request.headers.get('Upgrade') === 'websocket') {
      return this.handleWebSocket(request);
    }
    
    const url = new URL(request.url);
    
    if (url.pathname === '/messages' && request.method === 'GET') {
      return this.getMessages();
    }
    
    if (url.pathname === '/messages' && request.method === 'POST') {
      return this.postMessage(request);
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async handleWebSocket(request) {
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    
    // Accept the WebSocket connection
    server.accept();
    
    // Add to active sessions
    this.sessions.add(server);
    
    // Send recent messages to new connection
    const recentMessages = this.messages.slice(-10);
    if (recentMessages.length > 0) {
      server.send(JSON.stringify({
        type: 'history',
        messages: recentMessages
      }));
    }
    
    // Handle incoming messages
    server.addEventListener('message', async (event) => {
      try {
        const data = JSON.parse(event.data);
        await this.handleMessage(server, data);
      } catch (error) {
        server.send(JSON.stringify({
          type: 'error',
          message: 'Invalid message format'
        }));
      }
    });
    
    // Handle connection close
    server.addEventListener('close', () => {
      this.sessions.delete(server);
    });
    
    // Handle connection errors
    server.addEventListener('error', () => {
      this.sessions.delete(server);
    });
    
    // Send connection count update
    this.broadcast({
      type: 'user_count',
      count: this.sessions.size
    });
    
    return new Response(null, {
      status: 101,
      webSocket: client
    });
  }
  
  async handleMessage(sender, data) {
    switch (data.type) {
      case 'chat':
        await this.handleChatMessage(sender, data);
        break;
        
      case 'typing':
        this.handleTypingIndicator(sender, data);
        break;
        
      case 'ping':
        sender.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
        break;
    }
  }
  
  async handleChatMessage(sender, data) {
    const message = {
      id: crypto.randomUUID(),
      username: data.username,
      text: data.text,
      timestamp: Date.now(),
      type: 'chat'
    };
    
    // Store message
    this.messages.push(message);
    
    // Keep only last 1000 messages in memory
    if (this.messages.length > 1000) {
      this.messages = this.messages.slice(-1000);
    }
    
    // Persist messages
    await this.state.storage.put('messages', this.messages);
    
    // Broadcast to all connected clients
    this.broadcast(message);
  }
  
  handleTypingIndicator(sender, data) {
    // Don't store typing indicators, just broadcast to others
    this.broadcast({
      type: 'typing',
      username: data.username,
      isTyping: data.isTyping
    }, sender); // Exclude sender
  }
  
  broadcast(message, exclude = null) {
    const messageString = JSON.stringify(message);
    
    for (const session of this.sessions) {
      if (session !== exclude) {
        try {
          session.send(messageString);
        } catch (error) {
          // Remove broken connections
          this.sessions.delete(session);
        }
      }
    }
  }
  
  async getMessages() {
    await this.initialize();
    
    const limit = 50;
    const recentMessages = this.messages.slice(-limit);
    
    return Response.json({
      messages: recentMessages,
      total: this.messages.length
    });
  }
  
  async postMessage(request) {
    const { username, text } = await request.json();
    
    if (!username || !text) {
      return new Response('Username and text required', { status: 400 });
    }
    
    await this.handleChatMessage(null, { username, text });
    
    return Response.json({ success: true });
  }
  
  // Alarm handler for cleanup
  async alarm() {
    // Clean up old messages
    const now = Date.now();
    const maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days
    
    this.messages = this.messages.filter(msg => 
      now - msg.timestamp < maxAge
    );
    
    await this.state.storage.put('messages', this.messages);
    
    // Set next alarm
    await this.state.storage.setAlarm(Date.now() + 60000);
  }
}
```

## Integration Patterns

### 1. Real-time Collaboration

```javascript
// Collaborative document editor
export class DocumentEditor {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.document = { content: '', version: 0 };
    this.collaborators = new Map();
    this.operations = [];
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load document state
    this.document = await this.state.storage.get('document') || { content: '', version: 0 };
    this.operations = await this.state.storage.get('operations') || [];
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    if (request.headers.get('Upgrade') === 'websocket') {
      return this.handleCollaborator(request);
    }
    
    const url = new URL(request.url);
    
    if (url.pathname === '/document' && request.method === 'GET') {
      return Response.json(this.document);
    }
    
    if (url.pathname === '/operations' && request.method === 'POST') {
      return this.applyOperation(request);
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async handleCollaborator(request) {
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    
    server.accept();
    
    const collaboratorId = crypto.randomUUID();
    const collaborator = {
      id: collaboratorId,
      socket: server,
      cursor: { line: 0, column: 0 },
      selection: null,
      lastSeen: Date.now()
    };
    
    this.collaborators.set(collaboratorId, collaborator);
    
    // Send current document state
    server.send(JSON.stringify({
      type: 'document_state',
      document: this.document,
      collaboratorId
    }));
    
    // Send list of current collaborators
    server.send(JSON.stringify({
      type: 'collaborators',
      collaborators: Array.from(this.collaborators.values()).map(c => ({
        id: c.id,
        cursor: c.cursor,
        selection: c.selection
      }))
    }));
    
    server.addEventListener('message', async (event) => {
      try {
        const data = JSON.parse(event.data);
        await this.handleCollaboratorMessage(collaboratorId, data);
      } catch (error) {
        server.send(JSON.stringify({
          type: 'error',
          message: 'Invalid message format'
        }));
      }
    });
    
    server.addEventListener('close', () => {
      this.collaborators.delete(collaboratorId);
      this.broadcastCollaboratorUpdate();
    });
    
    return new Response(null, {
      status: 101,
      webSocket: client
    });
  }
  
  async handleCollaboratorMessage(collaboratorId, data) {
    const collaborator = this.collaborators.get(collaboratorId);
    if (!collaborator) return;
    
    switch (data.type) {
      case 'operation':
        await this.processOperation(collaboratorId, data.operation);
        break;
        
      case 'cursor':
        collaborator.cursor = data.cursor;
        collaborator.selection = data.selection;
        this.broadcastCursorUpdate(collaboratorId);
        break;
        
      case 'ping':
        collaborator.lastSeen = Date.now();
        collaborator.socket.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  }
  
  async processOperation(collaboratorId, operation) {
    // Transform operation based on document version
    const transformedOp = this.transformOperation(operation, this.document.version);
    
    // Apply operation to document
    this.document = this.applyOperationToDocument(this.document, transformedOp);
    this.document.version++;
    
    // Store operation in history
    this.operations.push({
      ...transformedOp,
      collaboratorId,
      timestamp: Date.now(),
      version: this.document.version
    });
    
    // Keep only last 1000 operations
    if (this.operations.length > 1000) {
      this.operations = this.operations.slice(-1000);
    }
    
    // Persist state
    await this.state.storage.put('document', this.document);
    await this.state.storage.put('operations', this.operations);
    
    // Broadcast operation to other collaborators
    this.broadcastOperation(transformedOp, collaboratorId);
  }
  
  transformOperation(operation, currentVersion) {
    // Implement Operational Transformation logic
    // This is a simplified version - real OT is more complex
    
    if (operation.version === currentVersion) {
      return operation; // No transformation needed
    }
    
    // Transform against operations since the operation's version
    const recentOps = this.operations.filter(op => op.version > operation.version);
    
    let transformedOp = { ...operation };
    
    for (const recentOp of recentOps) {
      transformedOp = this.transformAgainstOperation(transformedOp, recentOp);
    }
    
    return transformedOp;
  }
  
  transformAgainstOperation(op1, op2) {
    // Simplified transformation logic
    // In a real implementation, you'd handle all operation types and conflicts
    
    if (op1.type === 'insert' && op2.type === 'insert') {
      if (op2.position <= op1.position) {
        op1.position += op2.content.length;
      }
    } else if (op1.type === 'delete' && op2.type === 'insert') {
      if (op2.position < op1.position) {
        op1.position += op2.content.length;
      }
    } else if (op1.type === 'insert' && op2.type === 'delete') {
      if (op2.position < op1.position) {
        op1.position -= op2.length;
      }
    } else if (op1.type === 'delete' && op2.type === 'delete') {
      if (op2.position < op1.position) {
        op1.position -= op2.length;
      }
    }
    
    return op1;
  }
  
  applyOperationToDocument(document, operation) {
    let content = document.content;
    
    switch (operation.type) {
      case 'insert':
        content = content.slice(0, operation.position) + 
                  operation.content + 
                  content.slice(operation.position);
        break;
        
      case 'delete':
        content = content.slice(0, operation.position) + 
                  content.slice(operation.position + operation.length);
        break;
        
      case 'replace':
        content = content.slice(0, operation.position) + 
                  operation.content + 
                  content.slice(operation.position + operation.length);
        break;
    }
    
    return { ...document, content };
  }
  
  broadcastOperation(operation, excludeCollaboratorId) {
    const message = JSON.stringify({
      type: 'operation',
      operation,
      version: this.document.version
    });
    
    for (const [id, collaborator] of this.collaborators.entries()) {
      if (id !== excludeCollaboratorId) {
        try {
          collaborator.socket.send(message);
        } catch (error) {
          this.collaborators.delete(id);
        }
      }
    }
  }
  
  broadcastCursorUpdate(collaboratorId) {
    const collaborator = this.collaborators.get(collaboratorId);
    if (!collaborator) return;
    
    const message = JSON.stringify({
      type: 'cursor_update',
      collaboratorId,
      cursor: collaborator.cursor,
      selection: collaborator.selection
    });
    
    for (const [id, otherCollaborator] of this.collaborators.entries()) {
      if (id !== collaboratorId) {
        try {
          otherCollaborator.socket.send(message);
        } catch (error) {
          this.collaborators.delete(id);
        }
      }
    }
  }
  
  broadcastCollaboratorUpdate() {
    const collaborators = Array.from(this.collaborators.values()).map(c => ({
      id: c.id,
      cursor: c.cursor,
      selection: c.selection
    }));
    
    const message = JSON.stringify({
      type: 'collaborators',
      collaborators
    });
    
    for (const collaborator of this.collaborators.values()) {
      try {
        collaborator.socket.send(message);
      } catch (error) {
        this.collaborators.delete(collaborator.id);
      }
    }
  }
}
```

### 2. Game Session Management

```javascript
// Real-time multiplayer game session
export class GameSession {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.players = new Map();
    this.gameState = {
      status: 'waiting', // waiting, playing, finished
      board: Array(9).fill(null), // Tic-tac-toe board
      currentPlayer: 'X',
      winner: null,
      moves: []
    };
    this.maxPlayers = 2;
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load game state
    const savedState = await this.state.storage.get('gameState');
    if (savedState) {
      this.gameState = savedState;
    }
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    if (request.headers.get('Upgrade') === 'websocket') {
      return this.handlePlayer(request);
    }
    
    const url = new URL(request.url);
    
    if (url.pathname === '/state' && request.method === 'GET') {
      return Response.json({
        gameState: this.gameState,
        playerCount: this.players.size
      });
    }
    
    if (url.pathname === '/reset' && request.method === 'POST') {
      return this.resetGame();
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async handlePlayer(request) {
    if (this.players.size >= this.maxPlayers && this.gameState.status !== 'finished') {
      return new Response('Game is full', { status: 400 });
    }
    
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    
    server.accept();
    
    const playerId = crypto.randomUUID();
    const playerSymbol = this.players.size === 0 ? 'X' : 'O';
    
    const player = {
      id: playerId,
      socket: server,
      symbol: playerSymbol,
      name: `Player ${playerSymbol}`,
      joinedAt: Date.now()
    };
    
    this.players.set(playerId, player);
    
    // Send initial game state to new player
    server.send(JSON.stringify({
      type: 'game_state',
      gameState: this.gameState,
      playerId,
      playerSymbol
    }));
    
    // Notify all players about new player
    this.broadcast({
      type: 'player_joined',
      player: {
        id: playerId,
        symbol: playerSymbol,
        name: player.name
      },
      playerCount: this.players.size
    });
    
    // Start game if we have enough players
    if (this.players.size === this.maxPlayers && this.gameState.status === 'waiting') {
      await this.startGame();
    }
    
    server.addEventListener('message', async (event) => {
      try {
        const data = JSON.parse(event.data);
        await this.handlePlayerMessage(playerId, data);
      } catch (error) {
        server.send(JSON.stringify({
          type: 'error',
          message: 'Invalid message format'
        }));
      }
    });
    
    server.addEventListener('close', async () => {
      await this.handlePlayerDisconnect(playerId);
    });
    
    return new Response(null, {
      status: 101,
      webSocket: client
    });
  }
  
  async handlePlayerMessage(playerId, data) {
    const player = this.players.get(playerId);
    if (!player) return;
    
    switch (data.type) {
      case 'move':
        await this.handleMove(playerId, data.position);
        break;
        
      case 'chat':
        this.handleChat(playerId, data.message);
        break;
        
      case 'ping':
        player.socket.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  }
  
  async handleMove(playerId, position) {
    const player = this.players.get(playerId);
    if (!player) return;
    
    // Validate move
    if (this.gameState.status !== 'playing') {
      player.socket.send(JSON.stringify({
        type: 'error',
        message: 'Game is not in progress'
      }));
      return;
    }
    
    if (this.gameState.currentPlayer !== player.symbol) {
      player.socket.send(JSON.stringify({
        type: 'error',
        message: 'Not your turn'
      }));
      return;
    }
    
    if (position < 0 || position > 8 || this.gameState.board[position] !== null) {
      player.socket.send(JSON.stringify({
        type: 'error',
        message: 'Invalid move'
      }));
      return;
    }
    
    // Apply move
    this.gameState.board[position] = player.symbol;
    this.gameState.moves.push({
      playerId,
      symbol: player.symbol,
      position,
      timestamp: Date.now()
    });
    
    // Check for winner
    const winner = this.checkWinner();
    if (winner) {
      this.gameState.winner = winner;
      this.gameState.status = 'finished';
    } else if (this.gameState.board.every(cell => cell !== null)) {
      // Draw
      this.gameState.status = 'finished';
      this.gameState.winner = 'draw';
    } else {
      // Switch turns
      this.gameState.currentPlayer = this.gameState.currentPlayer === 'X' ? 'O' : 'X';
    }
    
    // Persist game state
    await this.state.storage.put('gameState', this.gameState);
    
    // Broadcast updated game state
    this.broadcast({
      type: 'move',
      playerId,
      position,
      symbol: player.symbol,
      gameState: this.gameState
    });
  }
  
  checkWinner() {
    const board = this.gameState.board;
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6] // Diagonals
    ];
    
    for (const [a, b, c] of lines) {
      if (board[a] && board[a] === board[b] && board[a] === board[c]) {
        return board[a];
      }
    }
    
    return null;
  }
  
  async startGame() {
    this.gameState.status = 'playing';
    this.gameState.currentPlayer = 'X';
    
    await this.state.storage.put('gameState', this.gameState);
    
    this.broadcast({
      type: 'game_started',
      gameState: this.gameState
    });
  }
  
  async resetGame() {
    this.gameState = {
      status: this.players.size >= 2 ? 'playing' : 'waiting',
      board: Array(9).fill(null),
      currentPlayer: 'X',
      winner: null,
      moves: []
    };
    
    await this.state.storage.put('gameState', this.gameState);
    
    this.broadcast({
      type: 'game_reset',
      gameState: this.gameState
    });
    
    return Response.json({ success: true });
  }
  
  handleChat(playerId, message) {
    const player = this.players.get(playerId);
    if (!player) return;
    
    this.broadcast({
      type: 'chat',
      playerId,
      playerName: player.name,
      message,
      timestamp: Date.now()
    });
  }
  
  async handlePlayerDisconnect(playerId) {
    const player = this.players.get(playerId);
    if (!player) return;
    
    this.players.delete(playerId);
    
    // Notify remaining players
    this.broadcast({
      type: 'player_left',
      playerId,
      playerCount: this.players.size
    });
    
    // Pause game if a player disconnects during play
    if (this.gameState.status === 'playing' && this.players.size < 2) {
      this.gameState.status = 'waiting';
      await this.state.storage.put('gameState', this.gameState);
      
      this.broadcast({
        type: 'game_paused',
        reason: 'Player disconnected'
      });
    }
  }
  
  broadcast(message, exclude = null) {
    const messageString = JSON.stringify(message);
    
    for (const player of this.players.values()) {
      if (player !== exclude) {
        try {
          player.socket.send(messageString);
        } catch (error) {
          this.players.delete(player.id);
        }
      }
    }
  }
}
```

## Advanced Features

### 1. Distributed Coordination

```javascript
// Distributed lock and coordination system
export class CoordinationService {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.locks = new Map();
    this.queues = new Map();
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load persistent locks
    const persistedLocks = await this.state.storage.get('locks') || {};
    for (const [key, lock] of Object.entries(persistedLocks)) {
      if (Date.now() < lock.expiresAt) {
        this.locks.set(key, lock);
      }
    }
    
    // Set up cleanup alarm
    await this.state.storage.setAlarm(Date.now() + 30000); // 30 seconds
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    const url = new URL(request.url);
    const method = request.method;
    
    if (method === 'POST' && url.pathname === '/lock') {
      return this.acquireLock(request);
    }
    
    if (method === 'DELETE' && url.pathname.startsWith('/lock/')) {
      const lockKey = url.pathname.split('/')[2];
      return this.releaseLock(lockKey, request);
    }
    
    if (method === 'GET' && url.pathname === '/locks') {
      return this.listLocks();
    }
    
    if (method === 'POST' && url.pathname === '/queue') {
      return this.enqueue(request);
    }
    
    if (method === 'GET' && url.pathname.startsWith('/queue/')) {
      const queueName = url.pathname.split('/')[2];
      return this.dequeue(queueName);
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async acquireLock(request) {
    const { key, ttl = 30000, ownerId } = await request.json();
    
    if (!key || !ownerId) {
      return new Response('Key and ownerId required', { status: 400 });
    }
    
    const existingLock = this.locks.get(key);
    
    // Check if lock is available
    if (existingLock && Date.now() < existingLock.expiresAt) {
      if (existingLock.ownerId === ownerId) {
        // Extend existing lock
        existingLock.expiresAt = Date.now() + ttl;
        await this.persistLocks();
        
        return Response.json({
          acquired: true,
          lockId: existingLock.lockId,
          expiresAt: existingLock.expiresAt,
          extended: true
        });
      } else {
        // Lock is held by someone else
        return Response.json({
          acquired: false,
          heldBy: existingLock.ownerId,
          expiresAt: existingLock.expiresAt
        });
      }
    }
    
    // Acquire new lock
    const lock = {
      lockId: crypto.randomUUID(),
      key,
      ownerId,
      acquiredAt: Date.now(),
      expiresAt: Date.now() + ttl
    };
    
    this.locks.set(key, lock);
    await this.persistLocks();
    
    return Response.json({
      acquired: true,
      lockId: lock.lockId,
      expiresAt: lock.expiresAt
    });
  }
  
  async releaseLock(lockKey, request) {
    const { ownerId } = await request.json();
    
    const lock = this.locks.get(lockKey);
    
    if (!lock) {
      return new Response('Lock not found', { status: 404 });
    }
    
    if (lock.ownerId !== ownerId) {
      return new Response('Not lock owner', { status: 403 });
    }
    
    this.locks.delete(lockKey);
    await this.persistLocks();
    
    return Response.json({ released: true });
  }
  
  async listLocks() {
    const now = Date.now();
    const activeLocks = [];
    
    for (const [key, lock] of this.locks.entries()) {
      if (now < lock.expiresAt) {
        activeLocks.push({
          key,
          ownerId: lock.ownerId,
          acquiredAt: lock.acquiredAt,
          expiresAt: lock.expiresAt,
          remainingTtl: lock.expiresAt - now
        });
      }
    }
    
    return Response.json({ locks: activeLocks });
  }
  
  async enqueue(request) {
    const { queueName, item, priority = 0 } = await request.json();
    
    if (!queueName || !item) {
      return new Response('Queue name and item required', { status: 400 });
    }
    
    let queue = this.queues.get(queueName);
    if (!queue) {
      queue = [];
      this.queues.set(queueName, queue);
    }
    
    const queueItem = {
      id: crypto.randomUUID(),
      item,
      priority,
      enqueuedAt: Date.now()
    };
    
    // Insert item based on priority (higher priority first)
    let inserted = false;
    for (let i = 0; i < queue.length; i++) {
      if (priority > queue[i].priority) {
        queue.splice(i, 0, queueItem);
        inserted = true;
        break;
      }
    }
    
    if (!inserted) {
      queue.push(queueItem);
    }
    
    await this.persistQueues();
    
    return Response.json({
      itemId: queueItem.id,
      position: queue.indexOf(queueItem),
      queueLength: queue.length
    });
  }
  
  async dequeue(queueName) {
    const queue = this.queues.get(queueName);
    
    if (!queue || queue.length === 0) {
      return Response.json({ item: null, empty: true });
    }
    
    const item = queue.shift();
    
    if (queue.length === 0) {
      this.queues.delete(queueName);
    }
    
    await this.persistQueues();
    
    return Response.json({
      item: item.item,
      itemId: item.id,
      waitTime: Date.now() - item.enqueuedAt,
      remainingItems: queue.length
    });
  }
  
  async persistLocks() {
    const locksObject = Object.fromEntries(this.locks);
    await this.state.storage.put('locks', locksObject);
  }
  
  async persistQueues() {
    const queuesObject = Object.fromEntries(this.queues);
    await this.state.storage.put('queues', queuesObject);
  }
  
  // Cleanup expired locks
  async alarm() {
    const now = Date.now();
    let cleaned = false;
    
    for (const [key, lock] of this.locks.entries()) {
      if (now >= lock.expiresAt) {
        this.locks.delete(key);
        cleaned = true;
      }
    }
    
    if (cleaned) {
      await this.persistLocks();
    }
    
    // Set next alarm
    await this.state.storage.setAlarm(Date.now() + 30000);
  }
}
```

### 2. Event Sourcing and CQRS

```javascript
// Event sourcing pattern with Durable Objects
export class EventStore {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.events = [];
    this.snapshots = new Map();
    this.projections = new Map();
    this.version = 0;
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load events
    this.events = await this.state.storage.get('events') || [];
    this.version = await this.state.storage.get('version') || 0;
    
    // Load snapshots
    const snapshots = await this.state.storage.get('snapshots') || {};
    this.snapshots = new Map(Object.entries(snapshots));
    
    // Rebuild projections from events
    await this.rebuildProjections();
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    const url = new URL(request.url);
    const method = request.method;
    
    if (method === 'POST' && url.pathname === '/events') {
      return this.appendEvent(request);
    }
    
    if (method === 'GET' && url.pathname === '/events') {
      return this.getEvents(request);
    }
    
    if (method === 'GET' && url.pathname.startsWith('/projection/')) {
      const projectionName = url.pathname.split('/')[2];
      return this.getProjection(projectionName);
    }
    
    if (method === 'POST' && url.pathname === '/snapshot') {
      return this.createSnapshot(request);
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async appendEvent(request) {
    const { eventType, data, expectedVersion } = await request.json();
    
    // Optimistic concurrency check
    if (expectedVersion !== undefined && expectedVersion !== this.version) {
      return new Response('Concurrency conflict', { status: 409 });
    }
    
    const event = {
      id: crypto.randomUUID(),
      type: eventType,
      data,
      version: this.version + 1,
      timestamp: Date.now(),
      metadata: {
        correlationId: crypto.randomUUID(),
        causationId: null // Could be set from request
      }
    };
    
    // Append event
    this.events.push(event);
    this.version++;
    
    // Persist events
    await this.state.storage.put('events', this.events);
    await this.state.storage.put('version', this.version);
    
    // Update projections
    await this.updateProjections(event);
    
    return Response.json({
      eventId: event.id,
      version: this.version,
      timestamp: event.timestamp
    });
  }
  
  async getEvents(request) {
    const url = new URL(request.url);
    const fromVersion = parseInt(url.searchParams.get('from') || '0');
    const toVersion = parseInt(url.searchParams.get('to') || this.version.toString());
    const eventType = url.searchParams.get('type');
    
    let filteredEvents = this.events.filter(event => 
      event.version >= fromVersion && event.version <= toVersion
    );
    
    if (eventType) {
      filteredEvents = filteredEvents.filter(event => event.type === eventType);
    }
    
    return Response.json({
      events: filteredEvents,
      totalEvents: filteredEvents.length,
      currentVersion: this.version
    });
  }
  
  async getProjection(projectionName) {
    const projection = this.projections.get(projectionName);
    
    if (!projection) {
      return new Response('Projection not found', { status: 404 });
    }
    
    return Response.json({
      projection: projectionName,
      data: projection.data,
      lastEventVersion: projection.lastEventVersion,
      updatedAt: projection.updatedAt
    });
  }
  
  async createSnapshot(request) {
    const { projectionName } = await request.json();
    
    const projection = this.projections.get(projectionName);
    if (!projection) {
      return new Response('Projection not found', { status: 404 });
    }
    
    const snapshot = {
      projectionName,
      data: projection.data,
      version: projection.lastEventVersion,
      createdAt: Date.now()
    };
    
    this.snapshots.set(projectionName, snapshot);
    
    // Persist snapshots
    const snapshotsObject = Object.fromEntries(this.snapshots);
    await this.state.storage.put('snapshots', snapshotsObject);
    
    return Response.json({
      snapshotCreated: true,
      version: snapshot.version
    });
  }
  
  async rebuildProjections() {
    // Initialize projection handlers
    const projectionHandlers = {
      'user_summary': this.buildUserSummaryProjection.bind(this),
      'order_totals': this.buildOrderTotalsProjection.bind(this),
      'activity_log': this.buildActivityLogProjection.bind(this)
    };
    
    // Rebuild each projection
    for (const [name, handler] of Object.entries(projectionHandlers)) {
      await this.rebuildProjection(name, handler);
    }
  }
  
  async rebuildProjection(projectionName, handler) {
    // Check for existing snapshot
    const snapshot = this.snapshots.get(projectionName);
    let data = {};
    let startVersion = 0;
    
    if (snapshot) {
      data = snapshot.data;
      startVersion = snapshot.version;
    }
    
    // Apply events since snapshot
    const eventsToApply = this.events.filter(event => event.version > startVersion);
    
    for (const event of eventsToApply) {
      data = handler(data, event);
    }
    
    // Store projection
    this.projections.set(projectionName, {
      data,
      lastEventVersion: this.version,
      updatedAt: Date.now()
    });
  }
  
  async updateProjections(event) {
    // Update user summary projection
    if (this.projections.has('user_summary')) {
      const projection = this.projections.get('user_summary');
      projection.data = this.buildUserSummaryProjection(projection.data, event);
      projection.lastEventVersion = event.version;
      projection.updatedAt = Date.now();
    }
    
    // Update order totals projection
    if (this.projections.has('order_totals')) {
      const projection = this.projections.get('order_totals');
      projection.data = this.buildOrderTotalsProjection(projection.data, event);
      projection.lastEventVersion = event.version;
      projection.updatedAt = Date.now();
    }
    
    // Update activity log projection
    if (this.projections.has('activity_log')) {
      const projection = this.projections.get('activity_log');
      projection.data = this.buildActivityLogProjection(projection.data, event);
      projection.lastEventVersion = event.version;
      projection.updatedAt = Date.now();
    }
  }
  
  buildUserSummaryProjection(currentData, event) {
    const data = { ...currentData };
    
    switch (event.type) {
      case 'UserCreated':
        data[event.data.userId] = {
          userId: event.data.userId,
          email: event.data.email,
          createdAt: event.timestamp,
          orderCount: 0,
          totalSpent: 0
        };
        break;
        
      case 'OrderCompleted':
        if (data[event.data.userId]) {
          data[event.data.userId].orderCount++;
          data[event.data.userId].totalSpent += event.data.total;
        }
        break;
        
      case 'UserDeleted':
        delete data[event.data.userId];
        break;
    }
    
    return data;
  }
  
  buildOrderTotalsProjection(currentData, event) {
    const data = { ...currentData };
    
    if (!data.daily) data.daily = {};
    if (!data.monthly) data.monthly = {};
    
    switch (event.type) {
      case 'OrderCompleted':
        const date = new Date(event.timestamp);
        const dayKey = date.toISOString().split('T')[0];
        const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        
        // Daily totals
        if (!data.daily[dayKey]) {
          data.daily[dayKey] = { count: 0, total: 0 };
        }
        data.daily[dayKey].count++;
        data.daily[dayKey].total += event.data.total;
        
        // Monthly totals
        if (!data.monthly[monthKey]) {
          data.monthly[monthKey] = { count: 0, total: 0 };
        }
        data.monthly[monthKey].count++;
        data.monthly[monthKey].total += event.data.total;
        break;
    }
    
    return data;
  }
  
  buildActivityLogProjection(currentData, event) {
    const data = { ...currentData };
    
    if (!data.activities) data.activities = [];
    
    // Add activity entry for all events
    data.activities.push({
      eventId: event.id,
      type: event.type,
      timestamp: event.timestamp,
      summary: this.generateActivitySummary(event)
    });
    
    // Keep only last 1000 activities
    if (data.activities.length > 1000) {
      data.activities = data.activities.slice(-1000);
    }
    
    return data;
  }
  
  generateActivitySummary(event) {
    switch (event.type) {
      case 'UserCreated':
        return `User ${event.data.email} created`;
      case 'OrderCompleted':
        return `Order completed for $${event.data.total}`;
      case 'UserDeleted':
        return `User ${event.data.userId} deleted`;
      default:
        return `${event.type} event occurred`;
    }
  }
}
```

## Performance Optimization

### WebSocket Connection Management
- Pool connections efficiently
- Implement heartbeat/ping-pong for connection health
- Handle reconnection logic gracefully
- Use connection state management

### State Management
- Implement smart caching strategies
- Use alarms for cleanup operations
- Optimize storage operations with batching
- Consider memory vs. storage trade-offs

### Scaling Considerations
- Design for single-object constraints
- Implement sharding strategies when needed
- Use multiple objects for high-throughput scenarios
- Consider object lifecycle management

## Best Practices

### Code Organization
- Separate concerns within objects
- Implement proper error handling
- Use TypeScript for better type safety
- Document object interfaces clearly

### State Management
- Design for strong consistency requirements
- Implement proper cleanup mechanisms
- Use alarms for scheduled operations
- Handle edge cases gracefully

### Security
- Validate all inputs
- Implement proper authorization
- Use secure WebSocket practices
- Protect against state corruption

### Monitoring
- Log important state changes
- Monitor object performance
- Track connection counts
- Set up alerting for errors

## Common Use Cases

1. **Real-time Chat** - Multi-user messaging and presence
2. **Collaborative Editing** - Document collaboration with conflict resolution
3. **Gaming** - Multiplayer game state management
4. **IoT Coordination** - Device state and command coordination
5. **Distributed Locks** - Resource coordination across services
6. **Event Sourcing** - Audit trails and event-driven architectures

Durable Objects provide the missing piece for stateful applications at the edge, enabling real-time, consistent, and coordinated experiences that scale globally while maintaining strong consistency guarantees.
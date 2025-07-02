# Cloudflare Workers - Serverless Compute

## Overview

Cloudflare Workers provide serverless compute that runs on Cloudflare's global edge network, offering ultra-low latency and high performance for web applications. Workers support multiple programming languages and integrate seamlessly with other Cloudflare services.

## Quick Start

### Basic Worker Setup
```javascript
// Hello World Worker
export default {
  async fetch(request, env, ctx) {
    return new Response('Hello from Cloudflare Workers!');
  }
};
```

### Configuration
```toml
# wrangler.toml
name = "my-worker"
main = "src/index.js"
compatibility_date = "2024-07-01"

[env.production]
vars = { ENV = "production" }

[[env.production.kv_namespaces]]
binding = "MY_KV"
id = "your-kv-namespace-id"
```

## Core Concepts

### Runtime APIs
Workers provide standard web APIs plus Cloudflare-specific APIs:

```javascript
export default {
  async fetch(request, env, ctx) {
    // Standard Web APIs
    const url = new URL(request.url);
    const userAgent = request.headers.get('User-Agent');
    
    // Cloudflare-specific APIs
    const country = request.cf.country;
    const datacenter = request.cf.colo;
    
    return Response.json({
      path: url.pathname,
      userAgent,
      country,
      datacenter,
      timestamp: Date.now(),
    });
  }
};
```

### Request/Response Handling
```javascript
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Route handling
    switch (url.pathname) {
      case '/api/users':
        return handleUsers(request, env);
      case '/api/upload':
        return handleUpload(request, env);
      case '/health':
        return new Response('OK', { status: 200 });
      default:
        return new Response('Not Found', { status: 404 });
    }
  }
};

async function handleUsers(request, env) {
  if (request.method === 'GET') {
    // Get users from KV or database
    const users = await env.USERS_KV.get('users', 'json') || [];
    return Response.json(users);
  }
  
  if (request.method === 'POST') {
    // Create new user
    const newUser = await request.json();
    
    // Validate user data
    if (!newUser.email || !newUser.name) {
      return new Response('Invalid user data', { status: 400 });
    }
    
    // Save to KV
    const users = await env.USERS_KV.get('users', 'json') || [];
    const user = {
      id: crypto.randomUUID(),
      ...newUser,
      createdAt: new Date().toISOString(),
    };
    
    users.push(user);
    await env.USERS_KV.put('users', JSON.stringify(users));
    
    return Response.json(user, { status: 201 });
  }
  
  return new Response('Method not allowed', { status: 405 });
}
```

## Integration Patterns

### 1. API Gateway Pattern

```javascript
// Comprehensive API gateway with authentication and routing
export default {
  async fetch(request, env, ctx) {
    try {
      // CORS handling
      if (request.method === 'OPTIONS') {
        return handleCORS();
      }
      
      // Rate limiting
      const rateLimitResult = await checkRateLimit(request, env);
      if (!rateLimitResult.allowed) {
        return new Response('Rate limit exceeded', { 
          status: 429,
          headers: {
            'Retry-After': rateLimitResult.retryAfter.toString(),
          },
        });
      }
      
      // Authentication
      const authResult = await authenticate(request, env);
      if (!authResult.success && requiresAuth(request)) {
        return new Response('Unauthorized', { status: 401 });
      }
      
      // Route to appropriate handler
      const response = await routeRequest(request, env, authResult.user);
      
      // Add CORS headers to response
      return addCORSHeaders(response);
      
    } catch (error) {
      console.error('Worker error:', error);
      return new Response('Internal Server Error', { status: 500 });
    }
  }
};

async function checkRateLimit(request, env) {
  const clientIP = request.headers.get('CF-Connecting-IP');
  const key = `rate_limit:${clientIP}`;
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 minute
  const maxRequests = 100;
  
  const current = await env.RATE_LIMIT_KV.get(key, 'json') || { count: 0, resetTime: now + windowMs };
  
  if (now > current.resetTime) {
    // Reset window
    current.count = 1;
    current.resetTime = now + windowMs;
  } else {
    current.count++;
  }
  
  await env.RATE_LIMIT_KV.put(key, JSON.stringify(current), {
    expirationTtl: Math.ceil((current.resetTime - now) / 1000),
  });
  
  return {
    allowed: current.count <= maxRequests,
    retryAfter: Math.ceil((current.resetTime - now) / 1000),
  };
}

async function authenticate(request, env) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { success: false };
  }
  
  const token = authHeader.slice(7);
  
  try {
    // Validate JWT token
    const payload = await verifyJWT(token, env.JWT_SECRET);
    return { success: true, user: payload };
  } catch {
    return { success: false };
  }
}

function requiresAuth(request) {
  const url = new URL(request.url);
  const publicPaths = ['/health', '/public'];
  return !publicPaths.some(path => url.pathname.startsWith(path));
}

async function routeRequest(request, env, user) {
  const url = new URL(request.url);
  
  // API routes
  if (url.pathname.startsWith('/api/')) {
    return handleAPI(request, env, user);
  }
  
  // Static file serving
  if (url.pathname.startsWith('/static/')) {
    return handleStaticFiles(request, env);
  }
  
  // Default response
  return new Response('Not Found', { status: 404 });
}

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
    },
  });
}

function addCORSHeaders(response) {
  const newResponse = new Response(response.body, response);
  newResponse.headers.set('Access-Control-Allow-Origin', '*');
  return newResponse;
}
```

### 2. Database Integration

```javascript
// Workers with database connectivity
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    if (url.pathname === '/api/posts' && request.method === 'GET') {
      return handleGetPosts(request, env);
    }
    
    if (url.pathname === '/api/posts' && request.method === 'POST') {
      return handleCreatePost(request, env);
    }
    
    return new Response('Not Found', { status: 404 });
  }
};

async function handleGetPosts(request, env) {
  const url = new URL(request.url);
  const page = parseInt(url.searchParams.get('page') || '1');
  const limit = parseInt(url.searchParams.get('limit') || '10');
  const offset = (page - 1) * limit;
  
  try {
    // Using D1 database
    const { results } = await env.DB.prepare(`
      SELECT id, title, content, author, created_at 
      FROM posts 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `).bind(limit, offset).all();
    
    const { results: [{ count }] } = await env.DB.prepare(
      'SELECT COUNT(*) as count FROM posts'
    ).all();
    
    return Response.json({
      posts: results,
      pagination: {
        page,
        limit,
        total: count,
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Database error:', error);
    return new Response('Database error', { status: 500 });
  }
}

async function handleCreatePost(request, env) {
  try {
    const postData = await request.json();
    
    // Validation
    if (!postData.title || !postData.content) {
      return new Response('Title and content are required', { status: 400 });
    }
    
    // Insert into database
    const { success, meta } = await env.DB.prepare(`
      INSERT INTO posts (title, content, author, created_at)
      VALUES (?, ?, ?, ?)
    `).bind(
      postData.title,
      postData.content,
      postData.author || 'Anonymous',
      new Date().toISOString()
    ).run();
    
    if (success) {
      return Response.json({
        id: meta.last_row_id,
        message: 'Post created successfully',
      }, { status: 201 });
    } else {
      return new Response('Failed to create post', { status: 500 });
    }
  } catch (error) {
    console.error('Error creating post:', error);
    return new Response('Invalid request data', { status: 400 });
  }
}
```

### 3. External API Integration

```javascript
// Workers as middleware for external APIs
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    if (url.pathname.startsWith('/proxy/')) {
      return handleProxy(request, env);
    }
    
    if (url.pathname === '/weather') {
      return handleWeather(request, env);
    }
    
    return new Response('Not Found', { status: 404 });
  }
};

async function handleProxy(request, env) {
  const url = new URL(request.url);
  const targetPath = url.pathname.slice(7); // Remove '/proxy/'
  const targetURL = `https://api.example.com${targetPath}${url.search}`;
  
  // Clone request for forwarding
  const proxyRequest = new Request(targetURL, {
    method: request.method,
    headers: {
      ...Object.fromEntries(request.headers),
      'Authorization': `Bearer ${env.API_KEY}`,
      'User-Agent': 'CloudflareWorker/1.0',
    },
    body: request.body,
  });
  
  try {
    const response = await fetch(proxyRequest);
    
    // Transform response if needed
    if (response.headers.get('content-type')?.includes('application/json')) {
      const data = await response.json();
      
      // Add metadata
      data._metadata = {
        timestamp: Date.now(),
        worker_id: env.WORKER_ID,
        cf_ray: request.headers.get('CF-Ray'),
      };
      
      return Response.json(data, {
        status: response.status,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=300',
        },
      });
    }
    
    return response;
  } catch (error) {
    console.error('Proxy error:', error);
    return new Response('Gateway error', { status: 502 });
  }
}

async function handleWeather(request, env) {
  const url = new URL(request.url);
  const city = url.searchParams.get('city') || 'London';
  
  // Check cache first
  const cacheKey = `weather:${city.toLowerCase()}`;
  const cached = await env.CACHE_KV.get(cacheKey, 'json');
  
  if (cached && Date.now() - cached.timestamp < 300000) { // 5 minutes
    return Response.json(cached.data);
  }
  
  try {
    // Fetch from weather API
    const weatherResponse = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${env.WEATHER_API_KEY}&units=metric`
    );
    
    if (!weatherResponse.ok) {
      return new Response('Weather data not found', { status: 404 });
    }
    
    const weatherData = await weatherResponse.json();
    
    // Transform and cache data
    const transformedData = {
      city: weatherData.name,
      country: weatherData.sys.country,
      temperature: weatherData.main.temp,
      description: weatherData.weather[0].description,
      humidity: weatherData.main.humidity,
      windSpeed: weatherData.wind.speed,
    };
    
    // Cache for 5 minutes
    await env.CACHE_KV.put(cacheKey, JSON.stringify({
      data: transformedData,
      timestamp: Date.now(),
    }), { expirationTtl: 300 });
    
    return Response.json(transformedData);
  } catch (error) {
    console.error('Weather API error:', error);
    return new Response('Weather service unavailable', { status: 503 });
  }
}
```

## Advanced Features

### 1. Scheduled Events (Cron Jobs)

```javascript
// Scheduled tasks for maintenance and automation
export default {
  async fetch(request, env, ctx) {
    // Handle HTTP requests
    return new Response('Worker is running');
  },
  
  async scheduled(event, env, ctx) {
    // Handle scheduled events
    switch (event.cron) {
      case '0 0 * * *': // Daily at midnight
        await performDailyMaintenance(env);
        break;
      case '*/5 * * * *': // Every 5 minutes
        await performHealthCheck(env);
        break;
      case '0 */6 * * *': // Every 6 hours
        await cleanupExpiredData(env);
        break;
    }
  }
};

async function performDailyMaintenance(env) {
  console.log('Starting daily maintenance...');
  
  // Clean up old cache entries
  const keys = await env.CACHE_KV.list();
  const now = Date.now();
  
  for (const key of keys.keys) {
    const value = await env.CACHE_KV.get(key.name, 'json');
    if (value && value.expires && now > value.expires) {
      await env.CACHE_KV.delete(key.name);
    }
  }
  
  // Send daily report
  await sendDailyReport(env);
  
  console.log('Daily maintenance completed');
}

async function performHealthCheck(env) {
  const services = [
    { name: 'Database', url: env.DB_HEALTH_URL },
    { name: 'External API', url: env.API_HEALTH_URL },
  ];
  
  for (const service of services) {
    try {
      const response = await fetch(service.url, { 
        method: 'HEAD',
        timeout: 5000,
      });
      
      const status = response.ok ? 'healthy' : 'unhealthy';
      await env.METRICS_KV.put(
        `health:${service.name.toLowerCase()}`,
        JSON.stringify({
          status,
          timestamp: Date.now(),
          responseTime: Date.now() - startTime,
        })
      );
    } catch (error) {
      await env.METRICS_KV.put(
        `health:${service.name.toLowerCase()}`,
        JSON.stringify({
          status: 'unhealthy',
          error: error.message,
          timestamp: Date.now(),
        })
      );
    }
  }
}
```

### 2. WebSocket Handling

```javascript
// WebSocket server with Durable Objects
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    if (url.pathname === '/ws') {
      const upgradeHeader = request.headers.get('Upgrade');
      if (upgradeHeader !== 'websocket') {
        return new Response('Expected websocket', { status: 400 });
      }
      
      // Get room ID from query params
      const roomId = url.searchParams.get('room') || 'general';
      
      // Get Durable Object for this room
      const durableObjectId = env.CHAT_ROOM.idFromName(roomId);
      const durableObject = env.CHAT_ROOM.get(durableObjectId);
      
      // Forward WebSocket connection to Durable Object
      return durableObject.fetch(request);
    }
    
    return new Response('Not Found', { status: 404 });
  }
};

// Durable Object class for WebSocket chat room
export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Set();
  }
  
  async fetch(request) {
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    
    // Accept WebSocket connection
    server.accept();
    
    // Add to sessions
    this.sessions.add(server);
    
    // Handle messages
    server.addEventListener('message', async (event) => {
      try {
        const message = JSON.parse(event.data);
        await this.handleMessage(server, message);
      } catch (error) {
        server.send(JSON.stringify({ error: 'Invalid message format' }));
      }
    });
    
    // Handle close
    server.addEventListener('close', () => {
      this.sessions.delete(server);
    });
    
    // Send welcome message
    server.send(JSON.stringify({
      type: 'welcome',
      message: 'Connected to chat room',
      userCount: this.sessions.size,
    }));
    
    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }
  
  async handleMessage(sender, message) {
    switch (message.type) {
      case 'chat':
        await this.broadcastMessage({
          type: 'chat',
          username: message.username,
          text: message.text,
          timestamp: Date.now(),
        }, sender);
        break;
        
      case 'typing':
        await this.broadcastMessage({
          type: 'typing',
          username: message.username,
          isTyping: message.isTyping,
        }, sender);
        break;
    }
  }
  
  async broadcastMessage(message, sender) {
    const messageString = JSON.stringify(message);
    
    // Send to all connected clients except sender
    for (const session of this.sessions) {
      if (session !== sender) {
        try {
          session.send(messageString);
        } catch (error) {
          // Remove broken connections
          this.sessions.delete(session);
        }
      }
    }
  }
}
```

### 3. Streaming Responses

```javascript
// Streaming large datasets efficiently
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    if (url.pathname === '/stream/logs') {
      return streamLogs(request, env);
    }
    
    if (url.pathname === '/stream/csv') {
      return streamCSV(request, env);
    }
    
    return new Response('Not Found', { status: 404 });
  }
};

async function streamLogs(request, env) {
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  
  // Start streaming in background
  (async () => {
    try {
      // Get logs from database in batches
      let offset = 0;
      const limit = 1000;
      
      while (true) {
        const { results } = await env.DB.prepare(`
          SELECT timestamp, level, message 
          FROM logs 
          ORDER BY timestamp DESC 
          LIMIT ? OFFSET ?
        `).bind(limit, offset).all();
        
        if (results.length === 0) break;
        
        for (const log of results) {
          const logLine = `${log.timestamp} [${log.level}] ${log.message}\n`;
          await writer.write(new TextEncoder().encode(logLine));
        }
        
        offset += limit;
        
        // Prevent infinite loops
        if (offset > 100000) break;
      }
    } finally {
      await writer.close();
    }
  })();
  
  return new Response(readable, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'no-cache',
    },
  });
}

async function streamCSV(request, env) {
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  
  // CSV streaming
  (async () => {
    try {
      // Write CSV header
      await writer.write(new TextEncoder().encode('id,name,email,created_at\n'));
      
      // Stream data in batches
      let offset = 0;
      const limit = 1000;
      
      while (true) {
        const { results } = await env.DB.prepare(`
          SELECT id, name, email, created_at 
          FROM users 
          ORDER BY id 
          LIMIT ? OFFSET ?
        `).bind(limit, offset).all();
        
        if (results.length === 0) break;
        
        for (const user of results) {
          const csvRow = `${user.id},"${user.name}","${user.email}","${user.created_at}"\n`;
          await writer.write(new TextEncoder().encode(csvRow));
        }
        
        offset += limit;
      }
    } finally {
      await writer.close();
    }
  })();
  
  return new Response(readable, {
    headers: {
      'Content-Type': 'text/csv',
      'Content-Disposition': 'attachment; filename="users.csv"',
    },
  });
}
```

## Performance Optimization

### 1. Response Caching

```javascript
// Intelligent response caching
export default {
  async fetch(request, env, ctx) {
    const cache = caches.default;
    const cacheKey = new Request(request.url, request);
    
    // Try cache first
    let response = await cache.match(cacheKey);
    if (response) {
      // Add cache hit header
      response = new Response(response.body, response);
      response.headers.set('X-Cache', 'HIT');
      return response;
    }
    
    // Generate response
    response = await generateResponse(request, env);
    
    // Cache if cacheable
    if (isCacheable(request, response)) {
      // Clone response for caching
      const responseToCache = response.clone();
      responseToCache.headers.set('X-Cache', 'MISS');
      responseToCache.headers.set('Cache-Control', 'public, max-age=3600');
      
      // Cache in background
      ctx.waitUntil(cache.put(cacheKey, responseToCache));
    }
    
    response.headers.set('X-Cache', 'MISS');
    return response;
  }
};

function isCacheable(request, response) {
  // Only cache GET requests
  if (request.method !== 'GET') return false;
  
  // Only cache successful responses
  if (response.status < 200 || response.status >= 300) return false;
  
  // Don't cache private content
  const cacheControl = response.headers.get('Cache-Control');
  if (cacheControl && cacheControl.includes('private')) return false;
  
  return true;
}
```

### 2. Connection Pooling

```javascript
// Efficient external API connections
class ConnectionPool {
  constructor(maxConnections = 10) {
    this.maxConnections = maxConnections;
    this.activeConnections = 0;
    this.waitingQueue = [];
  }
  
  async acquire() {
    if (this.activeConnections < this.maxConnections) {
      this.activeConnections++;
      return new PooledConnection(this);
    }
    
    // Wait for available connection
    return new Promise((resolve) => {
      this.waitingQueue.push(resolve);
    });
  }
  
  release() {
    this.activeConnections--;
    
    if (this.waitingQueue.length > 0) {
      const resolve = this.waitingQueue.shift();
      this.activeConnections++;
      resolve(new PooledConnection(this));
    }
  }
}

class PooledConnection {
  constructor(pool) {
    this.pool = pool;
    this.released = false;
  }
  
  async fetch(url, options) {
    if (this.released) {
      throw new Error('Connection already released');
    }
    
    try {
      return await fetch(url, options);
    } finally {
      this.release();
    }
  }
  
  release() {
    if (!this.released) {
      this.released = true;
      this.pool.release();
    }
  }
}

// Global connection pool
const pool = new ConnectionPool(20);

export default {
  async fetch(request, env, ctx) {
    const connection = await pool.acquire();
    
    try {
      const response = await connection.fetch('https://api.example.com/data');
      return response;
    } catch (error) {
      return new Response('Service unavailable', { status: 503 });
    }
  }
};
```

## Testing Strategies

### 1. Unit Testing

```javascript
// Unit tests for Worker functions
import { describe, test, expect, beforeEach } from 'vitest';
import { unstable_dev } from 'wrangler';

describe('Worker Functions', () => {
  let worker;
  
  beforeEach(async () => {
    worker = await unstable_dev('src/index.js', {
      experimental: { disableExperimentalWarning: true },
    });
  });
  
  afterEach(async () => {
    await worker.stop();
  });
  
  test('should handle GET request', async () => {
    const response = await worker.fetch('/api/health');
    expect(response.status).toBe(200);
    
    const text = await response.text();
    expect(text).toBe('OK');
  });
  
  test('should handle POST request with JSON', async () => {
    const response = await worker.fetch('/api/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test User', email: 'test@example.com' }),
    });
    
    expect(response.status).toBe(201);
    
    const user = await response.json();
    expect(user.name).toBe('Test User');
    expect(user.id).toBeDefined();
  });
});
```

### 2. Integration Testing

```javascript
// Integration tests with real Cloudflare services
import { describe, test, expect } from 'vitest';

describe('Worker Integration Tests', () => {
  const workerUrl = 'https://my-worker.example.workers.dev';
  
  test('should integrate with KV storage', async () => {
    // Test write
    const writeResponse = await fetch(`${workerUrl}/kv/test-key`, {
      method: 'PUT',
      body: JSON.stringify({ message: 'Hello KV' }),
      headers: { 'Content-Type': 'application/json' },
    });
    
    expect(writeResponse.status).toBe(200);
    
    // Test read
    const readResponse = await fetch(`${workerUrl}/kv/test-key`);
    expect(readResponse.status).toBe(200);
    
    const data = await readResponse.json();
    expect(data.message).toBe('Hello KV');
  });
  
  test('should handle R2 file operations', async () => {
    const testFile = new Blob(['test content'], { type: 'text/plain' });
    const formData = new FormData();
    formData.append('file', testFile, 'test.txt');
    
    // Upload file
    const uploadResponse = await fetch(`${workerUrl}/upload`, {
      method: 'POST',
      body: formData,
    });
    
    expect(uploadResponse.status).toBe(200);
    
    const result = await uploadResponse.json();
    expect(result.fileKey).toBeDefined();
    
    // Download file
    const downloadResponse = await fetch(`${workerUrl}/download/${result.fileKey}`);
    expect(downloadResponse.status).toBe(200);
    
    const content = await downloadResponse.text();
    expect(content).toBe('test content');
  });
});
```

## Best Practices

### Code Organization
- Use modules for better code structure
- Implement proper error handling
- Follow consistent naming conventions
- Use TypeScript for better type safety

### Performance
- Minimize cold start time
- Use streaming for large responses
- Implement intelligent caching
- Pool external connections

### Security
- Validate all inputs
- Use proper authentication
- Implement rate limiting
- Sanitize outputs

### Monitoring
- Use console.log for debugging
- Implement health checks
- Monitor performance metrics
- Set up alerting for errors

## Common Use Cases

1. **API Gateway** - Route and transform API requests
2. **Authentication** - JWT validation and session management
3. **Data Processing** - Transform data between services
4. **Caching Layer** - Intelligent response caching
5. **Webhook Processing** - Handle incoming webhooks
6. **Real-time Features** - WebSocket handling with Durable Objects

Workers provide the computational foundation for Cloudflare's edge platform, enabling low-latency, globally distributed applications that scale automatically.
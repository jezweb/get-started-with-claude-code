# Full-Stack Application Architecture with Cloudflare

## Overview

This guide demonstrates how to architect complete full-stack applications using Cloudflare services, combining Workers, Pages, R2, KV, D1, Durable Objects, and AI services into cohesive, scalable applications.

## Architecture Patterns

### 1. Modern JAMstack Application

```
Frontend (Pages) ↔ API (Workers) ↔ Data Layer (D1 + KV + R2)
                                  ↕
                           AI Services (Workers AI + AI Gateway)
```

#### Application Structure
```
my-app/
├── frontend/                    # Vue.js/React application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── stores/
│   │   └── utils/
│   ├── public/
│   └── package.json
├── backend/                     # Workers API
│   ├── src/
│   │   ├── handlers/
│   │   ├── middleware/
│   │   ├── services/
│   │   └── utils/
│   ├── schema.sql
│   └── wrangler.toml
├── shared/                      # Shared types/utilities
│   └── types/
└── README.md
```

#### Configuration
```toml
# wrangler.toml
name = "my-app-api"
main = "src/index.js"
compatibility_date = "2024-07-01"

# Database
[[d1_databases]]
binding = "DB"
database_name = "my-app-db"
database_id = "your-database-id"

# Key-Value Storage
[[kv_namespaces]]
binding = "CACHE"
id = "your-cache-namespace"

[[kv_namespaces]]
binding = "SESSIONS"
id = "your-sessions-namespace"

# Object Storage
[[r2_buckets]]
binding = "STORAGE"
bucket_name = "my-app-storage"

# AI Services
[[ai]]
binding = "AI"

# Environment Variables
[vars]
JWT_SECRET = "your-jwt-secret"
APP_ENV = "production"
```

### 2. Complete E-commerce Platform

```javascript
// E-commerce API with all Cloudflare services
export default {
  async fetch(request, env, ctx) {
    const router = new Router(env, ctx);
    return router.handle(request);
  }
};

class Router {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    this.routes = new Map();
    this.setupRoutes();
  }
  
  setupRoutes() {
    // Auth routes
    this.routes.set('POST /auth/register', new AuthHandler(this.env).register);
    this.routes.set('POST /auth/login', new AuthHandler(this.env).login);
    this.routes.set('POST /auth/refresh', new AuthHandler(this.env).refresh);
    
    // Product routes
    this.routes.set('GET /products', new ProductHandler(this.env).list);
    this.routes.set('GET /products/:id', new ProductHandler(this.env).get);
    this.routes.set('POST /products', new ProductHandler(this.env).create);
    this.routes.set('PUT /products/:id', new ProductHandler(this.env).update);
    
    // Cart routes
    this.routes.set('GET /cart', new CartHandler(this.env).get);
    this.routes.set('POST /cart/items', new CartHandler(this.env).addItem);
    this.routes.set('PUT /cart/items/:id', new CartHandler(this.env).updateItem);
    this.routes.set('DELETE /cart/items/:id', new CartHandler(this.env).removeItem);
    
    // Order routes
    this.routes.set('POST /orders', new OrderHandler(this.env).create);
    this.routes.set('GET /orders', new OrderHandler(this.env).list);
    this.routes.set('GET /orders/:id', new OrderHandler(this.env).get);
    
    // Media routes
    this.routes.set('POST /media/upload', new MediaHandler(this.env).upload);
    this.routes.set('GET /media/:id', new MediaHandler(this.env).serve);
    
    // Search routes
    this.routes.set('GET /search', new SearchHandler(this.env).search);
    this.routes.set('GET /recommendations', new RecommendationHandler(this.env).get);
  }
  
  async handle(request) {
    const url = new URL(request.url);
    const routeKey = `${request.method} ${url.pathname}`;
    
    // Handle exact matches
    if (this.routes.has(routeKey)) {
      const handler = this.routes.get(routeKey);
      return await handler.call(this, request);
    }
    
    // Handle parameterized routes
    for (const [route, handler] of this.routes.entries()) {
      const match = this.matchRoute(route, request.method, url.pathname);
      if (match) {
        request.params = match.params;
        return await handler.call(this, request);
      }
    }
    
    return new Response('Not Found', { status: 404 });
  }
  
  matchRoute(routePattern, method, pathname) {
    const [routeMethod, routePath] = routePattern.split(' ');
    
    if (routeMethod !== method) return null;
    
    const routeParts = routePath.split('/');
    const pathParts = pathname.split('/');
    
    if (routeParts.length !== pathParts.length) return null;
    
    const params = {};
    
    for (let i = 0; i < routeParts.length; i++) {
      if (routeParts[i].startsWith(':')) {
        params[routeParts[i].slice(1)] = pathParts[i];
      } else if (routeParts[i] !== pathParts[i]) {
        return null;
      }
    }
    
    return { params };
  }
}

// Product Handler
class ProductHandler {
  constructor(env) {
    this.env = env;
    this.db = env.DB;
    this.cache = env.CACHE;
    this.storage = env.STORAGE;
    this.ai = env.AI;
  }
  
  async list(request) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '20');
    const category = url.searchParams.get('category');
    const search = url.searchParams.get('search');
    
    const offset = (page - 1) * limit;
    
    // Build cache key
    const cacheKey = `products:${page}:${limit}:${category || 'all'}:${search || 'none'}`;
    
    // Check cache first
    const cached = await this.cache.get(cacheKey, 'json');
    if (cached) {
      return Response.json(cached);
    }
    
    // Build query
    let query = `
      SELECT p.*, c.name as category_name, 
             COUNT(r.id) as review_count,
             AVG(r.rating) as avg_rating
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN reviews r ON p.id = r.product_id
      WHERE p.active = TRUE
    `;
    
    const params = [];
    
    if (category) {
      query += ' AND c.slug = ?';
      params.push(category);
    }
    
    if (search) {
      query += ' AND (p.name LIKE ? OR p.description LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }
    
    query += `
      GROUP BY p.id, c.name
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    params.push(limit, offset);
    
    // Execute query
    const stmt = this.db.prepare(query);
    const result = await stmt.bind(...params).all();
    
    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM products p';
    const countParams = [];
    
    if (category) {
      countQuery += ' JOIN categories c ON p.category_id = c.id WHERE p.active = TRUE AND c.slug = ?';
      countParams.push(category);
    } else {
      countQuery += ' WHERE p.active = TRUE';
    }
    
    if (search) {
      countQuery += category ? ' AND' : ' WHERE';
      countQuery += ' (p.name LIKE ? OR p.description LIKE ?)';
      countParams.push(`%${search}%`, `%${search}%`);
    }
    
    const countStmt = this.db.prepare(countQuery);
    const countResult = await countStmt.bind(...countParams).first();
    
    const response = {
      products: result.results,
      pagination: {
        page,
        limit,
        total: countResult.total,
        pages: Math.ceil(countResult.total / limit)
      }
    };
    
    // Cache for 5 minutes
    await this.cache.put(cacheKey, JSON.stringify(response), {
      expirationTtl: 300
    });
    
    return Response.json(response);
  }
  
  async get(request) {
    const productId = request.params.id;
    
    // Check cache
    const cacheKey = `product:${productId}`;
    const cached = await this.cache.get(cacheKey, 'json');
    if (cached) {
      return Response.json(cached);
    }
    
    // Get product from database
    const query = `
      SELECT p.*, c.name as category_name,
             COUNT(r.id) as review_count,
             AVG(r.rating) as avg_rating
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN reviews r ON p.id = r.product_id
      WHERE p.id = ? AND p.active = TRUE
      GROUP BY p.id, c.name
    `;
    
    const stmt = this.db.prepare(query);
    const product = await stmt.bind(productId).first();
    
    if (!product) {
      return new Response('Product not found', { status: 404 });
    }
    
    // Get product images
    const imagesStmt = this.db.prepare(
      'SELECT * FROM product_images WHERE product_id = ? ORDER BY sort_order'
    );
    const images = await imagesStmt.bind(productId).all();
    
    // Get recent reviews
    const reviewsStmt = this.db.prepare(`
      SELECT r.*, u.name as user_name
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.product_id = ?
      ORDER BY r.created_at DESC
      LIMIT 5
    `);
    const reviews = await reviewsStmt.bind(productId).all();
    
    const response = {
      ...product,
      images: images.results,
      reviews: reviews.results
    };
    
    // Cache for 10 minutes
    await this.cache.put(cacheKey, JSON.stringify(response), {
      expirationTtl: 600
    });
    
    return Response.json(response);
  }
  
  async create(request) {
    // Authenticate admin user
    const user = await this.authenticateAdmin(request);
    
    const formData = await request.formData();
    const productData = {
      name: formData.get('name'),
      description: formData.get('description'),
      price: parseFloat(formData.get('price')),
      category_id: parseInt(formData.get('category_id')),
      inventory_count: parseInt(formData.get('inventory_count') || '0'),
      sku: formData.get('sku')
    };
    
    // Validate required fields
    if (!productData.name || !productData.price || !productData.category_id) {
      return Response.json(
        { error: 'Name, price, and category are required' },
        { status: 400 }
      );
    }
    
    // Generate SEO-friendly slug
    productData.slug = this.generateSlug(productData.name);
    
    // Use AI to enhance description
    if (productData.description) {
      const enhancedDescription = await this.enhanceProductDescription(
        productData.name,
        productData.description
      );
      productData.ai_description = enhancedDescription;
    }
    
    // Insert product
    const insertStmt = this.db.prepare(`
      INSERT INTO products 
      (name, description, ai_description, price, category_id, inventory_count, sku, slug, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    `);
    
    const result = await insertStmt.bind(
      productData.name,
      productData.description,
      productData.ai_description,
      productData.price,
      productData.category_id,
      productData.inventory_count,
      productData.sku,
      productData.slug
    ).run();
    
    if (result.success) {
      const productId = result.meta.last_row_id;
      
      // Handle image uploads
      const images = formData.getAll('images');
      if (images.length > 0) {
        await this.uploadProductImages(productId, images);
      }
      
      // Invalidate related caches
      await this.invalidateProductCaches();
      
      return Response.json({
        id: productId,
        ...productData
      }, { status: 201 });
    }
    
    return new Response('Failed to create product', { status: 500 });
  }
  
  async enhanceProductDescription(name, description) {
    try {
      const prompt = `
        Enhance this product description to be more appealing and SEO-friendly.
        Keep it concise but compelling.
        
        Product: ${name}
        Current description: ${description}
        
        Enhanced description:
      `;
      
      const response = await this.ai.run('@cf/meta/llama-2-7b-chat-int8', {
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 200
      });
      
      return response.response.trim();
    } catch (error) {
      console.error('Failed to enhance description:', error);
      return description; // Fallback to original
    }
  }
  
  async uploadProductImages(productId, images) {
    for (let i = 0; i < images.length; i++) {
      const image = images[i];
      if (!image.type.startsWith('image/')) continue;
      
      // Generate unique filename
      const filename = `products/${productId}/${Date.now()}-${i}-${image.name}`;
      
      // Upload to R2
      await this.storage.put(filename, image.stream(), {
        httpMetadata: {
          contentType: image.type
        },
        customMetadata: {
          productId: productId.toString(),
          originalName: image.name
        }
      });
      
      // Save image record
      const imageStmt = this.db.prepare(`
        INSERT INTO product_images (product_id, filename, alt_text, sort_order)
        VALUES (?, ?, ?, ?)
      `);
      
      await imageStmt.bind(
        productId,
        filename,
        `${image.name} for product ${productId}`,
        i
      ).run();
    }
  }
  
  generateSlug(name) {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9 -]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim('-');
  }
  
  async invalidateProductCaches() {
    // In a real implementation, you'd have a more sophisticated cache invalidation strategy
    const keys = await this.cache.list({ prefix: 'products:' });
    for (const key of keys.keys) {
      await this.cache.delete(key.name);
    }
  }
  
  async authenticateAdmin(request) {
    // Implement admin authentication
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new Error('Admin authentication required');
    }
    
    // Verify admin token and return user
    // Implementation depends on your auth system
    return { id: 1, role: 'admin' }; // Placeholder
  }
}

// Cart Handler with Durable Objects
class CartHandler {
  constructor(env) {
    this.env = env;
  }
  
  async get(request) {
    const userId = await this.getUserId(request);
    
    // Get cart Durable Object
    const cartId = this.env.CART.idFromName(`cart:${userId}`);
    const cart = this.env.CART.get(cartId);
    
    // Forward request to cart object
    return cart.fetch(new Request(`${request.url}/get`, {
      method: 'GET',
      headers: request.headers
    }));
  }
  
  async addItem(request) {
    const userId = await this.getUserId(request);
    
    const cartId = this.env.CART.idFromName(`cart:${userId}`);
    const cart = this.env.CART.get(cartId);
    
    return cart.fetch(new Request(`${request.url}/add`, {
      method: 'POST',
      headers: request.headers,
      body: request.body
    }));
  }
  
  async getUserId(request) {
    // Extract user ID from JWT token
    const authHeader = request.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Authentication required');
    }
    
    // Verify JWT and extract user ID
    // Implementation depends on your auth system
    return 'user123'; // Placeholder
  }
}

// Cart Durable Object
export class CartDurableObject {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.cart = {
      items: [],
      total: 0,
      updatedAt: Date.now()
    };
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    const stored = await this.state.storage.get('cart');
    if (stored) {
      this.cart = stored;
    }
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    const url = new URL(request.url);
    const action = url.pathname.split('/').pop();
    
    switch (action) {
      case 'get':
        return this.getCart();
      case 'add':
        return this.addItem(request);
      case 'update':
        return this.updateItem(request);
      case 'remove':
        return this.removeItem(request);
      case 'clear':
        return this.clearCart();
      default:
        return new Response('Invalid action', { status: 400 });
    }
  }
  
  async getCart() {
    return Response.json(this.cart);
  }
  
  async addItem(request) {
    const { productId, quantity = 1 } = await request.json();
    
    // Get product details from database
    const product = await this.env.DB.prepare(
      'SELECT id, name, price, inventory_count FROM products WHERE id = ? AND active = TRUE'
    ).bind(productId).first();
    
    if (!product) {
      return Response.json({ error: 'Product not found' }, { status: 404 });
    }
    
    // Check inventory
    if (product.inventory_count < quantity) {
      return Response.json({ error: 'Insufficient inventory' }, { status: 400 });
    }
    
    // Find existing item or add new one
    const existingIndex = this.cart.items.findIndex(item => item.productId === productId);
    
    if (existingIndex >= 0) {
      this.cart.items[existingIndex].quantity += quantity;
      this.cart.items[existingIndex].subtotal = 
        this.cart.items[existingIndex].quantity * product.price;
    } else {
      this.cart.items.push({
        productId,
        name: product.name,
        price: product.price,
        quantity,
        subtotal: quantity * product.price
      });
    }
    
    this.recalculateTotal();
    await this.save();
    
    return Response.json(this.cart);
  }
  
  recalculateTotal() {
    this.cart.total = this.cart.items.reduce((sum, item) => sum + item.subtotal, 0);
    this.cart.updatedAt = Date.now();
  }
  
  async save() {
    await this.state.storage.put('cart', this.cart);
  }
}
```

### 3. Real-time Collaboration Platform

```javascript
// Real-time collaboration with Durable Objects
export class CollaborationRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map();
    this.document = { content: '', version: 0 };
    this.initialized = false;
  }
  
  async initialize() {
    if (this.initialized) return;
    
    // Load document from storage
    const storedDoc = await this.state.storage.get('document');
    if (storedDoc) {
      this.document = storedDoc;
    }
    
    this.initialized = true;
  }
  
  async fetch(request) {
    await this.initialize();
    
    // Handle WebSocket upgrade
    if (request.headers.get('Upgrade') === 'websocket') {
      return this.handleWebSocket(request);
    }
    
    const url = new URL(request.url);
    
    if (url.pathname === '/document' && request.method === 'GET') {
      return Response.json(this.document);
    }
    
    if (url.pathname === '/save' && request.method === 'POST') {
      return this.saveDocument(request);
    }
    
    return new Response('Not found', { status: 404 });
  }
  
  async handleWebSocket(request) {
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    
    server.accept();
    
    const sessionId = crypto.randomUUID();
    const session = {
      id: sessionId,
      socket: server,
      user: null,
      cursor: { line: 0, column: 0 },
      lastSeen: Date.now()
    };
    
    this.sessions.set(sessionId, session);
    
    // Send current document state
    server.send(JSON.stringify({
      type: 'document_state',
      document: this.document,
      sessionId
    }));
    
    // Handle messages
    server.addEventListener('message', async (event) => {
      try {
        const message = JSON.parse(event.data);
        await this.handleMessage(sessionId, message);
      } catch (error) {
        console.error('WebSocket message error:', error);
      }
    });
    
    // Handle disconnect
    server.addEventListener('close', () => {
      this.sessions.delete(sessionId);
      this.broadcastUserLeft(sessionId);
    });
    
    return new Response(null, {
      status: 101,
      webSocket: client
    });
  }
  
  async handleMessage(sessionId, message) {
    const session = this.sessions.get(sessionId);
    if (!session) return;
    
    switch (message.type) {
      case 'operation':
        await this.handleOperation(sessionId, message.operation);
        break;
      case 'cursor':
        this.handleCursorUpdate(sessionId, message.cursor);
        break;
      case 'user_info':
        this.handleUserInfo(sessionId, message.user);
        break;
    }
  }
  
  async handleOperation(sessionId, operation) {
    // Apply operation to document
    this.document = this.applyOperation(this.document, operation);
    this.document.version++;
    
    // Save to storage
    await this.state.storage.put('document', this.document);
    
    // Save to D1 for persistence
    await this.env.DB.prepare(`
      INSERT INTO document_operations (room_id, operation_type, operation_data, version)
      VALUES (?, ?, ?, ?)
    `).bind(
      this.state.id.toString(),
      operation.type,
      JSON.stringify(operation),
      this.document.version
    ).run();
    
    // Broadcast to other sessions
    this.broadcast({
      type: 'operation',
      operation,
      version: this.document.version,
      sessionId
    }, sessionId);
  }
  
  applyOperation(document, operation) {
    let content = document.content;
    
    switch (operation.type) {
      case 'insert':
        content = content.slice(0, operation.position) + 
                  operation.text + 
                  content.slice(operation.position);
        break;
      case 'delete':
        content = content.slice(0, operation.position) + 
                  content.slice(operation.position + operation.length);
        break;
    }
    
    return { ...document, content };
  }
  
  broadcast(message, excludeSessionId = null) {
    const messageString = JSON.stringify(message);
    
    for (const [sessionId, session] of this.sessions.entries()) {
      if (sessionId !== excludeSessionId) {
        try {
          session.socket.send(messageString);
        } catch (error) {
          // Remove broken session
          this.sessions.delete(sessionId);
        }
      }
    }
  }
}
```

## Deployment Strategy

### 1. Multi-Environment Setup

```toml
# wrangler.toml
name = "my-app"

[env.development]
vars = { ENV = "development" }
d1_databases = [
  { binding = "DB", database_name = "my-app-dev", database_id = "dev-db-id" }
]

[env.staging]
vars = { ENV = "staging" }
d1_databases = [
  { binding = "DB", database_name = "my-app-staging", database_id = "staging-db-id" }
]

[env.production]
vars = { ENV = "production" }
d1_databases = [
  { binding = "DB", database_name = "my-app-prod", database_id = "prod-db-id" }
]
```

### 2. CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloudflare

on:
  push:
    branches: [main, staging, development]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: |
          cd frontend && npm ci
          cd ../backend && npm ci
          
      - name: Build frontend
        run: cd frontend && npm run build
        
      - name: Deploy to staging
        if: github.ref == 'refs/heads/staging'
        run: |
          cd backend && npx wrangler deploy --env staging
          cd ../frontend && npx wrangler pages deploy dist --project-name my-app-staging
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          
      - name: Deploy to production
        if: github.ref == 'refs/heads/main'
        run: |
          cd backend && npx wrangler deploy --env production
          cd ../frontend && npx wrangler pages deploy dist --project-name my-app
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

## Monitoring and Analytics

### 1. Performance Monitoring

```javascript
// Performance monitoring middleware
class PerformanceMonitor {
  constructor(env) {
    this.env = env;
  }
  
  async monitor(request, handler) {
    const startTime = Date.now();
    const requestId = crypto.randomUUID();
    
    try {
      const response = await handler(request);
      
      // Log successful request
      await this.logRequest({
        requestId,
        method: request.method,
        url: request.url,
        status: response.status,
        duration: Date.now() - startTime,
        timestamp: Date.now()
      });
      
      // Add performance headers
      response.headers.set('X-Request-ID', requestId);
      response.headers.set('X-Response-Time', `${Date.now() - startTime}ms`);
      
      return response;
    } catch (error) {
      // Log error
      await this.logError({
        requestId,
        method: request.method,
        url: request.url,
        error: error.message,
        duration: Date.now() - startTime,
        timestamp: Date.now()
      });
      
      throw error;
    }
  }
  
  async logRequest(data) {
    // Store in KV for analytics
    const key = `request:${data.timestamp}:${data.requestId}`;
    await this.env.ANALYTICS.put(key, JSON.stringify(data), {
      expirationTtl: 86400 * 30 // Keep for 30 days
    });
    
    // Update daily metrics
    await this.updateDailyMetrics(data);
  }
  
  async updateDailyMetrics(data) {
    const today = new Date().toISOString().split('T')[0];
    const key = `metrics:${today}`;
    
    const current = await this.env.ANALYTICS.get(key, 'json') || {
      requests: 0,
      errors: 0,
      totalDuration: 0,
      statusCodes: {}
    };
    
    current.requests++;
    current.totalDuration += data.duration;
    current.statusCodes[data.status] = (current.statusCodes[data.status] || 0) + 1;
    
    await this.env.ANALYTICS.put(key, JSON.stringify(current), {
      expirationTtl: 86400 * 365 // Keep for 1 year
    });
  }
}
```

## Security Best Practices

### 1. Authentication & Authorization

```javascript
// Comprehensive auth system
class AuthSystem {
  constructor(env) {
    this.env = env;
    this.jwtSecret = env.JWT_SECRET;
  }
  
  async authenticateRequest(request, requiredRole = null) {
    const authHeader = request.headers.get('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new Error('Authentication required');
    }
    
    const token = authHeader.slice(7);
    const payload = await this.verifyJWT(token);
    
    // Get user from database
    const user = await this.env.DB.prepare(
      'SELECT * FROM users WHERE id = ? AND active = TRUE'
    ).bind(payload.userId).first();
    
    if (!user) {
      throw new Error('User not found');
    }
    
    // Check role if required
    if (requiredRole && user.role !== requiredRole) {
      throw new Error('Insufficient permissions');
    }
    
    return user;
  }
  
  async verifyJWT(token) {
    // Implement JWT verification
    // Use crypto.subtle for HMAC verification
    // This is a simplified version
    return JSON.parse(atob(token.split('.')[1]));
  }
}
```

## Performance Optimization

### 1. Caching Strategy

```javascript
// Multi-layer caching strategy
class CacheManager {
  constructor(env) {
    this.kv = env.CACHE;
    this.edge = caches.default;
  }
  
  async get(key, fetcher, options = {}) {
    const { 
      kvTtl = 3600,
      edgeTtl = 300,
      staleWhileRevalidate = false 
    } = options;
    
    // Try edge cache first
    let response = await this.edge.match(key);
    if (response) {
      return response;
    }
    
    // Try KV cache
    const kvData = await this.kv.get(key, 'json');
    if (kvData) {
      response = Response.json(kvData);
      
      // Update edge cache
      response.headers.set('Cache-Control', `public, max-age=${edgeTtl}`);
      await this.edge.put(key, response.clone());
      
      return response;
    }
    
    // Fetch fresh data
    const data = await fetcher();
    response = Response.json(data);
    
    // Cache in KV
    await this.kv.put(key, JSON.stringify(data), {
      expirationTtl: kvTtl
    });
    
    // Cache at edge
    response.headers.set('Cache-Control', `public, max-age=${edgeTtl}`);
    await this.edge.put(key, response.clone());
    
    return response;
  }
}
```

This comprehensive guide demonstrates how to build production-ready full-stack applications using Cloudflare's edge platform, combining multiple services for optimal performance, scalability, and developer experience.
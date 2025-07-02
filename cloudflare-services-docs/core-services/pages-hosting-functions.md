# Cloudflare Pages - Static Site Hosting & Functions

## Overview

Cloudflare Pages provides fast, secure static site hosting with integrated serverless functions, automatic deployments from Git repositories, and seamless integration with the Cloudflare edge network. Perfect for JAMstack applications, SPAs, and modern web development workflows.

## Quick Start

### Basic Setup
```bash
# Install Wrangler CLI
npm install -g wrangler

# Create new Pages project
npx create-cloudflare@latest my-app --framework=react
cd my-app

# Deploy to Pages
npx wrangler pages deploy dist
```

### Project Structure
```
my-app/
├── public/              # Static assets
├── src/                # Source code
├── functions/          # Pages Functions (serverless)
│   ├── api/
│   │   └── users.js    # /api/users endpoint
│   └── _middleware.js  # Global middleware
├── _redirects         # Redirect rules
├── _headers           # Custom headers
└── wrangler.toml      # Configuration
```

## Core Concepts

### Static Site Hosting
Pages automatically builds and deploys your static sites:

```javascript
// Next.js example
// pages/index.js
export default function Home() {
  return (
    <div>
      <h1>Welcome to Cloudflare Pages</h1>
      <p>Deployed automatically from Git</p>
    </div>
  );
}

// Automatic build and deployment on git push
```

### Git Integration
```yaml
# .github/workflows/pages.yml
name: Deploy to Cloudflare Pages
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: my-app
          directory: dist
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

## Pages Functions

### API Endpoints
```javascript
// functions/api/users.js
export async function onRequestGet(context) {
  const { request, env, params } = context;
  
  // Get users from database
  const users = await env.DB.prepare('SELECT * FROM users').all();
  
  return Response.json(users.results);
}

export async function onRequestPost(context) {
  const { request, env } = context;
  
  try {
    const userData = await request.json();
    
    // Validate input
    if (!userData.name || !userData.email) {
      return new Response('Name and email are required', { status: 400 });
    }
    
    // Insert user
    const { success, meta } = await env.DB.prepare(`
      INSERT INTO users (name, email, created_at)
      VALUES (?, ?, ?)
    `).bind(userData.name, userData.email, new Date().toISOString()).run();
    
    if (success) {
      return Response.json({
        id: meta.last_row_id,
        ...userData,
        created_at: new Date().toISOString(),
      }, { status: 201 });
    }
    
    return new Response('Failed to create user', { status: 500 });
  } catch (error) {
    return new Response('Invalid JSON', { status: 400 });
  }
}
```

### Dynamic Routes
```javascript
// functions/api/users/[id].js
export async function onRequestGet(context) {
  const { params, env } = context;
  const userId = params.id;
  
  const user = await env.DB.prepare('SELECT * FROM users WHERE id = ?')
    .bind(userId)
    .first();
  
  if (!user) {
    return new Response('User not found', { status: 404 });
  }
  
  return Response.json(user);
}

export async function onRequestPut(context) {
  const { params, request, env } = context;
  const userId = params.id;
  
  const updateData = await request.json();
  
  const { success } = await env.DB.prepare(`
    UPDATE users 
    SET name = ?, email = ?, updated_at = ?
    WHERE id = ?
  `).bind(updateData.name, updateData.email, new Date().toISOString(), userId).run();
  
  if (success) {
    return Response.json({ message: 'User updated successfully' });
  }
  
  return new Response('User not found', { status: 404 });
}

export async function onRequestDelete(context) {
  const { params, env } = context;
  const userId = params.id;
  
  const { success } = await env.DB.prepare('DELETE FROM users WHERE id = ?')
    .bind(userId)
    .run();
  
  if (success) {
    return Response.json({ message: 'User deleted successfully' });
  }
  
  return new Response('User not found', { status: 404 });
}
```

### Middleware
```javascript
// functions/_middleware.js
export async function onRequest(context) {
  const { request, next, env } = context;
  
  // Add security headers
  const response = await next();
  
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  
  return response;
}

// functions/admin/_middleware.js
export async function onRequest(context) {
  const { request, next, env } = context;
  
  // Check authentication for admin routes
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  const token = authHeader.slice(7);
  const isValid = await validateAdminToken(token, env);
  
  if (!isValid) {
    return new Response('Invalid token', { status: 401 });
  }
  
  return next();
}

async function validateAdminToken(token, env) {
  try {
    // Validate JWT or check against database
    const payload = jwt.verify(token, env.JWT_SECRET);
    return payload.role === 'admin';
  } catch {
    return false;
  }
}
```

## Integration Patterns

### 1. Full-Stack Application

```javascript
// React frontend with Pages Functions backend
// src/components/UserManager.jsx
import { useState, useEffect } from 'react';

export default function UserManager() {
  const [users, setUsers] = useState([]);
  const [newUser, setNewUser] = useState({ name: '', email: '' });
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    fetchUsers();
  }, []);
  
  const fetchUsers = async () => {
    try {
      const response = await fetch('/api/users');
      const data = await response.json();
      setUsers(data);
    } catch (error) {
      console.error('Failed to fetch users:', error);
    }
  };
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newUser),
      });
      
      if (response.ok) {
        const user = await response.json();
        setUsers([...users, user]);
        setNewUser({ name: '', email: '' });
      } else {
        const error = await response.text();
        alert(`Error: ${error}`);
      }
    } catch (error) {
      console.error('Failed to create user:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const deleteUser = async (id) => {
    try {
      const response = await fetch(`/api/users/${id}`, {
        method: 'DELETE',
      });
      
      if (response.ok) {
        setUsers(users.filter(user => user.id !== id));
      }
    } catch (error) {
      console.error('Failed to delete user:', error);
    }
  };
  
  return (
    <div className="user-manager">
      <h2>User Management</h2>
      
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Name"
          value={newUser.name}
          onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
          required
        />
        <input
          type="email"
          placeholder="Email"
          value={newUser.email}
          onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
          required
        />
        <button type="submit" disabled={loading}>
          {loading ? 'Creating...' : 'Add User'}
        </button>
      </form>
      
      <div className="users-list">
        {users.map(user => (
          <div key={user.id} className="user-card">
            <h3>{user.name}</h3>
            <p>{user.email}</p>
            <button onClick={() => deleteUser(user.id)}>Delete</button>
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 2. E-commerce Integration

```javascript
// functions/api/products/[id].js
export async function onRequestGet(context) {
  const { params, env } = context;
  const productId = params.id;
  
  // Get product from database
  const product = await env.DB.prepare(`
    SELECT p.*, c.name as category_name 
    FROM products p 
    LEFT JOIN categories c ON p.category_id = c.id 
    WHERE p.id = ?
  `).bind(productId).first();
  
  if (!product) {
    return new Response('Product not found', { status: 404 });
  }
  
  // Get product images from R2
  const images = await env.PRODUCT_IMAGES.list({ prefix: `products/${productId}/` });
  product.images = images.objects.map(obj => ({
    url: `/api/images/${obj.key}`,
    key: obj.key,
  }));
  
  return Response.json(product);
}

// functions/api/cart.js
export async function onRequestPost(context) {
  const { request, env } = context;
  const { productId, quantity, userId } = await request.json();
  
  // Validate product exists and has stock
  const product = await env.DB.prepare('SELECT * FROM products WHERE id = ?')
    .bind(productId)
    .first();
  
  if (!product) {
    return new Response('Product not found', { status: 404 });
  }
  
  if (product.stock < quantity) {
    return new Response('Insufficient stock', { status: 400 });
  }
  
  // Add to cart
  const { success, meta } = await env.DB.prepare(`
    INSERT INTO cart_items (user_id, product_id, quantity, created_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT (user_id, product_id) DO UPDATE SET
    quantity = quantity + ?,
    updated_at = ?
  `).bind(
    userId,
    productId,
    quantity,
    new Date().toISOString(),
    quantity,
    new Date().toISOString()
  ).run();
  
  if (success) {
    return Response.json({ message: 'Added to cart', cartItemId: meta.last_row_id });
  }
  
  return new Response('Failed to add to cart', { status: 500 });
}

// functions/api/checkout.js
export async function onRequestPost(context) {
  const { request, env } = context;
  const { userId, paymentMethod } = await request.json();
  
  // Get cart items
  const cartItems = await env.DB.prepare(`
    SELECT ci.*, p.name, p.price 
    FROM cart_items ci 
    JOIN products p ON ci.product_id = p.id 
    WHERE ci.user_id = ?
  `).bind(userId).all();
  
  if (cartItems.results.length === 0) {
    return new Response('Cart is empty', { status: 400 });
  }
  
  // Calculate total
  const total = cartItems.results.reduce((sum, item) => 
    sum + (item.price * item.quantity), 0
  );
  
  // Process payment (integrate with payment provider)
  const paymentResult = await processPayment({
    amount: total,
    method: paymentMethod,
    userId,
  }, env);
  
  if (paymentResult.success) {
    // Create order
    const { success, meta } = await env.DB.prepare(`
      INSERT INTO orders (user_id, total, status, payment_id, created_at)
      VALUES (?, ?, 'paid', ?, ?)
    `).bind(userId, total, paymentResult.paymentId, new Date().toISOString()).run();
    
    if (success) {
      const orderId = meta.last_row_id;
      
      // Add order items
      for (const item of cartItems.results) {
        await env.DB.prepare(`
          INSERT INTO order_items (order_id, product_id, quantity, price)
          VALUES (?, ?, ?, ?)
        `).bind(orderId, item.product_id, item.quantity, item.price).run();
      }
      
      // Clear cart
      await env.DB.prepare('DELETE FROM cart_items WHERE user_id = ?')
        .bind(userId)
        .run();
      
      return Response.json({
        orderId,
        total,
        status: 'paid',
        message: 'Order placed successfully',
      });
    }
  }
  
  return new Response('Payment failed', { status: 400 });
}

async function processPayment(paymentData, env) {
  // Integrate with payment provider (Stripe, PayPal, etc.)
  try {
    const response = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        amount: paymentData.amount * 100, // Convert to cents
        currency: 'usd',
        payment_method: paymentData.method,
        confirm: 'true',
      }),
    });
    
    const result = await response.json();
    
    return {
      success: result.status === 'succeeded',
      paymentId: result.id,
    };
  } catch (error) {
    console.error('Payment error:', error);
    return { success: false };
  }
}
```

### 3. Content Management System

```javascript
// functions/api/content/[...slug].js
export async function onRequestGet(context) {
  const { params, env } = context;
  const slug = params.slug.join('/');
  
  // Get content from database
  const content = await env.DB.prepare(`
    SELECT c.*, u.name as author_name
    FROM content c
    JOIN users u ON c.author_id = u.id
    WHERE c.slug = ? AND c.status = 'published'
  `).bind(slug).first();
  
  if (!content) {
    return new Response('Content not found', { status: 404 });
  }
  
  // Parse content based on type
  let parsedContent = content.body;
  
  if (content.type === 'markdown') {
    // Convert markdown to HTML (you'd use a markdown parser)
    parsedContent = await renderMarkdown(content.body);
  }
  
  return Response.json({
    ...content,
    body: parsedContent,
  });
}

export async function onRequestPost(context) {
  const { request, env } = context;
  const { title, body, type, status, authorId } = await request.json();
  
  // Generate slug from title
  const slug = title.toLowerCase()
    .replace(/[^a-z0-9 -]/g, '')
    .replace(/\s+/g, '-');
  
  // Check if slug exists
  const existing = await env.DB.prepare('SELECT id FROM content WHERE slug = ?')
    .bind(slug)
    .first();
  
  if (existing) {
    return new Response('Content with this title already exists', { status: 400 });
  }
  
  // Insert content
  const { success, meta } = await env.DB.prepare(`
    INSERT INTO content (title, slug, body, type, status, author_id, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(
    title,
    slug,
    body,
    type,
    status,
    authorId,
    new Date().toISOString()
  ).run();
  
  if (success) {
    return Response.json({
      id: meta.last_row_id,
      title,
      slug,
      message: 'Content created successfully',
    }, { status: 201 });
  }
  
  return new Response('Failed to create content', { status: 500 });
}

async function renderMarkdown(markdown) {
  // Use a markdown parser like marked or markdown-it
  // This is a placeholder implementation
  return markdown.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                .replace(/\*(.*?)\*/g, '<em>$1</em>');
}
```

## Advanced Features

### 1. Authentication & Authorization

```javascript
// functions/auth/login.js
export async function onRequestPost(context) {
  const { request, env } = context;
  const { email, password } = await request.json();
  
  // Get user from database
  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?')
    .bind(email)
    .first();
  
  if (!user) {
    return new Response('Invalid credentials', { status: 401 });
  }
  
  // Verify password (use bcrypt in production)
  const isValidPassword = await verifyPassword(password, user.password_hash);
  
  if (!isValidPassword) {
    return new Response('Invalid credentials', { status: 401 });
  }
  
  // Generate JWT token
  const token = await generateJWT({
    userId: user.id,
    email: user.email,
    role: user.role,
  }, env.JWT_SECRET);
  
  // Set secure cookie
  const response = Response.json({
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    },
    token,
  });
  
  response.headers.set('Set-Cookie', `auth_token=${token}; HttpOnly; Secure; SameSite=Strict; Max-Age=${7 * 24 * 60 * 60}`);
  
  return response;
}

// functions/auth/logout.js
export async function onRequestPost(context) {
  const response = Response.json({ message: 'Logged out successfully' });
  
  // Clear auth cookie
  response.headers.set('Set-Cookie', 'auth_token=; HttpOnly; Secure; SameSite=Strict; Max-Age=0');
  
  return response;
}

// functions/auth/refresh.js
export async function onRequestPost(context) {
  const { request, env } = context;
  
  // Get token from cookie or header
  const token = request.headers.get('Authorization')?.slice(7) ||
                getCookieValue(request.headers.get('Cookie'), 'auth_token');
  
  if (!token) {
    return new Response('No token provided', { status: 401 });
  }
  
  try {
    const payload = await verifyJWT(token, env.JWT_SECRET);
    
    // Generate new token
    const newToken = await generateJWT({
      userId: payload.userId,
      email: payload.email,
      role: payload.role,
    }, env.JWT_SECRET);
    
    return Response.json({ token: newToken });
  } catch {
    return new Response('Invalid token', { status: 401 });
  }
}

function getCookieValue(cookieString, name) {
  const cookies = cookieString?.split(';') || [];
  for (const cookie of cookies) {
    const [key, value] = cookie.trim().split('=');
    if (key === name) return value;
  }
  return null;
}
```

### 2. File Upload Handling

```javascript
// functions/api/upload.js
export async function onRequestPost(context) {
  const { request, env } = context;
  
  try {
    const formData = await request.formData();
    const file = formData.get('file');
    const uploadType = formData.get('type') || 'general';
    
    if (!file) {
      return new Response('No file provided', { status: 400 });
    }
    
    // Validate file
    const validationResult = validateFile(file, uploadType);
    if (!validationResult.valid) {
      return new Response(validationResult.error, { status: 400 });
    }
    
    // Generate unique filename
    const fileExtension = file.name.split('.').pop();
    const fileName = `${uploadType}/${Date.now()}-${crypto.randomUUID()}.${fileExtension}`;
    
    // Upload to R2
    await env.UPLOADS_BUCKET.put(fileName, file.stream(), {
      httpMetadata: {
        contentType: file.type,
      },
      customMetadata: {
        originalName: file.name,
        uploadType,
        uploadedAt: new Date().toISOString(),
      },
    });
    
    // Save file metadata to database
    const { success, meta } = await env.DB.prepare(`
      INSERT INTO files (filename, original_name, content_type, size, upload_type, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      fileName,
      file.name,
      file.type,
      file.size,
      uploadType,
      new Date().toISOString()
    ).run();
    
    if (success) {
      return Response.json({
        id: meta.last_row_id,
        filename: fileName,
        originalName: file.name,
        url: `/api/files/${fileName}`,
        size: file.size,
        contentType: file.type,
      });
    }
    
    return new Response('Failed to save file metadata', { status: 500 });
  } catch (error) {
    console.error('Upload error:', error);
    return new Response('Upload failed', { status: 500 });
  }
}

function validateFile(file, uploadType) {
  const maxSizes = {
    image: 5 * 1024 * 1024, // 5MB
    document: 10 * 1024 * 1024, // 10MB
    general: 25 * 1024 * 1024, // 25MB
  };
  
  const allowedTypes = {
    image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    document: ['application/pdf', 'text/plain', 'application/msword'],
    general: [], // Allow all types
  };
  
  // Check file size
  const maxSize = maxSizes[uploadType] || maxSizes.general;
  if (file.size > maxSize) {
    return {
      valid: false,
      error: `File too large. Maximum size: ${Math.round(maxSize / 1024 / 1024)}MB`,
    };
  }
  
  // Check file type
  const allowed = allowedTypes[uploadType];
  if (allowed && allowed.length > 0 && !allowed.includes(file.type)) {
    return {
      valid: false,
      error: `Invalid file type. Allowed: ${allowed.join(', ')}`,
    };
  }
  
  return { valid: true };
}

// functions/api/files/[filename].js
export async function onRequestGet(context) {
  const { params, env } = context;
  const filename = params.filename;
  
  // Get file from R2
  const object = await env.UPLOADS_BUCKET.get(filename);
  
  if (!object) {
    return new Response('File not found', { status: 404 });
  }
  
  return new Response(object.body, {
    headers: {
      'Content-Type': object.httpMetadata.contentType,
      'Cache-Control': 'public, max-age=31536000',
      'Content-Disposition': `inline; filename="${object.customMetadata.originalName}"`,
    },
  });
}
```

## Performance Optimization

### 1. Static Asset Optimization

```javascript
// _headers file for static assets
/*
  Cache-Control: public, max-age=31536000, immutable
  X-Content-Type-Options: nosniff

/api/*
  Cache-Control: no-cache

/*.css
  Content-Type: text/css; charset=utf-8
  Cache-Control: public, max-age=31536000, immutable

/*.js
  Content-Type: application/javascript; charset=utf-8
  Cache-Control: public, max-age=31536000, immutable

/*.woff2
  Content-Type: font/woff2
  Cache-Control: public, max-age=31536000, immutable
```

### 2. Response Optimization

```javascript
// functions/_middleware.js
export async function onRequest(context) {
  const { request, next } = context;
  
  // Get response from next handler
  const response = await next();
  
  // Add performance headers
  response.headers.set('X-Powered-By', 'Cloudflare Pages');
  
  // Enable compression for text content
  const contentType = response.headers.get('Content-Type');
  if (contentType && (
    contentType.includes('text/') ||
    contentType.includes('application/json') ||
    contentType.includes('application/javascript')
  )) {
    response.headers.set('Vary', 'Accept-Encoding');
  }
  
  // Security headers
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  return response;
}
```

## Configuration & Deployment

### 1. Environment Variables

```toml
# wrangler.toml
name = "my-pages-app"
compatibility_date = "2024-07-01"

[env.production]
vars = { ENVIRONMENT = "production" }

[[env.production.d1_databases]]
binding = "DB"
database_name = "my-production-db"
database_id = "your-production-db-id"

[[env.production.r2_buckets]]
binding = "UPLOADS_BUCKET"
bucket_name = "my-production-uploads"

[env.staging]
vars = { ENVIRONMENT = "staging" }

[[env.staging.d1_databases]]
binding = "DB"
database_name = "my-staging-db"
database_id = "your-staging-db-id"
```

### 2. Build Configuration

```json
// package.json
{
  "scripts": {
    "build": "vite build",
    "deploy": "npm run build && wrangler pages deploy dist",
    "deploy:staging": "npm run build && wrangler pages deploy dist --env staging",
    "dev": "vite dev",
    "functions:dev": "wrangler pages dev dist --port 3000"
  }
}
```

## Best Practices

### Code Organization
- Separate API routes into logical groups
- Use middleware for common functionality
- Implement proper error handling
- Follow consistent naming conventions

### Performance
- Optimize static assets (minification, compression)
- Use appropriate caching strategies
- Minimize function cold starts
- Leverage edge caching

### Security
- Validate all inputs
- Implement proper authentication
- Use HTTPS everywhere
- Set security headers

### SEO & Accessibility
- Implement proper meta tags
- Use semantic HTML
- Optimize for Core Web Vitals
- Ensure accessibility compliance

## Common Use Cases

1. **JAMstack Applications** - React, Vue, Angular with API functions
2. **E-commerce Sites** - Product catalogs with serverless checkout
3. **Content Management** - Blogs and documentation sites
4. **Landing Pages** - Marketing sites with form handling
5. **Progressive Web Apps** - Offline-capable applications

Cloudflare Pages combines the best of static hosting and serverless functions, providing a complete platform for modern web applications with global performance and automatic scaling.
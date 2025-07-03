# Cloudflare D1 - Serverless SQL Database

## Overview

Cloudflare D1 is a serverless SQL database built on SQLite, distributed globally across Cloudflare's edge network. It provides familiar SQL capabilities with automatic scaling, zero maintenance, and seamless integration with Workers and Pages.

## Quick Start

### Basic Setup
```javascript
// Workers with D1 database
export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    
    if (pathname === '/users' && request.method === 'GET') {
      const { results } = await env.DB.prepare('SELECT * FROM users').all();
      return Response.json(results);
    }
    
    if (pathname === '/users' && request.method === 'POST') {
      const { name, email } = await request.json();
      
      const { success, meta } = await env.DB.prepare(
        'INSERT INTO users (name, email) VALUES (?, ?)'
      ).bind(name, email).run();
      
      if (success) {
        return Response.json({
          id: meta.last_row_id,
          name,
          email
        }, { status: 201 });
      }
      
      return new Response('Failed to create user', { status: 500 });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

### Configuration
```toml
# wrangler.toml
[[d1_databases]]
binding = "DB"
database_name = "my-database"
database_id = "your-database-id"
```

### Database Schema
```sql
-- schema.sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  published BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_published ON posts(published);
```

## Core Operations

### CRUD Operations
```javascript
class DatabaseManager {
  constructor(db) {
    this.db = db;
  }
  
  // Create operations
  async createUser(userData) {
    const { name, email, bio = null } = userData;
    
    const stmt = this.db.prepare(`
      INSERT INTO users (name, email, bio, created_at, updated_at)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    `);
    
    const result = await stmt.bind(name, email, bio).run();
    
    if (result.success) {
      return {
        id: result.meta.last_row_id,
        name,
        email,
        bio,
        created_at: new Date().toISOString()
      };
    }
    
    throw new Error('Failed to create user');
  }
  
  async createPost(postData) {
    const { user_id, title, content, published = false } = postData;
    
    const stmt = this.db.prepare(`
      INSERT INTO posts (user_id, title, content, published, created_at)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
    `);
    
    const result = await stmt.bind(user_id, title, content, published).run();
    
    if (result.success) {
      return {
        id: result.meta.last_row_id,
        user_id,
        title,
        content,
        published,
        created_at: new Date().toISOString()
      };
    }
    
    throw new Error('Failed to create post');
  }
  
  // Read operations
  async getUser(userId) {
    const stmt = this.db.prepare('SELECT * FROM users WHERE id = ?');
    const user = await stmt.bind(userId).first();
    
    if (!user) {
      throw new Error('User not found');
    }
    
    return user;
  }
  
  async getUserByEmail(email) {
    const stmt = this.db.prepare('SELECT * FROM users WHERE email = ?');
    return await stmt.bind(email).first();
  }
  
  async getUsersWithPagination(limit = 10, offset = 0) {
    const countStmt = this.db.prepare('SELECT COUNT(*) as total FROM users');
    const usersStmt = this.db.prepare(`
      SELECT * FROM users 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `);
    
    const [countResult, usersResult] = await Promise.all([
      countStmt.first(),
      usersStmt.bind(limit, offset).all()
    ]);
    
    return {
      users: usersResult.results,
      total: countResult.total,
      limit,
      offset,
      has_more: offset + limit < countResult.total
    };
  }
  
  async getUserPosts(userId, includeUnpublished = false) {
    let query = `
      SELECT p.*, u.name as author_name
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.user_id = ?
    `;
    
    if (!includeUnpublished) {
      query += ' AND p.published = TRUE';
    }
    
    query += ' ORDER BY p.created_at DESC';
    
    const stmt = this.db.prepare(query);
    const result = await stmt.bind(userId).all();
    
    return result.results;
  }
  
  // Update operations
  async updateUser(userId, updateData) {
    const { name, email, bio } = updateData;
    
    const stmt = this.db.prepare(`
      UPDATE users 
      SET name = ?, email = ?, bio = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `);
    
    const result = await stmt.bind(name, email, bio, userId).run();
    
    if (result.success && result.meta.changes > 0) {
      return await this.getUser(userId);
    }
    
    throw new Error('Failed to update user or user not found');
  }
  
  async publishPost(postId) {
    const stmt = this.db.prepare(`
      UPDATE posts 
      SET published = TRUE, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `);
    
    const result = await stmt.bind(postId).run();
    
    return result.success && result.meta.changes > 0;
  }
  
  // Delete operations
  async deleteUser(userId) {
    // First delete user's posts
    const deletePostsStmt = this.db.prepare('DELETE FROM posts WHERE user_id = ?');
    await deletePostsStmt.bind(userId).run();
    
    // Then delete user
    const deleteUserStmt = this.db.prepare('DELETE FROM users WHERE id = ?');
    const result = await deleteUserStmt.bind(userId).run();
    
    return result.success && result.meta.changes > 0;
  }
  
  async deletePost(postId) {
    const stmt = this.db.prepare('DELETE FROM posts WHERE id = ?');
    const result = await stmt.bind(postId).run();
    
    return result.success && result.meta.changes > 0;
  }
}
```

## Advanced Features

### Transactions
```javascript
// Transaction management for data consistency
class TransactionManager {
  constructor(db) {
    this.db = db;
  }
  
  async transferUserPosts(fromUserId, toUserId) {
    // Begin transaction
    const transaction = this.db.batch([
      // Verify both users exist
      this.db.prepare('SELECT id FROM users WHERE id = ?').bind(fromUserId),
      this.db.prepare('SELECT id FROM users WHERE id = ?').bind(toUserId),
      
      // Transfer posts
      this.db.prepare('UPDATE posts SET user_id = ? WHERE user_id = ?')
        .bind(toUserId, fromUserId),
      
      // Update timestamp on target user
      this.db.prepare('UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = ?')
        .bind(toUserId)
    ]);
    
    const results = await transaction;
    
    // Check if all operations succeeded
    const allSuccessful = results.every(result => result.success);
    
    if (allSuccessful) {
      return {
        success: true,
        posts_transferred: results[2].meta.changes
      };
    }
    
    throw new Error('Transaction failed');
  }
  
  async createUserWithPost(userData, postData) {
    // Create user and their first post in a transaction
    const userInsert = this.db.prepare(`
      INSERT INTO users (name, email, created_at, updated_at)
      VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    `).bind(userData.name, userData.email);
    
    const transaction = this.db.batch([userInsert]);
    const [userResult] = await transaction;
    
    if (userResult.success) {
      const userId = userResult.meta.last_row_id;
      
      // Create the post
      const postInsert = this.db.prepare(`
        INSERT INTO posts (user_id, title, content, published, created_at)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
      `).bind(userId, postData.title, postData.content, postData.published || false);
      
      const postTransaction = this.db.batch([postInsert]);
      const [postResult] = await postTransaction;
      
      if (postResult.success) {
        return {
          user: {
            id: userId,
            ...userData
          },
          post: {
            id: postResult.meta.last_row_id,
            user_id: userId,
            ...postData
          }
        };
      }
    }
    
    throw new Error('Failed to create user and post');
  }
  
  async bulkInsertPosts(posts) {
    const statements = posts.map(post => 
      this.db.prepare(`
        INSERT INTO posts (user_id, title, content, published, created_at)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
      `).bind(post.user_id, post.title, post.content, post.published || false)
    );
    
    const results = await this.db.batch(statements);
    
    const successful = results.filter(result => result.success);
    const failed = results.filter(result => !result.success);
    
    return {
      total: posts.length,
      successful: successful.length,
      failed: failed.length,
      inserted_ids: successful.map(result => result.meta.last_row_id)
    };
  }
}
```

### Complex Queries and Analytics
```javascript
// Advanced querying and analytics
class AnalyticsManager {
  constructor(db) {
    this.db = db;
  }
  
  async getUserStatistics() {
    const query = `
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN created_at >= datetime('now', '-30 days') THEN 1 END) as users_last_30_days,
        COUNT(CASE WHEN created_at >= datetime('now', '-7 days') THEN 1 END) as users_last_7_days,
        AVG(post_count) as avg_posts_per_user
      FROM (
        SELECT 
          u.id,
          u.created_at,
          COUNT(p.id) as post_count
        FROM users u
        LEFT JOIN posts p ON u.id = p.user_id
        GROUP BY u.id, u.created_at
      ) user_stats
    `;
    
    const result = await this.db.prepare(query).first();
    return result;
  }
  
  async getPostStatistics() {
    const query = `
      SELECT 
        COUNT(*) as total_posts,
        COUNT(CASE WHEN published = TRUE THEN 1 END) as published_posts,
        COUNT(CASE WHEN published = FALSE THEN 1 END) as draft_posts,
        COUNT(CASE WHEN created_at >= datetime('now', '-30 days') THEN 1 END) as posts_last_30_days,
        AVG(LENGTH(content)) as avg_content_length
      FROM posts
    `;
    
    const result = await this.db.prepare(query).first();
    return result;
  }
  
  async getTopAuthors(limit = 10) {
    const query = `
      SELECT 
        u.id,
        u.name,
        u.email,
        COUNT(p.id) as post_count,
        COUNT(CASE WHEN p.published = TRUE THEN 1 END) as published_count,
        AVG(LENGTH(p.content)) as avg_content_length
      FROM users u
      LEFT JOIN posts p ON u.id = p.user_id
      GROUP BY u.id, u.name, u.email
      HAVING post_count > 0
      ORDER BY post_count DESC
      LIMIT ?
    `;
    
    const result = await this.db.prepare(query).bind(limit).all();
    return result.results;
  }
  
  async getContentTrends(days = 30) {
    const query = `
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as posts_created,
        COUNT(CASE WHEN published = TRUE THEN 1 END) as posts_published,
        AVG(LENGTH(content)) as avg_content_length
      FROM posts
      WHERE created_at >= datetime('now', '-' || ? || ' days')
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    `;
    
    const result = await this.db.prepare(query).bind(days).all();
    return result.results;
  }
  
  async searchPosts(searchTerm, limit = 20, offset = 0) {
    const searchQuery = `%${searchTerm}%`;
    
    const query = `
      SELECT 
        p.*,
        u.name as author_name,
        u.email as author_email
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE (
        p.title LIKE ? OR 
        p.content LIKE ? OR
        u.name LIKE ?
      ) AND p.published = TRUE
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    const result = await this.db.prepare(query)
      .bind(searchQuery, searchQuery, searchQuery, limit, offset)
      .all();
    
    return result.results;
  }
  
  async getRelatedPosts(postId, limit = 5) {
    // Simple related posts based on common words in title
    const query = `
      WITH current_post AS (
        SELECT title FROM posts WHERE id = ?
      ),
      word_matches AS (
        SELECT 
          p.*,
          u.name as author_name,
          (
            LENGTH(p.title) - LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(
              UPPER(p.title), 
              UPPER(SUBSTR((SELECT title FROM current_post), 1, INSTR((SELECT title FROM current_post), ' ')-1)), ''
            ), 
              UPPER(SUBSTR((SELECT title FROM current_post), INSTR((SELECT title FROM current_post), ' ')+1, 
                INSTR((SELECT title FROM current_post || ' '), ' ', INSTR((SELECT title FROM current_post), ' ')+1) - INSTR((SELECT title FROM current_post), ' ')-1)), ''
            ), ' ', ''), ' ', ''))
          ) as similarity_score
        FROM posts p
        JOIN users u ON p.user_id = u.id
        WHERE p.id != ? AND p.published = TRUE
      )
      SELECT *
      FROM word_matches
      WHERE similarity_score > 0
      ORDER BY similarity_score DESC
      LIMIT ?
    `;
    
    const result = await this.db.prepare(query)
      .bind(postId, postId, limit)
      .all();
    
    return result.results;
  }
}
```

## Integration Patterns

### 1. API with Authentication

```javascript
// Complete API with user authentication
class UserAPI {
  constructor(db, jwtSecret) {
    this.db = new DatabaseManager(db);
    this.jwtSecret = jwtSecret;
  }
  
  async handleRequest(request) {
    const url = new URL(request.url);
    const method = request.method;
    
    try {
      // Public routes
      if (url.pathname === '/auth/register' && method === 'POST') {
        return this.register(request);
      }
      
      if (url.pathname === '/auth/login' && method === 'POST') {
        return this.login(request);
      }
      
      // Protected routes
      const user = await this.authenticateRequest(request);
      
      if (url.pathname === '/users/me' && method === 'GET') {
        return Response.json(user);
      }
      
      if (url.pathname === '/users/me' && method === 'PUT') {
        return this.updateProfile(request, user);
      }
      
      if (url.pathname === '/posts' && method === 'GET') {
        return this.getUserPosts(request, user);
      }
      
      if (url.pathname === '/posts' && method === 'POST') {
        return this.createPost(request, user);
      }
      
      const postMatch = url.pathname.match(/^\/posts\/(\d+)$/);
      if (postMatch) {
        const postId = parseInt(postMatch[1]);
        
        if (method === 'PUT') {
          return this.updatePost(request, user, postId);
        }
        
        if (method === 'DELETE') {
          return this.deletePost(request, user, postId);
        }
      }
      
      return new Response('Not found', { status: 404 });
    } catch (error) {
      console.error('API Error:', error);
      return Response.json({ error: error.message }, { status: 500 });
    }
  }
  
  async register(request) {
    const { name, email, password } = await request.json();
    
    if (!name || !email || !password) {
      return Response.json(
        { error: 'Name, email, and password are required' },
        { status: 400 }
      );
    }
    
    // Check if user already exists
    const existingUser = await this.db.getUserByEmail(email);
    if (existingUser) {
      return Response.json(
        { error: 'User with this email already exists' },
        { status: 409 }
      );
    }
    
    // Hash password (in production, use proper hashing)
    const hashedPassword = await this.hashPassword(password);
    
    // Create user
    const user = await this.db.createUser({
      name,
      email,
      password_hash: hashedPassword
    });
    
    // Generate JWT token
    const token = await this.generateJWT({ userId: user.id, email: user.email });
    
    return Response.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        created_at: user.created_at
      },
      token
    }, { status: 201 });
  }
  
  async login(request) {
    const { email, password } = await request.json();
    
    if (!email || !password) {
      return Response.json(
        { error: 'Email and password are required' },
        { status: 400 }
      );
    }
    
    // Get user by email
    const user = await this.db.getUserByEmail(email);
    if (!user) {
      return Response.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }
    
    // Verify password
    const isValidPassword = await this.verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      return Response.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      );
    }
    
    // Generate JWT token
    const token = await this.generateJWT({ userId: user.id, email: user.email });
    
    return Response.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        created_at: user.created_at
      },
      token
    });
  }
  
  async createPost(request, user) {
    const { title, content, published = false } = await request.json();
    
    if (!title || !content) {
      return Response.json(
        { error: 'Title and content are required' },
        { status: 400 }
      );
    }
    
    const post = await this.db.createPost({
      user_id: user.id,
      title,
      content,
      published
    });
    
    return Response.json(post, { status: 201 });
  }
  
  async authenticateRequest(request) {
    const authHeader = request.headers.get('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new Error('Authentication required');
    }
    
    const token = authHeader.slice(7);
    const payload = await this.verifyJWT(token);
    
    const user = await this.db.getUser(payload.userId);
    return user;
  }
  
  async hashPassword(password) {
    // In production, use a proper hashing library like bcrypt
    const encoder = new TextEncoder();
    const data = encoder.encode(password + this.jwtSecret);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }
  
  async verifyPassword(password, hash) {
    const hashedPassword = await this.hashPassword(password);
    return hashedPassword === hash;
  }
  
  async generateJWT(payload) {
    // Simple JWT implementation - use a proper library in production
    const header = { alg: 'HS256', typ: 'JWT' };
    const data = {
      ...payload,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24 hours
    };
    
    const encodedHeader = btoa(JSON.stringify(header));
    const encodedPayload = btoa(JSON.stringify(data));
    const signature = await this.sign(`${encodedHeader}.${encodedPayload}`);
    
    return `${encodedHeader}.${encodedPayload}.${signature}`;
  }
  
  async verifyJWT(token) {
    const [encodedHeader, encodedPayload, signature] = token.split('.');
    
    const expectedSignature = await this.sign(`${encodedHeader}.${encodedPayload}`);
    
    if (signature !== expectedSignature) {
      throw new Error('Invalid token signature');
    }
    
    const payload = JSON.parse(atob(encodedPayload));
    
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      throw new Error('Token expired');
    }
    
    return payload;
  }
  
  async sign(data) {
    const encoder = new TextEncoder();
    const keyData = encoder.encode(this.jwtSecret);
    const dataToSign = encoder.encode(data);
    
    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );
    
    const signature = await crypto.subtle.sign('HMAC', key, dataToSign);
    const signatureArray = Array.from(new Uint8Array(signature));
    return signatureArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }
}
```

### 2. Data Migration and Schema Management

```javascript
// Database migration system
class MigrationManager {
  constructor(db) {
    this.db = db;
  }
  
  async initializeMigrations() {
    // Create migrations table if it doesn't exist
    await this.db.prepare(`
      CREATE TABLE IF NOT EXISTS migrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        executed_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
  }
  
  async runMigration(name, sql) {
    // Check if migration has already been run
    const existing = await this.db.prepare(
      'SELECT name FROM migrations WHERE name = ?'
    ).bind(name).first();
    
    if (existing) {
      console.log(`Migration ${name} already executed`);
      return;
    }
    
    try {
      // Execute migration SQL
      await this.db.exec(sql);
      
      // Record successful migration
      await this.db.prepare(
        'INSERT INTO migrations (name) VALUES (?)'
      ).bind(name).run();
      
      console.log(`Migration ${name} executed successfully`);
    } catch (error) {
      console.error(`Migration ${name} failed:`, error);
      throw error;
    }
  }
  
  async runAllMigrations() {
    await this.initializeMigrations();
    
    const migrations = [
      {
        name: '001_create_users_table',
        sql: `
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            bio TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
          );
          
          CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        `
      },
      {
        name: '002_create_posts_table',
        sql: `
          CREATE TABLE IF NOT EXISTS posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            content TEXT,
            published BOOLEAN DEFAULT FALSE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          );
          
          CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
          CREATE INDEX IF NOT EXISTS idx_posts_published ON posts(published);
        `
      },
      {
        name: '003_add_user_avatar',
        sql: `
          ALTER TABLE users ADD COLUMN avatar_url TEXT;
        `
      },
      {
        name: '004_create_categories_table',
        sql: `
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            description TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          );
          
          ALTER TABLE posts ADD COLUMN category_id INTEGER REFERENCES categories(id);
          CREATE INDEX IF NOT EXISTS idx_posts_category_id ON posts(category_id);
        `
      }
    ];
    
    for (const migration of migrations) {
      await this.runMigration(migration.name, migration.sql);
    }
  }
  
  async getMigrationStatus() {
    const executed = await this.db.prepare(
      'SELECT name, executed_at FROM migrations ORDER BY executed_at'
    ).all();
    
    return executed.results;
  }
}
```

## Performance Optimization

### Query Optimization
- Use appropriate indexes for frequently queried columns
- Optimize JOIN operations and query structure
- Use LIMIT and OFFSET for pagination
- Implement query result caching

### Batch Operations
- Use transactions for multiple related operations
- Implement bulk insert/update operations
- Process operations in appropriately sized batches
- Monitor operation performance

### Connection Management
- Reuse database connections in Workers
- Implement proper error handling and retries
- Monitor connection pool usage
- Optimize for read/write patterns

## Best Practices

### Schema Design
- Design normalized schemas to avoid data duplication
- Use appropriate data types and constraints
- Implement proper foreign key relationships
- Plan for future schema evolution

### Security
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization
- Validate all input data
- Use HTTPS for all database operations

### Monitoring
- Track query performance and slow queries
- Monitor database size and growth
- Set up alerting for errors and performance issues
- Analyze usage patterns

### Backup and Recovery
- Implement regular database backups
- Test restoration procedures
- Plan for disaster recovery scenarios
- Monitor backup integrity

## Common Use Cases

1. **User Management Systems** - Authentication, profiles, permissions
2. **Content Management** - Blogs, articles, media metadata
3. **E-commerce** - Products, orders, inventory tracking
4. **Analytics** - Event tracking, user behavior, metrics
5. **Configuration Storage** - Application settings, feature flags
6. **Session Management** - User sessions, temporary data

D1 provides a familiar SQL interface with global distribution and automatic scaling, making it ideal for applications requiring structured data storage with strong consistency guarantees.
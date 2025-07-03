# Cloudflare KV - Global Key-Value Storage

## Overview

Cloudflare KV is a global, low-latency key-value data store that provides eventual consistency across Cloudflare's edge network. Perfect for caching, session storage, configuration management, and any use case requiring fast read access to relatively static data.

## Quick Start

### Basic Setup
```javascript
// Workers KV integration
export default {
  async fetch(request, env) {
    // Store data
    await env.MY_KV.put('user:123', JSON.stringify({
      name: 'John Doe',
      email: 'john@example.com',
      lastLogin: Date.now()
    }));
    
    // Retrieve data
    const userData = await env.MY_KV.get('user:123', 'json');
    
    return Response.json(userData);
  }
};
```

### Configuration
```toml
# wrangler.toml
[[kv_namespaces]]
binding = "MY_KV"
id = "your-kv-namespace-id"
preview_id = "your-preview-kv-namespace-id"

[[kv_namespaces]]
binding = "CACHE"
id = "your-cache-namespace-id"

[[kv_namespaces]]
binding = "SESSIONS"
id = "your-sessions-namespace-id"
```

## Core Concepts

### Data Types and Operations
KV supports various data types with automatic serialization:

```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.searchParams.get('key');
    const value = url.searchParams.get('value');
    
    switch (request.method) {
      case 'GET':
        // Different return types
        const text = await env.MY_KV.get(key); // Returns string
        const json = await env.MY_KV.get(key, 'json'); // Parses JSON
        const buffer = await env.MY_KV.get(key, 'arrayBuffer'); // Binary data
        const stream = await env.MY_KV.get(key, 'stream'); // Streaming
        
        return Response.json({ text, json });
        
      case 'PUT':
        // Different value types
        await env.MY_KV.put(key, value); // String
        await env.MY_KV.put(`${key}:json`, JSON.stringify({ data: value })); // JSON
        await env.MY_KV.put(`${key}:buffer`, new ArrayBuffer(8)); // Binary
        
        // With metadata and expiration
        await env.MY_KV.put(key, value, {
          expirationTtl: 3600, // Expires in 1 hour
          metadata: { 
            type: 'user_data',
            created: Date.now(),
            version: '1.0'
          }
        });
        
        return new Response('Stored successfully');
        
      case 'DELETE':
        await env.MY_KV.delete(key);
        return new Response('Deleted successfully');
        
      case 'POST':
        // List keys with filtering
        const list = await env.MY_KV.list({
          prefix: url.searchParams.get('prefix'),
          limit: parseInt(url.searchParams.get('limit') || '10'),
          cursor: url.searchParams.get('cursor')
        });
        
        return Response.json(list);
    }
    
    return new Response('Method not allowed', { status: 405 });
  }
};
```

### Metadata and Expiration
```javascript
// Advanced KV operations with metadata
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    if (url.pathname === '/cache/set') {
      const { key, value, ttl, tags } = await request.json();
      
      await env.CACHE.put(key, JSON.stringify(value), {
        expirationTtl: ttl || 3600,
        metadata: {
          tags: tags || [],
          cached_at: Date.now(),
          expires_at: Date.now() + (ttl || 3600) * 1000,
          content_type: 'application/json'
        }
      });
      
      return Response.json({ cached: true, key, ttl });
    }
    
    if (url.pathname === '/cache/get') {
      const key = url.searchParams.get('key');
      
      const { value, metadata } = await env.CACHE.getWithMetadata(key, 'json');
      
      if (!value) {
        return new Response('Not found', { status: 404 });
      }
      
      return Response.json({
        data: value,
        metadata,
        age: metadata ? Math.floor((Date.now() - metadata.cached_at) / 1000) : null
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

## Integration Patterns

### 1. Application Caching Layer

```javascript
// Intelligent caching with fallback to database
class CacheManager {
  constructor(kvNamespace, database) {
    this.kv = kvNamespace;
    this.db = database;
    this.defaultTTL = 3600; // 1 hour
  }
  
  async get(key, fetcher, options = {}) {
    const cacheKey = this.buildCacheKey(key);
    const ttl = options.ttl || this.defaultTTL;
    
    // Try cache first
    const cached = await this.kv.getWithMetadata(cacheKey, 'json');
    
    if (cached.value) {
      // Check if cache is still fresh
      const age = Date.now() - (cached.metadata?.cached_at || 0);
      const maxAge = (cached.metadata?.ttl || this.defaultTTL) * 1000;
      
      if (age < maxAge) {
        return {
          data: cached.value,
          source: 'cache',
          age: Math.floor(age / 1000)
        };
      }
    }
    
    // Cache miss or expired - fetch fresh data
    try {
      const freshData = await fetcher();
      
      // Cache the fresh data
      await this.kv.put(cacheKey, JSON.stringify(freshData), {
        expirationTtl: ttl,
        metadata: {
          cached_at: Date.now(),
          ttl,
          key: key
        }
      });
      
      return {
        data: freshData,
        source: 'database',
        age: 0
      };
    } catch (error) {
      // Return stale cache if available on error
      if (cached.value) {
        return {
          data: cached.value,
          source: 'stale_cache',
          age: Math.floor((Date.now() - cached.metadata.cached_at) / 1000),
          warning: 'Serving stale data due to fetch error'
        };
      }
      throw error;
    }
  }
  
  async set(key, value, ttl = this.defaultTTL) {
    const cacheKey = this.buildCacheKey(key);
    
    await this.kv.put(cacheKey, JSON.stringify(value), {
      expirationTtl: ttl,
      metadata: {
        cached_at: Date.now(),
        ttl,
        key: key
      }
    });
  }
  
  async invalidate(key) {
    const cacheKey = this.buildCacheKey(key);
    await this.kv.delete(cacheKey);
  }
  
  async invalidatePattern(pattern) {
    const list = await this.kv.list({ prefix: this.buildCacheKey(pattern) });
    
    const deletePromises = list.keys.map(keyObj => 
      this.kv.delete(keyObj.name)
    );
    
    await Promise.all(deletePromises);
  }
  
  buildCacheKey(key) {
    return `cache:${key}`;
  }
}

// Usage in Workers
export default {
  async fetch(request, env) {
    const cache = new CacheManager(env.CACHE, env.DB);
    const url = new URL(request.url);
    
    if (url.pathname === '/api/users') {
      const users = await cache.get('users:all', async () => {
        const { results } = await env.DB.prepare('SELECT * FROM users').all();
        return results;
      }, { ttl: 1800 }); // Cache for 30 minutes
      
      return Response.json(users);
    }
    
    if (url.pathname.startsWith('/api/users/')) {
      const userId = url.pathname.split('/')[3];
      
      const user = await cache.get(`user:${userId}`, async () => {
        const result = await env.DB.prepare('SELECT * FROM users WHERE id = ?')
          .bind(userId)
          .first();
        
        if (!result) {
          throw new Error('User not found');
        }
        
        return result;
      }, { ttl: 3600 }); // Cache for 1 hour
      
      return Response.json(user);
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

### 2. Session Management

```javascript
// Robust session management with KV
class SessionManager {
  constructor(kvNamespace, options = {}) {
    this.kv = kvNamespace;
    this.sessionTTL = options.sessionTTL || 86400; // 24 hours
    this.cookieName = options.cookieName || 'session_id';
    this.secure = options.secure !== false; // Default to secure
  }
  
  async createSession(userId, userData = {}) {
    const sessionId = crypto.randomUUID();
    const sessionData = {
      userId,
      ...userData,
      createdAt: Date.now(),
      lastAccessed: Date.now(),
      ipAddress: null, // Set from request
      userAgent: null  // Set from request
    };
    
    await this.kv.put(`session:${sessionId}`, JSON.stringify(sessionData), {
      expirationTtl: this.sessionTTL,
      metadata: {
        userId,
        createdAt: sessionData.createdAt
      }
    });
    
    return sessionId;
  }
  
  async getSession(sessionId) {
    if (!sessionId) return null;
    
    const sessionData = await this.kv.get(`session:${sessionId}`, 'json');
    
    if (!sessionData) return null;
    
    // Update last accessed time
    sessionData.lastAccessed = Date.now();
    await this.kv.put(`session:${sessionId}`, JSON.stringify(sessionData), {
      expirationTtl: this.sessionTTL,
      metadata: {
        userId: sessionData.userId,
        createdAt: sessionData.createdAt
      }
    });
    
    return sessionData;
  }
  
  async updateSession(sessionId, updates) {
    const sessionData = await this.getSession(sessionId);
    
    if (!sessionData) {
      throw new Error('Session not found');
    }
    
    const updatedData = {
      ...sessionData,
      ...updates,
      lastAccessed: Date.now()
    };
    
    await this.kv.put(`session:${sessionId}`, JSON.stringify(updatedData), {
      expirationTtl: this.sessionTTL,
      metadata: {
        userId: updatedData.userId,
        createdAt: updatedData.createdAt
      }
    });
    
    return updatedData;
  }
  
  async destroySession(sessionId) {
    await this.kv.delete(`session:${sessionId}`);
  }
  
  async destroyAllUserSessions(userId) {
    // List all sessions for the user
    const list = await this.kv.list({ prefix: 'session:' });
    
    const deletePromises = [];
    
    for (const key of list.keys) {
      if (key.metadata?.userId === userId) {
        deletePromises.push(this.kv.delete(key.name));
      }
    }
    
    await Promise.all(deletePromises);
  }
  
  getSessionCookie(sessionId) {
    const secure = this.secure ? '; Secure' : '';
    const sameSite = '; SameSite=Strict';
    const httpOnly = '; HttpOnly';
    const maxAge = `; Max-Age=${this.sessionTTL}`;
    
    return `${this.cookieName}=${sessionId}; Path=/${secure}${sameSite}${httpOnly}${maxAge}`;
  }
  
  clearSessionCookie() {
    return `${this.cookieName}=; Path=/; Max-Age=0`;
  }
  
  extractSessionId(request) {
    const cookieHeader = request.headers.get('Cookie');
    if (!cookieHeader) return null;
    
    const cookies = cookieHeader.split(';');
    for (const cookie of cookies) {
      const [name, value] = cookie.trim().split('=');
      if (name === this.cookieName) {
        return value;
      }
    }
    
    return null;
  }
}

// Usage in authentication system
export default {
  async fetch(request, env) {
    const sessions = new SessionManager(env.SESSIONS);
    const url = new URL(request.url);
    
    if (url.pathname === '/auth/login' && request.method === 'POST') {
      const { email, password } = await request.json();
      
      // Validate credentials (implement your auth logic)
      const user = await validateCredentials(email, password, env);
      
      if (!user) {
        return new Response('Invalid credentials', { status: 401 });
      }
      
      // Create session
      const sessionId = await sessions.createSession(user.id, {
        email: user.email,
        role: user.role,
        ipAddress: request.headers.get('CF-Connecting-IP'),
        userAgent: request.headers.get('User-Agent')
      });
      
      const response = Response.json({
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        }
      });
      
      response.headers.set('Set-Cookie', sessions.getSessionCookie(sessionId));
      
      return response;
    }
    
    if (url.pathname === '/auth/logout' && request.method === 'POST') {
      const sessionId = sessions.extractSessionId(request);
      
      if (sessionId) {
        await sessions.destroySession(sessionId);
      }
      
      const response = Response.json({ message: 'Logged out' });
      response.headers.set('Set-Cookie', sessions.clearSessionCookie());
      
      return response;
    }
    
    if (url.pathname === '/auth/me') {
      const sessionId = sessions.extractSessionId(request);
      const sessionData = await sessions.getSession(sessionId);
      
      if (!sessionData) {
        return new Response('Unauthorized', { status: 401 });
      }
      
      return Response.json({
        user: {
          id: sessionData.userId,
          email: sessionData.email,
          role: sessionData.role
        },
        session: {
          createdAt: sessionData.createdAt,
          lastAccessed: sessionData.lastAccessed
        }
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

### 3. Configuration Management & Feature Flags

```javascript
// Dynamic configuration and feature flag system
class ConfigManager {
  constructor(kvNamespace) {
    this.kv = kvNamespace;
    this.localCache = new Map();
    this.cacheTimeout = 60000; // 1 minute local cache
  }
  
  async getConfig(key, defaultValue = null) {
    // Check local cache first
    const cached = this.localCache.get(key);
    if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
      return cached.value;
    }
    
    // Fetch from KV
    const value = await this.kv.get(`config:${key}`, 'json');
    const result = value !== null ? value : defaultValue;
    
    // Cache locally
    this.localCache.set(key, {
      value: result,
      timestamp: Date.now()
    });
    
    return result;
  }
  
  async setConfig(key, value, metadata = {}) {
    await this.kv.put(`config:${key}`, JSON.stringify(value), {
      metadata: {
        ...metadata,
        updatedAt: Date.now(),
        type: 'config'
      }
    });
    
    // Clear local cache
    this.localCache.delete(key);
  }
  
  async getFeatureFlag(flagName, userId = null, defaultValue = false) {
    const flag = await this.getConfig(`feature_flag:${flagName}`);
    
    if (!flag) return defaultValue;
    
    // Simple percentage rollout
    if (flag.percentage !== undefined) {
      if (userId) {
        // Consistent hash-based rollout
        const hash = await this.hashUserId(userId);
        return hash < flag.percentage;
      } else {
        // Random rollout for anonymous users
        return Math.random() * 100 < flag.percentage;
      }
    }
    
    // User-specific flags
    if (flag.users && userId) {
      return flag.users.includes(userId);
    }
    
    // Global flag
    return flag.enabled || defaultValue;
  }
  
  async setFeatureFlag(flagName, config) {
    await this.setConfig(`feature_flag:${flagName}`, config, {
      type: 'feature_flag'
    });
  }
  
  async getAllConfigs(prefix = '') {
    const list = await this.kv.list({ prefix: `config:${prefix}` });
    const configs = {};
    
    for (const key of list.keys) {
      const configKey = key.name.replace('config:', '');
      configs[configKey] = await this.kv.get(key.name, 'json');
    }
    
    return configs;
  }
  
  async hashUserId(userId) {
    const encoder = new TextEncoder();
    const data = encoder.encode(userId.toString());
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = new Uint8Array(hashBuffer);
    
    // Convert to percentage (0-100)
    return (hashArray[0] / 255) * 100;
  }
}

// Usage for A/B testing and feature flags
export default {
  async fetch(request, env) {
    const config = new ConfigManager(env.CONFIG);
    const url = new URL(request.url);
    
    // Get user from session or request
    const userId = await getUserIdFromRequest(request, env);
    
    if (url.pathname === '/api/features') {
      // Return feature flags for current user
      const features = {
        newDesign: await config.getFeatureFlag('new_design', userId),
        betaFeatures: await config.getFeatureFlag('beta_features', userId),
        advancedSearch: await config.getFeatureFlag('advanced_search', userId)
      };
      
      return Response.json({ features });
    }
    
    if (url.pathname === '/api/config') {
      // Return public configuration
      const publicConfig = {
        apiVersion: await config.getConfig('api_version', '1.0'),
        maintenanceMode: await config.getConfig('maintenance_mode', false),
        supportEmail: await config.getConfig('support_email', 'support@example.com'),
        maxUploadSize: await config.getConfig('max_upload_size', 10485760) // 10MB
      };
      
      return Response.json(publicConfig);
    }
    
    if (url.pathname === '/admin/config' && request.method === 'POST') {
      // Admin endpoint to update configuration
      const { key, value } = await request.json();
      
      // Validate admin permissions (implement your auth logic)
      const isAdmin = await validateAdminPermissions(request, env);
      if (!isAdmin) {
        return new Response('Forbidden', { status: 403 });
      }
      
      await config.setConfig(key, value);
      
      return Response.json({ message: 'Configuration updated', key, value });
    }
    
    // Feature flag example usage
    if (url.pathname === '/app') {
      const useNewDesign = await config.getFeatureFlag('new_design', userId);
      
      if (useNewDesign) {
        return new Response(await getNewDesignHTML());
      } else {
        return new Response(await getClassicDesignHTML());
      }
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

## Advanced Features

### 1. Multi-Region Data Synchronization

```javascript
// Synchronize data across regions with conflict resolution
class MultiRegionManager {
  constructor(kvNamespace) {
    this.kv = kvNamespace;
  }
  
  async setWithSync(key, value, metadata = {}) {
    const syncData = {
      value,
      timestamp: Date.now(),
      region: process.env.CF_REGION || 'unknown',
      version: this.generateVersion(),
      ...metadata
    };
    
    await this.kv.put(key, JSON.stringify(syncData), {
      metadata: {
        type: 'synced_data',
        timestamp: syncData.timestamp,
        region: syncData.region,
        version: syncData.version
      }
    });
    
    // Trigger sync to other regions (implement based on your needs)
    await this.triggerRegionSync(key, syncData);
    
    return syncData;
  }
  
  async getWithSync(key) {
    const data = await this.kv.get(key, 'json');
    
    if (!data) return null;
    
    // Check if data needs refresh from other regions
    const age = Date.now() - data.timestamp;
    const maxAge = 300000; // 5 minutes
    
    if (age > maxAge) {
      // Try to refresh from primary region
      const freshData = await this.fetchFromPrimaryRegion(key);
      if (freshData && freshData.timestamp > data.timestamp) {
        await this.kv.put(key, JSON.stringify(freshData), {
          metadata: {
            type: 'synced_data',
            timestamp: freshData.timestamp,
            region: freshData.region,
            version: freshData.version
          }
        });
        return freshData;
      }
    }
    
    return data;
  }
  
  async resolveConflicts(key, localData, remoteData) {
    // Last-write-wins conflict resolution
    if (remoteData.timestamp > localData.timestamp) {
      await this.kv.put(key, JSON.stringify(remoteData), {
        metadata: {
          type: 'synced_data',
          timestamp: remoteData.timestamp,
          region: remoteData.region,
          version: remoteData.version
        }
      });
      return remoteData;
    }
    
    return localData;
  }
  
  generateVersion() {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
  
  async triggerRegionSync(key, data) {
    // Implementation depends on your multi-region setup
    // Could use Durable Objects, external APIs, or message queues
    console.log(`Syncing ${key} to other regions:`, data);
  }
  
  async fetchFromPrimaryRegion(key) {
    // Implementation to fetch from primary region
    // This is a placeholder - implement based on your architecture
    return null;
  }
}
```

### 2. Analytics and Metrics Storage

```javascript
// Store and aggregate analytics data in KV
class AnalyticsManager {
  constructor(kvNamespace) {
    this.kv = kvNamespace;
  }
  
  async recordEvent(eventType, eventData, userId = null) {
    const timestamp = Date.now();
    const eventId = crypto.randomUUID();
    
    const event = {
      id: eventId,
      type: eventType,
      data: eventData,
      userId,
      timestamp,
      date: new Date().toISOString().split('T')[0], // YYYY-MM-DD
      hour: new Date().getHours()
    };
    
    // Store individual event
    await this.kv.put(`event:${eventId}`, JSON.stringify(event), {
      expirationTtl: 2592000, // 30 days
      metadata: {
        type: 'event',
        eventType,
        date: event.date,
        hour: event.hour
      }
    });
    
    // Update hourly aggregates
    await this.updateHourlyAggregate(eventType, event.date, event.hour);
    
    // Update daily aggregates
    await this.updateDailyAggregate(eventType, event.date);
    
    return eventId;
  }
  
  async updateHourlyAggregate(eventType, date, hour) {
    const key = `aggregate:hourly:${eventType}:${date}:${hour}`;
    
    const current = await this.kv.get(key, 'json') || { count: 0, events: [] };
    current.count++;
    current.lastUpdated = Date.now();
    
    await this.kv.put(key, JSON.stringify(current), {
      expirationTtl: 604800, // 7 days
      metadata: {
        type: 'hourly_aggregate',
        eventType,
        date,
        hour
      }
    });
  }
  
  async updateDailyAggregate(eventType, date) {
    const key = `aggregate:daily:${eventType}:${date}`;
    
    const current = await this.kv.get(key, 'json') || { count: 0 };
    current.count++;
    current.lastUpdated = Date.now();
    
    await this.kv.put(key, JSON.stringify(current), {
      expirationTtl: 2592000, // 30 days
      metadata: {
        type: 'daily_aggregate',
        eventType,
        date
      }
    });
  }
  
  async getHourlyStats(eventType, date) {
    const stats = [];
    
    for (let hour = 0; hour < 24; hour++) {
      const key = `aggregate:hourly:${eventType}:${date}:${hour}`;
      const data = await this.kv.get(key, 'json');
      
      stats.push({
        hour,
        count: data?.count || 0
      });
    }
    
    return stats;
  }
  
  async getDailyStats(eventType, days = 30) {
    const stats = [];
    const today = new Date();
    
    for (let i = 0; i < days; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      const key = `aggregate:daily:${eventType}:${dateStr}`;
      const data = await this.kv.get(key, 'json');
      
      stats.unshift({
        date: dateStr,
        count: data?.count || 0
      });
    }
    
    return stats;
  }
}

// Usage in analytics endpoint
export default {
  async fetch(request, env) {
    const analytics = new AnalyticsManager(env.ANALYTICS);
    const url = new URL(request.url);
    
    if (url.pathname === '/api/analytics/track' && request.method === 'POST') {
      const { event, data } = await request.json();
      const userId = await getUserIdFromRequest(request, env);
      
      const eventId = await analytics.recordEvent(event, {
        ...data,
        userAgent: request.headers.get('User-Agent'),
        ip: request.headers.get('CF-Connecting-IP'),
        country: request.cf?.country,
        referer: request.headers.get('Referer')
      }, userId);
      
      return Response.json({ eventId, tracked: true });
    }
    
    if (url.pathname === '/api/analytics/stats') {
      const eventType = url.searchParams.get('event') || 'page_view';
      const type = url.searchParams.get('type') || 'daily';
      const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0];
      
      let stats;
      if (type === 'hourly') {
        stats = await analytics.getHourlyStats(eventType, date);
      } else {
        const days = parseInt(url.searchParams.get('days') || '30');
        stats = await analytics.getDailyStats(eventType, days);
      }
      
      return Response.json({ eventType, type, stats });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

## Performance Optimization

### 1. Bulk Operations

```javascript
// Efficient bulk operations for KV
class BulkKVManager {
  constructor(kvNamespace, options = {}) {
    this.kv = kvNamespace;
    this.batchSize = options.batchSize || 50;
    this.concurrency = options.concurrency || 10;
  }
  
  async bulkSet(items, options = {}) {
    const chunks = this.chunkArray(items, this.batchSize);
    const results = [];
    
    // Process chunks with controlled concurrency
    for (let i = 0; i < chunks.length; i += this.concurrency) {
      const batch = chunks.slice(i, i + this.concurrency);
      
      const batchPromises = batch.map(chunk =>
        this.processBatch(chunk, 'set', options)
      );
      
      const batchResults = await Promise.allSettled(batchPromises);
      results.push(...batchResults);
    }
    
    return this.summarizeResults(results);
  }
  
  async bulkGet(keys) {
    const chunks = this.chunkArray(keys, this.batchSize);
    const results = [];
    
    for (let i = 0; i < chunks.length; i += this.concurrency) {
      const batch = chunks.slice(i, i + this.concurrency);
      
      const batchPromises = batch.map(chunk =>
        this.processBatch(chunk, 'get')
      );
      
      const batchResults = await Promise.allSettled(batchPromises);
      results.push(...batchResults);
    }
    
    return this.flattenGetResults(results);
  }
  
  async bulkDelete(keys) {
    const chunks = this.chunkArray(keys, this.batchSize);
    const results = [];
    
    for (let i = 0; i < chunks.length; i += this.concurrency) {
      const batch = chunks.slice(i, i + this.concurrency);
      
      const batchPromises = batch.map(chunk =>
        this.processBatch(chunk, 'delete')
      );
      
      const batchResults = await Promise.allSettled(batchPromises);
      results.push(...batchResults);
    }
    
    return this.summarizeResults(results);
  }
  
  async processBatch(items, operation, options = {}) {
    const promises = items.map(item => {
      switch (operation) {
        case 'set':
          return this.kv.put(item.key, item.value, item.options || options);
        case 'get':
          return this.kv.get(item, 'json');
        case 'delete':
          return this.kv.delete(item);
        default:
          throw new Error(`Unknown operation: ${operation}`);
      }
    });
    
    return Promise.allSettled(promises);
  }
  
  chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }
  
  summarizeResults(results) {
    const summary = {
      total: 0,
      successful: 0,
      failed: 0,
      errors: []
    };
    
    results.forEach(batchResult => {
      if (batchResult.status === 'fulfilled') {
        batchResult.value.forEach(itemResult => {
          summary.total++;
          if (itemResult.status === 'fulfilled') {
            summary.successful++;
          } else {
            summary.failed++;
            summary.errors.push(itemResult.reason);
          }
        });
      } else {
        summary.failed++;
        summary.errors.push(batchResult.reason);
      }
    });
    
    return summary;
  }
  
  flattenGetResults(results) {
    const data = {};
    
    results.forEach(batchResult => {
      if (batchResult.status === 'fulfilled') {
        batchResult.value.forEach((itemResult, index) => {
          if (itemResult.status === 'fulfilled') {
            data[`item_${index}`] = itemResult.value;
          }
        });
      }
    });
    
    return data;
  }
}
```

### 2. Smart Caching Strategies

```javascript
// Advanced caching with cache warming and invalidation
class SmartCache {
  constructor(kvNamespace, options = {}) {
    this.kv = kvNamespace;
    this.defaultTTL = options.defaultTTL || 3600;
    this.warmupThreshold = options.warmupThreshold || 300; // 5 minutes before expiry
  }
  
  async get(key, fetcher, options = {}) {
    const cacheKey = `smart:${key}`;
    const { value, metadata } = await this.kv.getWithMetadata(cacheKey, 'json');
    
    if (value && metadata) {
      const age = Date.now() - metadata.cached_at;
      const ttl = metadata.ttl * 1000;
      
      // If cache is fresh, return it
      if (age < ttl) {
        // Check if we should warm up the cache
        if (ttl - age < this.warmupThreshold * 1000) {
          // Warm up in background
          this.warmupCache(key, fetcher, options);
        }
        
        return {
          data: value,
          source: 'cache',
          age: Math.floor(age / 1000)
        };
      }
    }
    
    // Cache miss or expired
    return this.fetchAndCache(key, fetcher, options);
  }
  
  async fetchAndCache(key, fetcher, options = {}) {
    const cacheKey = `smart:${key}`;
    const ttl = options.ttl || this.defaultTTL;
    
    try {
      const data = await fetcher();
      
      await this.kv.put(cacheKey, JSON.stringify(data), {
        expirationTtl: ttl,
        metadata: {
          cached_at: Date.now(),
          ttl,
          key,
          warmup_count: 0
        }
      });
      
      return {
        data,
        source: 'database',
        age: 0
      };
    } catch (error) {
      // Return stale cache if available
      const { value, metadata } = await this.kv.getWithMetadata(cacheKey, 'json');
      if (value) {
        return {
          data: value,
          source: 'stale_cache',
          age: Math.floor((Date.now() - metadata.cached_at) / 1000),
          warning: 'Serving stale data due to fetch error'
        };
      }
      throw error;
    }
  }
  
  async warmupCache(key, fetcher, options = {}) {
    // Don't await - run in background
    try {
      const cacheKey = `smart:${key}`;
      const { metadata } = await this.kv.getWithMetadata(cacheKey);
      
      if (metadata) {
        const warmupCount = (metadata.warmup_count || 0) + 1;
        
        const data = await fetcher();
        const ttl = options.ttl || this.defaultTTL;
        
        await this.kv.put(cacheKey, JSON.stringify(data), {
          expirationTtl: ttl,
          metadata: {
            cached_at: Date.now(),
            ttl,
            key,
            warmup_count: warmupCount
          }
        });
        
        console.log(`Cache warmed up for ${key}, count: ${warmupCount}`);
      }
    } catch (error) {
      console.error(`Cache warmup failed for ${key}:`, error);
    }
  }
  
  async invalidate(key) {
    await this.kv.delete(`smart:${key}`);
  }
  
  async invalidatePattern(pattern) {
    const list = await this.kv.list({ prefix: `smart:${pattern}` });
    
    const deletePromises = list.keys.map(keyObj => 
      this.kv.delete(keyObj.name)
    );
    
    await Promise.all(deletePromises);
  }
}
```

## Best Practices

### Data Modeling
- Use consistent key naming conventions
- Implement proper data versioning
- Design for eventual consistency
- Use metadata effectively

### Performance
- Batch operations when possible
- Implement local caching for frequently accessed data
- Use appropriate TTL values
- Consider geographic distribution patterns

### Cost Optimization
- Set appropriate expiration times
- Clean up unused keys regularly
- Use metadata to track usage patterns
- Implement data lifecycle policies

### Security
- Don't store sensitive data without encryption
- Use proper access controls
- Validate all input data
- Implement rate limiting for write operations

## Common Use Cases

1. **Application Caching** - Database query results and computed data
2. **Session Storage** - User sessions and authentication tokens
3. **Configuration Management** - Application settings and feature flags
4. **Rate Limiting** - Request counters and throttling data
5. **Analytics** - Event tracking and metrics aggregation
6. **Content Delivery** - Static content and localization data

KV provides the perfect balance of performance, simplicity, and global reach for web applications requiring fast, distributed data access with eventual consistency guarantees.
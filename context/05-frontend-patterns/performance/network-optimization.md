# Network Optimization

Strategies and techniques for optimizing network performance in web applications.

## Data Fetching Strategies

```javascript
// Service Worker for caching
// sw.js
const CACHE_NAME = 'app-cache-v1'
const urlsToCache = [
  '/',
  '/static/css/main.css',
  '/static/js/main.js',
  '/api/critical-data'
]

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  )
})

self.addEventListener('fetch', (event) => {
  // Cache-first strategy for static assets
  if (event.request.url.includes('/static/')) {
    event.respondWith(
      caches.match(event.request)
        .then((response) => response || fetch(event.request))
    )
    return
  }
  
  // Network-first strategy for API calls
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          // Clone and cache successful responses
          if (response.status === 200) {
            const responseClone = response.clone()
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseClone)
            })
          }
          return response
        })
        .catch(() => {
          // Fallback to cache on network error
          return caches.match(event.request)
        })
    )
  }
})

// Request optimization with batching
class RequestBatcher {
  constructor(batchSize = 10, delay = 100) {
    this.batchSize = batchSize
    this.delay = delay
    this.queue = []
    this.timeoutId = null
  }
  
  add(request) {
    return new Promise((resolve, reject) => {
      this.queue.push({ request, resolve, reject })
      
      if (this.queue.length >= this.batchSize) {
        this.flush()
      } else if (!this.timeoutId) {
        this.timeoutId = setTimeout(() => this.flush(), this.delay)
      }
    })
  }
  
  async flush() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }
    
    const batch = this.queue.splice(0, this.batchSize)
    if (batch.length === 0) return
    
    try {
      const requests = batch.map(({ request }) => request)
      const responses = await this.executeBatch(requests)
      
      batch.forEach(({ resolve }, index) => {
        resolve(responses[index])
      })
    } catch (error) {
      batch.forEach(({ reject }) => {
        reject(error)
      })
    }
  }
  
  async executeBatch(requests) {
    // Send batched request to server
    const response = await fetch('/api/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requests })
    })
    
    return response.json()
  }
}

const batcher = new RequestBatcher()

// Usage
async function fetchUser(id) {
  return batcher.add({ type: 'user', id })
}

// Request deduplication
class RequestDeduplicator {
  constructor() {
    this.cache = new Map()
  }
  
  async request(key, requestFn) {
    if (this.cache.has(key)) {
      return this.cache.get(key)
    }
    
    const promise = requestFn()
    this.cache.set(key, promise)
    
    try {
      const result = await promise
      // Cache successful results for a short time
      setTimeout(() => this.cache.delete(key), 5000)
      return result
    } catch (error) {
      // Remove failed requests immediately
      this.cache.delete(key)
      throw error
    }
  }
}

const deduplicator = new RequestDeduplicator()

// Usage
async function getUser(id) {
  return deduplicator.request(`user-${id}`, () => 
    fetch(`/api/users/${id}`).then(r => r.json())
  )
}
```

## HTTP/2 & HTTP/3 Optimization

```javascript
// Resource loading optimization
function optimizeResourceLoading() {
  // Preload critical resources
  const criticalResources = [
    { href: '/fonts/main.woff2', as: 'font', type: 'font/woff2' },
    { href: '/api/user', as: 'fetch', crossorigin: 'anonymous' },
    { href: '/images/hero.jpg', as: 'image' }
  ]
  
  criticalResources.forEach(resource => {
    const link = document.createElement('link')
    link.rel = 'preload'
    Object.assign(link, resource)
    document.head.appendChild(link)
  })
  
  // DNS prefetching for external resources
  const externalDomains = [
    'fonts.googleapis.com',
    'api.analytics.com',
    'cdn.example.com'
  ]
  
  externalDomains.forEach(domain => {
    const link = document.createElement('link')
    link.rel = 'dns-prefetch'
    link.href = `//${domain}`
    document.head.appendChild(link)
  })
  
  // Early hints (HTTP/2 Server Push alternative)
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').then(registration => {
      // Service worker can implement early hints
      registration.addEventListener('message', event => {
        if (event.data.type === 'EARLY_HINTS') {
          event.data.resources.forEach(resource => {
            const link = document.createElement('link')
            link.rel = 'preload'
            link.href = resource.url
            link.as = resource.as
            document.head.appendChild(link)
          })
        }
      })
    })
  }
}

// HTTP/2 push simulation with link prefetch
function simulateHTTP2Push(resources) {
  resources.forEach(resource => {
    const link = document.createElement('link')
    link.rel = 'prefetch'
    link.href = resource.url
    link.as = resource.type
    document.head.appendChild(link)
  })
}
```

## Compression Strategies

```javascript
// Client-side compression for uploads
class CompressionService {
  static async compressImage(file, maxWidth = 1920, quality = 0.8) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.readAsDataURL(file)
      reader.onload = (event) => {
        const img = new Image()
        img.src = event.target.result
        img.onload = () => {
          const canvas = document.createElement('canvas')
          let width = img.width
          let height = img.height
          
          if (width > maxWidth) {
            height = (maxWidth / width) * height
            width = maxWidth
          }
          
          canvas.width = width
          canvas.height = height
          
          const ctx = canvas.getContext('2d')
          ctx.drawImage(img, 0, 0, width, height)
          
          canvas.toBlob(
            (blob) => resolve(blob),
            file.type,
            quality
          )
        }
      }
      reader.onerror = reject
    })
  }
  
  static async compressText(text) {
    const encoder = new TextEncoder()
    const data = encoder.encode(text)
    
    const cs = new CompressionStream('gzip')
    const writer = cs.writable.getWriter()
    writer.write(data)
    writer.close()
    
    const compressed = []
    const reader = cs.readable.getReader()
    
    while (true) {
      const { value, done } = await reader.read()
      if (done) break
      compressed.push(value)
    }
    
    return new Blob(compressed)
  }
}

// Brotli compression detection
function supportsBrotli() {
  const acceptEncoding = navigator.userAgent.includes('Chrome') || 
                        navigator.userAgent.includes('Firefox')
  return acceptEncoding
}

// Request with compression
async function fetchWithCompression(url, options = {}) {
  const headers = {
    ...options.headers,
    'Accept-Encoding': supportsBrotli() ? 'br, gzip' : 'gzip'
  }
  
  return fetch(url, { ...options, headers })
}
```

## WebSocket Optimization

```javascript
// Efficient WebSocket manager
class WebSocketManager {
  constructor(url, options = {}) {
    this.url = url
    this.options = options
    this.ws = null
    this.reconnectAttempts = 0
    this.maxReconnectAttempts = options.maxReconnectAttempts || 5
    this.reconnectDelay = options.reconnectDelay || 1000
    this.messageQueue = []
    this.listeners = new Map()
  }
  
  connect() {
    this.ws = new WebSocket(this.url)
    
    this.ws.onopen = () => {
      console.log('WebSocket connected')
      this.reconnectAttempts = 0
      this.flushMessageQueue()
    }
    
    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data)
      this.emit(data.type, data.payload)
    }
    
    this.ws.onclose = () => {
      this.handleDisconnect()
    }
    
    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error)
    }
  }
  
  handleDisconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++
      const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1)
      console.log(`Reconnecting in ${delay}ms...`)
      setTimeout(() => this.connect(), delay)
    }
  }
  
  send(type, payload) {
    const message = JSON.stringify({ type, payload })
    
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(message)
    } else {
      this.messageQueue.push(message)
    }
  }
  
  flushMessageQueue() {
    while (this.messageQueue.length > 0) {
      const message = this.messageQueue.shift()
      this.ws.send(message)
    }
  }
  
  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, [])
    }
    this.listeners.get(event).push(callback)
  }
  
  emit(event, data) {
    const callbacks = this.listeners.get(event) || []
    callbacks.forEach(callback => callback(data))
  }
  
  close() {
    this.ws?.close()
  }
}

// Usage
const ws = new WebSocketManager('wss://api.example.com/ws')
ws.connect()
ws.on('message', (data) => console.log('Received:', data))
ws.send('subscribe', { channel: 'updates' })
```

## Offline Support

```javascript
// Offline queue manager
class OfflineQueueManager {
  constructor() {
    this.queue = this.loadQueue()
    this.isOnline = navigator.onLine
    
    window.addEventListener('online', () => {
      this.isOnline = true
      this.processQueue()
    })
    
    window.addEventListener('offline', () => {
      this.isOnline = false
    })
  }
  
  loadQueue() {
    const stored = localStorage.getItem('offlineQueue')
    return stored ? JSON.parse(stored) : []
  }
  
  saveQueue() {
    localStorage.setItem('offlineQueue', JSON.stringify(this.queue))
  }
  
  async request(url, options = {}) {
    if (this.isOnline) {
      try {
        return await fetch(url, options)
      } catch (error) {
        this.queueRequest(url, options)
        throw error
      }
    } else {
      this.queueRequest(url, options)
      return Promise.reject(new Error('Offline'))
    }
  }
  
  queueRequest(url, options) {
    this.queue.push({
      url,
      options,
      timestamp: Date.now(),
      id: Math.random().toString(36).substr(2, 9)
    })
    this.saveQueue()
  }
  
  async processQueue() {
    const requests = [...this.queue]
    this.queue = []
    
    for (const request of requests) {
      try {
        await fetch(request.url, request.options)
      } catch (error) {
        // Re-queue failed requests
        this.queue.push(request)
      }
    }
    
    this.saveQueue()
  }
}

const offlineQueue = new OfflineQueueManager()

// Usage
async function apiRequest(url, options) {
  return offlineQueue.request(url, options)
}
```

## GraphQL Optimization

```javascript
// GraphQL query batching
class GraphQLBatcher {
  constructor(endpoint, options = {}) {
    this.endpoint = endpoint
    this.batchDelay = options.batchDelay || 10
    this.maxBatchSize = options.maxBatchSize || 10
    this.queue = []
    this.timer = null
  }
  
  query(query, variables = {}) {
    return new Promise((resolve, reject) => {
      this.queue.push({ query, variables, resolve, reject })
      
      if (this.queue.length >= this.maxBatchSize) {
        this.flush()
      } else if (!this.timer) {
        this.timer = setTimeout(() => this.flush(), this.batchDelay)
      }
    })
  }
  
  async flush() {
    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = null
    }
    
    const batch = this.queue.splice(0, this.maxBatchSize)
    if (batch.length === 0) return
    
    const queries = batch.map((item, index) => ({
      id: index,
      query: item.query,
      variables: item.variables
    }))
    
    try {
      const response = await fetch(this.endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(queries)
      })
      
      const results = await response.json()
      
      batch.forEach((item, index) => {
        const result = results.find(r => r.id === index)
        if (result.errors) {
          item.reject(result.errors)
        } else {
          item.resolve(result.data)
        }
      })
    } catch (error) {
      batch.forEach(item => item.reject(error))
    }
  }
}

// Persisted queries
class PersistedQueryClient {
  constructor(endpoint) {
    this.endpoint = endpoint
    this.queryMap = new Map()
  }
  
  async query(queryId, variables = {}) {
    const response = await fetch(this.endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: queryId,
        variables
      })
    })
    
    return response.json()
  }
  
  registerQuery(id, query) {
    this.queryMap.set(id, query)
  }
}
```

## Performance Monitoring

```javascript
// Network performance observer
class NetworkPerformanceObserver {
  constructor() {
    this.metrics = []
    this.init()
  }
  
  init() {
    // Monitor resource timing
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.entryType === 'resource') {
          this.recordMetric(entry)
        }
      }
    })
    
    observer.observe({ entryTypes: ['resource'] })
  }
  
  recordMetric(entry) {
    const metric = {
      name: entry.name,
      type: this.getResourceType(entry.name),
      duration: entry.duration,
      size: entry.transferSize,
      protocol: entry.nextHopProtocol,
      cached: entry.transferSize === 0,
      timestamp: Date.now()
    }
    
    this.metrics.push(metric)
    
    // Alert on slow resources
    if (metric.duration > 1000) {
      console.warn(`Slow resource: ${metric.name} took ${metric.duration}ms`)
    }
  }
  
  getResourceType(url) {
    if (url.includes('/api/')) return 'api'
    if (/\.(js|mjs)$/.test(url)) return 'script'
    if (/\.css$/.test(url)) return 'style'
    if (/\.(jpg|jpeg|png|gif|webp|avif)$/.test(url)) return 'image'
    if (/\.(woff|woff2|ttf|otf)$/.test(url)) return 'font'
    return 'other'
  }
  
  getMetricsSummary() {
    const summary = {}
    
    this.metrics.forEach(metric => {
      if (!summary[metric.type]) {
        summary[metric.type] = {
          count: 0,
          totalDuration: 0,
          totalSize: 0,
          cached: 0
        }
      }
      
      summary[metric.type].count++
      summary[metric.type].totalDuration += metric.duration
      summary[metric.type].totalSize += metric.size
      if (metric.cached) summary[metric.type].cached++
    })
    
    return summary
  }
}

const networkObserver = new NetworkPerformanceObserver()
```
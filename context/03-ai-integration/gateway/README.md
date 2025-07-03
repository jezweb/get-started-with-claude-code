# AI Gateway Patterns

Comprehensive guide to implementing AI Gateway for unified AI model access, including caching, rate limiting, analytics, and fallback strategies.

## 🎯 What is AI Gateway?

AI Gateway acts as a proxy between your application and various AI providers:
- **Unified Interface** - Single endpoint for multiple AI providers
- **Caching** - Reduce costs and latency with intelligent caching
- **Rate Limiting** - Protect against abuse and manage costs
- **Analytics** - Track usage, costs, and performance
- **Fallbacks** - Automatic failover between providers
- **Request Logging** - Debug and audit AI interactions

## 🚀 Quick Start

### Setting Up AI Gateway

```javascript
// Configure AI Gateway endpoint
const AI_GATEWAY_URL = 'https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_name}'

// Basic request structure
async function callAIGateway(provider, model, messages) {
  const response = await fetch(`${AI_GATEWAY_URL}/${provider}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`
    },
    body: JSON.stringify({
      model,
      messages,
      // Provider-specific parameters
      temperature: 0.7,
      max_tokens: 1000
    })
  })
  
  return response.json()
}
```

### Multi-Provider Configuration

```javascript
// Gateway configuration for multiple providers
const AI_PROVIDERS = {
  openai: {
    endpoint: 'openai/v1/chat/completions',
    models: ['gpt-4', 'gpt-3.5-turbo'],
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
    }
  },
  anthropic: {
    endpoint: 'anthropic/v1/messages',
    models: ['claude-3-opus', 'claude-3-sonnet'],
    headers: {
      'x-api-key': process.env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01'
    }
  },
  workers_ai: {
    endpoint: 'workers-ai/v1',
    models: ['@cf/meta/llama-2-7b-chat-int8'],
    headers: {
      'Authorization': `Bearer ${process.env.CF_API_TOKEN}`
    }
  }
}
```

## 🔧 Core Patterns

### Caching Strategies

```javascript
// Implement semantic caching for similar queries
class AIGatewayCache {
  constructor() {
    this.cache = new Map()
    this.embeddings = new Map()
  }
  
  async getCacheKey(messages, provider, model) {
    // Create deterministic cache key
    const content = messages.map(m => `${m.role}:${m.content}`).join('|')
    const baseKey = `${provider}:${model}:${content}`
    
    // For semantic caching, generate embedding
    if (this.useSemanticCache) {
      const embedding = await this.generateEmbedding(content)
      return this.findSimilarKey(embedding, baseKey)
    }
    
    return crypto.createHash('sha256').update(baseKey).digest('hex')
  }
  
  async get(messages, provider, model) {
    const key = await this.getCacheKey(messages, provider, model)
    const cached = this.cache.get(key)
    
    if (cached && Date.now() - cached.timestamp < cached.ttl) {
      return {
        ...cached.response,
        cached: true,
        cache_hit_at: cached.timestamp
      }
    }
    
    return null
  }
  
  async set(messages, provider, model, response, ttl = 3600000) {
    const key = await this.getCacheKey(messages, provider, model)
    this.cache.set(key, {
      response,
      timestamp: Date.now(),
      ttl
    })
  }
}

// Gateway with caching
class AIGateway {
  constructor(config) {
    this.config = config
    this.cache = new AIGatewayCache()
    this.metrics = new AIMetrics()
  }
  
  async query(provider, model, messages, options = {}) {
    const startTime = Date.now()
    
    // Check cache first
    if (!options.skipCache) {
      const cached = await this.cache.get(messages, provider, model)
      if (cached) {
        this.metrics.recordCacheHit(provider, model)
        return cached
      }
    }
    
    try {
      // Make request
      const response = await this.makeRequest(provider, model, messages, options)
      
      // Cache successful responses
      if (response.success && !options.skipCache) {
        await this.cache.set(messages, provider, model, response)
      }
      
      // Record metrics
      this.metrics.recordRequest(provider, model, {
        duration: Date.now() - startTime,
        tokens: response.usage?.total_tokens || 0,
        cost: this.calculateCost(provider, model, response.usage)
      })
      
      return response
    } catch (error) {
      this.metrics.recordError(provider, model, error)
      throw error
    }
  }
}
```

### Rate Limiting & Throttling

```javascript
// Token bucket rate limiter
class TokenBucket {
  constructor(capacity, refillRate) {
    this.capacity = capacity
    this.tokens = capacity
    this.refillRate = refillRate
    this.lastRefill = Date.now()
  }
  
  async acquire(tokens = 1) {
    await this.refill()
    
    if (this.tokens >= tokens) {
      this.tokens -= tokens
      return true
    }
    
    return false
  }
  
  async refill() {
    const now = Date.now()
    const timePassed = (now - this.lastRefill) / 1000
    const tokensToAdd = timePassed * this.refillRate
    
    this.tokens = Math.min(this.capacity, this.tokens + tokensToAdd)
    this.lastRefill = now
  }
}

// Rate-limited gateway
class RateLimitedGateway {
  constructor() {
    this.limiters = new Map()
    this.queues = new Map()
  }
  
  getLimiter(key, config) {
    if (!this.limiters.has(key)) {
      this.limiters.set(key, new TokenBucket(
        config.capacity || 100,
        config.refillRate || 10
      ))
    }
    return this.limiters.get(key)
  }
  
  async request(provider, model, messages, userId) {
    const limiterKey = `${userId}:${provider}`
    const limiter = this.getLimiter(limiterKey, {
      capacity: 100,  // 100 requests
      refillRate: 1   // 1 per second
    })
    
    // Try to acquire token
    if (await limiter.acquire()) {
      return this.executeRequest(provider, model, messages)
    }
    
    // Queue request if rate limited
    return this.queueRequest(limiterKey, () => 
      this.request(provider, model, messages, userId)
    )
  }
  
  async queueRequest(key, requestFn) {
    if (!this.queues.has(key)) {
      this.queues.set(key, [])
    }
    
    return new Promise((resolve, reject) => {
      this.queues.get(key).push({ requestFn, resolve, reject })
      this.processQueue(key)
    })
  }
}
```

### Fallback & Retry Patterns

```javascript
// Intelligent fallback system
class FallbackGateway {
  constructor(providers) {
    this.providers = providers
    this.healthChecks = new Map()
    this.startHealthChecks()
  }
  
  async query(messages, options = {}) {
    const preferredProvider = options.provider || this.getPreferredProvider()
    const providers = this.getProviderChain(preferredProvider)
    
    let lastError
    
    for (const provider of providers) {
      // Skip unhealthy providers
      if (!this.isHealthy(provider.name)) {
        continue
      }
      
      try {
        const response = await this.queryProvider(provider, messages, options)
        
        // Mark provider as healthy
        this.markHealthy(provider.name)
        
        return {
          ...response,
          provider: provider.name,
          fallback: provider.name !== preferredProvider
        }
      } catch (error) {
        lastError = error
        
        // Mark provider as unhealthy if it's a provider error
        if (this.isProviderError(error)) {
          this.markUnhealthy(provider.name, error)
        }
        
        // Don't fallback for user errors
        if (this.isUserError(error)) {
          throw error
        }
      }
    }
    
    throw new Error(`All providers failed. Last error: ${lastError?.message}`)
  }
  
  getProviderChain(preferred) {
    const providers = [...this.providers]
    
    // Sort by: preferred first, then by health score and cost
    return providers.sort((a, b) => {
      if (a.name === preferred) return -1
      if (b.name === preferred) return 1
      
      const healthA = this.getHealthScore(a.name)
      const healthB = this.getHealthScore(b.name)
      
      if (healthA !== healthB) return healthB - healthA
      
      return a.costPerToken - b.costPerToken
    })
  }
  
  async queryProvider(provider, messages, options) {
    const maxRetries = options.maxRetries || 3
    const backoffMs = options.backoffMs || 1000
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.makeRequest(provider, messages, options)
      } catch (error) {
        if (attempt === maxRetries) throw error
        
        // Exponential backoff with jitter
        const delay = backoffMs * Math.pow(2, attempt - 1) * (0.5 + Math.random() * 0.5)
        await new Promise(resolve => setTimeout(resolve, delay))
      }
    }
  }
}
```

### Request/Response Transformation

```javascript
// Unified request/response format
class RequestTransformer {
  // Transform to provider-specific format
  transformRequest(provider, messages, options) {
    switch (provider) {
      case 'openai':
        return {
          model: options.model || 'gpt-4',
          messages: messages.map(m => ({
            role: m.role,
            content: m.content
          })),
          temperature: options.temperature || 0.7,
          max_tokens: options.maxTokens || 1000,
          stream: options.stream || false
        }
        
      case 'anthropic':
        return {
          model: options.model || 'claude-3-opus-20240229',
          messages: messages.map(m => ({
            role: m.role === 'user' ? 'user' : 'assistant',
            content: m.content
          })),
          max_tokens: options.maxTokens || 1000,
          temperature: options.temperature || 0.7
        }
        
      case 'workers-ai':
        return {
          messages: messages.map(m => ({
            role: m.role,
            content: m.content
          })),
          stream: options.stream || false
        }
        
      default:
        throw new Error(`Unknown provider: ${provider}`)
    }
  }
  
  // Transform from provider-specific format
  transformResponse(provider, response) {
    switch (provider) {
      case 'openai':
        return {
          content: response.choices[0].message.content,
          role: response.choices[0].message.role,
          usage: {
            promptTokens: response.usage.prompt_tokens,
            completionTokens: response.usage.completion_tokens,
            totalTokens: response.usage.total_tokens
          },
          model: response.model,
          finishReason: response.choices[0].finish_reason
        }
        
      case 'anthropic':
        return {
          content: response.content[0].text,
          role: 'assistant',
          usage: {
            promptTokens: response.usage.input_tokens,
            completionTokens: response.usage.output_tokens,
            totalTokens: response.usage.input_tokens + response.usage.output_tokens
          },
          model: response.model,
          finishReason: response.stop_reason
        }
        
      case 'workers-ai':
        return {
          content: response.response,
          role: 'assistant',
          usage: null, // Workers AI doesn't provide token counts
          model: response.model,
          finishReason: 'stop'
        }
    }
  }
}
```

### Analytics & Monitoring

```javascript
// Comprehensive analytics system
class AIGatewayAnalytics {
  constructor() {
    this.metrics = {
      requests: new Map(),
      errors: new Map(),
      latencies: [],
      costs: new Map(),
      cacheHits: 0,
      cacheMisses: 0
    }
  }
  
  recordRequest(provider, model, data) {
    const key = `${provider}:${model}`
    
    // Increment request count
    this.metrics.requests.set(key, 
      (this.metrics.requests.get(key) || 0) + 1
    )
    
    // Record latency
    this.metrics.latencies.push({
      provider,
      model,
      duration: data.duration,
      timestamp: Date.now()
    })
    
    // Track costs
    if (data.cost) {
      this.metrics.costs.set(key,
        (this.metrics.costs.get(key) || 0) + data.cost
      )
    }
    
    // Emit metrics for monitoring
    this.emitMetrics({
      type: 'request',
      provider,
      model,
      duration: data.duration,
      tokens: data.tokens,
      cost: data.cost
    })
  }
  
  recordError(provider, model, error) {
    const key = `${provider}:${model}:${error.code || 'unknown'}`
    this.metrics.errors.set(key,
      (this.metrics.errors.get(key) || 0) + 1
    )
    
    this.emitMetrics({
      type: 'error',
      provider,
      model,
      error: error.message,
      code: error.code
    })
  }
  
  getReport(timeRange = 3600000) { // Last hour
    const now = Date.now()
    const recentLatencies = this.metrics.latencies.filter(
      l => now - l.timestamp < timeRange
    )
    
    return {
      summary: {
        totalRequests: Array.from(this.metrics.requests.values())
          .reduce((a, b) => a + b, 0),
        totalErrors: Array.from(this.metrics.errors.values())
          .reduce((a, b) => a + b, 0),
        cacheHitRate: this.metrics.cacheHits / 
          (this.metrics.cacheHits + this.metrics.cacheMisses),
        totalCost: Array.from(this.metrics.costs.values())
          .reduce((a, b) => a + b, 0)
      },
      providers: this.getProviderStats(),
      latency: {
        p50: this.percentile(recentLatencies.map(l => l.duration), 50),
        p95: this.percentile(recentLatencies.map(l => l.duration), 95),
        p99: this.percentile(recentLatencies.map(l => l.duration), 99)
      },
      errors: this.getErrorBreakdown()
    }
  }
}
```

## 🛠️ Advanced Patterns

### Streaming Responses

```javascript
// Streaming gateway implementation
class StreamingGateway {
  async streamQuery(provider, model, messages, onChunk) {
    const transformer = new RequestTransformer()
    const request = transformer.transformRequest(provider, messages, {
      model,
      stream: true
    })
    
    const response = await fetch(this.getEndpoint(provider), {
      method: 'POST',
      headers: this.getHeaders(provider),
      body: JSON.stringify(request)
    })
    
    if (!response.ok) {
      throw new Error(`Gateway error: ${response.statusText}`)
    }
    
    const reader = response.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ''
    
    try {
      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        
        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() || ''
        
        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6)
            if (data === '[DONE]') continue
            
            try {
              const chunk = JSON.parse(data)
              const transformed = this.transformStreamChunk(provider, chunk)
              if (transformed.content) {
                await onChunk(transformed)
              }
            } catch (e) {
              console.error('Failed to parse chunk:', e)
            }
          }
        }
      }
    } finally {
      reader.releaseLock()
    }
  }
  
  transformStreamChunk(provider, chunk) {
    switch (provider) {
      case 'openai':
        return {
          content: chunk.choices[0]?.delta?.content || '',
          role: chunk.choices[0]?.delta?.role,
          finishReason: chunk.choices[0]?.finish_reason
        }
        
      case 'anthropic':
        return {
          content: chunk.delta?.text || '',
          role: 'assistant',
          finishReason: chunk.delta?.stop_reason
        }
        
      default:
        return chunk
    }
  }
}
```

### Request Batching

```javascript
// Batch multiple requests for efficiency
class BatchingGateway {
  constructor() {
    this.batchQueue = new Map()
    this.batchTimeout = 50 // ms
    this.maxBatchSize = 10
  }
  
  async query(provider, model, messages, options = {}) {
    if (options.immediate) {
      return this.executeRequest(provider, model, messages, options)
    }
    
    return this.addToBatch(provider, model, messages, options)
  }
  
  async addToBatch(provider, model, messages, options) {
    const batchKey = `${provider}:${model}`
    
    if (!this.batchQueue.has(batchKey)) {
      this.batchQueue.set(batchKey, {
        requests: [],
        timer: null
      })
    }
    
    const batch = this.batchQueue.get(batchKey)
    
    return new Promise((resolve, reject) => {
      batch.requests.push({ messages, options, resolve, reject })
      
      // Process immediately if batch is full
      if (batch.requests.length >= this.maxBatchSize) {
        this.processBatch(batchKey)
      } else if (!batch.timer) {
        // Set timer for batch processing
        batch.timer = setTimeout(() => {
          this.processBatch(batchKey)
        }, this.batchTimeout)
      }
    })
  }
  
  async processBatch(batchKey) {
    const batch = this.batchQueue.get(batchKey)
    if (!batch || batch.requests.length === 0) return
    
    // Clear batch
    this.batchQueue.delete(batchKey)
    if (batch.timer) clearTimeout(batch.timer)
    
    const [provider, model] = batchKey.split(':')
    
    try {
      // Execute batch request
      const responses = await this.executeBatchRequest(
        provider,
        model,
        batch.requests.map(r => r.messages)
      )
      
      // Resolve individual promises
      batch.requests.forEach((request, index) => {
        request.resolve(responses[index])
      })
    } catch (error) {
      // Reject all promises in batch
      batch.requests.forEach(request => {
        request.reject(error)
      })
    }
  }
}
```

### Cost Optimization

```javascript
// Cost-aware routing
class CostOptimizedGateway {
  constructor() {
    this.providers = [
      {
        name: 'workers-ai',
        models: ['@cf/meta/llama-2-7b-chat-int8'],
        costPerMillion: 0,  // Free tier
        capabilities: ['chat', 'completion']
      },
      {
        name: 'openai',
        models: {
          'gpt-3.5-turbo': { costPerMillion: 0.5 },
          'gpt-4': { costPerMillion: 30 }
        },
        capabilities: ['chat', 'completion', 'function-calling']
      },
      {
        name: 'anthropic',
        models: {
          'claude-3-haiku': { costPerMillion: 0.25 },
          'claude-3-opus': { costPerMillion: 15 }
        },
        capabilities: ['chat', 'completion', 'vision']
      }
    ]
  }
  
  async query(messages, options = {}) {
    const requirements = this.analyzeRequirements(messages, options)
    const provider = this.selectProvider(requirements)
    
    return this.executeWithProvider(provider, messages, options)
  }
  
  analyzeRequirements(messages, options) {
    return {
      complexity: this.estimateComplexity(messages),
      capabilities: this.requiredCapabilities(messages, options),
      maxCost: options.maxCost || Infinity,
      quality: options.quality || 'balanced'
    }
  }
  
  selectProvider(requirements) {
    const eligible = this.providers.filter(p => 
      this.meetsRequirements(p, requirements)
    )
    
    // Sort by cost-effectiveness
    return eligible.sort((a, b) => {
      const costA = this.estimateCost(a, requirements)
      const costB = this.estimateCost(b, requirements)
      
      if (requirements.quality === 'best') {
        // Prioritize quality over cost
        return b.qualityScore - a.qualityScore || costA - costB
      }
      
      return costA - costB
    })[0]
  }
  
  estimateCost(provider, requirements) {
    const tokens = requirements.complexity * 1000 // Rough estimate
    const model = this.selectModel(provider, requirements)
    const costPerMillion = provider.models[model]?.costPerMillion || 0
    
    return (tokens / 1000000) * costPerMillion
  }
}
```

## 🔍 Error Handling

```javascript
// Comprehensive error handling
class GatewayErrorHandler {
  handleError(error, context) {
    // Categorize error
    const errorType = this.categorizeError(error)
    
    switch (errorType) {
      case 'rate_limit':
        return this.handleRateLimit(error, context)
        
      case 'quota_exceeded':
        return this.handleQuotaExceeded(error, context)
        
      case 'invalid_request':
        return this.handleInvalidRequest(error, context)
        
      case 'provider_error':
        return this.handleProviderError(error, context)
        
      case 'network_error':
        return this.handleNetworkError(error, context)
        
      default:
        return this.handleUnknownError(error, context)
    }
  }
  
  categorizeError(error) {
    if (error.status === 429) return 'rate_limit'
    if (error.code === 'quota_exceeded') return 'quota_exceeded'
    if (error.status === 400) return 'invalid_request'
    if (error.status >= 500) return 'provider_error'
    if (error.code === 'ECONNREFUSED') return 'network_error'
    
    return 'unknown'
  }
  
  async handleRateLimit(error, context) {
    const retryAfter = error.headers?.['retry-after'] || 60
    
    // Log rate limit event
    await this.logEvent({
      type: 'rate_limit',
      provider: context.provider,
      retryAfter,
      userId: context.userId
    })
    
    // Queue for retry or return friendly error
    if (context.options.autoRetry) {
      return this.queueForRetry(context, retryAfter * 1000)
    }
    
    throw new RateLimitError(
      `Rate limit exceeded. Please retry after ${retryAfter} seconds.`,
      { retryAfter }
    )
  }
  
  async handleQuotaExceeded(error, context) {
    // Try fallback to a cheaper provider
    if (context.options.allowFallback) {
      const fallbackProvider = this.findFallbackProvider(context)
      if (fallbackProvider) {
        return this.retryWithProvider(fallbackProvider, context)
      }
    }
    
    throw new QuotaExceededError(
      'Monthly quota exceeded. Please upgrade your plan or wait until next billing cycle.'
    )
  }
}
```

## 📊 Testing & Monitoring

```javascript
// Gateway testing utilities
class GatewayTester {
  async runHealthChecks() {
    const results = new Map()
    
    for (const [provider, config] of Object.entries(this.providers)) {
      try {
        const start = Date.now()
        const response = await this.testProvider(provider, config)
        
        results.set(provider, {
          healthy: true,
          latency: Date.now() - start,
          model: response.model,
          timestamp: new Date().toISOString()
        })
      } catch (error) {
        results.set(provider, {
          healthy: false,
          error: error.message,
          timestamp: new Date().toISOString()
        })
      }
    }
    
    return results
  }
  
  async testProvider(provider, config) {
    const testMessage = [{
      role: 'user',
      content: 'Reply with "OK" if you receive this message.'
    }]
    
    return this.gateway.query(provider, config.models[0], testMessage, {
      timeout: 5000,
      skipCache: true
    })
  }
  
  async runLoadTest(options = {}) {
    const {
      duration = 60000,  // 1 minute
      rps = 10,          // requests per second
      providers = Object.keys(this.providers)
    } = options
    
    const results = {
      requests: 0,
      successes: 0,
      failures: 0,
      latencies: [],
      errors: new Map()
    }
    
    const interval = 1000 / rps
    const endTime = Date.now() + duration
    
    while (Date.now() < endTime) {
      const provider = providers[Math.floor(Math.random() * providers.length)]
      const start = Date.now()
      
      try {
        await this.makeTestRequest(provider)
        results.successes++
        results.latencies.push(Date.now() - start)
      } catch (error) {
        results.failures++
        const errorKey = `${provider}:${error.message}`
        results.errors.set(errorKey, 
          (results.errors.get(errorKey) || 0) + 1
        )
      }
      
      results.requests++
      await new Promise(resolve => setTimeout(resolve, interval))
    }
    
    return this.generateLoadTestReport(results)
  }
}
```

## 🚀 Best Practices

### 1. **Provider Selection**
```javascript
// Smart provider selection based on use case
const selectProvider = (task) => {
  switch (task.type) {
    case 'simple_qa':
      return { provider: 'workers-ai', model: '@cf/meta/llama-2-7b-chat-int8' }
      
    case 'complex_reasoning':
      return { provider: 'openai', model: 'gpt-4' }
      
    case 'creative_writing':
      return { provider: 'anthropic', model: 'claude-3-opus' }
      
    case 'code_generation':
      return { provider: 'openai', model: 'gpt-4' }
      
    default:
      return { provider: 'openai', model: 'gpt-3.5-turbo' }
  }
}
```

### 2. **Cache Management**
- Cache similar queries with semantic similarity
- Set appropriate TTLs based on content type
- Implement cache warming for common queries
- Monitor cache hit rates

### 3. **Cost Control**
- Set spending limits per user/application
- Implement token counting before requests
- Use cheaper models for simple tasks
- Batch requests when possible

### 4. **Monitoring & Alerting**
- Track provider availability
- Monitor response times and error rates
- Set up alerts for unusual patterns
- Log all requests for audit trails

### 5. **Security**
- Rotate API keys regularly
- Implement request signing
- Validate and sanitize inputs
- Use encryption for sensitive data

## 📖 Resources & References

### Official Documentation
- [Cloudflare AI Gateway](https://developers.cloudflare.com/ai-gateway/)
- [OpenAI API](https://platform.openai.com/docs)
- [Anthropic API](https://docs.anthropic.com)
- [Workers AI](https://developers.cloudflare.com/workers-ai/)

### Tools & Libraries
- **Gateway SDKs** - Official client libraries
- **Monitoring Tools** - Grafana, Datadog integrations
- **Testing Frameworks** - Jest, Vitest with gateway mocks
- **Cost Calculators** - Token counting utilities

---

*This guide covers essential AI Gateway patterns for building scalable, cost-effective AI applications. Focus on caching, fallbacks, and monitoring for production success.*
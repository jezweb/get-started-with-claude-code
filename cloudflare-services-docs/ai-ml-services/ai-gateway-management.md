# Cloudflare AI Gateway - AI Request Management

## Overview

Cloudflare AI Gateway provides intelligent AI request management, caching, analytics, and cost optimization for AI services. It acts as a unified interface for multiple AI providers, offering request caching, rate limiting, usage analytics, and fallback strategies to build robust AI-powered applications.

## Quick Start

### Basic Setup
```javascript
// Workers with AI Gateway integration
export default {
  async fetch(request, env) {
    const aiGateway = new AIGateway(env.AI_GATEWAY_URL, env.AI_GATEWAY_TOKEN);
    
    const response = await aiGateway.chat({
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'user', content: 'Hello, how are you?' }
      ]
    });
    
    return Response.json(response);
  }
};

class AIGateway {
  constructor(gatewayUrl, token) {
    this.gatewayUrl = gatewayUrl;
    this.token = token;
  }
  
  async chat(options) {
    const response = await fetch(`${this.gatewayUrl}/openai/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(options),
    });
    
    return response.json();
  }
}
```

### Configuration
```toml
# wrangler.toml
[vars]
AI_GATEWAY_URL = "https://gateway.ai.cloudflare.com/v1/your-account-id/your-gateway-id"
AI_GATEWAY_TOKEN = "your-openai-api-key"

[[kv_namespaces]]
binding = "AI_CACHE"
id = "your-ai-cache-namespace"

[[kv_namespaces]]
binding = "AI_ANALYTICS"
id = "your-analytics-namespace"
```

## Core Concepts

### Multi-Provider Support
AI Gateway supports multiple AI providers with unified interfaces:

```javascript
// Multi-provider AI service with fallback
class MultiProviderAI {
  constructor(env) {
    this.env = env;
    this.providers = {
      openai: {
        url: `${env.AI_GATEWAY_URL}/openai`,
        token: env.OPENAI_API_KEY,
        models: ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo']
      },
      anthropic: {
        url: `${env.AI_GATEWAY_URL}/anthropic`,
        token: env.ANTHROPIC_API_KEY,
        models: ['claude-3-haiku', 'claude-3-sonnet', 'claude-3-opus']
      },
      workers: {
        url: `${env.AI_GATEWAY_URL}/workers-ai`,
        token: env.CF_API_TOKEN,
        models: ['@cf/meta/llama-2-7b-chat-int8', '@cf/mistral/mistral-7b-instruct-v0.1']
      }
    };
  }
  
  async chat(messages, options = {}) {
    const { model, provider, temperature = 0.7, maxTokens = 150 } = options;
    
    // Determine provider and model
    const selectedProvider = provider || this.selectProvider(model);
    const selectedModel = model || this.getDefaultModel(selectedProvider);
    
    try {
      return await this.callProvider(selectedProvider, selectedModel, messages, {
        temperature,
        max_tokens: maxTokens
      });
    } catch (error) {
      console.error(`Primary provider ${selectedProvider} failed:`, error);
      
      // Try fallback provider
      const fallbackProvider = this.getFallbackProvider(selectedProvider);
      if (fallbackProvider) {
        const fallbackModel = this.getCompatibleModel(selectedModel, fallbackProvider);
        return await this.callProvider(fallbackProvider, fallbackModel, messages, {
          temperature,
          max_tokens: maxTokens
        });
      }
      
      throw error;
    }
  }
  
  async callProvider(provider, model, messages, options) {
    const providerConfig = this.providers[provider];
    
    const requestBody = this.formatRequest(provider, model, messages, options);
    
    const response = await fetch(`${providerConfig.url}/${this.getEndpoint(provider)}`, {
      method: 'POST',
      headers: {
        'Authorization': this.getAuthHeader(provider, providerConfig.token),
        'Content-Type': 'application/json',
        'CF-AI-Gateway-Cache-TTL': '3600', // Cache for 1 hour
        'CF-AI-Gateway-Skip-Cache': options.skipCache ? 'true' : 'false'
      },
      body: JSON.stringify(requestBody)
    });
    
    if (!response.ok) {
      throw new Error(`${provider} API error: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    return this.formatResponse(provider, data);
  }
  
  formatRequest(provider, model, messages, options) {
    switch (provider) {
      case 'openai':
        return {
          model,
          messages,
          temperature: options.temperature,
          max_tokens: options.max_tokens
        };
        
      case 'anthropic':
        return {
          model,
          messages: this.convertToAnthropicFormat(messages),
          temperature: options.temperature,
          max_tokens: options.max_tokens
        };
        
      case 'workers':
        return {
          messages,
          temperature: options.temperature,
          max_tokens: options.max_tokens
        };
        
      default:
        throw new Error(`Unsupported provider: ${provider}`);
    }
  }
  
  formatResponse(provider, data) {
    switch (provider) {
      case 'openai':
        return {
          content: data.choices[0].message.content,
          model: data.model,
          usage: data.usage,
          provider: 'openai'
        };
        
      case 'anthropic':
        return {
          content: data.content[0].text,
          model: data.model,
          usage: data.usage,
          provider: 'anthropic'
        };
        
      case 'workers':
        return {
          content: data.result.response,
          model: data.result.model,
          usage: data.result.usage,
          provider: 'workers'
        };
        
      default:
        return data;
    }
  }
  
  selectProvider(model) {
    for (const [provider, config] of Object.entries(this.providers)) {
      if (config.models.includes(model)) {
        return provider;
      }
    }
    return 'openai'; // Default fallback
  }
  
  getDefaultModel(provider) {
    return this.providers[provider]?.models[0] || 'gpt-3.5-turbo';
  }
  
  getFallbackProvider(primaryProvider) {
    const fallbacks = {
      openai: 'anthropic',
      anthropic: 'openai',
      workers: 'openai'
    };
    return fallbacks[primaryProvider];
  }
  
  getCompatibleModel(model, targetProvider) {
    const modelMappings = {
      'gpt-3.5-turbo': { anthropic: 'claude-3-haiku', workers: '@cf/meta/llama-2-7b-chat-int8' },
      'gpt-4': { anthropic: 'claude-3-sonnet', workers: '@cf/meta/llama-2-7b-chat-int8' },
      'claude-3-haiku': { openai: 'gpt-3.5-turbo', workers: '@cf/meta/llama-2-7b-chat-int8' },
      'claude-3-sonnet': { openai: 'gpt-4', workers: '@cf/meta/llama-2-7b-chat-int8' }
    };
    
    return modelMappings[model]?.[targetProvider] || this.getDefaultModel(targetProvider);
  }
  
  getEndpoint(provider) {
    const endpoints = {
      openai: 'chat/completions',
      anthropic: 'messages',
      workers: 'chat/completions'
    };
    return endpoints[provider];
  }
  
  getAuthHeader(provider, token) {
    switch (provider) {
      case 'openai':
      case 'workers':
        return `Bearer ${token}`;
      case 'anthropic':
        return `Bearer ${token}`;
      default:
        return `Bearer ${token}`;
    }
  }
  
  convertToAnthropicFormat(messages) {
    // Convert OpenAI format to Anthropic format
    return messages.map(msg => ({
      role: msg.role === 'assistant' ? 'assistant' : 'user',
      content: msg.content
    }));
  }
}
```

## Integration Patterns

### 1. Intelligent Caching System

```javascript
// Smart caching with AI Gateway and KV
class SmartAICache {
  constructor(env) {
    this.env = env;
    this.kv = env.AI_CACHE;
    this.analytics = env.AI_ANALYTICS;
  }
  
  async getCachedResponse(request, options = {}) {
    const cacheKey = this.generateCacheKey(request, options);
    
    // Check cache first
    const cached = await this.kv.getWithMetadata(cacheKey, 'json');
    
    if (cached.value && this.isCacheValid(cached.metadata, options)) {
      // Update cache hit analytics
      await this.recordCacheHit(cacheKey);
      
      return {
        ...cached.value,
        fromCache: true,
        cacheAge: Date.now() - cached.metadata.cached_at
      };
    }
    
    // Cache miss - make AI request
    const response = await this.makeAIRequest(request, options);
    
    // Cache the response
    await this.cacheResponse(cacheKey, response, options);
    
    // Record cache miss
    await this.recordCacheMiss(cacheKey);
    
    return {
      ...response,
      fromCache: false
    };
  }
  
  generateCacheKey(request, options) {
    const keyData = {
      messages: request.messages,
      model: options.model || 'gpt-3.5-turbo',
      temperature: options.temperature || 0.7,
      maxTokens: options.maxTokens || 150
    };
    
    // Create deterministic hash
    const keyString = JSON.stringify(keyData);
    return `ai_cache:${this.hashString(keyString)}`;
  }
  
  async hashString(str) {
    const encoder = new TextEncoder();
    const data = encoder.encode(str);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }
  
  isCacheValid(metadata, options) {
    if (!metadata) return false;
    
    const age = Date.now() - metadata.cached_at;
    const maxAge = (options.cacheTTL || 3600) * 1000; // Default 1 hour
    
    return age < maxAge;
  }
  
  async cacheResponse(cacheKey, response, options) {
    const ttl = options.cacheTTL || 3600; // 1 hour default
    
    await this.kv.put(cacheKey, JSON.stringify(response), {
      expirationTtl: ttl,
      metadata: {
        cached_at: Date.now(),
        ttl,
        model: options.model,
        provider: response.provider
      }
    });
  }
  
  async makeAIRequest(request, options) {
    const ai = new MultiProviderAI(this.env);
    return await ai.chat(request.messages, options);
  }
  
  async recordCacheHit(cacheKey) {
    const today = new Date().toISOString().split('T')[0];
    const hitKey = `cache_hits:${today}`;
    
    const current = await this.analytics.get(hitKey, 'json') || { count: 0, keys: {} };
    current.count++;
    current.keys[cacheKey] = (current.keys[cacheKey] || 0) + 1;
    
    await this.analytics.put(hitKey, JSON.stringify(current), {
      expirationTtl: 7 * 24 * 3600 // Keep for 7 days
    });
  }
  
  async recordCacheMiss(cacheKey) {
    const today = new Date().toISOString().split('T')[0];
    const missKey = `cache_misses:${today}`;
    
    const current = await this.analytics.get(missKey, 'json') || { count: 0, keys: {} };
    current.count++;
    current.keys[cacheKey] = (current.keys[cacheKey] || 0) + 1;
    
    await this.analytics.put(missKey, JSON.stringify(current), {
      expirationTtl: 7 * 24 * 3600 // Keep for 7 days
    });
  }
  
  async getCacheStats(days = 7) {
    const stats = {
      hits: 0,
      misses: 0,
      hitRate: 0,
      dailyStats: []
    };
    
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      const hits = await this.analytics.get(`cache_hits:${dateStr}`, 'json');
      const misses = await this.analytics.get(`cache_misses:${dateStr}`, 'json');
      
      const dailyHits = hits?.count || 0;
      const dailyMisses = misses?.count || 0;
      
      stats.hits += dailyHits;
      stats.misses += dailyMisses;
      
      stats.dailyStats.unshift({
        date: dateStr,
        hits: dailyHits,
        misses: dailyMisses,
        hitRate: dailyHits + dailyMisses > 0 ? (dailyHits / (dailyHits + dailyMisses) * 100).toFixed(2) : 0
      });
    }
    
    const total = stats.hits + stats.misses;
    stats.hitRate = total > 0 ? (stats.hits / total * 100).toFixed(2) : 0;
    
    return stats;
  }
}
```

### 2. Rate Limiting and Cost Management

```javascript
// Comprehensive rate limiting and cost management
class AIRateLimiter {
  constructor(env) {
    this.env = env;
    this.kv = env.AI_ANALYTICS;
    this.limits = {
      requests_per_minute: 60,
      requests_per_hour: 1000,
      requests_per_day: 10000,
      tokens_per_day: 1000000,
      cost_per_day: 100.00 // $100 per day
    };
  }
  
  async checkLimits(userId, requestEstimate) {
    const now = Date.now();
    const minute = Math.floor(now / 60000);
    const hour = Math.floor(now / 3600000);
    const day = Math.floor(now / 86400000);
    
    // Check all rate limits
    const checks = await Promise.all([
      this.checkRateLimit(userId, 'minute', minute, this.limits.requests_per_minute),
      this.checkRateLimit(userId, 'hour', hour, this.limits.requests_per_hour),
      this.checkRateLimit(userId, 'day', day, this.limits.requests_per_day),
      this.checkTokenLimit(userId, day, requestEstimate.estimatedTokens),
      this.checkCostLimit(userId, day, requestEstimate.estimatedCost)
    ]);
    
    const failures = checks.filter(check => !check.allowed);
    
    if (failures.length > 0) {
      return {
        allowed: false,
        failures,
        retryAfter: Math.max(...failures.map(f => f.retryAfter || 60))
      };
    }
    
    return { allowed: true };
  }
  
  async checkRateLimit(userId, period, periodValue, limit) {
    const key = `rate_limit:${userId}:${period}:${periodValue}`;
    const current = await this.kv.get(key, 'json') || { count: 0 };
    
    if (current.count >= limit) {
      const retryAfter = this.getRetryAfter(period, periodValue);
      return {
        allowed: false,
        type: `${period}_rate_limit`,
        current: current.count,
        limit,
        retryAfter
      };
    }
    
    return { allowed: true, current: current.count, limit };
  }
  
  async checkTokenLimit(userId, day, estimatedTokens) {
    const key = `tokens:${userId}:${day}`;
    const current = await this.kv.get(key, 'json') || { count: 0 };
    
    if (current.count + estimatedTokens > this.limits.tokens_per_day) {
      return {
        allowed: false,
        type: 'token_limit',
        current: current.count,
        estimated: estimatedTokens,
        limit: this.limits.tokens_per_day,
        retryAfter: this.getRetryAfter('day', day)
      };
    }
    
    return { allowed: true, current: current.count, limit: this.limits.tokens_per_day };
  }
  
  async checkCostLimit(userId, day, estimatedCost) {
    const key = `cost:${userId}:${day}`;
    const current = await this.kv.get(key, 'json') || { amount: 0 };
    
    if (current.amount + estimatedCost > this.limits.cost_per_day) {
      return {
        allowed: false,
        type: 'cost_limit',
        current: current.amount,
        estimated: estimatedCost,
        limit: this.limits.cost_per_day,
        retryAfter: this.getRetryAfter('day', day)
      };
    }
    
    return { allowed: true, current: current.amount, limit: this.limits.cost_per_day };
  }
  
  async recordUsage(userId, usage) {
    const now = Date.now();
    const minute = Math.floor(now / 60000);
    const hour = Math.floor(now / 3600000);
    const day = Math.floor(now / 86400000);
    
    // Update rate limit counters
    await Promise.all([
      this.incrementCounter(`rate_limit:${userId}:minute:${minute}`, 60),
      this.incrementCounter(`rate_limit:${userId}:hour:${hour}`, 3600),
      this.incrementCounter(`rate_limit:${userId}:day:${day}`, 86400),
      this.incrementUsage(`tokens:${userId}:${day}`, usage.tokens, 86400),
      this.incrementUsage(`cost:${userId}:${day}`, usage.cost, 86400)
    ]);
  }
  
  async incrementCounter(key, ttl) {
    const current = await this.kv.get(key, 'json') || { count: 0 };
    current.count++;
    
    await this.kv.put(key, JSON.stringify(current), {
      expirationTtl: ttl
    });
  }
  
  async incrementUsage(key, amount, ttl) {
    const current = await this.kv.get(key, 'json') || 
      (key.includes('cost') ? { amount: 0 } : { count: 0 });
    
    if (key.includes('cost')) {
      current.amount += amount;
    } else {
      current.count += amount;
    }
    
    await this.kv.put(key, JSON.stringify(current), {
      expirationTtl: ttl
    });
  }
  
  getRetryAfter(period, periodValue) {
    const now = Date.now();
    
    switch (period) {
      case 'minute':
        return 60 - (Math.floor(now / 1000) % 60);
      case 'hour':
        return 3600 - (Math.floor(now / 1000) % 3600);
      case 'day':
        return 86400 - (Math.floor(now / 1000) % 86400);
      default:
        return 60;
    }
  }
  
  estimateRequest(messages, options = {}) {
    const model = options.model || 'gpt-3.5-turbo';
    const maxTokens = options.maxTokens || 150;
    
    // Rough token estimation
    const inputText = messages.map(m => m.content).join(' ');
    const estimatedInputTokens = Math.ceil(inputText.length / 4); // Rough estimate
    const estimatedOutputTokens = maxTokens;
    const totalTokens = estimatedInputTokens + estimatedOutputTokens;
    
    // Cost estimation (simplified)
    const costs = {
      'gpt-3.5-turbo': { input: 0.0015, output: 0.002 }, // per 1K tokens
      'gpt-4': { input: 0.03, output: 0.06 },
      'claude-3-haiku': { input: 0.00025, output: 0.00125 }
    };
    
    const modelCost = costs[model] || costs['gpt-3.5-turbo'];
    const estimatedCost = 
      (estimatedInputTokens / 1000) * modelCost.input +
      (estimatedOutputTokens / 1000) * modelCost.output;
    
    return {
      estimatedTokens: totalTokens,
      estimatedInputTokens,
      estimatedOutputTokens,
      estimatedCost
    };
  }
  
  async getUserUsage(userId, days = 7) {
    const usage = {
      daily: [],
      totals: {
        requests: 0,
        tokens: 0,
        cost: 0
      }
    };
    
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const day = Math.floor(date.getTime() / 86400000);
      
      const [requests, tokens, cost] = await Promise.all([
        this.kv.get(`rate_limit:${userId}:day:${day}`, 'json'),
        this.kv.get(`tokens:${userId}:${day}`, 'json'),
        this.kv.get(`cost:${userId}:${day}`, 'json')
      ]);
      
      const dailyUsage = {
        date: date.toISOString().split('T')[0],
        requests: requests?.count || 0,
        tokens: tokens?.count || 0,
        cost: cost?.amount || 0
      };
      
      usage.daily.unshift(dailyUsage);
      usage.totals.requests += dailyUsage.requests;
      usage.totals.tokens += dailyUsage.tokens;
      usage.totals.cost += dailyUsage.cost;
    }
    
    return usage;
  }
}
```

### 3. Content Moderation and Safety

```javascript
// AI content moderation and safety filters
class AIContentModerator {
  constructor(env) {
    this.env = env;
    this.ai = new MultiProviderAI(env);
    this.moderationCache = env.AI_CACHE;
  }
  
  async moderateRequest(messages, options = {}) {
    const results = await Promise.all([
      this.checkContentPolicy(messages),
      this.checkSensitiveTopics(messages),
      this.checkPromptInjection(messages)
    ]);
    
    const violations = results.filter(result => !result.allowed);
    
    if (violations.length > 0) {
      return {
        allowed: false,
        violations,
        blockedReasons: violations.map(v => v.reason)
      };
    }
    
    return { allowed: true };
  }
  
  async moderateResponse(response, originalMessages) {
    const results = await Promise.all([
      this.checkResponseSafety(response),
      this.checkFactualAccuracy(response, originalMessages),
      this.checkBiasDetection(response)
    ]);
    
    const issues = results.filter(result => result.confidence > 0.7);
    
    return {
      safe: issues.length === 0,
      issues,
      needsReview: issues.some(issue => issue.severity === 'high')
    };
  }
  
  async checkContentPolicy(messages) {
    const cacheKey = `moderation:${await this.hashMessages(messages)}`;
    
    // Check cache first
    const cached = await this.moderationCache.get(cacheKey, 'json');
    if (cached) {
      return cached;
    }
    
    const lastMessage = messages[messages.length - 1]?.content || '';
    
    // Use OpenAI moderation API through AI Gateway
    try {
      const moderationResponse = await fetch(`${this.env.AI_GATEWAY_URL}/openai/moderations`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          input: lastMessage
        })
      });
      
      const moderation = await moderationResponse.json();
      const result = moderation.results[0];
      
      const policyResult = {
        allowed: !result.flagged,
        reason: result.flagged ? this.getModerationReason(result.categories) : null,
        confidence: Math.max(...Object.values(result.category_scores || {})),
        details: result
      };
      
      // Cache result
      await this.moderationCache.put(cacheKey, JSON.stringify(policyResult), {
        expirationTtl: 3600 // 1 hour
      });
      
      return policyResult;
    } catch (error) {
      console.error('Moderation API error:', error);
      // Fail open - allow request but log for review
      return { allowed: true, error: error.message };
    }
  }
  
  async checkSensitiveTopics(messages) {
    const sensitivePatterns = [
      /\b(suicide|self-harm|kill myself)\b/i,
      /\b(bomb|explosive|terrorist)\b/i,
      /\b(illegal drugs|cocaine|heroin)\b/i,
      /\b(hack|hacking|crack password)\b/i
    ];
    
    const content = messages.map(m => m.content).join(' ');
    
    for (const pattern of sensitivePatterns) {
      if (pattern.test(content)) {
        return {
          allowed: false,
          reason: 'sensitive_topic',
          pattern: pattern.source,
          confidence: 0.8
        };
      }
    }
    
    return { allowed: true };
  }
  
  async checkPromptInjection(messages) {
    const injectionPatterns = [
      /ignore\s+(?:previous|above|all)\s+instructions/i,
      /\bdisregard\s+(?:previous|above|all)\s+instructions/i,
      /act\s+as\s+(?:an?\s+)?(?:admin|administrator|root)/i,
      /\bsystem\s*:\s*ignore/i,
      /\boverride\s+(?:safety|security)\s+protocols/i
    ];
    
    const lastMessage = messages[messages.length - 1]?.content || '';
    
    for (const pattern of injectionPatterns) {
      if (pattern.test(lastMessage)) {
        return {
          allowed: false,
          reason: 'prompt_injection',
          pattern: pattern.source,
          confidence: 0.9
        };
      }
    }
    
    return { allowed: true };
  }
  
  async checkResponseSafety(response) {
    // Check for potentially harmful content in AI response
    const harmfulPatterns = [
      /\b(?:kill|murder|assassinate)\s+(?:someone|people)\b/i,
      /how\s+to\s+(?:make|create|build)\s+(?:bomb|explosive)/i,
      /\b(?:commit|perform)\s+(?:suicide|self-harm)/i
    ];
    
    const content = response.content || '';
    
    for (const pattern of harmfulPatterns) {
      if (pattern.test(content)) {
        return {
          issue: 'harmful_content',
          confidence: 0.8,
          severity: 'high',
          pattern: pattern.source
        };
      }
    }
    
    return { issue: null, confidence: 0 };
  }
  
  async checkFactualAccuracy(response, originalMessages) {
    // Simple fact-checking using AI
    const factCheckPrompt = `Please evaluate the factual accuracy of this response. Rate from 0-1 where 1 is completely accurate:
    
    Original question: ${originalMessages[originalMessages.length - 1]?.content}
    Response: ${response.content}
    
    Respond with just a number between 0 and 1.`;
    
    try {
      const factCheck = await this.ai.chat([
        { role: 'user', content: factCheckPrompt }
      ], {
        model: 'gpt-3.5-turbo',
        temperature: 0.1,
        maxTokens: 10
      });
      
      const accuracy = parseFloat(factCheck.content.trim());
      
      return {
        issue: accuracy < 0.7 ? 'factual_accuracy' : null,
        confidence: 1 - accuracy,
        severity: accuracy < 0.5 ? 'high' : 'medium',
        accuracy
      };
    } catch (error) {
      return { issue: null, confidence: 0 };
    }
  }
  
  async checkBiasDetection(response) {
    // Simple bias detection
    const biasPatterns = [
      /\b(?:all|most|every)\s+(?:women|men|people)\s+(?:are|do|have)\b/i,
      /\b(?:typical|usually|always)\s+(?:black|white|asian|hispanic)\s+people/i,
      /\b(?:real|true)\s+(?:man|woman)\s+(?:should|must|needs)/i
    ];
    
    const content = response.content || '';
    
    for (const pattern of biasPatterns) {
      if (pattern.test(content)) {
        return {
          issue: 'potential_bias',
          confidence: 0.6,
          severity: 'medium',
          pattern: pattern.source
        };
      }
    }
    
    return { issue: null, confidence: 0 };
  }
  
  getModerationReason(categories) {
    const flaggedCategories = Object.entries(categories)
      .filter(([_, flagged]) => flagged)
      .map(([category, _]) => category);
    
    return flaggedCategories.length > 0 ? flaggedCategories.join(', ') : 'content_policy_violation';
  }
  
  async hashMessages(messages) {
    const content = JSON.stringify(messages);
    const encoder = new TextEncoder();
    const data = encoder.encode(content);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }
}
```

## Usage Examples

### Complete AI Service Implementation

```javascript
// Complete AI service with all features
export default {
  async fetch(request, env) {
    const ai = new AIService(env);
    const url = new URL(request.url);
    
    try {
      if (url.pathname === '/chat' && request.method === 'POST') {
        return ai.handleChatRequest(request);
      }
      
      if (url.pathname === '/usage' && request.method === 'GET') {
        return ai.handleUsageRequest(request);
      }
      
      if (url.pathname === '/cache/stats' && request.method === 'GET') {
        return ai.handleCacheStatsRequest(request);
      }
      
      return new Response('Not found', { status: 404 });
    } catch (error) {
      console.error('AI service error:', error);
      return new Response('Internal server error', { status: 500 });
    }
  }
};

class AIService {
  constructor(env) {
    this.env = env;
    this.cache = new SmartAICache(env);
    this.rateLimiter = new AIRateLimiter(env);
    this.moderator = new AIContentModerator(env);
  }
  
  async handleChatRequest(request) {
    const { messages, options = {}, userId } = await request.json();
    
    if (!messages || !Array.isArray(messages)) {
      return new Response('Invalid messages format', { status: 400 });
    }
    
    // Content moderation
    const moderationResult = await this.moderator.moderateRequest(messages, options);
    if (!moderationResult.allowed) {
      return Response.json({
        error: 'Content policy violation',
        violations: moderationResult.violations
      }, { status: 400 });
    }
    
    // Rate limiting
    const requestEstimate = this.rateLimiter.estimateRequest(messages, options);
    const rateLimitResult = await this.rateLimiter.checkLimits(userId, requestEstimate);
    
    if (!rateLimitResult.allowed) {
      return Response.json({
        error: 'Rate limit exceeded',
        failures: rateLimitResult.failures,
        retryAfter: rateLimitResult.retryAfter
      }, { 
        status: 429,
        headers: {
          'Retry-After': rateLimitResult.retryAfter.toString()
        }
      });
    }
    
    // Get AI response (with caching)
    const response = await this.cache.getCachedResponse({ messages }, options);
    
    // Moderate response
    const responseModeration = await this.moderator.moderateResponse(response, messages);
    if (!responseModeration.safe) {
      // Log for review but still return response with warning
      console.warn('Response flagged for review:', responseModeration.issues);
      response.warning = 'Response flagged for manual review';
    }
    
    // Record usage
    if (userId) {
      await this.rateLimiter.recordUsage(userId, {
        tokens: response.usage?.total_tokens || requestEstimate.estimatedTokens,
        cost: requestEstimate.estimatedCost
      });
    }
    
    return Response.json(response);
  }
  
  async handleUsageRequest(request) {
    const url = new URL(request.url);
    const userId = url.searchParams.get('userId');
    const days = parseInt(url.searchParams.get('days') || '7');
    
    if (!userId) {
      return new Response('User ID required', { status: 400 });
    }
    
    const usage = await this.rateLimiter.getUserUsage(userId, days);
    return Response.json(usage);
  }
  
  async handleCacheStatsRequest(request) {
    const url = new URL(request.url);
    const days = parseInt(url.searchParams.get('days') || '7');
    
    const stats = await this.cache.getCacheStats(days);
    return Response.json(stats);
  }
}
```

## Best Practices

### Performance Optimization
- Implement intelligent caching strategies
- Use request batching where possible
- Optimize prompt engineering for cost efficiency
- Monitor and analyze usage patterns

### Cost Management
- Set up usage alerts and limits
- Implement tiered pricing models
- Use caching to reduce API calls
- Monitor cost per request metrics

### Security & Safety
- Always moderate user inputs
- Implement content filtering
- Monitor for prompt injection attempts
- Review flagged responses

### Reliability
- Implement fallback providers
- Use circuit breakers for failing services
- Monitor service health and latency
- Implement retry logic with exponential backoff

## Common Use Cases

1. **Chatbots & Virtual Assistants** - Intelligent customer support and interaction
2. **Content Generation** - Blog posts, marketing copy, and creative writing
3. **Code Assistance** - Code completion, debugging, and documentation
4. **Translation Services** - Multi-language content translation
5. **Content Moderation** - Automated safety and policy enforcement
6. **Analytics & Insights** - Data analysis and report generation

AI Gateway provides the infrastructure layer needed to build robust, scalable, and cost-effective AI-powered applications with proper monitoring, caching, and safety controls.
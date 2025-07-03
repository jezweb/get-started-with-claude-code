# Workers AI Patterns

Comprehensive guide to building AI-powered applications with Cloudflare Workers AI, including model selection, edge inference, and optimization strategies.

## 🎯 What is Workers AI?

Workers AI runs machine learning models on Cloudflare's global network:
- **Edge Inference** - Run models close to users globally
- **No Infrastructure** - Zero configuration or maintenance
- **Pay-per-request** - No idle costs or GPU management
- **Built-in Models** - Curated selection of optimized models
- **Privacy-First** - Data never leaves the region
- **Integrated Platform** - Works seamlessly with Workers, R2, D1

## 🚀 Quick Start

### Basic Setup

```javascript
// wrangler.toml
name = "my-ai-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"

[ai]
binding = "AI"

// src/index.js
export default {
  async fetch(request, env) {
    const response = await env.AI.run(
      '@cf/meta/llama-2-7b-chat-int8',
      {
        messages: [
          { role: 'system', content: 'You are a helpful assistant.' },
          { role: 'user', content: 'What is the capital of France?' }
        ]
      }
    )
    
    return Response.json(response)
  }
}
```

### Available Model Categories

```javascript
// Text Generation
const textModels = [
  '@cf/meta/llama-2-7b-chat-int8',
  '@cf/meta/llama-2-7b-chat-fp16',
  '@cf/mistral/mistral-7b-instruct-v0.1',
  '@cf/thebloke/discolm-german-7b-v1-awq',
  '@cf/tiiuae/falcon-7b-instruct'
]

// Text Embeddings
const embeddingModels = [
  '@cf/baai/bge-base-en-v1.5',
  '@cf/baai/bge-large-en-v1.5',
  '@cf/baai/bge-small-en-v1.5'
]

// Image Classification
const imageModels = [
  '@cf/microsoft/resnet-50'
]

// Speech Recognition
const speechModels = [
  '@cf/openai/whisper'
]

// Translation
const translationModels = [
  '@cf/meta/m2m100-1.2b'
]
```

## 🧠 Model Patterns

### Text Generation

```javascript
// Advanced text generation with parameters
export default {
  async fetch(request, env) {
    const { prompt, maxTokens = 256, temperature = 0.7 } = await request.json()
    
    try {
      const response = await env.AI.run(
        '@cf/meta/llama-2-7b-chat-int8',
        {
          prompt,
          max_tokens: maxTokens,
          temperature,
          top_p: 0.9,
          top_k: 40,
          repetition_penalty: 1.1,
          stream: false
        }
      )
      
      return Response.json({
        success: true,
        response: response.response,
        usage: {
          prompt_tokens: response.prompt_tokens,
          completion_tokens: response.completion_tokens
        }
      })
    } catch (error) {
      return Response.json({
        success: false,
        error: error.message
      }, { status: 500 })
    }
  }
}

// Streaming responses
export async function streamChat(env, messages) {
  const stream = await env.AI.run(
    '@cf/meta/llama-2-7b-chat-int8',
    {
      messages,
      stream: true
    }
  )
  
  // Return SSE stream
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
  })
}
```

### Embeddings & Semantic Search

```javascript
// Generate embeddings for semantic search
class EmbeddingService {
  constructor(env) {
    this.env = env
    this.model = '@cf/baai/bge-base-en-v1.5'
  }
  
  async generateEmbedding(text) {
    const response = await this.env.AI.run(this.model, {
      text: [text]
    })
    
    return response.data[0]
  }
  
  async generateBatchEmbeddings(texts) {
    // Batch process for efficiency
    const batchSize = 100
    const embeddings = []
    
    for (let i = 0; i < texts.length; i += batchSize) {
      const batch = texts.slice(i, i + batchSize)
      const response = await this.env.AI.run(this.model, {
        text: batch
      })
      
      embeddings.push(...response.data)
    }
    
    return embeddings
  }
  
  cosineSimilarity(a, b) {
    let dotProduct = 0
    let normA = 0
    let normB = 0
    
    for (let i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i]
      normA += a[i] * a[i]
      normB += b[i] * b[i]
    }
    
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB))
  }
  
  async semanticSearch(query, documents) {
    const queryEmbedding = await this.generateEmbedding(query)
    const docEmbeddings = await this.generateBatchEmbeddings(
      documents.map(d => d.content)
    )
    
    const results = documents.map((doc, i) => ({
      ...doc,
      score: this.cosineSimilarity(queryEmbedding, docEmbeddings[i])
    }))
    
    return results.sort((a, b) => b.score - a.score)
  }
}
```

### Image Classification

```javascript
// Image classification with caching
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)
    const imageUrl = url.searchParams.get('url')
    
    if (!imageUrl) {
      return Response.json({ error: 'Missing image URL' }, { status: 400 })
    }
    
    // Check cache first
    const cacheKey = new Request(url.toString(), request)
    const cache = caches.default
    let response = await cache.match(cacheKey)
    
    if (!response) {
      try {
        // Fetch image
        const imageResponse = await fetch(imageUrl)
        const imageBlob = await imageResponse.blob()
        const imageArray = await imageBlob.arrayBuffer()
        
        // Run classification
        const result = await env.AI.run(
          '@cf/microsoft/resnet-50',
          {
            image: [...new Uint8Array(imageArray)]
          }
        )
        
        // Process results
        const topResults = result
          .sort((a, b) => b.score - a.score)
          .slice(0, 5)
          .map(item => ({
            label: item.label,
            confidence: Math.round(item.score * 100) / 100
          }))
        
        response = Response.json({
          success: true,
          results: topResults,
          model: '@cf/microsoft/resnet-50'
        })
        
        // Cache for 1 hour
        response.headers.set('Cache-Control', 'public, max-age=3600')
        ctx.waitUntil(cache.put(cacheKey, response.clone()))
        
      } catch (error) {
        response = Response.json({
          success: false,
          error: error.message
        }, { status: 500 })
      }
    }
    
    return response
  }
}
```

### Speech Recognition

```javascript
// Speech-to-text with Whisper
export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }
    
    const formData = await request.formData()
    const audioFile = formData.get('audio')
    
    if (!audioFile) {
      return Response.json({ error: 'No audio file provided' }, { status: 400 })
    }
    
    try {
      const audioArray = await audioFile.arrayBuffer()
      
      const response = await env.AI.run(
        '@cf/openai/whisper',
        {
          audio: [...new Uint8Array(audioArray)]
        }
      )
      
      return Response.json({
        success: true,
        text: response.text,
        // Optional: word-level timestamps
        words: response.words,
        // Language detection
        language: response.language,
        // Confidence scores
        confidence: response.confidence
      })
    } catch (error) {
      return Response.json({
        success: false,
        error: error.message
      }, { status: 500 })
    }
  }
}
```

### Translation

```javascript
// Multi-language translation service
class TranslationService {
  constructor(env) {
    this.env = env
    this.model = '@cf/meta/m2m100-1.2b'
    
    // Language codes supported by M2M100
    this.languages = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'nl': 'Dutch',
      'pl': 'Polish',
      'ru': 'Russian',
      'ja': 'Japanese',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi'
    }
  }
  
  async translate(text, sourceLang, targetLang) {
    if (!this.languages[sourceLang] || !this.languages[targetLang]) {
      throw new Error('Unsupported language')
    }
    
    const response = await this.env.AI.run(this.model, {
      text,
      source_lang: sourceLang,
      target_lang: targetLang
    })
    
    return response.translated_text
  }
  
  async detectLanguage(text) {
    // Use translation model to detect language
    // by attempting translation from 'auto'
    try {
      const response = await this.env.AI.run(this.model, {
        text,
        source_lang: 'auto',
        target_lang: 'en'
      })
      
      return response.detected_source_lang
    } catch (error) {
      return null
    }
  }
  
  async batchTranslate(texts, sourceLang, targetLang) {
    const translations = []
    
    // Process in batches to avoid timeouts
    for (const text of texts) {
      const translated = await this.translate(text, sourceLang, targetLang)
      translations.push(translated)
    }
    
    return translations
  }
}
```

## 🔧 Advanced Patterns

### Chain of Thought Reasoning

```javascript
// Implement step-by-step reasoning
class ChainOfThoughtAI {
  constructor(env) {
    this.env = env
    this.model = '@cf/meta/llama-2-7b-chat-int8'
  }
  
  async reason(question, context = '') {
    const steps = []
    
    // Step 1: Break down the problem
    const breakdown = await this.runStep(
      `Break down this problem into logical steps: ${question}`,
      context
    )
    steps.push({ step: 'breakdown', result: breakdown })
    
    // Step 2: Analyze each component
    const analysis = await this.runStep(
      `Analyze each component of: ${breakdown}`,
      context
    )
    steps.push({ step: 'analysis', result: analysis })
    
    // Step 3: Synthesize solution
    const solution = await this.runStep(
      `Based on the analysis, provide a solution: ${analysis}`,
      context
    )
    steps.push({ step: 'solution', result: solution })
    
    // Step 4: Verify solution
    const verification = await this.runStep(
      `Verify this solution is correct: ${solution} for problem: ${question}`,
      context
    )
    steps.push({ step: 'verification', result: verification })
    
    return {
      question,
      steps,
      finalAnswer: solution,
      confidence: this.calculateConfidence(verification)
    }
  }
  
  async runStep(prompt, context) {
    const response = await this.env.AI.run(this.model, {
      prompt: `${context}\n\n${prompt}\n\nThink step by step:`,
      max_tokens: 256,
      temperature: 0.7
    })
    
    return response.response
  }
  
  calculateConfidence(verification) {
    // Simple confidence scoring based on verification
    const keywords = ['correct', 'accurate', 'valid', 'confirmed']
    const matches = keywords.filter(word => 
      verification.toLowerCase().includes(word)
    ).length
    
    return Math.min(0.2 + (matches * 0.2), 1.0)
  }
}
```

### Function Calling Pattern

```javascript
// Implement function calling with Workers AI
class AIFunctionCaller {
  constructor(env) {
    this.env = env
    this.functions = new Map()
  }
  
  registerFunction(name, schema, handler) {
    this.functions.set(name, { schema, handler })
  }
  
  async processRequest(userInput) {
    // Step 1: Determine intent and extract parameters
    const intent = await this.extractIntent(userInput)
    
    if (!intent.functionName || !this.functions.has(intent.functionName)) {
      return {
        success: false,
        message: "I couldn't understand what you want me to do."
      }
    }
    
    // Step 2: Validate parameters
    const func = this.functions.get(intent.functionName)
    const validation = this.validateParameters(intent.parameters, func.schema)
    
    if (!validation.valid) {
      return {
        success: false,
        message: `Invalid parameters: ${validation.errors.join(', ')}`
      }
    }
    
    // Step 3: Execute function
    try {
      const result = await func.handler(intent.parameters)
      return {
        success: true,
        result,
        function: intent.functionName
      }
    } catch (error) {
      return {
        success: false,
        error: error.message
      }
    }
  }
  
  async extractIntent(userInput) {
    const functionsDesc = Array.from(this.functions.entries())
      .map(([name, { schema }]) => `${name}: ${schema.description}`)
      .join('\n')
    
    const prompt = `
    Available functions:
    ${functionsDesc}
    
    User input: "${userInput}"
    
    Extract the function name and parameters in JSON format:
    `
    
    const response = await this.env.AI.run(
      '@cf/meta/llama-2-7b-chat-int8',
      {
        prompt,
        max_tokens: 256,
        temperature: 0.3
      }
    )
    
    try {
      // Extract JSON from response
      const jsonMatch = response.response.match(/{[^}]+}/)
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0])
      }
    } catch (e) {
      console.error('Failed to parse intent:', e)
    }
    
    return {}
  }
  
  validateParameters(params, schema) {
    const errors = []
    
    // Check required parameters
    for (const [key, config] of Object.entries(schema.parameters)) {
      if (config.required && !params[key]) {
        errors.push(`Missing required parameter: ${key}`)
      }
      
      if (params[key] && config.type) {
        const actualType = typeof params[key]
        if (actualType !== config.type) {
          errors.push(`Parameter ${key} should be ${config.type}, got ${actualType}`)
        }
      }
    }
    
    return {
      valid: errors.length === 0,
      errors
    }
  }
}

// Example usage
const functionCaller = new AIFunctionCaller(env)

functionCaller.registerFunction('weather', {
  description: 'Get weather information for a location',
  parameters: {
    location: { type: 'string', required: true },
    units: { type: 'string', required: false }
  }
}, async (params) => {
  // Implementation
  return `Weather in ${params.location}: Sunny, 72°F`
})
```

### RAG (Retrieval-Augmented Generation)

```javascript
// RAG implementation with Workers AI
class RAGSystem {
  constructor(env) {
    this.env = env
    this.embeddingModel = '@cf/baai/bge-base-en-v1.5'
    this.generationModel = '@cf/meta/llama-2-7b-chat-int8'
  }
  
  async query(question, documents) {
    // Step 1: Generate embeddings for question
    const questionEmbedding = await this.generateEmbedding(question)
    
    // Step 2: Find relevant documents
    const relevantDocs = await this.findRelevantDocuments(
      questionEmbedding,
      documents
    )
    
    // Step 3: Generate context from relevant documents
    const context = this.buildContext(relevantDocs)
    
    // Step 4: Generate answer using context
    const answer = await this.generateAnswer(question, context)
    
    return {
      answer,
      sources: relevantDocs.map(doc => ({
        title: doc.title,
        relevance: doc.score
      }))
    }
  }
  
  async generateEmbedding(text) {
    const response = await this.env.AI.run(this.embeddingModel, {
      text: [text]
    })
    return response.data[0]
  }
  
  async findRelevantDocuments(queryEmbedding, documents, topK = 3) {
    const scoredDocs = []
    
    for (const doc of documents) {
      const docEmbedding = await this.generateEmbedding(doc.content)
      const score = this.cosineSimilarity(queryEmbedding, docEmbedding)
      scoredDocs.push({ ...doc, score })
    }
    
    return scoredDocs
      .sort((a, b) => b.score - a.score)
      .slice(0, topK)
  }
  
  buildContext(documents) {
    return documents
      .map(doc => `${doc.title}:\n${doc.content}`)
      .join('\n\n---\n\n')
  }
  
  async generateAnswer(question, context) {
    const prompt = `
    Context information:
    ${context}
    
    Based on the above context, please answer the following question:
    ${question}
    
    If the answer cannot be found in the context, say "I don't have enough information to answer this question."
    `
    
    const response = await this.env.AI.run(this.generationModel, {
      prompt,
      max_tokens: 512,
      temperature: 0.7
    })
    
    return response.response
  }
  
  cosineSimilarity(a, b) {
    let dotProduct = 0
    let normA = 0
    let normB = 0
    
    for (let i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i]
      normA += a[i] * a[i]
      normB += b[i] * b[i]
    }
    
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB))
  }
}
```

### Model Chaining

```javascript
// Chain multiple models for complex tasks
class ModelChain {
  constructor(env) {
    this.env = env
  }
  
  async summarizeAndTranslate(text, targetLang) {
    // Step 1: Summarize the text
    const summary = await this.env.AI.run(
      '@cf/meta/llama-2-7b-chat-int8',
      {
        prompt: `Summarize the following text in 2-3 sentences:\n\n${text}`,
        max_tokens: 150
      }
    )
    
    // Step 2: Translate the summary
    const translation = await this.env.AI.run(
      '@cf/meta/m2m100-1.2b',
      {
        text: summary.response,
        source_lang: 'en',
        target_lang: targetLang
      }
    )
    
    return {
      originalLength: text.length,
      summary: summary.response,
      translation: translation.translated_text,
      targetLanguage: targetLang
    }
  }
  
  async analyzeAndClassify(imageUrl, additionalContext) {
    // Step 1: Classify image
    const imageResponse = await fetch(imageUrl)
    const imageBlob = await imageResponse.blob()
    const imageArray = await imageBlob.arrayBuffer()
    
    const classification = await this.env.AI.run(
      '@cf/microsoft/resnet-50',
      {
        image: [...new Uint8Array(imageArray)]
      }
    )
    
    // Step 2: Generate description based on classification
    const topLabel = classification[0].label
    const prompt = `
    An image has been classified as "${topLabel}".
    Additional context: ${additionalContext}
    
    Provide a detailed description of what this might represent:
    `
    
    const description = await this.env.AI.run(
      '@cf/meta/llama-2-7b-chat-int8',
      {
        prompt,
        max_tokens: 256
      }
    )
    
    return {
      classification: classification.slice(0, 3),
      description: description.response
    }
  }
}
```

## 🚀 Performance Optimization

### Request Batching

```javascript
// Batch multiple AI requests for efficiency
class AIBatcher {
  constructor(env) {
    this.env = env
    this.queue = []
    this.processing = false
    this.batchSize = 10
    this.batchTimeout = 50 // ms
  }
  
  async add(request) {
    return new Promise((resolve, reject) => {
      this.queue.push({ request, resolve, reject })
      this.processBatch()
    })
  }
  
  async processBatch() {
    if (this.processing || this.queue.length === 0) return
    
    // Wait for more requests or timeout
    if (this.queue.length < this.batchSize) {
      await new Promise(resolve => setTimeout(resolve, this.batchTimeout))
    }
    
    this.processing = true
    const batch = this.queue.splice(0, this.batchSize)
    
    try {
      // Process batch in parallel
      const promises = batch.map(({ request }) => 
        this.env.AI.run(request.model, request.input)
      )
      
      const results = await Promise.all(promises)
      
      // Resolve individual promises
      batch.forEach(({ resolve }, index) => {
        resolve(results[index])
      })
    } catch (error) {
      // Reject all promises in batch
      batch.forEach(({ reject }) => {
        reject(error)
      })
    } finally {
      this.processing = false
      
      // Process next batch if queue has items
      if (this.queue.length > 0) {
        this.processBatch()
      }
    }
  }
}
```

### Caching Strategies

```javascript
// Intelligent caching for AI responses
class AICache {
  constructor(env) {
    this.env = env
    this.cache = caches.default
  }
  
  async get(model, input, options = {}) {
    const cacheKey = this.generateCacheKey(model, input)
    
    // Check cache
    const cached = await this.cache.match(cacheKey)
    if (cached) {
      const data = await cached.json()
      if (Date.now() - data.timestamp < (options.maxAge || 3600000)) {
        return { ...data.response, cached: true }
      }
    }
    
    // Generate fresh response
    const response = await this.env.AI.run(model, input)
    
    // Cache response
    await this.cache.put(cacheKey, Response.json({
      response,
      timestamp: Date.now(),
      model,
      input
    }))
    
    return response
  }
  
  generateCacheKey(model, input) {
    const hash = btoa(JSON.stringify({ model, input }))
      .replace(/[^a-zA-Z0-9]/g, '')
      .substring(0, 32)
    
    return new Request(`https://cache.ai/${model}/${hash}`)
  }
  
  async invalidate(pattern) {
    // Invalidate cache entries matching pattern
    // Note: This is a simplified example
    const keys = await this.cache.keys()
    
    for (const key of keys) {
      if (key.url.includes(pattern)) {
        await this.cache.delete(key)
      }
    }
  }
}
```

## 🔍 Error Handling & Monitoring

```javascript
// Comprehensive error handling
class AIErrorHandler {
  constructor(env) {
    this.env = env
    this.errorCounts = new Map()
  }
  
  async runWithRetry(model, input, options = {}) {
    const maxRetries = options.maxRetries || 3
    const backoffMs = options.backoffMs || 1000
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.env.AI.run(model, input)
      } catch (error) {
        this.recordError(model, error)
        
        if (attempt === maxRetries) {
          throw new Error(`AI request failed after ${maxRetries} attempts: ${error.message}`)
        }
        
        // Exponential backoff
        const delay = backoffMs * Math.pow(2, attempt - 1)
        await new Promise(resolve => setTimeout(resolve, delay))
      }
    }
  }
  
  recordError(model, error) {
    const key = `${model}:${error.message}`
    this.errorCounts.set(key, (this.errorCounts.get(key) || 0) + 1)
    
    // Log to analytics
    this.logError({
      model,
      error: error.message,
      timestamp: new Date().toISOString(),
      count: this.errorCounts.get(key)
    })
  }
  
  async logError(data) {
    // Send to analytics service
    await this.env.ANALYTICS.writeDataPoint({
      series: 'ai_errors',
      tags: { model: data.model },
      fields: { count: data.count },
      timestamp: Date.now()
    })
  }
}

// Monitoring wrapper
export default {
  async fetch(request, env, ctx) {
    const startTime = Date.now()
    const url = new URL(request.url)
    const model = url.pathname.split('/')[2]
    
    try {
      const response = await handleAIRequest(request, env)
      
      // Record metrics
      ctx.waitUntil(
        env.ANALYTICS.writeDataPoint({
          series: 'ai_requests',
          tags: { model, status: 'success' },
          fields: {
            duration: Date.now() - startTime,
            tokens: response.usage?.total_tokens || 0
          },
          timestamp: Date.now()
        })
      )
      
      return response
    } catch (error) {
      // Record error metrics
      ctx.waitUntil(
        env.ANALYTICS.writeDataPoint({
          series: 'ai_requests',
          tags: { model, status: 'error', error_type: error.name },
          fields: { duration: Date.now() - startTime },
          timestamp: Date.now()
        })
      )
      
      throw error
    }
  }
}
```

## 📚 Best Practices

### 1. **Model Selection**
- Use lighter models (int8) for simple tasks
- Reserve larger models for complex reasoning
- Consider latency vs accuracy tradeoffs
- Test different models for your use case

### 2. **Edge Optimization**
- Implement aggressive caching
- Use regional inference when possible
- Batch requests when feasible
- Monitor cold start performance

### 3. **Cost Management**
- Track token usage per request
- Implement user quotas
- Use streaming for long responses
- Cache common queries

### 4. **Security**
- Validate and sanitize inputs
- Implement rate limiting
- Use Cloudflare Access for authentication
- Never expose sensitive data in prompts

### 5. **Reliability**
- Implement retry logic
- Have fallback responses
- Monitor model availability
- Set appropriate timeouts

## 📖 Resources & References

### Official Documentation
- [Workers AI Documentation](https://developers.cloudflare.com/workers-ai/)
- [Available Models](https://developers.cloudflare.com/workers-ai/models/)
- [Pricing Calculator](https://developers.cloudflare.com/workers-ai/pricing/)
- [API Reference](https://developers.cloudflare.com/workers-ai/configuration/bindings/)

### Example Projects
- **AI Chat Bot** - Full-featured chatbot
- **Image Analyzer** - Multi-model image processing
- **Translation API** - Multi-language support
- **Document Q&A** - RAG implementation

### Tools & Libraries
- **Wrangler** - CLI for Workers development
- **Miniflare** - Local Workers development
- **Workers Analytics Engine** - Built-in analytics
- **Vectorize** - Vector database for embeddings

---

*This guide covers essential Workers AI patterns for building intelligent edge applications. Focus on model selection, caching, and edge optimization for best results.*
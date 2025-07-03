# AI SDK Integration Guide

Comprehensive guide to integrating popular AI SDKs including OpenAI, Anthropic Claude, Google Gemini, and specialized AI services for building intelligent applications.

## 🎯 SDK Overview

Modern AI SDKs provide structured interfaces to AI services:
- **Type Safety** - Strongly typed responses and parameters
- **Error Handling** - Consistent error management
- **Streaming** - Real-time response streaming
- **Retries** - Automatic retry logic
- **Observability** - Built-in logging and monitoring
- **Multi-Modal** - Support for text, images, and more

## 🚀 Quick Start

### Installing AI SDKs

```bash
# OpenAI SDK
npm install openai

# Anthropic Claude SDK
npm install @anthropic-ai/sdk

# Google Generative AI (Gemini)
npm install @google/generative-ai

# Vercel AI SDK (unified interface)
npm install ai @ai-sdk/openai @ai-sdk/anthropic

# LangChain (orchestration)
npm install langchain @langchain/openai @langchain/anthropic
```

### Basic Setup

```javascript
// Environment configuration
// .env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_AI_API_KEY=...
```

## 🧠 OpenAI SDK Integration

### Basic Chat Completion

```javascript
import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
})

// Simple completion
async function getChatCompletion(prompt) {
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
      messages: [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 1000
    })
    
    return completion.choices[0].message.content
  } catch (error) {
    if (error instanceof OpenAI.APIError) {
      console.error('OpenAI API Error:', error.status, error.message)
    }
    throw error
  }
}

// Streaming response
async function streamChatCompletion(prompt, onChunk) {
  const stream = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [{ role: 'user', content: prompt }],
    stream: true,
  })
  
  for await (const chunk of stream) {
    const content = chunk.choices[0]?.delta?.content || ''
    if (content) {
      onChunk(content)
    }
  }
}
```

### Function Calling

```javascript
// Define tools/functions
const tools = [
  {
    type: 'function',
    function: {
      name: 'get_weather',
      description: 'Get the current weather in a location',
      parameters: {
        type: 'object',
        properties: {
          location: {
            type: 'string',
            description: 'The city and state, e.g. San Francisco, CA'
          },
          unit: {
            type: 'string',
            enum: ['celsius', 'fahrenheit']
          }
        },
        required: ['location']
      }
    }
  }
]

// Function calling implementation
async function chatWithFunctions(messages) {
  const response = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages,
    tools,
    tool_choice: 'auto'
  })
  
  const message = response.choices[0].message
  
  // Check if the model wants to call a function
  if (message.tool_calls) {
    const toolCall = message.tool_calls[0]
    const functionName = toolCall.function.name
    const functionArgs = JSON.parse(toolCall.function.arguments)
    
    // Execute the function
    let functionResult
    if (functionName === 'get_weather') {
      functionResult = await getWeather(functionArgs.location, functionArgs.unit)
    }
    
    // Add the function result to messages
    messages.push(message)
    messages.push({
      role: 'tool',
      tool_call_id: toolCall.id,
      content: JSON.stringify(functionResult)
    })
    
    // Get the final response
    const finalResponse = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
      messages
    })
    
    return finalResponse.choices[0].message.content
  }
  
  return message.content
}
```

### Vision API

```javascript
// Image analysis with GPT-4 Vision
async function analyzeImage(imageUrl, prompt) {
  const response = await openai.chat.completions.create({
    model: 'gpt-4-vision-preview',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          {
            type: 'image_url',
            image_url: {
              url: imageUrl,
              detail: 'high' // 'low', 'high', or 'auto'
            }
          }
        ]
      }
    ],
    max_tokens: 1000
  })
  
  return response.choices[0].message.content
}

// Multiple images
async function compareImages(imageUrls, prompt) {
  const content = [
    { type: 'text', text: prompt },
    ...imageUrls.map(url => ({
      type: 'image_url',
      image_url: { url }
    }))
  ]
  
  const response = await openai.chat.completions.create({
    model: 'gpt-4-vision-preview',
    messages: [{ role: 'user', content }]
  })
  
  return response.choices[0].message.content
}
```

### Embeddings

```javascript
// Generate embeddings for semantic search
async function generateEmbedding(text) {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
    encoding_format: 'float'
  })
  
  return response.data[0].embedding
}

// Batch embeddings
async function generateBatchEmbeddings(texts) {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: texts
  })
  
  return response.data.map(item => item.embedding)
}

// Semantic search implementation
class SemanticSearch {
  constructor(openai) {
    this.openai = openai
    this.embeddings = new Map()
  }
  
  async addDocument(id, text) {
    const embedding = await generateEmbedding(text)
    this.embeddings.set(id, { text, embedding })
  }
  
  async search(query, topK = 5) {
    const queryEmbedding = await generateEmbedding(query)
    
    const results = []
    for (const [id, doc] of this.embeddings) {
      const similarity = this.cosineSimilarity(queryEmbedding, doc.embedding)
      results.push({ id, text: doc.text, similarity })
    }
    
    return results
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, topK)
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

## 🤖 Anthropic Claude SDK

### Basic Usage

```javascript
import Anthropic from '@anthropic-ai/sdk'

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
})

// Chat completion
async function claudeChat(prompt) {
  const message = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 1024,
    temperature: 0.7,
    system: 'You are a helpful AI assistant.',
    messages: [
      { role: 'user', content: prompt }
    ]
  })
  
  return message.content[0].text
}

// Streaming
async function claudeStream(prompt, onChunk) {
  const stream = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 1024,
    messages: [{ role: 'user', content: prompt }],
    stream: true,
  })
  
  for await (const messageStreamEvent of stream) {
    if (messageStreamEvent.type === 'content_block_delta') {
      onChunk(messageStreamEvent.delta.text)
    }
  }
}
```

### Vision with Claude

```javascript
// Image analysis with Claude
async function analyzeImageClaude(imageBase64, prompt) {
  const message = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: 'image/jpeg',
              data: imageBase64
            }
          },
          {
            type: 'text',
            text: prompt
          }
        ]
      }
    ]
  })
  
  return message.content[0].text
}

// Multiple images and text
async function multiModalAnalysis(contents) {
  const message = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content: contents // Array of text and image objects
      }
    ]
  })
  
  return message.content[0].text
}
```

### Advanced Claude Features

```javascript
// Long context handling
async function processLongDocument(document) {
  // Claude 3 supports up to 200k tokens
  const chunks = splitIntoChunks(document, 150000) // Leave room for response
  
  let context = ''
  for (const chunk of chunks) {
    const response = await anthropic.messages.create({
      model: 'claude-3-opus-20240229',
      max_tokens: 4096,
      messages: [
        {
          role: 'user',
          content: `Previous context: ${context}\n\nContinue analyzing this document:\n${chunk}`
        }
      ]
    })
    
    context = response.content[0].text
  }
  
  return context
}

// Tool use with Claude
async function claudeWithTools(prompt) {
  const response = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 1024,
    tools: [
      {
        name: 'get_weather',
        description: 'Get weather for a location',
        input_schema: {
          type: 'object',
          properties: {
            location: { type: 'string' }
          },
          required: ['location']
        }
      }
    ],
    messages: [{ role: 'user', content: prompt }]
  })
  
  // Handle tool calls
  if (response.stop_reason === 'tool_use') {
    const toolUse = response.content.find(c => c.type === 'tool_use')
    if (toolUse && toolUse.name === 'get_weather') {
      const weather = await getWeather(toolUse.input.location)
      
      // Continue conversation with tool result
      const finalResponse = await anthropic.messages.create({
        model: 'claude-3-opus-20240229',
        max_tokens: 1024,
        messages: [
          { role: 'user', content: prompt },
          { role: 'assistant', content: response.content },
          { 
            role: 'user', 
            content: [{
              type: 'tool_result',
              tool_use_id: toolUse.id,
              content: JSON.stringify(weather)
            }]
          }
        ]
      })
      
      return finalResponse.content[0].text
    }
  }
  
  return response.content[0].text
}
```

## 💎 Google Gemini SDK

### Basic Setup

```javascript
import { GoogleGenerativeAI } from '@google/generative-ai'

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY)

// Text generation
async function generateWithGemini(prompt) {
  const model = genAI.getGenerativeModel({ model: 'gemini-pro' })
  
  const result = await model.generateContent(prompt)
  const response = await result.response
  
  return response.text()
}

// Streaming
async function streamGemini(prompt, onChunk) {
  const model = genAI.getGenerativeModel({ model: 'gemini-pro' })
  
  const result = await model.generateContentStream(prompt)
  
  for await (const chunk of result.stream) {
    const chunkText = chunk.text()
    onChunk(chunkText)
  }
}
```

### Multi-Modal with Gemini

```javascript
// Image analysis
async function analyzeImageGemini(imagePath, prompt) {
  const model = genAI.getGenerativeModel({ model: 'gemini-pro-vision' })
  
  const imageParts = [
    {
      inlineData: {
        data: Buffer.from(fs.readFileSync(imagePath)).toString('base64'),
        mimeType: 'image/jpeg'
      }
    }
  ]
  
  const result = await model.generateContent([prompt, ...imageParts])
  const response = await result.response
  
  return response.text()
}

// Multi-turn conversations
async function chatWithGemini() {
  const model = genAI.getGenerativeModel({ model: 'gemini-pro' })
  
  const chat = model.startChat({
    history: [
      {
        role: 'user',
        parts: [{ text: 'Hello, I want to learn about space' }],
      },
      {
        role: 'model',
        parts: [{ text: 'Great! What would you like to know about space?' }],
      },
    ],
    generationConfig: {
      maxOutputTokens: 1000,
      temperature: 0.9,
    },
  })
  
  const result = await chat.sendMessage('Tell me about black holes')
  return result.response.text()
}
```

### Advanced Gemini Features

```javascript
// Function calling with Gemini
const functionDeclarations = [
  {
    name: 'getWeather',
    description: 'Get weather for a location',
    parameters: {
      type: 'object',
      properties: {
        location: {
          type: 'string',
          description: 'City and state'
        },
        unit: {
          type: 'string',
          enum: ['celsius', 'fahrenheit']
        }
      },
      required: ['location']
    }
  }
]

async function geminiWithFunctions(prompt) {
  const model = genAI.getGenerativeModel({
    model: 'gemini-pro',
    tools: [{ functionDeclarations }]
  })
  
  const result = await model.generateContent(prompt)
  const response = await result.response
  
  // Check for function calls
  const functionCall = response.functionCalls?.[0]
  if (functionCall) {
    const functionResponse = await executeFunction(
      functionCall.name,
      functionCall.args
    )
    
    // Send function response back
    const result2 = await model.generateContent([
      prompt,
      {
        functionResponse: {
          name: functionCall.name,
          response: functionResponse
        }
      }
    ])
    
    return result2.response.text()
  }
  
  return response.text()
}

// Safety settings
async function generateWithSafety(prompt) {
  const model = genAI.getGenerativeModel({
    model: 'gemini-pro',
    safetySettings: [
      {
        category: HarmCategory.HARM_CATEGORY_HARASSMENT,
        threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
      },
      {
        category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
        threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
      },
    ],
  })
  
  try {
    const result = await model.generateContent(prompt)
    return result.response.text()
  } catch (error) {
    if (error.message.includes('blocked')) {
      return 'Content was blocked due to safety filters'
    }
    throw error
  }
}
```

## 🔧 Unified AI SDK Patterns

### Vercel AI SDK

```javascript
import { openai } from '@ai-sdk/openai'
import { anthropic } from '@ai-sdk/anthropic'
import { streamText, generateText } from 'ai'

// Unified interface for multiple providers
async function unifiedGenerate(prompt, provider = 'openai') {
  const model = provider === 'openai' 
    ? openai('gpt-4-turbo-preview')
    : anthropic('claude-3-opus-20240229')
  
  const { text } = await generateText({
    model,
    prompt,
    temperature: 0.7,
    maxTokens: 1000,
  })
  
  return text
}

// Streaming with any provider
async function unifiedStream(prompt, provider = 'openai') {
  const model = provider === 'openai'
    ? openai('gpt-4-turbo-preview')
    : anthropic('claude-3-opus-20240229')
  
  const result = await streamText({
    model,
    prompt,
  })
  
  // Use in server-sent events
  return result.toAIStreamResponse()
}

// Tool calling with unified interface
async function unifiedToolCalling(prompt) {
  const { text, toolCalls } = await generateText({
    model: openai('gpt-4-turbo-preview'),
    prompt,
    tools: {
      weather: {
        description: 'Get weather information',
        parameters: z.object({
          location: z.string(),
        }),
        execute: async ({ location }) => {
          return getWeather(location)
        },
      },
    },
  })
  
  return { text, toolCalls }
}
```

### LangChain Integration

```javascript
import { ChatOpenAI } from '@langchain/openai'
import { ChatAnthropic } from '@langchain/anthropic'
import { ChatGoogleGenerativeAI } from '@langchain/google-genai'
import { ChatPromptTemplate } from '@langchain/core/prompts'
import { RunnableSequence } from '@langchain/core/runnables'

// Multi-provider chain
class MultiProviderChain {
  constructor() {
    this.providers = {
      openai: new ChatOpenAI({
        modelName: 'gpt-4-turbo-preview',
        temperature: 0.7,
      }),
      anthropic: new ChatAnthropic({
        modelName: 'claude-3-opus-20240229',
        temperature: 0.7,
      }),
      gemini: new ChatGoogleGenerativeAI({
        modelName: 'gemini-pro',
        temperature: 0.7,
      }),
    }
  }
  
  async run(prompt, provider = 'openai') {
    const model = this.providers[provider]
    
    const promptTemplate = ChatPromptTemplate.fromMessages([
      ['system', 'You are a helpful assistant.'],
      ['user', '{input}'],
    ])
    
    const chain = RunnableSequence.from([
      promptTemplate,
      model,
      (response) => response.content,
    ])
    
    return chain.invoke({ input: prompt })
  }
}

// RAG with LangChain
import { MemoryVectorStore } from 'langchain/vectorstores/memory'
import { OpenAIEmbeddings } from '@langchain/openai'
import { RetrievalQAChain } from 'langchain/chains'

async function createRAGChain(documents) {
  // Create vector store
  const vectorStore = await MemoryVectorStore.fromDocuments(
    documents,
    new OpenAIEmbeddings()
  )
  
  // Create retrieval chain
  const chain = RetrievalQAChain.fromLLM(
    new ChatOpenAI({ modelName: 'gpt-4-turbo-preview' }),
    vectorStore.asRetriever()
  )
  
  return chain
}

// Agent with tools
import { initializeAgentExecutorWithOptions } from 'langchain/agents'
import { Calculator } from 'langchain/tools/calculator'
import { WebBrowser } from 'langchain/tools/webbrowser'

async function createAgent() {
  const tools = [
    new Calculator(),
    new WebBrowser({ model: new ChatOpenAI() }),
  ]
  
  const agent = await initializeAgentExecutorWithOptions(
    tools,
    new ChatOpenAI({ modelName: 'gpt-4-turbo-preview' }),
    {
      agentType: 'openai-functions',
      verbose: true,
    }
  )
  
  return agent
}
```

## 🚀 Advanced Patterns

### Provider Abstraction Layer

```javascript
// Abstract AI provider interface
class AIProvider {
  async complete(prompt, options = {}) {
    throw new Error('Must implement complete method')
  }
  
  async stream(prompt, options = {}) {
    throw new Error('Must implement stream method')
  }
  
  async embed(text) {
    throw new Error('Must implement embed method')
  }
}

// Provider implementations
class OpenAIProvider extends AIProvider {
  constructor(apiKey) {
    super()
    this.client = new OpenAI({ apiKey })
  }
  
  async complete(prompt, options = {}) {
    const response = await this.client.chat.completions.create({
      model: options.model || 'gpt-4-turbo-preview',
      messages: [{ role: 'user', content: prompt }],
      ...options
    })
    
    return {
      text: response.choices[0].message.content,
      usage: response.usage,
      model: response.model
    }
  }
  
  async *stream(prompt, options = {}) {
    const stream = await this.client.chat.completions.create({
      model: options.model || 'gpt-4-turbo-preview',
      messages: [{ role: 'user', content: prompt }],
      stream: true,
      ...options
    })
    
    for await (const chunk of stream) {
      yield chunk.choices[0]?.delta?.content || ''
    }
  }
}

// Provider manager
class AIProviderManager {
  constructor() {
    this.providers = new Map()
    this.defaultProvider = null
  }
  
  register(name, provider) {
    this.providers.set(name, provider)
    if (!this.defaultProvider) {
      this.defaultProvider = name
    }
  }
  
  async complete(prompt, options = {}) {
    const provider = options.provider || this.defaultProvider
    const instance = this.providers.get(provider)
    
    if (!instance) {
      throw new Error(`Provider ${provider} not found`)
    }
    
    return instance.complete(prompt, options)
  }
  
  // Fallback logic
  async completeWithFallback(prompt, options = {}) {
    const providers = options.providers || [this.defaultProvider]
    
    for (const provider of providers) {
      try {
        return await this.complete(prompt, { ...options, provider })
      } catch (error) {
        console.error(`Provider ${provider} failed:`, error)
        
        if (provider === providers[providers.length - 1]) {
          throw error
        }
      }
    }
  }
}
```

### Response Caching

```javascript
// Intelligent response caching
class AIResponseCache {
  constructor(options = {}) {
    this.cache = new Map()
    this.ttl = options.ttl || 3600000 // 1 hour
    this.maxSize = options.maxSize || 1000
  }
  
  generateKey(provider, prompt, options) {
    const normalized = {
      provider,
      prompt: prompt.trim().toLowerCase(),
      model: options.model,
      temperature: options.temperature
    }
    
    return crypto
      .createHash('sha256')
      .update(JSON.stringify(normalized))
      .digest('hex')
  }
  
  async get(provider, prompt, options, generator) {
    const key = this.generateKey(provider, prompt, options)
    const cached = this.cache.get(key)
    
    if (cached && Date.now() - cached.timestamp < this.ttl) {
      return { ...cached.response, cached: true }
    }
    
    // Generate fresh response
    const response = await generator()
    
    // Cache response
    this.set(key, response)
    
    return response
  }
  
  set(key, response) {
    // LRU eviction
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value
      this.cache.delete(firstKey)
    }
    
    this.cache.set(key, {
      response,
      timestamp: Date.now()
    })
  }
}
```

### Error Handling & Retries

```javascript
// Robust error handling
class AIErrorHandler {
  constructor(options = {}) {
    this.maxRetries = options.maxRetries || 3
    this.backoffMs = options.backoffMs || 1000
    this.timeout = options.timeout || 30000
  }
  
  async executeWithRetry(operation, context = {}) {
    let lastError
    
    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        // Add timeout
        const result = await Promise.race([
          operation(),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Timeout')), this.timeout)
          )
        ])
        
        return result
      } catch (error) {
        lastError = error
        
        // Don't retry on certain errors
        if (this.isNonRetryable(error)) {
          throw error
        }
        
        // Log attempt
        console.warn(`Attempt ${attempt} failed:`, error.message)
        
        // Calculate backoff
        if (attempt < this.maxRetries) {
          const delay = this.calculateBackoff(attempt, error)
          await new Promise(resolve => setTimeout(resolve, delay))
        }
      }
    }
    
    throw new Error(`Failed after ${this.maxRetries} attempts: ${lastError.message}`)
  }
  
  isNonRetryable(error) {
    // Don't retry on client errors
    if (error.status >= 400 && error.status < 500) {
      return true
    }
    
    // Don't retry on specific error codes
    const nonRetryableCodes = ['invalid_api_key', 'insufficient_quota']
    if (nonRetryableCodes.includes(error.code)) {
      return true
    }
    
    return false
  }
  
  calculateBackoff(attempt, error) {
    // Exponential backoff with jitter
    const exponential = this.backoffMs * Math.pow(2, attempt - 1)
    const jitter = Math.random() * exponential * 0.1
    
    // Respect rate limit headers
    if (error.headers?.['retry-after']) {
      const retryAfter = parseInt(error.headers['retry-after'])
      return Math.max(retryAfter * 1000, exponential + jitter)
    }
    
    return exponential + jitter
  }
}
```

### Observability & Monitoring

```javascript
// AI SDK observability
class AIObservability {
  constructor() {
    this.metrics = {
      requests: new Map(),
      latency: [],
      errors: new Map(),
      tokens: 0
    }
  }
  
  async observe(operation, metadata = {}) {
    const startTime = Date.now()
    const traceId = crypto.randomUUID()
    
    try {
      // Log request
      this.logEvent('request_start', {
        traceId,
        ...metadata,
        timestamp: startTime
      })
      
      // Execute operation
      const result = await operation()
      
      // Log success
      const duration = Date.now() - startTime
      this.logEvent('request_success', {
        traceId,
        duration,
        tokens: result.usage?.total_tokens,
        ...metadata
      })
      
      // Update metrics
      this.updateMetrics({
        provider: metadata.provider,
        model: metadata.model,
        duration,
        tokens: result.usage?.total_tokens,
        success: true
      })
      
      return result
    } catch (error) {
      // Log error
      const duration = Date.now() - startTime
      this.logEvent('request_error', {
        traceId,
        duration,
        error: error.message,
        code: error.code,
        ...metadata
      })
      
      // Update metrics
      this.updateMetrics({
        provider: metadata.provider,
        model: metadata.model,
        duration,
        success: false,
        error: error.code
      })
      
      throw error
    }
  }
  
  updateMetrics(data) {
    // Request counts
    const key = `${data.provider}:${data.model}`
    this.metrics.requests.set(key, 
      (this.metrics.requests.get(key) || 0) + 1
    )
    
    // Latency
    this.metrics.latency.push({
      duration: data.duration,
      timestamp: Date.now()
    })
    
    // Tokens
    if (data.tokens) {
      this.metrics.tokens += data.tokens
    }
    
    // Errors
    if (!data.success) {
      const errorKey = `${key}:${data.error}`
      this.metrics.errors.set(errorKey,
        (this.metrics.errors.get(errorKey) || 0) + 1
      )
    }
  }
  
  getMetrics() {
    const now = Date.now()
    const recentLatency = this.metrics.latency
      .filter(l => now - l.timestamp < 300000) // Last 5 minutes
    
    return {
      requests: Object.fromEntries(this.metrics.requests),
      errors: Object.fromEntries(this.metrics.errors),
      totalTokens: this.metrics.tokens,
      latency: {
        avg: this.average(recentLatency.map(l => l.duration)),
        p95: this.percentile(recentLatency.map(l => l.duration), 95),
        p99: this.percentile(recentLatency.map(l => l.duration), 99)
      }
    }
  }
}
```

## 📚 Best Practices

### 1. **API Key Management**
- Use environment variables
- Implement key rotation
- Never commit keys to version control
- Use different keys for dev/prod
- Monitor key usage

### 2. **Error Handling**
- Implement comprehensive retry logic
- Handle rate limits gracefully
- Log errors with context
- Provide fallback responses
- Monitor error rates

### 3. **Performance Optimization**
- Cache responses when appropriate
- Use streaming for real-time UX
- Batch requests when possible
- Monitor latency and token usage
- Implement request queuing

### 4. **Cost Management**
- Track token usage per request
- Implement user quotas
- Use appropriate models for tasks
- Cache expensive operations
- Monitor costs by feature

### 5. **Security**
- Validate and sanitize inputs
- Implement rate limiting
- Use content filtering
- Audit AI interactions
- Protect sensitive data

## 📖 Resources & References

### Official SDKs
- [OpenAI Node.js SDK](https://github.com/openai/openai-node)
- [Anthropic SDK](https://github.com/anthropics/anthropic-sdk-node)
- [Google AI SDK](https://github.com/google/generative-ai-js)
- [Vercel AI SDK](https://sdk.vercel.ai/)

### Orchestration Frameworks
- **LangChain** - Complex AI workflows
- **LlamaIndex** - Data framework for LLMs
- **Semantic Kernel** - Microsoft's AI orchestration
- **Haystack** - NLP framework

### Monitoring & Observability
- **Helicone** - AI observability platform
- **Langfuse** - LLM engineering platform
- **Phoenix** - ML observability
- **Weights & Biases** - ML experiment tracking

---

*This guide covers essential patterns for integrating AI SDKs into production applications. Focus on abstraction, error handling, and observability for reliable AI systems.*
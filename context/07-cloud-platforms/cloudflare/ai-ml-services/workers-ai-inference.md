# Cloudflare Workers AI - Edge ML Inference

## Overview

Cloudflare Workers AI provides serverless machine learning inference at the edge, offering access to popular AI models without managing infrastructure. Run AI models globally with low latency, automatic scaling, and cost-effective pricing directly from Workers.

## Quick Start

### Basic Setup
```javascript
// Simple AI inference in Workers
export default {
  async fetch(request, env) {
    const { AI } = env;
    
    // Text generation
    const response = await AI.run('@cf/meta/llama-2-7b-chat-int8', {
      messages: [
        { role: 'user', content: 'Explain quantum computing in simple terms' }
      ]
    });
    
    return Response.json(response);
  }
};
```

### Configuration
```toml
# wrangler.toml
[[ai]]
binding = "AI"
```

## Available Models

### Text Generation Models
```javascript
export default {
  async fetch(request, env) {
    const models = {
      // Meta Llama models
      llama2_7b: '@cf/meta/llama-2-7b-chat-int8',
      llama2_13b: '@cf/meta/llama-2-13b-chat-awq',
      codellama: '@cf/meta/codellama-7b-instruct-awq',
      
      // Mistral models
      mistral_7b: '@cf/mistral/mistral-7b-instruct-v0.1',
      
      // Microsoft models
      phi2: '@cf/microsoft/phi-2',
      
      // Google models
      gemma_2b: '@cf/google/gemma-2b-it-lora',
      gemma_7b: '@cf/google/gemma-7b-it-lora'
    };
    
    const modelName = new URL(request.url).searchParams.get('model') || 'llama2_7b';
    const model = models[modelName];
    
    if (!model) {
      return new Response('Model not found', { status: 404 });
    }
    
    const { prompt } = await request.json();
    
    const response = await env.AI.run(model, {
      prompt
    });
    
    return Response.json({
      model: modelName,
      response: response.response
    });
  }
};
```

### Embedding Models
```javascript
// Generate embeddings for text
async function generateEmbeddings(texts, env) {
  const embeddings = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
    text: Array.isArray(texts) ? texts : [texts]
  });
  
  return embeddings.data;
}

export default {
  async fetch(request, env) {
    if (request.method === 'POST' && new URL(request.url).pathname === '/embeddings') {
      const { texts } = await request.json();
      
      const embeddings = await generateEmbeddings(texts, env);
      
      return Response.json({
        embeddings,
        model: '@cf/baai/bge-base-en-v1.5',
        dimensions: embeddings[0].length
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

### Image Classification
```javascript
// Image classification and analysis
export default {
  async fetch(request, env) {
    if (request.method === 'POST' && new URL(request.url).pathname === '/classify-image') {
      const formData = await request.formData();
      const imageFile = formData.get('image');
      
      if (!imageFile) {
        return new Response('No image provided', { status: 400 });
      }
      
      // Convert image to array buffer
      const imageBuffer = await imageFile.arrayBuffer();
      
      // Classify image
      const classification = await env.AI.run('@cf/microsoft/resnet-50', {
        image: [...new Uint8Array(imageBuffer)]
      });
      
      return Response.json({
        filename: imageFile.name,
        predictions: classification,
        model: '@cf/microsoft/resnet-50'
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

## Integration Patterns

### 1. Multi-Model AI Service

```javascript
// Comprehensive AI service with multiple model types
class AIService {
  constructor(aiBinding) {
    this.ai = aiBinding;
    this.models = {
      chat: {
        'llama-2-7b': '@cf/meta/llama-2-7b-chat-int8',
        'llama-2-13b': '@cf/meta/llama-2-13b-chat-awq',
        'mistral-7b': '@cf/mistral/mistral-7b-instruct-v0.1',
        'codellama': '@cf/meta/codellama-7b-instruct-awq'
      },
      embeddings: {
        'bge-base': '@cf/baai/bge-base-en-v1.5',
        'bge-large': '@cf/baai/bge-large-en-v1.5'
      },
      classification: {
        'resnet-50': '@cf/microsoft/resnet-50'
      },
      translation: {
        'm2m100': '@cf/meta/m2m100-1.2b'
      }
    };
  }
  
  async generateText(prompt, options = {}) {
    const {
      model = 'llama-2-7b',
      maxTokens = 256,
      temperature = 0.7,
      systemPrompt = null
    } = options;
    
    const modelId = this.models.chat[model];
    if (!modelId) {
      throw new Error(`Chat model '${model}' not available`);
    }
    
    let messages = [];
    
    if (systemPrompt) {
      messages.push({ role: 'system', content: systemPrompt });
    }
    
    messages.push({ role: 'user', content: prompt });
    
    const response = await this.ai.run(modelId, {
      messages,
      max_tokens: maxTokens,
      temperature
    });
    
    return {
      text: response.response,
      model: model,
      usage: {
        prompt_tokens: response.usage?.prompt_tokens || 0,
        completion_tokens: response.usage?.completion_tokens || 0,
        total_tokens: response.usage?.total_tokens || 0
      }
    };
  }
  
  async generateEmbeddings(texts, options = {}) {
    const { model = 'bge-base' } = options;
    
    const modelId = this.models.embeddings[model];
    if (!modelId) {
      throw new Error(`Embedding model '${model}' not available`);
    }
    
    const textArray = Array.isArray(texts) ? texts : [texts];
    
    const response = await this.ai.run(modelId, {
      text: textArray
    });
    
    return {
      embeddings: response.data,
      model: model,
      dimensions: response.data[0]?.length || 0,
      usage: {
        total_tokens: textArray.reduce((sum, text) => sum + text.length, 0)
      }
    };
  }
  
  async classifyImage(imageBuffer, options = {}) {
    const { model = 'resnet-50', topK = 5 } = options;
    
    const modelId = this.models.classification[model];
    if (!modelId) {
      throw new Error(`Classification model '${model}' not available`);
    }
    
    const response = await this.ai.run(modelId, {
      image: [...new Uint8Array(imageBuffer)]
    });
    
    // Sort predictions by confidence and take top K
    const sortedPredictions = response
      .sort((a, b) => b.score - a.score)
      .slice(0, topK);
    
    return {
      predictions: sortedPredictions,
      model: model,
      confidence: sortedPredictions[0]?.score || 0
    };
  }
  
  async translateText(text, options = {}) {
    const {
      model = 'm2m100',
      sourceLanguage = 'en',
      targetLanguage = 'es'
    } = options;
    
    const modelId = this.models.translation[model];
    if (!modelId) {
      throw new Error(`Translation model '${model}' not available`);
    }
    
    const response = await this.ai.run(modelId, {
      text,
      source_lang: sourceLanguage,
      target_lang: targetLanguage
    });
    
    return {
      translated_text: response.translated_text,
      source_language: sourceLanguage,
      target_language: targetLanguage,
      model: model
    };
  }
  
  async analyzeText(text, analysisTypes = ['sentiment', 'keywords', 'summary']) {
    const results = {};
    
    // Sentiment analysis using chat model
    if (analysisTypes.includes('sentiment')) {
      const sentimentResponse = await this.generateText(
        `Analyze the sentiment of this text and respond with only: "positive", "negative", or "neutral". Text: "${text}"`,
        { 
          model: 'llama-2-7b',
          maxTokens: 10,
          temperature: 0.1
        }
      );
      
      results.sentiment = sentimentResponse.text.trim().toLowerCase();
    }
    
    // Keyword extraction
    if (analysisTypes.includes('keywords')) {
      const keywordResponse = await this.generateText(
        `Extract the 5 most important keywords from this text. Respond with only the keywords separated by commas. Text: "${text}"`,
        {
          model: 'llama-2-7b',
          maxTokens: 50,
          temperature: 0.1
        }
      );
      
      results.keywords = keywordResponse.text
        .split(',')
        .map(k => k.trim())
        .filter(k => k.length > 0);
    }
    
    // Text summary
    if (analysisTypes.includes('summary')) {
      const summaryResponse = await this.generateText(
        `Summarize this text in 2-3 sentences: "${text}"`,
        {
          model: 'llama-2-7b',
          maxTokens: 100,
          temperature: 0.3
        }
      );
      
      results.summary = summaryResponse.text.trim();
    }
    
    return results;
  }
  
  async batchProcess(requests) {
    const results = await Promise.allSettled(
      requests.map(async (request) => {
        switch (request.type) {
          case 'text_generation':
            return await this.generateText(request.prompt, request.options);
          case 'embeddings':
            return await this.generateEmbeddings(request.texts, request.options);
          case 'image_classification':
            return await this.classifyImage(request.imageBuffer, request.options);
          case 'translation':
            return await this.translateText(request.text, request.options);
          case 'text_analysis':
            return await this.analyzeText(request.text, request.analysisTypes);
          default:
            throw new Error(`Unknown request type: ${request.type}`);
        }
      })
    );
    
    return results.map((result, index) => ({
      request_id: requests[index].id || index,
      success: result.status === 'fulfilled',
      result: result.status === 'fulfilled' ? result.value : null,
      error: result.status === 'rejected' ? result.reason.message : null
    }));
  }
}

// Usage in Worker
export default {
  async fetch(request, env) {
    const ai = new AIService(env.AI);
    const url = new URL(request.url);
    
    try {
      switch (url.pathname) {
        case '/chat':
          return handleChat(request, ai);
        case '/embeddings':
          return handleEmbeddings(request, ai);
        case '/classify':
          return handleImageClassification(request, ai);
        case '/translate':
          return handleTranslation(request, ai);
        case '/analyze':
          return handleTextAnalysis(request, ai);
        case '/batch':
          return handleBatch(request, ai);
        default:
          return new Response('Not found', { status: 404 });
      }
    } catch (error) {
      return Response.json({ error: error.message }, { status: 500 });
    }
  }
};

async function handleChat(request, ai) {
  const { prompt, model, maxTokens, temperature, systemPrompt } = await request.json();
  
  const response = await ai.generateText(prompt, {
    model,
    maxTokens,
    temperature,
    systemPrompt
  });
  
  return Response.json(response);
}

async function handleEmbeddings(request, ai) {
  const { texts, model } = await request.json();
  
  const response = await ai.generateEmbeddings(texts, { model });
  
  return Response.json(response);
}

async function handleImageClassification(request, ai) {
  const formData = await request.formData();
  const imageFile = formData.get('image');
  const model = formData.get('model') || 'resnet-50';
  const topK = parseInt(formData.get('topK') || '5');
  
  if (!imageFile) {
    return new Response('No image provided', { status: 400 });
  }
  
  const imageBuffer = await imageFile.arrayBuffer();
  const response = await ai.classifyImage(imageBuffer, { model, topK });
  
  return Response.json(response);
}

async function handleTranslation(request, ai) {
  const { text, model, sourceLanguage, targetLanguage } = await request.json();
  
  const response = await ai.translateText(text, {
    model,
    sourceLanguage,
    targetLanguage
  });
  
  return Response.json(response);
}

async function handleTextAnalysis(request, ai) {
  const { text, analysisTypes } = await request.json();
  
  const response = await ai.analyzeText(text, analysisTypes);
  
  return Response.json(response);
}

async function handleBatch(request, ai) {
  const { requests } = await request.json();
  
  const response = await ai.batchProcess(requests);
  
  return Response.json({
    batch_id: crypto.randomUUID(),
    results: response,
    processed_at: Date.now()
  });
}
```

### 2. Content Processing Pipeline

```javascript
// Automated content processing with multiple AI models
class ContentProcessor {
  constructor(aiBinding, storage) {
    this.ai = aiBinding;
    this.storage = storage; // R2 or KV storage
  }
  
  async processDocument(documentId, documentBuffer, options = {}) {
    const pipeline = options.pipeline || [
      'extract_text',
      'generate_summary',
      'extract_keywords',
      'analyze_sentiment',
      'generate_embeddings',
      'classify_content'
    ];
    
    const results = {
      document_id: documentId,
      processed_at: Date.now(),
      pipeline,
      results: {}
    };
    
    try {
      // Extract text (if image/PDF)
      if (pipeline.includes('extract_text')) {
        results.results.text_extraction = await this.extractText(documentBuffer);
      }
      
      const text = results.results.text_extraction?.text || 
                   new TextDecoder().decode(documentBuffer);
      
      // Generate summary
      if (pipeline.includes('generate_summary')) {
        results.results.summary = await this.generateSummary(text);
      }
      
      // Extract keywords
      if (pipeline.includes('extract_keywords')) {
        results.results.keywords = await this.extractKeywords(text);
      }
      
      // Analyze sentiment
      if (pipeline.includes('analyze_sentiment')) {
        results.results.sentiment = await this.analyzeSentiment(text);
      }
      
      // Generate embeddings
      if (pipeline.includes('generate_embeddings')) {
        results.results.embeddings = await this.generateEmbeddings(text);
      }
      
      // Classify content
      if (pipeline.includes('classify_content')) {
        results.results.classification = await this.classifyContent(text);
      }
      
      // Store results
      await this.storeProcessingResults(documentId, results);
      
      return results;
    } catch (error) {
      results.error = error.message;
      results.status = 'failed';
      throw error;
    }
  }
  
  async extractText(documentBuffer) {
    // For images, you might use OCR models when available
    // For now, assume it's already text
    const text = new TextDecoder().decode(documentBuffer);
    
    return {
      text,
      word_count: text.split(' ').length,
      character_count: text.length
    };
  }
  
  async generateSummary(text) {
    if (text.length < 200) {
      return {
        summary: text,
        compression_ratio: 1.0,
        method: 'no_summarization_needed'
      };
    }
    
    const response = await this.ai.run('@cf/meta/llama-2-7b-chat-int8', {
      messages: [
        {
          role: 'user',
          content: `Summarize the following text in 2-3 sentences, capturing the main points:\n\n${text}`
        }
      ],
      max_tokens: 150
    });
    
    return {
      summary: response.response.trim(),
      original_length: text.length,
      summary_length: response.response.length,
      compression_ratio: response.response.length / text.length,
      method: 'llama2_7b'
    };
  }
  
  async extractKeywords(text) {
    const response = await this.ai.run('@cf/meta/llama-2-7b-chat-int8', {
      messages: [
        {
          role: 'user',
          content: `Extract the 10 most important keywords from this text. Respond with only the keywords separated by commas:\n\n${text}`
        }
      ],
      max_tokens: 100,
      temperature: 0.1
    });
    
    const keywords = response.response
      .split(',')
      .map(k => k.trim())
      .filter(k => k.length > 0)
      .slice(0, 10);
    
    return {
      keywords,
      count: keywords.length,
      method: 'llama2_extraction'
    };
  }
  
  async analyzeSentiment(text) {
    const response = await this.ai.run('@cf/meta/llama-2-7b-chat-int8', {
      messages: [
        {
          role: 'user',
          content: `Analyze the sentiment of this text. Respond with only one word: "positive", "negative", or "neutral":\n\n${text}`
        }
      ],
      max_tokens: 10,
      temperature: 0.1
    });
    
    const sentiment = response.response.trim().toLowerCase();
    
    return {
      sentiment: ['positive', 'negative', 'neutral'].includes(sentiment) ? sentiment : 'neutral',
      confidence: sentiment === 'neutral' ? 0.5 : 0.8,
      method: 'llama2_classification'
    };
  }
  
  async generateEmbeddings(text) {
    // Split text into chunks if too long
    const chunks = this.chunkText(text, 512);
    
    const embeddings = await this.ai.run('@cf/baai/bge-base-en-v1.5', {
      text: chunks
    });
    
    // Average embeddings for multiple chunks
    let averageEmbedding;
    if (embeddings.data.length === 1) {
      averageEmbedding = embeddings.data[0];
    } else {
      averageEmbedding = this.averageEmbeddings(embeddings.data);
    }
    
    return {
      embedding: averageEmbedding,
      dimensions: averageEmbedding.length,
      chunks_processed: chunks.length,
      method: 'bge_base_en'
    };
  }
  
  async classifyContent(text) {
    const categories = [
      'business', 'technology', 'science', 'health', 'education',
      'entertainment', 'sports', 'politics', 'finance', 'other'
    ];
    
    const response = await this.ai.run('@cf/meta/llama-2-7b-chat-int8', {
      messages: [
        {
          role: 'user',
          content: `Classify this text into one of these categories: ${categories.join(', ')}. Respond with only the category name:\n\n${text}`
        }
      ],
      max_tokens: 20,
      temperature: 0.1
    });
    
    const classification = response.response.trim().toLowerCase();
    
    return {
      category: categories.includes(classification) ? classification : 'other',
      confidence: categories.includes(classification) ? 0.8 : 0.3,
      available_categories: categories,
      method: 'llama2_classification'
    };
  }
  
  chunkText(text, maxWords) {
    const words = text.split(' ');
    const chunks = [];
    
    for (let i = 0; i < words.length; i += maxWords) {
      chunks.push(words.slice(i, i + maxWords).join(' '));
    }
    
    return chunks;
  }
  
  averageEmbeddings(embeddings) {
    const dimensions = embeddings[0].length;
    const average = new Array(dimensions).fill(0);
    
    for (const embedding of embeddings) {
      for (let i = 0; i < dimensions; i++) {
        average[i] += embedding[i];
      }
    }
    
    for (let i = 0; i < dimensions; i++) {
      average[i] /= embeddings.length;
    }
    
    return average;
  }
  
  async storeProcessingResults(documentId, results) {
    const key = `processing_results:${documentId}`;
    await this.storage.put(key, JSON.stringify(results), {
      expirationTtl: 86400 * 30 // Keep for 30 days
    });
  }
  
  async getProcessingResults(documentId) {
    const key = `processing_results:${documentId}`;
    const results = await this.storage.get(key, 'json');
    return results;
  }
}
```

### 3. Real-time AI Chat System

```javascript
// Real-time AI chat with context management
class ChatSystem {
  constructor(aiBinding, contextStorage) {
    this.ai = aiBinding;
    this.contextStorage = contextStorage; // KV for storing conversation context
  }
  
  async handleChatMessage(sessionId, message, options = {}) {
    const {
      model = 'llama-2-7b',
      maxTokens = 512,
      temperature = 0.7,
      systemPrompt = 'You are a helpful assistant.',
      useContext = true,
      maxContextMessages = 10
    } = options;
    
    // Get conversation context
    const context = useContext ? await this.getContext(sessionId) : [];
    
    // Prepare messages
    let messages = [
      { role: 'system', content: systemPrompt }
    ];
    
    // Add context messages
    if (context.length > 0) {
      messages.push(...context.slice(-maxContextMessages));
    }
    
    // Add current message
    messages.push({ role: 'user', content: message });
    
    // Generate response
    const modelId = this.getModelId(model);
    const response = await this.ai.run(modelId, {
      messages,
      max_tokens: maxTokens,
      temperature
    });
    
    // Update context
    if (useContext) {
      await this.updateContext(sessionId, [
        { role: 'user', content: message, timestamp: Date.now() },
        { role: 'assistant', content: response.response, timestamp: Date.now() }
      ]);
    }
    
    return {
      session_id: sessionId,
      message: response.response,
      model: model,
      context_length: messages.length,
      usage: response.usage || {}
    };
  }
  
  async handleStreamingChat(sessionId, message, options = {}) {
    const {
      model = 'llama-2-7b',
      maxTokens = 512,
      temperature = 0.7,
      systemPrompt = 'You are a helpful assistant.'
    } = options;
    
    // Get context and prepare messages (same as above)
    const context = await this.getContext(sessionId);
    let messages = [
      { role: 'system', content: systemPrompt },
      ...context.slice(-10),
      { role: 'user', content: message }
    ];
    
    // Create readable stream for response
    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();
    
    // Start AI generation in background
    (async () => {
      try {
        const modelId = this.getModelId(model);
        const response = await this.ai.run(modelId, {
          messages,
          max_tokens: maxTokens,
          temperature,
          stream: true // Enable streaming if supported
        });
        
        // Stream the response
        if (response.stream) {
          for await (const chunk of response.stream) {
            await writer.write(new TextEncoder().encode(
              `data: ${JSON.stringify({ content: chunk.response })}\n\n`
            ));
          }
        } else {
          // Fallback: send complete response
          await writer.write(new TextEncoder().encode(
            `data: ${JSON.stringify({ content: response.response })}\n\n`
          ));
        }
        
        // Update context
        await this.updateContext(sessionId, [
          { role: 'user', content: message, timestamp: Date.now() },
          { role: 'assistant', content: response.response, timestamp: Date.now() }
        ]);
        
        // Send completion signal
        await writer.write(new TextEncoder().encode('data: [DONE]\n\n'));
      } catch (error) {
        await writer.write(new TextEncoder().encode(
          `data: ${JSON.stringify({ error: error.message })}\n\n`
        ));
      } finally {
        await writer.close();
      }
    })();
    
    return new Response(readable, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive'
      }
    });
  }
  
  async getContext(sessionId) {
    const key = `chat_context:${sessionId}`;
    const context = await this.contextStorage.get(key, 'json');
    return context || [];
  }
  
  async updateContext(sessionId, newMessages) {
    const key = `chat_context:${sessionId}`;
    const currentContext = await this.getContext(sessionId);
    
    const updatedContext = [...currentContext, ...newMessages];
    
    // Keep only last 50 messages to prevent context from growing too large
    const limitedContext = updatedContext.slice(-50);
    
    await this.contextStorage.put(key, JSON.stringify(limitedContext), {
      expirationTtl: 86400 * 7 // Keep for 7 days
    });
  }
  
  async clearContext(sessionId) {
    const key = `chat_context:${sessionId}`;
    await this.contextStorage.delete(key);
  }
  
  async getChatSessions(userId) {
    // List all chat sessions for a user
    const prefix = `chat_context:${userId}:`;
    const sessions = await this.contextStorage.list({ prefix });
    
    return sessions.keys.map(key => ({
      session_id: key.name.replace(prefix, ''),
      last_modified: key.metadata?.last_modified || null
    }));
  }
  
  getModelId(model) {
    const models = {
      'llama-2-7b': '@cf/meta/llama-2-7b-chat-int8',
      'llama-2-13b': '@cf/meta/llama-2-13b-chat-awq',
      'mistral-7b': '@cf/mistral/mistral-7b-instruct-v0.1',
      'codellama': '@cf/meta/codellama-7b-instruct-awq'
    };
    
    return models[model] || models['llama-2-7b'];
  }
  
  async generateChatTitle(sessionId) {
    const context = await this.getContext(sessionId);
    
    if (context.length === 0) {
      return 'New Chat';
    }
    
    // Use first few messages to generate a title
    const firstMessages = context.slice(0, 4);
    const conversationText = firstMessages
      .map(msg => `${msg.role}: ${msg.content}`)
      .join('\n');
    
    const response = await this.ai.run('@cf/meta/llama-2-7b-chat-int8', {
      messages: [
        {
          role: 'user',
          content: `Generate a short, descriptive title (3-5 words) for this conversation:\n\n${conversationText}`
        }
      ],
      max_tokens: 20,
      temperature: 0.3
    });
    
    return response.response.trim().replace(/['"]/g, '');
  }
}
```

## Performance Optimization

### Model Selection
- Use appropriate models for task complexity
- Consider latency vs. quality trade-offs
- Monitor model performance metrics
- Switch models based on requirements

### Request Optimization
- Batch similar requests when possible
- Use appropriate token limits
- Optimize prompt engineering
- Implement response caching

### Resource Management
- Monitor compute usage and costs
- Implement request queuing for high load
- Use edge caching for repeated requests
- Set appropriate timeouts

## Best Practices

### Model Usage
- Choose the right model for each task
- Optimize prompts for better results
- Handle model limitations gracefully
- Monitor model performance and costs

### Error Handling
- Implement proper retry logic
- Handle model capacity limits
- Provide fallback options
- Log errors for monitoring

### Security
- Validate all inputs
- Sanitize user content
- Implement rate limiting
- Monitor for abuse patterns

### Cost Management
- Track usage and costs
- Implement usage limits
- Optimize model selection
- Use caching to reduce API calls

## Common Use Cases

1. **Content Generation** - Blog posts, product descriptions, creative writing
2. **Text Analysis** - Sentiment analysis, keyword extraction, summarization
3. **Code Assistance** - Code generation, debugging, documentation
4. **Translation** - Multi-language content translation
5. **Image Classification** - Automatic image tagging and categorization
6. **Chatbots** - Customer service, virtual assistants, conversational AI

Workers AI provides powerful edge-based machine learning capabilities that enable intelligent applications with global performance and automatic scaling.
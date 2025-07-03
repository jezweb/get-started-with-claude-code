# Vectorize Implementation Guide

Comprehensive guide to implementing vector databases with Cloudflare Vectorize for semantic search, recommendation systems, and AI-powered applications.

## 🎯 What is Vectorize?

Cloudflare Vectorize is a globally distributed vector database:
- **Vector Storage** - Store and query high-dimensional vectors
- **Semantic Search** - Find similar content based on meaning
- **Low Latency** - Globally distributed for fast queries
- **Integrated Platform** - Works seamlessly with Workers AI
- **Scalable** - Handles millions of vectors efficiently
- **Metadata Filtering** - Query vectors with metadata constraints

## 🚀 Quick Start

### Creating a Vector Index

```bash
# Create a new vector index
wrangler vectorize create my-index --dimensions=768 --metric=cosine

# List indexes
wrangler vectorize list

# Get index info
wrangler vectorize info my-index
```

### Basic Configuration

```toml
# wrangler.toml
name = "my-vectorize-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"

[[vectorize]]
binding = "VECTORIZE"
index_name = "my-index"

[ai]
binding = "AI"
```

### Simple Vector Operations

```javascript
// src/index.js
export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url)
    
    if (pathname === '/insert') {
      // Insert vectors
      const vectors = [
        {
          id: '1',
          values: [0.1, 0.2, 0.3, ...], // 768 dimensions
          metadata: { type: 'document', title: 'Introduction' }
        },
        {
          id: '2', 
          values: [0.4, 0.5, 0.6, ...],
          metadata: { type: 'document', title: 'Chapter 1' }
        }
      ]
      
      await env.VECTORIZE.insert(vectors)
      return Response.json({ inserted: vectors.length })
    }
    
    if (pathname === '/query') {
      // Query similar vectors
      const queryVector = [0.2, 0.3, 0.4, ...] // 768 dimensions
      const results = await env.VECTORIZE.query(queryVector, {
        topK: 5,
        filter: { type: 'document' }
      })
      
      return Response.json(results)
    }
  }
}
```

## 🧠 Core Patterns

### Semantic Search Implementation

```javascript
// Complete semantic search system
class SemanticSearch {
  constructor(env) {
    this.env = env
    this.embeddingModel = '@cf/baai/bge-base-en-v1.5'
    this.dimensions = 768
  }
  
  async indexDocument(doc) {
    // Generate embedding for document
    const embedding = await this.generateEmbedding(doc.content)
    
    // Store in Vectorize with metadata
    await this.env.VECTORIZE.insert([{
      id: doc.id,
      values: embedding,
      metadata: {
        title: doc.title,
        type: doc.type,
        author: doc.author,
        timestamp: doc.timestamp,
        url: doc.url,
        // Store first 1000 chars for preview
        preview: doc.content.substring(0, 1000)
      }
    }])
    
    return { success: true, id: doc.id }
  }
  
  async indexBatch(documents) {
    const vectors = []
    
    // Process documents in parallel batches
    const batchSize = 100
    for (let i = 0; i < documents.length; i += batchSize) {
      const batch = documents.slice(i, i + batchSize)
      
      const embeddings = await Promise.all(
        batch.map(doc => this.generateEmbedding(doc.content))
      )
      
      batch.forEach((doc, idx) => {
        vectors.push({
          id: doc.id,
          values: embeddings[idx],
          metadata: {
            title: doc.title,
            type: doc.type,
            timestamp: doc.timestamp,
            preview: doc.content.substring(0, 1000)
          }
        })
      })
    }
    
    // Insert all vectors
    await this.env.VECTORIZE.insert(vectors)
    
    return { success: true, indexed: vectors.length }
  }
  
  async search(query, options = {}) {
    const {
      topK = 10,
      filter = {},
      includeContent = true,
      threshold = 0.7
    } = options
    
    // Generate query embedding
    const queryEmbedding = await this.generateEmbedding(query)
    
    // Search for similar vectors
    const results = await this.env.VECTORIZE.query(queryEmbedding, {
      topK,
      filter,
      includeMetadata: true,
      includeValues: false
    })
    
    // Filter by threshold and enrich results
    const enrichedResults = results.matches
      .filter(match => match.score >= threshold)
      .map(match => ({
        id: match.id,
        score: match.score,
        title: match.metadata.title,
        preview: match.metadata.preview,
        type: match.metadata.type,
        url: match.metadata.url
      }))
    
    // Optionally fetch full content
    if (includeContent && enrichedResults.length > 0) {
      await this.enrichWithContent(enrichedResults)
    }
    
    return {
      query,
      results: enrichedResults,
      totalFound: enrichedResults.length
    }
  }
  
  async generateEmbedding(text) {
    const response = await this.env.AI.run(this.embeddingModel, {
      text: [text]
    })
    
    return response.data[0]
  }
  
  async enrichWithContent(results) {
    // Fetch full content from your storage (R2, KV, D1, etc.)
    const ids = results.map(r => r.id)
    
    // Example: Fetch from KV
    const contents = await Promise.all(
      ids.map(id => this.env.CONTENT_KV.get(id))
    )
    
    results.forEach((result, idx) => {
      result.content = contents[idx]
    })
  }
}
```

### Hybrid Search (Vector + Full-Text)

```javascript
// Combine vector search with traditional search
class HybridSearch {
  constructor(env) {
    this.env = env
    this.vectorSearch = new SemanticSearch(env)
  }
  
  async search(query, options = {}) {
    const {
      vectorWeight = 0.7,
      textWeight = 0.3,
      topK = 20
    } = options
    
    // Parallel search
    const [vectorResults, textResults] = await Promise.all([
      this.vectorSearch.search(query, { topK: topK * 2 }),
      this.fullTextSearch(query, { limit: topK * 2 })
    ])
    
    // Combine and rerank results
    const combined = this.combineResults(
      vectorResults.results,
      textResults,
      vectorWeight,
      textWeight
    )
    
    return {
      query,
      results: combined.slice(0, topK),
      sources: {
        vector: vectorResults.results.length,
        text: textResults.length
      }
    }
  }
  
  async fullTextSearch(query, options) {
    // Example using D1 database
    const results = await this.env.DB.prepare(`
      SELECT id, title, preview, 
             rank() OVER (ORDER BY bm25(content, ?)) as text_score
      FROM documents
      WHERE content MATCH ?
      ORDER BY text_score DESC
      LIMIT ?
    `).bind(query, query, options.limit).all()
    
    return results.results.map(r => ({
      ...r,
      score: r.text_score / 100 // Normalize score
    }))
  }
  
  combineResults(vectorResults, textResults, vectorWeight, textWeight) {
    const scoreMap = new Map()
    
    // Add vector results
    vectorResults.forEach(result => {
      scoreMap.set(result.id, {
        ...result,
        vectorScore: result.score,
        textScore: 0,
        combinedScore: result.score * vectorWeight
      })
    })
    
    // Add text results
    textResults.forEach(result => {
      const existing = scoreMap.get(result.id)
      if (existing) {
        existing.textScore = result.score
        existing.combinedScore = 
          (existing.vectorScore * vectorWeight) + 
          (result.score * textWeight)
      } else {
        scoreMap.set(result.id, {
          ...result,
          vectorScore: 0,
          textScore: result.score,
          combinedScore: result.score * textWeight
        })
      }
    })
    
    // Sort by combined score
    return Array.from(scoreMap.values())
      .sort((a, b) => b.combinedScore - a.combinedScore)
  }
}
```

### Recommendation System

```javascript
// Build recommendation engine with Vectorize
class RecommendationEngine {
  constructor(env) {
    this.env = env
    this.userIndexName = 'user-preferences'
    this.itemIndexName = 'item-embeddings'
  }
  
  async updateUserPreferences(userId, interactions) {
    // Calculate user preference vector from interactions
    const preferenceVector = await this.calculateUserVector(interactions)
    
    await this.env.USER_VECTORS.upsert([{
      id: userId,
      values: preferenceVector,
      metadata: {
        lastUpdated: Date.now(),
        interactionCount: interactions.length,
        categories: this.extractCategories(interactions)
      }
    }])
  }
  
  async calculateUserVector(interactions) {
    // Weight recent interactions more heavily
    const now = Date.now()
    const weightedVectors = []
    
    for (const interaction of interactions) {
      const itemVector = await this.getItemVector(interaction.itemId)
      const age = now - interaction.timestamp
      const weight = this.calculateTimeDecay(age) * interaction.score
      
      weightedVectors.push({
        vector: itemVector,
        weight
      })
    }
    
    // Calculate weighted average
    return this.weightedAverage(weightedVectors)
  }
  
  calculateTimeDecay(ageMs, halfLife = 7 * 24 * 60 * 60 * 1000) {
    // Exponential decay with 7-day half-life
    return Math.exp(-0.693 * ageMs / halfLife)
  }
  
  weightedAverage(weightedVectors) {
    const dimensions = weightedVectors[0].vector.length
    const result = new Array(dimensions).fill(0)
    let totalWeight = 0
    
    for (const { vector, weight } of weightedVectors) {
      for (let i = 0; i < dimensions; i++) {
        result[i] += vector[i] * weight
      }
      totalWeight += weight
    }
    
    // Normalize
    for (let i = 0; i < dimensions; i++) {
      result[i] /= totalWeight
    }
    
    return result
  }
  
  async getRecommendations(userId, options = {}) {
    const {
      count = 10,
      diversityFactor = 0.2,
      excludeInteracted = true,
      categories = []
    } = options
    
    // Get user preference vector
    const userVector = await this.env.USER_VECTORS.get(userId)
    if (!userVector) {
      return this.getColdStartRecommendations(options)
    }
    
    // Query similar items
    const filter = {}
    if (categories.length > 0) {
      filter.category = { $in: categories }
    }
    
    const results = await this.env.ITEM_VECTORS.query(userVector.values, {
      topK: count * 3, // Get extra for filtering
      filter
    })
    
    // Apply diversity
    const diversified = this.diversifyResults(results.matches, diversityFactor)
    
    // Filter out already interacted items
    let recommendations = diversified
    if (excludeInteracted) {
      const interacted = await this.getUserInteractedItems(userId)
      recommendations = diversified.filter(
        item => !interacted.has(item.id)
      )
    }
    
    return {
      userId,
      recommendations: recommendations.slice(0, count).map(item => ({
        id: item.id,
        score: item.score,
        ...item.metadata
      })),
      basedOn: 'user_preferences'
    }
  }
  
  diversifyResults(items, diversityFactor) {
    if (diversityFactor === 0) return items
    
    const selected = []
    const remaining = [...items]
    
    // Select first item (highest score)
    selected.push(remaining.shift())
    
    while (remaining.length > 0 && selected.length < items.length) {
      // Calculate diversity score for each remaining item
      const scores = remaining.map(item => {
        const similarity = selected.reduce((sum, selectedItem) => {
          return sum + this.cosineSimilarity(item.values, selectedItem.values)
        }, 0) / selected.length
        
        // Balance relevance and diversity
        return item.score * (1 - diversityFactor) + 
               (1 - similarity) * diversityFactor
      })
      
      // Select item with highest combined score
      const bestIndex = scores.indexOf(Math.max(...scores))
      selected.push(remaining.splice(bestIndex, 1)[0])
    }
    
    return selected
  }
  
  async getColdStartRecommendations(options) {
    // Return popular or trending items for new users
    const trending = await this.env.ITEM_VECTORS.query(
      new Array(768).fill(0.5), // Neutral vector
      {
        topK: options.count,
        filter: { trending: true }
      }
    )
    
    return {
      recommendations: trending.matches.map(item => ({
        id: item.id,
        score: item.score,
        ...item.metadata
      })),
      basedOn: 'trending'
    }
  }
}
```

### Question Answering System

```javascript
// RAG-based Q&A with Vectorize
class QuestionAnsweringSystem {
  constructor(env) {
    this.env = env
    this.chunkSize = 512
    this.chunkOverlap = 128
  }
  
  async indexDocument(document) {
    // Split document into chunks
    const chunks = this.createChunks(document.content)
    const vectors = []
    
    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i]
      const embedding = await this.generateEmbedding(chunk.text)
      
      vectors.push({
        id: `${document.id}_chunk_${i}`,
        values: embedding,
        metadata: {
          documentId: document.id,
          documentTitle: document.title,
          chunkIndex: i,
          chunkText: chunk.text,
          startOffset: chunk.start,
          endOffset: chunk.end,
          section: chunk.section
        }
      })
    }
    
    await this.env.VECTORIZE.insert(vectors)
    
    return {
      documentId: document.id,
      chunksCreated: vectors.length
    }
  }
  
  createChunks(content) {
    const chunks = []
    const sentences = this.splitIntoSentences(content)
    
    let currentChunk = []
    let currentLength = 0
    let startOffset = 0
    
    for (const sentence of sentences) {
      if (currentLength + sentence.length > this.chunkSize && currentChunk.length > 0) {
        // Save current chunk
        chunks.push({
          text: currentChunk.join(' '),
          start: startOffset,
          end: startOffset + currentLength,
          section: this.detectSection(currentChunk[0])
        })
        
        // Start new chunk with overlap
        const overlapSentences = this.getOverlapSentences(currentChunk)
        currentChunk = [...overlapSentences, sentence]
        startOffset = startOffset + currentLength - this.chunkOverlap
        currentLength = currentChunk.join(' ').length
      } else {
        currentChunk.push(sentence)
        currentLength += sentence.length + 1
      }
    }
    
    // Add final chunk
    if (currentChunk.length > 0) {
      chunks.push({
        text: currentChunk.join(' '),
        start: startOffset,
        end: startOffset + currentLength,
        section: this.detectSection(currentChunk[0])
      })
    }
    
    return chunks
  }
  
  async answerQuestion(question, options = {}) {
    const {
      maxChunks = 5,
      includeSource = true,
      answerStyle = 'concise'
    } = options
    
    // Find relevant chunks
    const queryEmbedding = await this.generateEmbedding(question)
    const results = await this.env.VECTORIZE.query(queryEmbedding, {
      topK: maxChunks,
      includeMetadata: true
    })
    
    if (results.matches.length === 0) {
      return {
        answer: "I couldn't find relevant information to answer your question.",
        sources: []
      }
    }
    
    // Build context from chunks
    const context = this.buildContext(results.matches)
    
    // Generate answer
    const answer = await this.generateAnswer(question, context, answerStyle)
    
    const response = { answer }
    
    if (includeSource) {
      response.sources = results.matches.map(match => ({
        documentId: match.metadata.documentId,
        documentTitle: match.metadata.documentTitle,
        relevance: match.score,
        excerpt: this.createExcerpt(match.metadata.chunkText, 150)
      }))
    }
    
    return response
  }
  
  buildContext(matches) {
    // Sort chunks by document and position for coherence
    const sorted = matches.sort((a, b) => {
      if (a.metadata.documentId === b.metadata.documentId) {
        return a.metadata.chunkIndex - b.metadata.chunkIndex
      }
      return b.score - a.score
    })
    
    return sorted
      .map(match => match.metadata.chunkText)
      .join('\n\n')
  }
  
  async generateAnswer(question, context, style) {
    const stylePrompts = {
      concise: 'Answer in 1-2 sentences',
      detailed: 'Provide a comprehensive answer',
      bullet: 'Answer using bullet points',
      technical: 'Provide a technical explanation'
    }
    
    const prompt = `
    Context: ${context}
    
    Question: ${question}
    
    ${stylePrompts[style] || stylePrompts.concise}.
    Base your answer only on the provided context.
    If the context doesn't contain the answer, say so.
    `
    
    const response = await this.env.AI.run(
      '@cf/meta/llama-2-7b-chat-int8',
      {
        prompt,
        max_tokens: 512,
        temperature: 0.7
      }
    )
    
    return response.response
  }
  
  createExcerpt(text, maxLength) {
    if (text.length <= maxLength) return text
    
    return text.substring(0, maxLength - 3) + '...'
  }
}
```

## 🔧 Advanced Patterns

### Multi-Tenant Vector Search

```javascript
// Implement isolated vector spaces for multiple tenants
class MultiTenantVectorStore {
  constructor(env) {
    this.env = env
  }
  
  async upsertVector(tenantId, vector) {
    // Prefix vector ID with tenant ID for isolation
    const prefixedVector = {
      ...vector,
      id: `${tenantId}:${vector.id}`,
      metadata: {
        ...vector.metadata,
        tenantId
      }
    }
    
    await this.env.VECTORIZE.upsert([prefixedVector])
  }
  
  async query(tenantId, queryVector, options = {}) {
    // Filter by tenant ID
    const filter = {
      tenantId,
      ...(options.filter || {})
    }
    
    const results = await this.env.VECTORIZE.query(queryVector, {
      ...options,
      filter
    })
    
    // Remove tenant prefix from IDs
    results.matches = results.matches.map(match => ({
      ...match,
      id: match.id.replace(`${tenantId}:`, '')
    }))
    
    return results
  }
  
  async deleteTenant(tenantId) {
    // Delete all vectors for a tenant
    // Note: This is a simplified example
    const vectors = await this.listTenantVectors(tenantId)
    const ids = vectors.map(v => v.id)
    
    if (ids.length > 0) {
      await this.env.VECTORIZE.deleteByIds(ids)
    }
    
    return { deleted: ids.length }
  }
  
  async getTenantStats(tenantId) {
    // Get usage statistics for a tenant
    const sample = await this.env.VECTORIZE.query(
      new Array(768).fill(0), // Dummy vector
      {
        topK: 1,
        filter: { tenantId },
        includeMetadata: false
      }
    )
    
    return {
      tenantId,
      vectorCount: sample.count || 0,
      lastUpdated: new Date().toISOString()
    }
  }
}
```

### Incremental Index Updates

```javascript
// Handle incremental updates to vector index
class IncrementalIndexer {
  constructor(env) {
    this.env = env
    this.batchSize = 100
  }
  
  async updateDocuments(documents) {
    const updates = []
    const inserts = []
    const deletes = []
    
    for (const doc of documents) {
      switch (doc.operation) {
        case 'update':
          updates.push(doc)
          break
        case 'insert':
          inserts.push(doc)
          break
        case 'delete':
          deletes.push(doc)
          break
      }
    }
    
    const results = await Promise.all([
      this.handleUpdates(updates),
      this.handleInserts(inserts),
      this.handleDeletes(deletes)
    ])
    
    return {
      updated: results[0].length,
      inserted: results[1].length,
      deleted: results[2].length
    }
  }
  
  async handleUpdates(documents) {
    const updated = []
    
    for (const doc of documents) {
      // Delete old chunks
      await this.deleteDocumentChunks(doc.id)
      
      // Insert new chunks
      const chunks = await this.createAndEmbedChunks(doc)
      await this.env.VECTORIZE.insert(chunks)
      
      updated.push(doc.id)
    }
    
    return updated
  }
  
  async handleInserts(documents) {
    const vectors = []
    
    for (const doc of documents) {
      const chunks = await this.createAndEmbedChunks(doc)
      vectors.push(...chunks)
    }
    
    // Batch insert
    for (let i = 0; i < vectors.length; i += this.batchSize) {
      const batch = vectors.slice(i, i + this.batchSize)
      await this.env.VECTORIZE.insert(batch)
    }
    
    return documents.map(d => d.id)
  }
  
  async handleDeletes(documents) {
    const deleted = []
    
    for (const doc of documents) {
      await this.deleteDocumentChunks(doc.id)
      deleted.push(doc.id)
    }
    
    return deleted
  }
  
  async deleteDocumentChunks(documentId) {
    // Find all chunks for document
    const results = await this.env.VECTORIZE.query(
      new Array(768).fill(0), // Dummy vector
      {
        filter: { documentId },
        topK: 1000 // Max chunks per document
      }
    )
    
    if (results.matches.length > 0) {
      const ids = results.matches.map(m => m.id)
      await this.env.VECTORIZE.deleteByIds(ids)
    }
  }
}
```

### Vector Compression

```javascript
// Implement vector compression for storage optimization
class CompressedVectorStore {
  constructor(env) {
    this.env = env
    this.compressionRatio = 0.5 // Reduce dimensions by 50%
  }
  
  async insert(vectors) {
    const compressed = vectors.map(v => ({
      ...v,
      values: this.compressVector(v.values),
      metadata: {
        ...v.metadata,
        originalDimensions: v.values.length,
        compressed: true
      }
    }))
    
    await this.env.VECTORIZE.insert(compressed)
  }
  
  async query(queryVector, options) {
    // Compress query vector
    const compressedQuery = this.compressVector(queryVector)
    
    // Query with compressed vector
    const results = await this.env.VECTORIZE.query(compressedQuery, options)
    
    // Adjust scores based on compression loss
    results.matches = results.matches.map(match => ({
      ...match,
      score: this.adjustScore(match.score)
    }))
    
    return results
  }
  
  compressVector(vector) {
    // Simple PCA-like compression (simplified)
    const targetDims = Math.floor(vector.length * this.compressionRatio)
    const compressed = []
    
    // Average adjacent dimensions
    const step = vector.length / targetDims
    for (let i = 0; i < targetDims; i++) {
      const start = Math.floor(i * step)
      const end = Math.floor((i + 1) * step)
      
      let sum = 0
      for (let j = start; j < end; j++) {
        sum += vector[j]
      }
      
      compressed.push(sum / (end - start))
    }
    
    return compressed
  }
  
  adjustScore(compressedScore) {
    // Adjust similarity score based on compression loss
    return compressedScore * 0.95 // 5% penalty for compression
  }
}
```

## 🚀 Performance Optimization

### Caching Layer

```javascript
// Implement caching for vector queries
class CachedVectorSearch {
  constructor(env) {
    this.env = env
    this.cache = caches.default
    this.cacheTTL = 3600000 // 1 hour
  }
  
  async query(queryVector, options = {}) {
    const cacheKey = this.getCacheKey(queryVector, options)
    
    // Check cache
    const cached = await this.cache.match(cacheKey)
    if (cached) {
      const data = await cached.json()
      if (Date.now() - data.timestamp < this.cacheTTL) {
        return data.results
      }
    }
    
    // Query Vectorize
    const results = await this.env.VECTORIZE.query(queryVector, options)
    
    // Cache results
    await this.cache.put(
      cacheKey,
      Response.json({
        results,
        timestamp: Date.now()
      })
    )
    
    return results
  }
  
  getCacheKey(vector, options) {
    // Create deterministic cache key
    const vectorHash = this.hashVector(vector)
    const optionsHash = this.hashObject(options)
    
    return new Request(
      `https://vector-cache.local/${vectorHash}/${optionsHash}`
    )
  }
  
  hashVector(vector) {
    // Simple vector hashing (first and last few values + length)
    const sample = [
      ...vector.slice(0, 5),
      vector.length,
      ...vector.slice(-5)
    ].join(',')
    
    return btoa(sample).replace(/[^a-zA-Z0-9]/g, '').substring(0, 16)
  }
  
  hashObject(obj) {
    return btoa(JSON.stringify(obj))
      .replace(/[^a-zA-Z0-9]/g, '')
      .substring(0, 16)
  }
}
```

### Batch Processing

```javascript
// Efficient batch operations
class BatchVectorProcessor {
  constructor(env) {
    this.env = env
    this.queue = []
    this.processing = false
    this.batchSize = 100
    this.flushInterval = 1000 // 1 second
  }
  
  async add(operation) {
    return new Promise((resolve, reject) => {
      this.queue.push({ operation, resolve, reject })
      
      if (this.queue.length >= this.batchSize) {
        this.flush()
      } else if (!this.processing) {
        setTimeout(() => this.flush(), this.flushInterval)
      }
    })
  }
  
  async flush() {
    if (this.processing || this.queue.length === 0) return
    
    this.processing = true
    const batch = this.queue.splice(0, this.batchSize)
    
    try {
      // Group operations by type
      const groups = this.groupOperations(batch)
      
      // Execute each group
      const results = await Promise.all([
        this.executeInserts(groups.insert),
        this.executeUpdates(groups.update),
        this.executeDeletes(groups.delete)
      ])
      
      // Resolve promises
      let resultIndex = 0
      batch.forEach(({ operation, resolve }) => {
        resolve(results.flat()[resultIndex++])
      })
    } catch (error) {
      batch.forEach(({ reject }) => reject(error))
    } finally {
      this.processing = false
      
      if (this.queue.length > 0) {
        this.flush()
      }
    }
  }
  
  groupOperations(batch) {
    const groups = {
      insert: [],
      update: [],
      delete: []
    }
    
    batch.forEach(({ operation }) => {
      groups[operation.type].push(operation)
    })
    
    return groups
  }
}
```

## 🔍 Monitoring & Analytics

```javascript
// Vector search analytics
class VectorAnalytics {
  constructor(env) {
    this.env = env
  }
  
  async logQuery(query, results, metadata) {
    const analytics = {
      timestamp: Date.now(),
      queryId: crypto.randomUUID(),
      resultCount: results.matches.length,
      topScore: results.matches[0]?.score || 0,
      avgScore: this.calculateAvgScore(results.matches),
      metadata
    }
    
    // Log to Analytics Engine
    await this.env.ANALYTICS.writeDataPoint({
      series: 'vector_queries',
      tags: {
        index: metadata.index,
        userId: metadata.userId
      },
      fields: {
        resultCount: analytics.resultCount,
        topScore: analytics.topScore,
        queryTime: metadata.queryTime
      },
      timestamp: analytics.timestamp
    })
    
    return analytics
  }
  
  calculateAvgScore(matches) {
    if (matches.length === 0) return 0
    
    const sum = matches.reduce((acc, match) => acc + match.score, 0)
    return sum / matches.length
  }
  
  async getQueryStats(timeRange = '1h') {
    const results = await this.env.ANALYTICS.query({
      series: 'vector_queries',
      timeRange,
      aggregations: [
        { type: 'count', alias: 'total_queries' },
        { type: 'avg', field: 'resultCount', alias: 'avg_results' },
        { type: 'avg', field: 'topScore', alias: 'avg_top_score' },
        { type: 'p95', field: 'queryTime', alias: 'p95_query_time' }
      ]
    })
    
    return results
  }
}
```

## 📚 Best Practices

### 1. **Vector Dimensions**
- Use appropriate embedding models (768 for BERT, 1536 for GPT)
- Consider dimension reduction for large scale
- Match dimensions across your pipeline
- Test different models for your use case

### 2. **Metadata Design**
- Keep metadata lightweight
- Index frequently filtered fields
- Avoid storing large text in metadata
- Use references to external storage

### 3. **Query Optimization**
- Implement caching for common queries
- Use appropriate topK values
- Apply pre-filtering when possible
- Batch similar queries

### 4. **Index Management**
- Plan for incremental updates
- Implement cleanup strategies
- Monitor index size and performance
- Use multiple indexes for different data types

### 5. **Cost Control**
- Monitor query volumes
- Implement rate limiting
- Cache aggressively
- Optimize vector dimensions

## 📖 Resources & References

### Official Documentation
- [Vectorize Documentation](https://developers.cloudflare.com/vectorize/)
- [Vectorize API Reference](https://developers.cloudflare.com/vectorize/api-reference/)
- [Vectorize Limits](https://developers.cloudflare.com/vectorize/limits/)
- [Vectorize Pricing](https://developers.cloudflare.com/vectorize/pricing/)

### Integration Guides
- **Workers AI + Vectorize** - Embedding generation
- **D1 + Vectorize** - Hybrid search
- **R2 + Vectorize** - Document storage
- **Queues + Vectorize** - Async indexing

### Example Applications
- **Semantic Search** - Document search system
- **Recommendation Engine** - Personalized recommendations  
- **Q&A System** - RAG implementation
- **Image Search** - Visual similarity search

---

*This guide covers essential Vectorize patterns for building intelligent applications with vector search. Focus on embedding quality, metadata design, and query optimization for best results.*
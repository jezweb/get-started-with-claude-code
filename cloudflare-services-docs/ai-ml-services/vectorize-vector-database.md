# Cloudflare Vectorize - Vector Database

## Overview

Cloudflare Vectorize is a globally distributed vector database designed for AI applications, enabling semantic search, recommendation systems, and similarity matching at scale. Built on Cloudflare's edge network, Vectorize provides low-latency vector operations with automatic scaling and no infrastructure management.

## Quick Start

### Basic Setup
```javascript
// Workers with Vectorize integration
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    if (url.pathname === '/search' && request.method === 'POST') {
      const { query, limit = 10 } = await request.json();
      
      // Generate embedding for search query
      const embedding = await generateEmbedding(query, env);
      
      // Search vectors
      const results = await env.VECTORIZE_INDEX.query(embedding, {
        topK: limit,
        returnMetadata: true
      });
      
      return Response.json({
        query,
        results: results.matches.map(match => ({
          id: match.id,
          score: match.score,
          metadata: match.metadata
        }))
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};

async function generateEmbedding(text, env) {
  // Use Workers AI or external API to generate embeddings
  const response = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
    text: [text]
  });
  
  return response.data[0];
}
```

### Configuration
```toml
# wrangler.toml
[[vectorize]]
binding = "VECTORIZE_INDEX"
index_name = "semantic-search-index"

[[ai]]
binding = "AI"
```

## Core Concepts

### Vector Operations
Vectorize supports standard vector database operations:

```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const method = request.method;
    
    if (url.pathname === '/vectors') {
      switch (method) {
        case 'POST':
          return this.insertVectors(request, env);
        case 'GET':
          return this.queryVectors(request, env);
        case 'PUT':
          return this.updateVectors(request, env);
        case 'DELETE':
          return this.deleteVectors(request, env);
      }
    }
    
    return new Response('Not found', { status: 404 });
  },
  
  async insertVectors(request, env) {
    const { vectors } = await request.json();
    
    // Validate vectors
    if (!vectors || !Array.isArray(vectors)) {
      return new Response('Invalid vectors format', { status: 400 });
    }
    
    // Insert vectors into Vectorize
    const insertResult = await env.VECTORIZE_INDEX.upsert(vectors);
    
    return Response.json({
      inserted: insertResult.count,
      ids: insertResult.ids
    });
  },
  
  async queryVectors(request, env) {
    const url = new URL(request.url);
    const queryVector = JSON.parse(url.searchParams.get('vector') || '[]');
    const topK = parseInt(url.searchParams.get('topK') || '10');
    const filter = JSON.parse(url.searchParams.get('filter') || '{}');
    
    const results = await env.VECTORIZE_INDEX.query(queryVector, {
      topK,
      filter,
      returnMetadata: true,
      returnVectors: false
    });
    
    return Response.json(results);
  },
  
  async updateVectors(request, env) {
    const { vectors } = await request.json();
    
    // Upsert (insert or update) vectors
    const result = await env.VECTORIZE_INDEX.upsert(vectors);
    
    return Response.json({
      updated: result.count,
      ids: result.ids
    });
  },
  
  async deleteVectors(request, env) {
    const { ids } = await request.json();
    
    const result = await env.VECTORIZE_INDEX.deleteByIds(ids);
    
    return Response.json({
      deleted: result.count
    });
  }
};
```

### Metadata Filtering
```javascript
// Advanced querying with metadata filters
async function searchWithFilters(query, filters, env) {
  const embedding = await generateEmbedding(query, env);
  
  // Complex metadata filtering
  const results = await env.VECTORIZE_INDEX.query(embedding, {
    topK: 20,
    filter: {
      category: { $eq: filters.category },
      created_at: { 
        $gte: filters.dateFrom,
        $lte: filters.dateTo 
      },
      tags: { $in: filters.tags },
      author: { $ne: 'excluded_author' }
    },
    returnMetadata: true
  });
  
  return results.matches;
}
```

## Integration Patterns

### 1. Semantic Document Search

```javascript
// Comprehensive document search system
class DocumentSearchEngine {
  constructor(vectorizeIndex, aiBinding) {
    this.vectorize = vectorizeIndex;
    this.ai = aiBinding;
  }
  
  async indexDocument(document) {
    // Process document into chunks
    const chunks = this.chunkDocument(document.content, 512);
    
    // Generate embeddings for each chunk
    const vectors = await Promise.all(
      chunks.map(async (chunk, index) => {
        const embedding = await this.generateEmbedding(chunk);
        
        return {
          id: `${document.id}_chunk_${index}`,
          values: embedding,
          metadata: {
            document_id: document.id,
            document_title: document.title,
            document_type: document.type,
            chunk_index: index,
            chunk_text: chunk,
            author: document.author,
            created_at: document.created_at,
            tags: document.tags || [],
            word_count: chunk.split(' ').length
          }
        };
      })
    );
    
    // Insert vectors into Vectorize
    const result = await this.vectorize.upsert(vectors);
    
    return {
      document_id: document.id,
      chunks_indexed: vectors.length,
      vector_ids: result.ids
    };
  }
  
  async searchDocuments(query, options = {}) {
    const {
      limit = 10,
      documentTypes = [],
      authors = [],
      tags = [],
      dateRange = null,
      includeSnippets = true
    } = options;
    
    // Generate query embedding
    const queryEmbedding = await this.generateEmbedding(query);
    
    // Build metadata filter
    const filter = this.buildSearchFilter({
      documentTypes,
      authors,
      tags,
      dateRange
    });
    
    // Search vectors
    const searchResults = await this.vectorize.query(queryEmbedding, {
      topK: limit * 3, // Get more results to deduplicate
      filter,
      returnMetadata: true
    });
    
    // Process and deduplicate results
    const documents = this.processSearchResults(
      searchResults.matches,
      query,
      limit,
      includeSnippets
    );
    
    return {
      query,
      total_results: documents.length,
      documents,
      search_time: Date.now()
    };
  }
  
  chunkDocument(content, maxTokens) {
    const words = content.split(' ');
    const chunks = [];
    
    for (let i = 0; i < words.length; i += maxTokens) {
      const chunk = words.slice(i, i + maxTokens).join(' ');
      if (chunk.trim()) {
        chunks.push(chunk.trim());
      }
    }
    
    return chunks;
  }
  
  async generateEmbedding(text) {
    const response = await this.ai.run('@cf/baai/bge-base-en-v1.5', {
      text: [text]
    });
    
    return response.data[0];
  }
  
  buildSearchFilter(options) {
    const filter = {};
    
    if (options.documentTypes.length > 0) {
      filter.document_type = { $in: options.documentTypes };
    }
    
    if (options.authors.length > 0) {
      filter.author = { $in: options.authors };
    }
    
    if (options.tags.length > 0) {
      filter.tags = { $in: options.tags };
    }
    
    if (options.dateRange) {
      filter.created_at = {
        $gte: options.dateRange.from,
        $lte: options.dateRange.to
      };
    }
    
    return filter;
  }
  
  processSearchResults(matches, query, limit, includeSnippets) {
    // Group by document and find best matching chunk per document
    const documentGroups = new Map();
    
    for (const match of matches) {
      const docId = match.metadata.document_id;
      
      if (!documentGroups.has(docId) || 
          documentGroups.get(docId).score < match.score) {
        documentGroups.set(docId, {
          document_id: docId,
          title: match.metadata.document_title,
          type: match.metadata.document_type,
          author: match.metadata.author,
          created_at: match.metadata.created_at,
          tags: match.metadata.tags,
          score: match.score,
          best_chunk: match.metadata.chunk_text,
          chunk_index: match.metadata.chunk_index
        });
      }
    }
    
    // Convert to array and sort by relevance
    let documents = Array.from(documentGroups.values())
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);
    
    // Add snippets if requested
    if (includeSnippets) {
      documents = documents.map(doc => ({
        ...doc,
        snippet: this.generateSnippet(doc.best_chunk, query)
      }));
    }
    
    return documents;
  }
  
  generateSnippet(text, query, maxLength = 200) {
    const queryWords = query.toLowerCase().split(' ');
    const textLower = text.toLowerCase();
    
    // Find best starting position (around first query word match)
    let bestStart = 0;
    for (const word of queryWords) {
      const index = textLower.indexOf(word);
      if (index !== -1) {
        bestStart = Math.max(0, index - 50);
        break;
      }
    }
    
    // Extract snippet
    let snippet = text.substring(bestStart, bestStart + maxLength);
    
    // Ensure we don't cut words
    if (bestStart > 0) {
      const firstSpace = snippet.indexOf(' ');
      if (firstSpace > 0) {
        snippet = '...' + snippet.substring(firstSpace);
      }
    }
    
    if (snippet.length === maxLength) {
      const lastSpace = snippet.lastIndexOf(' ');
      if (lastSpace > 0) {
        snippet = snippet.substring(0, lastSpace) + '...';
      }
    }
    
    return snippet;
  }
  
  async deleteDocument(documentId) {
    // Find all vectors for this document
    const searchResults = await this.vectorize.query(
      new Array(384).fill(0), // Zero vector for metadata-only search
      {
        topK: 1000,
        filter: { document_id: { $eq: documentId } },
        returnMetadata: true
      }
    );
    
    // Delete all vectors for this document
    const vectorIds = searchResults.matches.map(match => match.id);
    
    if (vectorIds.length > 0) {
      await this.vectorize.deleteByIds(vectorIds);
    }
    
    return {
      document_id: documentId,
      deleted_vectors: vectorIds.length
    };
  }
}
```

### 2. Recommendation System

```javascript
// Product/content recommendation system
class RecommendationEngine {
  constructor(vectorizeIndex, aiBinding) {
    this.vectorize = vectorizeIndex;
    this.ai = aiBinding;
  }
  
  async indexItem(item) {
    // Create rich text representation for embedding
    const textRepresentation = this.createItemDescription(item);
    
    // Generate embedding
    const embedding = await this.generateEmbedding(textRepresentation);
    
    // Store in Vectorize
    const vector = {
      id: item.id,
      values: embedding,
      metadata: {
        title: item.title,
        category: item.category,
        price: item.price,
        tags: item.tags || [],
        rating: item.rating || 0,
        created_at: item.created_at,
        popularity_score: item.popularity_score || 0,
        description: item.description
      }
    };
    
    await this.vectorize.upsert([vector]);
    
    return { success: true, item_id: item.id };
  }
  
  async getRecommendations(userId, options = {}) {
    const {
      limit = 10,
      categories = [],
      priceRange = null,
      excludeIds = [],
      includeUserHistory = true
    } = options;
    
    // Get user embedding (based on history, preferences, etc.)
    const userEmbedding = await this.getUserEmbedding(userId, includeUserHistory);
    
    // Build filter
    const filter = this.buildRecommendationFilter({
      categories,
      priceRange,
      excludeIds
    });
    
    // Search for similar items
    const results = await this.vectorize.query(userEmbedding, {
      topK: limit * 2, // Get extra for filtering
      filter,
      returnMetadata: true
    });
    
    // Post-process recommendations
    const recommendations = this.processRecommendations(
      results.matches,
      userId,
      limit
    );
    
    return {
      user_id: userId,
      recommendations,
      generated_at: Date.now()
    };
  }
  
  async getSimilarItems(itemId, limit = 10) {
    // Get the item's embedding
    const itemResults = await this.vectorize.query(
      new Array(384).fill(0), // Zero vector for metadata search
      {
        topK: 1,
        filter: { id: { $eq: itemId } },
        returnVectors: true,
        returnMetadata: true
      }
    );
    
    if (itemResults.matches.length === 0) {
      throw new Error('Item not found');
    }
    
    const itemVector = itemResults.matches[0].values;
    const itemCategory = itemResults.matches[0].metadata.category;
    
    // Find similar items
    const similarResults = await this.vectorize.query(itemVector, {
      topK: limit + 1, // +1 to exclude the item itself
      filter: {
        id: { $ne: itemId }, // Exclude the original item
        category: { $eq: itemCategory } // Same category
      },
      returnMetadata: true
    });
    
    return {
      base_item_id: itemId,
      similar_items: similarResults.matches.map(match => ({
        id: match.id,
        title: match.metadata.title,
        similarity_score: match.score,
        price: match.metadata.price,
        rating: match.metadata.rating
      }))
    };
  }
  
  createItemDescription(item) {
    // Create rich text representation for better embeddings
    const parts = [
      item.title,
      item.description,
      `Category: ${item.category}`,
      `Tags: ${(item.tags || []).join(', ')}`
    ];
    
    if (item.price) {
      parts.push(`Price: $${item.price}`);
    }
    
    if (item.rating) {
      parts.push(`Rating: ${item.rating}/5`);
    }
    
    return parts.filter(Boolean).join('. ');
  }
  
  async getUserEmbedding(userId, includeHistory = true) {
    if (!includeHistory) {
      // Return a default embedding or user preference embedding
      return new Array(384).fill(0);
    }
    
    // Get user interaction history
    const userHistory = await this.getUserHistory(userId);
    
    if (userHistory.length === 0) {
      return new Array(384).fill(0);
    }
    
    // Create user profile text
    const profileText = this.createUserProfile(userHistory);
    
    // Generate embedding for user profile
    return await this.generateEmbedding(profileText);
  }
  
  async getUserHistory(userId) {
    // This would typically come from your user activity database
    // For demo purposes, return mock data
    return [
      { item_id: 'item1', action: 'view', timestamp: Date.now() - 86400000 },
      { item_id: 'item2', action: 'purchase', timestamp: Date.now() - 172800000 }
    ];
  }
  
  createUserProfile(history) {
    // Create a text representation of user preferences
    const recentItems = history.slice(0, 10); // Last 10 interactions
    
    return `User interests based on recent activity: ${
      recentItems.map(h => `${h.action} item ${h.item_id}`).join(', ')
    }`;
  }
  
  buildRecommendationFilter(options) {
    const filter = {};
    
    if (options.categories.length > 0) {
      filter.category = { $in: options.categories };
    }
    
    if (options.priceRange) {
      filter.price = {
        $gte: options.priceRange.min,
        $lte: options.priceRange.max
      };
    }
    
    if (options.excludeIds.length > 0) {
      filter.id = { $nin: options.excludeIds };
    }
    
    return filter;
  }
  
  processRecommendations(matches, userId, limit) {
    return matches
      .slice(0, limit)
      .map(match => ({
        item_id: match.id,
        title: match.metadata.title,
        category: match.metadata.category,
        price: match.metadata.price,
        rating: match.metadata.rating,
        relevance_score: match.score,
        reason: this.generateRecommendationReason(match)
      }));
  }
  
  generateRecommendationReason(match) {
    if (match.score > 0.9) {
      return 'Highly recommended based on your preferences';
    } else if (match.score > 0.8) {
      return 'Similar to items you\'ve liked';
    } else if (match.metadata.rating > 4.5) {
      return 'Highly rated by other users';
    } else {
      return 'Recommended for you';
    }
  }
  
  async generateEmbedding(text) {
    const response = await this.ai.run('@cf/baai/bge-base-en-v1.5', {
      text: [text]
    });
    
    return response.data[0];
  }
}
```

### 3. Content Clustering and Analysis

```javascript
// Automated content clustering and analysis
class ContentAnalyzer {
  constructor(vectorizeIndex, aiBinding) {
    this.vectorize = vectorizeIndex;
    this.ai = aiBinding;
  }
  
  async analyzeContentSimilarity(contentIds) {
    // Get vectors for all content
    const vectors = await this.getVectorsForContent(contentIds);
    
    // Calculate pairwise similarities
    const similarities = this.calculateSimilarityMatrix(vectors);
    
    // Find clusters
    const clusters = this.identifyClusters(similarities, 0.8); // 80% similarity threshold
    
    return {
      content_count: contentIds.length,
      clusters,
      similarity_matrix: similarities
    };
  }
  
  async findDuplicateContent(threshold = 0.95) {
    // Get all vectors (you might want to batch this for large datasets)
    const allVectors = await this.getAllVectors();
    
    const duplicates = [];
    
    for (let i = 0; i < allVectors.length; i++) {
      for (let j = i + 1; j < allVectors.length; j++) {
        const similarity = this.cosineSimilarity(
          allVectors[i].values,
          allVectors[j].values
        );
        
        if (similarity >= threshold) {
          duplicates.push({
            content1: allVectors[i].id,
            content2: allVectors[j].id,
            similarity_score: similarity,
            metadata1: allVectors[i].metadata,
            metadata2: allVectors[j].metadata
          });
        }
      }
    }
    
    return duplicates;
  }
  
  async categorizeContent(contentId, possibleCategories) {
    // Get content vector
    const contentVector = await this.getContentVector(contentId);
    
    // Generate category embeddings
    const categoryEmbeddings = await Promise.all(
      possibleCategories.map(async category => ({
        category,
        embedding: await this.generateEmbedding(category)
      }))
    );
    
    // Calculate similarities
    const categoryScores = categoryEmbeddings.map(({ category, embedding }) => ({
      category,
      score: this.cosineSimilarity(contentVector.values, embedding)
    }));
    
    // Sort by score
    categoryScores.sort((a, b) => b.score - a.score);
    
    return {
      content_id: contentId,
      suggested_categories: categoryScores,
      best_match: categoryScores[0]
    };
  }
  
  async getVectorsForContent(contentIds) {
    const vectors = [];
    
    // Batch fetch vectors
    for (const id of contentIds) {
      const result = await this.vectorize.query(
        new Array(384).fill(0), // Zero vector for metadata search
        {
          topK: 1,
          filter: { id: { $eq: id } },
          returnVectors: true,
          returnMetadata: true
        }
      );
      
      if (result.matches.length > 0) {
        vectors.push(result.matches[0]);
      }
    }
    
    return vectors;
  }
  
  calculateSimilarityMatrix(vectors) {
    const matrix = [];
    
    for (let i = 0; i < vectors.length; i++) {
      matrix[i] = [];
      for (let j = 0; j < vectors.length; j++) {
        if (i === j) {
          matrix[i][j] = 1.0;
        } else {
          matrix[i][j] = this.cosineSimilarity(
            vectors[i].values,
            vectors[j].values
          );
        }
      }
    }
    
    return matrix;
  }
  
  identifyClusters(similarityMatrix, threshold) {
    const clusters = [];
    const visited = new Set();
    
    for (let i = 0; i < similarityMatrix.length; i++) {
      if (visited.has(i)) continue;
      
      const cluster = [i];
      visited.add(i);
      
      for (let j = i + 1; j < similarityMatrix.length; j++) {
        if (!visited.has(j) && similarityMatrix[i][j] >= threshold) {
          cluster.push(j);
          visited.add(j);
        }
      }
      
      if (cluster.length > 1) {
        clusters.push(cluster);
      }
    }
    
    return clusters;
  }
  
  cosineSimilarity(vecA, vecB) {
    let dotProduct = 0;
    let normA = 0;
    let normB = 0;
    
    for (let i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }
    
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }
  
  async getAllVectors() {
    // Note: In production, you'd want to implement pagination
    const result = await this.vectorize.query(
      new Array(384).fill(0),
      {
        topK: 10000, // Adjust based on your dataset size
        returnVectors: true,
        returnMetadata: true
      }
    );
    
    return result.matches;
  }
  
  async getContentVector(contentId) {
    const result = await this.vectorize.query(
      new Array(384).fill(0),
      {
        topK: 1,
        filter: { id: { $eq: contentId } },
        returnVectors: true,
        returnMetadata: true
      }
    );
    
    if (result.matches.length === 0) {
      throw new Error(`Content not found: ${contentId}`);
    }
    
    return result.matches[0];
  }
  
  async generateEmbedding(text) {
    const response = await this.ai.run('@cf/baai/bge-base-en-v1.5', {
      text: [text]
    });
    
    return response.data[0];
  }
}
```

## Advanced Features

### 1. Hybrid Search (Vector + Text)

```javascript
// Combine vector similarity with traditional text search
class HybridSearchEngine {
  constructor(vectorizeIndex, aiBinding, searchIndex) {
    this.vectorize = vectorizeIndex;
    this.ai = aiBinding;
    this.searchIndex = searchIndex; // Traditional search index (KV or external)
  }
  
  async hybridSearch(query, options = {}) {
    const {
      limit = 10,
      vectorWeight = 0.7,
      textWeight = 0.3,
      filters = {}
    } = options;
    
    // Perform vector search
    const vectorResults = await this.vectorSearch(query, filters, limit * 2);
    
    // Perform text search
    const textResults = await this.textSearch(query, filters, limit * 2);
    
    // Combine and rank results
    const combinedResults = this.combineResults(
      vectorResults,
      textResults,
      vectorWeight,
      textWeight
    );
    
    return {
      query,
      total_results: combinedResults.length,
      results: combinedResults.slice(0, limit),
      method: 'hybrid'
    };
  }
  
  async vectorSearch(query, filters, limit) {
    const embedding = await this.generateEmbedding(query);
    
    const results = await this.vectorize.query(embedding, {
      topK: limit,
      filter: filters,
      returnMetadata: true
    });
    
    return results.matches.map(match => ({
      id: match.id,
      score: match.score,
      type: 'vector',
      metadata: match.metadata
    }));
  }
  
  async textSearch(query, filters, limit) {
    // Implement text search using KV or external search service
    // This is a simplified example
    const searchKey = `search:${query.toLowerCase()}`;
    const results = await this.searchIndex.get(searchKey, 'json') || [];
    
    return results.slice(0, limit).map(result => ({
      id: result.id,
      score: result.textScore,
      type: 'text',
      metadata: result.metadata
    }));
  }
  
  combineResults(vectorResults, textResults, vectorWeight, textWeight) {
    const combinedScores = new Map();
    
    // Add vector scores
    for (const result of vectorResults) {
      combinedScores.set(result.id, {
        ...result,
        combinedScore: result.score * vectorWeight,
        vectorScore: result.score,
        textScore: 0
      });
    }
    
    // Add text scores
    for (const result of textResults) {
      if (combinedScores.has(result.id)) {
        const existing = combinedScores.get(result.id);
        existing.combinedScore += result.score * textWeight;
        existing.textScore = result.score;
      } else {
        combinedScores.set(result.id, {
          ...result,
          combinedScore: result.score * textWeight,
          vectorScore: 0,
          textScore: result.score
        });
      }
    }
    
    // Sort by combined score
    return Array.from(combinedScores.values())
      .sort((a, b) => b.combinedScore - a.combinedScore);
  }
  
  async generateEmbedding(text) {
    const response = await this.ai.run('@cf/baai/bge-base-en-v1.5', {
      text: [text]
    });
    
    return response.data[0];
  }
}
```

### 2. Real-time Vector Updates

```javascript
// Handle real-time vector updates and consistency
class VectorUpdateManager {
  constructor(vectorizeIndex, changeLog) {
    this.vectorize = vectorizeIndex;
    this.changeLog = changeLog; // KV store for tracking changes
  }
  
  async updateVector(id, newVector, metadata) {
    // Create update operation
    const updateOp = {
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      type: 'update',
      vectorId: id,
      oldVector: await this.getExistingVector(id),
      newVector,
      metadata
    };
    
    // Log the operation
    await this.logOperation(updateOp);
    
    try {
      // Perform the update
      await this.vectorize.upsert([{
        id,
        values: newVector,
        metadata
      }]);
      
      // Mark operation as successful
      await this.markOperationComplete(updateOp.id, 'success');
      
      return { success: true, operationId: updateOp.id };
    } catch (error) {
      // Mark operation as failed
      await this.markOperationComplete(updateOp.id, 'failed', error.message);
      throw error;
    }
  }
  
  async batchUpdate(updates) {
    const batchId = crypto.randomUUID();
    const operations = [];
    
    // Prepare batch operations
    for (const update of updates) {
      const operation = {
        id: crypto.randomUUID(),
        batchId,
        timestamp: Date.now(),
        type: 'batch_update',
        vectorId: update.id,
        newVector: update.vector,
        metadata: update.metadata
      };
      
      operations.push(operation);
    }
    
    // Log batch operation
    await this.logBatchOperation(batchId, operations);
    
    try {
      // Prepare vectors for upsert
      const vectors = updates.map(update => ({
        id: update.id,
        values: update.vector,
        metadata: update.metadata
      }));
      
      // Perform batch upsert
      const result = await this.vectorize.upsert(vectors);
      
      // Mark batch as successful
      await this.markBatchComplete(batchId, 'success', result);
      
      return {
        success: true,
        batchId,
        updated: result.count,
        operations: operations.length
      };
    } catch (error) {
      // Mark batch as failed
      await this.markBatchComplete(batchId, 'failed', null, error.message);
      throw error;
    }
  }
  
  async getExistingVector(id) {
    const result = await this.vectorize.query(
      new Array(384).fill(0),
      {
        topK: 1,
        filter: { id: { $eq: id } },
        returnVectors: true,
        returnMetadata: true
      }
    );
    
    return result.matches.length > 0 ? result.matches[0] : null;
  }
  
  async logOperation(operation) {
    const key = `operation:${operation.id}`;
    await this.changeLog.put(key, JSON.stringify(operation), {
      expirationTtl: 86400 * 7 // Keep for 7 days
    });
  }
  
  async logBatchOperation(batchId, operations) {
    const batchLog = {
      batchId,
      timestamp: Date.now(),
      operations: operations.length,
      status: 'pending'
    };
    
    await this.changeLog.put(`batch:${batchId}`, JSON.stringify(batchLog), {
      expirationTtl: 86400 * 7
    });
    
    // Log individual operations
    for (const operation of operations) {
      await this.logOperation(operation);
    }
  }
  
  async markOperationComplete(operationId, status, error = null) {
    const key = `operation:${operationId}`;
    const operation = await this.changeLog.get(key, 'json');
    
    if (operation) {
      operation.status = status;
      operation.completedAt = Date.now();
      if (error) {
        operation.error = error;
      }
      
      await this.changeLog.put(key, JSON.stringify(operation), {
        expirationTtl: 86400 * 7
      });
    }
  }
  
  async markBatchComplete(batchId, status, result = null, error = null) {
    const key = `batch:${batchId}`;
    const batch = await this.changeLog.get(key, 'json');
    
    if (batch) {
      batch.status = status;
      batch.completedAt = Date.now();
      if (result) {
        batch.result = result;
      }
      if (error) {
        batch.error = error;
      }
      
      await this.changeLog.put(key, JSON.stringify(batch), {
        expirationTtl: 86400 * 7
      });
    }
  }
  
  async getOperationStatus(operationId) {
    const operation = await this.changeLog.get(`operation:${operationId}`, 'json');
    return operation || { error: 'Operation not found' };
  }
  
  async getBatchStatus(batchId) {
    const batch = await this.changeLog.get(`batch:${batchId}`, 'json');
    return batch || { error: 'Batch not found' };
  }
}
```

## Performance Optimization

### Batch Operations
- Process multiple vectors in single requests
- Use appropriate batch sizes (100-1000 vectors)
- Implement retry logic for failed operations
- Monitor operation latency and throughput

### Query Optimization
- Use metadata filters to reduce search space
- Optimize embedding dimensions for your use case
- Implement result caching for frequent queries
- Use appropriate topK values

### Memory Management
- Stream large result sets
- Implement pagination for large datasets
- Clean up unused vectors regularly
- Monitor index size and performance

## Best Practices

### Data Modeling
- Design consistent metadata schemas
- Use meaningful vector IDs
- Implement proper data validation
- Plan for data evolution and migration

### Indexing Strategy
- Separate indexes by use case when appropriate
- Use metadata filtering effectively
- Monitor index performance metrics
- Implement proper backup and recovery

### Security
- Validate all input vectors and metadata
- Implement proper access controls
- Monitor for unusual query patterns
- Protect sensitive data in metadata

### Monitoring
- Track query performance metrics
- Monitor index size and growth
- Set up alerting for errors
- Analyze usage patterns

## Common Use Cases

1. **Semantic Search** - Document and content discovery
2. **Recommendation Systems** - Product and content recommendations  
3. **Content Classification** - Automatic categorization and tagging
4. **Duplicate Detection** - Find similar or duplicate content
5. **Clustering Analysis** - Group related content automatically
6. **Question Answering** - RAG (Retrieval Augmented Generation) systems

Vectorize provides the vector database foundation needed for AI-powered search, recommendations, and content understanding applications that scale globally with Cloudflare's edge network.
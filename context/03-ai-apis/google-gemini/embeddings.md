# Google Gemini Embeddings

## Overview
Embeddings are numerical representations of text that capture semantic meaning and relationships. Gemini's embedding capabilities enable advanced text similarity, search, classification, and clustering applications.

## What Are Embeddings?

### Core Concept
- **Vector representations**: Text converted to arrays of floating-point numbers
- **Semantic understanding**: Similar texts have "closer" embeddings in vector space
- **Dimensional vectors**: Contain hundreds of dimensions capturing meaning
- **Mathematical operations**: Enable similarity calculations and comparisons

### Key Benefits
- **Semantic search**: Find content by meaning, not just keywords
- **Text classification**: Categorize content automatically
- **Clustering**: Group similar content together
- **Recommendation systems**: Suggest related content
- **Similarity detection**: Identify duplicate or similar content

## Available Embedding Models

### Current Models
1. **text-embedding-004**
   - Latest general-purpose embedding model
   - Optimized for various text understanding tasks
   - Best overall performance

2. **embedding-001**
   - Legacy embedding model
   - Still supported for existing applications
   - Consider upgrading to newer models

3. **gemini-embedding-exp-03-07**
   - Experimental embedding model
   - Preview of upcoming capabilities
   - Not recommended for production

## Task Types

### SEMANTIC_SIMILARITY
Measure how similar two pieces of text are:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="What is machine learning?",
    task_type="SEMANTIC_SIMILARITY"
)
```

### CLASSIFICATION
Optimized for text classification tasks:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="Product review: Great quality and fast delivery!",
    task_type="CLASSIFICATION"
)
```

### CLUSTERING
Group similar content together:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="News article about technology trends",
    task_type="CLUSTERING"
)
```

### RETRIEVAL_DOCUMENT
Optimized for document indexing:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="Long document content for retrieval...",
    task_type="RETRIEVAL_DOCUMENT"
)
```

### RETRIEVAL_QUERY
Optimized for search queries:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="search query",
    task_type="RETRIEVAL_QUERY"
)
```

### QUESTION_ANSWERING
Optimized for QA systems:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="What is the capital of France?",
    task_type="QUESTION_ANSWERING"
)
```

### FACT_VERIFICATION
Optimized for fact-checking:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="Statement to verify",
    task_type="FACT_VERIFICATION"
)
```

### CODE_RETRIEVAL_QUERY
Optimized for code search:
```python
result = client.models.embed_content(
    model="text-embedding-004",
    contents="function to sort array",
    task_type="CODE_RETRIEVAL_QUERY"
)
```

## Implementation Examples

### Basic Embedding Generation
```python
import google.generativeai as genai

# Configure API
genai.configure(api_key="your-api-key")

# Generate embedding
result = genai.embed_content(
    model="text-embedding-004",
    content="What is the meaning of life?",
    task_type="SEMANTIC_SIMILARITY"
)

embedding = result['embedding']
print(f"Embedding dimensions: {len(embedding)}")
print(f"First 5 values: {embedding[:5]}")
```

### Batch Embedding Generation
```python
texts = [
    "Machine learning is a subset of artificial intelligence",
    "Deep learning uses neural networks with multiple layers",
    "Python is a popular programming language",
    "Data science involves extracting insights from data"
]

embeddings = []
for text in texts:
    result = genai.embed_content(
        model="text-embedding-004",
        content=text,
        task_type="SEMANTIC_SIMILARITY"
    )
    embeddings.append(result['embedding'])

print(f"Generated {len(embeddings)} embeddings")
```

### Similarity Calculation
```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

def calculate_similarity(text1: str, text2: str) -> float:
    """Calculate cosine similarity between two texts."""
    
    # Generate embeddings
    embedding1 = genai.embed_content(
        model="text-embedding-004",
        content=text1,
        task_type="SEMANTIC_SIMILARITY"
    )['embedding']
    
    embedding2 = genai.embed_content(
        model="text-embedding-004",
        content=text2,
        task_type="SEMANTIC_SIMILARITY"
    )['embedding']
    
    # Calculate cosine similarity
    similarity = cosine_similarity(
        [embedding1], 
        [embedding2]
    )[0][0]
    
    return similarity

# Example usage
similarity = calculate_similarity(
    "I love programming",
    "Coding is my passion"
)
print(f"Similarity: {similarity:.3f}")
```

## Common Use Cases

### Semantic Search
```python
import numpy as np
from typing import List, Tuple

class SemanticSearchEngine:
    def __init__(self):
        self.documents = []
        self.embeddings = []
    
    def add_document(self, text: str):
        """Add document to search index."""
        result = genai.embed_content(
            model="text-embedding-004",
            content=text,
            task_type="RETRIEVAL_DOCUMENT"
        )
        
        self.documents.append(text)
        self.embeddings.append(result['embedding'])
    
    def search(self, query: str, top_k: int = 5) -> List[Tuple[str, float]]:
        """Search for similar documents."""
        # Generate query embedding
        query_result = genai.embed_content(
            model="text-embedding-004",
            content=query,
            task_type="RETRIEVAL_QUERY"
        )
        query_embedding = query_result['embedding']
        
        # Calculate similarities
        similarities = cosine_similarity(
            [query_embedding], 
            self.embeddings
        )[0]
        
        # Get top results
        top_indices = np.argsort(similarities)[::-1][:top_k]
        
        results = []
        for idx in top_indices:
            results.append((self.documents[idx], similarities[idx]))
        
        return results

# Usage
search_engine = SemanticSearchEngine()
search_engine.add_document("Python programming tutorial")
search_engine.add_document("Machine learning with TensorFlow")
search_engine.add_document("Web development with React")

results = search_engine.search("learn coding in Python")
for doc, score in results:
    print(f"Score: {score:.3f} - {doc}")
```

### Text Classification
```python
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
import numpy as np

class TextClassifier:
    def __init__(self):
        self.classifier = LogisticRegression()
        self.is_trained = False
    
    def prepare_embeddings(self, texts: List[str]) -> np.ndarray:
        """Generate embeddings for text classification."""
        embeddings = []
        for text in texts:
            result = genai.embed_content(
                model="text-embedding-004",
                content=text,
                task_type="CLASSIFICATION"
            )
            embeddings.append(result['embedding'])
        return np.array(embeddings)
    
    def train(self, texts: List[str], labels: List[str]):
        """Train the classifier."""
        X = self.prepare_embeddings(texts)
        y = labels
        
        self.classifier.fit(X, y)
        self.is_trained = True
    
    def predict(self, text: str) -> str:
        """Predict label for new text."""
        if not self.is_trained:
            raise ValueError("Model must be trained first")
        
        X = self.prepare_embeddings([text])
        prediction = self.classifier.predict(X)[0]
        return prediction

# Usage
training_texts = [
    "I love this product, it's amazing!",
    "Terrible quality, waste of money",
    "Good value for the price",
    "Worst purchase ever made"
]
training_labels = ["positive", "negative", "positive", "negative"]

classifier = TextClassifier()
classifier.train(training_texts, training_labels)

result = classifier.predict("This is a great item!")
print(f"Sentiment: {result}")
```

### Content Clustering
```python
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt

class ContentClusterer:
    def __init__(self, n_clusters: int = 3):
        self.n_clusters = n_clusters
        self.kmeans = KMeans(n_clusters=n_clusters)
        self.embeddings = None
        self.texts = None
    
    def fit(self, texts: List[str]):
        """Cluster texts by similarity."""
        self.texts = texts
        
        # Generate embeddings
        embeddings = []
        for text in texts:
            result = genai.embed_content(
                model="text-embedding-004",
                content=text,
                task_type="CLUSTERING"
            )
            embeddings.append(result['embedding'])
        
        self.embeddings = np.array(embeddings)
        
        # Perform clustering
        self.kmeans.fit(self.embeddings)
    
    def get_clusters(self) -> dict:
        """Get texts grouped by cluster."""
        clusters = {}
        labels = self.kmeans.labels_
        
        for i, label in enumerate(labels):
            if label not in clusters:
                clusters[label] = []
            clusters[label].append(self.texts[i])
        
        return clusters

# Usage
articles = [
    "Latest AI research breakthrough",
    "Sports team wins championship",
    "Machine learning in healthcare",
    "Football match results",
    "Deep learning applications",
    "Basketball season highlights"
]

clusterer = ContentClusterer(n_clusters=2)
clusterer.fit(articles)

clusters = clusterer.get_clusters()
for cluster_id, texts in clusters.items():
    print(f"Cluster {cluster_id}:")
    for text in texts:
        print(f"  - {text}")
```

## Advanced Applications

### Recommendation System
```python
class RecommendationEngine:
    def __init__(self):
        self.items = []
        self.embeddings = []
        self.user_profiles = {}
    
    def add_item(self, item_id: str, description: str):
        """Add item to recommendation database."""
        result = genai.embed_content(
            model="text-embedding-004",
            content=description,
            task_type="SEMANTIC_SIMILARITY"
        )
        
        self.items.append(item_id)
        self.embeddings.append(result['embedding'])
    
    def update_user_profile(self, user_id: str, liked_items: List[str]):
        """Update user profile based on liked items."""
        # Find embeddings for liked items
        liked_embeddings = []
        for item_id in liked_items:
            if item_id in self.items:
                idx = self.items.index(item_id)
                liked_embeddings.append(self.embeddings[idx])
        
        # Create user profile as average of liked items
        if liked_embeddings:
            user_profile = np.mean(liked_embeddings, axis=0)
            self.user_profiles[user_id] = user_profile
    
    def recommend(self, user_id: str, top_k: int = 5) -> List[str]:
        """Recommend items for user."""
        if user_id not in self.user_profiles:
            return []
        
        user_profile = self.user_profiles[user_id]
        
        # Calculate similarities
        similarities = cosine_similarity(
            [user_profile], 
            self.embeddings
        )[0]
        
        # Get top recommendations
        top_indices = np.argsort(similarities)[::-1][:top_k]
        recommendations = [self.items[idx] for idx in top_indices]
        
        return recommendations
```

### Duplicate Detection
```python
class DuplicateDetector:
    def __init__(self, threshold: float = 0.85):
        self.threshold = threshold
        self.documents = []
        self.embeddings = []
    
    def add_document(self, doc_id: str, content: str) -> bool:
        """Add document and check for duplicates."""
        result = genai.embed_content(
            model="text-embedding-004",
            content=content,
            task_type="SEMANTIC_SIMILARITY"
        )
        new_embedding = result['embedding']
        
        # Check for duplicates
        if self.embeddings:
            similarities = cosine_similarity(
                [new_embedding], 
                self.embeddings
            )[0]
            
            max_similarity = np.max(similarities)
            if max_similarity > self.threshold:
                duplicate_idx = np.argmax(similarities)
                print(f"Duplicate detected! Similar to: {self.documents[duplicate_idx]}")
                return False
        
        # Add if not duplicate
        self.documents.append(doc_id)
        self.embeddings.append(new_embedding)
        return True
```

## Performance Optimization

### Batch Processing
```python
def generate_embeddings_batch(texts: List[str], batch_size: int = 100) -> List[List[float]]:
    """Generate embeddings in batches for efficiency."""
    all_embeddings = []
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        batch_embeddings = []
        
        for text in batch:
            result = genai.embed_content(
                model="text-embedding-004",
                content=text,
                task_type="SEMANTIC_SIMILARITY"
            )
            batch_embeddings.append(result['embedding'])
        
        all_embeddings.extend(batch_embeddings)
        
        # Optional: Add delay between batches
        import time
        time.sleep(0.1)
    
    return all_embeddings
```

### Caching Embeddings
```python
import pickle
import hashlib
from pathlib import Path

class EmbeddingCache:
    def __init__(self, cache_dir: str = "embedding_cache"):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
    
    def get_cache_key(self, text: str, model: str, task_type: str) -> str:
        """Generate cache key for text."""
        content = f"{text}_{model}_{task_type}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def get_embedding(self, text: str, model: str = "text-embedding-004", 
                     task_type: str = "SEMANTIC_SIMILARITY") -> List[float]:
        """Get embedding with caching."""
        cache_key = self.get_cache_key(text, model, task_type)
        cache_file = self.cache_dir / f"{cache_key}.pkl"
        
        # Check cache
        if cache_file.exists():
            with open(cache_file, 'rb') as f:
                return pickle.load(f)
        
        # Generate and cache
        result = genai.embed_content(
            model=model,
            content=text,
            task_type=task_type
        )
        embedding = result['embedding']
        
        with open(cache_file, 'wb') as f:
            pickle.dump(embedding, f)
        
        return embedding

# Usage
cache = EmbeddingCache()
embedding = cache.get_embedding("Machine learning is fascinating")
```

## Integration with Vector Databases

### Pinecone Integration
```python
import pinecone

# Initialize Pinecone
pinecone.init(api_key="your-pinecone-key", environment="your-env")

# Create index
index_name = "gemini-embeddings"
if index_name not in pinecone.list_indexes():
    pinecone.create_index(
        index_name,
        dimension=768,  # Adjust based on embedding model
        metric="cosine"
    )

index = pinecone.Index(index_name)

def store_embeddings(texts: List[str], ids: List[str]):
    """Store embeddings in Pinecone."""
    vectors = []
    
    for i, text in enumerate(texts):
        result = genai.embed_content(
            model="text-embedding-004",
            content=text,
            task_type="RETRIEVAL_DOCUMENT"
        )
        
        vectors.append({
            "id": ids[i],
            "values": result['embedding'],
            "metadata": {"text": text}
        })
    
    index.upsert(vectors)

def search_similar(query: str, top_k: int = 5):
    """Search for similar documents."""
    result = genai.embed_content(
        model="text-embedding-004",
        content=query,
        task_type="RETRIEVAL_QUERY"
    )
    
    search_results = index.query(
        vector=result['embedding'],
        top_k=top_k,
        include_metadata=True
    )
    
    return search_results
```

## Cost Management

### Token Usage Tracking
```python
class EmbeddingTracker:
    def __init__(self):
        self.total_requests = 0
        self.total_characters = 0
    
    def track_embedding(self, text: str) -> List[float]:
        """Generate embedding with usage tracking."""
        result = genai.embed_content(
            model="text-embedding-004",
            content=text,
            task_type="SEMANTIC_SIMILARITY"
        )
        
        # Track usage
        self.total_requests += 1
        self.total_characters += len(text)
        
        return result['embedding']
    
    def get_usage_stats(self) -> dict:
        """Get usage statistics."""
        return {
            "total_requests": self.total_requests,
            "total_characters": self.total_characters,
            "avg_chars_per_request": self.total_characters / max(1, self.total_requests)
        }
```

## Best Practices

### Text Preprocessing
1. **Clean text**: Remove unnecessary formatting and noise
2. **Consistent encoding**: Use UTF-8 encoding
3. **Appropriate length**: Optimize text length for embedding quality
4. **Language handling**: Be consistent with language processing
5. **Normalization**: Consider text normalization for consistency

### Model Selection
1. **Task-specific models**: Use appropriate model for your task
2. **Performance testing**: Compare models for your specific use case
3. **Version updates**: Stay current with model updates
4. **Fallback options**: Have backup models available
5. **Cost considerations**: Balance performance with cost

### Quality Assurance
1. **Similarity validation**: Test similarity calculations with known examples
2. **Edge case handling**: Test with edge cases and unusual text
3. **Performance monitoring**: Track embedding quality over time
4. **User feedback**: Collect feedback on search/recommendation quality
5. **Regular evaluation**: Periodically evaluate system performance

## Limitations and Considerations

### Technical Limitations
- **Context length**: Limited input text length
- **Language support**: Varying quality across languages
- **Domain specificity**: May need fine-tuning for specialized domains
- **Update frequency**: Model updates may affect consistency

### Implementation Considerations
1. **Rate limits**: Respect API rate limits
2. **Caching strategy**: Implement appropriate caching
3. **Error handling**: Handle API failures gracefully
4. **Monitoring**: Track usage and performance
5. **Security**: Protect sensitive data in embeddings

---

**Last Updated:** Based on Google Gemini API documentation as of 2025
**Reference:** https://ai.google.dev/gemini-api/docs/embeddings
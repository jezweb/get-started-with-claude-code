# Vertex AI Search Integration Guide

Comprehensive guide for implementing enterprise search capabilities using Google Vertex AI Search (formerly Enterprise Search), featuring generative AI-powered search, summarization, and conversational experiences.

## 🎯 Overview

Vertex AI Search is a fully-managed platform that provides:
- **Semantic Search** - Natural language understanding out-of-the-box
- **Generative Summarization** - AI-powered answer generation
- **Conversational Search** - Multi-turn dialogue capabilities
- **Self-Learning** - Automatic improvement from user interactions
- **Enterprise Scale** - Handle millions of documents and queries

## 🚀 Quick Start

### 1. Enable APIs and Create Search App

```bash
# Enable required APIs
gcloud services enable discoveryengine.googleapis.com
gcloud services enable storage.googleapis.com

# Set project and location
export PROJECT_ID="your-project-id"
export LOCATION="global"  # or specific region
```

### 2. Create Search Application

```python
from google.cloud import discoveryengine_v1 as discoveryengine

# Initialize client
client = discoveryengine.EngineServiceClient()

# Create search engine
project = f"projects/{PROJECT_ID}/locations/{LOCATION}"
engine = discoveryengine.Engine(
    display_name="my-search-engine",
    solution_type=discoveryengine.SolutionType.SOLUTION_TYPE_SEARCH,
    search_engine_config=discoveryengine.Engine.SearchEngineConfig(
        search_tier=discoveryengine.SearchTier.SEARCH_TIER_ENTERPRISE,
        search_add_ons=[
            discoveryengine.SearchAddOn.SEARCH_ADD_ON_LLM,
        ]
    )
)

# Create the engine
operation = client.create_engine(
    parent=project,
    engine=engine,
    engine_id="my-search-engine-id"
)
```

## 📊 Search Types

### 1. Custom Search
For general document search across websites, databases, and custom data:

```python
# Create data store for custom search
data_store = discoveryengine.DataStore(
    display_name="my-data-store",
    content_config=discoveryengine.DataStore.ContentConfig.CONTENT_REQUIRED,
    solution_types=[discoveryengine.SolutionType.SOLUTION_TYPE_SEARCH]
)

# Import documents from Cloud Storage
import_config = discoveryengine.ImportDocumentsRequest(
    parent=f"{project}/dataStores/{data_store_id}",
    gcs_source=discoveryengine.GcsSource(
        input_uris=["gs://my-bucket/documents/*"]
    ),
    reconciliation_mode=discoveryengine.ImportDocumentsRequest.ReconciliationMode.INCREMENTAL
)
```

### 2. Media Search
Optimized for media content with metadata extraction:

```python
# Configure for media search
media_config = discoveryengine.Engine.MediaRecommendationEngineConfig(
    type_=discoveryengine.Engine.MediaRecommendationEngineConfig.Type.MEDIA_RECOMMENDATION_ENGINE_TYPE_SEARCH,
    optimization_objective="maximize-relevance"
)
```

### 3. Healthcare Search
HIPAA-compliant search for medical data:

```python
# Healthcare-specific configuration
healthcare_config = {
    "fhir_store_source": {
        "fhir_store": f"projects/{PROJECT_ID}/locations/{LOCATION}/datasets/{dataset_id}/fhirStores/{fhir_store_id}"
    }
}
```

## 🔍 Search Implementation

### Basic Search Query

```python
from google.cloud import discoveryengine_v1 as discoveryengine

# Initialize search client
search_client = discoveryengine.SearchServiceClient()

# Prepare search request
request = discoveryengine.SearchRequest(
    serving_config=f"{project}/dataStores/{data_store_id}/servingConfigs/default_config",
    query="machine learning best practices",
    page_size=10,
    query_expansion_spec=discoveryengine.SearchRequest.QueryExpansionSpec(
        condition=discoveryengine.SearchRequest.QueryExpansionSpec.Condition.AUTO
    ),
    spell_correction_spec=discoveryengine.SearchRequest.SpellCorrectionSpec(
        mode=discoveryengine.SearchRequest.SpellCorrectionSpec.Mode.AUTO
    )
)

# Execute search
response = search_client.search(request)

# Process results
for result in response.results:
    document = result.document
    print(f"Title: {document.struct_data.get('title')}")
    print(f"Snippet: {result.snippet}")
    print(f"Relevance Score: {result.relevance_score}")
```

### Advanced Search with Summarization

```python
# Enable summarization
request.content_search_spec = discoveryengine.SearchRequest.ContentSearchSpec(
    summary_spec=discoveryengine.SearchRequest.ContentSearchSpec.SummarySpec(
        summary_result_count=5,
        include_citations=True,
        language_code="en",
        model_spec=discoveryengine.SearchRequest.ContentSearchSpec.SummarySpec.ModelSpec(
            version="stable"
        )
    )
)

# Execute search with summary
response = search_client.search(request)

# Get AI-generated summary
if response.summary:
    print(f"Summary: {response.summary.summary_text}")
    for citation in response.summary.citations:
        print(f"Source: {citation.source}")
```

### Conversational Search

```python
# Create conversation
conversation_client = discoveryengine.ConversationalSearchServiceClient()

# Start conversation
conversation = conversation_client.create_conversation(
    parent=f"{project}/dataStores/{data_store_id}",
    conversation=discoveryengine.Conversation()
)

# Multi-turn conversation
messages = [
    "What are the latest AI trends?",
    "Tell me more about transformers",
    "How do they compare to RNNs?"
]

for message in messages:
    request = discoveryengine.ConverseConversationRequest(
        name=conversation.name,
        query=discoveryengine.TextInput(text=message),
        serving_config=f"{conversation.name}/servingConfigs/default_config"
    )
    
    response = conversation_client.converse_conversation(request)
    print(f"Q: {message}")
    print(f"A: {response.reply.text}")
```

## 🎨 Search UI Integration

### Embedded Widget

```html
<!-- Add Vertex AI Search widget to your website -->
<div id="vertex-search-widget"></div>

<script>
  // Configure search widget
  const searchConfig = {
    projectId: 'your-project-id',
    location: 'global',
    dataStoreId: 'your-datastore-id',
    widgetConfig: {
      enableSummary: true,
      enableConversation: true,
      enableFilters: true,
      resultsPerPage: 10
    }
  };
  
  // Initialize widget
  google.cloud.vertexai.search.createWidget(
    document.getElementById('vertex-search-widget'),
    searchConfig
  );
</script>
```

### Custom UI with API

```javascript
// Frontend search implementation
async function searchVertexAI(query) {
  const response = await fetch('/api/search', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query: query,
      filters: {
        category: 'documentation',
        language: 'en'
      },
      pageSize: 20
    })
  });
  
  const results = await response.json();
  return results;
}

// Display results with highlighting
function displayResults(results) {
  const container = document.getElementById('search-results');
  container.innerHTML = '';
  
  results.forEach(result => {
    const div = document.createElement('div');
    div.className = 'search-result';
    div.innerHTML = `
      <h3>${result.title}</h3>
      <p class="snippet">${result.snippet}</p>
      <a href="${result.link}">View More</a>
      <div class="metadata">
        Score: ${result.relevanceScore} | 
        Updated: ${result.lastModified}
      </div>
    `;
    container.appendChild(div);
  });
}
```

## 🔧 Configuration & Tuning

### Search Tuning

```python
# Upload tuning data
tuning_data = [
    {
        "query": "machine learning",
        "positive_docs": ["doc1", "doc2"],
        "negative_docs": ["doc3"]
    },
    {
        "query": "neural networks",
        "positive_docs": ["doc4", "doc5"],
        "negative_docs": ["doc6"]
    }
]

# Create tuning operation
tune_request = discoveryengine.TuneEngineRequest(
    name=f"{project}/engines/{engine_id}",
    training_data=tuning_data
)
```

### Boost and Bury Controls

```python
# Configure boost/bury rules
boost_spec = discoveryengine.SearchRequest.BoostSpec(
    condition_boost_specs=[
        discoveryengine.SearchRequest.BoostSpec.ConditionBoostSpec(
            condition="category: tutorial",
            boost=2.0
        ),
        discoveryengine.SearchRequest.BoostSpec.ConditionBoostSpec(
            condition="outdated: true",
            boost=-0.5  # Bury outdated content
        )
    ]
)
```

## 📈 Analytics & Monitoring

### Search Analytics

```python
# Get search analytics
analytics_client = discoveryengine.AnalyticsServiceClient()

# Query metrics
metrics_request = discoveryengine.QueryMetricsRequest(
    parent=f"{project}/dataStores/{data_store_id}",
    start_time=start_timestamp,
    end_time=end_timestamp,
    metrics=["search_count", "click_through_rate", "average_position"]
)

metrics = analytics_client.query_metrics(metrics_request)
```

### User Events Tracking

```python
# Track user interactions
event_client = discoveryengine.UserEventServiceClient()

# Search event
search_event = discoveryengine.UserEvent(
    event_type="search",
    user_pseudo_id="user123",
    event_time=timestamp,
    search_info=discoveryengine.SearchInfo(
        search_query="machine learning",
        order_by="relevance"
    )
)

# Click event
click_event = discoveryengine.UserEvent(
    event_type="click",
    user_pseudo_id="user123",
    document_info=discoveryengine.DocumentInfo(
        id="doc123",
        name=f"{project}/dataStores/{data_store_id}/branches/default/documents/doc123"
    )
)

# Write events
event_client.write_user_event(parent=f"{project}/dataStores/{data_store_id}", user_event=search_event)
```

## 🔒 Security & Access Control

### IAM Configuration

```bash
# Grant search access
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="user:searcher@example.com" \
    --role="roles/discoveryengine.viewer"

# Admin access
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="user:admin@example.com" \
    --role="roles/discoveryengine.admin"
```

### VPC Service Controls

```python
# Configure VPC-SC
vpc_config = {
    "network": f"projects/{PROJECT_ID}/global/networks/my-vpc",
    "ip_allocation": "10.0.0.0/24"
}
```

## 💰 Pricing Considerations

### Cost Optimization Tips

1. **Search Tiers**:
   - Standard: Basic search features
   - Enterprise: Advanced AI features (recommended)

2. **Request Optimization**:
   ```python
   # Batch multiple searches
   batch_request = discoveryengine.BatchSearchRequest(
       requests=[search_req1, search_req2, search_req3]
   )
   ```

3. **Caching Strategy**:
   ```python
   # Implement client-side caching
   from functools import lru_cache
   
   @lru_cache(maxsize=1000)
   def cached_search(query, filters):
       return search_client.search(build_request(query, filters))
   ```

## 🎯 Best Practices

1. **Data Preparation**:
   - Structure documents with clear metadata
   - Use consistent naming conventions
   - Include relevant timestamps

2. **Query Optimization**:
   - Use query expansion for better recall
   - Apply appropriate filters early
   - Leverage faceted search

3. **Performance**:
   - Implement pagination for large result sets
   - Use asynchronous requests where possible
   - Monitor and optimize slow queries

4. **User Experience**:
   - Provide query suggestions
   - Show result previews
   - Implement "did you mean?" functionality

## 📚 Additional Resources

- [Vertex AI Search Documentation](https://cloud.google.com/vertex-ai-search/docs)
- [API Reference](https://cloud.google.com/vertex-ai-search/docs/reference)
- [Pricing Calculator](https://cloud.google.com/products/calculator)
- [Search Quality Guidelines](https://cloud.google.com/vertex-ai-search/docs/quality)

---

*Note: Vertex AI Search offers a $1,000 credit for first-time users, valid for 12 months. Check the latest pricing and features in the official documentation.*
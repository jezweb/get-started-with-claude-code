# Vertex AI Models & Pricing Guide

Comprehensive guide to available models, pricing, and migration strategies for Google Vertex AI, featuring the latest Gemini models and Model Garden offerings.

## 🎯 Overview

Vertex AI provides access to:
- **Gemini Models** - Google's flagship multi-modal AI models
- **Model Garden** - 200+ third-party models (Claude, Llama, Mistral, etc.)
- **PaLM Models** - Legacy models (being deprecated)
- **Specialized Models** - Task-specific models for vision, language, etc.

## 🚀 Gemini Models (Latest)

### Gemini 2.5 Series (Released June 2025)

#### Gemini 2.5 Pro
```python
# Most powerful thinking model
model = GenerativeModel("gemini-2.5-pro")

# Configuration
config = {
    "temperature": 0.7,
    "top_p": 0.95,
    "top_k": 40,
    "max_output_tokens": 65536,
    "response_mime_type": "text/plain",
}

# Features
- Context window: 2,000,000 tokens
- Output tokens: Up to 65,536
- Thinking capabilities for complex reasoning
- Knowledge cutoff: January 2025
- Best for: Complex analysis, code generation, creative tasks
```

#### Gemini 2.5 Flash
```python
# Best price-performance ratio
model = GenerativeModel("gemini-2.5-flash")

# Features
- Context window: 2,000,000 tokens
- Output tokens: Up to 65,536
- Adaptive thinking capabilities
- 2x faster than 2.5 Pro
- Best for: General purpose, high-volume applications
```

#### Gemini 2.5 Flash-Lite
```python
# Most cost-efficient
model = GenerativeModel("gemini-2.5-flash-lite-preview-06-17")

# Features
- Context window: 1,000,000 tokens
- Output tokens: Up to 64,000
- Optimized for speed and cost
- Best for: Simple tasks, high-volume processing
```

### Gemini 2.0 Series

#### Gemini 2.0 Flash
```python
# Next-generation features
model = GenerativeModel("gemini-2.0-flash")

# Features
- Context window: 1,048,576 tokens
- Output tokens: Up to 8,192
- Native tool use
- Multimodal generation
- Best for: Agentic applications, tool integration
```

### Specialized Gemini Models

#### Text-to-Speech Models
```python
# TTS with Gemini 2.5 Flash
tts_model = GenerativeModel("gemini-2.5-flash-preview-tts")

# TTS with Gemini 2.5 Pro
tts_pro_model = GenerativeModel("gemini-2.5-pro-preview-tts")

# Usage
response = tts_model.generate_content(
    "Convert this text to speech: Hello, world!",
    generation_config={"response_modalities": ["AUDIO"]}
)
```

#### Native Audio Dialog
```python
# For conversational audio
audio_model = GenerativeModel("gemini-2.5-flash-preview-native-audio-dialog")

# Features
- Real-time audio processing
- Natural conversation flow
- 30+ HD voices in 24 languages
```

#### Live API Model
```python
# For real-time streaming
live_model = GenerativeModel("gemini-live-2.5-flash-preview")

# Features
- Bidirectional audio/video streaming
- Ultra-low latency
- Real-time interactions
```

#### Image Generation
```python
# Generate images
imagen_model = GenerativeModel("gemini-2.0-flash-preview-image-generation")

response = imagen_model.generate_content(
    "Create an image of a futuristic city at sunset",
    generation_config={"response_modalities": ["IMAGE"]}
)
```

## 💰 Pricing Structure

### Gemini Models Pricing (as of January 2025)

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context Window |
|-------|----------------------|------------------------|----------------|
| **Gemini 2.5 Pro** | $7.00 | $21.00 | 2M tokens |
| **Gemini 2.5 Flash** | $0.35 | $1.05 | 2M tokens |
| **Gemini 2.5 Flash-Lite** | $0.10 | $0.30 | 1M tokens |
| **Gemini 2.0 Flash** | $0.50 | $1.50 | 1M tokens |

### Specialized Models Pricing

| Model | Pricing |
|-------|---------|
| **TTS Models** | $0.000025 per character |
| **Native Audio** | $0.50 per minute |
| **Live API** | $1.00 per minute |
| **Image Generation** | $0.02 per image |

### Volume Discounts

```python
# Calculate pricing with volume discounts
def calculate_cost(input_tokens, output_tokens, model="gemini-2.5-flash"):
    base_prices = {
        "gemini-2.5-pro": {"input": 7.00, "output": 21.00},
        "gemini-2.5-flash": {"input": 0.35, "output": 1.05},
        "gemini-2.5-flash-lite": {"input": 0.10, "output": 0.30}
    }
    
    price = base_prices[model]
    
    # Volume discounts (example)
    if input_tokens > 100_000_000:  # 100M tokens
        price["input"] *= 0.8  # 20% discount
        price["output"] *= 0.8
    
    input_cost = (input_tokens / 1_000_000) * price["input"]
    output_cost = (output_tokens / 1_000_000) * price["output"]
    
    return {
        "input_cost": input_cost,
        "output_cost": output_cost,
        "total_cost": input_cost + output_cost
    }
```

## 🌐 Model Garden

### Available Third-Party Models

#### Anthropic Claude
```python
# Claude 3.7 Sonnet via Vertex AI
from anthropic import AnthropicVertex

client = AnthropicVertex(region=LOCATION, project_id=PROJECT_ID)

message = client.messages.create(
    model="claude-3-7-sonnet",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Hello, Claude!"}
    ]
)
```

#### Meta Llama
```python
# Llama 4 70B
llama_endpoint = aiplatform.Endpoint(
    endpoint_name="llama-4-70b-endpoint"
)

response = llama_endpoint.predict(
    instances=[{"prompt": "Explain machine learning"}]
)
```

#### Mistral Models
```python
# Mixtral 8x22B
mixtral_model = aiplatform.Model(
    model_name="mixtral-8x22b"
)

# Deploy and use
endpoint = mixtral_model.deploy(
    machine_type="n1-standard-8",
    accelerator_type="NVIDIA_TESLA_V100",
    accelerator_count=2
)
```

### Model Garden Catalog

| Provider | Models | Use Cases |
|----------|--------|-----------|
| **Anthropic** | Claude 3.7 (Opus, Sonnet, Haiku) | Complex reasoning, coding |
| **Meta** | Llama 4 (8B, 70B, 405B) | Open-source, fine-tunable |
| **Mistral** | Mixtral 8x7B, 8x22B | Efficient mixture-of-experts |
| **Cohere** | Command R, Command R+ | Enterprise search, RAG |
| **AI21** | Jamba 1.5 Large/Mini | Hybrid architecture |

## 🔄 Migration Guide

### From Gemini 1.5 to 2.5

```python
# Old code (Gemini 1.5)
old_model = GenerativeModel("gemini-1.5-pro-001")

# New code (Gemini 2.5)
new_model = GenerativeModel("gemini-2.5-pro")

# Migration considerations:
# 1. Update model name
# 2. Adjust for new token limits
# 3. Update temperature ranges (now 0-2)
# 4. Test thinking mode behavior
```

### Migration Timeline

```python
import datetime

# Key dates
DEPRECATION_DATES = {
    "gemini-1.5-models": datetime.date(2025, 4, 29),
    "preview-endpoints": datetime.date(2025, 7, 15),
    "palm-models": datetime.date(2025, 3, 31)
}

def check_migration_status(model_name: str):
    """Check if model needs migration"""
    today = datetime.date.today()
    
    if "1.5" in model_name and today > DEPRECATION_DATES["gemini-1.5-models"]:
        return "URGENT: Model deprecated. Migrate to Gemini 2.5 immediately."
    
    if "preview" in model_name and today > DEPRECATION_DATES["preview-endpoints"]:
        return "WARNING: Preview endpoint deprecated. Use GA endpoint."
    
    return "Model is current."
```

## 🎯 Model Selection Guide

### Decision Matrix

```python
def select_model(requirements: dict) -> str:
    """Select optimal model based on requirements"""
    
    # Requirements: {
    #   "complexity": "high|medium|low",
    #   "latency": "real-time|low|normal",
    #   "cost_sensitive": bool,
    #   "context_size": int,
    #   "multimodal": bool
    # }
    
    if requirements["complexity"] == "high":
        if requirements["context_size"] > 1_000_000:
            return "gemini-2.5-pro"  # 2M context
        return "gemini-2.5-pro"
    
    elif requirements["latency"] == "real-time":
        if requirements["multimodal"]:
            return "gemini-live-2.5-flash-preview"
        return "gemini-2.0-flash"
    
    elif requirements["cost_sensitive"]:
        return "gemini-2.5-flash-lite"
    
    else:  # Default balanced choice
        return "gemini-2.5-flash"
```

### Use Case Recommendations

| Use Case | Recommended Model | Why |
|----------|------------------|-----|
| **Chatbots** | Gemini 2.5 Flash | Balance of cost and capability |
| **Code Generation** | Gemini 2.5 Pro | Superior reasoning |
| **Document Analysis** | Gemini 2.5 Pro | 2M token context |
| **Real-time Voice** | Live API Model | Native audio support |
| **High-volume API** | Gemini 2.5 Flash-Lite | Cost efficiency |
| **Research/Analysis** | Claude 3.7 Opus | Deep reasoning |
| **Open-source needs** | Llama 4 70B | Customizable |

## 📊 Performance Benchmarks

### Latency Comparison

```python
# Benchmark different models
import time
import asyncio

async def benchmark_models():
    models = [
        "gemini-2.5-pro",
        "gemini-2.5-flash", 
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash"
    ]
    
    prompt = "Explain quantum computing in 100 words"
    results = {}
    
    for model_name in models:
        model = GenerativeModel(model_name)
        
        start = time.time()
        response = await model.generate_content_async(prompt)
        latency = time.time() - start
        
        results[model_name] = {
            "latency_ms": latency * 1000,
            "tokens": response.usage_metadata.total_token_count,
            "tokens_per_second": response.usage_metadata.total_token_count / latency
        }
    
    return results
```

### Quality Metrics

| Model | MMLU Score | HumanEval | Context Accuracy |
|-------|------------|-----------|------------------|
| Gemini 2.5 Pro | 94.2% | 89.5% | 99.2% |
| Gemini 2.5 Flash | 91.8% | 85.3% | 98.7% |
| Gemini 2.0 Flash | 89.6% | 82.1% | 97.9% |
| Claude 3.7 Sonnet | 93.5% | 88.2% | 98.9% |

## 🔧 Optimization Strategies

### Token Optimization

```python
class TokenOptimizer:
    def __init__(self, model_name: str):
        self.model = GenerativeModel(model_name)
        self.tokenizer = self.model.start_chat().count_tokens
        
    def optimize_prompt(self, prompt: str, max_tokens: int = 1000):
        """Optimize prompt to fit token limits"""
        token_count = self.tokenizer(prompt).total_tokens
        
        if token_count <= max_tokens:
            return prompt
        
        # Truncate or summarize
        # Implementation depends on use case
        return self._truncate_intelligently(prompt, max_tokens)
    
    def batch_for_efficiency(self, prompts: List[str], batch_size: int = 10):
        """Batch prompts for cost efficiency"""
        batches = []
        current_batch = []
        current_tokens = 0
        
        for prompt in prompts:
            tokens = self.tokenizer(prompt).total_tokens
            if current_tokens + tokens > 10000 or len(current_batch) >= batch_size:
                batches.append(current_batch)
                current_batch = [prompt]
                current_tokens = tokens
            else:
                current_batch.append(prompt)
                current_tokens += tokens
        
        if current_batch:
            batches.append(current_batch)
            
        return batches
```

### Caching Strategy

```python
from functools import lru_cache
import hashlib

class ModelCache:
    def __init__(self, model_name: str):
        self.model = GenerativeModel(model_name)
        self.cache = {}
        
    def _hash_request(self, prompt: str, config: dict) -> str:
        """Create hash for caching"""
        cache_key = f"{prompt}_{json.dumps(config, sort_keys=True)}"
        return hashlib.md5(cache_key.encode()).hexdigest()
    
    @lru_cache(maxsize=1000)
    def cached_generate(self, prompt: str, **kwargs):
        """Generate with caching"""
        cache_key = self._hash_request(prompt, kwargs)
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        response = self.model.generate_content(prompt, **kwargs)
        self.cache[cache_key] = response
        
        return response
```

## 🚨 Important Notes

### Billing Changes
- **Vertex AI Agent Engine**: Billing starts March 4, 2025
- **New pricing model**: Based on vCPU hours and GiB hours
- **Preview models**: May have different pricing

### Regional Availability
```python
# Check model availability by region
REGIONAL_MODELS = {
    "us-central1": ["all-models"],
    "europe-west4": ["gemini-2.5-flash", "gemini-2.5-pro"],
    "asia-northeast1": ["gemini-2.5-flash"],
    # Add more regions as needed
}

def is_model_available(model: str, region: str) -> bool:
    """Check if model is available in region"""
    if region not in REGIONAL_MODELS:
        return False
    
    available = REGIONAL_MODELS[region]
    return "all-models" in available or model in available
```

## 📚 Resources

- [Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing)
- [Model Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Model Garden Catalog](https://cloud.google.com/vertex-ai/docs/model-garden/explore-models)
- [Migration Guide](https://cloud.google.com/vertex-ai/docs/generative-ai/migrate)
- [Quotas & Limits](https://cloud.google.com/vertex-ai/docs/quotas)

---

*Always check the official documentation for the most current pricing and availability. Models and pricing are subject to change.*
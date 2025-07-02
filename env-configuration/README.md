# Environment Variable Configuration Resource

> **🎯 Use Case**: Setting up environment variables for AI-powered applications  
> **🤖 AI Models**: Optimized for Google Gemini 2.5 series (Pro, Flash, Flash-Lite)  
> **📊 Level**: Beginner to Advanced  
> **🔧 Languages**: Python/FastAPI focus, adaptable to any framework

## 📁 What's in This Folder

| File | Purpose | Best For |
|------|---------|----------|
| **`.env.simple`** | Basic AI app template | Quick prototypes, single model setup |
| **`.env.complete`** | Advanced multi-model config | Production apps, multiple use cases |
| **`.env.example`** | Safe template with dummy values | Sharing configuration structure |
| **`validate_env.py`** | Configuration validator | Checking setup before deployment |
| **`config_example.py`** | FastAPI/Pydantic integration | Type-safe configuration loading |
| **`setup.sh`** | Quick setup script | First-time configuration |

## 🚀 Quick Usage

### For AI Tools
Point your AI assistant to this folder:
```
Using the environment configuration templates in env-configuration/, help me set up environment variables for a Gemini-powered chatbot with fallback models.
```

### Grab What You Need
```bash
# Just the simple template
curl -O https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/env-configuration/.env.simple

# Or the complete setup
curl -O https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/env-configuration/.env.complete
```

### Local Setup
1. Copy the template you need: `.env.simple` or `.env.complete`
2. Rename to `.env` and fill in your API keys
3. Run `python validate_env.py` to verify setup

## 📋 Table of Contents

- [Security Best Practices](#security-best-practices)
- [Naming Conventions](#naming-conventions)
- [Google Gemini Models Guide](#google-gemini-models-guide)
- [Use Case Configurations](#use-case-configurations)
- [Multi-Model Patterns](#multi-model-patterns)
- [FastAPI Integration](#fastapi-integration)
- [Environment Management](#environment-management)
- [Troubleshooting](#troubleshooting)

## 🔒 Security Best Practices

### Critical Rules

1. **Never commit `.env` files to version control**
   ```bash
   # Add to .gitignore immediately
   echo ".env" >> .gitignore
   echo ".env.*" >> .gitignore
   echo "!.env.example" >> .gitignore
   ```

2. **Use different API keys for different environments**
   - Development: Use restricted keys with lower quotas
   - Staging: Use keys with moderate limits
   - Production: Use production keys with appropriate quotas

3. **Rotate API keys regularly**
   - Set calendar reminders for 90-day rotation
   - Keep a secure record of key rotation dates

4. **For production deployments**
   - Use secret management services (Google Secret Manager, AWS Secrets Manager)
   - Never store production keys in `.env` files
   - Use environment variables injected by your deployment platform

### Security Checklist

- [ ] `.env` added to `.gitignore`
- [ ] `.env.example` created with dummy values
- [ ] Different API keys for dev/staging/prod
- [ ] No hardcoded secrets in code
- [ ] Regular key rotation schedule established
- [ ] Production uses secret management service

## 📝 Naming Conventions

### Standard Prefixes by Category

| Prefix | Category | Example |
|--------|----------|---------|
| `APP_` | Application settings | `APP_NAME`, `APP_PORT` |
| `AI_` | General AI settings | `AI_DEFAULT_PROVIDER` |
| `GEMINI_` | Google Gemini specific | `GEMINI_API_KEY` |
| `CLAUDE_` | Anthropic Claude specific | `CLAUDE_API_KEY` |
| `DB_` | Database configuration | `DB_CONNECTION_STRING` |
| `AUTH_` | Authentication settings | `AUTH_SECRET_KEY` |
| `LOG_` | Logging configuration | `LOG_LEVEL` |

### Use Case Prefixes

| Prefix | Use Case | Example |
|--------|----------|---------|
| `CHAT_` | Conversational AI | `CHAT_MODEL`, `CHAT_TEMPERATURE` |
| `DOC_` | Document generation | `DOC_MODEL`, `DOC_MAX_TOKENS` |
| `ANALYSIS_` | Document analysis | `ANALYSIS_MODEL` |
| `TTS_` | Text-to-speech | `TTS_MODEL`, `TTS_VOICE` |
| `EMBED_` | Embeddings | `EMBED_MODEL`, `EMBED_DIMENSION` |

## 🤖 Google Gemini Models Guide

### Available Models (July 2025)

| Model | Best For | Key Features |
|-------|----------|--------------|
| **Gemini 2.5 Pro** | Complex reasoning, analysis | • Most powerful<br>• 1M token context<br>• Multimodal (text, image, video, audio, PDF)<br>• Advanced thinking mode |
| **Gemini 2.5 Flash** | General purpose, balanced | • Best price-performance<br>• 1M token context<br>• Fast response times<br>• Multimodal support |
| **Gemini 2.5 Flash-Lite** | High-volume, real-time | • Most cost-effective<br>• Lowest latency<br>• Good for simple tasks<br>• Multimodal support |

### Temperature Guidelines by Use Case

| Use Case | Temperature | Reasoning |
|----------|-------------|-----------|
| Code generation | 0.0 - 0.2 | Maximum precision |
| Factual Q&A | 0.1 - 0.3 | Accuracy focused |
| Document analysis | 0.2 - 0.4 | Balanced accuracy |
| General chat | 0.5 - 0.7 | Natural conversation |
| Creative writing | 0.7 - 1.0 | Maximum creativity |
| Brainstorming | 0.8 - 1.2 | Diverse ideas |

### Token Limits by Use Case

| Use Case | Recommended Tokens | Notes |
|----------|-------------------|-------|
| Quick chat responses | 500 - 1,000 | Keep it concise |
| Detailed explanations | 1,000 - 2,000 | Thorough answers |
| Document generation | 2,000 - 8,000 | Long-form content |
| Code generation | 1,500 - 4,000 | Complete implementations |
| Summaries | 200 - 500 | Brief overviews |

## 🎯 Use Case Configurations

### Chat/Conversation

Optimized for interactive dialogue, customer support, and Q&A:

```env
# Gemini 2.5 Flash - balanced for conversations
CHAT_MODEL=gemini-2.5-flash
CHAT_TEMPERATURE=0.7
CHAT_MAX_TOKENS=1000
CHAT_TOP_P=0.9
CHAT_THINKING_MODE=false  # Quick responses
```

### Document Generation

For creating articles, reports, and long-form content:

```env
# Gemini 2.5 Pro - complex reasoning for quality content
DOC_MODEL=gemini-2.5-pro
DOC_TEMPERATURE=0.5
DOC_MAX_TOKENS=4000
DOC_TOP_P=0.95
DOC_THINKING_MODE=true  # Better structure
```

### Document Analysis

For processing PDFs, extracting information, and understanding documents:

```env
# Gemini 2.5 Pro - multimodal capabilities
ANALYSIS_MODEL=gemini-2.5-pro
ANALYSIS_TEMPERATURE=0.2
ANALYSIS_MAX_TOKENS=2000
ANALYSIS_ENABLE_PDF=true
ANALYSIS_ENABLE_VISION=true
```

### Real-time Applications

For chatbots, live translations, and instant responses:

```env
# Gemini 2.5 Flash-Lite - lowest latency
REALTIME_MODEL=gemini-2.5-flash-lite
REALTIME_TEMPERATURE=0.5
REALTIME_MAX_TOKENS=500
REALTIME_TIMEOUT_MS=5000
```

## 🔄 Multi-Model Patterns

### Fallback Strategy

Configure primary and fallback models for reliability:

```env
# Primary model (Gemini)
PRIMARY_PROVIDER=gemini
PRIMARY_MODEL=gemini-2.5-flash

# Fallback models
FALLBACK_PROVIDERS=claude,openai
FALLBACK_MODEL_CLAUDE=claude-3-5-sonnet-20240620
FALLBACK_MODEL_OPENAI=gpt-4-turbo

# Retry configuration
MAX_RETRIES=3
RETRY_DELAY_MS=1000
FALLBACK_ON_RATE_LIMIT=true
FALLBACK_ON_ERROR=true
```

### Cost Optimization

Balance performance and cost:

```env
# Cost tiers
USE_PREMIUM_MODELS=false
COST_LIMIT_PER_REQUEST=0.10
COST_LIMIT_DAILY=100.00

# Model selection by cost
ECONOMY_MODEL=gemini-2.5-flash-lite
STANDARD_MODEL=gemini-2.5-flash
PREMIUM_MODEL=gemini-2.5-pro

# Automatic downgrade
ENABLE_MODEL_DOWNGRADE=true
DOWNGRADE_THRESHOLD_TOKENS=10000
```

## 🐍 FastAPI Integration

### Using Pydantic Settings

```python
# config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional, List
from functools import lru_cache

class Settings(BaseSettings):
    # Application
    app_name: str = "AI Application"
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_debug: bool = False
    
    # Google Gemini Configuration
    gemini_api_key: str
    gemini_default_model: str = "gemini-2.5-flash"
    gemini_default_temperature: float = 0.7
    gemini_default_max_tokens: int = 1000
    gemini_thinking_mode: bool = True
    
    # Use Case Specific - Chat
    chat_model: str = "gemini-2.5-flash"
    chat_temperature: float = 0.7
    chat_max_tokens: int = 1000
    
    # Use Case Specific - Document
    doc_model: str = "gemini-2.5-pro"
    doc_temperature: float = 0.5
    doc_max_tokens: int = 4000
    
    # Database
    database_url: str = "sqlite:///./app.db"
    
    # Security
    secret_key: str
    cors_origins: List[str] = ["http://localhost:3000"]
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )

@lru_cache()
def get_settings() -> Settings:
    return Settings()
```

### Usage in FastAPI

```python
# main.py
from fastapi import FastAPI, Depends
from config import get_settings, Settings
import google.generativeai as genai

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    settings = get_settings()
    genai.configure(api_key=settings.gemini_api_key)

@app.post("/chat")
async def chat(
    message: str,
    settings: Settings = Depends(get_settings)
):
    model = genai.GenerativeModel(
        model_name=settings.chat_model,
        generation_config={
            "temperature": settings.chat_temperature,
            "max_output_tokens": settings.chat_max_tokens,
        }
    )
    response = model.generate_content(message)
    return {"response": response.text}
```

## 🌍 Environment Management

### Environment-Specific Files

```bash
.env                  # Default/development
.env.test            # Testing environment
.env.staging         # Staging environment
.env.production      # Production (reference only)
```

### Loading Order (Priority)

1. System environment variables (highest)
2. `.env.{environment}` file
3. `.env` file
4. Default values in code (lowest)

### Docker Support

```dockerfile
# Dockerfile
FROM python:3.10

# Don't copy .env files
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Environment variables should be injected at runtime
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    env_file:
      - .env  # Local development only
    environment:
      - APP_ENV=development
```

## ❓ Troubleshooting

### Common Issues

1. **API Key Not Found**
   ```python
   # Check if key is loaded
   import os
   print(f"Key exists: {'GEMINI_API_KEY' in os.environ}")
   print(f"Key length: {len(os.environ.get('GEMINI_API_KEY', ''))}")
   ```

2. **Wrong Model Name**
   - Ensure you're using current model names (e.g., `gemini-2.5-flash`, not `gemini-1.5-flash`)

3. **Rate Limiting**
   - Implement exponential backoff
   - Use fallback models
   - Monitor daily quotas

4. **Environment Variable Not Loading**
   ```python
   # Force reload
   from dotenv import load_dotenv
   load_dotenv(override=True)
   ```

### Validation Script

```python
# validate_env.py
from config import get_settings

try:
    settings = get_settings()
    print("✅ Environment configuration valid")
    print(f"📍 Environment: {settings.app_env}")
    print(f"🤖 Default Model: {settings.gemini_default_model}")
except Exception as e:
    print(f"❌ Configuration error: {e}")
```

## 📚 Additional Resources

- [Google Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Pydantic Settings Documentation](https://docs.pydantic.dev/latest/usage/pydantic_settings/)
- [python-dotenv Documentation](https://pypi.org/project/python-dotenv/)
- [FastAPI Configuration Guide](https://fastapi.tiangolo.com/advanced/settings/)

---

Remember: **Security first!** Never commit real API keys or sensitive configuration to version control.
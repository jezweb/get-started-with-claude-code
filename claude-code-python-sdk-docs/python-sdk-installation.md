# Claude Code Python SDK Installation and Setup

## Overview
The Claude Code Python SDK enables developers to integrate Claude's AI-powered coding capabilities into web applications. This guide covers installation, setup, and authentication for web development environments.

## Prerequisites

### System Requirements
- **Python**: 3.10 or higher
- **Node.js**: Required for Claude Code CLI (latest LTS recommended)
- **Operating System**: Linux, macOS, or Windows with WSL

### Development Environment
- **Web Framework**: FastAPI, Flask, Django, or other Python web frameworks
- **Package Manager**: pip (with virtual environment recommended)
- **Version Control**: Git (for project management)

## Installation

### Step 1: Install Claude Code CLI
The Python SDK requires the Claude Code CLI to be installed globally:

```bash
npm install -g @anthropic-ai/claude-code
```

Verify installation:
```bash
claude --version
```

### Step 2: Install Python SDK
Install the Python SDK using pip:

```bash
pip install claude-code-sdk
```

For development with additional dependencies:
```bash
pip install claude-code-sdk[dev]
```

### Step 3: Virtual Environment Setup (Recommended)
For web application development, use a virtual environment:

```bash
# Create virtual environment
python -m venv claude-env

# Activate virtual environment
# On Linux/macOS:
source claude-env/bin/activate
# On Windows:
claude-env\Scripts\activate

# Install SDK in virtual environment
pip install claude-code-sdk
```

## Authentication

### Method 1: Anthropic API Key (Recommended)
1. Create an account at [Anthropic Console](https://console.anthropic.com)
2. Generate an API key from the dashboard
3. Set the environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

For persistent setup, add to your shell profile:
```bash
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

### Method 2: Environment Configuration File
Create a `.env` file in your project root:

```env
ANTHROPIC_API_KEY=your-api-key-here
```

Load in your Python application:
```python
from dotenv import load_dotenv
load_dotenv()
```

### Method 3: Third-Party Providers
For enterprise deployments, configure alternative providers:

#### Amazon Bedrock
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

#### Google Vertex AI
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
export GOOGLE_CLOUD_PROJECT="your-project-id"
```

## Verification

### Test Installation
Create a simple test script to verify everything works:

```python
import asyncio
from claude_code_sdk import query, ClaudeCodeOptions

async def test_installation():
    """Test Claude Code SDK installation"""
    try:
        messages = []
        async for message in query(
            prompt="Hello, Claude Code SDK!",
            options=ClaudeCodeOptions(max_turns=1)
        ):
            messages.append(message)
        
        print("✅ Claude Code SDK installed successfully!")
        print(f"Response: {messages[0].content if messages else 'No response'}")
        
    except Exception as e:
        print(f"❌ Installation test failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_installation())
```

Save as `test_claude_sdk.py` and run:
```bash
python test_claude_sdk.py
```

## Web Application Integration

### FastAPI Project Setup
For FastAPI web applications:

```bash
# Create new FastAPI project
mkdir my-claude-web-app
cd my-claude-web-app

# Create virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies
pip install fastapi uvicorn claude-code-sdk python-dotenv

# Create project structure
mkdir app
touch app/__init__.py
touch app/main.py
touch .env
```

Example `app/main.py`:
```python
from fastapi import FastAPI
from claude_code_sdk import query, ClaudeCodeOptions
import asyncio

app = FastAPI(title="Claude Code Web API")

@app.get("/")
async def root():
    return {"message": "Claude Code SDK Web API"}

@app.post("/claude/query")
async def claude_query(prompt: str):
    """Endpoint to query Claude Code SDK"""
    messages = []
    async for message in query(
        prompt=prompt,
        options=ClaudeCodeOptions(max_turns=1)
    ):
        messages.append(message)
    
    return {"response": messages[0].content if messages else "No response"}
```

### Django Project Setup
For Django web applications:

```bash
# Install Django with Claude SDK
pip install django claude-code-sdk

# Create Django project
django-admin startproject claude_web_project
cd claude_web_project

# Create Django app
python manage.py startapp claude_integration
```

## Configuration for Production

### Environment Variables
Set up production environment variables:

```bash
# Production environment
export CLAUDE_ENV=production
export ANTHROPIC_API_KEY="prod-api-key"
export DEBUG=False

# Optional: Rate limiting
export CLAUDE_MAX_REQUESTS_PER_MINUTE=60
export CLAUDE_MAX_TURNS_PER_REQUEST=5
```

### Security Considerations
1. **API Key Security**: Never commit API keys to version control
2. **Environment Isolation**: Use different API keys for development/production
3. **Rate Limiting**: Implement request rate limiting for web endpoints
4. **Input Validation**: Sanitize user inputs before sending to Claude
5. **Error Handling**: Implement proper error handling and logging

### Performance Optimization
```python
# Example production configuration
production_options = ClaudeCodeOptions(
    max_turns=3,  # Limit conversation length
    system_prompt="You are a helpful coding assistant for web applications.",
    permission_mode="askForEdits",  # Require permission for file modifications
    allowed_tools=["Read", "Write"]  # Limit available tools
)
```

## Troubleshooting

### Common Issues

#### 1. Claude CLI Not Found
```bash
# Error: claude command not found
# Solution: Install CLI globally
npm install -g @anthropic-ai/claude-code

# Verify Node.js path
which node
npm config get prefix
```

#### 2. Python SDK Import Error
```python
# Error: ModuleNotFoundError: No module named 'claude_code_sdk'
# Solution: Ensure SDK is installed in correct environment
pip list | grep claude-code-sdk
```

#### 3. Authentication Failed
```bash
# Error: Authentication failed
# Solution: Check API key configuration
echo $ANTHROPIC_API_KEY

# Test API key validity
curl -H "x-api-key: $ANTHROPIC_API_KEY" \
     https://api.anthropic.com/v1/messages
```

#### 4. Permission Denied
```bash
# Error: Permission denied when running claude
# Solution: Check file permissions and user access
ls -la $(which claude)
sudo chmod +x $(which claude)
```

### Development vs Production
- **Development**: Use liberal permissions and detailed logging
- **Production**: Restrict permissions, implement rate limiting, monitor usage

### Logging Configuration
```python
import logging

# Configure logging for Claude SDK
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('claude_sdk.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('claude_code_sdk')
```

## Next Steps

After successful installation:
1. Review [Core API Documentation](python-sdk-core-api.md)
2. Explore [FastAPI Integration Patterns](python-sdk-fastapi-integration.md)
3. Study [Async Programming Patterns](python-sdk-async-patterns.md)
4. Implement [Error Handling](python-sdk-error-handling.md)

## Resources

- [Claude Code SDK GitHub Repository](https://github.com/anthropics/claude-code)
- [Anthropic API Documentation](https://docs.anthropic.com)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Python Async Programming Guide](https://docs.python.org/3/library/asyncio.html)

---

**Last Updated:** Based on Claude Code SDK documentation as of 2025
**Reference:** https://docs.anthropic.com/en/docs/claude-code/sdk
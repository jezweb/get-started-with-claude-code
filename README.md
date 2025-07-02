# Claude Code Starter Kit

A comprehensive starter kit for web development with Claude Code, including extensive documentation and context folders for popular frameworks and services. Get coding in seconds, not minutes.

## 🚀 Quick Install

In any project directory:

```bash
# Basic install
curl -fsSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | sh

# With pre-approved commands (recommended for smoother workflow)
curl -fsSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | sh -s -- --with-settings
```

Or manually:

```bash
git clone https://github.com/jezweb/get-started-with-claude-code.git
cp -r get-started-with-claude-code/{CLAUDE.md,kickoff-prompt.md,mvp-from-plan.md,.claude} .
# Optional: Copy documentation folders you need
cp -r get-started-with-claude-code/fastapi-complete-docs .  # For FastAPI projects
cp -r get-started-with-claude-code/env-configuration .      # For environment setup
rm -rf get-started-with-claude-code
```

## 📦 What You Get

### Core Files
- **CLAUDE.md** - Project context for Claude Code
- **kickoff-prompt.md** - Universal prompt for starting web projects
- **mvp-from-plan.md** - Build MVP from existing PRD/plan
- **.claude/commands/** - Useful commands:
  - `/feature` - Add new features
  - `/debug` - Fix issues
  - `/deploy` - Prepare for production
  - `/refactor` - Improve code quality
  - `/mvp` - Build from existing plan
  - And more...
- **settings.local.json** (optional) - Pre-approved commands for smoother workflow

### 📚 Documentation Context Folders

#### 🔧 Environment Configuration (`env-configuration/`)
- Complete guide for managing environment variables
- Templates for simple and advanced setups
- Security best practices
- Multi-model AI configuration patterns
- Validation tools

#### 🐍 FastAPI Documentation (`fastapi-complete-docs/`)
- Comprehensive FastAPI development guide
- Production patterns and best practices
- Database integration (SQLAlchemy, MongoDB)
- Authentication and security
- Deployment strategies

#### 🤖 Google Gemini API (`gemini-api-docs/`)
- Complete Gemini API reference
- Model selection guide (2.5 Pro, Flash, Flash-Lite)
- Integration patterns
- Function calling and multimodal features
- Best practices and examples

#### 🎨 Shadcn/Vue Documentation (`shadcn-vue-docs/`)
- Complete component library reference
- Styling and theming guide
- Framework integration (Vue 3, Nuxt, Vite)
- Advanced patterns and blocks
- Production deployment

#### ☁️ Cloudflare Services (`cloudflare-services-docs/`)
- Workers, Pages, D1, R2 documentation
- KV, Durable Objects, Queues
- Email Workers and Analytics
- Complete deployment guides

#### 🐍 Modern Python Features (`python-modern-features-docs/`)
- Python 3.10+ feature guide
- Type hints and async patterns
- Modern standard library usage
- Best practices and examples

#### 🧰 Additional Resources
- **AI-Development-Guide.md** - AI-powered development best practices
- **Project-Setup-Checklist.md** - Comprehensive project setup guide
- **mcp-servers.md** - MCP (Model Context Protocol) server documentation
- **useful-context/** - Additional helpful documentation

## 🎯 How to Use

### Basic Usage
1. **Install** the starter kit in your project
2. **Edit** CLAUDE.md to match your tech stack
3. **Run** `claude-code`
4. **Choose** your starting approach:
   - **New idea?** Use `kickoff-prompt.md` or `/kickoff`
   - **Have a plan?** Use `mvp-from-plan.md` or `/mvp`

### Using Documentation Folders
Copy the documentation folders you need into your project to give Claude Code deep context:

```bash
# For FastAPI projects
cp -r /path/to/get-started-with-claude-code/fastapi-complete-docs .

# For environment configuration
cp -r /path/to/get-started-with-claude-code/env-configuration .

# For Vue.js with shadcn/vue
cp -r /path/to/get-started-with-claude-code/shadcn-vue-docs .
```

Then reference them in your prompts:
```
Using the FastAPI documentation in fastapi-complete-docs/, create a REST API with JWT authentication
```

## 🛠️ Works Great For

- **Web Applications** - Full-stack apps with modern frameworks
- **APIs and Services** - RESTful APIs, microservices, serverless
- **AI-Powered Apps** - Integration with Gemini, Claude, OpenAI
- **Landing Pages** - Marketing sites, portfolios
- **Dashboards** - Admin panels, analytics interfaces
- **Prototypes** - Quick MVPs and proof of concepts

## 📝 Example Usage

### Basic Project
```
I want to build a dashboard for tracking expenses with charts and category breakdown.
```

### With Context Folders
```
Using the FastAPI docs, create an API for managing blog posts with SQLAlchemy and JWT auth.
```

### Environment Setup
```
Help me set up environment variables using the env-configuration templates for a Gemini-powered chatbot.
```

## 🎨 Customization

Edit `CLAUDE.md` to set your preferences:
- Preferred framework (React, Vue, etc.)
- Code style guidelines
- Project structure
- Common commands

See `SETTINGS_GUIDE.md` for customizing pre-approved commands.

## 📚 Documentation Highlights

### Environment Configuration
The `env-configuration/` folder includes:
- **`.env.simple`** - Quick start template for basic AI apps
- **`.env.complete`** - Advanced multi-model configuration
- **`validate_env.py`** - Validate your configuration
- **Complete guide** covering security, naming conventions, and best practices

### FastAPI Documentation
Complete production-ready patterns including:
- Project structure and setup
- Database integration (async SQLAlchemy, MongoDB)
- Authentication (JWT, OAuth2)
- Background tasks and WebSockets
- Testing and deployment strategies

### Gemini API Documentation
Comprehensive guide for Google's latest AI models:
- Gemini 2.5 Pro, Flash, and Flash-Lite
- Multimodal capabilities (text, image, video, audio)
- Function calling and tool use
- Streaming and thinking modes
- Cost optimization strategies

## 🤝 Contributing

PRs welcome! Keep it simple and practical. Areas of interest:
- Additional framework documentation (Next.js, Django, etc.)
- More AI provider contexts (OpenAI, Anthropic)
- Deployment guides for various platforms
- Useful commands and automations

## 📄 License

MIT - Use freely in your projects.

---

**Ready to code?** Run the install command above and start building! 🚀

*Created with ❤️ to make AI-assisted development faster and more enjoyable.*
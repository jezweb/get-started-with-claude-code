# Claude Code Documentation Resources

A curated collection of comprehensive documentation and context resources for AI-assisted development. Point Claude Code, Gemini, or other AI tools at specific files/folders to get deep context for your projects.

## 🎯 How to Use This Repository

This is **not an installation kit** - it's a **resource library**. Here's how to use it:

### 🤖 With AI Tools (Recommended)
Point your AI assistant at specific resources:
```
Claude, using the FastAPI documentation at https://github.com/jezweb/get-started-with-claude-code/tree/main/fastapi-complete-docs, help me build a REST API with authentication.
```

### 📁 Grab Individual Resources
Copy specific folders/files you need:
```bash
# Just the environment configuration templates
curl -O https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/env-configuration/.env.simple

# Or clone and copy what you need
git clone https://github.com/jezweb/get-started-with-claude-code.git
cp -r get-started-with-claude-code/fastapi-complete-docs ./my-project/
```

### 🔍 Browse and Reference
Use this repository as a reference while working on your projects.

---

## 📚 Resource Index

### 🔧 Environment & Configuration

#### [`env-configuration/`](./env-configuration/)
**Complete environment variable management for AI applications**
- **Best for**: Setting up API keys, model configurations, multi-environment setups
- **Contains**: `.env` templates, validation tools, security best practices
- **AI Models**: Optimized for Gemini 2.5 Pro/Flash/Flash-Lite (July 2025)
- **Key files**: 
  - `.env.simple` - Quick start template
  - `.env.complete` - Advanced multi-model setup
  - `validate_env.py` - Configuration validator

---

### 🐍 Python & FastAPI

#### [`fastapi-complete-docs/`](./fastapi-complete-docs/)
**Production-ready FastAPI development patterns**
- **Best for**: Building robust Python APIs, microservices, full-stack apps
- **Contains**: Project structure, authentication, database integration, deployment
- **Level**: Beginner to Advanced
- **Key files**:
  - `README.md` - Complete FastAPI guide with examples
  - Production patterns and best practices

#### [`python-modern-features-docs/`](./python-modern-features-docs/)
**Modern Python 3.10+ features and patterns**
- **Best for**: Leveraging latest Python capabilities
- **Contains**: Type hints, async patterns, dataclasses, match statements
- **Level**: Intermediate to Advanced

---

### 🤖 AI & API Integration

#### [`gemini-api-docs/`](./gemini-api-docs/)
**Google Gemini API comprehensive guide**
- **Best for**: Integrating Gemini 2.5 models into applications
- **Contains**: Model selection, multimodal features, function calling, cost optimization
- **Models**: Pro, Flash, Flash-Lite (current as of July 2025)
- **Key files**:
  - Complete API reference and integration patterns

---

### 🎨 Frontend & UI

#### [`shadcn-vue-docs/`](./shadcn-vue-docs/)
**Complete shadcn/vue component library documentation**
- **Best for**: Vue.js projects with modern UI components
- **Contains**: 40+ components, styling guide, framework integration
- **Frameworks**: Vue 3, Nuxt.js, Vite
- **Key files**:
  - `shadcn-vue-components-reference.md` - All components with examples
  - `shadcn-vue-styling-theming.md` - Theming and customization
  - `shadcn-vue-framework-integration.md` - Vue 3/Nuxt patterns

---

### ☁️ Cloud & Infrastructure

#### [`cloudflare-services-docs/`](./cloudflare-services-docs/)
**Cloudflare platform services documentation**
- **Best for**: Serverless apps, edge computing, modern web infrastructure
- **Contains**: Workers, Pages, D1, R2, KV, Durable Objects
- **Level**: Beginner to Advanced

---

### 📋 Project Resources

#### Individual Reference Files
- [`AI-Development-Guide.md`](./AI-Development-Guide.md) - Best practices for AI-assisted development
- [`Project-Setup-Checklist.md`](./Project-Setup-Checklist.md) - Comprehensive project setup guide
- [`mcp-servers.md`](./mcp-servers.md) - Model Context Protocol server documentation

#### Legacy Starter Files
- [`CLAUDE.md`](./CLAUDE.md) - Example project context file
- [`kickoff-prompt.md`](./kickoff-prompt.md) - Universal project kickoff prompt
- [`mvp-from-plan.md`](./mvp-from-plan.md) - Build MVP from existing plans

---

## 🔍 Finding What You Need

### By Technology Stack
- **Python/FastAPI**: `fastapi-complete-docs/`, `python-modern-features-docs/`
- **Vue.js**: `shadcn-vue-docs/`
- **AI Integration**: `gemini-api-docs/`, `env-configuration/`
- **Serverless/Edge**: `cloudflare-services-docs/`

### By Project Phase
- **Planning**: `Project-Setup-Checklist.md`, `AI-Development-Guide.md`
- **Setup**: `env-configuration/`, `CLAUDE.md`
- **Development**: Framework-specific docs
- **Deployment**: Deployment sections in relevant docs

### By Experience Level
- **Beginner**: `env-configuration/.env.simple`, basic sections in all docs
- **Intermediate**: Most documentation folders
- **Advanced**: Complete configurations, production patterns

---

## 🤖 AI Tool Integration Tips

### For Claude Code
1. **Point to specific folders**: Reference GitHub URLs to folder contents
2. **Use file paths**: Mention specific files for focused context
3. **Combine resources**: Reference multiple relevant docs for complex projects

### For Gemini/ChatGPT
1. **Copy-paste relevant sections**: Grab specific documentation sections
2. **Reference structure**: Use the folder organization as context
3. **Link to raw files**: Use GitHub raw URLs for direct file access

### Example AI Prompts
```
Using the FastAPI documentation at [repo-url]/fastapi-complete-docs/, create a REST API for a blog with JWT authentication and SQLAlchemy.

Help me set up environment variables using the templates in [repo-url]/env-configuration/ for a Gemini-powered chatbot.

Using the shadcn/vue components reference, build a dashboard with data tables and charts.
```

---

## 🎯 Repository Goals

This repository aims to:
- **Reduce AI context setup time** by providing comprehensive, ready-to-use documentation
- **Improve AI output quality** through detailed, structured context
- **Share battle-tested patterns** from real-world development
- **Stay current** with latest framework versions and best practices

## 🤝 Contributing

This is a living resource! Contributions welcome:
- **New documentation folders** for popular frameworks/tools
- **Updates** to existing docs for latest versions
- **Improvements** to AI tool compatibility
- **Better organization** and indexing

### Contribution Guidelines
- Keep documentation comprehensive but focused
- Include practical examples and real-world patterns
- Optimize for AI tool consumption (clear structure, good examples)
- Update version information and model names

---

## 📄 License

MIT - Use freely in your projects.

---

**🔗 Repository**: https://github.com/jezweb/get-started-with-claude-code

*A curated resource collection for faster, better AI-assisted development.*
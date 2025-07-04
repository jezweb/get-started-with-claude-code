# Get Started with Claude Code

The simplest way to supercharge your development with AI assistance.

## 🚀 Quick Start (Linux/Mac)

```bash
curl -sSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | bash
```

That's it! The installer will:
1. Set up your personal Claude Code configuration
2. Ask if you want 5 essential commands (recommended!)

## 🎯 What You Get

### Personal Setup Files:
- **CLAUDE.md** - Your AI assistant profile (customize with your info!)
- **settings.local.json** - Reduces annoying approval prompts
- **make-command.md** - Creates custom commands for YOUR workflow

### Essential Commands (Optional but Recommended):
- **`/user:start-project`** - Smart project setup with tech stack detection
- **`/user:add-feature`** - Add features following project patterns
- **`/user:fix-bug`** - Debug issues systematically
- **`/user:write-tests`** - Create comprehensive tests
- **`/user:deploy`** - Deploy to production

### Create Your Own Commands:
```
claude-code
/user:make-command
```

## 📁 What's Here?

- **`get-started/`** - Simple 2-file setup + essential commands
- **`context/`** - Organized documentation for AI context
- **`archive/`** - Historical files and complex templates

## 🎯 Manual Setup

If you prefer to set up manually or you're on Windows:

1. **Install Claude Code**: `npm install -g @anthropic-ai/claude-code`
2. **Copy setup files**: See [`get-started/README.md`](get-started/README.md)
3. **Start building**: Run `claude-code` in any project

## 🚀 Smart Project Detection

The `/user:start-project` command automatically detects:
- Existing tech stack from your files
- Best practices for your framework
- Appropriate folder structure
- Required dependencies

Works with ANY tech stack:
- **AI Apps** - Python + FastAPI + Gemini/Claude APIs
- **Web Apps** - React, Vue, Next.js, plain HTML
- **Mobile** - React Native, Flutter
- **Backend** - Node.js, Python, Go, Rust
- **And more!**

## 📚 Learn More

- [Detailed Setup Guide](get-started/README.md)
- [Context Documentation](context/README.md)
- [Claude Code Docs](https://docs.anthropic.com/claude-code)

---

**Start building with AI assistance in minutes, not hours!** 🎉
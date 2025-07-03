# Quick Start Guide

A comprehensive guide to get developers up and running quickly with modern web development projects. This guide covers essential setup steps, project initialization, and common workflows.

## 🚀 Overview

This quick start guide helps you:
- **Set up your development environment** in minutes
- **Initialize new projects** with best practices
- **Start coding immediately** with proven patterns
- **Avoid common pitfalls** with tested workflows
- **Integrate AI assistance** from the beginning

## 📋 Prerequisites Check

### Essential Tools
```bash
# Check if you have required tools
node --version      # Should be 18.x or higher
npm --version       # Should be 8.x or higher
git --version       # Should be 2.x or higher
python --version    # Should be 3.10 or higher (for backend)

# Optional but recommended
docker --version    # For containerization
code --version      # VS Code
```

### Quick Install Commands
```bash
# macOS (using Homebrew)
brew install node git python@3.11

# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm git python3.11

# Windows (using winget)
winget install OpenJS.NodeJS Git.Git Python.Python.3.11
```

## 🎯 Project Types

### 1. Frontend Project (Vite + Vue/React)

```bash
# Vue 3 project
npm create vite@latest my-app -- --template vue
cd my-app
npm install
npm run dev

# React project
npm create vite@latest my-app -- --template react
cd my-app
npm install
npm run dev

# With TypeScript
npm create vite@latest my-app -- --template vue-ts
# or
npm create vite@latest my-app -- --template react-ts
```

### 2. Full-Stack Project (FastAPI + Vue)

```bash
# Create project structure
mkdir my-fullstack-app && cd my-fullstack-app

# Backend setup
mkdir backend && cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install fastapi uvicorn python-dotenv

# Create backend/main.py
cat > main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
def health_check():
    return {"status": "healthy"}
EOF

# Frontend setup (in project root)
cd ..
npm create vite@latest frontend -- --template vue
cd frontend
npm install
```

### 3. API-Only Project (FastAPI)

```bash
# Create project
mkdir my-api && cd my-api

# Setup Python environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn[standard] python-dotenv sqlalchemy

# Create project structure
mkdir -p app/{api,core,models,schemas}
touch app/__init__.py app/main.py

# Generate requirements.txt
pip freeze > requirements.txt
```

## 🛠️ Essential Configuration

### 1. Environment Variables (.env)
```bash
# .env file in project root
# Frontend
VITE_API_URL=http://localhost:8000
VITE_APP_TITLE="My App"

# Backend
DATABASE_URL=sqlite:///./app.db
SECRET_KEY=your-secret-key-here
ENVIRONMENT=development
DEBUG=true
```

### 2. Git Configuration (.gitignore)
```bash
# Node
node_modules/
dist/
.env.local
*.log

# Python
venv/
__pycache__/
*.pyc
.env
*.db

# IDE
.vscode/
.idea/
*.swp
.DS_Store
```

### 3. VS Code Setup (.vscode/settings.json)
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[vue]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

## 🏃 Common Workflows

### Starting Development

```bash
# Frontend only
npm run dev

# Backend only
uvicorn main:app --reload

# Full-stack (two terminals)
# Terminal 1: Backend
cd backend && source venv/bin/activate && uvicorn main:app --reload

# Terminal 2: Frontend
cd frontend && npm run dev

# Or use a process manager
npm install -g concurrently
concurrently "cd backend && uvicorn main:app --reload" "cd frontend && npm run dev"
```

### Adding Dependencies

```bash
# Frontend (npm)
npm install axios pinia vue-router
npm install -D @types/node sass

# Backend (pip)
pip install httpx pydantic[email] python-jose[cryptography]
pip freeze > requirements.txt
```

### Running Tests

```bash
# Frontend
npm test                    # Run tests once
npm run test:watch         # Watch mode
npm run test:coverage      # With coverage

# Backend
pytest                     # Run all tests
pytest -v                  # Verbose output
pytest --cov=app          # With coverage
```

## 🎨 Project Structure Best Practices

### Frontend Structure
```
frontend/
├── public/             # Static assets
├── src/
│   ├── assets/        # Images, fonts, etc.
│   ├── components/    # Reusable components
│   ├── composables/   # Vue composables / React hooks
│   ├── router/        # Route definitions
│   ├── stores/        # State management
│   ├── views/         # Page components
│   ├── utils/         # Helper functions
│   ├── App.vue        # Root component
│   └── main.js        # Entry point
├── .env               # Environment variables
├── .gitignore        # Git ignore rules
├── index.html        # HTML entry point
├── package.json      # Dependencies
├── README.md         # Project documentation
└── vite.config.js    # Vite configuration
```

### Backend Structure
```
backend/
├── app/
│   ├── api/          # API endpoints
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       └── endpoints/
│   ├── core/         # Core functionality
│   │   ├── __init__.py
│   │   ├── config.py
│   │   └── security.py
│   ├── models/       # Database models
│   │   ├── __init__.py
│   │   └── user.py
│   ├── schemas/      # Pydantic schemas
│   │   ├── __init__.py
│   │   └── user.py
│   ├── __init__.py
│   └── main.py       # FastAPI app
├── tests/            # Test files
├── .env              # Environment variables
├── .gitignore       # Git ignore rules
├── requirements.txt  # Dependencies
└── README.md        # Project documentation
```

## 🚦 First Steps Checklist

### After Project Creation
1. ✅ Initialize Git repository
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. ✅ Set up environment variables
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

3. ✅ Install dependencies
   ```bash
   npm install  # or pip install -r requirements.txt
   ```

4. ✅ Run initial tests
   ```bash
   npm test  # or pytest
   ```

5. ✅ Start development server
   ```bash
   npm run dev  # or uvicorn main:app --reload
   ```

6. ✅ Create CLAUDE.md for AI context
   ```bash
   touch CLAUDE.md
   # Add project-specific context
   ```

## 🤖 AI Integration

### Setting Up Claude Code
```bash
# Install Claude Code CLI (if available)
npm install -g @anthropic/claude-code

# Or use in project
touch CLAUDE.md
```

### CLAUDE.md Template
```markdown
# Project: [Your Project Name]

## Overview
Brief description of what this project does

## Tech Stack
- Frontend: Vue 3 / React
- Backend: FastAPI
- Database: SQLite / PostgreSQL
- State: Pinia / Redux

## Key Features
- Feature 1
- Feature 2

## Development Commands
\`\`\`bash
npm run dev      # Start frontend
uvicorn main:app --reload  # Start backend
npm test         # Run tests
\`\`\`

## Project Structure
Describe any non-standard structure

## Current Tasks
- [ ] Task 1
- [ ] Task 2
```

## 🔧 Troubleshooting

### Common Issues

**Port already in use**
```bash
# Find process using port
lsof -i :5173  # or :8000 for backend

# Kill process
kill -9 <PID>

# Or use different port
npm run dev -- --port 3000
uvicorn main:app --port 8001
```

**Module not found errors**
```bash
# Frontend
rm -rf node_modules package-lock.json
npm install

# Backend
pip install -r requirements.txt
```

**CORS errors**
```python
# In FastAPI main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 📚 Next Steps

After quick start:
1. **Read environment setup guide** for detailed configuration
2. **Review project patterns** for best practices
3. **Set up testing** with unit and integration tests
4. **Configure CI/CD** for automated workflows
5. **Plan your features** using AI-assisted development

## 🔗 Quick Links

- [Development Environment Setup](../environment-setup/README.md)
- [Project Initialization Patterns](../project-init/README.md)
- [Common Workflows](../workflows/README.md)
- [Testing Guide](../../06-testing-quality/README.md)
- [AI Development Patterns](../../ai-development-starter-kit/README.md)

---

*This quick start guide gets you coding in minutes. For detailed explanations and advanced patterns, explore the linked documentation.*
# Project Initialization Patterns

Best practices and patterns for initializing new projects with proper structure, tooling, and AI-assisted development setup.

## 🎯 Initialization Overview

Project initialization sets the foundation for:
- **Consistent Structure** - Organized, scalable architecture
- **Development Workflow** - Efficient processes from day one
- **Quality Standards** - Linting, testing, documentation
- **Team Collaboration** - Git, CI/CD, code reviews
- **AI Integration** - Context files, prompts, workflows
- **Future Scalability** - Patterns that grow with the project

## 📋 Pre-Initialization Checklist

### Project Planning
```markdown
# Answer these questions before starting:

## Project Basics
- **Name**: What is the project called?
- **Type**: Web app, API, library, CLI tool?
- **Scope**: MVP, prototype, production?
- **Timeline**: Development schedule?
- **Team Size**: Solo or team project?

## Technical Decisions
- **Frontend**: React, Vue, Svelte, vanilla?
- **Backend**: Node.js, Python, Go?
- **Database**: PostgreSQL, MongoDB, SQLite?
- **Hosting**: Vercel, AWS, self-hosted?
- **Authentication**: Built-in, Auth0, Supabase?

## Requirements
- **Performance**: Response time, concurrent users?
- **Security**: Data sensitivity, compliance?
- **Scalability**: Expected growth?
- **Integrations**: Third-party services?
```

## 🚀 Initialization Patterns

### 1. Full-Stack Web Application

```bash
# Create project structure
mkdir my-fullstack-app && cd my-fullstack-app

# Initialize git first
git init
echo "# My Fullstack App" > README.md

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
venv/
*.pyc
__pycache__/

# Environment
.env
.env.local
*.local

# Build outputs
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
.DS_Store

# Logs
*.log
npm-debug.log*
yarn-error.log*

# Testing
coverage/
.coverage
.pytest_cache/
*.coverage

# Database
*.db
*.sqlite3
EOF

# Create project structure
mkdir -p {frontend,backend,shared,docs,scripts}

# Frontend setup
cd frontend
npm init vite@latest . -- --template vue-ts
npm install
npm install -D @types/node sass

# Create frontend structure
mkdir -p src/{components,composables,stores,views,utils,styles,types}

# Backend setup
cd ../backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Create requirements.txt
cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
sqlalchemy==2.0.23
pydantic==2.5.0
pydantic-settings==2.1.0
alembic==1.12.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
httpx==0.25.1
pytest==7.4.3
pytest-asyncio==0.21.1
EOF

pip install -r requirements.txt

# Create backend structure
mkdir -p app/{api/v1/endpoints,core,db,models,schemas,services,utils}
touch app/__init__.py

# Create main application file
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "API is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
EOF

# Create configuration
cat > app/core/config.py << 'EOF'
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "My Fullstack App"
    VERSION: str = "0.1.0"
    API_V1_STR: str = "/api/v1"
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:5173"]
    
    # Database
    DATABASE_URL: str = "sqlite:///./app.db"
    
    # Security
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"

settings = Settings()
EOF

# Create shared types/interfaces
cd ../shared
touch types.ts

# Create documentation structure
cd ../docs
touch API.md DEPLOYMENT.md CONTRIBUTING.md

# Create development scripts
cd ../scripts
cat > dev.sh << 'EOF'
#!/bin/bash
# Start both frontend and backend in development mode

echo "Starting development servers..."

# Start backend
cd backend && source venv/bin/activate && uvicorn app.main:app --reload --port 8000 &
BACKEND_PID=$!

# Start frontend
cd frontend && npm run dev &
FRONTEND_PID=$!

# Wait for Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID" EXIT
wait
EOF

chmod +x dev.sh

# Return to root
cd ..
```

### 2. Component Library

```bash
# Initialize library project
mkdir my-component-library && cd my-component-library
git init

# Package.json with proper configuration
cat > package.json << 'EOF'
{
  "name": "@myorg/component-library",
  "version": "0.1.0",
  "description": "Reusable component library",
  "main": "dist/index.js",
  "module": "dist/index.esm.js",
  "types": "dist/index.d.ts",
  "files": [
    "dist",
    "README.md"
  ],
  "sideEffects": false,
  "scripts": {
    "dev": "vite",
    "build": "vite build && tsc",
    "test": "vitest",
    "lint": "eslint src --ext .ts,.tsx",
    "format": "prettier --write 'src/**/*.{ts,tsx,css}'",
    "storybook": "storybook dev -p 6006",
    "build-storybook": "storybook build"
  },
  "peerDependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^5.0.0",
    "vitest": "^1.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

# Create structure
mkdir -p src/{components,hooks,utils,types} 
mkdir -p .storybook

# Vite configuration for library
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react()],
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'MyComponentLibrary',
      formats: ['es', 'umd'],
      fileName: (format) => `index.${format}.js`
    },
    rollupOptions: {
      external: ['react', 'react-dom'],
      output: {
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM'
        }
      }
    }
  }
})
EOF

# TypeScript configuration
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "declaration": true,
    "declarationDir": "./dist",
    "outDir": "./dist"
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF
```

### 3. CLI Tool

```bash
# Initialize CLI project
mkdir my-cli-tool && cd my-cli-tool
git init

# Node.js CLI
npm init -y
npm install commander chalk ora inquirer
npm install -D @types/node typescript tsx

# Create structure
mkdir -p src/{commands,utils,types}

# Main CLI entry
cat > src/index.ts << 'EOF'
#!/usr/bin/env node
import { Command } from 'commander'
import chalk from 'chalk'
import { version } from '../package.json'

const program = new Command()

program
  .name('my-cli')
  .description('CLI tool description')
  .version(version)

program
  .command('init')
  .description('Initialize a new project')
  .option('-t, --template <type>', 'project template', 'default')
  .action(async (options) => {
    const { init } = await import('./commands/init')
    await init(options)
  })

program
  .command('build')
  .description('Build the project')
  .option('-w, --watch', 'watch mode')
  .action(async (options) => {
    const { build } = await import('./commands/build')
    await build(options)
  })

program.parse()
EOF

# Package.json updates
cat > package.json << 'EOF'
{
  "name": "my-cli-tool",
  "version": "0.1.0",
  "description": "CLI tool description",
  "bin": {
    "my-cli": "./dist/index.js"
  },
  "scripts": {
    "dev": "tsx src/index.ts",
    "build": "tsc",
    "prepublishOnly": "npm run build"
  },
  "files": [
    "dist",
    "templates"
  ],
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF

# Python CLI alternative
cat > setup.py << 'EOF'
from setuptools import setup, find_packages

setup(
    name="my-cli-tool",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "click>=8.0",
        "rich>=13.0",
        "requests>=2.28",
    ],
    entry_points={
        "console_scripts": [
            "my-cli=my_cli.main:cli",
        ],
    },
    python_requires=">=3.8",
)
EOF
```

## 🤖 AI-Assisted Development Setup

### CLAUDE.md Template

```markdown
# Project: [Project Name]

## Overview
[Brief description of the project's purpose and goals]

## Architecture
- **Frontend**: [Framework/Library]
- **Backend**: [Language/Framework]
- **Database**: [Type and specific DB]
- **Hosting**: [Platform]

## Key Features
1. [Feature 1]
2. [Feature 2]
3. [Feature 3]

## Project Structure
\`\`\`
[Show important directories and their purposes]
\`\`\`

## Development Workflow
1. **Branch naming**: feature/[description], fix/[description]
2. **Commit style**: [conventional commits / other]
3. **Code review**: [PR process]

## API Design
- **Base URL**: /api/v1
- **Authentication**: [Method]
- **Response format**: JSON

## Database Schema
[Key tables/collections and relationships]

## Testing Strategy
- **Unit tests**: [Framework]
- **Integration tests**: [Approach]
- **E2E tests**: [Tool]

## Deployment
- **Environment**: [dev, staging, prod]
- **CI/CD**: [Platform]
- **Monitoring**: [Tools]

## Common Commands
\`\`\`bash
# Development
npm run dev

# Testing
npm test

# Building
npm run build

# Deployment
npm run deploy
\`\`\`

## Current Focus
[What you're currently working on]

## Known Issues
- [ ] [Issue 1]
- [ ] [Issue 2]

## Resources
- [API Documentation](./docs/API.md)
- [Deployment Guide](./docs/DEPLOYMENT.md)
- [Contributing](./docs/CONTRIBUTING.md)
```

### AI Workflow Integration

```bash
# Create AI-specific directories
mkdir -p .claude/{commands,prompts,context}

# Command shortcuts
cat > .claude/commands/feature.md << 'EOF'
# New Feature Development

Please help me implement a new feature:

1. First, review the current codebase structure
2. Create necessary files following our patterns
3. Implement with error handling and validation
4. Add appropriate tests
5. Update documentation

Feature details:
- Name: [FEATURE_NAME]
- Description: [DESCRIPTION]
- Requirements: [REQUIREMENTS]
EOF

# Context snippets
cat > .claude/context/api-patterns.md << 'EOF'
# API Patterns

All API endpoints follow these patterns:

## Request/Response
- Use proper HTTP methods (GET, POST, PUT, DELETE)
- Return appropriate status codes
- Include error details in response body

## Validation
- Validate all inputs using Pydantic/Joi
- Return 400 for validation errors
- Include field-specific error messages

## Error Handling
\`\`\`python
try:
    result = await service.process(data)
    return {"success": True, "data": result}
except ValidationError as e:
    return JSONResponse(
        status_code=400,
        content={"success": False, "errors": e.errors()}
    )
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    return JSONResponse(
        status_code=500,
        content={"success": False, "error": "Internal server error"}
    )
\`\`\`
EOF
```

## 🔧 Configuration Files

### ESLint Configuration

```javascript
// .eslintrc.js
module.exports = {
  root: true,
  env: {
    node: true,
    es2022: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:vue/vue3-recommended', // or 'plugin:react/recommended'
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  },
}
```

### Prettier Configuration

```javascript
// .prettierrc.js
module.exports = {
  semi: false,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'es5',
  printWidth: 100,
  bracketSpacing: true,
  arrowParens: 'always',
  endOfLine: 'lf',
}
```

### TypeScript Configuration

```json
// Base tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "preserve",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "allowSyntheticDefaultImports": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## 📊 Project Templates

### Monorepo Structure

```bash
# Create monorepo
mkdir my-monorepo && cd my-monorepo
git init

# Use workspace tools
npm init -y
npm install -D lerna nx turbo

# Create workspace structure
mkdir -p packages/{ui,api,shared,config}
mkdir -p apps/{web,mobile}

# Root package.json
cat > package.json << 'EOF'
{
  "name": "my-monorepo",
  "private": true,
  "workspaces": [
    "packages/*",
    "apps/*"
  ],
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint"
  },
  "devDependencies": {
    "turbo": "latest"
  }
}
EOF

# Turbo configuration
cat > turbo.json << 'EOF'
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "dev": {
      "cache": false
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": ["coverage/**"]
    },
    "lint": {
      "outputs": []
    }
  }
}
EOF
```

## 🚦 Post-Initialization Checklist

### Immediate Tasks
- [ ] Initialize git and make first commit
- [ ] Set up pre-commit hooks (husky, lint-staged)
- [ ] Configure CI/CD pipeline
- [ ] Add LICENSE file
- [ ] Create initial documentation
- [ ] Set up error tracking (Sentry)
- [ ] Configure environment variables
- [ ] Add health check endpoints

### First Week Tasks
- [ ] Implement authentication
- [ ] Set up database migrations
- [ ] Create API documentation
- [ ] Add monitoring/logging
- [ ] Configure automated testing
- [ ] Set up staging environment
- [ ] Create deployment scripts
- [ ] Add performance benchmarks

## 🔄 Continuous Practices

### Code Quality
```bash
# Pre-commit hook setup
npm install -D husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"

# lint-staged configuration
cat > .lintstagedrc.json << 'EOF'
{
  "*.{js,jsx,ts,tsx,vue}": ["eslint --fix", "prettier --write"],
  "*.{json,md,yml,yaml}": ["prettier --write"],
  "*.py": ["black", "ruff --fix"]
}
EOF
```

### Documentation
```markdown
# Maintain these documents:
- README.md - Project overview and setup
- CONTRIBUTING.md - Development guidelines
- CHANGELOG.md - Version history
- API.md - API documentation
- ARCHITECTURE.md - System design
```

## 🎯 Success Metrics

Track these from the start:
- **Setup Time**: How long to get running
- **Build Time**: Development and production
- **Test Coverage**: Aim for 80%+
- **Bundle Size**: Monitor growth
- **Performance**: Core Web Vitals
- **Developer Experience**: Onboarding time

---

*Proper project initialization saves hours of refactoring later. Invest time upfront to establish solid patterns and workflows.*
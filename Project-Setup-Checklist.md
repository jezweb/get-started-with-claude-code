# Project Setup Checklist

## 🚀 Quick Start Guide for AI-Assisted Web Development

This checklist ensures consistent, high-quality project setup optimized for AI collaboration. Use it as a template for new projects.

---

## Pre-Setup Planning

### ☐ Define Project Scope
```markdown
Project Name: ________________
Business Purpose: ________________
Target Users: ________________
Key Features (MVP):
1. ________________
2. ________________
3. ________________
```

### ☐ Choose Tech Stack
- [ ] Backend: Python 3.10+ with FastAPI
- [ ] Database: SQLite (< 1000 users) or PostgreSQL
- [ ] Frontend: Vanilla JS or Vue/React
- [ ] AI Integration: Claude SDK / Google Generative AI
- [ ] Deployment: ________________

---

## Initial Setup

### ☐ Initialize with Claude
```bash
# Start with Claude Code
claude init

# Create initial prompt file
cat > project-brief.md << 'EOF'
## Project: [Name]

This is a project brief to create an MVP using a test-driven approach.

### Business Context
- Target users: [SME businesses in Australia]
- Main problem: [What we're solving]
- Success metrics: [How we measure success]

### Technical Requirements
- Python 3.10+ with FastAPI backend
- SQLite database for data persistence
- Simple HTML/CSS/JS frontend
- Authentication with JWT
- RESTful API design

### MVP Features
1. [Feature 1 with acceptance criteria]
2. [Feature 2 with acceptance criteria]
3. [Feature 3 with acceptance criteria]

Please follow TDD approach and create comprehensive documentation.
EOF
```

### ☐ Set Up Version Control
```bash
# Initialize git
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
*.egg-info/

# Environment
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# Testing
.coverage
htmlcov/
.pytest_cache/

# Database
*.db
*.sqlite3

# Logs
*.log

# OS
.DS_Store
Thumbs.db
EOF

# Initial commit
git add .
git commit -m "chore: initial project setup"
```

### ☐ Create Project Structure
```bash
# Create directory structure
mkdir -p src/{models,routes,services,repositories,utils}
mkdir -p tests/{unit,integration,e2e}
mkdir -p frontend/{css,js,assets}
mkdir -p docs
touch src/__init__.py

# Create main application file
cat > src/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Project Name",
    description="Project Description",
    version="0.1.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
EOF
```

### ☐ Set Up Python Environment
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Create requirements.txt
cat > requirements.txt << 'EOF'
# Core
fastapi==0.109.0
uvicorn[standard]==0.25.0
python-dotenv==1.0.0

# Database
sqlalchemy==2.0.25
sqlite-utils==3.35.2

# Authentication
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-cov==4.1.0
httpx==0.26.0

# Development
black==23.12.1
flake8==7.0.0
mypy==1.8.0
isort==5.13.2
EOF

# Install dependencies
pip install -r requirements.txt

# Create development requirements
cat > requirements-dev.txt << 'EOF'
-r requirements.txt
ipython==8.19.0
rich==13.7.0
EOF
```

---

## AI Configuration

### ☐ Create .clinerules
```yaml
cat > .clinerules << 'EOF'
# Project-Specific AI Coding Rules

## General Guidelines
- Follow PEP 8 for Python code
- Use type hints for all functions
- Write docstrings for public functions
- Prefer composition over inheritance

## Project Structure
- API routes in src/routes/
- Business logic in src/services/
- Data access in src/repositories/
- Shared utilities in src/utils/

## Git Workflow
- Use conventional commits format
- Create feature branches
- Reference issue numbers in commits
- Update tests and docs with code changes

## Testing Requirements
- Write tests before implementation (TDD)
- Minimum 80% code coverage
- Test edge cases and error scenarios
- Use pytest for all tests

## Security Rules
- Never hardcode secrets
- Validate all user inputs
- Use parameterized database queries
- Implement proper error handling

## API Design
- Follow RESTful conventions
- Use proper HTTP status codes
- Implement pagination for lists
- Include request/response validation

## Documentation
- Update README for new features
- Document API endpoints
- Include usage examples
- Explain complex business logic
EOF
```

### ☐ Create CLAUDE.md Context
```markdown
cat > CLAUDE.md << 'EOF'
# Project Context for AI Assistants

## Project Overview
[Brief description of the project, its purpose, and target users]

## Architecture Decisions
- **FastAPI**: Chosen for async support and automatic API documentation
- **SQLite**: Simple deployment for SME clients
- **JWT Auth**: Stateless authentication for scalability

## Code Conventions
- **Naming**: snake_case for Python, camelCase for JavaScript
- **File Organization**: Feature-based structure in src/
- **Error Handling**: Centralized in src/utils/errors.py

## Development Workflow
1. Write tests first (TDD)
2. Implement minimal code to pass
3. Refactor for clarity
4. Update documentation
5. Commit with conventional format

## Business Rules
[List any specific business logic or constraints]

## External Integrations
[List any APIs or services the project integrates with]

## Common Commands
- Run server: `uvicorn src.main:app --reload --port 20000`
- Run tests: `pytest tests/ -v --cov=src`
- Format code: `black src/ tests/ && isort src/ tests/`
EOF
```

---

## Development Environment

### ☐ Configure Environment Variables
```bash
cat > .env.example << 'EOF'
# Application
APP_NAME=MyProject
APP_ENV=development
DEBUG=true

# Server
HOST=0.0.0.0
PORT=20000

# Database
DATABASE_URL=sqlite:///./app.db

# Security
SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# External APIs (if needed)
# API_KEY=your-api-key
EOF

# Copy to actual .env
cp .env.example .env

# Generate secret key
python -c "import secrets; print(f'SECRET_KEY={secrets.token_urlsafe(32)}')"
```

### ☐ Set Up Configuration Module
```python
cat > src/config.py << 'EOF'
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    app_name: str = "FastAPI App"
    app_env: str = "development"
    debug: bool = True
    
    # Server
    host: str = "0.0.0.0"
    port: int = 20000
    
    # Database
    database_url: str = "sqlite:///./app.db"
    
    # Security
    secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 24
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
EOF
```

---

## Testing Setup

### ☐ Configure pytest
```ini
cat > pytest.ini << 'EOF'
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --strict-markers
    --tb=short
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80

markers =
    unit: Unit tests
    integration: Integration tests
    e2e: End-to-end tests
    slow: Slow tests
EOF
```

### ☐ Create Test Structure
```python
# Create conftest.py
cat > tests/conftest.py << 'EOF'
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from src.main import app
from src.database import Base, get_db

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function")
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
EOF

# Create first test
cat > tests/test_main.py << 'EOF'
def test_root_endpoint(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "API is running"}

def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
EOF
```

---

## Frontend Setup

### ☐ Create Base HTML
```html
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Name</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <nav>
            <h1>Project Name</h1>
        </nav>
    </header>
    
    <main>
        <section id="app">
            <h2>Welcome</h2>
            <p>Application is loading...</p>
        </section>
    </main>
    
    <footer>
        <p>&copy; 2024 Your Company. All rights reserved.</p>
    </footer>
    
    <script src="js/api.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
EOF
```

### ☐ Set Up API Client
```javascript
cat > frontend/js/api.js << 'EOF'
// API Client Module
const API = (() => {
    const BASE_URL = 'http://localhost:20000/api/v1';
    let authToken = localStorage.getItem('authToken');
    
    const request = async (endpoint, options = {}) => {
        const config = {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...(authToken && { 'Authorization': `Bearer ${authToken}` }),
                ...options.headers,
            },
        };
        
        try {
            const response = await fetch(`${BASE_URL}${endpoint}`, config);
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.detail || `HTTP ${response.status}`);
            }
            
            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    };
    
    return {
        get: (endpoint) => request(endpoint),
        post: (endpoint, data) => request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data),
        }),
        put: (endpoint, data) => request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data),
        }),
        delete: (endpoint) => request(endpoint, { method: 'DELETE' }),
        setAuthToken: (token) => {
            authToken = token;
            if (token) {
                localStorage.setItem('authToken', token);
            } else {
                localStorage.removeItem('authToken');
            }
        },
    };
})();
EOF
```

---

## Documentation

### ☐ Create Initial README
```markdown
cat > README.md << 'EOF'
# Project Name

## Overview
Brief description of what this project does and its value proposition.

## Quick Start

### Prerequisites
- Python 3.10+
- Git

### Installation
```bash
# Clone repository
git clone <repository-url>
cd project-name

# Set up Python environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment variables
cp .env.example .env
# Edit .env with your settings

# Run migrations (if applicable)
alembic upgrade head

# Start development server
uvicorn src.main:app --reload --port 20000
```

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src

# Run specific test category
pytest -m unit
```

## API Documentation
Once running, visit http://localhost:20000/docs for interactive API documentation.

## Project Structure
```
├── src/              # Application source code
├── tests/            # Test files
├── frontend/         # Frontend assets
├── docs/            # Additional documentation
└── scripts/         # Utility scripts
```

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License
[Your License] - see LICENSE file for details.
EOF
```

### ☐ Create Contributing Guide
```markdown
cat > CONTRIBUTING.md << 'EOF'
# Contributing Guidelines

## Development Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Write tests first (TDD)**
   - Create test file in appropriate directory
   - Write failing tests for new functionality
   - Run tests to ensure they fail

3. **Implement feature**
   - Write minimal code to pass tests
   - Refactor for clarity and efficiency
   - Ensure all tests pass

4. **Update documentation**
   - Update README if adding new features
   - Add docstrings to new functions
   - Update API documentation if applicable

5. **Format and lint code**
   ```bash
   black src/ tests/
   isort src/ tests/
   flake8 src/ tests/
   mypy src/
   ```

6. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

7. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Style
- Follow PEP 8 for Python
- Use meaningful variable names
- Add type hints to all functions
- Write clear docstrings

## Testing
- Maintain minimum 80% coverage
- Test edge cases
- Include integration tests for APIs
- Write E2E tests for critical flows

## Review Process
- All code requires review
- CI must pass
- Coverage must not decrease
- Documentation must be updated
EOF
```

---

## CI/CD Setup (Optional)

### ☐ GitHub Actions
```yaml
cat > .github/workflows/test.yml << 'EOF'
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Lint
      run: |
        flake8 src/ tests/
        black --check src/ tests/
        isort --check-only src/ tests/
    
    - name: Test
      run: |
        pytest --cov=src --cov-fail-under=80
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
EOF
```

---

## Launch Checklist

### ☐ Pre-Launch
- [ ] All tests passing
- [ ] Code coverage > 80%
- [ ] Documentation complete
- [ ] Environment variables documented
- [ ] Security review completed
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] API documentation generated

### ☐ First Commit
```bash
# Stage all files
git add .

# Create comprehensive first commit
git commit -m "feat: initial project setup with FastAPI, testing, and documentation

- Set up FastAPI application structure
- Configure SQLite database
- Add pytest testing framework
- Create frontend boilerplate
- Add comprehensive documentation
- Configure AI development rules"

# Create initial tag
git tag -a v0.1.0 -m "Initial project setup"
```

### ☐ Start Development Server
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Start FastAPI server
uvicorn src.main:app --reload --port 20000

# In another terminal, run tests in watch mode
pytest-watch

# View API docs at http://localhost:20000/docs
```

---

## Next Steps

1. **Implement Authentication**
   - User model and repository
   - JWT token generation
   - Protected routes

2. **Add Core Features**
   - Define your main entities
   - Create CRUD operations
   - Add business logic

3. **Enhance Frontend**
   - Create responsive design
   - Add interactive features
   - Implement error handling

4. **Prepare for Deployment**
   - Add Docker configuration
   - Set up environment configs
   - Create deployment scripts

---

## Troubleshooting

### Common Issues

**Port already in use:**
```bash
# Find process using port
lsof -i :20000
# Or use a different port
uvicorn src.main:app --reload --port 20001
```

**Import errors:**
```bash
# Ensure PYTHONPATH includes project root
export PYTHONPATH="${PYTHONPATH}:${PWD}"
```

**Database issues:**
```bash
# Reset database
rm app.db
# Recreate with migrations or initial schema
```

---

This checklist ensures consistent, high-quality project setup. Customize based on specific project needs, but maintain the core structure for optimal AI collaboration.
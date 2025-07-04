# AI Assistant Context and Rules

## Project Environment

**Tech Stack:**
- Backend: Python 3.10+, FastAPI
- Database: SQLite (default), PostgreSQL (for scale)
- AI SDKs: google-generativeai, anthropic
- Frontend: HTML, CSS, Vanilla JavaScript (or Vue/React when specified)
- Testing: pytest with coverage
- Deployment: Linux environments
- Ports: 20000+ range

**Target Context:**
- Users: SME businesses in Australia
- Scale: 10-1000 concurrent users
- Purpose: Productivity tools for efficiency and profitability
- Development approach: Test-driven, iterative

---

## Core Principles

### Code Quality
- Write clean, readable code that prioritizes maintainability
- Use type hints for all Python functions
- Include docstrings for public functions
- Follow PEP 8 for Python, modern ES6+ for JavaScript
- Implement proper error handling with meaningful messages

### Architecture
- Use repository pattern for data access
- Implement service layer for business logic
- Keep routes/controllers thin
- Use dependency injection where appropriate
- Separate concerns clearly

### Security First
- NEVER hardcode credentials or secrets
- ALWAYS validate user inputs
- Use parameterized database queries (no string concatenation)
- Implement proper authentication (JWT preferred)
- Hash passwords with bcrypt
- Return generic error messages to users

---

## Git Workflow

**Commit Format:**
```
type(scope): description

[optional body]
[optional footer]
```

**Types:** feat, fix, docs, style, refactor, test, chore

**Branching:**
- feature/description
- bugfix/issue-number
- hotfix/critical-issue

---

## Project Structure

```
project-root/
├── src/
│   ├── main.py          # FastAPI app
│   ├── config.py        # Settings
│   ├── models/          # Data models
│   ├── routes/          # API endpoints
│   ├── services/        # Business logic
│   ├── repositories/    # Data access
│   └── utils/          # Helpers
├── tests/              # Test files
├── frontend/           # UI assets
└── docs/              # Documentation
```

---

## Development Standards

### API Design
- Follow RESTful conventions
- Use appropriate HTTP status codes
- Implement pagination for lists
- Version APIs when needed
- Document all endpoints

### Testing Requirements
- Write tests BEFORE implementation (TDD)
- Minimum 80% code coverage
- Test happy paths and edge cases
- Include unit, integration, and E2E tests where appropriate

### Documentation
- Update README when adding features
- Document breaking changes
- Include usage examples
- Explain complex business logic

---

## Response Guidelines

### When implementing features:
1. Clarify ambiguous requirements
2. Consider test cases first
3. Implement incrementally
4. Ensure error handling
5. Update documentation

### When debugging:
1. Ask for specific error messages
2. Check common issues first
3. Provide diagnostic steps
4. Explain the solution

### Flexibility:
- Adapt patterns to specific project needs
- Prioritize clarity over strict adherence to patterns
- Ask for clarification when requirements conflict
- Suggest alternatives when appropriate

---

## Available Tools

**MCP Servers:**
- context7: Documentation lookups
- playwright: E2E testing
- jina: Web search/scraping
- unsplash: Image resources

**Usage:** Reference these when you need current documentation or external resources.

---

## Key Constraints

1. **Performance:** Optimize for SME scale, not enterprise
2. **Simplicity:** Prefer simple solutions that SME staff can understand
3. **Cost:** Consider hosting and maintenance costs
4. **Australian Context:** Consider local regulations (GST, privacy laws)

---

## Remember

- You're building tools for real businesses with real users
- Code quality matters more than feature quantity
- Always consider the maintenance burden
- When in doubt, ask for clarification
- Focus on solving the actual business problem
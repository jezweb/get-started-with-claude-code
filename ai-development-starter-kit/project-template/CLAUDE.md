# Project: [Name]

## The Problem
[One sentence - what problem does this solve?]

## The Solution
[One paragraph - how does this solve it?]

## 🔄 Project Awareness
- Always read PROJECT.md and PLANNING.md before starting work
- Check current status and todos below
- Follow established patterns in the codebase
- Look at existing similar features before building new ones

## 🧪 Testing Standards
- Write tests for new features using [pytest/jest/vitest]
- Test the happy path, edge cases, and error conditions
- Run tests before committing: `[test command]`
- Keep tests simple and focused

## ✅ Task Management
- Update PROJECT.md with completed tasks immediately
- Add new todos to PLANNING.md as you discover them
- Mark current work in progress clearly
- Break large tasks into smaller, testable pieces

## 🧠 AI Guidelines
- Ask questions if project context is unclear
- Don't assume libraries exist - check package.json/requirements.txt first
- Never delete existing code without explicit permission
- Explain what you're doing as you build
- Follow the existing code style and patterns

## 📁 Project Structure
- Keep files under 500 lines where possible
- Use clear, descriptive file and function names
- Group related functionality together
- Comment non-obvious business logic

## Tech Choices
- Language: [Python/JavaScript/etc]
- Framework: [FastAPI/Vue/etc - specific to THIS project]
- Database: [SQLite/PostgreSQL/etc]
- Hosting: [Local/Cloud/etc]

## Project Structure
- Main code: `app/` or `src/`
- Config: `.env` file (copy from `.env.example`)
- Tests: `tests/` folder - run with `[test command]`
- Docs: `docs/` folder
- Planning: `PROJECT.md` and `PLANNING.md`

## Key Files to Know
- `[main entry point]` - Where the app starts
- `[config file]` - Settings and configuration
- `[important feature]` - Core functionality
- `PROJECT.md` - Project status and decisions
- `PLANNING.md` - Current tasks and planning

## How to Run
1. [First step - e.g., install dependencies]
2. [Second step - e.g., set up database]
3. [Third step - e.g., start the server]
4. Run tests: `[test command]`

## 🔄 Development Workflow
1. Check PLANNING.md for current priorities
2. Create feature branch: `git checkout -b feature/[name]`
3. Write tests first (TDD approach)
4. Implement minimal code to pass tests
5. Refactor and improve
6. Update documentation
7. Commit with clear messages

## Status
- ✅ Working: [what's done and tested]
- 🚧 In Progress: [what's being built now]
- 📋 Planned: [what's coming next - see PLANNING.md]
- ⚠️ Known Issues: [what needs fixing]

## ⚙️ Configuration & Environment
- **Always use .env files** - Never hardcode API keys, URLs, or secrets
- **Copy .env.example to .env** and fill in your values
- **Document all variables** in .env.example with clear comments
- **Environment-specific settings**: Use different configs for dev/staging/prod
- **Common env variables**:
  - API keys (OPENAI_API_KEY, GOOGLE_AI_API_KEY, etc.)
  - Database URLs (DATABASE_URL)
  - App settings (PORT, HOST, DEBUG_MODE)
  - Feature flags (ENABLE_SIGNUP, ENABLE_PAYMENTS)
  - External service URLs and timeouts

## 🚫 Common Mistakes to Avoid
- **Hardcoding secrets** in source code
- **Committing .env files** to version control
- **Missing .env.example** template for new developers
- **No validation** of required environment variables
- **Inconsistent naming** of environment variables
- **No fallback values** for optional settings

## Special Notes
- [Any quirks or important things to remember]
- [Dependencies or integrations]
- [Performance considerations]
- [Testing gotchas or special setup needed]
- [Environment-specific configuration notes]
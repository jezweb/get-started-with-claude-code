# CLAUDE.md

This file helps Claude Code understand your project context and work effectively with your codebase.

## Project Context

### Tech Stack
- **Frontend**: [Vue 3 / React / vanilla JS - choose based on project]
- **Build Tool**: Vite (fast, modern, minimal config)
- **Styling**: Tailwind CSS / vanilla CSS
- **State**: Pinia (Vue) / Zustand (React) / Context API
- **Testing**: Vitest / Jest
- **Package Manager**: npm

### Code Style
- ES6+ modern JavaScript
- Async/await over promises
- Functional components (React/Vue)
- Clear, descriptive variable names
- Comments only when necessary

### Project Structure
src/
├── components/     # Reusable UI components
├── views/          # Page components
├── stores/         # State management
├── utils/          # Helper functions
├── styles/         # Global styles
└── main.js         # Entry point


### Development Guidelines
1. **Start Simple** - Get basic functionality working first
2. **Component-Based** - Break UI into reusable components
3. **State Management** - Keep state minimal and centralized
4. **Error Handling** - Always handle errors gracefully
5. **Performance** - Optimize only when needed

### Testing Approach
- Unit tests for utilities
- Component tests for UI logic
- E2E tests for critical paths
- Aim for practical coverage, not 100%

### Git Workflow
- Descriptive commit messages
- Feature branches for new work
- Test before committing
- Keep commits focused

## Quick Start
Use `kickoff-prompt.md` to start a new project or `/kickoff` command if available.

# Start New Project
<!-- VERSION: 1.0.0 -->

Help me plan and set up a new **$ARGUMENTS** project.

## First, let me understand your project:

1. **What are you building?** (Tell me about the project idea)
2. **Who will use it?** (Target users/audience)  
3. **Core features?** (What must it do?)

## Based on your needs, I'll:

### 1. Detect Existing Context
- Check for package.json, requirements.txt, Gemfile, etc.
- Look for .env files or configuration
- Identify any existing code patterns

### 2. Recommend Tech Stack
Based on what you're building, I'll suggest an appropriate stack:

**🐍 Python + AI Stack**
- Backend: Python 3.10+ + FastAPI + Uvicorn
- Database: SQLite (simple) or PostgreSQL (scalable)
- AI: Google Gemini API (gemini-2.5-flash for speed)
- Structure: Clean API-first architecture

**🟢 Node.js Stack**  
- Backend: Node.js + Express + TypeScript
- Database: PostgreSQL + Prisma ORM
- Testing: Jest + Supertest
- Structure: MVC with service layer

**⚛️ Modern Frontend**
- Framework: Vue 3 or React 18  
- Build: Vite (lightning fast)
- Styling: Tailwind CSS
- State: Pinia (Vue) or Zustand (React)

**🚀 Full-Stack**
- Any combination of the above
- Monorepo or separate repos
- Docker-ready setup

### 3. Create Project Structure
I'll create the perfect folder structure for your chosen stack.

### 4. Generate PROJECT.md
Tailored to your project with:
- Problem/solution clearly defined
- User stories based on your description  
- Progress tracking setup
- Tech decisions documented

### 5. Generate PLANNING.md  
With stack-specific tasks:
- Current sprint priorities
- Technical setup tasks
- Testing approach
- Deployment planning

### 6. Set Up Configuration
- Create .env.example with needed variables
- Add appropriate .gitignore
- Set up linting/formatting configs
- Add README with setup instructions

## Let's build something amazing!

Tell me about your project and I'll help you get started with the perfect setup.
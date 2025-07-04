# Create Your Own Custom Slash Command
<!-- VERSION: 1.0.0 -->

I want to create a custom slash command for Claude Code.

**What I want the command to do:**
[Describe what you want your command to help you with - e.g., "start a new project", "add a feature", "fix bugs", "deploy to production"]

**Command name:**
[What should I type after /user: to trigger it? Keep it short and memorable]

**Please help me:**

1. **Create the command file** in the right location (`~/.claude/commands/[name].md`)

2. **Write the prompt** that will help me with this task

3. **Show me examples** of other useful commands I might want to create

4. **Explain the syntax** so I can customize it or make more commands later

## 💡 Popular Command Ideas

Here are some commands other developers find useful:

**Project Management:**
- `/user:start-project` - Multi-stack project starter (Simple AI, Advanced AI, Mobile, React, etc.)
- `/user:add-feature` - Structured approach to adding features
- `/user:refactor` - Code cleanup and improvement guidance

**Development Workflow:** 
- `/user:fix-bug` - Debug and fix issues systematically
- `/user:write-tests` - Help create tests for existing code
- `/user:code-review` - Review code for best practices

**Deployment & DevOps:**
- `/user:deploy` - Deploy to staging/production safely
- `/user:setup-env` - Environment and dependency setup
- `/user:monitor` - Check app health and performance

**Learning & Explanation:**
- `/user:explain` - Break down complex code or concepts
- `/user:optimize` - Performance improvement suggestions
- `/user:security` - Security review and hardening

**Documentation:**
- `/user:document` - Create documentation for code/features
- `/user:readme` - Generate or update README files
- `/user:handover` - Prepare project handover documentation

## 🛠️ Command Syntax Tips

- **Keep names short** - you'll type them often
- **Use arguments** - `$ARGUMENTS` lets you pass context
- **Reference files** - `@filename` includes file content
- **Run commands** - `!command` executes bash commands
- **Be specific** - the more context, the better help you'll get

## 🚀 Pro Tip: Project Templates

Want to create a command like `/user:start-project` with multiple stack options? Here's how:

```markdown
# Start New Project

Help me create a **$ARGUMENTS** project.

## Choose a Stack:
1. **Simple AI** - Python + FastAPI + SQLite + Gemini API
2. **Advanced AI** - Vue + Python + LangChain + Vertex AI
3. **Mobile App** - React Native + Expo + TypeScript
4. **Website** - HTML + CSS + JavaScript + Vite
5. **React App** - React + TypeScript + Tailwind

Tell me what you're building and I'll recommend the best stack!
```

This lets you say things like:
- `/user:start-project inventory tracker` 
- `/user:start-project AI chatbot`
- `/user:start-project mobile shopping app`

Ready to create your first custom command?
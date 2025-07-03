# AI Development Starter Kit

A simple documentation system for product designers and idea people to build with AI assistants like Claude Code.

## 🎯 Who This Is For

- Product designers with ideas to build
- Business owners solving specific problems  
- Anyone who wants to create software without deep technical knowledge
- Teams that need clear handover documentation

## 🚀 Quick Start

### 1. One-Time Setup (5 minutes)

1. **Install Claude Code** (if you haven't already)
   ```bash
   npm install -g @anthropic/claude-code
   ```

2. **Set up your global preferences**
   ```bash
   # Copy the starter files to your home directory
   cp -r global-claude-setup/.claude ~/
   cp global-claude-setup/CLAUDE.md ~/.claude/
   cp global-claude-setup/settings.local.json ~/.claude/
   ```

3. **That's it!** Claude will now know your preferences across all projects.

### 2. Starting Your First Project

1. **Copy the project template**
   ```bash
   cp -r project-template my-awesome-idea
   cd my-awesome-idea
   ```

2. **Edit PROJECT.md** with your idea:
   - What problem does it solve?
   - Who will use it?
   - What should it do?

3. **Start building** with Claude:
   ```bash
   claude-code
   ```
   Then type: `/start-project` and follow the template

## 📁 What's Included

### Global Setup (One-time)
- **CLAUDE.md** - Your personal working preferences
- **settings.local.json** - Auto-approvals for common tasks
- **Mini prompts** - Templates for common requests:
  - `/start-project` - Begin a new project
  - `/fix-error` - Debug problems
  - `/add-feature` - Add new functionality
  - `/plan-and-code` - Advanced planning workflow
  - `/tdd-feature` - Test-driven development
  - `/feature-branch` - Professional git workflow
  - `/explain-code` - Understand existing code
  - `/make-it-live` - Deploy your project
  - `/test-everything` - Quality assurance
  - `/setup-env` - Configure environment files correctly

### Project Templates
- **CLAUDE.md** - Project-specific instructions and workflow guidance
- **PROJECT.md** - Your idea and progress tracker
- **PLANNING.md** - Task management and planning scratchpad
- **HANDOVER.md** - Documentation for users/developers

## 💡 How to Use Mini Prompts

Mini prompts are your starting point. Just type the command and fill in the blanks:

### Starting a Project
```
/start-project

I want to build something that [helps small businesses track inventory].
The users will be [shop owners and their staff].
It should:
- Track products in stock
- Alert when running low
- Generate simple reports
```

### Fixing Errors
```
/fix-error

I'm getting this error:
[paste the error message]

It happens when I [click the save button].
```

### Adding Features
```
/add-feature

I want to add [email notifications] that [alerts users when stock is low].
Users would:
- Set a threshold for each product
- Get daily summary emails
- Click to reorder directly
```

## 🔄 Advanced Workflow Patterns

Once you're comfortable with basic prompts, these advanced patterns help you work more efficiently:

### Planning → Compact → Code
```
/plan-and-code

I want to build [describe your feature in detail]
```

This follows the proven workflow:
1. **Plan thoroughly** with todos and markdown
2. **Compact context** to stay focused
3. **Implement systematically** with feature branches and testing

Perfect for larger features that need careful planning.

### Test-Driven Development
```
/tdd-feature

I want to add [feature name] that [does what]

Users will: [describe user interactions]
```

This approach:
1. **Writes tests first** (they'll fail initially)
2. **Implements minimal code** to pass tests
3. **Refactors and improves** the working code
4. **Documents** what was built

Great for ensuring your code actually works and is maintainable.

### Feature Branching
```
/feature-branch

Working on [feature name] that [brief description]
```

Professional workflow that:
1. **Creates dedicated branches** for each feature
2. **Keeps main branch clean** and deployable
3. **Enables easy collaboration** with pull requests
4. **Maintains project history** with clear commits

Essential when working with others or deploying regularly.

### Code Understanding
```
/explain-code

Can you explain what this code does? [paste code]
```

Helps you:
- **Understand existing code** before modifying it
- **Learn patterns** used in the project
- **Identify potential issues** or improvements
- **Document complex logic** for others

### Going Live
```
/make-it-live

I want to deploy [project name] for [target users]
Budget: [free/cheap/doesn't matter]
```

Guides you through:
- **Choosing the right hosting** for your needs
- **Setting up deployment** step-by-step
- **Configuring security** and performance
- **Planning updates** and maintenance

### Quality Assurance
```
/test-everything

Please test the project thoroughly
```

Ensures your project:
- **Works as expected** across different scenarios
- **Handles errors gracefully** when things go wrong
- **Performs well** under normal usage
- **Provides good user experience** on different devices

### Environment Setup
```
/setup-env

Help me configure this project's environment
```

Critical for avoiding common mistakes:
- **Secure configuration** with proper .env files
- **No hardcoded secrets** in source code
- **Environment-specific settings** for dev/staging/production
- **Proper API key management** and documentation

## 📝 Growing Your Documentation

### Start Simple
Begin with just the basic templates. Fill in only what you know.

### Add As You Learn
- Discover a preference? Add it to CLAUDE.md
- Make a decision? Note it in PROJECT.md
- Learn something useful? Update HANDOVER.md

### Create New Mini Prompts
Found yourself typing similar requests? Make a new prompt:
1. Create a file in `~/.claude/commands/your-prompt.md`
2. Add your template text
3. Use it with `/your-prompt`

## 🎨 Customization Tips

### For Different Tech Stacks
In your project's CLAUDE.md, specify:
```markdown
## Tech Choices
- Language: JavaScript  # or Python, Ruby, etc.
- Framework: Vue        # or React, FastAPI, etc.
- Database: PostgreSQL  # or MySQL, SQLite, etc.
```

### For Different Industries
Adjust PROJECT.md to include:
- Compliance requirements
- Industry-specific terms
- Regulatory considerations

### For Teams
- Share the project folder (including CLAUDE.md)
- Each person can have their own global preferences
- PROJECT.md becomes your shared understanding

## 🔒 Privacy & Security

### What's Shared
- Project CLAUDE.md is shared with your team
- PROJECT.md and HANDOVER.md are project documentation

### What's Private
- Your global ~/.claude/CLAUDE.md
- Your personal preferences
- Your command history

### Best Practices
- Never put passwords in documentation
- Use `.env` files for secrets
- Keep sensitive data out of prompts

## 🤝 Working with Developers

This system helps you hand over projects smoothly:

1. **HANDOVER.md** explains everything in plain English
2. **PROJECT.md** shows all decisions and progress
3. **The code itself** is organized and commented

Developers appreciate receiving:
- Clear problem statements
- Documented decisions
- Working prototypes
- User feedback

## 📚 Examples

### E-commerce Store
```markdown
# PROJECT.md
## The Idea
**Problem:** Local artisans can't easily sell online
**Solution:** Simple store builder with payment processing
**Users:** Artists, craftspeople, small manufacturers
```

### Internal Tool
```markdown
# PROJECT.md
## The Idea
**Problem:** HR spends hours on leave tracking
**Solution:** Self-service portal with automatic approvals
**Users:** Employees, managers, HR team
```

### Mobile App
```markdown
# PROJECT.md  
## The Idea
**Problem:** Tourists get lost in our city
**Solution:** Offline-first map with local recommendations
**Users:** Visitors, tourism board, local businesses
```

## ❓ Common Questions

**Q: Do I need to know how to code?**
A: No! Describe what you want in plain English.

**Q: What if I want to use different technology?**
A: Just specify in your project's CLAUDE.md file.

**Q: Can I use this with other AI assistants?**
A: Yes! The documentation structure works with any AI coding assistant.

**Q: How detailed should my descriptions be?**
A: Start simple. You can always add more detail as you learn what works.

**Q: What if I get stuck?**
A: Use the `/fix-error` prompt or start a fresh conversation with Claude.

## 🚦 Next Steps

1. **Try a simple project** - Start with something small
2. **Iterate on your prompts** - Adjust templates as you learn
3. **Share your experience** - Help others learn from what works
4. **Build your ideas** - Don't let technical barriers stop you

---

Remember: Every expert was once a beginner. This kit helps you start building immediately while learning as you go. Your ideas deserve to exist - let's build them together! 🎉
# Get Started with Claude Code

Start building with AI assistance in just 2 simple steps! This setup gives you a smooth development experience with Claude Code (or any AI assistant).

## 📋 Prerequisites

1. **Download this repository** (you've already done this!)
2. **Install Claude Code**: `npm install -g @anthropic-ai/claude-code`

## 🎯 Two-Step Setup

### Step 1: Personal Setup (One Time Only)

Set up your **personal preferences** that Claude will use across ALL your projects.

#### Option A: Simple Copy (No Command Line)
1. Navigate to the `personal-setup/` folder
2. Copy the `.claude/` folder to your home directory
   - **Windows**: Copy to `C:\Users\YourName\.claude\`
   - **Mac/Linux**: Copy to `~/.claude/`
3. Edit `~/.claude/CLAUDE.md` with YOUR information (name, preferences, etc.)

#### Option B: Command Line
```bash
# Copy personal setup files
cp -r personal-setup/.claude ~/
cp personal-setup/CLAUDE.md ~/.claude/
cp personal-setup/settings.local.json ~/.claude/

# Edit with your personal info
code ~/.claude/CLAUDE.md  # or nano, vim, etc.
```

### Step 2: New Project Setup (Every New Project)

For each new project, copy the **project template** files.

#### Option A: Simple Copy (No Command Line)
1. Create your new project folder
2. Copy all files from `new-project-template/` into your project folder
3. Edit `CLAUDE.md` in your project with the project details
4. Edit `PROJECT.md` with your project idea

#### Option B: Command Line
```bash
# Create new project
mkdir my-awesome-project
cd my-awesome-project

# Copy project template (including hidden files)
cp -r ../get-started-with-claude-code/get-started/new-project-template/* .
cp ../get-started-with-claude-code/get-started/new-project-template/.* . 2>/dev/null || true

# Edit project details
code CLAUDE.md     # Project-specific settings
code PROJECT.md    # Your project idea
```

## 🧠 Understanding the Two CLAUDE.md Files

This is important! There are **TWO different** CLAUDE.md files:

### 1. Personal CLAUDE.md (`~/.claude/CLAUDE.md`)
- **YOUR preferences**: Name, work style, tech preferences
- **Global settings**: Applies to ALL your projects
- **Location**: Your home directory (`~/.claude/`)
- **Contains**: Personal info, coding style, environment preferences

### 2. Project CLAUDE.md (in each project folder)
- **THIS PROJECT'S context**: What you're building, current status
- **Project-specific**: Only for this particular project
- **Location**: Inside each project folder
- **Contains**: Project goals, tech stack for THIS project, current todos

Think of it like this:
- **Personal CLAUDE.md** = "This is WHO I am and HOW I like to work"
- **Project CLAUDE.md** = "This is WHAT I'm building and WHERE we are"

## 🚀 Start Building

Once you've completed both steps:

1. Open your project folder in your terminal
2. Run `claude-code`
3. Try a mini-prompt like `/start-project` or just describe what you want to build!

Claude now knows:
- ✅ Your personal preferences and work style
- ✅ This specific project's context and goals
- ✅ Current progress and next steps

## 💡 What You Get

### Personal Setup Includes:
- **Global preferences** for all projects
- **Mini-prompt commands** like `/start-project`, `/fix-error`, `/add-feature`
- **Settings** for auto-approvals and tool permissions
- **Work style preferences** that Claude will remember

### Project Template Includes:
- **CLAUDE.md** - Project context template
- **PROJECT.md** - Project idea and progress tracker
- **PLANNING.md** - Task management scratchpad
- **docs/HANDOVER.md** - Documentation template
- **Environment files** - .env.example, .gitignore

## 🔄 Example Workflow

```bash
# 1. One-time setup (first time only)
cp -r personal-setup/.claude ~/
code ~/.claude/CLAUDE.md  # Add your info

# 2. Start new project
mkdir inventory-tracker
cd inventory-tracker
cp -r ../get-started/new-project-template/* .
cp ../get-started/new-project-template/.* . 2>/dev/null || true

# 3. Describe your project
code PROJECT.md  # "I want to build an inventory tracker for small shops..."

# 4. Start building with AI
claude-code
# Then type: "I want to build the inventory tracker described in PROJECT.md"
```

## 🎯 Next Steps

After setup, Claude will help you:
- Choose the right tech stack for your project
- Set up your development environment
- Write clean, well-structured code
- Follow best practices automatically
- Document as you build

## 🆘 Need Help?

- **Can't find files?** Make sure you're in the right directory
- **Claude doesn't remember you?** Check that `~/.claude/CLAUDE.md` exists and has your info
- **Project context missing?** Make sure `CLAUDE.md` and `PROJECT.md` are in your project folder
- **Commands not working?** Try restarting Claude Code

## 📚 Advanced Usage

Once comfortable with the basics, explore:
- **Custom mini-prompts** in `~/.claude/commands/`
- **Advanced workflows** like TDD, feature branching
- **Team collaboration** patterns
- **Integration with existing projects**

---

**You're all set!** Claude now knows who you are, how you like to work, and what you're building. Time to create something amazing! 🚀
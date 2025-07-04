# Get Started with Claude Code

The simplest setup for AI-powered development. Just 2 files to copy, then start building!

## 🚀 Super Simple Setup

### Prerequisites
- Install Claude Code: `npm install -g @anthropic-ai/claude-code`
- Download this repository (you've already done this!)

### Step 1: Copy 2 Files (One Time Only)

Copy the personal setup files to your home directory:

**Option A: Drag & Drop (No Command Line)**
1. Navigate to `personal-setup/.claude/` folder
2. Copy the entire `.claude` folder to your home directory:
   - **Windows**: Copy to `C:\Users\YourName\.claude\`
   - **Mac/Linux**: Copy to `~/.claude/`
3. Edit `~/.claude/CLAUDE.md` with YOUR personal information

**Option B: Command Line**
```bash
# Copy personal setup
cp -r personal-setup/.claude ~/

# Edit with your info
code ~/.claude/CLAUDE.md  # or nano, vim, etc.
```

### Step 2: Start Building

```bash
# Create any project folder
mkdir my-awesome-project
cd my-awesome-project

# Start Claude Code
claude-code

# Try your first command
/user:make-command
```

## 🎯 What You Get

### Essential Files:
- **CLAUDE.md** - Your personal AI assistant profile (work style, preferences, tech choices)
- **settings.local.json** - Reduces annoying approval prompts for safe operations
- **make-command.md** - One slash command that teaches you to create your own commands

### Your First Command: `/user:make-command`
This special command helps you create custom slash commands for YOUR specific needs:
- `/user:start-project` - Project kickoff helper
- `/user:add-feature` - Feature development workflow  
- `/user:fix-bug` - Debugging and fixing issues
- `/user:deploy` - Deployment assistance
- And whatever else you need!

## 💡 Why This Approach?

**Learning by Doing**: Instead of giving you dozens of pre-made commands, you'll learn to create exactly what YOU need.

**No Confusion**: No complex folder structures, no decision paralysis, no wondering "what do I copy?"

**Personalized**: Your commands, your workflow, your style.

## 🛠️ Example Workflow

```bash
# 1. One-time setup
cp -r personal-setup/.claude ~/
code ~/.claude/CLAUDE.md  # Add your name, preferences, etc.

# 2. Start any project
mkdir inventory-tracker
cd inventory-tracker
claude-code

# 3. Create your first custom command
/user:make-command
# Tell it: "I want a command to help me start new projects"

# 4. Use your new command
/user:start-project
# Describe your project idea and let Claude help!
```

## 🎉 Next Steps

After setup:
1. **Try `/user:make-command`** to create your first custom slash command
2. **Describe what you want to build** and let Claude guide you
3. **Create more commands** as you discover patterns in your workflow
4. **Build amazing projects** with your AI pair programmer!

## 🆘 Need Help?

- **Commands not working?** Make sure `.claude/` folder is in your home directory
- **Claude doesn't know you?** Check that `CLAUDE.md` has your personal info
- **Too many approval prompts?** The `settings.local.json` should help with that
- **Want inspiration?** Try `/user:make-command` and see the suggested command ideas

---

**That's it!** No complex templates, no decision paralysis. Just copy 2 files and start building with your AI assistant. 🚀

**Pro tip**: The `/user:make-command` command is like a meta-prompt that teaches you to create the exact development workflow you want. Use it whenever you think "I wish Claude could help me with..."
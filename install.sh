#!/bin/bash
# Claude Code Smart Installer - Simple and Robust
# One-line install: curl -sSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Print colored message
print_msg() {
    local color=$1
    shift
    printf "${color}%s${NC}\n" "$*"
}

print_msg "$BLUE" "Claude Code Smart Installer"
print_msg "$BLUE" "============================"
printf "\n"

# Download files
print_msg "$BLUE" "Downloading setup files..."
temp_dir=$(mktemp -d)
cd "$temp_dir"
curl -sSL https://github.com/jezweb/get-started-with-claude-code/archive/main.tar.gz | tar xz
setup_dir="get-started-with-claude-code-main/get-started/personal-setup/.claude"

# Check if first time or update
if [ ! -d "$HOME/.claude" ]; then
    # Fresh install
    print_msg "$GREEN" "First time setup detected!"
    cp -r "$setup_dir" "$HOME/"
    printf "\n"
    print_msg "$GREEN" "Installation complete!"
    printf "\n"
    print_msg "$YELLOW" "IMPORTANT: Personalize your setup:"
    print_msg "$GREEN" "  nano ~/.claude/CLAUDE.md"
else
    # Existing installation - check what needs updating
    print_msg "$CYAN" "Welcome back! Checking your existing setup..."
    printf "\n"
    
    # Check each file
    needs_update=false
    
    # Check CLAUDE.md
    if [ ! -f "$HOME/.claude/CLAUDE.md" ]; then
        print_msg "$YELLOW" "CLAUDE.md: Missing"
        cp "$setup_dir/CLAUDE.md" "$HOME/.claude/"
        print_msg "$GREEN" "  [+] Added CLAUDE.md"
        needs_update=true
    else
        print_msg "$GREEN" "CLAUDE.md: Found"
    fi
    
    # Check settings.local.json
    if [ ! -f "$HOME/.claude/settings.local.json" ]; then
        print_msg "$YELLOW" "settings.local.json: Missing"
        cp "$setup_dir/settings.local.json" "$HOME/.claude/"
        print_msg "$GREEN" "  [+] Added settings.local.json"
        needs_update=true
    else
        print_msg "$GREEN" "settings.local.json: Found"
    fi
    
    # Check make-command.md
    if [ ! -f "$HOME/.claude/commands/make-command.md" ]; then
        print_msg "$YELLOW" "commands/make-command.md: Missing"
        mkdir -p "$HOME/.claude/commands"
        cp "$setup_dir/commands/make-command.md" "$HOME/.claude/commands/"
        print_msg "$GREEN" "  [+] Added make-command.md"
        needs_update=true
    else
        print_msg "$GREEN" "commands/make-command.md: Found"
    fi
    
    if [ "$needs_update" = false ]; then
        printf "\n"
        print_msg "$GREEN" "Your setup is complete!"
        printf "\n"
        print_msg "$BLUE" "Try creating a new command:"
        print_msg "$GREEN" "  cd your-project && claude-code"
        print_msg "$GREEN" "  /user:make-command"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 0
    fi
    
    printf "\n"
    print_msg "$GREEN" "Update complete!"
fi

# Ask about essential commands
printf "\n"
print_msg "$BLUE" "Essential Commands"
print_msg "$NC" "Would you like to install 5 essential commands? (recommended)"
print_msg "$NC" "These smart commands adapt to any project:"
print_msg "$NC" "  - start-project - Smart project setup"
print_msg "$NC" "  - add-feature - Add features following patterns"
print_msg "$NC" "  - fix-bug - Debug systematically"
print_msg "$NC" "  - write-tests - Create comprehensive tests"
print_msg "$NC" "  - deploy - Deploy to production"
printf "\n"

printf "Install essential commands? (Y/n) "
read -r REPLY
if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]; then
    printf "\n"
    print_msg "$BLUE" "Installing essential commands..."
    printf "\n"
    
    mkdir -p "$HOME/.claude/commands"
    
    # Create start-project command
    cat > "$HOME/.claude/commands/start-project.md" << 'EOF'
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

**[Python + AI Stack]**
- Backend: Python 3.10+ + FastAPI + Uvicorn
- Database: SQLite (simple) or PostgreSQL (scalable)
- AI: Google Gemini API (gemini-2.5-flash for speed)
- Structure: Clean API-first architecture

**[Node.js Stack]**  
- Backend: Node.js + Express + TypeScript
- Database: PostgreSQL + Prisma ORM
- Testing: Jest + Supertest
- Structure: MVC with service layer

**[Modern Frontend]**
- Framework: Vue 3 or React 18  
- Build: Vite (lightning fast)
- Styling: Tailwind CSS
- State: Pinia (Vue) or Zustand (React)

**[Full-Stack]**
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
EOF
    print_msg "$GREEN" "  [+] Installed start-project.md"
    
    # Create add-feature command
    cat > "$HOME/.claude/commands/add-feature.md" << 'EOF'
# Add Feature
<!-- VERSION: 1.0.0 -->

I want to add **$ARGUMENTS** to the project.

## Let me help you build this feature properly:

### 1. First, I'll understand:
- Current project structure and patterns
- Existing similar features to follow conventions
- Tech stack and frameworks in use
- Testing approach

### 2. Plan the implementation:
- Break down the feature into components
- Identify dependencies and integrations
- Consider edge cases and error handling
- Plan the testing strategy

### 3. Build incrementally:
- Start with the core functionality
- Add proper error handling
- Include logging where appropriate
- Write tests alongside the code
- Update documentation

### 4. Follow project patterns:
- Match existing code style
- Use established naming conventions
- Integrate with current architecture
- Maintain consistency

## What I need from you:
- Describe how users will interact with this feature
- Any specific requirements or constraints
- Should this integrate with existing features?
- Any performance or security considerations?

Let's build this feature the right way!
EOF
    print_msg "$GREEN" "  [+] Installed add-feature.md"
    
    # Create fix-bug command
    cat > "$HOME/.claude/commands/fix-bug.md" << 'EOF'
# Fix Bug
<!-- VERSION: 1.0.0 -->

Help me fix: **$ARGUMENTS**

## Let's debug this systematically:

### 1. Understand the problem:
- What's the expected behavior?
- What's actually happening?
- When did this start?
- Can you reproduce it consistently?

### 2. Investigate:
- Check error messages and logs
- Identify the code path involved
- Look for recent changes
- Test edge cases

### 3. Fix approach:
- Isolate the root cause
- Implement the minimal fix
- Add tests to prevent regression
- Verify the fix doesn't break other features

### 4. Document:
- Comment why the fix was needed
- Update any affected documentation
- Add to test suite

## Share with me:
- Error messages or stack traces
- Steps to reproduce
- Any code you suspect is involved
- What you've already tried

Let's solve this together!
EOF
    print_msg "$GREEN" "  [+] Installed fix-bug.md"
    
    # Create write-tests command
    cat > "$HOME/.claude/commands/write-tests.md" << 'EOF'
# Write Tests
<!-- VERSION: 1.0.0 -->

Write tests for **$ARGUMENTS**

## Let's create comprehensive tests:

### 1. Identify test framework:
- Check existing test setup (Jest, pytest, vitest, etc.)
- Follow established patterns
- Use appropriate test utilities

### 2. Test coverage strategy:
- **Happy path** - Normal expected usage
- **Edge cases** - Boundary conditions
- **Error cases** - Invalid inputs, failures
- **Integration** - How components work together

### 3. Test structure:
- Clear test descriptions
- Arrange-Act-Assert pattern
- Isolated test cases
- Meaningful assertions

### 4. Best practices:
- Keep tests simple and focused
- Make tests deterministic
- Use meaningful test data
- Mock external dependencies appropriately

## What to test:
- Core functionality
- Input validation
- Error handling
- State changes
- Side effects

Let me analyze the code and write appropriate tests!
EOF
    print_msg "$GREEN" "  [+] Installed write-tests.md"
    
    # Create deploy command
    cat > "$HOME/.claude/commands/deploy.md" << 'EOF'
# Deploy Project
<!-- VERSION: 1.0.0 -->

Help me deploy **$ARGUMENTS**

## Let's get your project live:

### 1. Pre-deployment checklist:
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Static assets optimized
- [ ] Security headers configured
- [ ] Error monitoring setup

### 2. Deployment options:

**[Simple (Free/Low Cost)]**
- Vercel/Netlify (frontend)
- Railway/Render (backend)
- Supabase/Neon (database)

**[Scalable]**
- AWS/Google Cloud/Azure
- Docker containers
- Kubernetes orchestration

**[Specific Platforms]**
- Heroku (easy but paid)
- DigitalOcean App Platform
- Fly.io (global edge)

### 3. Setup steps:
- Configure deployment platform
- Set environment variables
- Set up CI/CD pipeline
- Configure domain/SSL
- Set up monitoring

### 4. Post-deployment:
- Verify all features work
- Check performance
- Monitor errors
- Set up backups

## Tell me:
- Where do you want to deploy?
- Budget constraints?
- Expected traffic?
- Any specific requirements?

Let's get your project live!
EOF
    print_msg "$GREEN" "  [+] Installed deploy.md"
    
    printf "\n"
    print_msg "$GREEN" "Commands ready!"
    INSTALLED_COMMANDS=true
else
    print_msg "$YELLOW" "Skipping essential commands."
    print_msg "$NC" "You can always create custom commands with /user:make-command"
    INSTALLED_COMMANDS=false
fi

# Final message
printf "\n"
print_msg "$BLUE" "Ready to build with AI!"
printf "\n"
print_msg "$CYAN" "Quick start:"
print_msg "$GREEN" "1. cd your-project"
print_msg "$GREEN" "2. claude-code"
if [ "$INSTALLED_COMMANDS" = true ]; then
    print_msg "$GREEN" "3. /user:start-project (smart project setup)"
else
    print_msg "$GREEN" "3. /user:make-command (create custom commands)"
fi
printf "\n"
print_msg "$BLUE" "Learn more: https://github.com/jezweb/get-started-with-claude-code"

# Cleanup
cd - > /dev/null 2>&1 || true
rm -rf "$temp_dir"
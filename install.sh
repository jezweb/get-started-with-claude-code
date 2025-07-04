#!/bin/bash
# Claude Code Smart Installer - Works for new AND existing users
# One-line install: curl -sSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | bash

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error handler
trap 'echo -e "\n${RED}Error occurred. Installation may be incomplete.${NC}"' ERR

echo -e "${BLUE}Claude Code Smart Installer${NC}"
echo -e "${BLUE}============================${NC}"
printf "\n"

# Helper Functions
backup_if_needed() {
    local file=$1
    if [ -f "$file" ]; then
        backup_name="$file.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        echo -e "   ${BLUE}Backed up to: $(basename $backup_name)${NC}"
    fi
}

check_make_command_version() {
    if [ -f "$HOME/.claude/commands/make-command.md" ]; then
        # Check for version tag in both files
        local_version=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$HOME/.claude/commands/make-command.md" 2>/dev/null || echo "0.0.0")
        github_version=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$setup_dir/commands/make-command.md" 2>/dev/null || echo "0.0.0")
        
        # Compare versions (simple string comparison for now)
        if [ "$local_version" = "0.0.0" ] || [ "$github_version" = "0.0.0" ]; then
            # No version found, fall back to checksum comparison
            local_hash=$(md5sum "$HOME/.claude/commands/make-command.md" 2>/dev/null | cut -d' ' -f1)
            github_hash=$(md5sum "$setup_dir/commands/make-command.md" 2>/dev/null | cut -d' ' -f1)
            
            if [ "$local_hash" != "$github_hash" ]; then
                echo "newer_available"
            else
                echo "up_to_date"
            fi
        elif [ "$local_version" != "$github_version" ]; then
            echo "newer_available"
        else
            echo "up_to_date"
        fi
    else
        echo "missing"
    fi
}

validate_claude_structure() {
    if [ -f "$HOME/.claude/CLAUDE.md" ]; then
        # Check for expected headings that indicate our template structure
        has_personal_info=$(grep -q "## Personal Information" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo "yes" || echo "no")
        has_dev_env=$(grep -q "## Development Environment" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo "yes" || echo "no")
        has_interaction_prefs=$(grep -q "## Claude Interaction Preferences" "$HOME/.claude/CLAUDE.md" 2>/dev/null && echo "yes" || echo "no")
        
        if [ "$has_personal_info" = "yes" ] && [ "$has_dev_env" = "yes" ]; then
            echo "valid_structure"
        else
            echo "different_structure"
        fi
    else
        echo "missing"
    fi
}

validate_settings() {
    if [ -f "$HOME/.claude/settings.local.json" ]; then
        # Check for key settings that indicate our template
        has_auto_approval=$(grep -q "autoApproval" "$HOME/.claude/settings.local.json" 2>/dev/null && echo "yes" || echo "no")
        has_permissions=$(grep -q "permissions" "$HOME/.claude/settings.local.json" 2>/dev/null && echo "yes" || echo "no")
        
        if [ "$has_auto_approval" = "yes" ] || [ "$has_permissions" = "yes" ]; then
            echo "valid"
        else
            echo "different_format"
        fi
    else
        echo "missing"
    fi
}

# Check if Claude Code is installed (optional check)
if [ -z "${SKIP_CLAUDE_CHECK:-}" ]; then
    claude_found=false
    
    # Try multiple detection methods
    if command -v claude-code &> /dev/null || \
       which claude-code &> /dev/null 2>&1 || \
       npm list -g @anthropic-ai/claude-code &> /dev/null 2>&1; then
        claude_found=true
    fi
    
    if [ "$claude_found" = false ]; then
        echo -e "${YELLOW}WARNING: Claude Code not detected in PATH${NC}"
        echo -e "\nThis might happen if:"
        echo -e "  - npm global binaries aren't in your PATH"
        echo -e "  - You installed it in a different shell"
        echo -e "  - The PATH isn't fully loaded yet"
        echo -e "\nIf you've already installed Claude Code, you can continue."
        echo -e "If not, install it with: ${GREEN}npm install -g @anthropic-ai/claude-code${NC}"
        echo
        read -p "Continue anyway? (y/N) " -n 1 -r
        printf "\n"
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            echo -e "\n${BLUE}Tip:${NC} You can skip this check with:"
            echo -e "${GREEN}SKIP_CLAUDE_CHECK=1 curl -sSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | bash${NC}"
            exit 1
        fi
    fi
fi

# Download files to temp directory first
echo -e "${BLUE}Downloading setup files...${NC}"
temp_dir=$(mktemp -d)
cd "$temp_dir"
curl -sSL https://github.com/jezweb/get-started-with-claude-code/archive/main.tar.gz | tar xz
setup_dir="get-started-with-claude-code-main/get-started/personal-setup/.claude"

# Check installation status
if [ ! -d "$HOME/.claude" ]; then
    # SCENARIO 1: Fresh install
    echo -e "${GREEN}First time setup detected!${NC}"
    echo -e "${BLUE}Creating ~/.claude with all files...${NC}"
    
    cp -r "$setup_dir" "$HOME/"
    
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo -e "\n${YELLOW}IMPORTANT: Personalize your setup:${NC}"
    echo -e "   ${GREEN}nano ~/.claude/CLAUDE.md${NC} (or use your favorite editor)"
    echo -e "\n${BLUE}Then start any project:${NC}"
    echo -e "   ${GREEN}cd your-project && claude-code${NC}"
    echo -e "   ${GREEN}/user:make-command${NC} (to create custom commands)"
    
else
    # SCENARIO 2: Existing installation
    echo -e "${CYAN}Welcome back! Checking your existing setup...${NC}\n"
    
    # Check if CLAUDE.md exists and validate structure
    claude_status="missing"
    claude_structure="unknown"
    if [ -f "$HOME/.claude/CLAUDE.md" ]; then
        # First check if it's still a template
        if grep -q "\[Your Name" "$HOME/.claude/CLAUDE.md" 2>/dev/null || \
           grep -q "\[Your Title" "$HOME/.claude/CLAUDE.md" 2>/dev/null || \
           grep -q "\[your.email@example.com\]" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
            claude_status="template"
            echo -e "CLAUDE.md: ${YELLOW}Found (still using template)${NC}"
        else
            claude_status="personalized"
            # Check structure
            claude_structure=$(validate_claude_structure)
            if [ "$claude_structure" = "valid_structure" ]; then
                echo -e "CLAUDE.md: ${GREEN}Found (personalized)${NC}"
            else
                echo -e "CLAUDE.md: ${YELLOW}Found (different format)${NC}"
                echo -e "   ${CYAN}Your file might be from an older version or customized${NC}"
            fi
        fi
    else
        echo -e "CLAUDE.md: ${YELLOW}Missing${NC}"
    fi
    
    # Check settings.local.json and validate
    settings_status=$(validate_settings)
    if [ "$settings_status" = "valid" ]; then
        echo -e "settings.local.json: ${GREEN}Found${NC}"
        settings_exists=true
    elif [ "$settings_status" = "different_format" ]; then
        echo -e "settings.local.json: ${YELLOW}Found (different format)${NC}"
        settings_exists=true
    else
        echo -e "settings.local.json: ${YELLOW}Missing${NC}"
        settings_exists=false
    fi
    
    # Check make-command.md version
    make_command_status=$(check_make_command_version)
    if [ "$make_command_status" = "newer_available" ]; then
        echo -e "commands/make-command.md: ${YELLOW}Found (update available)${NC}"
        make_command_exists=true
        make_command_outdated=true
    elif [ "$make_command_status" = "up_to_date" ]; then
        echo -e "commands/make-command.md: ${GREEN}Found (up to date)${NC}"
        make_command_exists=true
        make_command_outdated=false
    elif [ "$make_command_status" = "unknown" ]; then
        echo -e "commands/make-command.md: ${GREEN}Found${NC}"
        make_command_exists=true
        make_command_outdated=false
    else
        if [ -d "$HOME/.claude/commands" ]; then
            echo -e "commands/make-command.md: ${YELLOW}Missing${NC}"
        else
            echo -e "commands/: ${YELLOW}Missing${NC}"
        fi
        make_command_exists=false
        make_command_outdated=false
    fi
    
    echo -e "\n${BLUE}Actions needed:${NC}"
    actions_needed=false
    
    # Determine what needs to be done
    if [ "$claude_status" = "missing" ]; then
        echo -e "   - Add CLAUDE.md template"
        actions_needed=true
    elif [ "$claude_status" = "template" ]; then
        echo -e "   - Your CLAUDE.md still has template placeholders"
        echo -e "     ${YELLOW}Please personalize it after installation!${NC}"
    elif [ "$claude_structure" = "different_structure" ]; then
        echo -e "   - Your CLAUDE.md has a different structure"
        echo -e "     ${CYAN}This is OK if it's working for you!${NC}"
    fi
    
    if [ "$settings_exists" = false ]; then
        echo -e "   - Add settings.local.json (reduces approval prompts)"
        actions_needed=true
    elif [ "$settings_status" = "different_format" ]; then
        echo -e "   - Your settings.local.json has a different format"
        echo -e "     ${CYAN}This is OK if it's working for you!${NC}"
    fi
    
    if [ "$make_command_exists" = false ]; then
        echo -e "   - Add make-command.md (teaches custom commands)"
        actions_needed=true
    elif [ "$make_command_outdated" = true ]; then
        echo -e "   - Update make-command.md to latest version"
        echo -e "     ${CYAN}New features and improvements available!${NC}"
        actions_needed=true
    fi
    
    if [ "$actions_needed" = false ] && [ "$claude_status" = "personalized" ]; then
        echo -e "   ${GREEN}None! Your setup is complete.${NC}"
        echo -e "\n${BLUE}Try creating a new command:${NC}"
        echo -e "   ${GREEN}cd your-project && claude-code${NC}"
        echo -e "   ${GREEN}/user:make-command${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 0
    fi
    
    # Ask before proceeding
    printf "\n"
    read -p "Proceed with updates? (Y/n) " -n 1 -r
    printf "\n"
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [ -n "$REPLY" ]; then
        echo -e "${YELLOW}Installation cancelled. No changes made.${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 0
    fi
    
    # Perform updates
    echo -e "\n${BLUE}Updating your setup...${NC}"
    
    # Add CLAUDE.md if missing
    if [ "$claude_status" = "missing" ]; then
        cp "$setup_dir/CLAUDE.md" "$HOME/.claude/"
        echo -e "   ${GREEN}[+]${NC} Added CLAUDE.md template"
    fi
    
    # Add settings.local.json if missing
    if [ "$settings_exists" = false ]; then
        cp "$setup_dir/settings.local.json" "$HOME/.claude/"
        echo -e "   ${GREEN}[+]${NC} Added settings.local.json"
    fi
    
    # Handle make-command.md updates
    if [ "$make_command_exists" = false ]; then
        mkdir -p "$HOME/.claude/commands"
        cp "$setup_dir/commands/make-command.md" "$HOME/.claude/commands/"
        echo -e "   ${GREEN}[+]${NC} Added make-command.md"
    elif [ "$make_command_outdated" = true ]; then
        # Get version info for display
        local_ver=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$HOME/.claude/commands/make-command.md" 2>/dev/null || echo "unknown")
        github_ver=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$setup_dir/commands/make-command.md" 2>/dev/null || echo "1.0.0")
        
        echo -e "\n${YELLOW}Update available for make-command.md${NC}"
        echo -e "Current version: ${CYAN}$local_ver${NC} -> New version: ${GREEN}$github_ver${NC}"
        echo -e "New features: Better project templates, enhanced examples"
        read -p "Update to latest version? (Y/n) " -n 1 -r
        printf "\n"
        if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
            backup_if_needed "$HOME/.claude/commands/make-command.md"
            cp "$setup_dir/commands/make-command.md" "$HOME/.claude/commands/"
            echo -e "   ${GREEN}[*]${NC} Updated make-command.md"
        else
            echo -e "   ${YELLOW}[-]${NC} Skipped make-command.md update"
        fi
    fi
    
    echo -e "\n${GREEN}Update complete!${NC}"
    
    # Remind about personalization if needed
    if [ "$claude_status" != "personalized" ]; then
        echo -e "\n${YELLOW}Don't forget to personalize:${NC}"
        echo -e "   ${GREEN}nano ~/.claude/CLAUDE.md${NC}"
    fi
fi

# Function to create command files
create_command() {
    local name=$1
    local version=$2
    local content=$3
    local dest_file="$HOME/.claude/commands/${name}.md"
    
    if [ -f "$dest_file" ]; then
        # Check version
        local_ver=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$dest_file" 2>/dev/null || echo "0.0.0")
        if [ "$local_ver" != "$version" ]; then
            echo "$content" > "$dest_file"
            echo -e "   ${GREEN}[*]${NC} Updated ${name}.md (${local_ver} -> ${version})"
            return 1
        else
            echo -e "   ${BLUE}[-]${NC} ${name}.md already up to date"
            return 2
        fi
    else
        echo "$content" > "$dest_file"
        echo -e "   ${GREEN}[+]${NC} Installed ${name}.md"
        return 0
    fi
}

# Ask about essential commands
echo -e "\n${BLUE}Essential Commands${NC}"
echo -e "Would you like to install 5 essential commands? (recommended)"
echo -e "These smart commands adapt to any project:"
echo -e "  - start-project - Smart project setup"
echo -e "  - add-feature - Add features following patterns"
echo -e "  - fix-bug - Debug systematically"
echo -e "  - write-tests - Create comprehensive tests"
echo -e "  - deploy - Deploy to production\n"

read -p "Install essential commands? (Y/n) " -n 1 -r
printf "\n"
if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
    echo -e "\n${BLUE}Installing essential commands...${NC}\n"
    
    # Install each command
    cmd_installed=0
    cmd_updated=0
    cmd_skipped=0
    
    # Create start-project command
    create_command "start-project" "1.0.0" '# Start New Project
<!-- VERSION: 1.0.0 -->

Help me plan and set up a new **$ARGUMENTS** project.

## First, let me understand your project:

1. **What are you building?** (Tell me about the project idea)
2. **Who will use it?** (Target users/audience)  
3. **Core features?** (What must it do?)

## Based on your needs, I'\''ll:

### 1. Detect Existing Context
- Check for package.json, requirements.txt, Gemfile, etc.
- Look for .env files or configuration
- Identify any existing code patterns

### 2. Recommend Tech Stack
Based on what you'\''re building, I'\''ll suggest an appropriate stack:

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
I'\''ll create the perfect folder structure for your chosen stack.

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

## Let'\''s build something amazing!

Tell me about your project and I'\''ll help you get started with the perfect setup.'
    result=$?
    [ $result -eq 0 ] && ((cmd_installed++))
    [ $result -eq 1 ] && ((cmd_updated++))
    [ $result -eq 2 ] && ((cmd_skipped++))
    
    # Create add-feature command
    create_command "add-feature" "1.0.0" '# Add Feature
<!-- VERSION: 1.0.0 -->

I want to add **$ARGUMENTS** to the project.

## Let me help you build this feature properly:

### 1. First, I'\''ll understand:
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

Let'\''s build this feature the right way!'
    result=$?
    [ $result -eq 0 ] && ((cmd_installed++))
    [ $result -eq 1 ] && ((cmd_updated++))
    [ $result -eq 2 ] && ((cmd_skipped++))
    
    # Create fix-bug command
    create_command "fix-bug" "1.0.0" '# Fix Bug
<!-- VERSION: 1.0.0 -->

Help me fix: **$ARGUMENTS**

## Let'\''s debug this systematically:

### 1. Understand the problem:
- What'\''s the expected behavior?
- What'\''s actually happening?
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
- Verify the fix doesn'\''t break other features

### 4. Document:
- Comment why the fix was needed
- Update any affected documentation
- Add to test suite

## Share with me:
- Error messages or stack traces
- Steps to reproduce
- Any code you suspect is involved
- What you'\''ve already tried

Let'\''s solve this together!'
    result=$?
    [ $result -eq 0 ] && ((cmd_installed++))
    [ $result -eq 1 ] && ((cmd_updated++))
    [ $result -eq 2 ] && ((cmd_skipped++))
    
    # Create write-tests command
    create_command "write-tests" "1.0.0" '# Write Tests
<!-- VERSION: 1.0.0 -->

Write tests for **$ARGUMENTS**

## Let'\''s create comprehensive tests:

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

Let me analyze the code and write appropriate tests!'
    result=$?
    [ $result -eq 0 ] && ((cmd_installed++))
    [ $result -eq 1 ] && ((cmd_updated++))
    [ $result -eq 2 ] && ((cmd_skipped++))
    
    # Create deploy command
    create_command "deploy" "1.0.0" '# Deploy Project
<!-- VERSION: 1.0.0 -->

Help me deploy **$ARGUMENTS**

## Let'\''s get your project live:

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

Let'\''s get your project live!'
    result=$?
    [ $result -eq 0 ] && ((cmd_installed++))
    [ $result -eq 1 ] && ((cmd_updated++))
    [ $result -eq 2 ] && ((cmd_skipped++))
    
    if [ $cmd_installed -gt 0 ] || [ $cmd_updated -gt 0 ]; then
        echo -e "\n${GREEN}Commands ready!${NC}"
        echo -e "   Installed: ${cmd_installed}, Updated: ${cmd_updated}, Skipped: ${cmd_skipped}"
    fi
else
    echo -e "${YELLOW}Skipping essential commands.${NC}"
    echo -e "You can always create custom commands with ${GREEN}/user:make-command${NC}"
fi

# Common ending message
echo -e "\n${BLUE}Ready to build with AI!${NC}"
echo -e "\n${CYAN}Quick start:${NC}"
echo -e "1. ${GREEN}cd your-project${NC}"
echo -e "2. ${GREEN}claude-code${NC}"
if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
    echo -e "3. ${GREEN}/user:start-project${NC} (smart project setup)"
else
    echo -e "3. ${GREEN}/user:make-command${NC} (create custom commands)"
fi

echo -e "\n${BLUE}Learn more:${NC} https://github.com/jezweb/get-started-with-claude-code"

# Cleanup
cd - > /dev/null 2>&1 || true
rm -rf "$temp_dir"

# Clean exit
exit 0
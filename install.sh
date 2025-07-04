#!/bin/bash
# Claude Code Smart Installer - Works for new AND existing users
# One-line install: curl -sSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | bash

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Claude Code Smart Installer${NC}"
echo -e "${BLUE}==============================\n${NC}"

# Helper Functions
backup_if_needed() {
    local file=$1
    if [ -f "$file" ]; then
        backup_name="$file.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        echo -e "   ${BLUE}📂 Backed up to: $(basename $backup_name)${NC}"
    fi
}

check_make_command_version() {
    if [ -f "$HOME/.claude/commands/make-command.md" ]; then
        # Use checksums for exact comparison
        local_hash=$(md5sum "$HOME/.claude/commands/make-command.md" 2>/dev/null | cut -d' ' -f1)
        github_hash=$(md5sum "$setup_dir/commands/make-command.md" 2>/dev/null | cut -d' ' -f1)
        
        if [ -z "$local_hash" ] || [ -z "$github_hash" ]; then
            echo "unknown"
        elif [ "$local_hash" != "$github_hash" ]; then
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
if [ -z "$SKIP_CLAUDE_CHECK" ]; then
    claude_found=false
    
    # Try multiple detection methods
    if command -v claude-code &> /dev/null || \
       which claude-code &> /dev/null 2>&1 || \
       npm list -g @anthropic-ai/claude-code &> /dev/null 2>&1; then
        claude_found=true
    fi
    
    if [ "$claude_found" = false ]; then
        echo -e "${YELLOW}⚠️  Claude Code not detected in PATH${NC}"
        echo -e "\nThis might happen if:"
        echo -e "  • npm global binaries aren't in your PATH"
        echo -e "  • You installed it in a different shell"
        echo -e "  • The PATH isn't fully loaded yet"
        echo -e "\nIf you've already installed Claude Code, you can continue."
        echo -e "If not, install it with: ${GREEN}npm install -g @anthropic-ai/claude-code${NC}"
        echo
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            echo -e "\n${BLUE}Tip:${NC} You can skip this check with:"
            echo -e "${GREEN}SKIP_CLAUDE_CHECK=1 curl -sSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | bash${NC}"
            exit 1
        fi
    fi
fi

# Download files to temp directory first
echo -e "${BLUE}📥 Downloading setup files...${NC}"
temp_dir=$(mktemp -d)
cd "$temp_dir"
curl -sSL https://github.com/jezweb/get-started-with-claude-code/archive/main.tar.gz | tar xz
setup_dir="get-started-with-claude-code-main/get-started/personal-setup/.claude"

# Check installation status
if [ ! -d "$HOME/.claude" ]; then
    # SCENARIO 1: Fresh install
    echo -e "${GREEN}🆕 First time setup detected!${NC}"
    echo -e "${BLUE}Creating ~/.claude with all files...${NC}"
    
    cp -r "$setup_dir" "$HOME/"
    
    echo -e "\n${GREEN}✅ Installation complete!${NC}"
    echo -e "\n${YELLOW}⚠️  IMPORTANT: Personalize your setup:${NC}"
    echo -e "   ${GREEN}nano ~/.claude/CLAUDE.md${NC} (or use your favorite editor)"
    echo -e "\n${BLUE}Then start any project:${NC}"
    echo -e "   ${GREEN}cd your-project && claude-code${NC}"
    echo -e "   ${GREEN}/user:make-command${NC} (to create custom commands)"
    
else
    # SCENARIO 2: Existing installation
    echo -e "${CYAN}👋 Welcome back! Checking your existing setup...${NC}\n"
    
    # Check if CLAUDE.md exists and validate structure
    claude_status="missing"
    claude_structure="unknown"
    if [ -f "$HOME/.claude/CLAUDE.md" ]; then
        # First check if it's still a template
        if grep -q "\[Your Name" "$HOME/.claude/CLAUDE.md" 2>/dev/null || \
           grep -q "\[Your Title" "$HOME/.claude/CLAUDE.md" 2>/dev/null || \
           grep -q "\[your.email@example.com\]" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
            claude_status="template"
            echo -e "📄 CLAUDE.md: ${YELLOW}Found (still using template)${NC}"
        else
            claude_status="personalized"
            # Check structure
            claude_structure=$(validate_claude_structure)
            if [ "$claude_structure" = "valid_structure" ]; then
                echo -e "📄 CLAUDE.md: ${GREEN}Found (personalized) ✓${NC}"
            else
                echo -e "📄 CLAUDE.md: ${YELLOW}Found (different format) ⚠️${NC}"
                echo -e "   ${CYAN}Your file might be from an older version or customized${NC}"
            fi
        fi
    else
        echo -e "📄 CLAUDE.md: ${YELLOW}Missing${NC}"
    fi
    
    # Check settings.local.json and validate
    settings_status=$(validate_settings)
    if [ "$settings_status" = "valid" ]; then
        echo -e "⚙️  settings.local.json: ${GREEN}Found ✓${NC}"
        settings_exists=true
    elif [ "$settings_status" = "different_format" ]; then
        echo -e "⚙️  settings.local.json: ${YELLOW}Found (different format) ⚠️${NC}"
        settings_exists=true
    else
        echo -e "⚙️  settings.local.json: ${YELLOW}Missing${NC}"
        settings_exists=false
    fi
    
    # Check make-command.md version
    make_command_status=$(check_make_command_version)
    if [ "$make_command_status" = "newer_available" ]; then
        echo -e "📁 commands/make-command.md: ${YELLOW}Found (update available) 🔄${NC}"
        make_command_exists=true
        make_command_outdated=true
    elif [ "$make_command_status" = "up_to_date" ]; then
        echo -e "📁 commands/make-command.md: ${GREEN}Found (up to date) ✓${NC}"
        make_command_exists=true
        make_command_outdated=false
    elif [ "$make_command_status" = "unknown" ]; then
        echo -e "📁 commands/make-command.md: ${GREEN}Found ✓${NC}"
        make_command_exists=true
        make_command_outdated=false
    else
        if [ -d "$HOME/.claude/commands" ]; then
            echo -e "📁 commands/make-command.md: ${YELLOW}Missing${NC}"
        else
            echo -e "📁 commands/: ${YELLOW}Missing${NC}"
        fi
        make_command_exists=false
        make_command_outdated=false
    fi
    
    echo -e "\n${BLUE}📋 Actions needed:${NC}"
    actions_needed=false
    
    # Determine what needs to be done
    if [ "$claude_status" = "missing" ]; then
        echo -e "   • Add CLAUDE.md template"
        actions_needed=true
    elif [ "$claude_status" = "template" ]; then
        echo -e "   • Your CLAUDE.md still has template placeholders"
        echo -e "     ${YELLOW}Please personalize it after installation!${NC}"
    elif [ "$claude_structure" = "different_structure" ]; then
        echo -e "   • Your CLAUDE.md has a different structure"
        echo -e "     ${CYAN}This is OK if it's working for you!${NC}"
    fi
    
    if [ "$settings_exists" = false ]; then
        echo -e "   • Add settings.local.json (reduces approval prompts)"
        actions_needed=true
    elif [ "$settings_status" = "different_format" ]; then
        echo -e "   • Your settings.local.json has a different format"
        echo -e "     ${CYAN}This is OK if it's working for you!${NC}"
    fi
    
    if [ "$make_command_exists" = false ]; then
        echo -e "   • Add make-command.md (teaches custom commands)"
        actions_needed=true
    elif [ "$make_command_outdated" = true ]; then
        echo -e "   • Update make-command.md to latest version"
        echo -e "     ${CYAN}New features and improvements available!${NC}"
        actions_needed=true
    fi
    
    if [ "$actions_needed" = false ] && [ "$claude_status" = "personalized" ]; then
        echo -e "   ${GREEN}None! Your setup is complete. ✨${NC}"
        echo -e "\n${BLUE}Try creating a new command:${NC}"
        echo -e "   ${GREEN}cd your-project && claude-code${NC}"
        echo -e "   ${GREEN}/user:make-command${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 0
    fi
    
    # Ask before proceeding
    echo
    read -p "Proceed with updates? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [ -n "$REPLY" ]; then
        echo -e "${YELLOW}Installation cancelled. No changes made.${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 0
    fi
    
    # Perform updates
    echo -e "\n${BLUE}📝 Updating your setup...${NC}"
    
    # Add CLAUDE.md if missing
    if [ "$claude_status" = "missing" ]; then
        cp "$setup_dir/CLAUDE.md" "$HOME/.claude/"
        echo -e "   ${GREEN}✓${NC} Added CLAUDE.md template"
    fi
    
    # Add settings.local.json if missing
    if [ "$settings_exists" = false ]; then
        cp "$setup_dir/settings.local.json" "$HOME/.claude/"
        echo -e "   ${GREEN}✓${NC} Added settings.local.json"
    fi
    
    # Handle make-command.md updates
    if [ "$make_command_exists" = false ]; then
        mkdir -p "$HOME/.claude/commands"
        cp "$setup_dir/commands/make-command.md" "$HOME/.claude/commands/"
        echo -e "   ${GREEN}✓${NC} Added make-command.md"
    elif [ "$make_command_outdated" = true ]; then
        echo -e "\n${YELLOW}📦 Update available for make-command.md${NC}"
        echo -e "New features: Better project templates, enhanced examples"
        read -p "Update to latest version? (Y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
            backup_if_needed "$HOME/.claude/commands/make-command.md"
            cp "$setup_dir/commands/make-command.md" "$HOME/.claude/commands/"
            echo -e "   ${GREEN}✓${NC} Updated make-command.md"
        else
            echo -e "   ${YELLOW}↩${NC} Skipped make-command.md update"
        fi
    fi
    
    echo -e "\n${GREEN}✅ Update complete!${NC}"
    
    # Remind about personalization if needed
    if [ "$claude_status" != "personalized" ]; then
        echo -e "\n${YELLOW}⚠️  Don't forget to personalize:${NC}"
        echo -e "   ${GREEN}nano ~/.claude/CLAUDE.md${NC}"
    fi
fi

# Common ending message
echo -e "\n${BLUE}🎉 Ready to build with AI!${NC}"
echo -e "   ${GREEN}cd your-project && claude-code${NC}"
echo -e "   ${GREEN}/user:make-command${NC} (creates custom commands)\n"
echo -e "${BLUE}Learn more:${NC} https://github.com/jezweb/get-started-with-claude-code"

# Cleanup
cd - > /dev/null 2>&1 || true
rm -rf "$temp_dir"

# Clean exit
exit 0
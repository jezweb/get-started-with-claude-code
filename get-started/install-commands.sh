#!/bin/bash
# Claude Code Essential Commands Installer

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Claude Code Essential Commands Installer${NC}"
echo -e "${BLUE}===========================================${NC}\n"

# Check if ~/.claude/commands exists
if [ ! -d "$HOME/.claude/commands" ]; then
    echo -e "${YELLOW}Creating ~/.claude/commands directory...${NC}"
    mkdir -p "$HOME/.claude/commands"
fi

# Commands to install
commands=(
    "start-project:Start a new project with smart tech stack detection"
    "add-feature:Add a feature following project patterns"
    "fix-bug:Debug and fix issues systematically"
    "write-tests:Create comprehensive tests"
    "deploy:Deploy your project to production"
)

echo -e "${BLUE}📦 Available commands:${NC}\n"
for cmd in "${commands[@]}"; do
    name="${cmd%%:*}"
    desc="${cmd#*:}"
    echo -e "  ${GREEN}/user:${name}${NC} - ${desc}"
done

echo -e "\n${BLUE}Installing commands...${NC}\n"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install each command
installed=0
updated=0
skipped=0

for cmd in "${commands[@]}"; do
    name="${cmd%%:*}"
    source_file="$SCRIPT_DIR/commands/${name}.md"
    dest_file="$HOME/.claude/commands/${name}.md"
    
    if [ -f "$source_file" ]; then
        if [ -f "$dest_file" ]; then
            # Check versions
            local_ver=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$dest_file" 2>/dev/null || echo "0.0.0")
            new_ver=$(grep -oP '<!-- VERSION: \K[0-9.]+' "$source_file" 2>/dev/null || echo "1.0.0")
            
            if [ "$local_ver" != "$new_ver" ]; then
                cp "$source_file" "$dest_file"
                echo -e "  ${GREEN}✓${NC} Updated ${name}.md (${local_ver} → ${new_ver})"
                ((updated++))
            else
                echo -e "  ${BLUE}−${NC} ${name}.md already up to date"
                ((skipped++))
            fi
        else
            cp "$source_file" "$dest_file"
            echo -e "  ${GREEN}✓${NC} Installed ${name}.md"
            ((installed++))
        fi
    else
        echo -e "  ${YELLOW}⚠${NC}  ${name}.md not found in source"
    fi
done

echo -e "\n${GREEN}✅ Installation complete!${NC}"
echo -e "   Installed: ${installed}"
echo -e "   Updated: ${updated}"
echo -e "   Skipped: ${skipped}"

echo -e "\n${BLUE}🎯 Quick Start:${NC}"
echo -e "1. Open any project folder: ${GREEN}cd my-project${NC}"
echo -e "2. Start Claude Code: ${GREEN}claude-code${NC}"
echo -e "3. Create a new project: ${GREEN}/user:start-project${NC}"
echo -e "\n${BLUE}Other commands:${NC}"
echo -e "   ${GREEN}/user:add-feature${NC} - Add new functionality"
echo -e "   ${GREEN}/user:fix-bug${NC} - Debug issues"
echo -e "   ${GREEN}/user:write-tests${NC} - Create tests"
echo -e "   ${GREEN}/user:deploy${NC} - Deploy to production"

echo -e "\n${CYAN}💡 Tip:${NC} The start-project command is smart!"
echo -e "It detects your context and suggests the perfect tech stack."
echo
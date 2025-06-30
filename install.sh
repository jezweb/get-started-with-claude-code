#!/bin/bash
# Claude Code Starter Kit Installer

set -e

echo "🚀 Installing Claude Code Starter Kit..."

# Base URL for raw files
BASE_URL="https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main"

# Create .claude directory if it doesn't exist
mkdir -p .claude/commands

# Download main files
echo "📥 Downloading starter files..."
curl -fsSL "$BASE_URL/CLAUDE.md" -o CLAUDE.md
curl -fsSL "$BASE_URL/kickoff-prompt.md" -o kickoff-prompt.md
curl -fsSL "$BASE_URL/mvp-from-plan.md" -o mvp-from-plan.md

# Download commands
echo "📥 Downloading commands..."
curl -fsSL "$BASE_URL/.claude/commands/feature.md" -o .claude/commands/feature.md
curl -fsSL "$BASE_URL/.claude/commands/debug.md" -o .claude/commands/debug.md
curl -fsSL "$BASE_URL/.claude/commands/deploy.md" -o .claude/commands/deploy.md
curl -fsSL "$BASE_URL/.claude/commands/refactor.md" -o .claude/commands/refactor.md
curl -fsSL "$BASE_URL/.claude/commands/mvp.md" -o .claude/commands/mvp.md

# Optional: Download other useful commands
echo "📥 Downloading additional commands..."
curl -fsSL "$BASE_URL/.claude/commands/optimize.md" -o .claude/commands/optimize.md 2>/dev/null || true
curl -fsSL "$BASE_URL/.claude/commands/test-all.md" -o .claude/commands/test-all.md 2>/dev/null || true

echo "✅ Claude Code Starter Kit installed!"
echo ""
echo "📝 Files created:"
echo "   - CLAUDE.md (project context)"
echo "   - kickoff-prompt.md (start new projects)"
echo "   - mvp-from-plan.md (build from existing plan)"
echo "   - .claude/commands/ (useful commands)"
echo ""
echo "🎯 Next steps:"
echo "   1. Edit CLAUDE.md to match your project"
echo "   2. Run: claude-code"
echo "   3. Use kickoff-prompt.md or /kickoff to start"
echo ""
echo "Happy coding! 🎉"
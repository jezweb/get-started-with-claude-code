#!/bin/bash
# Quick setup script for environment configuration

echo "🚀 Environment Configuration Setup"
echo "================================="
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  Warning: .env file already exists!"
    echo "   Rename or backup your existing .env file first."
    exit 1
fi

# Ask user which template to use
echo "Which template would you like to use?"
echo "1) Simple - Basic AI API setup (recommended for beginners)"
echo "2) Complete - Advanced multi-model configuration"
echo ""
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        cp .env.simple .env
        echo "✅ Created .env from simple template"
        ;;
    2)
        cp .env.complete .env
        echo "✅ Created .env from complete template"
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "📋 Next steps:"
echo "1. Edit .env and add your API keys"
echo "2. Run './validate_env.py' to check your configuration"
echo "3. Make sure .env is in your .gitignore file"
echo ""
echo "🔑 Get your Gemini API key at: https://makersuite.google.com/app/apikey"
echo ""
echo "Happy coding! 🎉"
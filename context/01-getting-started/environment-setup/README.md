# Development Environment Setup

Comprehensive guide for setting up a modern development environment optimized for full-stack web development with AI assistance.

## 🎯 Environment Overview

A properly configured development environment includes:
- **Code Editor** - VS Code with essential extensions
- **Version Control** - Git and GitHub/GitLab
- **Runtime Environments** - Node.js, Python, Docker
- **Package Managers** - npm, pip, pnpm
- **Development Tools** - Linters, formatters, debuggers
- **AI Integration** - Claude Code, GitHub Copilot

## 💻 Operating System Setup

### macOS

```bash
# Install Homebrew (package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install essential tools
brew install git node python@3.11 docker

# Install development tools
brew install --cask visual-studio-code iterm2 postman

# Install databases
brew install postgresql redis sqlite

# Verify installations
brew list --versions
```

### Ubuntu/Debian

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl git build-essential

# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python
sudo apt install -y python3.11 python3.11-venv python3-pip

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install VS Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code
```

### Windows

```powershell
# Install Windows Package Manager (if not present)
# Download from Microsoft Store or GitHub

# Install essential tools
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Python.Python.3.11
winget install Docker.DockerDesktop
winget install Microsoft.VisualStudioCode

# Install Windows Terminal
winget install Microsoft.WindowsTerminal

# Enable WSL2 (recommended)
wsl --install
wsl --set-default-version 2
```

## 🛠️ Essential Tools

### Git Configuration

```bash
# Set up user information
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Configure line endings
git config --global core.autocrlf input  # macOS/Linux
git config --global core.autocrlf true   # Windows

# Set default branch name
git config --global init.defaultBranch main

# Enable color output
git config --global color.ui auto

# Set up aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# Configure merge tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'

# SSH key setup
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Node.js Environment

```bash
# Install Node Version Manager (nvm) - macOS/Linux
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node Version Manager (nvm-windows) - Windows
# Download from: https://github.com/coreybutler/nvm-windows

# Install and use latest LTS
nvm install --lts
nvm use --lts

# Set defaults
nvm alias default node

# Global npm packages
npm install -g pnpm yarn
npm install -g typescript ts-node
npm install -g @vue/cli create-vite
npm install -g vercel netlify-cli

# Configure npm
npm config set init-author-name "Your Name"
npm config set init-author-email "your.email@example.com"
npm config set init-license "MIT"
```

### Python Environment

```bash
# Install Python version management (pyenv) - macOS/Linux
curl https://pyenv.run | bash

# Add to shell profile
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Install Python versions
pyenv install 3.11.6
pyenv install 3.12.0
pyenv global 3.11.6

# Install Poetry (dependency management)
curl -sSL https://install.python-poetry.org | python3 -

# Install global Python tools
pip install --user pipx
pipx install black
pipx install ruff
pipx install mypy
pipx install pytest
pipx install httpie
```

## 📝 VS Code Setup

### Essential Extensions

```bash
# Install via command line
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.black-formatter
code --install-extension Vue.volar
code --install-extension bradlc.vscode-tailwindcss
code --install-extension formulahendry.auto-rename-tag
code --install-extension christian-kohler.path-intellisense
code --install-extension PKief.material-icon-theme
code --install-extension GitHub.copilot
code --install-extension eamodio.gitlens
code --install-extension ms-vscode-remote.remote-containers
code --install-extension ritwickdey.LiveServer
code --install-extension humao.rest-client
```

### VS Code Settings (settings.json)

```json
{
  // Editor
  "editor.fontSize": 14,
  "editor.fontFamily": "'Fira Code', 'Cascadia Code', Consolas, monospace",
  "editor.fontLigatures": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": true,
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.minimap.enabled": false,
  "editor.wordWrap": "on",
  "editor.rulers": [80, 120],
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  
  // Terminal
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  
  // Files
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/.pytest_cache": true
  },
  
  // Language-specific
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[vue]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  
  // Extensions
  "prettier.semi": false,
  "prettier.singleQuote": true,
  "prettier.trailingComma": "es5",
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue"
  ],
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.testing.pytestEnabled": true,
  
  // Git
  "git.autofetch": true,
  "git.confirmSync": false,
  "gitlens.hovers.currentLine.over": "line",
  
  // AI
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": false,
    "markdown": true
  }
}
```

## 🐚 Shell Configuration

### Zsh with Oh My Zsh (macOS/Linux)

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Edit ~/.zshrc
plugins=(
  git
  node
  npm
  python
  docker
  vscode
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Custom aliases
alias ll='ls -la'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias dev='npm run dev'
alias py='python'
alias pip='pip3'
alias dc='docker-compose'
```

### PowerShell Profile (Windows)

```powershell
# Create profile if not exists
if (!(Test-Path -Path $PROFILE)) {
  New-Item -Type File -Path $PROFILE -Force
}

# Edit profile
notepad $PROFILE

# Add to profile
# Aliases
Set-Alias -Name g -Value git
Set-Alias -Name py -Value python
Set-Alias -Name touch -Value New-Item

# Functions
function dev { npm run dev }
function build { npm run build }
function test { npm test }

# Git shortcuts
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m $m }
function gp { git push }
function gl { git log --oneline --graph --decorate }

# Prompt customization
oh-my-posh init pwsh | Invoke-Expression
```

## 🔧 Development Utilities

### Docker Configuration

```yaml
# docker-compose.yml for development
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: devdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI

volumes:
  postgres_data:
```

### Environment Management

```bash
# .envrc for direnv (auto-load environment)
# Install direnv first
curl -sfL https://direnv.net/install.sh | bash

# Create .envrc in project
cat > .envrc << 'EOF'
# Python
layout python python3.11
export PYTHONPATH=$PWD

# Node
use node 20.10.0

# Project specific
export DATABASE_URL="postgresql://dev:devpass@localhost/devdb"
export REDIS_URL="redis://localhost:6379"
export SECRET_KEY="dev-secret-key"
export DEBUG=true
EOF

# Allow direnv
direnv allow
```

## 🤖 AI Development Setup

### Claude Code Configuration

```bash
# Global CLAUDE.md setup
mkdir -p ~/.claude
cat > ~/.claude/CLAUDE.md << 'EOF'
# Global Claude Configuration

## Development Preferences
- Always use modern ES6+ JavaScript
- Prefer async/await over promises
- Use TypeScript for larger projects
- Follow clean code principles
- Write tests for critical functionality

## Code Style
- 2 spaces for indentation
- No semicolons in JavaScript/TypeScript
- Single quotes for strings
- Trailing commas in objects/arrays
- Meaningful variable names

## Common Patterns
- Use composition over inheritance
- Implement error boundaries
- Add proper error handling
- Include JSDoc comments for functions
- Keep functions small and focused
EOF
```

### GitHub Copilot Settings

```json
{
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "plaintext": false,
    "markdown": true,
    "scminput": false
  },
  "github.copilot.advanced": {
    "length": 500,
    "temperature": 0.7,
    "top_p": 1,
    "stops": {
      "python": ["\n\n", "\ndef", "\nclass"],
      "javascript": ["\n\n", "\nfunction", "\nconst", "\nlet"]
    }
  }
}
```

## 🔍 Debugging Setup

### Browser DevTools

```bash
# Chrome/Edge extensions
# React Developer Tools
# Vue.js devtools
# Redux DevTools
# Network throttling profiles
# Lighthouse for performance
```

### VS Code Debugging

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Node.js",
      "program": "${workspaceFolder}/index.js",
      "envFile": "${workspaceFolder}/.env"
    },
    {
      "type": "python",
      "request": "launch",
      "name": "Debug Python",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": true
    },
    {
      "type": "chrome",
      "request": "launch",
      "name": "Debug Chrome",
      "url": "http://localhost:5173",
      "webRoot": "${workspaceFolder}/src"
    }
  ]
}
```

## 📊 Performance Tools

### System Monitoring

```bash
# macOS
brew install htop
brew install --cask stats

# Linux
sudo apt install htop
sudo apt install neofetch

# Cross-platform Node.js
npm install -g clinic
npm install -g 0x
```

### Development Metrics

```bash
# Code quality
npm install -g jshint eslint
pip install pylint flake8

# Bundle analysis
npm install -g webpack-bundle-analyzer
npm install -g source-map-explorer

# Performance testing
npm install -g lighthouse
npm install -g sitespeed.io
```

## 🔐 Security Setup

### SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub | pbcopy  # macOS
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard  # Linux
cat ~/.ssh/id_ed25519.pub | clip  # Windows
```

### GPG Setup

```bash
# Generate GPG key
gpg --full-generate-key

# List keys
gpg --list-secret-keys --keyid-format=long

# Configure Git to use GPG
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
```

## 🚀 Quick Validation

### Environment Check Script

```bash
#!/bin/bash
# save as check-env.sh

echo "🔍 Checking development environment..."

# Check commands
commands=(git node npm python3 docker code)
for cmd in "${commands[@]}"; do
  if command -v $cmd &> /dev/null; then
    echo "✅ $cmd: $(command -v $cmd)"
  else
    echo "❌ $cmd: not found"
  fi
done

# Check versions
echo -e "\n📊 Version Information:"
node --version
npm --version
python3 --version
git --version
docker --version 2>/dev/null || echo "Docker not running"

# Check global npm packages
echo -e "\n📦 Global npm packages:"
npm list -g --depth=0

echo -e "\n✨ Environment check complete!"
```

## 📚 Next Steps

1. **Install language-specific tools** based on your project needs
2. **Configure your shell** with aliases and functions
3. **Set up project templates** for quick starts
4. **Install browser extensions** for debugging
5. **Configure cloud CLI tools** (AWS, GCP, Azure)

## 🔗 Additional Resources

- [Shell customization guide](https://ohmyz.sh/)
- [VS Code tips and tricks](https://code.visualstudio.com/docs/getstarted/tips-and-tricks)
- [Git configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
- [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)

---

*A well-configured development environment is the foundation of productive coding. Take time to customize it to your workflow.*
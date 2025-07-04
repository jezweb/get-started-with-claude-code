# Claude Code Settings Guide

The `.claude/settings.local.json` file pre-approves common commands to streamline your workflow.

## What It Does

Instead of approving each command individually, Claude Code will automatically execute pre-approved commands. This makes development much smoother while maintaining security.

## Pre-approved Categories

### Git Operations
- All git commands (add, commit, push, pull, checkout, status, diff, log, branch)
- GitHub CLI commands (gh auth, issue, pr, repo)

### File Management
- Creating directories (`mkdir`) and files (`touch`)
- Listing (`ls`) and reading files (`cat`)
- Changing permissions (`chmod`)
- Removing files (`rm`)

### Package Management
- npm commands (install, run, test, build)
- pip commands (install, freeze)

### Development
- Python execution (`python`, `python3`)
- Virtual environment activation (`source`)
- Development servers (`npm run dev`, `uvicorn`, `python -m http.server`)
- Build tools (`vite`)

### Testing
- Test runners (`pytest`, `jest`, `vitest`)

### Utilities
- Common tools (`curl`, `grep`, `find`, `tree`)
- Script execution in current directory (`./start.sh`, `./install.sh`, `./scripts/*`)

### Web Access
- GitHub documentation and repositories
- NPM package documentation
- Python Package Index (PyPI)
- MDN Web Docs

### MCP Servers
- Context7 for documentation lookup
- Playwright for browser automation

## Installation

### Option 1: With Install Script
```bash
curl -fsSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/install.sh | sh -s -- --with-settings
```

### Option 2: Manual Installation
```bash
# After running regular install
curl -fsSL https://raw.githubusercontent.com/jezweb/get-started-with-claude-code/main/.claude/settings.local.json -o .claude/settings.local.json
```

## Customization

### Adding New Patterns
Edit `.claude/settings.local.json` and add patterns:

```json
"Bash(your-command:*)",
"WebFetch(domain:example.com)"
```

### Pattern Format
- `Bash(command:arguments)` - For shell commands
- `WebFetch(domain:example.com)` - For web access
- `mcp__servername__*` - For MCP server commands

### Removing Patterns
Simply delete any lines you don't want pre-approved.

## Security Notes

- Only common, safe development commands are included
- Commands like `rm -rf /` are NOT pattern-matched
- You can always override by using the deny list
- This file is user-specific and should not be committed

## Troubleshooting

### Settings Not Working?
1. Ensure file is in `.claude/settings.local.json`
2. Check JSON syntax is valid
3. Restart Claude Code after changes

### Too Permissive?
Remove patterns you're not comfortable with auto-approving.

### Want More Control?
Use the `deny` list to block specific patterns:

```json
"deny": [
  "Bash(rm -rf:*)",
  "Bash(sudo:*)"
]
```

## Best Practices

1. **Review Before Installing** - Check what commands are pre-approved
2. **Customize for Your Workflow** - Add project-specific scripts
3. **Don't Commit** - Keep settings.local.json in .gitignore
4. **Update Regularly** - Add new patterns as needed

Happy coding with fewer interruptions! 🚀
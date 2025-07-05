# TailwindCSS Context Folder

This folder contains comprehensive research and guides for setting up TailwindCSS with Vite, troubleshooting common issues, and understanding the differences between v3 and v4.

## Contents

1. **approach-comparison.md** - Detailed comparison of PostCSS vs Vite plugin approaches
2. **common-issues.md** - Common problems and their solutions
3. **setup-guides.md** - Step-by-step setup instructions
4. **version-differences.md** - Key differences between v3 and v4
5. **troubleshooting.md** - Debugging strategies and error fixes
6. **practical-recommendations.md** - Real-world developer experience and opinionated guidance

## Quick Start

For any project, use the PostCSS approach (most reliable):

```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

See `setup-guides.md` for complete instructions.

## When to Use Each Approach

- **PostCSS Plugin**: Recommended for all projects (better reliability and developer experience)
- **Vite Plugin**: Alternative for simple Vite projects (less reliable, HMR issues common)

## Common Error Prevention

1. Never mix v3 and v4 configurations
2. Use exact version numbers in package.json
3. Clear node_modules when switching approaches
4. Verify your CSS imports match your chosen approach

For detailed troubleshooting, see `troubleshooting.md`.
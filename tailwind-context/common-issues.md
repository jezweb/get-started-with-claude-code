# Common TailwindCSS Issues and Solutions

## Mixed v3/v4 Configuration Problems

### Error: "It looks like you're trying to use `tailwindcss` directly as a PostCSS plugin"
**Cause**: Using main `tailwindcss` package as PostCSS plugin in v4
**Solution**: Use `@tailwindcss/postcss` package instead

```bash
# Wrong approach
npm install tailwindcss

# Correct approach for PostCSS
npm install tailwindcss @tailwindcss/postcss
```

### Error: "Could not load the configuration file"
**Cause**: v4 configuration changes from JavaScript to CSS
**Solution**: Migrate from `tailwind.config.js` to CSS-based configuration

```css
/* Old v3 approach */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* New v4 approach */
@import "tailwindcss";

@theme {
  --color-primary: #3b82f6;
  --font-family-display: ui-serif;
}
```

### Error: "Missing './components' specifier in 'tailwindcss' package"
**Cause**: Import statements using v3 patterns with v4 installation
**Solution**: Update all imports to use v4 patterns

## Dependency and Installation Issues

### Error: "ERESOLVE unable to resolve dependency tree"
**Solutions**:
1. Use legacy peer deps: `npm install --legacy-peer-deps`
2. Clear cache: `npm cache clean --force`
3. Remove node_modules: `rm -rf node_modules package-lock.json`
4. Update Node.js to v20+ (required for v4 upgrade tool)

### Error: "PostCSS plugin tailwindcss requires PostCSS 8"
**Solution**: Update PostCSS to v8.x or higher
```bash
npm install postcss@^8.5.6
```

### Angular/Build Tool Conflicts
**Issue**: `@angular-devkit/build-angular` expects Tailwind v2/v3
**Solution**: Use legacy peer deps or consider staying on v3 for Angular projects

## Vite-Specific Issues

### Error: "Cannot build frontend using Vite, TailwindCSS with PostCSS"
**Solutions**:
1. Switch to `@tailwindcss/vite` plugin (recommended)
2. Ensure correct PostCSS configuration for v4
3. Remove `autoprefixer` (handled automatically in v4)

### Performance Issues with PostCSS + Vite
**Solution**: Migrate to Vite plugin for better performance
```bash
npm uninstall @tailwindcss/postcss
npm install @tailwindcss/vite
```

## AI-Generated Code Issues

### Mixed Configuration Syntax
**Problem**: AI generates v3 config with v4 installation
**Prevention**: Always specify exact Tailwind version in prompts

### Plugin Compatibility Issues
**Problem**: AI includes v3 plugins incompatible with v4
**Solution**: Use official migration tool: `npx @tailwindcss/upgrade@next`

## CSS Import and Configuration Issues

### Incorrect CSS Imports
**Wrong**:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Correct for v4**:
```css
@import "tailwindcss";
```

### Custom Configuration Migration
**v3 JavaScript Config**:
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    colors: {
      'midnight': '#121063',
    }
  }
}
```

**v4 CSS Config**:
```css
@import "tailwindcss";

@theme {
  --color-midnight: #121063;
}
```

## Build Process Issues

### Styles Not Applying
**Common causes**:
1. Incorrect import statement
2. Missing content configuration
3. Build tool not processing CSS correctly

**Solutions**:
1. Verify CSS import: `@import "tailwindcss"`
2. Check build tool configuration
3. Ensure template files are being scanned

### Production Build Problems
**Issue**: Styles work in development but not production
**Solutions**:
1. Verify purge/content configuration
2. Check for CSS minification issues
3. Ensure all template files are included in build

## Version-Specific Troubleshooting

### v4 Browser Compatibility
**Requirements**: Safari 16.4+, Chrome 111+, Firefox 128+
**Issue**: Styles not working in older browsers
**Solution**: Consider staying on v3 for broader compatibility

### Color System Changes
**v3 to v4 Migration**:
- Colors now use CSS variables
- Opacity modifiers work differently
- Custom color additions require CSS syntax

## Debugging Strategies

### Clean Installation Process
```bash
# Complete clean install
rm -rf node_modules package-lock.json
npm cache clean --force

# For v4 with Vite
npm install tailwindcss @tailwindcss/vite

# For v4 with PostCSS
npm install tailwindcss @tailwindcss/postcss
```

### Verification Steps
1. Check package.json for correct dependencies
2. Verify CSS import statement
3. Test with simple utility class
4. Check browser developer tools for CSS loading
5. Verify build tool configuration

### Common File Locations to Check
- `package.json` - dependency versions
- `vite.config.js` - Vite plugin configuration
- `postcss.config.js` - PostCSS plugin configuration
- Main CSS file - import statements and theme customization
- Template files - utility class usage

## Prevention Best Practices

### Version Management
- Use exact version numbers in package.json
- Lock dependencies to prevent automatic updates
- Test upgrades in separate branches

### Configuration Consistency
- Choose one approach (Vite plugin OR PostCSS plugin)
- Don't mix v3 and v4 syntax
- Use official migration tools when available

### Team Collaboration
- Document chosen approach in README
- Share configuration files in version control
- Establish clear upgrade procedures
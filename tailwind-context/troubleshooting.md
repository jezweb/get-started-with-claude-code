# TailwindCSS Troubleshooting Guide

## Diagnostic Checklist

### 1. Quick Environment Check
```bash
# Check Node.js version (v20+ recommended for v4)
node --version

# Check package versions
npm list tailwindcss
npm list @tailwindcss/vite
npm list @tailwindcss/postcss
```

### 2. CSS Import Verification
```css
/* Correct for v4 */
@import "tailwindcss";

/* Incorrect (v3 syntax) */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### 3. Build Tool Configuration
- **Vite**: Check `vite.config.js` for `@tailwindcss/vite` plugin
- **PostCSS**: Check `postcss.config.js` for `@tailwindcss/postcss` plugin
- **Other**: Verify PostCSS processing is enabled

## Vite Plugin Specific Issues

### HMR (Hot Module Replacement) Problems
**Symptoms**: 
- Styles disappearing during development
- 5+ second reload times
- Full page refreshes instead of hot updates
- CSS not updating when classes change

**Solution**: Switch to PostCSS approach
```bash
npm uninstall @tailwindcss/vite
npm install @tailwindcss/postcss postcss
```

### Version Compatibility Issues
**Error**: "Package @tailwindcss/vite requires Vite ^5.2.0 || ^6"
**Cause**: Vite plugin doesn't support Vite 7+
**Solution**: Use PostCSS plugin for universal compatibility

### Build Instability
**Symptoms**:
- Random build failures
- Inconsistent CSS generation
- Cache issues between builds

**Solution**: PostCSS provides more predictable builds

## Common Error Messages and Solutions

### "cho: command not found" or Similar Encoding Errors
**Cause**: Unicode characters in shell scripts when piped through curl
**Solution**: Use ASCII-only characters in shell scripts

### "It looks like you're trying to use `tailwindcss` directly as a PostCSS plugin"
**Cause**: Using main package instead of `@tailwindcss/postcss`
**Solution**:
```bash
npm uninstall tailwindcss
npm install tailwindcss @tailwindcss/postcss
```

### "Could not load the configuration file"
**Cause**: v4 doesn't use `tailwind.config.js`
**Solution**: Move configuration to CSS using `@theme` directive

### "ERESOLVE unable to resolve dependency tree"
**Solutions**:
```bash
# Option 1: Use legacy peer deps
npm install --legacy-peer-deps

# Option 2: Clear cache and reinstall
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# Option 3: Update Node.js
nvm use 20  # or latest LTS
```

### "PostCSS plugin tailwindcss requires PostCSS 8"
**Solution**:
```bash
npm install postcss@^8.5.6
```

### "Cannot build frontend using Vite, TailwindCSS with PostCSS"
**Solution**: Switch to Vite plugin
```bash
npm uninstall @tailwindcss/postcss
npm install @tailwindcss/vite
```

## Step-by-Step Debugging

### 1. Verify Installation
```bash
# Check if packages are installed
npm list | grep tailwind

# Expected for Vite:
# └── tailwindcss@4.x.x
# └── @tailwindcss/vite@4.x.x

# Expected for PostCSS:
# └── tailwindcss@4.x.x
# └── @tailwindcss/postcss@4.x.x
```

### 2. Check Configuration Files
```bash
# For Vite plugin approach
ls -la vite.config.js  # Should exist
ls -la postcss.config.js  # Should NOT exist

# For PostCSS plugin approach  
ls -la postcss.config.js  # Should exist
ls -la tailwind.config.js  # Should NOT exist (v4)
```

### 3. Verify CSS File
```css
/* src/style.css - Check this file */
@import "tailwindcss";  /* Must be present */

/* Optional theme customization */
@theme {
  --color-primary: #3b82f6;
}
```

### 4. Test Basic Styles
```html
<!-- Add to your HTML -->
<div class="bg-red-500 text-white p-4 rounded">
  Test: If this is red with white text, Tailwind is working
</div>
```

### 5. Check Browser Developer Tools
1. Open browser dev tools
2. Check if CSS is loaded
3. Look for Tailwind utility classes
4. Check for any CSS errors

## Clean Installation Process

### Complete Fresh Install
```bash
# Remove everything
rm -rf node_modules package-lock.json
rm -f postcss.config.js tailwind.config.js

# Clear npm cache
npm cache clean --force

# For Vite projects
npm install tailwindcss @tailwindcss/vite

# For PostCSS projects
npm install tailwindcss @tailwindcss/postcss
```

### Vite Plugin Setup
```javascript
// vite.config.js
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [tailwindcss()],
})
```

### PostCSS Plugin Setup
```javascript
// postcss.config.js
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
}
```

## Advanced Troubleshooting

### Build Process Issues
```bash
# For Vite
npm run build -- --debug

# Check build output
ls -la dist/assets/  # Look for CSS files
```

### Content Detection Problems
```javascript
// If styles aren't applying, check content detection
// postcss.config.js (PostCSS approach only)
export default {
  plugins: {
    '@tailwindcss/postcss': {
      content: [
        './src/**/*.{html,js,vue,ts,tsx,jsx}',
        './index.html'
      ]
    },
  }
}
```

### Performance Issues
```bash
# Check bundle size
npm run build
ls -lh dist/assets/*.css

# Expected: ~10kB for typical application
```

## Framework-Specific Issues

### Vue.js Issues with Vite Plugin
**Problem**: Vue SFC styles conflict with Vite plugin HMR
**Solution**: Use PostCSS approach instead
```javascript
// postcss.config.js (recommended)
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
};
```

### React Issues with Vite Plugin
**Problem**: React Fast Refresh interference
**Solution**: Use PostCSS approach instead
```javascript
// postcss.config.js (recommended)
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
};
```

### Next.js Issues
```javascript
// next.config.js - v4 might need specific configuration
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Add any specific v4 configurations here
}

module.exports = nextConfig
```

## Development vs Production Issues

### Development Working, Production Broken
**Common causes**:
1. Content paths not including production files
2. Environment-specific build configuration
3. CSS minification issues

**Solutions**:
1. Check content configuration
2. Test production build locally
3. Verify deployment process

### Styles Not Applying in Production
```bash
# Check if CSS is being generated
npm run build
grep -r "bg-red-500" dist/  # Should find your test classes

# Check if CSS is being loaded
curl -I your-production-url  # Check for CSS files
```

## Browser Compatibility Issues

### Styles Not Working in Older Browsers
**v4 Requirements**:
- Safari 16.4+
- Chrome 111+
- Firefox 128+

**Solution**: Consider staying on v3 for broader compatibility

### Modern CSS Features Not Working
**Check**: Browser support for CSS features used by v4
**Solution**: Use appropriate fallbacks or polyfills

## IDE and Editor Issues

### IntelliSense Not Working
1. Install Tailwind CSS IntelliSense extension
2. Restart IDE
3. Check if CSS file is being detected

### Autocomplete Issues
```json
// VS Code settings.json
{
  "tailwindCSS.experimental.classRegex": [
    ["class\\s*=\\s*\"([^\"]*)", "([^\"]*class[^\"]*\"[^\"]*")"]
  ]
}
```

## When to Seek Help

### Before Asking for Help
1. ✅ Tried clean installation
2. ✅ Verified configuration files
3. ✅ Checked browser developer tools
4. ✅ Tested with simple HTML
5. ✅ Checked this troubleshooting guide

### Where to Get Help
- [TailwindCSS Discord](https://discord.gg/tailwindcss)
- [GitHub Issues](https://github.com/tailwindlabs/tailwindcss/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/tailwind-css)

### Information to Include
- Node.js version
- Package versions (`npm list tailwindcss`)
- Configuration files
- Error messages
- Browser and OS
- Minimal reproduction case

## Prevention Strategies

### Best Practices
1. **Lock versions**: Use exact versions in package.json
2. **Document setup**: Keep README updated with setup steps
3. **Test builds**: Regularly test production builds
4. **Monitor changes**: Watch for breaking changes in updates
5. **Use official tools**: Stick to official migration tools

### Team Coordination
1. **Standardize setup**: Use same approach across team
2. **Share configurations**: Version control configuration files
3. **Document decisions**: Record why certain approaches were chosen
4. **Training**: Ensure team understands chosen approach
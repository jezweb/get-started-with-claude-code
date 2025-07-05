# TailwindCSS Setup Guides

## Quick Decision Guide

### For Any Project (Recommended)
**Use PostCSS Plugin** - Better reliability and developer experience

### For Vite Projects Specifically
**PostCSS Plugin** - More stable than Vite plugin, works with any build tool

### For Next.js, Angular, or Other Frameworks
**PostCSS Plugin** - Universal compatibility (only option)

## PostCSS Plugin Setup (Recommended)

### 1. Installation
```bash
npm install tailwindcss @tailwindcss/postcss postcss
```

### 2. PostCSS Configuration
```javascript
// postcss.config.js
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
};
```

### 3. CSS Setup
```css
/* src/style.css */
@import "tailwindcss";

/* Optional: Custom theme */
@theme {
  --color-primary: #3b82f6;
  --font-family-display: ui-serif;
}
```

### 4. Import CSS
```javascript
// main.js
import './style.css'
```

### 5. Test Setup
```html
<!-- index.html -->
<div class="bg-blue-500 text-white p-4 rounded">
  TailwindCSS is working!
</div>
```

## Vite Plugin Setup (Alternative, Less Reliable)

**Note**: While officially recommended, many developers report better results with PostCSS approach.

### 1. Installation
```bash
npm install tailwindcss @tailwindcss/vite
```

### 2. Vite Configuration
```javascript
// vite.config.js
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss()],
});
```

### 3. CSS Setup
```css
/* src/style.css */
@import "tailwindcss";

/* Optional: Custom theme */
@theme {
  --color-primary: #3b82f6;
  --font-family-display: ui-serif;
}
```

### 4. Common Issues
- HMR failures and slow reloads
- Styles disappearing during development
- Version compatibility issues
- Consider switching to PostCSS if you experience problems

## Framework-Specific Setups

### Vue 3 with Vite (PostCSS Recommended)
```bash
# Create Vue project
npm create vue@latest my-project
cd my-project
npm install

# Add Tailwind with PostCSS
npm install tailwindcss @tailwindcss/postcss postcss
```

```javascript
// postcss.config.js
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
};
```

### React with Vite (PostCSS Recommended)
```bash
# Create React project
npm create vite@latest my-react-app -- --template react
cd my-react-app
npm install

# Add Tailwind with PostCSS
npm install tailwindcss @tailwindcss/postcss postcss
```

```javascript
// postcss.config.js
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
};
```

### Next.js Setup
```bash
# Create Next.js project
npx create-next-app@latest my-app
cd my-app

# Add Tailwind with PostCSS
npm install tailwindcss @tailwindcss/postcss
```

```javascript
// postcss.config.js
module.exports = {
  plugins: {
    '@tailwindcss/postcss': {},
  },
}
```

## Advanced Configuration

### Custom Theme Configuration
```css
/* styles/tailwind.css */
@import "tailwindcss";

@theme {
  /* Colors */
  --color-primary: #3b82f6;
  --color-secondary: #64748b;
  --color-accent: #f59e0b;
  
  /* Typography */
  --font-family-display: ui-serif, Georgia, serif;
  --font-family-body: ui-sans-serif, system-ui, sans-serif;
  
  /* Spacing */
  --spacing-18: 4.5rem;
  --spacing-88: 22rem;
  
  /* Breakpoints */
  --breakpoint-3xl: 1920px;
}
```

### Content Configuration (if needed)
Most v4 setups automatically detect content, but you can configure it:

```javascript
// For PostCSS plugin in postcss.config.js
export default {
  plugins: {
    '@tailwindcss/postcss': {
      content: [
        './src/**/*.{html,js,vue,ts,tsx,jsx}',
        './index.html'
      ]
    },
  }
};
```

## Production Optimization

### Build Configuration
Both approaches automatically optimize for production:
- Remove unused CSS
- Minify output
- Generate source maps (if configured)

### Bundle Size Expectations
- Typical production bundle: ~10kB of CSS
- Unused styles automatically removed
- Modern CSS features for smaller bundles

## Migration from v3

### Automated Migration
```bash
# Install migration tool (requires Node.js 20+)
npx @tailwindcss/upgrade@next

# Follow the prompts to migrate your project
```

### Manual Migration Steps
1. **Update dependencies**
   ```bash
   npm uninstall tailwindcss postcss autoprefixer
   npm install tailwindcss @tailwindcss/vite  # or @tailwindcss/postcss
   ```

2. **Update CSS imports**
   ```css
   /* Old v3 */
   @tailwind base;
   @tailwind components;
   @tailwind utilities;
   
   /* New v4 */
   @import "tailwindcss";
   ```

3. **Migrate configuration**
   ```javascript
   // Old tailwind.config.js
   module.exports = {
     theme: {
       colors: {
         primary: '#3b82f6',
       }
     }
   }
   ```
   
   ```css
   /* New CSS-based config */
   @theme {
     --color-primary: #3b82f6;
   }
   ```

4. **Update build configuration**
   - Remove PostCSS config if using Vite plugin
   - Update Vite config to include Tailwind plugin

## Troubleshooting New Setups

### Styles Not Loading
1. Check CSS import statement: `@import "tailwindcss"`
2. Verify build tool is processing CSS
3. Check browser developer tools for CSS loading
4. Ensure template files are being scanned

### Build Errors
1. Verify correct package installation
2. Check configuration file syntax
3. Clear node_modules and reinstall
4. Check for conflicting dependencies

### Performance Issues
1. Use Vite plugin for Vite projects
2. Ensure proper content configuration
3. Check for unnecessary CSS processing

## Testing Your Setup

### Basic Test
```html
<div class="bg-blue-500 text-white p-4 rounded-lg shadow-md">
  <h1 class="text-2xl font-bold">TailwindCSS Test</h1>
  <p class="mt-2">If you can see this styled, Tailwind is working!</p>
</div>
```

### Dynamic Values Test (v4 feature)
```html
<div class="w-103 h-47 bg-red-333 grid-cols-15">
  Dynamic values working!
</div>
```

### CSS Variables Test
```html
<div class="bg-primary text-white p-4">
  Custom theme colors working!
</div>
```

## Next Steps

1. **Customize your theme** in CSS using `@theme` directive
2. **Add component styles** using CSS or framework patterns
3. **Set up your development workflow** with proper tooling
4. **Configure your IDE** for Tailwind IntelliSense
5. **Learn v4 features** like container queries and modern CSS integration
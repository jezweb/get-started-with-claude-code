# TailwindCSS v3 vs v4 - Key Differences

## Architecture Changes

### Configuration System
**v3**: JavaScript-based configuration
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    colors: {
      'primary': '#3b82f6',
    }
  }
}
```

**v4**: CSS-based configuration
```css
@import "tailwindcss";

@theme {
  --color-primary: #3b82f6;
}
```

### PostCSS Plugin Structure
**v3**: Single package
```bash
npm install tailwindcss
```

**v4**: Separate plugin packages
```bash
# For PostCSS
npm install tailwindcss @tailwindcss/postcss

# For Vite
npm install tailwindcss @tailwindcss/vite
```

## Performance Improvements

### Build Speed
- **Full builds**: 3.5x to 5x faster
- **Incremental builds with changes**: ~8x faster
- **Incremental builds without changes**: Over 100x faster
- **New Oxide engine**: Rust-based processing for speed

### Bundle Size
- **Typical production bundle**: Under 10kB (vs ~20kB in v3)
- **Better tree-shaking**: More efficient unused CSS removal
- **Modern CSS features**: Smaller output using native CSS

## Feature Additions

### Dynamic Utility Values
**v3**: Predefined values only
```html
<!-- Only works if w-103 is configured -->
<div class="w-103"></div>
```

**v4**: Dynamic values work out of the box
```html
<!-- These work without configuration -->
<div class="w-103 h-47 grid-cols-15 bg-red-333"></div>
```

### Modern CSS Features
**v4 adds first-class support for**:
- Container queries (`@container`)
- Cascade layers (`@layer`)
- CSS custom properties (`@property`)
- Color mixing (`color-mix()`)
- Relative color syntax

### CSS Variables Exposure
**v4**: All design tokens available as CSS variables
```css
/* Automatically available */
background-color: var(--color-blue-500);
font-size: var(--font-size-xl);
```

## Browser Compatibility

### Requirements
**v3**: IE 11+ (with polyfills)
**v4**: Modern browsers only
- Safari 16.4+
- Chrome 111+
- Firefox 128+

### Impact
- **Breaking change**: Older browser support removed
- **Modern CSS**: Takes advantage of latest CSS features
- **Performance**: Better optimization for modern browsers

## Migration Breaking Changes

### CSS Imports
**v3**:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**v4**:
```css
@import "tailwindcss";
```

### Configuration Location
**v3**: JavaScript config file
**v4**: CSS-based configuration using `@theme`

### Plugin System
**v3**: Plugins in JavaScript config
**v4**: Plugins need updates for v4 compatibility

## Color System Changes

### Color Definition
**v3**: JavaScript object
```javascript
colors: {
  'brand': {
    50: '#eff6ff',
    500: '#3b82f6',
    900: '#1e3a8a'
  }
}
```

**v4**: CSS variables
```css
@theme {
  --color-brand-50: #eff6ff;
  --color-brand-500: #3b82f6;
  --color-brand-900: #1e3a8a;
}
```

### Opacity Handling
**v3**: Separate opacity utilities
```html
<div class="bg-blue-500 bg-opacity-50"></div>
```

**v4**: Integrated opacity syntax
```html
<div class="bg-blue-500/50"></div>
```

## Development Experience

### IntelliSense
**v3**: Good IDE support
**v4**: Enhanced IntelliSense with dynamic values

### Hot Reloading
**v3**: Fast hot reloading
**v4**: Even faster with Oxide engine

### Error Messages
**v4**: Improved error messages and debugging

## Plugin Ecosystem

### Core Plugins
**v3**: Many built-in plugins
**v4**: Streamlined core, some plugins need updates

### Third-Party Plugins
**v3**: Extensive ecosystem
**v4**: Many plugins need v4 compatibility updates

### Custom Plugins
**v3**: JavaScript-based
**v4**: May need migration to work with new architecture

## Framework Integration

### Vite
**v3**: PostCSS plugin
**v4**: Dedicated `@tailwindcss/vite` plugin for better performance

### Next.js
**v3**: Works well
**v4**: PostCSS plugin recommended, some configuration changes needed

### Other Frameworks
**v3**: Universal PostCSS compatibility
**v4**: PostCSS plugin maintains compatibility

## Production Considerations

### Build Process
**v3**: Reliable and well-tested
**v4**: New build system with better performance

### Deployment
**v3**: Mature deployment patterns
**v4**: Same deployment patterns, smaller bundles

### Monitoring
**v3**: Established monitoring practices
**v4**: New performance characteristics to monitor

## Migration Strategy

### When to Migrate
**Migrate to v4 when**:
- Starting new projects
- Want better performance
- Can drop older browser support
- Using modern CSS features

**Stay on v3 when**:
- Need IE/older browser support
- Large existing project with many customizations
- Using many third-party plugins
- Team not ready for configuration changes

### Migration Process
1. **Assess compatibility**: Check browser requirements
2. **Update dependencies**: Install v4 packages
3. **Migrate configuration**: JS to CSS
4. **Test thoroughly**: Verify all styles work
5. **Update build process**: Use appropriate plugin
6. **Train team**: New configuration approach

## Future Considerations

### v4 Advantages
- Better performance and smaller bundles
- Modern CSS feature support
- Future-proof architecture
- Improved developer experience

### v3 Advantages
- Mature ecosystem
- Broader browser support
- Established patterns
- Large community knowledge base

### Recommendation
- **New projects**: Use v4 for better performance
- **Existing projects**: Evaluate migration carefully
- **Legacy support**: Consider staying on v3 until ready

## Common Gotchas

### Configuration Mixing
**Problem**: Using v3 config syntax with v4 installation
**Solution**: Use only CSS-based configuration in v4

### Plugin Compatibility
**Problem**: v3 plugins may not work with v4
**Solution**: Check plugin v4 compatibility or find alternatives

### Build Tool Configuration
**Problem**: Incorrect PostCSS setup for v4
**Solution**: Use `@tailwindcss/postcss` package, not main package

### Browser Support
**Problem**: Styles not working in older browsers
**Solution**: Check browser compatibility requirements for v4
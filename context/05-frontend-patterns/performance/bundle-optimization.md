# Bundle Optimization

Comprehensive guide to optimizing JavaScript bundles for smaller sizes and faster load times.

## Webpack/Vite Configuration

```javascript
// vite.config.js - Optimized build configuration
import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    // Enable code splitting
    rollupOptions: {
      output: {
        manualChunks: {
          // Vendor chunks
          vendor: ['react', 'react-dom'],
          ui: ['@headlessui/react', 'framer-motion'],
          utils: ['lodash', 'date-fns'],
          
          // Route-based chunks
          home: ['./src/pages/Home'],
          dashboard: ['./src/pages/Dashboard'],
        }
      }
    },
    
    // Optimize chunk sizes
    chunkSizeWarningLimit: 1000,
    
    // Enable minification
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  },
  
  // Optimize dependencies
  optimizeDeps: {
    include: ['react', 'react-dom'],
    exclude: ['@vite/client', '@vite/env']
  },
  
  // Enable CSS code splitting
  css: {
    codeStyle: 'split'
  }
})

// webpack.config.js - Advanced optimization
module.exports = {
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
        },
        common: {
          name: 'common',
          minChunks: 2,
          chunks: 'all',
          enforce: true
        }
      }
    },
    
    // Tree shaking configuration
    usedExports: true,
    sideEffects: false,
    
    // Runtime chunk for better caching
    runtimeChunk: 'single'
  },
  
  // Module resolution optimization
  resolve: {
    modules: ['node_modules'],
    extensions: ['.js', '.jsx', '.ts', '.tsx'],
    alias: {
      '@': resolve(__dirname, 'src')
    }
  }
}
```

## Tree Shaking Optimization

```javascript
// Optimize imports for better tree shaking
// ❌ Bad - imports entire library
import _ from 'lodash'
import * as icons from 'lucide-react'

// ✅ Good - imports only what's needed
import { debounce, throttle } from 'lodash'
import { Search, User, Settings } from 'lucide-react'

// ❌ Bad - side effects prevent tree shaking
import 'some-library/styles.css'
import 'some-library' // This might import everything

// ✅ Good - explicit imports
import { specificFunction } from 'some-library/specific-module'
import 'some-library/styles.css' // If needed, mark as side effect

// Package.json configuration for tree shaking
{
  "sideEffects": [
    "*.css",
    "*.scss",
    "./src/polyfills.js"
  ]
}

// Mark specific imports as side-effect free
import /*#__PURE__*/ { heavyFunction } from './utils'

// Conditional imports for better tree shaking
const isDevelopment = process.env.NODE_ENV === 'development'

// Only import in development
if (isDevelopment) {
  import('./dev-tools').then(({ setupDevTools }) => {
    setupDevTools()
  })
}

// Use dynamic imports for optional features
async function loadOptionalFeature() {
  if (shouldLoadFeature) {
    const { OptionalComponent } = await import('./OptionalFeature')
    return OptionalComponent
  }
  return null
}
```

## Advanced Bundle Analysis

```javascript
// Bundle analyzer setup
import { visualizer } from 'rollup-plugin-visualizer'
import { BundleAnalyzerPlugin } from 'webpack-bundle-analyzer'

// Vite config with analyzer
export default defineConfig({
  plugins: [
    visualizer({
      filename: './dist/stats.html',
      open: true,
      gzipSize: true,
      brotliSize: true,
    })
  ]
})

// Webpack config with analyzer
module.exports = {
  plugins: [
    new BundleAnalyzerPlugin({
      analyzerMode: 'static',
      generateStatsFile: true,
      statsOptions: { source: false }
    })
  ]
}

// Custom bundle size monitoring
class BundleSizePlugin {
  apply(compiler) {
    compiler.hooks.done.tap('BundleSizePlugin', (stats) => {
      const assets = stats.compilation.assets
      const sizes = {}
      
      Object.keys(assets).forEach(filename => {
        if (filename.endsWith('.js') || filename.endsWith('.css')) {
          sizes[filename] = {
            size: assets[filename].size(),
            gzip: gzipSize.sync(assets[filename].source())
          }
        }
      })
      
      console.table(sizes)
      
      // Check against budget
      const totalSize = Object.values(sizes)
        .reduce((sum, { size }) => sum + size, 0)
      
      if (totalSize > 500000) { // 500KB
        console.warn('⚠️ Bundle size exceeds budget!')
      }
    })
  }
}
```

## Dynamic Import Strategies

```javascript
// Route-based code splitting with React
const routes = [
  {
    path: '/',
    component: () => import('./pages/Home'),
    preload: true // Preload critical routes
  },
  {
    path: '/dashboard',
    component: () => import('./pages/Dashboard'),
    preload: false
  },
  {
    path: '/settings',
    component: () => import('./pages/Settings'),
    preload: false
  }
]

// Preload critical routes
routes
  .filter(route => route.preload)
  .forEach(route => {
    route.component()
  })

// Component-level code splitting
const HeavyComponent = lazy(() => 
  import(/* webpackChunkName: "heavy-component" */ './HeavyComponent')
)

// Conditional loading based on viewport
const loadMapComponent = () => {
  if (window.innerWidth > 768) {
    return import('./DesktopMap')
  } else {
    return import('./MobileMap')
  }
}

// Progressive enhancement
class FeatureLoader {
  constructor() {
    this.loaded = new Set()
  }
  
  async loadFeature(featureName) {
    if (this.loaded.has(featureName)) {
      return this[featureName]
    }
    
    const features = {
      charts: () => import('./features/charts'),
      editor: () => import('./features/editor'),
      analytics: () => import('./features/analytics')
    }
    
    if (features[featureName]) {
      const module = await features[featureName]()
      this[featureName] = module.default
      this.loaded.add(featureName)
      return module.default
    }
    
    throw new Error(`Unknown feature: ${featureName}`)
  }
}
```

## Library Optimization

```javascript
// Replace heavy libraries with lighter alternatives
// Before: 70KB
import moment from 'moment'
const formatted = moment(date).format('YYYY-MM-DD')

// After: 12KB
import { format } from 'date-fns'
const formatted = format(date, 'yyyy-MM-dd')

// Use modular imports
// Before: imports entire library
import * as R from 'ramda'
const result = R.pipe(R.map(x => x * 2), R.filter(x => x > 10))(data)

// After: imports only needed functions
import pipe from 'ramda/src/pipe'
import map from 'ramda/src/map'
import filter from 'ramda/src/filter'
const result = pipe(map(x => x * 2), filter(x => x > 10))(data)

// Create aliases for common combinations
// utils/lodash-optimized.js
export { debounce, throttle } from 'lodash-es/debounce'
export { get, set } from 'lodash-es/get'
export { cloneDeep } from 'lodash-es/cloneDeep'

// Use native alternatives when possible
// Before
import { isArray, isObject } from 'lodash'

// After
const isArray = Array.isArray
const isObject = (val) => val !== null && typeof val === 'object'
```

## CSS Optimization

```javascript
// Extract critical CSS
import { extractCritical } from '@emotion/server'

// Server-side critical CSS extraction
const html = renderToString(<App />)
const { css, ids } = extractCritical(html)

// Inline critical CSS
const finalHtml = `
  <html>
    <head>
      <style>${css}</style>
    </head>
    <body>
      <div id="root">${html}</div>
    </body>
  </html>
`

// PurgeCSS configuration
module.exports = {
  content: [
    './src/**/*.{js,jsx,ts,tsx}',
    './public/index.html',
  ],
  safelist: [
    // Dynamic classes
    /^bg-/,
    /^text-/,
  ],
  blocklist: [
    // Remove unused utilities
    'container',
    /^debug-/,
  ]
}

// CSS modules with tree shaking
// styles.module.css
.button { /* used */ }
.unused { /* will be removed */ }

// component.js
import styles from './styles.module.css'
// Only 'button' class will be included
<button className={styles.button}>Click</button>
```

## Asset Optimization

```javascript
// Image optimization with responsive loading
const ImageOptimizer = {
  generateSrcSet(imagePath) {
    const sizes = [320, 640, 1024, 1920]
    return sizes
      .map(size => `${imagePath}?w=${size} ${size}w`)
      .join(', ')
  },
  
  generateSizes() {
    return '(max-width: 320px) 280px, (max-width: 640px) 600px, 1024px'
  }
}

// Lazy load images
const LazyImage = ({ src, alt, ...props }) => {
  const [imageSrc, setImageSrc] = useState(null)
  const imageRef = useRef()
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setImageSrc(src)
          observer.disconnect()
        }
      },
      { threshold: 0.1 }
    )
    
    if (imageRef.current) {
      observer.observe(imageRef.current)
    }
    
    return () => observer.disconnect()
  }, [src])
  
  return (
    <img
      ref={imageRef}
      src={imageSrc}
      alt={alt}
      loading="lazy"
      {...props}
    />
  )
}

// Font optimization
const FontLoader = {
  preloadFonts() {
    const fonts = [
      '/fonts/inter-var.woff2',
      '/fonts/inter-var-italic.woff2'
    ]
    
    fonts.forEach(font => {
      const link = document.createElement('link')
      link.rel = 'preload'
      link.as = 'font'
      link.type = 'font/woff2'
      link.href = font
      link.crossOrigin = 'anonymous'
      document.head.appendChild(link)
    })
  },
  
  // Use font-display: swap
  loadFonts() {
    const style = document.createElement('style')
    style.textContent = `
      @font-face {
        font-family: 'Inter';
        src: url('/fonts/inter-var.woff2') format('woff2');
        font-display: swap;
        font-weight: 100 900;
      }
    `
    document.head.appendChild(style)
  }
}
```

## Module Federation

```javascript
// Host application configuration
const { ModuleFederationPlugin } = require('webpack').container

module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'host',
      remotes: {
        app1: 'app1@http://localhost:3001/remoteEntry.js',
        app2: 'app2@http://localhost:3002/remoteEntry.js',
      },
      shared: {
        react: { singleton: true, requiredVersion: '^18.0.0' },
        'react-dom': { singleton: true, requiredVersion: '^18.0.0' },
      },
    }),
  ],
}

// Remote application configuration
module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'app1',
      filename: 'remoteEntry.js',
      exposes: {
        './Button': './src/components/Button',
        './Header': './src/components/Header',
      },
      shared: {
        react: { singleton: true, requiredVersion: '^18.0.0' },
        'react-dom': { singleton: true, requiredVersion: '^18.0.0' },
      },
    }),
  ],
}

// Dynamic remote loading
const loadRemoteModule = async (scope, module) => {
  await __webpack_init_sharing__('default')
  const container = window[scope]
  await container.init(__webpack_share_scopes__.default)
  const factory = await container.get(module)
  return factory()
}

// Usage
const RemoteButton = lazy(() => loadRemoteModule('app1', './Button'))
```
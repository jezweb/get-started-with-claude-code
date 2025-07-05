# Core Web Vitals

Understanding and optimizing Google's user experience metrics for better performance and SEO.

## Understanding the Metrics

```javascript
// Web Vitals measurement
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals'

function sendToAnalytics(metric) {
  // Send to your analytics service
  console.log(metric)
}

// Measure all Core Web Vitals
getCLS(sendToAnalytics)  // Cumulative Layout Shift
getFID(sendToAnalytics)  // First Input Delay
getFCP(sendToAnalytics)  // First Contentful Paint
getLCP(sendToAnalytics)  // Largest Contentful Paint
getTTFB(sendToAnalytics) // Time to First Byte

// Performance Observer for custom metrics
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.entryType === 'navigation') {
      console.log('Page Load Time:', entry.loadEventEnd - entry.loadEventStart)
    }
    
    if (entry.entryType === 'paint') {
      console.log(`${entry.name}:`, entry.startTime)
    }
  }
})

observer.observe({ entryTypes: ['navigation', 'paint', 'largest-contentful-paint'] })
```

## Optimizing Core Web Vitals

### Cumulative Layout Shift (CLS) Optimization

```javascript
// 1. Always include size attributes for images and videos
<img src="hero.jpg" width="800" height="400" alt="Hero image" />

// 2. Use aspect-ratio CSS to reserve space
.video-container {
  aspect-ratio: 16 / 9;
  width: 100%;
}

// 3. Avoid inserting content above existing content
// Bad: Dynamically inserting banner
const banner = document.createElement('div')
document.body.insertBefore(banner, document.body.firstChild)

// Good: Reserve space for dynamic content
<div className="banner-placeholder min-h-16">
  {showBanner && <Banner />}
</div>
```

### First Input Delay (FID) Optimization

```javascript
// 1. Break up long tasks
function processLargeDataset(data) {
  const chunkSize = 100
  let index = 0
  
  function processChunk() {
    const endIndex = Math.min(index + chunkSize, data.length)
    
    for (let i = index; i < endIndex; i++) {
      // Process data[i]
      processItem(data[i])
    }
    
    index = endIndex
    
    if (index < data.length) {
      // Use scheduler if available, otherwise setTimeout
      if (typeof scheduler?.postTask === 'function') {
        scheduler.postTask(processChunk, { priority: 'background' })
      } else {
        setTimeout(processChunk, 0)
      }
    }
  }
  
  processChunk()
}

// 2. Use Web Workers for heavy computations
// worker.js
self.addEventListener('message', (e) => {
  const result = performHeavyCalculation(e.data)
  self.postMessage(result)
})

// main.js
const worker = new Worker('worker.js')
worker.postMessage(largeData)
worker.onmessage = (e) => {
  updateUI(e.data)
}
```

### Largest Contentful Paint (LCP) Optimization

```javascript
// 1. Preload critical resources
<link rel="preload" as="image" href="hero-image.jpg" />
<link rel="preload" as="font" href="main-font.woff2" crossorigin />

// 2. Optimize server response times
// Use CDN for static assets
const imageUrl = process.env.NODE_ENV === 'production'
  ? 'https://cdn.example.com/images/hero.jpg'
  : '/images/hero.jpg'

// 3. Use responsive images
<picture>
  <source media="(max-width: 768px)" srcset="hero-mobile.jpg" />
  <source media="(min-width: 769px)" srcset="hero-desktop.jpg" />
  <img src="hero-fallback.jpg" alt="Hero" loading="eager" />
</picture>
```

## Real-time Performance Monitoring

```javascript
class PerformanceMonitor {
  constructor() {
    this.metrics = {}
    this.init()
  }

  init() {
    // Monitor paint timing
    this.observePaintTiming()
    
    // Monitor long tasks
    this.observeLongTasks()
    
    // Monitor layout shifts
    this.observeLayoutShifts()
    
    // Monitor user interactions
    this.observeInteractions()
  }

  observePaintTiming() {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        this.metrics[entry.name] = entry.startTime
        
        // Send critical metrics immediately
        if (entry.name === 'first-contentful-paint') {
          this.sendMetric('FCP', entry.startTime)
        }
      }
    })
    
    observer.observe({ entryTypes: ['paint'] })
  }

  observeLongTasks() {
    if ('PerformanceObserver' in window && 'PerformanceLongTaskTiming' in window) {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          // Log tasks longer than 50ms
          if (entry.duration > 50) {
            this.sendMetric('longTask', {
              duration: entry.duration,
              startTime: entry.startTime,
              attribution: entry.attribution
            })
          }
        }
      })
      
      observer.observe({ entryTypes: ['longtask'] })
    }
  }

  observeLayoutShifts() {
    let clsScore = 0
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (!entry.hadRecentInput) {
          clsScore += entry.value
          this.metrics.CLS = clsScore
        }
      }
    })
    
    observer.observe({ type: 'layout-shift', buffered: true })
  }

  observeInteractions() {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        const eventType = entry.name
        const duration = entry.processingEnd - entry.processingStart
        
        this.sendMetric('interaction', {
          type: eventType,
          duration: duration,
          delay: entry.processingStart - entry.startTime
        })
      }
    })
    
    observer.observe({ type: 'event', buffered: true })
  }

  sendMetric(name, value) {
    // Send to analytics
    if (typeof gtag !== 'undefined') {
      gtag('event', 'performance_metric', {
        metric_name: name,
        metric_value: typeof value === 'object' ? JSON.stringify(value) : value,
        page_url: window.location.href
      })
    }
  }

  getMetrics() {
    return this.metrics
  }
}

// Initialize monitoring
const perfMonitor = new PerformanceMonitor()
```

## Optimizing for Specific Metrics

### Time to First Byte (TTFB)
```javascript
// 1. Server-side optimizations
// Use edge computing
export const config = {
  runtime: 'edge'
}

export default function handler(request) {
  // Process at edge location closest to user
  return new Response('Hello from the edge!')
}

// 2. Implement effective caching
// Service Worker with cache-first strategy
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request).then((fetchResponse) => {
        return caches.open('v1').then((cache) => {
          cache.put(event.request, fetchResponse.clone())
          return fetchResponse
        })
      })
    })
  )
})

// 3. Use resource hints
<link rel="dns-prefetch" href="https://api.example.com" />
<link rel="preconnect" href="https://api.example.com" />
```

### First Contentful Paint (FCP)
```javascript
// 1. Inline critical CSS
const critical = require('critical')

critical.generate({
  base: 'dist/',
  src: 'index.html',
  target: {
    html: 'index-critical.html',
    css: 'critical.css'
  },
  inline: true,
  width: 1300,
  height: 900
})

// 2. Optimize font loading
// Use font-display: swap
@font-face {
  font-family: 'CustomFont';
  src: url('font.woff2') format('woff2');
  font-display: swap;
}

// 3. Reduce render-blocking resources
// Load non-critical CSS asynchronously
<link rel="preload" href="styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="styles.css"></noscript>
```

## Performance Budget Implementation

```javascript
// webpack.config.js
module.exports = {
  performance: {
    maxAssetSize: 244000, // 244 KB
    maxEntrypointSize: 244000,
    hints: 'error',
    
    assetFilter: function(assetFilename) {
      // Only apply to JS and CSS files
      return assetFilename.endsWith('.js') || assetFilename.endsWith('.css')
    }
  }
}

// Performance budget monitoring
class PerformanceBudget {
  constructor(budgets) {
    this.budgets = budgets
    this.violations = []
  }

  check() {
    // Check JavaScript size
    this.checkResourceSize('script', this.budgets.javascript)
    
    // Check CSS size
    this.checkResourceSize('style', this.budgets.css)
    
    // Check image sizes
    this.checkResourceSize('img', this.budgets.images)
    
    // Check Core Web Vitals
    this.checkWebVitals()
    
    return this.violations
  }

  checkResourceSize(type, maxSize) {
    const resources = performance.getEntriesByType('resource')
    const typeResources = resources.filter(r => {
      if (type === 'script') return r.name.endsWith('.js')
      if (type === 'style') return r.name.endsWith('.css')
      if (type === 'img') return /\.(jpg|jpeg|png|gif|webp)$/i.test(r.name)
      return false
    })

    const totalSize = typeResources.reduce((sum, r) => sum + r.transferSize, 0)
    
    if (totalSize > maxSize) {
      this.violations.push({
        type: `${type}-size`,
        actual: totalSize,
        budget: maxSize,
        difference: totalSize - maxSize
      })
    }
  }

  checkWebVitals() {
    // Check against budgets
    getCLS((metric) => {
      if (metric.value > this.budgets.cls) {
        this.violations.push({
          type: 'cls',
          actual: metric.value,
          budget: this.budgets.cls
        })
      }
    })

    getLCP((metric) => {
      if (metric.value > this.budgets.lcp) {
        this.violations.push({
          type: 'lcp',
          actual: metric.value,
          budget: this.budgets.lcp
        })
      }
    })

    getFID((metric) => {
      if (metric.value > this.budgets.fid) {
        this.violations.push({
          type: 'fid',
          actual: metric.value,
          budget: this.budgets.fid
        })
      }
    })
  }
}

// Define budgets
const budgets = {
  javascript: 200 * 1024,  // 200 KB
  css: 50 * 1024,         // 50 KB
  images: 500 * 1024,     // 500 KB per image
  cls: 0.1,               // Good CLS
  lcp: 2500,              // 2.5s - Good LCP
  fid: 100                // 100ms - Good FID
}

const budgetChecker = new PerformanceBudget(budgets)
window.addEventListener('load', () => {
  setTimeout(() => {
    const violations = budgetChecker.check()
    if (violations.length > 0) {
      console.warn('Performance budget violations:', violations)
      // Send to monitoring service
    }
  }, 5000) // Wait for all metrics to be collected
})
```
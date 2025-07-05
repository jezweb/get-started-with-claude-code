# Image Optimization

Modern techniques for optimizing images to improve loading performance and user experience.

## Modern Image Techniques

```jsx
// Responsive images with modern formats
function OptimizedImage({ 
  src, 
  alt, 
  width, 
  height, 
  className,
  priority = false,
  sizes = "100vw"
}) {
  const webpSrc = src.replace(/\.(jpg|jpeg|png)$/, '.webp')
  const avifSrc = src.replace(/\.(jpg|jpeg|png)$/, '.avif')
  
  return (
    <picture>
      {/* Modern formats first */}
      <source srcSet={avifSrc} type="image/avif" />
      <source srcSet={webpSrc} type="image/webp" />
      
      {/* Fallback */}
      <img
        src={src}
        alt={alt}
        width={width}
        height={height}
        className={className}
        loading={priority ? "eager" : "lazy"}
        decoding="async"
        sizes={sizes}
      />
    </picture>
  )
}

// Progressive image loading
function ProgressiveImage({ src, placeholder, alt, ...props }) {
  const [imageSrc, setImageSrc] = useState(placeholder)
  const [isLoaded, setIsLoaded] = useState(false)
  
  useEffect(() => {
    const img = new Image()
    img.onload = () => {
      setImageSrc(src)
      setIsLoaded(true)
    }
    img.src = src
  }, [src])
  
  return (
    <div className="relative overflow-hidden">
      <img
        src={imageSrc}
        alt={alt}
        className={`transition-opacity duration-300 ${
          isLoaded ? 'opacity-100' : 'opacity-0'
        }`}
        {...props}
      />
      
      {!isLoaded && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse" />
      )}
    </div>
  )
}

// Image preloading hook
function useImagePreloader(imageUrls) {
  const [loadedImages, setLoadedImages] = useState(new Set())
  
  useEffect(() => {
    const preloadImage = (url) => {
      return new Promise((resolve, reject) => {
        const img = new Image()
        img.onload = () => resolve(url)
        img.onerror = reject
        img.src = url
      })
    }
    
    Promise.allSettled(imageUrls.map(preloadImage))
      .then(results => {
        const loaded = results
          .filter(result => result.status === 'fulfilled')
          .map(result => result.value)
        
        setLoadedImages(new Set(loaded))
      })
  }, [imageUrls])
  
  return loadedImages
}

// Next.js Image optimization
import Image from 'next/image'

function OptimizedImageGallery({ images }) {
  return (
    <div className="grid grid-cols-3 gap-4">
      {images.map((image, index) => (
        <Image
          key={image.id}
          src={image.src}
          alt={image.alt}
          width={400}
          height={300}
          priority={index < 3} // Prioritize first 3 images
          placeholder="blur"
          blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..." // Low quality placeholder
          sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
        />
      ))}
    </div>
  )
}
```

## Lazy Loading with Intersection Observer

```jsx
// Advanced lazy loading component
function LazyImage({ 
  src, 
  alt, 
  placeholder, 
  threshold = 0.1,
  rootMargin = '50px',
  onLoad,
  ...props 
}) {
  const [imageSrc, setImageSrc] = useState(placeholder || '')
  const [isIntersecting, setIsIntersecting] = useState(false)
  const imageRef = useRef(null)
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsIntersecting(true)
          observer.disconnect()
        }
      },
      { threshold, rootMargin }
    )
    
    if (imageRef.current) {
      observer.observe(imageRef.current)
    }
    
    return () => observer.disconnect()
  }, [threshold, rootMargin])
  
  useEffect(() => {
    if (isIntersecting && src) {
      const img = new Image()
      img.onload = () => {
        setImageSrc(src)
        onLoad?.()
      }
      img.src = src
    }
  }, [isIntersecting, src, onLoad])
  
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

// Lazy loading with blur-up effect
function BlurUpImage({ src, alt, blurSrc, ...props }) {
  const [currentSrc, setCurrentSrc] = useState(blurSrc)
  const [isLoaded, setIsLoaded] = useState(false)
  
  return (
    <div className="relative">
      <img
        src={currentSrc}
        alt={alt}
        className={`
          transition-all duration-300
          ${!isLoaded ? 'filter blur-lg scale-110' : 'filter-none scale-100'}
        `}
        {...props}
      />
      <LazyImage
        src={src}
        alt=""
        className="absolute inset-0 opacity-0"
        onLoad={() => {
          setCurrentSrc(src)
          setIsLoaded(true)
        }}
      />
    </div>
  )
}
```

## Responsive Images

```jsx
// Responsive image with srcset
function ResponsiveImage({ 
  src, 
  alt, 
  sizes = '100vw',
  widths = [320, 640, 768, 1024, 1280, 1536]
}) {
  const generateSrcSet = () => {
    return widths
      .map(width => {
        const url = src.replace(/(\.\w+)$/, `-${width}$1`)
        return `${url} ${width}w`
      })
      .join(', ')
  }
  
  return (
    <img
      src={src}
      srcSet={generateSrcSet()}
      sizes={sizes}
      alt={alt}
      loading="lazy"
    />
  )
}

// Art direction with picture element
function ArtDirectedImage({ desktop, tablet, mobile, alt }) {
  return (
    <picture>
      <source
        media="(min-width: 1024px)"
        srcSet={desktop.src}
        width={desktop.width}
        height={desktop.height}
      />
      <source
        media="(min-width: 768px)"
        srcSet={tablet.src}
        width={tablet.width}
        height={tablet.height}
      />
      <img
        src={mobile.src}
        alt={alt}
        width={mobile.width}
        height={mobile.height}
        loading="lazy"
      />
    </picture>
  )
}

// Dynamic sizing based on container
function ContainerAwareImage({ src, alt }) {
  const containerRef = useRef(null)
  const [containerWidth, setContainerWidth] = useState(0)
  
  useEffect(() => {
    const observer = new ResizeObserver(entries => {
      for (const entry of entries) {
        setContainerWidth(entry.contentRect.width)
      }
    })
    
    if (containerRef.current) {
      observer.observe(containerRef.current)
    }
    
    return () => observer.disconnect()
  }, [])
  
  const getOptimalSrc = () => {
    const dpr = window.devicePixelRatio || 1
    const width = Math.ceil(containerWidth * dpr)
    
    // Round to nearest breakpoint
    const breakpoints = [320, 640, 768, 1024, 1280, 1536, 1920]
    const optimalWidth = breakpoints.find(bp => bp >= width) || breakpoints[breakpoints.length - 1]
    
    return src.replace(/(\.\w+)$/, `-${optimalWidth}$1`)
  }
  
  return (
    <div ref={containerRef} className="w-full">
      {containerWidth > 0 && (
        <img
          src={getOptimalSrc()}
          alt={alt}
          className="w-full h-auto"
          loading="lazy"
        />
      )}
    </div>
  )
}
```

## Image Format Optimization

```javascript
// Automatic format selection
class ImageOptimizer {
  static supportsWebP() {
    const canvas = document.createElement('canvas')
    canvas.width = 1
    canvas.height = 1
    return canvas.toDataURL('image/webp').indexOf('image/webp') === 0
  }
  
  static supportsAvif() {
    const image = new Image()
    return image.decode !== undefined
  }
  
  static getOptimalFormat(originalFormat) {
    if (this.supportsAvif()) return 'avif'
    if (this.supportsWebP()) return 'webp'
    return originalFormat
  }
  
  static generateOptimalSrc(src) {
    const format = this.getOptimalFormat('jpg')
    return src.replace(/\.(jpg|jpeg|png)$/, `.${format}`)
  }
}

// Image transformation service
class ImageTransformService {
  constructor(baseUrl) {
    this.baseUrl = baseUrl
  }
  
  transform(src, options = {}) {
    const params = new URLSearchParams({
      w: options.width || '',
      h: options.height || '',
      q: options.quality || 80,
      fm: options.format || 'auto',
      fit: options.fit || 'crop',
      dpr: window.devicePixelRatio || 1
    })
    
    return `${this.baseUrl}/${src}?${params}`
  }
  
  generateSrcSet(src, widths = [320, 640, 1024, 1920]) {
    return widths
      .map(width => {
        const url = this.transform(src, { width })
        return `${url} ${width}w`
      })
      .join(', ')
  }
}
```

## Placeholder Strategies

```jsx
// Base64 blur placeholder
function generateBlurPlaceholder(width, height) {
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')
  
  // Create gradient placeholder
  const gradient = ctx.createLinearGradient(0, 0, width, height)
  gradient.addColorStop(0, '#f0f0f0')
  gradient.addColorStop(1, '#e0e0e0')
  ctx.fillStyle = gradient
  ctx.fillRect(0, 0, width, height)
  
  return canvas.toDataURL('image/jpeg', 0.1)
}

// SVG placeholder with shimmer effect
function ShimmerPlaceholder({ width, height }) {
  return (
    <svg
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient id="shimmer" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#f0f0f0" />
          <stop offset="50%" stopColor="#e0e0e0" />
          <stop offset="100%" stopColor="#f0f0f0" />
        </linearGradient>
      </defs>
      <rect width={width} height={height} fill="url(#shimmer)">
        <animate
          attributeName="x"
          from={-width}
          to={width}
          dur="1.5s"
          repeatCount="indefinite"
        />
      </rect>
    </svg>
  )
}

// Dominant color placeholder
async function extractDominantColor(imageSrc) {
  return new Promise((resolve) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      canvas.width = img.width
      canvas.height = img.height
      ctx.drawImage(img, 0, 0)
      
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      const data = imageData.data
      
      let r = 0, g = 0, b = 0
      const pixelCount = data.length / 4
      
      for (let i = 0; i < data.length; i += 4) {
        r += data[i]
        g += data[i + 1]
        b += data[i + 2]
      }
      
      r = Math.floor(r / pixelCount)
      g = Math.floor(g / pixelCount)
      b = Math.floor(b / pixelCount)
      
      resolve(`rgb(${r}, ${g}, ${b})`)
    }
    img.src = imageSrc
  })
}
```

## Performance Monitoring

```javascript
// Image loading performance tracker
class ImagePerformanceTracker {
  constructor() {
    this.metrics = []
  }
  
  track(imageSrc) {
    const startTime = performance.now()
    const img = new Image()
    
    img.onload = () => {
      const loadTime = performance.now() - startTime
      const metric = {
        src: imageSrc,
        loadTime,
        size: img.naturalWidth * img.naturalHeight,
        timestamp: new Date().toISOString()
      }
      
      this.metrics.push(metric)
      this.reportMetric(metric)
    }
    
    img.onerror = () => {
      this.reportError(imageSrc)
    }
    
    img.src = imageSrc
  }
  
  reportMetric(metric) {
    // Send to analytics
    if (typeof gtag !== 'undefined') {
      gtag('event', 'image_load', {
        load_time: Math.round(metric.loadTime),
        image_size: metric.size,
        image_src: metric.src
      })
    }
  }
  
  reportError(src) {
    console.error(`Failed to load image: ${src}`)
    // Send error to monitoring service
  }
  
  getAverageLoadTime() {
    if (this.metrics.length === 0) return 0
    const sum = this.metrics.reduce((acc, m) => acc + m.loadTime, 0)
    return sum / this.metrics.length
  }
}

// Usage
const tracker = new ImagePerformanceTracker()
images.forEach(img => tracker.track(img.src))
```
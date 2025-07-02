# Cloudflare R2 - Object Storage

## Overview

Cloudflare R2 Storage provides S3-compatible object storage with zero egress fees, making it ideal for web applications that need cost-effective file storage and distribution. R2 integrates seamlessly with other Cloudflare services and offers global performance through Cloudflare's edge network.

## Quick Start

### Basic Setup
```javascript
// Workers environment
export default {
  async fetch(request, env) {
    // Access R2 bucket through environment binding
    const bucket = env.MY_BUCKET; // Configured in wrangler.toml
    
    // Upload a file
    const file = await request.formData().get('file');
    await bucket.put('uploads/' + file.name, file.stream());
    
    return new Response('File uploaded successfully');
  }
};
```

### Configuration
```toml
# wrangler.toml
[[r2_buckets]]
binding = "MY_BUCKET"
bucket_name = "my-app-storage"
```

## Core Concepts

### S3 Compatibility
R2 is fully compatible with the AWS S3 API, making migration straightforward:

```javascript
// Using AWS SDK v3 with R2
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({
  region: 'auto',
  endpoint: `https://${ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
  },
});

// Upload file
const uploadCommand = new PutObjectCommand({
  Bucket: 'my-bucket',
  Key: 'path/to/file.jpg',
  Body: fileBuffer,
  ContentType: 'image/jpeg',
});

await s3Client.send(uploadCommand);
```

### Object Operations
```javascript
// Workers R2 API - Direct integration
export default {
  async fetch(request, env) {
    const bucket = env.MY_BUCKET;
    const url = new URL(request.url);
    const key = url.pathname.slice(1); // Remove leading slash
    
    switch (request.method) {
      case 'PUT':
        // Upload file
        const file = await request.arrayBuffer();
        await bucket.put(key, file, {
          httpMetadata: {
            contentType: request.headers.get('content-type'),
            cacheControl: 'public, max-age=31536000',
          },
          customMetadata: {
            uploadedBy: 'user123',
            uploadDate: new Date().toISOString(),
          },
        });
        return new Response('Uploaded successfully');
        
      case 'GET':
        // Download file
        const object = await bucket.get(key);
        if (!object) {
          return new Response('File not found', { status: 404 });
        }
        
        return new Response(object.body, {
          headers: {
            'Content-Type': object.httpMetadata.contentType,
            'Cache-Control': object.httpMetadata.cacheControl,
            'ETag': object.httpEtag,
          },
        });
        
      case 'DELETE':
        // Delete file
        await bucket.delete(key);
        return new Response('Deleted successfully');
        
      case 'HEAD':
        // Get metadata
        const head = await bucket.head(key);
        if (!head) {
          return new Response('File not found', { status: 404 });
        }
        
        return new Response(null, {
          headers: {
            'Content-Length': head.size.toString(),
            'Content-Type': head.httpMetadata.contentType,
            'Last-Modified': head.uploaded.toUTCString(),
          },
        });
    }
    
    return new Response('Method not allowed', { status: 405 });
  }
};
```

## Integration Patterns

### 1. File Upload with Progress Tracking

```javascript
// Frontend file upload with progress
class FileUploader {
  constructor(apiEndpoint) {
    this.apiEndpoint = apiEndpoint;
  }
  
  async uploadFile(file, onProgress) {
    const formData = new FormData();
    formData.append('file', file);
    
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100;
          onProgress(percentComplete);
        }
      });
      
      xhr.onload = () => {
        if (xhr.status === 200) {
          resolve(JSON.parse(xhr.responseText));
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`));
        }
      };
      
      xhr.onerror = () => reject(new Error('Network error'));
      
      xhr.open('POST', `${this.apiEndpoint}/upload`);
      xhr.send(formData);
    });
  }
}

// Workers upload handler
export default {
  async fetch(request, env) {
    if (request.method === 'POST' && request.url.endsWith('/upload')) {
      const formData = await request.formData();
      const file = formData.get('file');
      
      if (!file) {
        return new Response('No file provided', { status: 400 });
      }
      
      // Generate unique filename
      const fileKey = `uploads/${Date.now()}-${file.name}`;
      
      // Upload to R2 with metadata
      await env.MY_BUCKET.put(fileKey, file.stream(), {
        httpMetadata: {
          contentType: file.type,
          cacheControl: 'public, max-age=31536000',
        },
        customMetadata: {
          originalName: file.name,
          uploadDate: new Date().toISOString(),
          fileSize: file.size.toString(),
        },
      });
      
      return Response.json({
        success: true,
        fileKey,
        downloadUrl: `/download/${fileKey}`,
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

### 2. Signed URLs for Direct Upload

```javascript
// Generate signed URLs for direct client uploads
import { SignedURL } from '@aws-sdk/s3-request-presigner';
import { PutObjectCommand } from '@aws-sdk/client-s3';

export default {
  async fetch(request, env) {
    if (request.method === 'POST' && request.url.endsWith('/signed-upload')) {
      const { filename, contentType } = await request.json();
      
      const key = `uploads/${Date.now()}-${filename}`;
      
      const command = new PutObjectCommand({
        Bucket: env.BUCKET_NAME,
        Key: key,
        ContentType: contentType,
      });
      
      // Generate signed URL (expires in 1 hour)
      const signedUrl = await getSignedUrl(env.S3_CLIENT, command, {
        expiresIn: 3600,
      });
      
      return Response.json({
        signedUrl,
        key,
        fields: {
          'Content-Type': contentType,
        },
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

### 3. Image Optimization Pipeline

```javascript
// Automatic image optimization and variant generation
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const imagePath = url.pathname.slice(1);
    
    // Check for resize parameters
    const width = url.searchParams.get('w');
    const height = url.searchParams.get('h');
    const quality = url.searchParams.get('q') || '85';
    const format = url.searchParams.get('f') || 'webp';
    
    // Generate cache key for variants
    const cacheKey = `${imagePath}?w=${width}&h=${height}&q=${quality}&f=${format}`;
    
    // Check KV cache first
    const cached = await env.IMAGE_CACHE.get(cacheKey, 'arrayBuffer');
    if (cached) {
      return new Response(cached, {
        headers: {
          'Content-Type': `image/${format}`,
          'Cache-Control': 'public, max-age=31536000',
        },
      });
    }
    
    // Get original image from R2
    const originalImage = await env.MY_BUCKET.get(imagePath);
    if (!originalImage) {
      return new Response('Image not found', { status: 404 });
    }
    
    // Process image (using Cloudflare Images or external service)
    const processedImage = await processImage(originalImage.body, {
      width: parseInt(width),
      height: parseInt(height),
      quality: parseInt(quality),
      format,
    });
    
    // Cache processed image
    await env.IMAGE_CACHE.put(cacheKey, processedImage, {
      expirationTtl: 86400 * 7, // 7 days
    });
    
    return new Response(processedImage, {
      headers: {
        'Content-Type': `image/${format}`,
        'Cache-Control': 'public, max-age=31536000',
      },
    });
  }
};

async function processImage(imageBuffer, options) {
  // Implement image processing logic
  // This could use Cloudflare Images, Sharp, or external API
  return imageBuffer; // Placeholder
}
```

## Advanced Features

### 1. Multipart Upload for Large Files

```javascript
// Handle large file uploads efficiently
class MultipartUploader {
  constructor(bucket, key) {
    this.bucket = bucket;
    this.key = key;
    this.parts = [];
  }
  
  async initiate() {
    this.uploadId = await this.bucket.createMultipartUpload(this.key);
    return this.uploadId;
  }
  
  async uploadPart(partNumber, data) {
    const part = await this.bucket.uploadPart(
      this.key,
      this.uploadId,
      partNumber,
      data
    );
    
    this.parts.push({
      PartNumber: partNumber,
      ETag: part.etag,
    });
    
    return part;
  }
  
  async complete() {
    return await this.bucket.completeMultipartUpload(
      this.key,
      this.uploadId,
      this.parts
    );
  }
  
  async abort() {
    return await this.bucket.abortMultipartUpload(this.key, this.uploadId);
  }
}
```

### 2. Lifecycle Management

```javascript
// Automated lifecycle management for cost optimization
export default {
  async scheduled(event, env, ctx) {
    const bucket = env.MY_BUCKET;
    
    // List objects older than 30 days
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    
    const objects = await bucket.list({
      prefix: 'temp/',
    });
    
    const expiredObjects = objects.objects.filter(
      obj => obj.uploaded < thirtyDaysAgo
    );
    
    // Delete expired objects
    for (const obj of expiredObjects) {
      await bucket.delete(obj.key);
      console.log(`Deleted expired object: ${obj.key}`);
    }
    
    // Archive old logs to cheaper storage class
    const archiveObjects = objects.objects.filter(
      obj =>
        obj.key.startsWith('logs/') &&
        obj.uploaded < new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
    );
    
    for (const obj of archiveObjects) {
      // Move to archive prefix (or implement storage class transition)
      const archiveKey = `archive/${obj.key}`;
      await bucket.put(archiveKey, await bucket.get(obj.key));
      await bucket.delete(obj.key);
    }
  }
};
```

### 3. Access Control and Security

```javascript
// Implement access control for sensitive files
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.pathname.slice(1);
    
    // Validate access token
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response('Unauthorized', { status: 401 });
    }
    
    const token = authHeader.slice(7);
    const userId = await validateAccessToken(token, env);
    
    if (!userId) {
      return new Response('Invalid token', { status: 401 });
    }
    
    // Check file permissions
    const hasAccess = await checkFileAccess(userId, key, env);
    if (!hasAccess) {
      return new Response('Forbidden', { status: 403 });
    }
    
    // Serve file with appropriate headers
    const object = await env.MY_BUCKET.get(key);
    if (!object) {
      return new Response('File not found', { status: 404 });
    }
    
    return new Response(object.body, {
      headers: {
        'Content-Type': object.httpMetadata.contentType,
        'Content-Disposition': 'attachment; filename="' + key + '"',
        'Cache-Control': 'private, no-cache',
      },
    });
  }
};

async function validateAccessToken(token, env) {
  // Implement JWT validation or lookup in KV
  try {
    const payload = jwt.verify(token, env.JWT_SECRET);
    return payload.userId;
  } catch {
    return null;
  }
}

async function checkFileAccess(userId, key, env) {
  // Check permissions in KV or database
  const permissions = await env.FILE_PERMISSIONS.get(`${userId}:${key}`);
  return permissions === 'read' || permissions === 'write';
}
```

## Performance Optimization

### 1. Intelligent Caching Strategy

```javascript
// Multi-layer caching for optimal performance
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.pathname.slice(1);
    const cacheKey = `r2:${key}`;
    
    // Layer 1: Edge cache (Cloudflare CDN)
    const cache = caches.default;
    let response = await cache.match(request);
    
    if (response) {
      return response;
    }
    
    // Layer 2: KV cache for metadata
    const metadata = await env.FILE_CACHE.get(cacheKey, 'json');
    
    // Layer 3: R2 storage
    const object = await env.MY_BUCKET.get(key);
    if (!object) {
      return new Response('File not found', { status: 404 });
    }
    
    // Create response with proper caching headers
    response = new Response(object.body, {
      headers: {
        'Content-Type': object.httpMetadata.contentType,
        'ETag': object.httpEtag,
        'Last-Modified': object.uploaded.toUTCString(),
        'Cache-Control': 'public, max-age=31536000, immutable',
        'Vary': 'Accept-Encoding',
      },
    });
    
    // Cache metadata in KV
    await env.FILE_CACHE.put(
      cacheKey,
      JSON.stringify({
        contentType: object.httpMetadata.contentType,
        size: object.size,
        etag: object.httpEtag,
        uploaded: object.uploaded.toISOString(),
      }),
      { expirationTtl: 86400 }
    );
    
    // Cache response at edge
    ctx.waitUntil(cache.put(request, response.clone()));
    
    return response;
  }
};
```

### 2. Batch Operations

```javascript
// Efficient batch operations for multiple files
export default {
  async fetch(request, env) {
    if (request.method === 'POST' && request.url.endsWith('/batch-upload')) {
      const formData = await request.formData();
      const files = formData.getAll('files');
      
      // Process uploads in parallel with concurrency limit
      const results = await Promise.allSettled(
        files.map(async (file, index) => {
          const key = `batch/${Date.now()}-${index}-${file.name}`;
          
          await env.MY_BUCKET.put(key, file.stream(), {
            httpMetadata: {
              contentType: file.type,
            },
            customMetadata: {
              batchId: formData.get('batchId'),
              originalName: file.name,
            },
          });
          
          return { key, originalName: file.name, size: file.size };
        })
      );
      
      const successful = results
        .filter(result => result.status === 'fulfilled')
        .map(result => result.value);
        
      const failed = results
        .filter(result => result.status === 'rejected')
        .map(result => result.reason);
      
      return Response.json({
        successful,
        failed,
        total: files.length,
      });
    }
    
    return new Response('Not found', { status: 404 });
  }
};
```

## Cost Optimization

### 1. Storage Class Management

```javascript
// Implement intelligent storage class transitions
export default {
  async scheduled(event, env, ctx) {
    const bucket = env.MY_BUCKET;
    
    // Analyze access patterns and move to appropriate storage class
    const objects = await bucket.list({
      include: ['customMetadata'],
    });
    
    for (const obj of objects.objects) {
      const accessCount = await getAccessCount(obj.key, env);
      const daysSinceUpload = Math.floor(
        (Date.now() - obj.uploaded.getTime()) / (1000 * 60 * 60 * 24)
      );
      
      // Move to cold storage if not accessed in 90 days
      if (daysSinceUpload > 90 && accessCount === 0) {
        await moveToStorageClass(obj.key, 'COLD', env);
      }
      
      // Move to archive if not accessed in 365 days
      if (daysSinceUpload > 365 && accessCount === 0) {
        await moveToStorageClass(obj.key, 'ARCHIVE', env);
      }
    }
  }
};

async function getAccessCount(key, env) {
  const stats = await env.ACCESS_STATS.get(`access:${key}`, 'json');
  return stats?.count || 0;
}

async function moveToStorageClass(key, storageClass, env) {
  // Implement storage class transition logic
  // This might involve copying to a different bucket or prefix
  console.log(`Moving ${key} to ${storageClass} storage class`);
}
```

### 2. Bandwidth Optimization

```javascript
// Optimize bandwidth usage with compression and CDN
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const key = url.pathname.slice(1);
    
    const object = await env.MY_BUCKET.get(key);
    if (!object) {
      return new Response('File not found', { status: 404 });
    }
    
    // Check if client accepts compression
    const acceptEncoding = request.headers.get('Accept-Encoding') || '';
    const supportsGzip = acceptEncoding.includes('gzip');
    const supportsBrotli = acceptEncoding.includes('br');
    
    let body = object.body;
    let contentEncoding = null;
    
    // Apply compression for text files
    if (object.httpMetadata.contentType?.startsWith('text/') ||
        object.httpMetadata.contentType?.includes('json') ||
        object.httpMetadata.contentType?.includes('javascript')) {
      
      if (supportsBrotli) {
        body = await compress(body, 'br');
        contentEncoding = 'br';
      } else if (supportsGzip) {
        body = await compress(body, 'gzip');
        contentEncoding = 'gzip';
      }
    }
    
    const headers = {
      'Content-Type': object.httpMetadata.contentType,
      'Cache-Control': 'public, max-age=31536000',
      'ETag': object.httpEtag,
    };
    
    if (contentEncoding) {
      headers['Content-Encoding'] = contentEncoding;
    }
    
    return new Response(body, { headers });
  }
};
```

## Testing Strategies

### 1. Unit Tests

```javascript
// Test R2 operations with mocked bucket
import { describe, test, expect, beforeEach } from 'vitest';

describe('R2 File Operations', () => {
  let mockBucket;
  
  beforeEach(() => {
    mockBucket = {
      put: vi.fn(),
      get: vi.fn(),
      delete: vi.fn(),
      head: vi.fn(),
      list: vi.fn(),
    };
  });
  
  test('should upload file successfully', async () => {
    const fileData = new ArrayBuffer(1024);
    const key = 'test/file.txt';
    
    mockBucket.put.mockResolvedValue({ etag: 'mock-etag' });
    
    await mockBucket.put(key, fileData, {
      httpMetadata: { contentType: 'text/plain' },
    });
    
    expect(mockBucket.put).toHaveBeenCalledWith(
      key,
      fileData,
      expect.objectContaining({
        httpMetadata: { contentType: 'text/plain' },
      })
    );
  });
  
  test('should handle file not found', async () => {
    mockBucket.get.mockResolvedValue(null);
    
    const result = await mockBucket.get('nonexistent/file.txt');
    
    expect(result).toBeNull();
  });
});
```

### 2. Integration Tests

```javascript
// Test with actual R2 bucket in test environment
import { describe, test, expect } from 'vitest';

describe('R2 Integration Tests', () => {
  const testBucket = getTestBucket(); // Configure test bucket
  
  test('should perform full CRUD operations', async () => {
    const key = `test/${Date.now()}/file.txt`;
    const content = 'Test file content';
    
    // Create
    await testBucket.put(key, content, {
      httpMetadata: { contentType: 'text/plain' },
    });
    
    // Read
    const object = await testBucket.get(key);
    expect(object).toBeTruthy();
    expect(await object.text()).toBe(content);
    
    // Update
    const newContent = 'Updated content';
    await testBucket.put(key, newContent, {
      httpMetadata: { contentType: 'text/plain' },
    });
    
    const updatedObject = await testBucket.get(key);
    expect(await updatedObject.text()).toBe(newContent);
    
    // Delete
    await testBucket.delete(key);
    const deletedObject = await testBucket.get(key);
    expect(deletedObject).toBeNull();
  });
});
```

## Best Practices

### File Organization
- Use consistent naming conventions
- Implement logical folder structures
- Include metadata for better organization
- Use prefixes for different file types

### Security
- Implement proper access controls
- Use signed URLs for temporary access
- Validate file types and sizes
- Scan uploads for malware

### Performance
- Leverage Cloudflare's global network
- Implement multi-layer caching
- Use appropriate compression
- Optimize for your access patterns

### Cost Management
- Monitor storage usage and costs
- Implement lifecycle policies
- Use storage classes appropriately
- Optimize data transfer patterns

## Common Use Cases

1. **Static Asset Hosting** - CSS, JS, images for web applications
2. **User File Uploads** - Profile pictures, document storage
3. **Data Backup** - Application backups and archives
4. **Media Streaming** - Video and audio content delivery
5. **Data Analytics** - Log files and analytics data storage

R2 provides a powerful, cost-effective foundation for web application storage needs, especially when combined with other Cloudflare services for a complete edge computing solution.
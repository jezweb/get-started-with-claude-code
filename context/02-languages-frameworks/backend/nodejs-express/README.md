# Node.js Express Framework Guide

Comprehensive guide to building scalable web applications and APIs with Express.js, covering modern JavaScript patterns, middleware architecture, and production best practices.

## 🎯 Express Overview

Express.js is a minimal and flexible Node.js web framework that provides:
- **Minimalist Core** - Unopinionated, flexible foundation
- **Middleware Architecture** - Composable request handling
- **Routing System** - Powerful URL pattern matching
- **Template Engine Support** - Multiple view engines
- **HTTP Utility Methods** - Simplified request/response handling
- **Performance** - Lightweight with minimal overhead

## 🚀 Getting Started

### Installation and Setup

```bash
# Initialize new project
mkdir express-app && cd express-app
npm init -y

# Install Express and common dependencies
npm install express
npm install dotenv cors helmet morgan compression cookie-parser
npm install -D nodemon @types/node

# TypeScript setup (optional but recommended)
npm install -D typescript ts-node @types/express @types/cors @types/morgan
npx tsc --init

# Additional common packages
npm install express-validator express-rate-limit express-session
npm install jsonwebtoken bcryptjs
npm install -D @types/jsonwebtoken @types/bcryptjs
```

### Basic Application

```javascript
// app.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(compression()); // Compress responses
app.use(morgan('combined')); // Logging
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Express API' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### TypeScript Version

```typescript
// src/app.ts
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(compression());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Type definitions
interface ErrorWithStatus extends Error {
  status?: number;
}

// Routes
app.get('/', (req: Request, res: Response) => {
  res.json({ message: 'Welcome to Express TypeScript API' });
});

// Error handling
app.use((err: ErrorWithStatus, req: Request, res: Response, next: NextFunction) => {
  const status = err.status || 500;
  const message = err.message || 'Internal Server Error';
  
  res.status(status).json({
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
```

## 📁 Project Structure

### Scalable Architecture

```
express-app/
├── src/
│   ├── config/           # Configuration files
│   │   ├── database.js
│   │   ├── redis.js
│   │   └── index.js
│   ├── controllers/      # Route controllers
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   └── product.controller.js
│   ├── middlewares/      # Custom middlewares
│   │   ├── auth.js
│   │   ├── validate.js
│   │   ├── rateLimiter.js
│   │   └── errorHandler.js
│   ├── models/          # Data models
│   │   ├── user.model.js
│   │   └── product.model.js
│   ├── routes/          # Route definitions
│   │   ├── index.js
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   └── product.routes.js
│   ├── services/        # Business logic
│   │   ├── auth.service.js
│   │   ├── user.service.js
│   │   └── email.service.js
│   ├── utils/           # Utility functions
│   │   ├── logger.js
│   │   ├── validators.js
│   │   └── helpers.js
│   ├── validations/     # Request validations
│   │   ├── auth.validation.js
│   │   └── user.validation.js
│   └── app.js          # Express app setup
├── tests/              # Test files
├── scripts/            # Utility scripts
├── public/             # Static files
├── .env
├── .env.example
├── .gitignore
├── package.json
├── tsconfig.json       # If using TypeScript
└── server.js          # Server entry point
```

## 🔧 Middleware Patterns

### Custom Middleware

```javascript
// src/middlewares/requestLogger.js
const requestLogger = (req, res, next) => {
  const start = Date.now();
  
  // Log request
  console.log(`${req.method} ${req.url} - ${req.ip}`);
  
  // Log response
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.url} ${res.statusCode} - ${duration}ms`);
  });
  
  next();
};

// src/middlewares/asyncHandler.js
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Usage
app.get('/users', asyncHandler(async (req, res) => {
  const users = await User.findAll();
  res.json(users);
}));

// src/middlewares/validate.js
const { validationResult } = require('express-validator');

const validate = (validations) => {
  return async (req, res, next) => {
    await Promise.all(validations.map(validation => validation.run(req)));

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    res.status(400).json({ 
      errors: errors.array().map(err => ({
        field: err.param,
        message: err.msg
      }))
    });
  };
};
```

### Authentication Middleware

```javascript
// src/middlewares/auth.js
const jwt = require('jsonwebtoken');

const authenticate = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      throw new Error();
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password');
    
    if (!user) {
      throw new Error();
    }
    
    req.user = user;
    req.token = token;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Please authenticate' });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        error: 'Access denied' 
      });
    }
    next();
  };
};

module.exports = { authenticate, authorize };
```

## 🛣️ Advanced Routing

### Router Module Pattern

```javascript
// src/routes/user.routes.js
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate, authorize } = require('../middlewares/auth');
const validate = require('../middlewares/validate');
const userController = require('../controllers/user.controller');

// Validation schemas
const createUserValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).matches(/^(?=.*[A-Za-z])(?=.*\d)/),
  body('name').trim().notEmpty()
];

const updateUserValidation = [
  body('email').optional().isEmail().normalizeEmail(),
  body('name').optional().trim().notEmpty()
];

// Routes
router.get('/', authenticate, userController.getUsers);
router.get('/profile', authenticate, userController.getProfile);
router.get('/:id', authenticate, userController.getUserById);
router.post('/', validate(createUserValidation), userController.createUser);
router.patch('/:id', authenticate, validate(updateUserValidation), userController.updateUser);
router.delete('/:id', authenticate, authorize('admin'), userController.deleteUser);

// Advanced routing patterns
router.route('/bulk')
  .post(authenticate, authorize('admin'), userController.bulkCreate)
  .delete(authenticate, authorize('admin'), userController.bulkDelete);

// Nested routes
router.use('/:userId/posts', require('./post.routes'));

module.exports = router;

// src/routes/index.js
const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/users', require('./user.routes'));
router.use('/products', require('./product.routes'));

// API versioning
router.use('/v1', router);

module.exports = router;
```

## 💾 Database Integration

### MongoDB with Mongoose

```javascript
// src/config/database.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB connected');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// src/models/user.model.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 8
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: Date,
  refreshTokens: [{
    token: String,
    createdAt: {
      type: Date,
      default: Date.now,
      expires: 604800 // 7 days
    }
  }]
}, {
  timestamps: true,
  toJSON: {
    transform: (doc, ret) => {
      delete ret.password;
      delete ret.__v;
      return ret;
    }
  }
});

// Indexes
userSchema.index({ email: 1 });
userSchema.index({ createdAt: -1 });

// Methods
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
```

### PostgreSQL with Sequelize

```javascript
// src/config/database.js
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});

// src/models/user.model.js
const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const sequelize = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  },
  role: {
    type: DataTypes.ENUM('user', 'admin'),
    defaultValue: 'user'
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  }
}, {
  hooks: {
    beforeCreate: async (user) => {
      user.password = await bcrypt.hash(user.password, 10);
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    }
  }
});

User.prototype.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = User;
```

## 🔐 Security Best Practices

### Security Configuration

```javascript
// src/config/security.js
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const hpp = require('hpp');

const configSecurity = (app) => {
  // Helmet configuration
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    }
  }));
  
  // Rate limiting
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP',
    standardHeaders: true,
    legacyHeaders: false,
  });
  
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    message: 'Too many authentication attempts',
    skipSuccessfulRequests: true
  });
  
  app.use('/api/', limiter);
  app.use('/api/auth/', authLimiter);
  
  // Data sanitization
  app.use(mongoSanitize()); // Prevent NoSQL injection
  app.use(xss()); // Clean user input from malicious HTML
  
  // Prevent parameter pollution
  app.use(hpp({
    whitelist: ['sort', 'fields', 'page', 'limit']
  }));
  
  // Additional security headers
  app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    next();
  });
};

module.exports = configSecurity;
```

## 🧪 Testing

### Test Setup with Jest

```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  coveragePathIgnorePatterns: ['/node_modules/'],
  setupFilesAfterEnv: ['./tests/setup.js'],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/config/*.js',
    '!src/server.js'
  ]
};

// tests/setup.js
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  await mongoose.connect(mongoUri);
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

afterEach(async () => {
  const collections = await mongoose.connection.db.collections();
  for (const collection of collections) {
    await collection.deleteMany({});
  }
});

// tests/integration/auth.test.js
const request = require('supertest');
const app = require('../../src/app');
const User = require('../../src/models/user.model');

describe('Auth Endpoints', () => {
  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'Test123!'
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body.user).toHaveProperty('email', 'test@example.com');
      
      const user = await User.findOne({ email: 'test@example.com' });
      expect(user).toBeTruthy();
    });
    
    it('should not register user with invalid email', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'invalid-email',
          password: 'Test123!'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('errors');
    });
  });
});
```

## 🚀 Production Deployment

### PM2 Configuration

```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'express-app',
    script: './src/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '500M',
    exp_backoff_restart_delay: 100,
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    wait_ready: true,
    listen_timeout: 3000,
    kill_timeout: 5000
  }]
};

// src/server.js - Graceful shutdown
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  process.send && process.send('ready'); // PM2 ready signal
});

const gracefulShutdown = (signal) => {
  console.log(`${signal} received: closing HTTP server`);
  server.close(() => {
    console.log('HTTP server closed');
    // Close database connections
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
```

### Docker Configuration

```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Multi-stage build for smaller image
FROM node:18-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

# Switch to app user
USER nodejs

# Expose port
EXPOSE 3000

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/server.js"]
```

## 📊 Monitoring and Logging

### Winston Logger Setup

```javascript
// src/utils/logger.js
const winston = require('winston');
const path = require('path');

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

const level = () => {
  const env = process.env.NODE_ENV || 'development';
  const isDevelopment = env === 'development';
  return isDevelopment ? 'debug' : 'warn';
};

const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'white',
};

winston.addColors(colors);

const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.colorize({ all: true }),
  winston.format.printf(
    (info) => `${info.timestamp} ${info.level}: ${info.message}`,
  ),
);

const transports = [
  new winston.transports.Console(),
  new winston.transports.File({
    filename: path.join('logs', 'error.log'),
    level: 'error',
  }),
  new winston.transports.File({ 
    filename: path.join('logs', 'all.log') 
  }),
];

const Logger = winston.createLogger({
  level: level(),
  levels,
  format,
  transports,
});

// Morgan stream
Logger.stream = {
  write: (message) => Logger.http(message.trim()),
};

module.exports = Logger;
```

## 🎯 Best Practices

### Error Handling

```javascript
// src/utils/AppError.js
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

// src/middlewares/errorHandler.js
const errorHandler = (err, req, res, next) => {
  let { statusCode, message } = err;
  
  if (!err.isOperational) {
    statusCode = 500;
    message = 'Internal Server Error';
  }
  
  res.locals.errorMessage = err.message;
  
  const response = {
    code: statusCode,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  };
  
  logger.error(err);
  
  res.status(statusCode).send(response);
};

// Catch unhandled errors
process.on('uncaughtException', (error) => {
  logger.error('UNCAUGHT EXCEPTION! 💥 Shutting down...');
  logger.error(error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('UNHANDLED REJECTION! 💥 Shutting down...');
  logger.error(reason);
  server.close(() => {
    process.exit(1);
  });
});
```

### API Versioning

```javascript
// src/routes/v1/index.js
const express = require('express');
const router = express.Router();

// Version 1 routes
router.use('/auth', require('./auth.routes'));
router.use('/users', require('./user.routes'));

module.exports = router;

// src/routes/v2/index.js
const express = require('express');
const router = express.Router();

// Version 2 routes with breaking changes
router.use('/auth', require('./auth.routes'));
router.use('/users', require('./user.routes')); // New schema

module.exports = router;

// Main app
app.use('/api/v1', require('./routes/v1'));
app.use('/api/v2', require('./routes/v2'));
```

---

*Express.js provides a solid foundation for building Node.js applications. Focus on middleware composition, proper error handling, and security best practices for production-ready applications.*